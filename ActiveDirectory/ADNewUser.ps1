$VerbosePreference = 'Continue'
# Gather current Domain information
[String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainName = $Domain -replace'.com',''
$TLDN = $Domain -replace("$DomainName."),''

# Prompt user for the new account Username
$UserName = Read-Host "Username? (do NOT include prefix (admin-, dev-, or srv-))!"

#Remove leading/trailing Spaces
$UserName = $UserName.Trim()

# Combine for the parent OUs
$OUDomain = "$DomainName" + "Users"

# Prompt User for groups
$Groups = @() # Create a blank array for groups
$groupNum = 1 # Start the group count at 1

Write-Host "Please enter group names (must be 1 or more)"
do {
 $count = $groupNum++
 $input = (Read-Host "Group $count Name")
 if ($input -ne '') {$Groups += $input}
}
until ($input -eq '')
Write-Verbose "$count groups added"

Function Get-Requester {
    Param(
    [string]$UserName
    )
    $Requester = Get-ADuser $UserName
    $RequesterFirst = $Requester.GivenName
    $RequesterLast = $Requester.SurName
    $RequesterFull = "$RequesterFirst" + " " + "$RequesterLast"
    Return $RequesterFull
}

Function Get-Requester {
    Param($UserName)
    $Requester = Get-ADuser $UserName
    $RequesterFirst = $Requester.GivenName
    $RequesterLast = $Requester.SurName
    $RequesterFull = "$RequesterFirst" + " " + "$RequesterLast"
    Return $RequesterFull
}
# Prompt User for Type
$input =Read-Host "What Type of account? Admin-(1), Dev- (2), SRV- (3)"
$PasswordExpiresNever = $False # Default to false unless an SRV account
switch ($input)
    {
    '1'{
        $Type = 'admin'
        }
    '2'{
        $Type = "dev"
        }
    '3'{
        $Type = "srv"
        }
    }

    Write-Verbose "Creating a $Type account"
    if($Type -eq 'srv') {
        $PWNeverExpire = $True
        $srvOwner = Read-Host "What is the Owner name?"
        $srvOwnerDept = Read-host "What is the Owner Department?"
        $srvPurpose = Read-Host "What is the Purpose?"
        $Description = "Purpose: $srvPurpose. OwnerDept: $srvOwnerDept. Owner: $srvOwner"
    }
    else {
     Get-Requester -UserName $UserName
     $OU = "OU=Administration,OU=$OUDomain,DC=$DomainName,DC=$TLDN"
     $Description = "$Type account for $RequesterFull"
     $PWNeverExpire = $False
     }

# Build Account Name
If($UserName -notlike "srv-*"){
    $NewUser = "$Type-$Username"
}
Else{
    $NewUser = $Username
}

# Create the User Principal Name
$UPN = "$NewUser" + "@" + "$Domain"

# Trim the $NewUser to 20 chars, because the SamAccountName cannot be more than 20
If($NewUser.Length -gt 20) {
$SAM = $NewUser.Substring(0, 20)
}

# Do the work
Try{
    New-ADUser -Name $NewUser -SamAccountName $SAM -UserPrincipalName $UPN -Path $OU -Description $Description -AccountPassword(Read-Host -AsSecureString "Type Password for $NewUser") -PasswordNeverExpires:$PWNeverExpire -DisplayName $NewUser -Enabled $True -ErrorAction Stop
    Write-Host "$NewUser was created successfully" -ForegroundColor Green
}
Catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
    {
    Write-Host "$NewUser already exists" -ForegroundColor Green -BackgroundColor Red
    }
Catch{
    If ($Error.Exception -like '*The operation failed because UPN value provided for addition*is not unique forest-wide*')
        {
        Write-Host "$NewUser already exists (UPN not unique)" -ForegroundColor Green -BackgroundColor Red
        }
    Else
        {
        $Error[0].Exception
        }
    }
If ($Groups)
    {Write-Verbose "Root If: $Groups"
    Foreach ($Group in $Groups.Split(", "))
        {Write-Verbose "Foreach: $Groups"
        Try {Write-Verbose "Try: $Groups"
            Add-ADGroupMember -Identity $Group -Members $NewUser
            Write-Host "Added $NewUser to $Group"
            }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host "AD Group $Group doesn't exist. Check spelling and add manually" -ForegroundColor Yellow
            }
        }
    }