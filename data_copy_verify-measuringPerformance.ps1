
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
$referenceFolder = "D:\temp"
$differenceFolder = "D:\temp2"
$outputLogFolder = "D:\templog"
$outputLogNameFolderCompare = $null
$outputLogNameRobocopy = $null
#endregion

#region Check to see if source, destination, and output folders exist; exit script if they don't
if (!(Test-Path -Path $referenceFolder)) {
    Write-Output "The Source folder" $referenceFolder "does not exist.  Exiting script."
    exit
    }

if (!(test-path -Path $differenceFolder)) {
    write-Output "The Target folder" $differenceFolder "does not exist.  Exiting script."
    exit 
    }

if (!(test-path -Path $outputLogFolder)) {
    write-Output "The Output log folder" $outputLogFolder "does not exist.  Exiting script."
    exit
    }
#endregion

#region measuring where-object with sort-object

$getFileHashTime = (Measure-Command {
$ref = Get-ChildItem -Path $referenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path
$dif = Get-ChildItem -Path $differenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path


if ($referenceFolder.EndsWith("\")) {
    $referenceFolder=$referenceFolder.TrimEnd('\')
    }

if ($differenceFolder.EndsWith("\")) {
    $differenceFolder=$differenceFolder.TrimEnd('\')
    }



GetFileNameFolderCompare([ref]$outputLogNameFolderCompare)




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



$headerInfo = New-Object -TypeName PSObject
$headerInfo |Add-Member -NotePropertyName Path -NotePropertyValue None
$headerInfo |Add-Member -NotePropertyName Hash -NotePropertyValue " "
$headerInfo |Add-Member -NotePropertyName HashError -NotePropertyValue " " 
$headerInfo.Path = "where-object with sort" 
Export-Csv -NoTypeInformation -InputObject $headerInfo -Path $outputLogFolder\$outputLogNameFolderCompare




foreach ( $ref2item in $ref) {
    $difvalue = $dif|Where-Object {$_.relpath -eq $ref2item.relPath}
    #Write-Host "The refvalue is: " $ref2item
    #write-host "The difvalue is: " $difvalue
    #Write-Host "`n"
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

}).TotalMilliseconds
write-output "hashing with where-object and sort = " $getFileHashTime
#endregion

#region measuring where simple syntax with sort-object

$getFileHashTimeNS = (Measure-Command {
$ref = Get-ChildItem -Path $referenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path
$dif = Get-ChildItem -Path $differenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path


if ($referenceFolder.EndsWith("\")) {
    $referenceFolder=$referenceFolder.TrimEnd('\')
    }

if ($differenceFolder.EndsWith("\")) {
    $differenceFolder=$differenceFolder.TrimEnd('\')
    }

GetFileNameFolderCompare([ref]$outputLogNameFolderCompare)

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

$headerInfo = New-Object -TypeName PSObject
$headerInfo |Add-Member -NotePropertyName Path -NotePropertyValue "Where with simple syntax"
$headerInfo |Add-Member -NotePropertyName Hash -NotePropertyValue " "
$headerInfo |Add-Member -NotePropertyName HashError -NotePropertyValue " " 
Export-Csv -NoTypeInformation -InputObject $headerInfo -Path $outputLogFolder\$outputLogNameFolderCompare

foreach ( $ref2item in $ref) {
    
    $difvalue = $dif |Where relpath -eq $ref2item.relPath
    #($difvalue).Where({$_.relpath -eq $ref2item.relPath})

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

}).TotalMilliseconds

write-output "hashing where simplified syntax with sort = " $getFileHashTimeNS

#endregion

#region measuring foreach nested with sort-object

$getFileHashTimeNS = (Measure-Command {
$ref = Get-ChildItem -Path $referenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path
$dif = Get-ChildItem -Path $differenceFolder -Recurse -Force| get-filehash -Algorithm MD5 |Sort-Object Path


if ($referenceFolder.EndsWith("\")) {
    $referenceFolder=$referenceFolder.TrimEnd('\')
    }

if ($differenceFolder.EndsWith("\")) {
    $differenceFolder=$differenceFolder.TrimEnd('\')
    }

GetFileNameFolderCompare([ref]$outputLogNameFolderCompare)

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

$headerInfo = New-Object -TypeName PSObject
$headerInfo |Add-Member -NotePropertyName Path -NotePropertyValue "nested foreach syntax"
$headerInfo |Add-Member -NotePropertyName Hash -NotePropertyValue " "
$headerInfo |Add-Member -NotePropertyName HashError -NotePropertyValue " " 
Export-Csv -NoTypeInformation -InputObject $headerInfo -Path $outputLogFolder\$outputLogNameFolderCompare

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

}).TotalMilliseconds

write-output "hashing foreach nested with sort = " $getFileHashTimeNS

#endregion