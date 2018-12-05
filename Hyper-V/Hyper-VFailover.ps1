﻿$WorkingDir = "D:\Scripts"
$SourceFile = "$WorkingDir\SourceFiles\Hyper-V_Failover.txt"
$ResultsDir = "$WorkingDir\Results\"
#Read-Host "This will read from $SourceFile. Press ENTER when ready"
# Get the list of Hosts we want to use
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
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$ResultsFile = -join ("$ResultsDir", "Hyper-VFailover", "_", "$CurrentDate.csv")
Function WritePropsToCSV {
    Param ($HyperVHost, $HyperVHostPri, $HyperVHostRep, $RunningVMsName, $Repeater, $FailoverStatus, $Notes)
        $Props = [ordered]@{
            "HyperVHostPri" = "$HyperVHostPri";
            "HyperVHostRep" = "$HyperVHostRep";
            "VMName" = "$RunningVMsName";
            "Repeater" = "$Repeater"
            "Status" = "$FailoverStatus"
            "Notes" = "$Notes"
            }#end props
        $PropsObject = New-Object -TypeName PSObject -Property $Props
        $PropsObject| Export-CSV -NoTypeInformation $ResultsFile -Append
    }
Function FailOverVM {

}
Foreach ($HyperVHost in $HyperVHosts) {
    $HyperVHostPri = $HyperVHost
    If(Test-Connection -ComputerName $HyperVHost -Quiet -Count 1) {
        Try {
            # Get VM list from Host
            # This is in a Try block because if the Hyper-V Management service isn't running on the host
            # then we want to capture that and place it into our log csv.
            $VMs = Get-VM -ComputerName $HyperVHost -ErrorAction Stop
            Try {# RunningVMsName steps
                $RunningVMs = $VMs | Where-Object {$_.Status -like "Running"}
                $RunningVMsName = $RunningVMs.Name
                If ($RunningVMsName) {
                    Try {# Perform Failover on RunningVMsName
                        Write-Host $RunningVMsName | Format-List
                        $HyperVHostRep = Get-VMReplication -ComputerName $HyperVHost -VMName $RunningVMsName
                        $HyperVHostRep = $HyperVHostRep.ReplicaServer
                        Stop-VM -ComputerName $HyperVHosts -Name $RunningVMsName -Force
                        #while(!($RunningVMsName.State -like "Off")) {
                        #    Write-Host "Waiting for Off"
                        #    }
                        Start-VMFailover -Prepare -VMName $RunningVMsName -ComputerName $HyperVHostPri -Confirm:$false -ErrorAction Stop
                        Start-VMFailover -VMName $RunningVMsName -ComputerName $HyperVHostRep -Confirm:$false -ErrorAction Stop
                        Start-VM -VMName $RunningVMsName -ComputerName $HyperVHostRep -ErrorAction Stop
                        Set-VMReplication -Reverse -VMName $RunningVMsName -ComputerName $HyperVHostRep -ErrorAction Stop
                        Write-Host "$RunningVMsName was successfully failed over"
                        # Write Props to CSV
                        $FailoverStatus = "Success"
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $RunningVMsName $Repeater $FailoverStatus $Notes
                        }
                    Catch {
                        # Something in the failover failed.
                        Write-Host "Something failed while failing over $RunningVMsName from $HyperVHost" - -ForegroundColor Yellow
                        $FailoverStatus = "Something Failed during the failover process of $HyperVHostPri with $RunningVMsName."
                        $Notes = $Error[0].Exception
                        # Write Props to CSV
                        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $RunningVMsName $Repeater $FailoverStatus $Notes
                        }
                    }
                Else {
                    $FailoverStatus = "$PriSec was not found on $HyperVHostPri"
                    WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $RunningVMsName $Repeater $FailoverStatus $Notes
                    }
                }
            Catch {
                Write-Host "Something failed while getting $PrRunningVMsName from $HyperVHost"
                $FailoverStatus = "Couldn't get $RunningVMsName from $HyperVHost"
                $Notes = "$Error[0]"
                }
            }
        Catch{
            Write-Host "Couldn't get VM List from $HyperVHost."
            $FailoverStatus = "Failed to retrieve VM list from $HyperVHost"
            $Notes = "$Error[0]"
            WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $RunningVMsName $Repeater $FailoverStatus
            }
    }
    Else{
        Write-Host "Test-Connection failed"
        $FailoverStatus = "Test-Connection failed. Offline"
        WritePropsToCSV $HyperVHost $HyperVHostPri $HyperVHostRep $RunningVMsName $Repeater $FailoverStatus       
        }
    }