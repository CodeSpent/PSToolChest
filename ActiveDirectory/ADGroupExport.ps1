Import-Module ActiveDirectory
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$ExportPath = "C:\Temp"
If (Test-Path $ExportPath -ErrorAction Stop)
    {
    $Group = Read-Host "What group are you looking to export?"
    $ExportFile = $Group, "$CurrentDate.csv" -join ", "
    Try {
        $Members = Get-ADGroupMember -Identity “$Group” -Recursive
        $Members = $Members | select name
        $Members = $Members | Export-Csv -Path $ExportPath\$ExportFile -NoTypeInformation
        Write-Host = "CSV exported to $ExportPath\$ExportFile"
        }
    Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
        Write-Host "Group: $Group doesn't exist. Please check your typing/spelling" -ForegroundColor Yellow
        }
    }
Else
    {
    Write-Host "ExportPath: $ExportPath is not found. Either modify the value, or create the directory" -ForegroundColor Yellow
    }