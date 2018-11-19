# PSToolChest
PowerShell ToolChest
Just a repo of all my PowerShell scripts that are either a Work In Progress, or completed.

# Dell Folder:
 # LifeCycleControllerStatusCheck.ps1
 This script takes an existing .txt file with a list of iDRACs from at least Dell PowerEdge Generation 11 (I believe) and up, and checks the LifeCycle Controller status, and outputs the IP address scanned, the Controller Attribute type, and the current status (Enabled, Recovery, Disabled) to a .csv file.
 This script has error handling as well, in case an iDRAC is offline for some reason, doesn't have the standard credentials, or if you have a mixed environment where not all servers have a LifeCycle controller (maybe in the middle of an upgrade?)

# LAMEConverter:
  This script uses the LAME (lame3.100-64, found here: https://sourceforge.net/projects/lame/files/lame/) encoder to convert WAV to .mp3 files. The script defaults to 96Kbps, but can be easily changed by changing the BitRate value on line 9 to something else. You will likely need to modify the program's location, but editing the "LAMEexe" value, on line 6.
  Personally, I have this set up to work with "TheFolderSpy" to watch a specific folder. When the file "DeleteMeWhenReady.txt" is deleted, this script executes. When it's done, it recreates the "trigger" file, which arms TheFolderSpy again. TheFolderSpy can be found: (http://venussoftcorporation.blogspot.com/2010/05/thefolderspy.html)
  
  # Server-LocalAdmin-AddUsersToServers.ps1:
    This will add multiple users to the local administrators group on multiple servers. I'm working on making this be able to read from a .csv file, but because this script currently works for what I need it to, I've stashed that part away for a rainy day. Feel free to contribute, if you'd like.
