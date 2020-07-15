#region Script Info
<#

This file will copy (not move) files from one folder to another.  
It will then create log files to record what was copied.

Run this script from the archive server using the interactive Powershell window.  
Make sure you have a mapped drive to all directories: source, target, and output. UNC paths don't work.

NOTE: this script will not delete from the source folder, by design.  That should be done manually
once all logs are checked.

# Definitions:
# - Source directory is the folder to be archived
# - Source File is the file to be archived (if the entire folder is not being archived).
# - Target directory is the main folder used to hold all archived data for a quarter.  For instance, when ran from the <removed> server, the target folder during the 3rd quarter of 2015 would be <removed>:\2015-q3\study.  
# - Archive directory is created under the target directory.  This folder will store all archive data from one work order for one study.  The name format is <StudyNumber-TrackItNumber>.
# - Numbered Subfolder is an auto-generated folder, starting with '0', that is used to archive data from a specific location.  Since an archive request for one study can contain multiple source directories from different systems, this was created to store those source directories separately.
# - Output directory is the directory where the log files will be created.  I use my <removed>: drive for this, you can use anything that can be reached by this script.
#>
#endregion



#region 1 Ask for info from console, store in variables

$studyNumber = Read-Host "Enter Study Number"
$trackitWO = Read-Host "Enter TrackIt Work Order Number"
$sourceDirectory = Read-Host "Enter Source Path"
####
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $true # Multiple files can be chosen
	# Filter = 'Images (*.jpg, *.png)|*.jpg;*.png' # Specified file types
}
$FileBrowser.initialDirectory = $sourceDirectory
[void]$FileBrowser.ShowDialog()
$sourceDirectoryFiles = $FileBrowser.FileNames;
if (!$sourceDirectoryFiles) {
	write-output "No files selected.  Exiting script."
	exit
	}
####
$targetDirectory = Read-Host "Enter Target Path"
$outputDirectory = Read-Host "Enter Output path for log files"
#endregion



#region 2 Check if paths exist.  If they don't exist, exit script.

if (!(Test-Path -Path $sourceDirectory)) {
    Write-Output "The Source path" $sourcedirectory "does not exist.  Exiting script."
    exit
    }
if (!(test-path -Path $targetdirectory)) {
    write-output "The Target path" $targetDirectory "does not exist.  Exiting script."
    exit 
    }
if (!(test-path -Path $outputDirectory)) {
    write-output "The Output files path" $outputDirectory "does not exist.  Exiting script."
    exit
    }
Write-Output "`nAll paths exist! Proceeding to source output file creation..."
#endregion




#region 3 Check for existing Archive folder under target folder.  create Archive folder if needed. 

if (!(test-path -Path $targetDirectory\$studyNumber-WO$trackitwo)) {
    New-Item $targetDirectory\$studynumber-WO$trackitwo -ItemType directory
    }
#endregion




#region 4 Check for Numbered Subfolder under Archive folder. loop until it doesn't exist, then create it

<# Notes
The purpose of this section is to create subfolders for every system that needs to be archived 
per the study and work order.  We often receive work orders that have multiple systems to be archived
for one study; by putting each system's data in its own folder, I ensure the data doesn't comingle with other 
systems and can be restored easier.
#>
$i=0
while (test-path -Path $targetDirectory\$studyNumber-WO$trackitwo\$i) {
    $i++
    }
New-Item $targetDirectory\$studyNumber-WO$trackitwo\$i -ItemType directory
#endregion




#region 5 Assign entire destination path to $fullTargetDirectory variable.

$fullTargetDirectory = $targetDirectory + "\" + $studyNumber + "-WO" + $trackitwo + "\" + $i
#endregion





#region 7 Copy files from source to $fullTargetDirectory.  Get size of each source file and pipe to a text file.

net use >> $outputDirectory\$studynumber-WO$trackitwo-$i-source.txt
Get-ChildItem $SourceDirectoryFiles -Force | Measure-Object -Property Length -Sum >> $outputDirectory\$studynumber-WO$trackitwo-$i-source.txt
New-Item $fullTargetdirectory\data -ItemType directory    
foreach($file in $sourceDirectoryFiles) {
    Copy-Item -path $file -Destination $fullTargetdirectory\data -Force
    Get-ChildItem $file -Force >> $outputDirectory\$studynumber-WO$trackitwo-$i-source.txt
	}
Write-Output "`nSource output file created and files copied..."
#endregion




#region 8 Get number and size of $fullTargetDirectory folder, list all files/folders in $fullTargetDirectory, and pipe to text file.
net use >> $outputDirectory\$studynumber-WO$trackitwo-$i-destination.txt
Get-ChildItem $fullTargetDirectory -Recurse -Force | Measure-Object -Property Length -Sum >> $outputDirectory\$studynumber-WO$trackitwo-$i-destination.txt
Get-ChildItem $fullTargetDirectory -Recurse -Force >> $OutputDirectory\$studynumber-WO$trackitwo-$i-destination.txt
Write-Output "`nFiles copied and target output file created.  Please verify successful copy before deleting source files.`n"
#endregion




#region 9 Copy output files to $fulltargetDirectory
Copy-Item -path $outputDirectory\$studyNumber-WO$trackitwo-$i-source.txt -Destination $fullTargetDirectory
Copy-Item -path $outputDirectory\$studyNumber-WO$trackitwo-$i-destination.txt -Destination $fullTargetDirectory
#endregion




#region 10 Copy output files to e:\archive_logs
Copy-Item -path $outputDirectory\$studyNumber-WO$trackitwo-$i-source.txt -Destination e:\archive_logs
Copy-Item -path $outputDirectory\$studyNumber-WO$trackitwo-$i-destination.txt -Destination e:\archive_logs
#endregion




#region 11 Check for 'archive.txt' file.  create 'archive.txt' file and place in source folder if necessary.
if (!(test-path -Path $sourceDirectory\archive.txt)) {
    Write-Output "`nCreating archive.txt file in source path."
    New-Item $sourceDirectory\archive.txt -ItemType File
    }
#endregion




#region 12 Add date and archive information to 'archive.txt' file.
$gDate = Get-Date -Format F
$gDate = "${gDate}:" 
Add-Content $sourceDirectory\archive.txt $gDate
Add-Content $sourceDirectory\archive.txt "Study $studyNumber data archived per TrackIt work order $trackitwo."
Add-Content $sourceDirectory\archive.txt "`n"
#endregion




#region 13 Open source and destination output files in Notepad.
notepad $outputDirectory\$studynumber-WO$trackitwo-$i-source.txt
notepad $OutputDirectory\$studynumber-WO$trackitwo-$i-destination.txt
#endregion

