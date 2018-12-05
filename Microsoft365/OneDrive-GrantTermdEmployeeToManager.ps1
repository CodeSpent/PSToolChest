$Error.Clear()
Try{
    Import-Module -DisableNameChecking 'C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell' -ErrorAction Stop
    }
Catch{
    Write-Host "SharePoint Online Management Shell module is not available. See: https://www.microsoft.com/en-us/download/details.aspx?id=35588"
    Pause
    Exit
    }

[String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainName = $Domain -replace'.com',''
$TLDN = $Domain -replace("$DomainName."),''
$orgName = "$DomainName" + "cloud"
Write-Host "Enter your Azure Admin Creds on the screen that appears" -ForegroundColor Green
Try{
    Connect-SPOService -Url https://$orgName-admin.sharepoint.com -ErrorAction Stop
    }
Catch{
    Write-Host "Connection failed with error message "$Error"" -ForegroundColor Yellow
    Pause
    Exit
    }
$TermdUser = Read-Host "What's the username of the terminated user?"
$Manager = Read-Host "What's the Username of the user who needs access?"
$ManagerUPN = $Manager, "@", $Domain -join ""
$TermdUserURL = "https://$orgName-my.sharepoint.com/personal/${TermdUser}_${DomainName}_${TLDN}"
Try{
    Set-SPOUser -Site $TermdUserURL -LoginName $Manager -IsSiteCollectionAdmin $True -ErrorAction Stop
    Write-Host "$Manager now has access to $TermdUser's OneDrive." -ForegroundColor Green
    }
Catch [Microsoft.SharePoint.Client.ServerException]{
    Write-Host "File not found. This typically means the user accounts are incorrect. Check the names and try again."
    }
Catch{
    Write-Host "Something went wrong with setting permissions. Check all user accounts and try again" -ForegroundColor Yellow
    Write-Host "Is the requesting user actually $Manager, and the term'd employee really $TermdUser ?" -ForegroundColor Yellow
    Write-Host "Error is: $Error" -ForegroundColor Yellow
    }