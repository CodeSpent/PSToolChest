$WorkingDir = "D:\Scripts"
$SourceFile = "$WorkingDir\SourceFiles\Hyper-V_Failover.txt"
$ResultsDir = "$WorkingDir\Results\"
#Read-Host "This will read from $SourceFile. Press ENTER when ready"
# Get the list of iDRACs we want to use
Try
    {
        $HyperVHosts = Get-Content "$SourceFile" -ErrorAction Stop;
        Write-host "Got List of Hyper-V Hosts!" -ForegroundColor Green
    }
catch
    {
        Write-Host "$SourceFile can't be read!" -ForegroundColor Yellow
        exit
    }
$HostOption = Read-Host "Are you failing OFF OF Host01 (1), or Host02 (2)? `nWhich ever option you select, that host will be free to power off." 
Switch ($HostOption){ 
    1 {Write-Host "Failing VMs over to Host02.`nThis allows Host01 to be brought down"
        $PriSec = "D100"
        $Repeater = "DR01"
        $HyperVHostPri = $HyperVHost
        $HyperVHostRep = "Replica Server Placeholder"
    } 
    2 {Write-Host "Failing VMs over to Host01.`nThis allows Host02 to be brought down"
        $PriSec = "D101"
        $Repeater = "CR01"
        $HyperVHostPri = $HyperVHost
        $HyperVHostRep = "Replica Server Placeholder"
    } 
    Default {Write-Host "No answer provided. Exiting."
    Exit
    }
}
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$ResultsFile = -join ("$ResultsDir", "Hyper-VFailover", "_", "$CurrentDate.csv")
Function WritePropsToCSV
    {
    Param ($HyperVHost, $HyperVHostPri, $HyperVHostRep, $PriSec, $Repeater, $FailoverStatus, $Notes)
        $Props = [ordered]@{
            "HyperVHostPri" = "$HyperVHostPri";
            "HyperVHostRep" = "$HyperVHostRep";
            "PriSec" = "$PriSec";
            "Repeater" = "$Repeater"
            "Status" = "$FailoverStatus"
            "Notes" = "$Notes"
            }#end props
        $PropsObject = New-Object -TypeName PSObject -Property $Props
        $PropsObject| Export-CSV -NoTypeInformation $ResultsFile -Append
    }

Foreach ($HyperVHost in $HyperVHosts) {
    If(Test-Connection -ComputerName $HyperVHost -Quiet -Count 1) {
        Try {
            # Get VM list from Host
            # This is in a Try block because if the Hyper-V Management service isn't running on the host
            # then we want to capture that and place it into our log csv.
            $VMs = Get-VM -ComputerName $HyperVHost -ErrorAction Stop
            Try {# PriSec steps
                $PriSec = $VMs | Where-Object {$_.Name -like "*$PriSec*"}
                $PriSec = $PriSec.Name
                If ($PriSec) {
                    Try {# Perform Failover on PriSec
                        Write-Host $PriSec | Format-List
                        $HyperVHostRep = Get-VMReplication -ComputerName $HyperVHost -VMName $PriSec
                        $HyperVHostRep = $HyperVHostRep.ReplicaServer
                        Stop-VM -ComputerName $HyperVHosts -Name $PriSec -Force
                        #while(!($PriSec.State -like "Off")) {
                        #    Write-Host "Waiting for Off"
                        #    }
                        Start-VMFailover -Prepare -VMName $PriSec -ComputerName $HyperVHostPri -Confirm:$false -ErrorAction Stop
                        Start-VMFailover -VMName $PriSec -ComputerName $HyperVHostRep -Confirm:$false -ErrorAction Stop
                        Start-VM -VMName $PriSec -ComputerName $HyperVHostRep -ErrorAction Stop
                        Set-VMReplication -Reverse -VMName $PriSec -ComputerName $HyperVHostRep -ErrorAction Stop
                        Write-Host "$PriSec was successfully failed over"
                        # Write Props to CSV
                        $FailoverStatus = "Success"
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                        }
                    Catch {
                        # Something in the failover failed.
                        Write-Host "Something failed while failing over $PriSec from $HyperVHost" - -ForegroundColor Yellow
                        $FailoverStatus = "Something Failed during the failover process of $HyperVHostPri with $PriSec."
                        $Notes = $Error[0].Exception
                        # Write Props to CSV
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                        }
                    }
                Else {
                    $FailoverStatus = "$PriSec was not found on $HyperVHostPri"
                    WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                    }
                Try {
                    # Repeater steps
                    $Repeater = $VMs | Where-Object {$_.Name -like "*$Repeater*"}
                    $Repeater = $Repeater.Name
                    Try {
                        Write-Host $Repeater | Format-List
                        Start-VMFailover -Prepare -VMName $Repeater -ComputerName $HyperVHostPri -WhatIf
                        Start-VMFailover -VMName $Repeater -ComputerName $HyperVHostRep -WhatIf
                        Set-VMReplication -Reverse -VMName $Repeater -ComputerName $HyperVHostRep -WhatIf
                        Start-VM -VMName $Repeater -ComputerName $HyperVHostRep -WhatIf
                        Write-Host "$Repeater was successfully failed over"
                        # Write Props to CSV
                        $FailoverStatus = "Success"
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                        }
                    Catch {
                        Write-Host "Repeater: $Repeater is not in a state where it can be failed over"
                        $FailoverStatus = "Something Failed during the failover process of $HyperVHostPri with $Repeater"
                        $Notes = $Error[0].Exception
                        # Write Props to CSV
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                        }
                    }
                Catch {
                    Write-Host "Failed to get $Repeater from $HyperVHost"
                    $FailoverStatus = "Failed to get $Repeater from $HyperVHost"
                    # Write Props to CSV
                    WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus $Notes
                    }
                }
            Catch {
                Write-Host "Something failed while getting $PriSec from $HyperVHost"
                $FailoverStatus = "Couldn't get $PriSec from $HyperVHost"
                $Notes = "$Error[0]"
                }
            }
        Catch{
            Write-Host "Couldn't get VM List from $HyperVHost."
            $FailoverStatus = "Failed to retrieve VM list from $HyperVHost"
            $Notes = "$Error[0]"
            WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus
            }
    }
    Else{
        Write-Host "Test-Connection failed"
        $FailoverStatus = "Test-Connection failed. Offline"
        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $PriSec $Repeater $FailoverStatus       
        }
    }