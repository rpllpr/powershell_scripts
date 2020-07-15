#region Script Info
<#
This script deletes the <remvoed>: drive (personal folder) from server <removed>:.
It creates a window and asks for the userID of the person to delete. 
It then gets prompts for admin credentials.
It will delete the folder under <removed> that matches the userID.

NOTE: sometimes you have to run the script twice to completely delete everything!
#>
#endregion

#region Change Log
<#
11/25/2015:
signed script and added regions/comments.. lpr;

#>
#endregion

#region Functions
function Read-InputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText) {     
    Add-Type -AssemblyName Microsoft.VisualBasic     
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText) 
    }
#endregion

#region Show input box popup and return the value entered by the user. 
$inputFromUser = Read-InputBoxDialog -WindowTitle "Delete <removed>: Drive" -Message "Enter the userID of the personal drive to be deleted"
#endregion

#region Ask for admin credentials
$cred = Get-Credential
#endregion

#region Invoke commands on <removed> to test for, then delete, the folder corresponding to the inputted userID
Invoke-Command -ComputerName <removed> -Credential $cred -Args $inputFromUser -ScriptBlock {
    param($inputFromUser)
    foreach ($oo in $inputFromUser) {
      if (Test-Path -Path <removed>\$oo) {
        Remove-Item -Path <removed>\$oo -Recurse -Force -Confirm
        }
    }
} 
#endregion
