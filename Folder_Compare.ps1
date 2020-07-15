#region Script Information
<#
The script compares the files between two folders and logs to a CSV file:
It gets a full listing from both source and destination folder,
generates a hash for each file in each location,
then creates a CSV file that lists the hash of each file and 
notes if they don't match or if the source file isn't found in the 
destination location.
#>
#endregion

#region Change Log
<#
11/25/2015: 
specified MD5 for the filehash algorithm instead of using the default SHA256;
signed the code;
  
#>
#endregion

#region Functions
Function GetFileName([ref]$outputLogName) {
    $invalidChars = [io.path]::GetInvalidFileNamechars() 
    $date = Get-Date -format s
    $outputLogName.value = "Folder_compare_" + ($date.ToString() -replace "[$invalidChars]","-") + ".csv"
    }

Function Read-InputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText) {     
    Add-Type -AssemblyName Microsoft.VisualBasic     
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText) 
    }
#endregion

#region Ask for source, destination, and output log folders. 
$referenceFolder = Read-InputBoxDialog -WindowTitle "Folder Compare" -Message "Enter the source folder to compare:"
$differenceFolder = Read-InputBoxDialog -WindowTitle "Folder Compare" -Message "Enter the destination folder to compare:"
$outputLogFolder = Read-InputBoxDialog -WindowTitle "Folder Compare" -Message "Enter the folder to send the output log to:"
#endregion

#region Check to see if source, destination, and output folders exist, exit script if they don't
if (!(Test-Path -Path $referenceFolder)) {
    Write-Output "The Source folder" $referenceFolder "does not exist.  Exiting script."
    pause
    exit
    }

if (!(test-path -Path $differenceFolder)) {
    write-output "The Target folder" $differenceFolder "does not exist.  Exiting script."
    pause
    exit 
    }

if (!(test-path -Path $outputLogFolder)) {
    write-output "The Output log folder" $outputLogFolder "does not exist.  Exiting script."
    pause
    exit
    }
#endregion

#region Get source and destination files, get a filehash, then sort on Path name
$ref = Get-ChildItem -Path $referenceFolder -Recurse -Force| get-filehash -Algorithm MD5|Sort-Object Path
$dif = Get-ChildItem -Path $differenceFolder -Recurse -Force| get-filehash -Algorithm MD5|Sort-Object Path
#endregion

#region Check for trailing backslash and remove it if it exists
if ($referenceFolder.EndsWith("\")) {
    $referenceFolder=$referenceFolder.TrimEnd('\')
    }
if ($differenceFolder.EndsWith("\")) {
    $differenceFolder=$differenceFolder.TrimEnd('\')
    }
#endregion

#region create output log file name based on current date
$outputLogName = $null
GetFileName([ref]$outputLogName)
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
Export-Csv -NoTypeInformation -InputObject $headerInfo -Path $outputLogFolder\$outputLogName
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
    $ref2item | Select-Object Path,Hash,HashError | Export-Csv -Append -NoTypeInformation -Path $outputLogFolder\$outputLogName
    $difvalue | Select-Object Path,Hash,HashError | Export-Csv -Append -NoTypeInformation -Path $outputLogFolder\$outputLogName
    }
#endregion

# SIG # Begin signature block
# MIIHqgYJKoZIhvcNAQcCoIIHmzCCB5cCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeIpIpEQFdnbvy+SoP/qiGUL0
# AlagggWfMIIFmzCCBIOgAwIBAgIKeK5UcAAAAAAAkzANBgkqhkiG9w0BAQUFADBH
# MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHYWJjbGFiczEX
# MBUGA1UEAxMOYWJjbGFicy1EQzEtQ0EwHhcNMTUxMTI0MTg0NjE5WhcNMTYxMTIz
# MTg0NjE5WjB8MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH
# YWJjbGFiczESMBAGA1UECxMJQUJDIFVzZXJzMREwDwYDVQQLEwhDb2x1bWJpYTEO
# MAwGA1UECxMFUGlsb3QxFTATBgNVBAMTDFJob2FkcywgUGF1bDCBnzANBgkqhkiG
# 9w0BAQEFAAOBjQAwgYkCgYEAsHQe/MyS5LlSJ4p20a3iOWMweb6EgmzBGyGA0O4h
# rkZ/7ov86jDa992OaMgQCSBy2PkUBRrARBK4SbIYAe8OdBfFlJGF12gvWYBZCpwX
# 3Z6+y6MByyUXToQpe8mwD0ard2Z1xLLwIOzgD7Z7FEIbrvgmzz6TEU53cF4vm4eh
# l+8CAwEAAaOCAtYwggLSMCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBu
# AGkAbgBnMBMGA1UdJQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAdBgNVHQ4E
# FgQUIRV5HBHH6+qWUY8DvTL6thw9pHQwHwYDVR0jBBgwFoAUbkzZbbz/GyTgTkuW
# Tus/lcHUpRYwgf4GA1UdHwSB9jCB8zCB8KCB7aCB6oaBsWxkYXA6Ly8vQ049YWJj
# bGFicy1EQzEtQ0EsQ049REMxLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2
# aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFiY2xhYnMsREM9
# Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1j
# UkxEaXN0cmlidXRpb25Qb2ludIY0aHR0cDovL2RjMS5hYmNsYWJzLmNvbS9DZXJ0
# RW5yb2xsL2FiY2xhYnMtREMxLUNBLmNybDCCARQGCCsGAQUFBwEBBIIBBjCCAQIw
# ga0GCCsGAQUFBzAChoGgbGRhcDovLy9DTj1hYmNsYWJzLURDMS1DQSxDTj1BSUEs
# Q049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmln
# dXJhdGlvbixEQz1hYmNsYWJzLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTBQBggrBgEFBQcwAoZEaHR0
# cDovL2RjMS5hYmNsYWJzLmNvbS9DZXJ0RW5yb2xsL0RDMS5hYmNsYWJzLmNvbV9h
# YmNsYWJzLURDMS1DQS5jcnQwLgYDVR0RBCcwJaAjBgorBgEEAYI3FAIDoBUME3Jo
# b2Fkc3BAYWJjbGFicy5jb20wDQYJKoZIhvcNAQEFBQADggEBAE1u31XtY2sFJS0n
# F/8ZsXKbKWZmdEUCmjj2V/abjlcUrCM/cos6qUys7vo5RJioNBa/nOCksHkPGsp8
# zeesVF99IVVopizkLipsLR7mQ4COf5VJ4IzceybBL9zt/Ip33R7XXh2yWohtMsP7
# R9y9TE4lM3kWYDacd2uMQGg8rhDXJpdEmfZTX3ZD43uez3+nM4fk5yxDUdBNyxrJ
# JviysU+uhDIaurwVohQK+HzZQnexadz1pd0j+FhAUNQYqIgWGn6RGnkSQeL3QkO2
# Ni+AummPCMQf7czPcZveKMrMihkCbTRCKNr8Izru00xERiAUFRxs4vrRehXcYkJ1
# xAZVwNkxggF1MIIBcQIBATBVMEcxEzARBgoJkiaJk/IsZAEZFgNjb20xFzAVBgoJ
# kiaJk/IsZAEZFgdhYmNsYWJzMRcwFQYDVQQDEw5hYmNsYWJzLURDMS1DQQIKeK5U
# cAAAAAAAkzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUa7IeS86xmVu3ywHcq4uVJgL8RM0wDQYJ
# KoZIhvcNAQEBBQAEgYCcPIjJWYmxAAxDuJW2DFtsPg8PVArTSVLZxnEhequ9iQI5
# KPQ/JyzxYFPkRKE6Tus4/TX6xcU1ijojVdnSPfkaq24qxeuhfD2M0Qgi1tltE5tK
# 7y884urADsiKrVpXOPZMULcndlDEVckbVfsiAqBnJ948HEYK/fh65oiRxuSyAw==
# SIG # End signature block
