Write-Host = "THIS IS A WORK IN PROGRESS!! If you see this message, it works as of 3:32p 11/5/2018, but receives errors anyway." -ForegroundColor Yellow -BackgroundColor DarkRed
$SourcePath = 'D:\Scripts\SourceFiles'
$SourceFile = 'LocalAdminSource.csv'
$SourceResultsFile = 'ServersToAddUserToLA-Results.txt'
$message = "This script will read from $SourcePath\SourceFile exactly. `n Press enter once this is correct."
[String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
Function pause ($message, $SourcePath, $SourceFile)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
function Get-LA-Members
    {
    invoke-command {
        net localgroup administrators | 
        where {$_ -AND $_ -notmatch "command completed successfully"} | 
        select -skip 4
        } -computer $Server
    }
Function Menu
{
    $EnterOrRead = Read-Host "Do you want to enter in the Usernames/Servers (1), or read from file (2)??"
    Switch ($EnterOrRead)
    {
        1 {
            Write-Host = "Manually Entering"
            ManualEnter
            }
        2 {
            Read-Host = "Selected Read from file. Make sure the files are"
            ReadFromFile
            }
        Default {
            Write-Host = "Manually Entering"
            ManualEnter
            }
        }

    if($choice -eq 1){
    Write-Host: "Manually entering values"
    }
    if($choice -eq 2){
    Read-Host = "Selected read from file"
    }
}
Function ManualEnter
{
    $UsersOrGroups = Read-Host "Name of the Username or AD Security Group, (separated by Comma Space)?"
    $Servers = Read-Host "Name of the Server Names, (separated by Comma Space)?"
    AddLAUsers $UsersOrGroups $UserOrGroup $Servers $Server
}    

#Get-LA-Members ($Server)

###This is currently not tested. Need to make Column A become $UsersOrGroups and Column B $Servers
Function ReadFromFile
{
    Import-CSV -Path $SourcePath\$SourceFile -Header Usernames,Servers
    Write-Host "Users: $UsersOrGroups, Servers: $Servers" -ForegroundColor Yellow 
}

Function AddLAUsers
{
    foreach ($UserOrGroup in $UsersOrGroups.Split(", "))
    {
        Write-Host "Looping User: $UserOrGroup" -ForegroundColor Yellow
        AddLAServers $Domain $Server $Servers $UserOrGroup $UsersOrGroups
    }
}

Function AddLAServers
{
    Write-Host "ADDLAServers Function is being run" -ForegroundColor Yellow
    foreach ($Server in $Servers.Split(", "))
    {
#        try
#        {
            Write-Host  "$UserOrGroup Being added to $Server" -ForegroundColor Yellow
            $adminGroup = [ADSI]"WinNT://$Server/Administrators"
            $adminGroup.add("WinNT://$Domain/$UserOrGroup")
            Write-Host "$server Success" -ForegroundColor Green
            "$server Success" | Out-File -FilePath $SourcePath\$SourceResultsFile -Append
<#            }
        catch
            {
            Write-Host "Something went wrong, check the results file in $SourcePath\results.txt" -ForegroundColor Red
               "$server " + $_.Exception.Message.ToString().Split(":")[1].Replace("`n","")
              "$server " + $_.Exception.Message.ToString().Split(":")[1].Replace("`n","") | Out-File -FilePath $SourcePath\results.txt -Append
            }   
#>        } 
}
#################Do Stuff#################
Menu $SourcePath $SourceFile $SourceResultsFile $Domain