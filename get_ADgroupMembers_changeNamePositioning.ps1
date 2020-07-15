Get-ADGroupMember <removed AD group name> -recursive | select -Property name | 
foreach {
$_.name = "{1}, {0}" -f ($_.name -split ', ') 
$_.name -replace ",", ""
} 
Out-File -FilePath <removed file name and path>.csv
