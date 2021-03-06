<#-----------------------------------------------------------------------------
Example code for
SID History PowerShell Toolkit v1.5
Ashley McGlone, Microsoft Premier Field Engineer
http://blogs.technet.com/b/ashleymcglone
July, 2013

LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
-----------------------------------------------------------------------------#>
break

Set-Location C:\Users\administrator.COHOVINEYARD\Documents\SIDHistory

# Import the modules
Import-Module SIDHistory -Force

# List the cmdlets and help
# Read through all of the help for good background information.
Get-Command -Module SIDHistory
Get-Help Get-SIDHistory -Full
Get-Command -Module SIDHistory | Get-Help -Full | More

# Export the core SID history data files
Export-DomainSIDs
Export-SIDMapping
Update-SIDMapping

# Scan all share permissions on a Windows server
Export-SIDHistoryShare CVMEMBER1

# Scan a Windows or NAS share path for NTFS SID history
Convert-SIDHistoryNTFS "\\CVMEMBER1\Share1" –WhatIf

### Add switch examples
# List everything as-is
Convert-SIDHistoryNTFS -StartPath \\cvdc1\share1 -WhatIf
# ---OR---
Convert-SIDHistoryNTFS -StartPath \\cvdc1\share1 -WhatIf -Add

# Append new SIDs beside old SID history entries
Convert-SIDHistoryNTFS -StartPath \\cvdc1\share1 -Add

# Replace the old SID history entries with new SID entries
# Default behavior is REPLACE
Convert-SIDHistoryNTFS -StartPath \\cvdc1\share1


# Get a list of shares on a Windows server
Get-WmiObject Win32_Share -ComputerName CVMEMBER1 |
    Select-Object * |
    Out-GridView

# Sample code to scan a group of Windows servers in a text file.
$Servers = Get-Content ".\servers.txt"
ForEach ($ComputerName in $Servers) {
    Export-SIDHistoryShare $ComputerName
    # Grab only file shares that were manually created
    $Shares = Get-WmiObject Win32_Share -ComputerName $ComputerName -Filter "Type=0"
    ForEach ($Share in $Shares) {
        Convert-SIDHistoryNTFS "\\$ComputerName\$($Share.Name)" -WhatIf
    }
}

# Sample code to scan a list of share paths in a text file.
# This can work for Windows or NAS servers.
$Shares = Get-Content ".\shares.txt"
ForEach ($Share in $Shares) {
    Convert-SIDHistoryNTFS $Share -WhatIf
}

# Now merge all of the output into a single CSV file for analysis.
# This will roll all of the NTFS and Share SID history inventory data
# into a single CSV file.

# Manually copy all Share and NTFS CSV output files into a working folder.
Merge-CSV -Path "C:\Temp\WorkingFolder"

# Copy these two files to the folder with the sample Access database
#   SIDReportUpdated.csv
#   ACL_SID_History_xxxxxxxxxxxxxxxx.csv
# Rename ACL_SID_History_xxxxxxxxxxxxxxxx.csv to ACL_SID_History.csv
# Update the linked tables in Access with these files.


# Use function to automate all of the share and NTFS scans
Search-SIDHistoryACL -OrganizationalUnit 'ou=servers,dc=cohovineyard,dc=com'
Watch-Job -Remove
.\joblog.csv
.\joblog.txt

# Use function to automate all of the share and NTFS scans
Search-SIDHistoryACL -ShareFile .\shares.txt -Credential (Get-Credential)
Watch-Job -Remove
.\joblog.csv
.\joblog.txt


# Query for SID history and remove it selectively
Get-SIDHistory –MemberOf Legal
Get-SIDHistory –DomainName tailspintoys.local
Get-SIDHistory –SamAccountName bjrettig
Get-SIDHistory –SamAccountName bjrettig –DomainName tailspintoys.local
#Get-SIDHistory –SamAccountName bjrettig | Remove-SIDHistory


# Export-SIDMappingCustom
#   SID mapping without SID history
Get-ADUser -LDAPFilter '(name=a*)' -Properties objectSID, samAccountName -Server wingtiptoys.local |
 Select-Object objectSID, samAccountName |
 Export-CSV .\WT_users.csv -NoTypeInformation

Get-ADUser -LDAPFilter '(name=a*)' -Properties objectSID, samAccountName -Server cohovineyard.com |
 Select-Object objectSID, samAccountName |
 Export-CSV .\CV_users.csv -NoTypeInformation

Get-Content .\WT_users.csv
Get-Content .\CV_users.csv

Get-Content .\WT_users.csv | Measure-Object
Get-Content .\CV_users.csv | Measure-Object

# Match against two CSV files
Export-SIDMappingCustom -ObjectType User -Property samAccountName -OldCSV .\WT_users.csv -NewCSV .\CV_users.csv -MapFile WT_CV_Map.csv
Get-Content .\WT_CV_Map.csv
Get-Content .\WT_CV_Map.csv | Measure-Object

# Match old CSV, new live DC
Export-SIDMappingCustom -ObjectType User -Property samAccountName -OldCSV .\WT_users.csv -NewServer cohovineyard.com -MapFile WT_CV_Map2.csv
Get-Content .\WT_CV_Map2.csv
Get-Content .\WT_CV_Map2.csv | Measure-Object

# Match new CSV, old live DC
Export-SIDMappingCustom -ObjectType User -Property samAccountName -OldServer wingtiptoys.local -NewCSV .\CV_users.csv -MapFile WT_CV_Map3.csv
Get-Content .\WT_CV_Map3.csv
Get-Content .\WT_CV_Map3.csv | Measure-Object

# Match old and new live DCs
# Matching all users, not just a*
Export-SIDMappingCustom -ObjectType User -Property samAccountName -OldServer wingtiptoys.local -NewServer cohovineyard.com -MapFile WT_CV_Map4.csv
Get-Content .\WT_CV_Map4.csv
Get-Content .\WT_CV_Map4.csv | Measure-Object

# Match old and new live DCs
# Matching all global groups
Export-SIDMappingCustom -ObjectType GlobalGroup -Property samAccountName -OldServer wingtiptoys.local -NewServer cohovineyard.com -MapFile WT_CV_Map5.csv
Get-Content .\WT_CV_Map5.csv
Get-Content .\WT_CV_Map5.csv | Measure-Object


# Tracking down old domains from SID history by keyword
Get-DomainSIDWordCount
Get-DomainSIDWordCount | Out-GridView

