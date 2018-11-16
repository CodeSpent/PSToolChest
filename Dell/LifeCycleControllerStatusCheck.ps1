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
$SourcePath = "D:\Scripts\iDRACUpgrade2018"
$SourceFile = "iDRACs.txt"
$ResultsPath = "$SourcePath\Results"
$message = "This script will read from $SourcePath\$SourceFile exactly. `n Press enter once this is correct. `n Use iDRAC Credentials on Cred prompt!"
#Get the Dates into a format that'll be used for the results page
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$ResultsFile = "iDRAC-LifeCycleResults_$CurrentDate.csv"

#############Conjunction Juncion, what's your Function#############
Function WritePropsToCSV
    {
        $Props = [ordered]@{
            "IP Address" = $iDRAC;
            "Attribute Name" = "$AttributeName";
            "Current Value" = "$CurrentValue"
            }#end props
        $PropsObject = New-Object -TypeName PSObject -Property $Props
        $PropsObject| Export-CSV -NoTypeInformation $ResultsPath\$ResultsFile -Append
    }
#Likely to be deletedvvvvv
Function CreateNewiDRACSession
    {
#####Create the new iDRAC Session. This must be repeated for every iDRAC in the loop
    Try
        {
        Write-Host "CreateNewiDRACSession running" -ForegroundColor 
        $iDRACSession = New-PEDRACSession -IPAddress $iDRAC -Credential $Creds -ErrorAction Stop
            #if $script:iDRACSession ()
        }
    Catch
        {
        Write-Host "CreateNewiDRACSession Catch block running" -ForegroundColor Yellow
        Write-Host "Check-LifeCycle Function foreach, ELSE block running" -ForegroundColor Yellow
        $AttributeName = "$_.Exception.Message"
        $CurrentValue = "Offline."
        WritePropsToCSV -AttributeName $AttributeName -CurrentValue $CurrentValue
        }
    }
####################Just Do It####################

#pause ($script:message)
#Define the further $Vars required.
#This is done so that the date/timestamp is set to when the loop actually starts, after creds, rather than being inaccurate
#rather than if the user ends up waiting minutes to enter creds (maybe they forgot them and need to ask?)
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$ResultsFile = "iDRAC-LifeCycleResults_$CurrentDate.csv"
#Get the list of iDRACs we want to use
    Try
        {
        $iDRACs = Get-Content "$SourcePath\$SourceFile" -ErrorAction Stop;
        Write-host "$iDRACs"
        }
    catch
        {
        Write-Host "$SourcePath\$SourceFile can't be read!" -ForegroundColor Yellow
        exit
        }
#Prompt User for OK and to provide info
$Confirm = Read-Host "$message"
#Let's define our credentials for the iDRACs.
    Write-Host "CredentialDefine running" -ForegroundColor Yellow
    Try
        {
        Write-Host "Check-LifeCycle Function Try Block running" -Foregroundcolor Yellow
         $Creds = Get-Credential -Message "Please enter credentials for the iDRAC"
        }
    catch
        {
        Write-Host "You didn't provide Credentials!" -ForegroundColor Yellow
        exit
        }

$ResultsFile = "iDRAC-LifeCycleResults_$CurrentDate.csv"
Write-Host "-Creds $Creds -iDRACs $iDRACs -ResultsPath $ResultsPath -ResultsFile $ResultsFile "

#####The code block that actually does the loop.
Write-Host "Check-LifeCycle Function has started" -ForegroundColor Yellow
Write-Host "iDRACs Var is "$iDRACs" - iDRAC Var is "$iDRAC"" -Foreground Yellow
Foreach ($iDRAC in $iDRACs)
    {
    Write-Host "Check-LifeCycle Function Foreach Block running" -ForegroundColor Yellow
    Write-Host "Pre-TestConnection iDRACs: $iDRACs"
    Write-Host "Pre-TestConnection iDRAC: $iDRAC"
    If (Test-Connection -ComputerName $iDRAC -Quiet -Count 1)
        {
        Write-Host "test-Connection succeeded" -ForegroundColor Yellow
        #####Create the new iDRAC Session. This must be repeated for every iDRAC in the loop
        Try
            {
            Write-Host "CreateNewiDRACSession running" -ForegroundColor 
            $iDRACSession = New-PEDRACSession -IPAddress $iDRAC -Credential $Creds -ErrorAction Stop
            $RawProps = Get-PELCAttribute -iDRACSession $iDRACSession | Where-Object {$_.AttributeName -match "Lifecycle Controller State"}
            #If connection was successful, but attributes we're looking for (Life Cycle Controller State" doesn't exist,
            #Print No LifeCycleController Found (possible with 11G servers or lower)
            If (!$RawProps)
                {
                    $AttributeName = "No LifeCycleController Found."
                    $CurrentValue = "No LifeCycleController Found."
                    WritePropsToCSV -AttributeName $AttributeName -CurrentValue $CurrentValue
                }
            Else
                {
                    $AttributeName = $RawProps.AttributeName
                    $CurrentValue = $RawProps.CurrentValue
                    WritePropsToCSV -AttributeName $AttributeName -CurrentValue $CurrentValue
                }
            }
        Catch
            {
            Write-Host "CreateNewiDRACSession Catch block running" -ForegroundColor Yellow
            Write-Host "Check-LifeCycle Function foreach, ELSE block running" -ForegroundColor Yellow
            $AttributeName = "$_.Exception.Message"
            $CurrentValue = "Offline."
            WritePropsToCSV -AttributeName $AttributeName -CurrentValue $CurrentValue
            }
        ####Need to make "CreatNewiDRACSession" not print twice."
        }
    Else
        {
        Write-Host "Check-LifeCycle Function foreach, ELSE block running" -ForegroundColor Yellow
            $AttributeName = "Offline."
            $CurrentValue = "Offline."
            WritePropsToCSV -AttributeName $AttributeName -CurrentValue $CurrentValue
        }
    }