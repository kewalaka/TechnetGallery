<#-----------------------------------------------------------------------------
SID History PowerShell Module v1.5
Ashley McGlone, Microsoft Premier Field Engineer
http://aka.ms/SIDHistory
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
-------------------------------------------------------------------------------

SIDHistory.psm1


-------------------------------------------------------------------------------
Version 1.5
July, 2013

Minor help corrections.
Published version 1.5.

-------------------------------------------------------------------------------
Version 1.4.8
December, 2012

Functions added in this release:
Export-SIDMappingCustom

-------------------------------------------------------------------------------
Version 1.4.7
November, 2012

Functions modified in this release:
Export-SIDMapping
-Added description and whenCreated to SIDReport.CSV.

Update-SIDMapping
-Added description and whenCreated to SIDReportUpdated.CSV.

Functions added in this release:
Get-SIDHistoryDuplicates
Search-SIDHistoryACL
Watch-Job
Get-DomainSIDWordCount

-------------------------------------------------------------------------------
Version 1.4.6
October, 2012

Functions modified in this release:
Convert-SIDHistoryNTFS
-modified csv and log files
-added error logging
-report when both Old SID and New SID are in ACL
Export-SIDHistoryShare
-modified csv file

-------------------------------------------------------------------------------
Version 1.4.5
September, 2012

Functions modified in this release:
Convert-SIDHistoryNTFS (added -Add switch, modified log files)
Export-SIDHistoryShare (modified csv file)
Export-SIDMapping (optimized queries)

-------------------------------------------------------------------------------
Version 1.4
June, 2012

Functions added in this release:
Export-SIDHistoryShare
Merge-CSV

Functions modified in this release:
Convert-SIDHistoryNTFS
Export-SIDMapping
Update-SIDMapping
Get-SIDHistory

Fixes:
Removed Test-Path validation on NewReport parameter of Update-SIDMapping.
Added file validation for DomainFile parameter of Get-SIDHistory.

-------------------------------------------------------------------------------
Version 1.3
December, 2011

Converted to module for importing
-------------------------------------------------------------------------------
Version 1.2
November, 2011

Functions added in this release:
Get-SIDHistory
Remove-SIDHistory
-------------------------------------------------------------------------------
Version 1.1
October, 2011

Functions added in this release:
Export-DomainSIDs
Update-SIDMapping
-------------------------------------------------------------------------------
Version 1.0
September, 2011

Functions added in this release:
Export-SIDMapping
Convert-SIDHistoryNTFS
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
Instructions for SID history documentation:
1. Import-Module SIDHistory
2. Export-DomainSIDs
3. Export-SIDMapping
4. Update-SIDMapping
5. Open the SIDMappingUpdated.csv file.

-------------------------------------------------------------------------------
Instructions for NTFS SID history clean up:
1. Import-Module SIDHistory
2. For instructions use Get-Help -Full to read about each function:
   Get-Help Convert-SIDHistoryNTFS -Full
3. Export-SIDMapping
4. Review the report files
5. Convert-SIDHistoryNTFS \\server\share\path -WhatIf
6. Review the report files
7. Convert-SIDHistoryNTFS \\server\share\path
8. Review the report files
9. Confirm access with affected users/groups
-----------------------------------------------------------------------------#>


function Export-SIDMapping {
    <#
    .SYNOPSIS
    This function builds two Active Directory SIDhistory reports.
    .DESCRIPTION
    This function queries Active Directory for SID history in order to build a SID mapping file for use with the ADMT to do security translation, especially in situations where the ADMT database has been lost.  In addition to the mapping file it also generates a full SID history report for viewing in Excel.
    .EXAMPLE
    Export-SIDMapping
    .NOTES
    This function must be run from a machine that has the Active Directory module for PowerShell installed (ie. Windows 7 with RSAT or Windows Server 2008 R2).  You must also have either a Windows Server 2008 R2 domain controller, or an older domain controller with the Active Directory Management Gateway Service (AD Web Service) installed.  For more information on ADWS see:
    http://blogs.technet.com/b/ashleymcglone/archive/2011/03/17/step-by-step-how-to-use-active-directory-powershell-cmdlets-against-2003-domain-controllers.aspx
    .LINK
    http://aka.ms/SIDHistory
    .LINK
    http://blogs.technet.com/b/ashleymcglone/archive/2011/03/17/step-by-step-how-to-use-active-directory-powershell-cmdlets-against-2003-domain-controllers.aspx
    #>

    #Query SID history, current SID, and related fields from AD
    $ADQuery = Get-ADObject -LDAPFilter "(sIDHistory=*)" `
        -Property objectClass, samAccountName, DisplayName, `
        objectSid, sIDHistory, distinguishedname, description, whenCreated |
        Select-Object * -ExpandProperty sIDHistory

    #Create a full SID History report file for reference in Excel
    $ADQuery |
        Select-Object objectClass, `
        @{name="OldSID";expression={$_.Value}}, `
        @{name="NewSID";expression={$_.objectSID}}, `
        samAccountName, displayName, description, whenCreated, DistinguishedName, `
        @{name="DateTimeStamp";expression={Get-Date -Format g}} |
        Export-CSV SIDReport.csv -NoTypeInformation

    #Create a SID Mapping text file for use with ADMT
    $ADQuery |
        Select-Object @{name="OldSID";expression={$_.Value}}, `
        @{name="NewSID";expression={$_.objectSID}} |
        Export-CSV SIDMap0.csv -NoTypeInformation

    #Peel out the quotes from the mapping file, because ADMT does not like those.
    Get-Content .\SIDMap0.csv |
        ForEach-Object {$_.Replace("`"","")} |
        Set-Content .\SIDMap.csv
    Remove-Item .\SIDMap0.csv

    "Output complete:"
    "SIDReport.csv  - full SID History report for reference in Excel"
    "SIDMap.csv     - file for use with ADMT to do security translation"

    #   ><>
}






function Parse-SDDL ($SDDLString, $Add) {
    #http://msdn.microsoft.com/en-us/library/aa374928.aspx
    # ace_type;ace_flags;rights;object_guid;inherit_object_guid;account_sid
    # 0       ;1        ;2     ;3          ;4                  ;5
    # 0       ;ID       ;2     ;3          ;4                  ;SID
    # O:S-1-5-21-124525005-000250630-1543110021-060600G:DUD:AI(A;;FA;;;S-1-5-21-3005000230-335460600-2062000006-1000)(A;OICIIO;GA;;;S-1-5-21-3005000230-335460600-2062000006-1000)(A;OICIID;FA;;;SY)(A;OICIID;FA;;;BA)(A;OICIID;FA;;;S-1-5-21-124525005-000250630-1543110021-060600)

    # Split the SDDL on the characer: (
    # Check index 0 for an owner SID
    # Process indexes 1 to end
    #   Split on character: ;
    #   If index 1 contains "ID" then ignore because inherited
    #   If index 5 contains a SID then process it
    #     If SID is in mapping file then replace or add
    #   If SDDL changed, then
    #     Re-Join SDDL text
    #     Commit SDDL change

    $SDDLSplit = $SDDLString.Split("(")
    $SDDLChanged = $false


    # Since later we are going to append to the SDDLSplit array when doing an ADD instead of REPLACE,
    # the length of the array will grow and cause processing to occur for the elements we added, but
    # we don't want that to happen.  Therefore we have to capture a static value of the array length
    # prior to declaring the loop.
    $SDDLSplitLength = $SDDLSplit.Length
    For ($i=1;$i -lt $SDDLSplitLength;$i++) {
        $ACLSplit = $SDDLSplit[$i].Split(";")
        If ($ACLSplit[1].Contains("ID")) {
            "Inherited" | Out-File -FilePath $LogFile -Append
        } Else {
            $ACLEntrySID = $null
            # Remove the trailing ")"
            $ACLEntry = $ACLSplit[5].TrimEnd(")")
            $ACLEntrySIDMatches = [regex]::Matches($ACLEntry,"(S(-\d+){2,8})")
            $ACLEntrySIDMatches | ForEach-Object {$ACLEntrySID = $_.value}
            If ($ACLEntrySID) {
                "Old SID: $ACLEntrySID" | Out-File -FilePath $LogFile -Append
                If ($SIDMapHash.Contains($ACLEntrySID)) {
                    $NewEntry = $SDDLSplit[$i].Replace($ACLEntrySID,$SIDMapHash.($ACLEntrySID))
                    # Do the ADD or REPLACE
                    If ($Add) {
                        "New SID: $($SIDMapHash.($ACLEntrySID)) ADD" | Out-File -FilePath $LogFile -Append
                        $SDDLSplit += $NewEntry
                    } Else {
                        "New SID: $($SIDMapHash.($ACLEntrySID)) REPLACE" | Out-File -FilePath $LogFile -Append
                        $SDDLSplit[$i] = $NewEntry
                    }
                    $SDDLChanged = $true

                    #Arrange the data we want into a custom object
                    $objTemp = New-Object PSObject -Property @{
                         # Parse out servername from the path, assuming it is in UNC format: \\servername\share\folder
                         ServerName=$StartPath.Substring(2,$StartPath.Substring(2,$StartPath.Length-3).IndexOf("\"));
                         StartPath=$StartPath;
                         Folder=$folder;
                         OldSID=$ACLEntrySID;
                         OldDomainSID=$ACLEntrySID.Substring(0,$ACLEntrySID.LastIndexOf("-"));
                         NewSID=$SIDMapHash.($ACLEntrySID);
                         NewDomainSID=$SIDMapHash.($ACLEntrySID).Substring(0,$SIDMapHash.($ACLEntrySID).LastIndexOf("-"));
                         #Does the SDDL already contain the new entry?
                         Both=$SDDLString.Contains($NewEntry);
                         ACLType="NTFS";
                         Operation=$(If ($Add) {'Add'} Else {'Replace'});
                         DateTimeStamp=Get-Date -Format g;
                        }
                    #Use array addition to add the new object to our report array
                    $script:report += $objTemp

                } Else {
                    "No SID history entry" | Out-File -FilePath $LogFile -Append
                }
            } Else {
                "Not inherited - No SID to translate" | Out-File -FilePath $LogFile -Append
            }
        }
    }

    If ($SDDLChanged) {
        $NewSDDLString = $SDDLSplit -Join "("
        "New SDDL string: $NewSDDLString" | Out-File -FilePath $LogFile -Append
        return $NewSDDLString
    } Else {
        "SDDL did not change." | Out-File -FilePath $LogFile -Append
        return $null
    }

}




function Convert-SIDHistoryNTFS {
    <#
    .SYNOPSIS
    This function adds or replaces ACL SID entries based on a SID history mapping file.
    .DESCRIPTION
    This function begins at the specified path and recursively scans all subfolder ACL ACE entries for SID matches in the mapping file specified.  Where non-inherited matches are found they are replaced with the mapping file SID value from the second column.
    .PARAMETER StartPath
    Specifies the root folder where the SID translation will begin.
    May be a local or UNC, absolute or relative file path.
    May be any NTFS file share platform (Windows, NAS, etc.).
    .PARAMETER MapFile
    CSV SID mapping file containing OldSID,NewSID entries.
    Looks for SIDMap.csv in the current folder if not specified.
    Use the function Export-SIDMapping to create this file.
    .PARAMETER LogFile
    Text log file for verbose output
    .PARAMETER ErrorFile
    CSV log file for folder path error output
    .PARAMETER ReportFile
    CSV log file documenting all changed SIDs and paths
    .PARAMETER WhatIf
    Runs without making any changes.  Logs what would change.
    .PARAMETER Add
    Does an ADD instead of REPLACE when converting SID history.
    .EXAMPLE
    Convert-SIDHistoryNTFS -StartPath \\fileserver\sharename\ -WhatIf
    .EXAMPLE
    Convert-SIDHistoryNTFS -StartPath \\fileserver\sharename\
    .EXAMPLE
    Convert-SIDHistoryNTFS -StartPath \\fileserver\sharename\ -Add
    .EXAMPLE
    Convert-SIDHistoryNTFS -StartPath D:\folder\ -WhatIf
    .EXAMPLE
    Convert-SIDHistoryNTFS -StartPath D:\folder\
    .NOTES
    Must run with permissions to edit security on all subfolders in the path specified.
    Use the error CSV log to see folders where access is denied under the current credentials.
    Most error messages displayed during the run will be capture in the error log with specific paths for investigation.
    This script may make changes to your environment when run without the WhatIf switch.
    Some backup programs treat ACL changes as a backup trigger.  Coordinate this with your backup administrator.
    The CSV report 'Both' column indicates when both the OldSID and NewSID entries already exist in the ACL. This can occur when an Add parameter has been used before the WhatIf report was run.
    .INPUTS
    Script takes input from a SID mapping file generated by the function "Export-SIDMapping".  This must be run first.
    .OUTPUTS
    LogFile is a txt file with a verbose record of everything found and changed.
    .OUTPUTS
    ErrorFile is a CSV listing folders that failed the scan due to access denied, path too long, etc.
    .OUTPUTS
    ReportFile is a CSV listing all affected folders, old SID, and new SID.  Run with the -WhatIf switch to create this report as an audit of SID history without making changes.
    .LINK
    http://aka.ms/SIDHistory
    #>

    Param (
        [parameter(Mandatory=$true)]
        [string]
        [ValidateScript({Test-Path -Path $_})]
        $StartPath,
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $MapFile = ".\SIDMap.csv",
        [parameter()]
        [string]
        $ErrorFile = ".\NTFS_SID_Translation_Report_"+(Get-Date -UFormat %Y%m%d%H%M%S)+"_ERRORS.csv",
        [parameter()]
        [string]
        $LogFile = ".\NTFS_SID_Translation_Report_"+(Get-Date -UFormat %Y%m%d%H%M%S)+".txt",
        [parameter()]
        [string]
        $ReportFile = ".\NTFS_SID_Translation_Report_"+(Get-Date -UFormat %Y%m%d%H%M%S)+".csv",
        [parameter()]
        [switch]
        $WhatIf,
        [parameter()]
        [switch]
        $Add
    )

    $Error.Clear()
    $MaximumErrorCount = 32768
    $ErrorActionPreference = 'Continue'

    <#-----------------------------------------------------------------------------
    Import mapfile.

    Get recursive folder list.

    For each folder
      Get-ACL | function for SDDL parsing
      If -not WhatIf then commit SDDL change
      Log output 
    -----------------------------------------------------------------------------#>

    # === BEGIN SETUP ===

    # Initiate log file
    Get-Date | Out-File -FilePath $LogFile

    If (-not $WhatIf) {
        ""
        "This script will update ACL entries recursively in the StartPath specified."
        "This could trigger a backup of all updated files."
        "Run the command using the -WhatIf switch first."
        $input = Read-Host "Are you sure you wish to proceed? (Y/N)"
        If ($input -eq "") { return } Else {
            If ($input.substring(0,1) -ne "y") { return }
        }
        "Security translation is live and changes will be committed." | Out-File -FilePath $LogFile -Append
    } Else {
        "AUDIT MODE: Security translation is not live and changes will not be committed." | Out-File -FilePath $LogFile -Append
    }

    "Log file is $LogFile" | Out-File -FilePath $LogFile -Append
    "Report file is $ReportFile" | Out-File -FilePath $LogFile -Append
    "Map file is $MapFile" | Out-File -FilePath $LogFile -Append
    "StartPath is $StartPath" | Out-File -FilePath $LogFile -Append
    "WhatIf is $WhatIf" | Out-File -FilePath $LogFile -Append
    "Operation is $(If ($Add) {'ADD'} Else {'REPLACE'})" | Out-File -FilePath $LogFile -Append

    # === END SETUP ===

    # === BEGIN BODY ===

    # Import SID mapping file
    # File format is:
    # OldSID,NewSID
    $SIDMapHash = @{}
    Import-CSV $MapFile | ForEach-Object {$SIDMapHash.Add($_.OldSID,$_.NewSID)}
    "SID mapping file imported." | Out-File -FilePath $LogFile -Append

    "" | Out-File -FilePath $LogFile -Append
    "Beginning security enumeration." | Out-File -FilePath $LogFile -Append
    "" | Out-File -FilePath $LogFile -Append

    # Initialize CSV report output
    $script:report = @()

    write-progress -activity "Collecting folders to scan..." -Status "Progress: " -PercentComplete 0

    # Get folder list for security translation
    # Start by grabbing the root folder itself
    # Add the folders in this order so that we hit the root first
    $folders = @()
    $folders += Get-Item $StartPath | Select-Object -ExpandProperty FullName

    # This will error on paths longer than 260 characters:
    #$subfolders = Get-Childitem $StartPath -Recurse | Where-Object {$_.PSIsContainer -eq $true} | Select-Object -ExpandProperty FullName
    # Instead use System.IO.Directory.GetFiles() and System.IO.Directory.GetDirectories()
    #$subfolders = [System.IO.Directory]::GetDirectories($StartPath,'*',1) #,SearchOption.AllDirectories)
    # But testing shows that folder errors in the tree will kill all results.  Not good.
    # http://msdn.microsoft.com/en-us/library/ms143314.aspx
    # http://msdn.microsoft.com/en-us/library/ms143448.aspx
    # http://social.technet.microsoft.com/wiki/contents/articles/12179.net-powershell-path-too-long-exception-and-a-net-powershell-robocopy-clone-en-us.aspx
    # Unfortunately the error reporting only works in PowerShell v3.
    # PowerShell v2 will fail silently and not report the error.
    $ErrorLog = @()
	$subfolders = Get-Childitem $StartPath -Recurse -ErrorVariable +ErrorLog -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $true} | Select-Object -ExpandProperty FullName

    # We don't want to add a null object to the list if there are no subfolders
    If ($subfolders) {$folders += $subfolders}
    $i = 0
    $FolderCount = $folders.count

    ForEach ($folder in $folders) {

        "=== Next Folder ===" | Out-File -FilePath $LogFile -Append

        Write-Progress -activity "Scanning folders" -CurrentOperation $folder -Status "Progress: " -PercentComplete ($i/$FolderCount*100)
        $i++

        # Get-ACL cannot report some errors out to the ErrorVariable.
        # Therefore we have to capture this error using other means.
        Try {
            $acl = Get-ACL -Path $folder -ErrorAction Continue
        }
        Catch {
            $ErrorLog += New-Object PSObject -Property @{CategoryInfo=$_.CategoryInfo;TargetObject=$folder}
        }
        $folder | Out-File -FilePath $LogFile -Append
        #$acl.path | Out-File -FilePath $LogFile -Append
        $acl.SDDL | Out-File -FilePath $LogFile -Append
        $acl.access | ForEach-Object {$_ | Out-File -FilePath $LogFile -Append}
        # If we don't have access, then the SDDL will be incomplete and cause errors.
		# Also, there is a Connect issue filed for paths containing a '[' character that returns a null ACL object.
        # This is fixed in PSv3 with the Get-ACL -LiteralPath parameter.
        #If ($acl.SDDL.Contains("(")) {   # This line errors when calling a method on a null value.
        If ($acl.SDDL) {
            $NewSDDL = Parse-SDDL $acl.SDDL -Add $Add
            If ($NewSDDL -ne $null) {
                If (-not $WhatIf) {
                    $acl.SetSecurityDescriptorSddlForm($NewSDDL)
                    Set-Acl -Path $acl.path -ACLObject $acl
                    "SDDL updated." | Out-File -FilePath $LogFile -Append
                }
            }
        } Else {
            $NewSDDL = $null
            "SDDL read error." | Out-File -FilePath $LogFile -Append
			#$ErrorLog += New-Object PSObject -Property @{CategoryInfo='Error: Invalid character in path (maybe).';TargetObject=$folder}
        }
        "" | Out-File -FilePath $LogFile -Append
    }

    # === END BODY ===

    ""
    $script:report | Select-Object ServerName, StartPath, Folder, OldSID, OldDomainSID, NewSID, NewDomainSID, Both, ACLType, Operation, DateTimeStamp | Export-CSV $ReportFile -NoTypeInformation
    "Find CSV report of security translation here:"
    $ReportFile

    "" | Out-File -FilePath $LogFile -Append

    #$Error | Select-Object ScriptStackTrace, CategoryInfo, TargetObject | Export-Csv $ErrorFile -NoTypeInformation
    $ErrorLog | Select-Object CategoryInfo, TargetObject | Export-Csv $ErrorFile -NoTypeInformation
    "Find CSV report of errors here:"
    $ErrorFile

    "" | Out-File -FilePath $LogFile -Append

    Get-Date | Out-File -FilePath $LogFile -Append
    "Find complete log file here:"
    $LogFile
    ""

}






function Export-DomainSIDs {
    <#
    .SYNOPSIS
    This function creates a list of domain SIDs for the forest and trusts.
    .DESCRIPTION
    This function attempts to document all domain SIDs in the forest and across trusts.  Use the output to identify source domains for SID history.  Note that there may be domains in SID history which no longer exist and no longer have discoverable trusts to identify them.  The function follows these steps:
    - Gets the SID of the current domain where the script is running.
    - For each domain in the forest it gets a list of all trusted domains and their SIDs.
    - Gets all forest trusts and their domain SIDs.
    - For each trusted forest it gets all of their trusted domain SIDs.
    For best results run this function from each root domain across all forest trusts, then manually consolidate the results into a single CSV file and eliminate any duplicates.
    .PARAMETER File
    CSV output file containing Domain SID entries.
    If not specified defaults to .\DomainSIDs.csv
    .EXAMPLE
    Export-DomainSIDs
    .EXAMPLE
    Export-DomainSIDs -File C:\output\DomainSIDsForMyForest.csv
    .NOTES
    This function uses .NET 3.0 and WMI to collect all data.  Therefore it will run in legacy environments without the need for the PowerShell ActiveDirectory module.
    Forest trusts from the root domain will be included.
    External trusts will be included for any domain(s) inside the current forest.
    External trusts for remote trust partners will not be included.
    Trust discovery is limited to one hop due to permissions and lack of transitivity beyond one hop.
    Stale trusts will cause timeouts and extend the script run time, but it will finish.
    Use the Active Directory Topology Diagrammer (linked below) to draw a picture of all domains and trusts in the forest.
    .INPUTS
    Function has no inputs.
    .OUTPUTS
    Function creates a CSV file containing the FQDN and SID of each domain that it finds in the forest and across trusts.
    .LINK
    http://aka.ms/SIDHistory
    .LINK
    http://www.microsoft.com/download/en/details.aspx?id=13380
    #>

    Param (
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $File = ".\DomainSIDs.csv"
    )

    # We know there will be some errors due to offline trust partners,
    # access denied to remote domains, and popping duplicate entries
    # into the hash table.
    $ErrorActionPreference = "SilentlyContinue"

    $DomainSIDList = @{}

    # Get my own local domain SID
    Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Domain"
    $MyDomainSID = gwmi -namespace root\MicrosoftActiveDirectory -class Microsoft_LocalDomainInfo | Select-Object DNSname, SID
    Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Domain" -Progress $MyDomainSID.DNSname
    $DomainSIDList.Add($MyDomainSID.DNSname, $MyDomainSID.SID)

    # Get list of all domains in local forest
    $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

    # For each domain in local forest use WMI to get trust list
    # Use WMI, because .NET Domain class GetAllTrustRelationships method does not include SID (although the forest class version does)
    Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Forest Domain Trusts"
    $forest.Domains | ForEach-Object {
            Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Forest Domain Trusts" -Progress "Domain: $_.Name"
            gwmi -namespace root\MicrosoftActiveDirectory -class Microsoft_DomainTrustStatus -computername $_.Name |
             ForEach-Object {
                Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Forest Domain Trusts" -Progress "Trust: $_.TrustedDomain"
                $DomainSIDList.Add($_.TrustedDomain, $_.SID)
             }
        }

    # Get forest trusts from .NET
    Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Forest Trusts"
    $trusts = $forest.GetAllTrustRelationships()
    ForEach ($trust in $trusts) {
      $trust.TrustedDomainInformation |
        ForEach-Object {
            Write-Progress -Activity "Collecting Domain SIDs" -Status "Current Forest Trusts" -Progress "Trust: $_.DnsName"
            $DomainSIDList.Add($_.DnsName, $_.DomainSid)

            # Get all forest trusts from remote trusted forests
            Write-Progress -Activity "Collecting Domain SIDs" -Status "Remote Forest Trusts"
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest",$_.DnsName)
            $remoteforest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($context)
            $remotetrusts = $remoteforest.GetAllTrustRelationships()
            ForEach ($remotetrust in $remotetrusts) {
              $remotetrust.TrustedDomainInformation | 
                ForEach-Object {
                    Write-Progress -Activity "Collecting Domain SIDs" -Status "Remote Forest Trusts" -Progress "Trust: $_.DnsName"
                    $DomainSIDList.Add($_.DnsName, $_.DomainSid)
                }
            }
        }
    }

    # Dump the list to a CSV file after sorting and naming the columns
    $DomainSIDList.GetEnumerator() | Sort-Object Key | Select-Object @{name="Domain";expression={$_.Key}}, @{name="SID";expression={$_.Value}} | Export-CSV $File -NoTypeInformation

    ""
    "See the output file for results: $File"
    ""
}




Function Update-SIDMapping {
    <#
    .SYNOPSIS
    This function inserts a SourceDomain column into the SIDReport.csv file.
    .DESCRIPTION
    This function identifies the old domain name where the SID history originated.
    Then it updates the SIDReport.CSV file.  This makes the report more meaningful.
    .PARAMETER OldReport
    Path and name of the SIDReport.CSV file generated by the function Export-SIDMapping.
    Defaults to: .\SIDReport.csv
    .PARAMETER NewReport
    Path and name for the updated report file.
    Defaults to: .\SIDReportUpdated.csv
    .PARAMETER DomainFile
    Path and name of the DomainSIDs.csv file generated by the function Export-DomainSIDs.
    Defaults to: .\DomainSIDs.csv
    .EXAMPLE
    Update-SIDMapping
    .EXAMPLE
    Update-SIDMapping -OldReport "C:\SIDReport.csv" -NewReport "C:\SIDReportUpdated.csv" -DomainFile "C:\DomainSIDs.csv"
    .NOTES
    Prior to calling this function you need to run Export-DomainSIDs and Export-SIDMapping.
    .INPUTS
    SIDReport.csv
    .INPUTS
    DomainSIDs.csv
    .OUTPUTS
    SIDReportUpdated.csv
    .LINK
    http://aka.ms/SIDHistory
    #>
    
    Param(
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $OldReport = ".\SIDReport.csv",
        [parameter()]
        [string]
        $NewReport = ".\SIDReportUpdated.csv",
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $DomainFile = ".\DomainSIDs.csv"
    )

    # Read in the old SID History Report file and append a new column to hold the SourceDomain update
    $SIDReport = Import-CSV $OldReport | Select-Object *, OldDomain, NewDomain, OldDomainSID, NewDomainSID

    # Read in the DomainSID CSV file and store it in a hash table
    $DomainSIDsHash = @{}
    Import-CSV $DomainFile | ForEach-Object {$DomainSIDsHash.Add($_.SID,$_.Domain)}

    # Process each line of the SID History Report file
    # Parse out the domain portion of the OldSID column
    # Match that to the domain SID in the hash table
    # Update the SourceDomain column with the domain name
    ForEach ($row in $SIDReport) {
        $row.OldDomain = $DomainSIDsHash.Item($row.OldSID.Substring(0,$row.OldSID.LastIndexOf("-")))
        $row.NewDomain = $DomainSIDsHash.Item($row.NewSID.Substring(0,$row.NewSID.LastIndexOf("-")))
        $row.OldDomainSID = $row.OldSID.Substring(0,$row.OldSID.LastIndexOf("-"))
        $row.NewDomainSID = $row.NewSID.Substring(0,$row.NewSID.LastIndexOf("-"))
    }

    # Write out the new SID History Report file and insert the SourceDomain column before the OldSID column
    $SIDReport | Select-Object ObjectClass, OldDomain, NewDomain, OldDomainSID, NewDomainSID, OldSID, NewSID, samAccountName, DisplayName, description, whenCreated, DistinguishedName, DateTimeStamp | Export-CSV $NewReport -NoTypeInformation
    
    ""
    "Updated SID History Report is located here: $NewReport"
    ""
}






function Remove-SIDHistory {
    <#
    .SYNOPSIS
    This function removes sIDHistory attribute entries for Active Directory objects.
    .DESCRIPTION
    This function retrieves an Active Directory object by distinguishedName and then removes the sIDHistory entry specified.
    .PARAMETER DistinguishedName
    Specifies the Active Directory object for which SID history will be removed.
    .PARAMETER SID
    Specifies the individual sIDHistory entry to be removed.
    .EXAMPLE
    Remove-SIDHistory -DistinguishedName "cn=user1,ou=department,dc=domain,dc=com" -SID S-1-5-21-2999376440-943217962-1153441346-1447
    .EXAMPLE
    Get-SIDHistory -samAccountName user1 | Remove-SIDHistory
    The easiest way to use Remove-SIDHistory is by piping the output from Get-SIDHistory.
    .EXAMPLE
    Get-SIDHistory -samAccountName user1 | Remove-SIDHistory -WhatIf
    Use the WhatIf parameters for testing.
    .EXAMPLE
    Get-SIDHistory -samAccountName user1 | Remove-SIDHistory -Confirm:$true
    Use the Confirm parameters for testing.
    .EXAMPLE
    Get-SIDHistory -MemberOf TestGroup | Remove-SIDHistory | Export-CSV removed.csv
    .NOTES
    Please note that removing SID history may cause significant impact to users if resource ACLs have not been migrated.
    Review the ADMT Guide and make sure all migration steps have been completed.
    As a backout plan make sure there is a verified system state backup from two DCs per domain.
    Use the WhatIf and/or Confirm parameters for testing.
    Use Export-SIDHistory to document all SID history in the environment before removing it.
    .INPUTS
    Function takes two mandatory parameters: DistinguishedName and SID.
    .OUTPUTS
    This script outputs three properties: DateModified, Status, DistinguishedName, SID.
    Pipe this output to a file or CSV for documentation of the change.
    Use the output for troubleshooting the specific time of the change if users are impacted.
    PS> Get-SIDHistory -MemberOf TestGroup | Remove-SIDHistory | Export-CSV removed.csv
    .LINK
    http://aka.ms/SIDHistory
    .LINK
    Get-SIDHistory
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact="Low")]
    Param (
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $DistinguishedName,
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $SID
    )

    Begin{}

    Process{
        #Purge a single sIDHistory entry for the specified distinguishedName
        Set-ADObject -Identity $DistinguishedName -Remove @{sIDHistory=$SID}
        1 | select-object @{name="DateModified";expression={Get-Date}}, @{name="Status";expression={"Removed"}}, @{name="DistinguishedName";expression={$DistinguishedName}}, @{name="SID";expression={$SID}}
    }

    End{}

}




function Get-SIDHistory {
    <#
    .SYNOPSIS
    This function retrieves sIDHistory attribute entries for Active Directory objects.
    .DESCRIPTION
    This function retrieves sIDHistory attribute entries for Active Directory objects.  Parameter switches can be used individually or in combination to shape the Active Directory query to target specfic objects.
    If an object has multiple sIDHistory entries it is not necessary to target all of them at once.  The DomainName and DomainSID parameters can retrieve specific values while ignoring others.  See the parameter help for more information.
    .PARAMETER DomainSID
    This is a string representing the domain portion of the sIDHistory entries to be returned.
    Example:
      -DomainSID S-1-5-21-2999376440-943117962-1153441346
    .PARAMETER DomainName
    This is the Fully Qualified Domain Name (FQDN) of the SID history domain to be retrieved.  When using this parameter you must supply a DomainSIDs.csv file created by the function Export-DomainSIDs.  Specify the path to the file using the switch DomainFile.  See the full help for Export-DomainSIDs for more information.
    .PARAMETER DomainFile
    Specifies the path to the DomainSIDs.csv file required by the DomainName parameter.  If omitted this parameter defaults to ".\DomainSIDs.csv".  This parameter has no effect if the DomainName parameter is omitted.  See the full help for Export-DomainSIDs for more information.
    .PARAMETER SamAccountName
    Specific user name, group name, or computer name.
    .PARAMETER MemberOf
    Specifies the name of a group to query for members.
    Note that this only returns users who are direct members of the group.
    It does not return nested groups or nested group membership.
    .PARAMETER SearchBase
    Specifies an Active Directory path under which to search.  Defaults to the root of the current domain.
      -SearchBase "ou=mfg,dc=noam,dc=corp,dc=contoso,dc=com"
    .PARAMETER SearchScope
    Specifies the scope of an Active Directory search. Possible values for this parameter are:
      Base or 0
      OneLevel or 1
      Subtree or 2
    A Base query searches only the current path or object.
    A OneLevel query searches the immediate children of that path or object.
    A Subtree query searches the current path or object and all children of that path or object.
    .PARAMETER ObjectClass
    This specifies the Active Directory ObjectClass for the query.  Valid options are:
      user
      computer
      group
    .EXAMPLE
    Get-SIDHistory
    .EXAMPLE
    Get-SIDHistory -SamAccountName ashleym
    .EXAMPLE
    Get-SIDHistory -DomainName fun.wingtiptoys.local -DomainFile DomainSIDs.csv
    .EXAMPLE
    Get-SIDHistory –DomainName wingtiptoys.com
    .EXAMPLE
    Get-SIDHistory –DomainName wingtiptoys.com –SamAccountName ashleym
    .EXAMPLE
    Get-SIDHistory –DomainSID "S-1-5-21-2371126157-4032412735-3953120161"
    .EXAMPLE
    Get-SIDHistory –ObjectClass group
    .EXAMPLE
    Get-SIDHistory –SearchBase "OU=Sales,DC=contoso,DC=com" -SearchScope onelevel
    .EXAMPLE
    Get-SIDHistory –ObjectClass user –SearchBase "OU=Sales,DC=contoso,DC=com" 
    .EXAMPLE
    Get-SIDHistory –MemberOf MigratedUsers
    .EXAMPLE
    Get-SIDHistory | Measure-Object
    Display count of all SID history entries.
    .EXAMPLE
    Get-SIDHistory -ObjectClass user | Measure-Object
    Display count of all user SID history entries.
    Note that this is not a user count but a SID history count.  It is possible for accounts to have multiple SID history entries.
    .NOTES
    This function is quite similar to Get-ADObject except for these two features:
      1. It uses ExpandProperty to guarantee a single row for each sIDHistory entry.
      2. It can selectively query sIDHistory based on a domain name.
    Note that it is possible to construct a query of mutually exclusive criteria which will give an empty result.
    For Example:
     Get-SIDHistory -SamAccountName AccountingUsers -ObjectClass user
    In this example the query is looking for a group but specifying the wrong object class.
    .INPUTS
    Takes a combination of search filters.
    .OUTPUTS
    Returns distinguishedName and sIDHistory entries matching the criteria.
    .LINK
    http://aka.ms/SIDHistory
    .LINK
    Get-SIDHistory
    .LINK
    Export-DomainSIDs
    #>
    [CmdletBinding(DefaultParameterSetName="DomainCSV")]
    Param (
        [parameter(ParameterSetName="DomainCSV")]
        [string]
        $DomainName,
        [parameter(ParameterSetName="DomainCSV")]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $DomainFile = ".\DomainSIDs.csv",
        [parameter(ParameterSetName="DomainSID")]
        [string]
        $DomainSID,
        [parameter()]
        [string]
        [ValidateScript({(Get-ADObject -Filter 'SamAccountName -eq $_')})]
        $SamAccountName,
        [parameter()]
        [string]
        [ValidateScript({(Get-ADGroup $_)})]
        $MemberOf,
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path "AD:$_"})]
        $SearchBase = (Get-ADDomain).DistinguishedName,
        [parameter()]
        [string]
        [ValidateSet("Base", "OneLevel", "Subtree", "0", "1", "2")]
        $SearchScope = "subtree",
        [parameter()]
        [string]
        [ValidateSet("computer", "user", "group")]
        $ObjectClass
    )

    # Validate that the domain name passed actually exists in the csv file.
    If ($DomainName) {
        # Validate that the DomainFile CSV actually exists
        If (Test-Path $DomainFile) {
            $DomainSIDsHash = @{}
            Import-CSV $DomainFile | ForEach-Object {$DomainSIDsHash.Add($_.Domain,$_.SID)}
            If (-not ($DomainSIDsHash.Item($DomainName))) {
                Write-Host "DomainName ($DomainName) does not exist in DomainFile ($DomainFile)." -BackgroundColor Black -ForegroundColor Red
                break
            }
        } Else {
            Write-Host "Cannot find DomainFile ($DomainFile)." -BackgroundColor Black -ForegroundColor Red
            break
        }
    }

    # This is the core filter telling AD to return only entries with SID history.
    $Filter = 'sidHistory -like "*"'
    
    # Modify the filter based on parameters passed.  These are cumulative.
    If ($SamAccountName) {$Filter += ' -and samAccountName -eq "' + $SamAccountName + '"'}
    If ($ObjectClass) {$Filter += ' -and objectClass -eq "' + $ObjectClass + '"'}
    If ($MemberOf) {$Filter += ' -and MemberOf -eq "' + (Get-ADGroup $MemberOf).DistinguishedName + '"'}

    # This is the base query which we will modify according to the parameters passed.
    $QueryString = "Get-ADObject -Filter '$Filter' -Property sidHistory -SearchBase ""$SearchBase"" -SearchScope ""$SearchScope"" | Select-Object * -ExpandProperty sidHistory"

    # If specifid, then filter the sIDHistory entries by domain.
    # AccountDomainSid is an attribute of the SID object.  We'll filter on this.
    # http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx
    If ($DomainName) {$QueryString += ' | Where-Object {$_.AccountDomainSid -eq "' + $DomainSIDsHash.Item($DomainName) +'"}'}
    If ($DomainSID) {$QueryString += ' | Where-Object {$_.AccountDomainSid -eq "' + $DomainSID +'"}'}

    # Structure the output properties to match the input properties for Remove-SIDHistory.
    # The "Value" property holds the sIDHistory entires split out by the ExpandProperty parameter.
    $QueryString += ' | Select-Object DistinguishedName, @{name="SID";expression={$_.Value}}'

    # The big finish... run the query.
    Invoke-Expression $QueryString
}




function Export-SIDHistoryShare {
    <#
    .SYNOPSIS
    This function enumerates shares on a server and then generates a CSV file documenting SID history instances in ACEs on the share ACLs.
    .DESCRIPTION
    This function enumerates shares on a server and then generates a CSV file documenting SID history instances in ACEs on the share ACLs.
    The output format of the CSV matches the NTFS CSV report so that they can be rolled up into the same database table.
    .PARAMETER ComputerName
    Specifies the Windows server where shares, ACLs, and ACEs will be scanned for SID history.
    .PARAMETER MapFile
    CSV SID mapping file containing OldSID,NewSID entries.
    Looks for SIDMap.csv in the current folder if not specified.
    Use the function Export-SIDMapping to create this file.
    .PARAMETER ReportFile
    CSV log file documenting all SID history ACEs on shares
    .EXAMPLE
    Export-SIDHistoryShare -ComputerName FileServer01
    .NOTES
    Script must be run with permissions to view security on all shares on the server, otherwise data returned will be incomplete.
    This script makes no changes to your environment.
    As this script requires WMI it will not work against NAS servers.
    .INPUTS
    Script takes input from a SID mapping file generated by the function "Export-SIDMapping".  This must be run first.
    .OUTPUTS
    ReportFile is a CSV listing shares, old SID, and new SID.  Note that only shares with SID history entries will be reported.
    .LINK
    http://aka.ms/SIDHistory
    .LINK
    http://blogs.technet.com/b/heyscriptingguy/archive/2011/11/26/use-powershell-to-find-out-who-has-permissions-to-a-share.aspx
    #>

    Param (
        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $MapFile = ".\SIDMap.csv",
        [parameter()]
        [string]
        $ReportFile = ".\Share_SID_History_Report_"+(Get-Date -UFormat %Y%m%d%H%M%S)+".csv"
    )

    # Import SID mapping file
    # File format is:
    # OldSID,NewSID
    $SIDMapHash = @{}
    Import-CSV $MapFile | ForEach-Object {$SIDMapHash.Add($_.OldSID,$_.NewSID)}

    # Initialize CSV report output
    $Report = @()
    # Get the list of shares
    $Shares = Get-WmiObject Win32_Share -ComputerName $ComputerName -Filter "Caption <> 'Remote IPC' and Caption <> 'Remote Admin'"
    ForEach ($Share in $Shares) {
        # Get the ACEs of each share
        # This generates errors for some shares like C$; all others work fine.
        $query = "Associators of {win32_LogicalShareSecuritySetting='$($Share.name)'} Where resultclass = win32_sid"
        $gwmi  = Get-WmiObject -Query $query -ComputerName $ComputerName -ErrorAction:SilentlyContinue | Where-Object {$_.SidLength -gt 16}
        # Only proceed if the query returned any results
        If ($gwmi) {
            ForEach ($ACE in $gwmi) {
                Write-Progress -Activity "Scanning Share ACEs" -Status $Share.Name -CurrentOperation $ACE.SID
                If ($SIDMapHash.Contains($ACE.SID)) {

                    # Break out the share type
                    Switch ($Share.Type) {
                        0          {$ACLType = "Share File"};
                        2147483648 {$ACLType = "Share File"};
                        1          {$ACLType = "Share Printer"};
                        2147483649 {$ACLType = "Share Printer"};
                        Default    {$ACLType = "Share Other"}
                    }

                    #Arrange the data we want into a custom object
                    $objTemp = New-Object PSObject -Property @{
                         # Parse out servername from the path, assuming it is in UNC format: \\servername\share\folder
                         ServerName=$ComputerName;
                         StartPath="\\$($ComputerName)\$($Share.name)";
                         Folder="\\$($ComputerName)\$($Share.name)";
                         OldSID=$ACE.SID;
                         OldDomainSID=$ACE.SID.Substring(0,$ACE.SID.LastIndexOf("-"));
                         NewSID=$SIDMapHash.($ACE.SID);
                         NewDomainSID=$SIDMapHash.($ACE.SID).Substring(0,$SIDMapHash.($ACE.SID).LastIndexOf("-"));
                         Both=$null;
                         ACLType=$ACLType;
                         Operation=$null;
                         DateTimeStamp=Get-Date -Format g;
                        }
                    #Use array addition to add the new object to our report array
                    $Report += $objTemp
                } Else {
                    # SID was not found in SID history map file
                }
            }
       } 

       # $Report += $gwmi |
       #   Select-Object @{Name="ServerName";Expression={$ComputerName}}, @{Name="Share";Expression={$Share.Name}}, @{Name="Type";Expression={ Switch ($Share.Type) {0 {"File"}; 1 {"Printer"}; Default {"Other"}} }}, ReferencedDomainName, AccountName, SID, SidLength
    }

    $Report | Select-Object ServerName, StartPath, Folder, OldSID, OldDomainSID, NewSID, NewDomainSID, Both, ACLType, Operation, DateTimeStamp | Export-CSV $ReportFile -NoTypeInformation
    "`nFind CSV report of share SID history here:`n$ReportFile`n"

}



function Merge-CSV {
    <#
    .SYNOPSIS
    Combine all CSV files in a folder to a single file.
    .DESCRIPTION
    This function lists all CSV files in the specified path and then rolls them
    up into a single CSV file using the specified prefix as the file name.
    The intention of this function is that you can use it to roll up multiple CSV
    SID history ACL reports into a single file which can then be imported into a
    database for analysis.
    .PARAMETER Path
    Path to the folder where the CSV files reside.
    Defaults to the current folder.
    .PARAMETER Prefix
    This string will be prepended to the output file name.
    For example:  ACL_SID_History_20120405101500.csv
    Defaults to "ACL_SID_History".
    .EXAMPLE
    Merge-CSV
    .EXAMPLE
    Merge-CSV -Path "C:\Working Folder\Output Files"
    .EXAMPLE
    Merge-CSV -Prefix "All_SID_History"
    .EXAMPLE
    Merge-CSV -Path "C:\Working Folder\Output Files" -Prefix "All_SID_History"
    .NOTES
    The function automatically excludes previous generations of the combined CSV file as long as the prefix is the same as the one specified.
    Assumptions:
    - CSV files do not have type information row.
    - All CSV files share the same schema (column layout).
    .INPUTS
    Function takes optional Path and Prefix switches as described in the full help.
    .OUTPUTS
    The output file of combined CSVs will be created in the same path as the combined files.
    .LINK
    http://aka.ms/SIDHistory
    #>

    Param (
        [parameter()]
        [string]
        $Path = ".",
        [parameter()]
        [string]
        $Prefix = "ACL_SID_History"
    )

    $CombinedCSVFile = "$Path\$($Prefix)_$(Get-Date -UFormat %Y%m%d%H%M%S).csv"
    $AllCSV = Get-ChildItem -Path $Path -Filter "*.csv" | Where-Object {$_.name -notlike "$Prefix*" -and $_.Length -gt 0}

    # Grab the header of one representative CSV file
    Get-Content $AllCSV[0].Fullname | Select-Object -First 1 | Add-Content $CombinedCSVFile

    # Grab all non-header content of all CSV files
    ForEach ($csv in $AllCSV) {
        $FileContent = Get-Content $csv.FullName
        $Rows = $FileContent.Count
        $FileContent[1..$Rows] | Add-Content $CombinedCSVFile
    }

    "`nOutput here:`n$CombinedCSVFile`n"
}







Function Get-SIDHistoryDuplicates {
    <#
    .SYNOPSIS
    This function analyzes the SIDReport.csv or SIDReportUpdated.csv file for duplicate OldSID entries.
    .DESCRIPTION
    Duplicate SID history entries are an anomoly and should be resolved prior to translating any ACLs.
    SID history entries should not have any duplicates.
    .PARAMETER MapFile
    Path and name of the SIDReport.CSV file generated by the function Export-SIDMapping
     - OR -
    Path and name of the SIDReportUpdated.CSV file generated by the function Update-SIDMapping
    Defaults to: .\SIDReportUpdated.csv
    .EXAMPLE
    Get-SIDHistoryDuplicates
    .EXAMPLE
    Get-SIDHistoryDuplicates -MapFile ".\SIDReport.csv"
    .EXAMPLE
    Get-SIDHistoryDuplicates | Export-CSV ".\SIDHistoryDuplicates.csv" -NoTypeInformation
    .NOTES
    For best results pipe the output to Export-CSV or Out-Gridview.
    .INPUTS
    SIDReport.csv or SIDReportUpdated.csv
    .OUTPUTS
    Filtered list containing only rows with duplicate OldSID values.
    .LINK
    http://aka.ms/SIDHistory
    #>
    
    Param(
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $MapFile = ".\SIDReportUpdated.csv"
    )

    Import-Csv $MapFile | Group-Object -Property OldSID | Where-Object {$_.Count -gt 1} | ForEach {$_.Group}

}





Function Search-SIDHistoryACL {
    <#
    .SYNOPSIS
    This function automates the use of 'Export-SIDHistoryShare' and 'Convert-SIDHistoryNTFS -WhatIf' for scanning large quantities of shares using PowerShell background jobs.
    It does not update any ACLs.  It only reports on SID history use in the share paths scanned.
    .DESCRIPTION
    Scan all of the shares in a text file. (Windows servers or NAS)
      - OR -
    Scan all of the shares on each server in an OU subtree. (Windows servers only)
    Launch each share scan in a separate job for multithreading efficiency.
    Output files all have the server and share as part of the file name.
    .PARAMETER OrganizationalUnit
    Specifies the OU path for Windows servers to scan.
    Enumerates all servers in the OU subtree that have been online in the last 60 days, thus filtering out stale servers.
    Computer accounts for non-Windows servers will error out.
    Uses WMI to enumerate a list of all manually created shares on each server, and then feeds that into the two functions 'Export-SIDHistoryShare' and 'Convert-SIDHistoryNTFS -WhatIf'.
    This parameter is aliased as 'OU'.
    .PARAMETER ShareFile
    Expects a text file containing a list of shares or paths in either UNC or local absolute path format.
    Defaults to: .\shares.txt
    .PARAMETER Credential
    Often scanning file shares requires alternate credentials.
    Defaults to: Get-Credential
    .EXAMPLE
    Search-SIDHistoryACL -OrganizationalUnit 'OU=FileServers,OU=Servers,OU=na,DC=contoso,DC=com'
    .EXAMPLE
    $cred = Get-Credential
    Search-SIDHistoryACL -OU 'OU=FileServers,OU=Servers,OU=na,DC=contoso,DC=com' -Credential $cred
    Search-SIDHistoryACL -OU 'OU=FileServers,OU=Servers,OU=emea,DC=contoso,DC=com' -Credential $cred
    .EXAMPLE
    Search-SIDHistoryACL -ShareFile .\shares.txt
    .NOTES
    The OrganizationalUnit option calls both 'Export-SIDHistoryShare' and 'Convert-SIDHistoryNTFS -WhatIf' for each server under the OU specified.
    The ShareFile option calls 'Convert-SIDHistoryNTFS -WhatIf' for each share path specified in the ShareFile parameter.
    The .\SIDMap.CSV file must be in the same path from where the function is called.
    This should be used carefully on a server with plenty of RAM, because no real throttling applies based on this simple code. Do not run too many at once.
    Once all of the jobs are launched the output files will appear in the local directory.
    This function spawns a process window for each job.  Do not close the windows.  They will close automatically when complete.
    Use the Watch-Job function to monitor the background job progress and capture the job status results.  Review the job log files to see where errors occurred or jobs failed.
    .INPUTS
    .\SIDMap.csv
    .INPUTS
    .\shares.txt (or some similar name)
    .OUTPUTS
    LogFile is a txt file with a verbose record of everything found.
    .OUTPUTS
    ErrorFile is a CSV listing folders that failed the scan due to access denied, path too long, etc.
    .OUTPUTS
    ReportFile is a CSV listing all affected folders, old SID, and new SID.
    .LINK
    Export-SIDHistoryShare
    .LINK
    Convert-SIDHistoryNTFS
    .LINK
    http://aka.ms/SIDHistory
    #>
    
    Param(
        [parameter(Mandatory=$true,ParameterSetName="OU")]
        [alias("OU")]
        [string]
        [ValidateScript({Test-Path -Path "AD:$_"})]
        $OrganizationalUnit,
        [parameter(Mandatory=$true,ParameterSetName="ShareFile")]
        [string]
        [ValidateScript({Test-Path -Path $_})]
        $ShareFile = '.\shares.txt',
        [parameter()]
        $Credential = (Get-Credential)
    )

    # $Pwd is the current directory where the script is running
    $sb2 = [scriptblock]::create("Set-Location $Pwd; Import-Module SIDHistory | Out-Null")

    # Prompt for creds, because often file share access can be misconfigured and exclude Domain Admins.
    # May need to run multiple times under multiple creds.

    If ($OrganizationalUnit) {

        # Get list of servers from an OU.
        # Exclude servers that have not updated their computer object for more than 60 days, because they are likely stale and offline.
        $Servers = Get-ADComputer -filter * -SearchBase $OrganizationalUnit -Properties whenChanged | Where-Object {$_.whenChanged -gt (get-date).AddDays(-60)} | Select-Object -ExpandProperty Name
        ForEach ($ComputerName in $Servers) {

            # Grab only file shares that were manually created
            $Shares = Get-WmiObject Win32_Share -ComputerName $ComputerName -Filter "Type=0" -Credential $Credential
            ForEach ($Share in $Shares) {

                # SHARE PERMISSIONS
                $sb1 = [scriptblock]::create("Export-SIDHistoryShare $ComputerName -Reportfile ""$ComputerName $($Share.Name) report shares.csv""")
                # Must use InitializationScript block to import the modules and set the path for the input/output files.
                # http://social.technet.microsoft.com/Forums/en-US/ITCG/thread/173978e3-1500-4a2c-acbd-ff222e4a44a3
                Start-Job -Credential $Credential -ScriptBlock $sb1 -InitializationScript $sb2

                # NTFS PERMISSIONS
                $sb1 = [scriptblock]::create("Convert-SIDHistoryNTFS ""\\$ComputerName\$($Share.Name)"" -WhatIf -Logfile ""$ComputerName $($Share.Name) log NTFS.txt"" -Reportfile ""$ComputerName $($Share.Name) report NTFS.csv"" -Errorfile ""$ComputerName $($Share.Name) error NTFS.csv""")
                Start-Job -Credential $Credential -ScriptBlock $sb1 -InitializationScript $sb2
            }
        }

    } ElseIf ($ShareFile) {

        # Get a list of shares from the text file specified and exclude blank lines in the text file.
        ForEach ($Share in (Get-Content $ShareFile | Where-Object {$_.Length -gt 3})) {

            # Clean up the share path for log file naming
            $ShareClean = $Share.Replace('\',' ').Trim()

            # NTFS PERMISSIONS
            # Must use InitializationScript block to import the modules and set the path for the input/output files.
            # http://social.technet.microsoft.com/Forums/en-US/ITCG/thread/173978e3-1500-4a2c-acbd-ff222e4a44a3
            $sb1 = [scriptblock]::create("Convert-SIDHistoryNTFS ""$Share"" -WhatIf -Logfile ""$ShareClean log NTFS.txt"" -Reportfile ""$ShareClean report NTFS.csv"" -Errorfile ""$ShareClean error NTFS.csv""")
            Start-Job -Credential $Credential -ScriptBlock $sb1 -InitializationScript $sb2
        }

    }

}



Function Watch-Job {
    <#
    .SYNOPSIS
    This function displays a progress bar for the background job queue and reports on the results when all are complete.
    This function is provided to watch the Search-SIDHistoryACL background jobs.
    .DESCRIPTION
    When all jobs are no longer running it does two things and one optional thing:
    1. Receives all of the job output into joblog.txt
    2. Exports a CSV report of all job status (complete, failed, start time, end time, command, etc.)
    3. If the -Remove switch is used it will remove all of the jobs from the queue
    .PARAMETER Remove
    Specifies whether to remove all of the jobs from the queue once finished.
    .EXAMPLE
    Watch-Job
    .EXAMPLE
    Watch-Job -Remove
    .NOTES
    Review the job log files to see where job command errors occurred or jobs failed.
    Use the -Remove switch with care.
    When finished all of the errors from the jobs will scroll in the console.
    .INPUTS
    Uses Get-Job to view all jobs in the queue.
    .OUTPUTS
    .\joblog.txt
    .OUTPUTS
    .\joblog.csv
    .LINK
    Search-SIDHistoryACL
    .LINK
    http://aka.ms/SIDHistory
    #>
    
    Param(
        [parameter()]
        [switch]
        $Remove
    )

    $Jobs = Get-Job
    $Running = $Jobs | Where-Object {$_.State -eq 'Running'}

    # Loop through all of the jobs until they are complete or failed
    While ($Running) {
        If ($Running.count -gt 0) {
            Write-Progress -Activity 'Watching running jobs' -Status 'Progress:' -PercentComplete (100-(100*$Running.count/$Jobs.count))
            Start-Sleep -Seconds 1
        } Else {
            Write-Progress -Activity 'Watching running jobs' -Status 'Progress:' -PercentComplete 100
        }
        $Jobs = Get-Job
        $Running = $Jobs | Where-Object {$_.State -eq 'Running'}
    }

    # v3 Syntax: Get-Job | Receive-Job *> .\joblog.txt
    #$r = Get-Job | Receive-Job
    #$r > .\joblog.txt | Out-Null
    #$r 2>> .\joblog.txt | Out-Null
    Get-Job | Receive-Job | Out-File .\joblog.txt
    Get-Job | Select-Object * | Export-CSV .\joblog.csv -NoTypeInformation
    
    If ($Remove) {Get-Job | Remove-Job}

    Get-ChildItem .\joblog.*

}




Function Get-DomainSIDWordCount {
    <#
    .SYNOPSIS
    This function assists with identifying old domains based on string data in the account DisplayName, Description, and DistinguishedName.
    .DESCRIPTION
    The old domain SID cannot be identified when its trust has been removed.  Often the accounts from the old domain will contain a keyword that references the old domain.  These keywords could appear in the DisplayName, Description, or DistinguishedName (OU path).
    This function takes some of the guess work out of identifying these old domains by creating a word count of strings found in these attributes, hoping that will give you clues how to manually update the DomainSIDs.csv file.
    .PARAMETER SIDReport
    Points to the SIDReportUpdated.csv file generated by the cmdlet Update-SIDMapping.
    .EXAMPLE
    Get-DomainSIDWordCount
    .EXAMPLE
    Get-DomainSIDWordCount | Out-GridView
    .EXAMPLE
    Get-DomainSIDWordCount | Export-CSV .\DomainSIDWordCount.csv -NoTypeInformation
    .NOTES
    It is best to pipe this output to a grid view or CSV for ease of use.
    This report runs against all OldDomainSIDs regardless of whether they have already been identified.
    .INPUTS
    .\SIDReportUpdated.csv
    .OUTPUTS
    Report of OldDomainSID, Word, Count
    .LINK
    Export-DomainSIDs
    .LINK
    http://aka.ms/SIDHistory
    #>
    
    Param (
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_})]
        $SIDReport = '.\SIDReportUpdated.csv'
    )

    $map = Import-Csv $SIDReport

    # All domain SIDs
    $OldDomainSIDs = $map | Select-Object OldDomainSID -Unique | Select-Object -ExpandProperty OldDomainSID

    # Empty report array variable
    $report = @()

    # For each domain SID that we found...
    ForEach ($sid in $OldDomainSIDs) {

        # New word count hash table for this OldDomainSID
        $WordCount = @{}

        # Loop through each entry for this OldDomainSID
        ForEach ($entry in ($map | Where-Object {$_.OldDomainSID -eq $sid})) {

            # Word Count Of DisplayName
            ForEach ($word in $entry.DisplayName.Split(" ")) {
                If ($WordCount.Contains($word)) {
                    $WordCount.Item($word)++
                } Else {
                    $WordCount.Add($word,1)
                }
            }

            # Word Count Of DistinguishedName
            ForEach ($word in $entry.DistinguishedName.Split(",")) {
                $word = $word.Replace('OU=',$null).Replace('CN=',$null)
                If ($WordCount.Contains($word)) {
                    $WordCount.Item($word)++
                } Else {
                    $WordCount.Add($word,1)
                }
            }

            # Word Count Of Description
            ForEach ($word in $entry.Description.Split(",")) {
                $word = $word.Replace('OU=',$null).Replace('CN=',$null)
                If ($WordCount.Contains($word)) {
                    $WordCount.Item($word)++
                } Else {
                    $WordCount.Add($word,1)
                }
            }

        }

        # Create the report output for each OldDomainSID
        $WordCount.GetEnumerator() | Where-Object {$_.Value -gt 2 -and $_.Name -NotLike 'DC=*'} | Sort-Object Value -Descending |
            ForEach-Object {
                $report += New-Object -TypeName PSObject -Property @{
                    OldDomainSID = $sid;
                    Word = $_.Name;
                    Count = $_.Value
                }
            }
    }

    $report

}







Function Export-SIDMappingCustom {
	<#
	.SYNOPSIS
	Matches Active Directory objects between two domains and generates a SID
    mapping file based on a matching property value.

	.DESCRIPTION
	This allows you to create a SID mapping file for ACL translation
    regardless of SID history. This aids in scenarios where no SID history
    was used in the migration or the source environment is not simultaneously
    accessible for whatever reason (permissions, firewall, etc.).
    For example, you could manually recreate users in a new domain with
    new IDs following a different naming convention.  Then you could match
    them on a common EmployeeID attribute between both environments. The
    result would be a SID mapping file with OldSID,NewSID from the two
    domains for ACL translation.
	
	.PARAMETER ObjectType
	The type of AD objects to use for the SID mapping file.
    Must be one of the following:
       User, GlobalGroup, DomainLocalGroup, UniversalGroup

	.PARAMETER Property
	Property name to match from both old and new domain sources.
    This property must have unique values (ie. name, employeeID, etc.).
    Property name must be a valid AD attribute of the ObjectType specified.
    Property name must be the same between both environments.

	.PARAMETER OldServer
	Specifies the FQDN of the source domain controller for comparison.

	.PARAMETER NewServer
	Specifies the FQDN of the destination domain controller for comparison.

	.PARAMETER OldCSV
	Specifies the CSV file of the source domain for comparison.
    The property specified and objectSID must be named columns.
    Ignores the parameter ObjectType.

	.PARAMETER NewCSV
	Specifies the CSV file of the destination domain for comparison.
    The property specified and objectSID must be named columns.
    Ignores the parameter ObjectType.

	.PARAMETER MapFile
	Name of CSV file output.  Defaults to .\SIDMapCustom.csv

	.INPUTS
	CSV file of AD objects -OR- live domain query.

	.OUTPUTS
	CSV file of OldSID,NewSID for security translation mapping.
	Overwrites any previous version of same name.
    This file can be used as input for Convert-SIDHistoryNTFS or the ADMT.

	.EXAMPLE
	C:\PS> Export-SIDMappingCustom -OldServer dc1.olddomain.com
      -NewServer dc1.newdomain.com -ObjectType User -Property EmployeeID
    
	.EXAMPLE
	C:\PS> Export-SIDMappingCustom -OldCSV .\dlgexport.csv
      -NewServer dc1.newdomain.com -ObjectType DomainLocalGroup -Property Name
      -MapFile .\SIDMap-DLG-Contoso-AlpineSkiHouse.csv

	.EXAMPLE
	C:\PS> Export-SIDMappingCustom -OldCSV .\OldUserExport.csv
      -NewServer dc1.newdomain.com -ObjectType User -Property samAccountName

    .NOTES
    Use lines similar to these to build the CSV files for input:

    This will export all users with SID and samAccountName:
    C:\PS> Get-ADUser -Filter * -Properties objectSID, samAccountName | Export-CSV .\OldDomainUsers.csv -NoTypeInformation

    This will export all users who have an EmployeeID populated:
    C:\PS> Get-ADUser -LDAPFilter '(employeeID=*)' -Properties objectSID, EmployeeID | Export-CSV .\OldDomainUsers.csv -NoTypeInformation

    This will export all domain local groups:
    C:\PS> Get-ADGroup -Filter "groupscope -eq 'DomainLocal'" -Properties objectSID, Name | Export-CSV .\OldDomainDLGs.csv -NoTypeInformation

    In the Properties parameter you must specify ObjectSID and the name of the property you want to match for the SID mapping.

    .LINK
    http://aka.ms/SIDHistory
	#>

	Param (
        [String]
		[ValidateSet('User','GlobalGroup','DomainLocalGroup','UniversalGroup')]
		$ObjectType,
		[parameter(Mandatory=$true)]
		[String]
		$Property,
		[String]
		$OldServer,
		[String]
		$NewServer,
		[String]
		$OldCSV,
		[String]
		$NewCSV,
		[String]
		$MapFile = '.\SIDMapCustom.csv'
	)

    <#
	Param (
        [String]
		[ValidateSet('User','GlobalGroup','DomainLocalGroup','UniversalGroup')]
		$ObjectType,
		[parameter(Mandatory=$true)]
		[String]
		$Property,
		[String]
		[ValidateScript({Test-Connection $_})]
		$OldServer,
		[String]
		[ValidateScript({Test-Connection $_})]
		$NewServer,
		[String]
		[ValidateScript({Test-Path $_})]
		$OldCSV,
		[String]
		[ValidateScript({Test-Path $_})]
		$NewCSV,
		[String]
		$MapFile = '.\SIDMapCustom.csv'
	)

	#>


    Switch ($ObjectType) {
        'User'              { $LDAPFilter = "(&(objectClass=user)(objectCategory=person)($Property=*))" }
        'GlobalGroup'       { $LDAPFilter = "(&(objectClass=group)(groupType=-2147483646)($Property=*))" }
        'DomainLocalGroup'  { $LDAPFilter = "(&(objectClass=group)(groupType=-2147483643)($Property=*))" }
        'UniversalGroup'    { $LDAPFilter = "(&(objectClass=group)(groupType=-2147483640)($Property=*))" }
    }

	# Get a list of objects from each domain
    If ($NewServer) {
        $new = Get-ADObject -LDAPFilter $LDAPFilter -Properties $Property, objectSID -server $NewServer
	} Else {
        $new = Import-Csv $NewCSV
    }
    If ($OldServer) {
    	$old = Get-ADObject -LDAPFilter $LDAPFilter -Properties $Property, objectSID -server $OldServer
	} Else {
        $old = Import-Csv $OldCSV
    }

	# Compare -PassThru > Object of Name, NewSID, (empty OldSID)
	$newmatches = Compare-Object -ReferenceObject $new -DifferenceObject $old -Property $Property -IncludeEqual -ExcludeDifferent -PassThru | Select-Object @{name='Comparison';expression={$_.$Property}}, @{name='NewSID';expression={$_.objectSID}}, @{name='OldSID';expression={$null}}
	
	# Compare -PassThru > Object of Name, OldSID > make hash table for fast lookup
	$oldht = @{}
	Compare-Object -ReferenceObject $old -DifferenceObject $new -Property $Property -IncludeEqual -ExcludeDifferent -PassThru | ForEach-Object {$oldht.Add($_.$Property,$_.objectSID)}
	
	# Append OldSID using hash table lookups.
	# This is incredibly faster than n*n lookups using a where-object.
	ForEach ($entry in $newmatches) {
		$entry.OldSID = $oldht.Item($entry.Comparison)
	}

	# Select where SIDs do not match, because the built-in objects have matching default SIDs and no translation is needed there.
	Set-Content -Path $MapFile -Value $null -Force
	$newmatches | Where-Object {$_.NewSID -ne $_.OldSID} | Select-Object OldSID, NewSID | ConvertTo-CSV -NoTypeInformation | ForEach-Object {Add-Content -Path $($MapFile) -Value $_.Replace("""","")}

	# Echo completion
	"`nFind the results here:`n$MapFile`n"
}











function Get-ADObjectADSI {
    Param(
        [string]$LDAPQueryString = "(&(objectClass=user)(objectCategory=person))",
        [string[]]$Properties = @("objectSID","employeeID")
    )

    $searcher = [ADSISEARCHER][ADSI]""
    $searcher.Filter = $LDAPQueryString

    ForEach ($prop in $Properties) {
        $searcher.PropertiesToLoad.Add($prop) | Out-Null
    }

    $users = $searcher.FindAll()

    $report = @()

    ForEach ($user in $users) {
        $entry = New-Object PSObject
        ForEach ($prop in $Properties) {
            $entry | Add-Member -Force -MemberType NoteProperty -Name $prop -Value $null
        }
        ForEach ($property in $user.properties.propertynames) {
            Switch ($property) {
                'objectsid' {
                    $entry | Add-Member -Force -MemberType NoteProperty -Name $property -Value (New-Object System.Security.Principal.SecurityIdentifier $user.Properties.Item("objectsid")[0], 0).Value
                }
                'sidhistory' {
                    $sh = @()
                    ForEach ($s in $user.Properties.Item('sidHistory')) {
                        $sh += (New-Object System.Security.Principal.SecurityIdentifier $s, 0).Value
                    }
                    $entry | Add-Member -Force -MemberType NoteProperty -Name $property -Value $sh
                }
                default     {
                    $entry | Add-Member -Force -MemberType NoteProperty -Name $property -Value $user.Properties.Item($property)[0]
                }
            }
        }

        $report += $entry
    }

    $report

}











# Export module members
Export-ModuleMember -Function Export-DomainSIDs
Export-ModuleMember -Function Export-SIDMapping
Export-ModuleMember -Function Export-SIDMappingCustom
Export-ModuleMember -Function Update-SIDMapping
Export-ModuleMember -Function Convert-SIDHistoryNTFS
Export-ModuleMember -Function Get-SIDHistory
Export-ModuleMember -Function Remove-SIDHistory
Export-ModuleMember -Function Export-SIDHistoryShare
Export-ModuleMember -Function Merge-CSV
Export-ModuleMember -Function Get-SIDHistoryDuplicates
Export-ModuleMember -Function Search-SIDHistoryACL
Export-ModuleMember -Function Watch-Job
Export-ModuleMember -Function Get-DomainSIDWordCount
Export-ModuleMember -Function Get-ADObjectADSI

