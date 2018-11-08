#LAME audio convert for 
$InputPath = "S:\Upload\Services\Input"
$OutputPath = "S:\Upload\Services\Output"
$LAMEexe = "C:\Program Files (Personal)\lame3.100-64\lame.exe"
$LogFile = "$OutputPath\wavToMP3.log"
$InputFiles = Get-ChildItem -Path $InputPath -Recurse -Include *.wav | select -expand fullname
Function WavToMP3Convert
    {
    Param ($InputPath, $OutputPath, $OutputFile, $LAMEexe, $LogFile, $InputFiles, $CurrentDate)
    Foreach ($InputFile in $InputFiles)
        {
        Write-Host $InputFile
        Write-Host $OutputPath
        $OutputFile = $InputFile.split('\.')[-2]
            & $LAMEexe $InputFile $OutputPath\$OutputFile.mp3
        LogWrite
        }
    }
Function LogWrite
{
   Param ($LogFile, $CurrentDate, $InputFile)
   BuildDates
   Write-Host "BuildDates Function Being called" -ForegroundColor Yellow
   Add-content $Logfile -value "On $CurrentDate, file $InputFile was converted."
}
Function BuildDates
{
    Write-Host
    $CurrentDate = Get-Date
    $CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
}
Write-Host "Starting" -ForegroundColor Yellow
WavToMP3Convert
Write-Host "WavToMP3Convert was called" -ForegroundColor Yellow