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
