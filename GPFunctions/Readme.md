# GPO Consolidation Redux #
Finally! Copy and merge GPOs! PowerShell saves the day! As I have said before..

## Fixes and Features ##
This version of the script includes the following fixes and features:

* All functions compatible on PowerShell v2.0 for Windows Server 2008 R2.
* Recursive infinite loop identified and fixed.
* Specify multiple source GPOs.
* Dynamically create the destination GPO if it does not exist.
* Verbose logging for every setting copied.
* Warnings for settings that get over-written, showing both old and new values.
* Warnings for settings that fail copying (usually the Disable/Delete type).
* Warnings for non-registry settings that need manual copy.
* Warning if source policy is not found.
* Helper functions for identifying linked and unlinked GPOs.
* Progress bar.
* Nice list.

## Show me some ‘Shell ##
This script file contains three functions:

* **Get-GPLink** – Detailed link report for GPOs, including enabled/disabled, enforced, block inheritance, WMIFilter, date created, date modified, version numbers, and more. This is based off of another GPO report that I did, but I removed the PowerShell v3 cmdlets for Windows Server 2008 R2 compatibility. This report only includes GPOs that are linked in the environment.
* **Get-GPUnlinked** – This is similar to the Get-GPLink report, but it includes unlinked GPOs and a simplified Linked property for reporting.
* **Copy-GPRegistryValue** – This function is the heart of the script, and it is a 99% rewrite of the previous version. See the bullet list above for the features list.

See the sample code below for using them.  Read through the comments to understand the scenarios enabled by these functions.

See the remaining documentation for this script here: http://blogs.technet.com/b/ashleymcglone/archive/2015/06/11/updated-copy-and-merge-group-policies-gpos-with-powershell.aspx

# Sample usage 

```powershell
# Help 
Help Get-GPLink -Full 
Help Get-GPUnlinked -Full 
Help Copy-GPRegistryValue -Full 
 
# Copy one GPO registry settings into another 
Copy-GPRegistryValue -Mode All -SourceGPO 'Client Settings' ` 
    -DestinationGPO 'New Merged GPO' -Verbose 
 
# Copy one GPO registry settings into another, just user settings 
Copy-GPRegistryValue -Mode User -SourceGPO 'Client Settings' ` 
    -DestinationGPO 'New Merged GPO' -Verbose 
 
# Copy one GPO registry settings into another, just computer settings 
Copy-GPRegistryValue -Mode Computer -SourceGPO 'Client Settings' ` 
    -DestinationGPO 'New Merged GPO' -Verbose 
 
# Copy multiple GPO registry settings into another 
Copy-GPRegistryValue -Mode All  -DestinationGPO "NewMergedGPO" ` 
    -SourceGPO "Firewall Policy", "Starter User", "Starter Computer" -Verbose 
 
# Copy all GPOs linked to one OU registry settings into another 
# Sort in reverse precedence order so that the highest precedence settings overwrite 
# any potential settings conflicts in lower precedence policies. 
$SourceGPOs = Get-GPLink -Path 'OU=SubTest,OU=Testing,DC=CohoVineyard,DC=com' | 
    Sort-Object Precedence -Descending | 
    Select-Object -ExpandProperty DisplayName 
Copy-GPRegistryValue -Mode All -SourceGPO $SourceGPOs ` 
    -DestinationGPO "NewMergedGPO" -Verbose 
 
# Log all GPO copy output (including verbose and warning) 
# Requires PowerShell v3.0+ 
Copy-GPRegistryValue -Mode All -SourceGPO 'IE Test' ` 
    -DestinationGPO 'New Merged GPO' -Verbose *> GPOCopyLog.txt 
 
# Disable all GPOs linked to an OU 
Get-GPLink -Path 'OU=SubTest,OU=Testing,DC=CohoVineyard,DC=com' | 
    ForEach-Object { 
        Set-GPLink -Target $_.OUDN -GUID $_.GUID -LinkEnabled No -Confirm 
    } 
 
# Enable all GPOs linked to an OU 
Get-GPLink -Path 'OU=SubTest,OU=Testing,DC=CohoVineyard,DC=com' | 
    ForEach-Object { 
        Set-GPLink -Target $_.OUDN -GUID $_.GUID -LinkEnabled Yes -Confirm 
    } 
 
# Quick link status of all GPOs 
Get-GPUnlinked | Out-Gridview 
 
# Just the unlinked GPOs 
Get-GPUnlinked | Where-Object {!$_.Linked} | Out-GridView 
 
# Detailed GP link status for all GPO with links 
Get-GPLink | Out-GridView 
 
# List of GPOs linked to a specific OU (or domain root) 
Get-GPLink -Path 'OU=SubTest,OU=Testing,DC=CohoVineyard,DC=com' | 
    Select-Object -ExpandProperty DisplayName 
 
# List of OUs (or domain root) where a specific GPO is linked 
Get-GPLink | 
    Where-Object {$_.DisplayName -eq 'Script And Delegation Test'} | 
    Select-Object -ExpandProperty OUDN 
```
