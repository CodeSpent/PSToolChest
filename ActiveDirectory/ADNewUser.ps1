# Gather current Domain information
[String]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainName = $Domain -replace'.com',''
$TLDN = $Domain -replace("$DomainName."),''

# Prompt User for requester's First/Last name
$FLName = Read-Host "Requester's First and Last name?"

# Prompt user for the new account Username
$UserName = Read-Host "Username?"

# Build Account Name
$NewUser = "$Type-$Username"

# Create the User Principal Name
$UPN = "$NewUser" + "@" + "$Domain"

# Combine for the parent OUs
$OUDomain = "$DomainName" + "Users"

# Prompt User for Type
$input =Read-Host "What Type of account? Admin-(1), Dev- (2), SRV- (2)"
switch ($input)
    {
    '1'{
        $Type = "Admin"
        # Create the full OU Path
        $OU = "OU=Administration,OU=$OUDomain,DC=$DomainName,DC=$TLDN"
        # Add user to CyberArk Group
        ######Need to decide how to sanitize
        }
    '2'{
        $Type = "Dev"
        # Create the full OU Path
        $OU = "OU=Administration,OU=$OUDomain,DC=$DomainName,DC=$TLDN"
        }
    '3'{
        $Type = "srv"
        # Create the full OU Path
        $OU = "OU=Service Accounts,OU=EnterpriseGroups,DC=$DomainName,DC=$TLDN"
        }
    }
# Do the work
Try{
New-ADUser -Name $NewUser -SamAccountName $NewUser -UserPrincipalName $UPN -Path $OU -Description "$Type account for $FLName" -AccountPassword(Read-Host -AsSecureString "Type Password for $NewUser") -DisplayName $NewUser -Enabled $True
}
Catch{
    If ($Error.Exception -like '*The operation failed because UPN value provided for addition*is not unique forest-wide*')
        {
            Write-Host "$NewUser already exists" -ForegroundColor Red
        }
    Else
        {
        $Error.Exception
        }
    }