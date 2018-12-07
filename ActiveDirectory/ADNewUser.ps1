# Gather current Domain information
[String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainName = $Domain -replace'.com',''
$TLDN = $Domain -replace("$DomainName."),''

# Prompt user for the new account Username
$UserName = Read-Host "Username? (do NOT include prefix (admin-, dev-, or srv-))!"

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

# Prompt User for Type
$input =Read-Host "What Type of account? Admin-(1), Dev- (2), SRV- (3)"
switch ($input)
    {
    '1'{
        $Type = "admin"
        # Prompt User for requester's First/Last name
        $FLName = Read-Host "Requester's First and Last name?"
        # Create the full OU Path
        $OU = "OU=Administration,OU=$OUDomain,DC=$DomainName,DC=$TLDN"
        $Description = "$Type account for $FLName"
        # Add normal account to extra Group
        ######Need to decide how to sanitize
        }
    '2'{
        $Type = "dev"
        # Prompt User for requester's First/Last name
        $FLName = Read-Host "Requester's First and Last name?"
        # Create the full OU Path
        $OU = "OU=Administration,OU=$OUDomain,DC=$DomainName,DC=$TLDN"
        $Description = "$Type account for $FLName"
        }
    '3'{
        $Type = "srv"
        # Create the full OU Path
        $OU = "OU=Service Accounts,OU=EnterpriseGroups,DC=$DomainName,DC=$TLDN"
        $srvOwner = Read-Host "What is the Owner name?"
        $srvOwnerDept = Read-host "What is the Owner Department?"
        $srvPurpose = Read-Host "What is the Purpose?"
        $Description = "Purpose: $srvPurpose. OwnerDept: $srvOwnerDept. Owner: $srvOwner"
        }
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

# Do the work
Try{
    New-ADUser -Name $NewUser -SamAccountName $NewUser -UserPrincipalName $UPN -Path $OU -Description $Description -AccountPassword(Read-Host -AsSecureString "Type Password for $NewUser") -DisplayName $NewUser -Enabled $True -ErrorAction Stop
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
        $Error.Exception
        }
    }
If ($Groups)
    {
    Foreach ($Group in $Groups)
        {
        Add-ADGroupMember -Identity $Group -Members $NewUser
        Write-Host "Added $NewUser to $Group"
        }
    }
