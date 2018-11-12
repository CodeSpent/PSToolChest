<#

.SYNOPSIS
This script requires the DellPEWSManTools (https://github.com/dell/DellPEWSMANTools).
This will take the file located in D:\Scripts\iDRACUpgrade2018\iDRACs.txt (modify in the script) and scan every IP address for the
LifeCycle Controller status. This is because if an iDRAC's LifeCycle Controller is not in the "Enabled" state, you cannot upgrade the firmware.


.DESCRIPTION
This will take the file located in D:\Scripts\iDRACUpgrade2018\iDRACs.txt (modify in the script) and scan every IP address for the
LifeCycle Controller status. This is because if an iDRAC's LifeCycle Controller is not in the "Enabled" state, you cannot upgrade the firmware.


.EXAMPLE
Example Output is:
"IP Address","Attribute Name","Current Value"
"192.168.0.49","Lifecycle Controller State","Recovery"
"192.168.289.149","Offline","Offline"
"192.168.1.49","Lifecycle Controller State","Recovery"
"192.168.2.149","Lifecycle Controller State","Enabled"
"192.168.3.49","No LifeCycleController Found","No LifeCycleController Found."
"192.168.4.49","Lifecycle Controller State","Enabled"

Which can obviously be opened in Excel, which makes it much easier to view, sort, and pawn off on someone else to enable the LifeCycleControllers :)

.NOTES
Depending on your connection speed and number of servers, this may take a while. Start it, watch the first few succeed, and go grab a coffee, go for a walk, or take a nap.
This takes about 3 seconds per server for me.

.LINK
https://github.com/joshbgosh10592/PSToolChest

#>
clear
Import-Module DellPEWSManTools
$script:SourcePath = "D:\Scripts\iDRACUpgrade2018"
$script:SourceFile = "iDRACs.txt"
$script:ResultsPath = "$script:SourcePath\Results"
$message = "This script will read from $script:SourcePath\$script:SourceFile exactly. `n Press enter once this is correct. `n Use iDRAC Credentials on Cred prompt!"
#############Conjunction Juncion, what's your Function#############
Function CredentialDefine
    {
    Write-Host "Check-LifeCycle Function running"
    Try
        {
        Write-Host "Check-LifeCycle Function Try Block running" -Foregroundcolor Yellow
         $script:Creds = Get-Credential -Message "Please enter credentials for the iDRAC"
        }
    catch
        {
        Write-Host "You didn't provide Credentials!" -ForegroundColor Yellow
        exit
        }
    }
Function Check-LifeCycle ($Creds, $iDRAC, $iDRACs, $ResultsPath, $ResultsFile)
    {
    Foreach ($script:iDRAC in $script:iDRACs)
        {
        Write-Host "Check-LifeCycle Function Foreach Block running" -ForegroundColor Yellow
        Write-Host "$script:iDRAC"
        If (Test-Connection -ComputerName $script:iDRAC -Quiet -Count 1)
            {
            CreateNewiDRACSession $iDRAC $Creds $ResultsPath $ResultsFile
            ####Need to make "CreatNewiDRACSession" not print twice."
            $script:RawProps = Get-PELCAttribute -iDRACSession $script:iDRACSession | Where-Object {$_.AttributeName -match "Lifecycle Controller State"}
                If (!$RawProps)
                    {
                    $script:Props = [ordered]@{
                            "IP Address" = $script:iDRAC;
                            "Attribute Name" = "No LifeCycleController Found";
                            "Current Value" = "No LifeCycleController Found."
                        }#end props
                    $script:PropsObject = New-Object -TypeName PSObject -Property $script:Props
                    $script:PropsObject| Export-CSV -NoTypeInformation $script:ResultsPath\$script:ResultsFile -Append
                    }
                Else
                    {
                    $script:Props = [ordered]@{
                        "IP Address" = $script:RawProps.PSComputerName;
                        "Attribute Name" = $script:RawProps.AttributeName;
                        "Current Value" = $script:RawProps.CurrentValue
                        }#end props
                    $script:PropsObject = New-Object -TypeName PSObject -Property $script:Props
                    $script:PropsObject| Export-CSV -NoTypeInformation $script:ResultsPath\$script:ResultsFile -Append
                }
            }
        Else
            {
            Write-Host "Check-LifeCycle Function foreach, ELSE block running" -ForegroundColor Yellow
            $script:Props = [ordered]@{
                "IP Address" = $script:iDRAC;
                "Attribute Name" = "Offline";
                "Current Value" = "Offline"
                }#end props
            $script:PropsObject = New-Object -TypeName PSObject -Property $script:Props
            $script:PropsObject| Export-CSV -NoTypeInformation $script:ResultsPath\$script:ResultsFile -Append
            }
        }
    }
Function CreateNewiDRACSession
    {
    Param ($iDRAC, $iDRACSession, $Creds)
    Try
        {
        Write-Host "CreateNewiDRACSession running" -ForegroundColor Yellow
        $script:iDRACSession = New-PEDRACSession -IPAddress $script:iDRAC -Credential $script:Creds -ErrorAction Stop
            #if $script:iDRACSession ()
        }
    Catch
        {
        Write-Host "CreateNewiDRACSession Catch block running" -ForegroundColor Yellow
        $script:Props = [ordered]@{
            "IP Address" = $script:iDRAC;
            "Attribute Name" = "$_.Exception.Message";
            "Current Value" = "Can't Create iDRAC Session. Check Password."
            }#end props
        $script:PropsObject = New-Object -TypeName PSObject -Property $script:Props
        $script:PropsObject| Export-CSV -NoTypeInformation $script:ResultsPath\$script:ResultsFile -Append
        }
    }
Function DoGetList
    {
    Param ($iDRACs, $SourcePath, $SourceFile)
    Try
        {
        $script:iDRACs = Get-Content "$script:SourcePath\$script:SourceFile" -ErrorAction Stop;
        }
    catch
        {
        Write-Host "$script:SourcePath\$script:SourceFile can't be read!" -ForegroundColor Yellow
        exit
        }
    }
Function BuildDates
    {
        $script:CurrentDate = Get-Date
        $script:CurrentDate = $script:CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
    }
####################Just Do It####################

#pause ($script:message)
BuildDates
$script:ResultsFile = "iDRAC-LifeCycleResults_$script:CurrentDate.csv"
$Confirm = Read-Host "$message"
CredentialDefine
DoGetList
Check-LifeCycle
