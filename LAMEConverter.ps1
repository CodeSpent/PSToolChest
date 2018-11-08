#LAME audio convert for 
$InputPath = "S:\Upload\Services\Input"
$OutputPath = "S:\Upload\Services\Output"
$LAMEexe = "C:\Program Files (Personal)\lame3.100-64\lame.exe"
#[array]$InputFiles = Get-ChildItem $InputPath | Where {$_.extension -like ".wav"} | select -expand name
$InputFiles = Get-ChildItem -Path $InputPath -Recurse -Include *.wav | select -expand fullname
Foreach ($InputFile in $InputFiles)
    {
    Write-Host $InputFile
    Write-Host $OutputPath
    $OutputFile = $InputFile.split('\.')[-2]
        & $LAMEexe $InputFile $OutputPath\$OutputFile.mp3
    }