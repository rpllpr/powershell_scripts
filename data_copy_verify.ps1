#region Script Info
<#
This script does a Robocopy of data from <removed>: drive to the <removed>: drive using the Mirror option.  
This file is scripted to run on server <removed>.  

After the copy is done, it will create a hash of each file and compare between source and 
destination folders, generating a CSV containing each file comparison.

#>
#endregion



#region Functions
Function GetFileNameFolderCompare([ref]$outputLogNameFolderCompare) {
    $invalidChars = [io.path]::GetInvalidFileNamechars() 
    $date = Get-Date -format s
    $outputLogNameFolderCompare.value = "Folder_compare_" + ($date.ToString() -replace "[$invalidChars]","-") + ".csv"
    }

Function GetFileNameRobocopy([ref]$outputLogNameRobocopy) {
    $invalidChars = [io.path]::GetInvalidFileNamechars() 
    $date = Get-Date -format s
    $outputLogNameRobocopy.value = "Robocopy_" + ($date.ToString() -replace "[$invalidChars]","-") + ".log"
    }

Function Read-InputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText) {     
    Add-Type -AssemblyName Microsoft.VisualBasic     
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText) 
    }
#endregion

#region Variables 
$referenceFolder = "<enter folder name and path>"
$differenceFolder = "<enter folder name and path>"
$outputLogFolder = "<enter folder name and path>"
$outputLogNameFolderCompare = $null
$outputLogNameRobocopy = $null
#endregion

#region Check to see if source, destination, and output folders exist; exit script if they don't
if (!(Test-Path -Path $referenceFolder)) {
    Write-Output "The Source folder" $referenceFolder "does not exist.  Exiting script."
    exit
    }

if (!(test-path -Path $differenceFolder)) {
    write-output "The Target folder" $differenceFolder "does not exist.  Exiting script."
    exit 
    }

if (!(test-path -Path $outputLogFolder)) {
    write-output "The Output log folder" $outputLogFolder "does not exist.  Exiting script."
    exit
    }
#endregion

#region Perform Robocopy from source folder to destination folder using Mirror option
GetFileNameRobocopy([ref]$outputLogNameRobocopy)
robocopy $referenceFolder $differenceFolder /MIR /LOG:$outputLogFolder\$outputLogNameRobocopy
#endregion

#region Get listing of source and destination files, get a filehash, then sort on Path name
$ref = Get-ChildItem -Path $referenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path
$dif = Get-ChildItem -Path $differenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path
#endregion

#region Check for trailing backslash and remove it if it exists
<#
I do this so the the folder information is consistent
#>
if ($referenceFolder.EndsWith("\")) {
    $referenceFolder=$referenceFolder.TrimEnd('\')
    }

if ($differenceFolder.EndsWith("\")) {
    $differenceFolder=$differenceFolder.TrimEnd('\')
    }
#endregion

#region Call function to create Folder Compare output log file name based on current date
GetFileNameFolderCompare([ref]$outputLogNameFolderCompare)
#endregion

#region Create new properties for each object in the collections
<#
The section creates two new properties for each object in the "$ref" and "$dif" collections. 
The new properties are "relPath" and "HashError". 
 
For relPath: I'm taking the absolute file path found in the Path property for each object in both collections, 
then finding the number of characters in the $referenceFolder/$differenceFolder (as applicable) variables,  
subtracting that from the beginning of that absolute file path and storing it in "relPath".
As a result, only the relative path should remain in "relPath" property, and the source and 
destination objects for each file should have matching "relPath" properties.  
#>

foreach ( $refitem in $ref ) { 
    Add-Member -NotePropertyName relPath -NotePropertyValue None -InputObject $refitem
    Add-Member -NotePropertyName HashError -NotePropertyValue "-" -InputObject $refitem
    $refitem.relPath = $refitem.Path.Substring($referenceFolder.Length)  
    #Write-Host "The refitem is: " $refitem 
    }

foreach ( $difitem in $dif) {
    Add-Member -NotePropertyName relPath -NotePropertyValue None -InputObject $difitem
    Add-Member -NotePropertyName HashError -NotePropertyValue "-" -InputObject $difitem
    $difitem.relPath = $difitem.Path.Substring($differenceFolder.Length)  
    #Write-Host "The difitem is: " $difitem
    }
#endregion

#region Add some info to the first line of the CSV file being generated
$headerInfo = New-Object -TypeName PSObject
$headerInfo |Add-Member -NotePropertyName Path -NotePropertyValue None
$headerInfo |Add-Member -NotePropertyName Hash -NotePropertyValue " "
$headerInfo |Add-Member -NotePropertyName HashError -NotePropertyValue " " 
$headerInfo.Path = "Source Folder: " + $referenceFolder + "; Destination Folder: " + $differenceFolder 
Export-Csv -NoTypeInformation -InputObject $headerInfo -Path $outputLogFolder\$outputLogNameFolderCompare
#endregion

#region Compare objects in the $ref and $dif collections, write to CSV
<# 
This region finds the $dif object that matches the $ref object. 
Then it checks to see if there is a matching object in the $dif collection.
If not, it writes an error to the HashError property of the $ref object.
It then checks to see if the Hash values match for each matching $ref <-> $dif object.
If not, it writes another error to the HashError property for both $ref and $dif objects.
It then writes the objects to a CSV file.
#>

foreach ( $ref2item in $ref) {
  
    $difvalue=$null
    foreach ($dif2item in $dif) {
        if ($dif2item.relPath -eq $ref2item.relpath) {
            $difvalue = $dif2item
            }
        }
        
    if (!$difvalue) {
        $ref2item.HashError = "No destination file found!"
        }

    if (($ref2item.Hash -ne $difvalue.Hash) -and ($ref2item.HashError -ne "No destination file found!")) {
        $ref2item.HashError = "The hash is different!"
        $difvalue.HashError = "The hash is different!"
        }

    $ref2item | Select-Object Path,Hash,HashError | Export-Csv -Append -NoTypeInformation -Path $outputLogFolder\$outputLogNameFolderCompare
    $difvalue | Select-Object Path,Hash,HashError | Export-Csv -Append -NoTypeInformation -Path $outputLogFolder\$outputLogNameFolderCompare
    }
#endregion
