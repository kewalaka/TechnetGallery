<#-----------------------------------------------------------------------------
SID History PowerShell Module v1.6.1
Ashley McGlone, Microsoft Premier Field Engineer
http://aka.ms/SIDHistory
August, 2014

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

This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at http://www.microsoft.com/info/cpyright.htm.
-----------------------------------------------------------------------------#>


#.ExternalHelp SIDHistory.psm1-Help.xml
function Export-SIDMapping {

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
            $LogFileStream.WriteLine("Inherited")
        } Else {
            $ACLEntrySID = $null
            # Remove the trailing ")"
            $ACLEntry = $ACLSplit[5].TrimEnd(")")
            $ACLEntrySIDMatches = [regex]::Matches($ACLEntry,"(S(-\d+){2,8})")
            $ACLEntrySIDMatches | ForEach-Object {$ACLEntrySID = $_.value}
            If ($ACLEntrySID) {
                $LogFileStream.WriteLine("Old SID: $ACLEntrySID")
                If ($SIDMapHash.Contains($ACLEntrySID)) {
                    $NewEntry = $SDDLSplit[$i].Replace($ACLEntrySID,$SIDMapHash.($ACLEntrySID))
                    # Do the ADD or REPLACE
                    If ($Add) {
                        $LogFileStream.WriteLine("New SID: $($SIDMapHash.($ACLEntrySID)) ADD")
                        $SDDLSplit += $NewEntry
                    } Else {
                        $LogFileStream.WriteLine("New SID: $($SIDMapHash.($ACLEntrySID)) REPLACE")
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
                    $LogFileStream.WriteLine("No SID history entry")
                }
            } Else {
                $LogFileStream.WriteLine("Not inherited - No SID to translate")
            }
        }
    }

    If ($SDDLChanged) {
        $NewSDDLString = $SDDLSplit -Join "("
        $LogFileStream.WriteLine("New SDDL string: $NewSDDLString")
        return $NewSDDLString
    } Else {
        $LogFileStream.WriteLine("SDDL did not change.")
        return $null
    }

}


#.ExternalHelp SIDHistory.psm1-Help.xml
function Convert-SIDHistoryNTFS {
    Param (
        [parameter(Mandatory=$true)]
        [string]
        [ValidateScript({Test-Path -LiteralPath $_})]
        $StartPath,
        [parameter()]
        [string]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        $MapFile = ".\SIDMap.csv",
        [parameter()]
        [string]
        $ErrorFile = ".\NTFS_SID_Translation_Report_$(Get-Date -UFormat %Y%m%d%H%M%S)_ERRORS.csv",
        [parameter()]
        [string]
        $ErrorFileXML = ".\NTFS_SID_Translation_Report_$(Get-Date -UFormat %Y%m%d%H%M%S)_ERRORS.xml",
        [parameter()]
        [string]
        $LogFile = $(Join-Path -Path $PWD -ChildPath "NTFS_SID_Translation_Report_$(Get-Date -UFormat %Y%m%d%H%M%S).txt"),
        [parameter()]
        [string]
        $ReportFile = ".\NTFS_SID_Translation_Report_$(Get-Date -UFormat %Y%m%d%H%M%S).csv",
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
    #Get-Date | Out-File -FilePath $LogFile
    $LogFileStream = New-Object System.IO.StreamWriter $LogFile
    $LogFileStream.WriteLine($(Get-Date))
    $LogFileStream.WriteLine("")

    If (-not $WhatIf) {
        ""
        "This script will update ACL entries recursively in the StartPath specified."
        "This could trigger a backup of all updated files."
        "Run the command using the -WhatIf switch first."
        $input = Read-Host "Are you sure you wish to proceed? (Y/N)"
        If ($input -eq "") { return } Else {
            If ($input.substring(0,1) -ne "y") { return }
        }
        $LogFileStream.WriteLine("Security translation is live and changes will be committed.")
    } Else {
        $LogFileStream.WriteLine("AUDIT MODE: Security translation is not live and changes will not be committed.")
    }

    $LogFileStream.WriteLine("")
    $LogFileStream.WriteLine("Log file is $LogFile")
    $LogFileStream.WriteLine("Report file is $ReportFile")
    $LogFileStream.WriteLine("Map file is $MapFile")
    $LogFileStream.WriteLine("StartPath is $StartPath")
    $LogFileStream.WriteLine("WhatIf is $WhatIf")
    $LogFileStream.WriteLine("Operation is $(If ($Add) {'ADD'} Else {'REPLACE'})")

    # === END SETUP ===

    # === BEGIN BODY ===

    # Import SID mapping file
    # File format is:
    # OldSID,NewSID
    $SIDMapHash = @{}
    Import-CSV $MapFile | ForEach-Object {$SIDMapHash.Add($_.OldSID,$_.NewSID)}
    $LogFileStream.WriteLine("")
    $LogFileStream.WriteLine("SID mapping file imported.")
    $LogFileStream.WriteLine("")

    $LogFileStream.WriteLine("Beginning security enumeration.")
    $LogFileStream.WriteLine("")

    # Initialize CSV report output
    $script:report = @()

    write-progress -activity "Collecting folders to scan..." -Status "Progress: " -PercentComplete 0

    # Get folder list for security translation
    # Start by grabbing the root folder itself
    # Add the folders in this order so that we hit the root first
    $folders = @()
    $folders += Get-Item -LiteralPath $StartPath -Force | Select-Object -ExpandProperty FullName

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
	#$subfolders = Get-Childitem -LiteralPath $StartPath -Force -Recurse -ErrorVariable +ErrorLog -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $true} | Select-Object -ExpandProperty FullName
	$subfolders = Get-Childitem -LiteralPath $StartPath -Force -Recurse -ErrorVariable +ErrorLog -ErrorAction SilentlyContinue -Directory | Select-Object -ExpandProperty FullName

    # We don't want to add a null object to the list if there are no subfolders
    If ($subfolders) {$folders += $subfolders}
    $i = 0
    $FolderCount = $folders.count

    ForEach ($folder in $folders) {

        $LogFileStream.WriteLine("=== Next Folder ===")

        Write-Progress -activity "Scanning folders" -CurrentOperation $folder -Status "Progress: " -PercentComplete ($i/$FolderCount*100)
        $i++

        # Get-ACL cannot report some errors out to the ErrorVariable.
        # Therefore we have to capture this error using other means.
        Try {
            $acl = Get-ACL -LiteralPath $folder -ErrorAction Continue
        }
        Catch {
            $ErrorLog += New-Object PSObject -Property @{CategoryInfo=$_.CategoryInfo;TargetObject=$folder}
        }
        $LogFileStream.WriteLine($folder)
        #$LogFileStream.WriteLine($acl.path)
        $LogFileStream.WriteLine($acl.SDDL)

        Try {
            $acl.access | ForEach-Object {$LogFileStream.WriteLine($($_ | Select-Object *))}
        }
        Catch {
            # Non-critical error resolving ACL entry domain(s).
        }
        
        # If we don't have access, then the SDDL will be incomplete and cause errors.
		# Also, there is a Connect issue filed for paths containing a '[' character that returns a null ACL object.
        # This is fixed in PSv3 with the Get-ACL -LiteralPath parameter.
        #If ($acl.SDDL.Contains("(")) {   # This line errors when calling a method on a null value.
        If ($acl.SDDL) {
            $NewSDDL = Parse-SDDL $acl.SDDL -Add $Add
            If ($NewSDDL -ne $null) {
                If (-not $WhatIf) {
                    $acl.SetSecurityDescriptorSddlForm($NewSDDL)
                    Set-Acl -LiteralPath $acl.path -ACLObject $acl
                    $LogFileStream.WriteLine("SDDL updated.")
                }
            }
        } Else {
            $NewSDDL = $null
            $LogFileStream.WriteLine("SDDL read error.")
			#$ErrorLog += New-Object PSObject -Property @{CategoryInfo='Error: Invalid character in path (maybe).';TargetObject=$folder}
        }
        $LogFileStream.WriteLine("")
    }

    # === END BODY ===

    ""
    $script:report | Select-Object ServerName, StartPath, Folder, OldSID, OldDomainSID, NewSID, NewDomainSID, Both, ACLType, Operation, DateTimeStamp | Export-CSV $ReportFile -NoTypeInformation
    "Find CSV report of security translation here:"
    $ReportFile

    $LogFileStream.WriteLine("")

    #$Error | Select-Object ScriptStackTrace, CategoryInfo, TargetObject | Export-Csv $ErrorFile -NoTypeInformation
    $ErrorLog | Select-Object CategoryInfo, TargetObject | Export-Csv $ErrorFile -NoTypeInformation
    "Find CSV report of errors here:"
    $ErrorFile

    $ErrorLog | Export-CliXML $ErrorFileXML
    "Find XML report of errors here:"
    $ErrorFileXML

    $LogFileStream.WriteLine("")

    $LogFileStream.WriteLine($(Get-Date))
    "Find complete log file here:"
    $LogFile
    ""

    $LogFileStream.Close()

}


#.ExternalHelp SIDHistory.psm1-Help.xml
function Export-DomainSIDs {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Update-SIDMapping {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
function Remove-SIDHistory {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
function Get-SIDHistory {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
function Export-SIDHistoryShare {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
function Merge-CSV {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Get-SIDHistoryDuplicates {
    Param(
        [parameter()]
        [string]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $MapFile = ".\SIDReportUpdated.csv"
    )

    Import-Csv $MapFile | Group-Object -Property OldSID | Where-Object {$_.Count -gt 1} | ForEach {$_.Group}
}


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Search-SIDHistoryACL {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Watch-Job {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Get-DomainSIDWordCount {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
Function Export-SIDMappingCustom {
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


#.ExternalHelp SIDHistory.psm1-Help.xml
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

#                                                                           sdg