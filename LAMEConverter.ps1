#LAME audio converter that converts basically any audio to MP3 format.
#More info on LAME commands can be found here: http://ecmc.rochester.edu/ecmc/docs/lame/switchs.html

$WorkingDir = "S:\Upload\Services"
$InputPath = "$WorkingDir\Input"
$OutputPath = "$WorkingDir\Output"
$LAMEexe = "C:\Program Files (Personal)\lame3.100-64\lame.exe"
$LogFile = "$OutputPath\wavToMP3.log"
$InputFiles = Get-ChildItem -Path $InputPath -Recurse -Include *.wav | select -expand fullname
$BitRate = "96"
Function WavToMP3Convert
{
    <#Param (
    $InputPath, 
    $OutputPath, 
    $OutputFile, 
    $LAMEexe, 
    $LogFile, 
    $InputFiles, 
    $CurrentDate
    )#>
    Write-Host "This is inside the WavToMP3Convert Function" -ForegroundColor Yellow
    Foreach ($InputFile in $InputFiles)
    {
        Write-Host $InputFile
        Write-Host $OutputPath
        $OutputFile = $InputFile.split('\.')[-2]
            & $LAMEexe $InputFile $OutputPath\$OutputFile.mp3 -b $BitRate
        LogWrite $LogFile $CurrentDate $InputFile $OutputFile
    }
}
Function LogWrite
{
  <#Param (
   $LogFile, 
   $CurrentDate, 
   $OutputFile)#>
   BuildDates
   Add-content -Path $Logfile -value "On $CurrentDate, file $OutputFile was converted."
}
Function BuildDates
{
    $script:CurrentDate = Get-Date
    $script:CurrentDate = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
}
WavToMP3Convert
New-Item -ItemType "file" -Path $InputPath\DeleteMeWhenReady.txt