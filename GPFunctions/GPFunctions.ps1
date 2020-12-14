<##############################################################################
Ashley McGlone
Microsoft Premier Field Engineer
http://aka.ms/GoateePFE
May 2015

This script includes the following functions:
Get-GPLink
Get-GPUnlinked
Copy-GPRegistryValue

All code has been tested on Windows Server 2008 R2 with PowerShell v2.0.

Requires:
-PowerShell v2 or above
-RSAT
-ActiveDirectory module
-GroupPolicy module

See the end of this file for sample usage.
Press F5 to run the script and only put the functions into memoory.
The BREAK statement keeps the sample code from running.
Edit and highlight the sample code.  Then run it with F8.

See the code below for comments and documentation inline.


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
##############################################################################>


<#
.SYNOPSIS
This function creates a report of all group policy links, their locations, and
their configurations in the current domain.  Output is a CSV file.
.DESCRIPTION
Long description
.PARAMETER Path
Optional parameter.  If specified, it will return GPLinks for a specific OU or domain root rather than all GPLinks.
.EXAMPLE
Get-GPLink | Out-GridView
.EXAMPLE
Get-GPLink -Path 'OU=Users,OU=IT,DC=wingtiptoys,DC=local' | Out-GridView
.EXAMPLE
Get-GPLink -Path 'DC=wingtiptoys,DC=local' | Out-GridView
.EXAMPLE
Get-GPLink -Path 'DC=wingtiptoys,DC=local' | ForEach-Object {$_.DisplayName}
.NOTES
For more information on gPLink, gPOptions, and gPLinkOptions see:
 [MS-GPOL]: Group Policy: Core Protocol
  http://msdn.microsoft.com/en-us/library/cc232478.aspx
 2.2.2 Domain SOM Search
  http://msdn.microsoft.com/en-us/library/cc232505.aspx
 2.3 Directory Service Schema Elements
  http://msdn.microsoft.com/en-us/library/cc422909.aspx
 3.2.5.1.5 GPO Search
  http://msdn.microsoft.com/en-us/library/cc232537.aspx

SOM is an acronym for Scope of Management, referring to any location where
a group policy could be linked: domain, OU, site.

This GPO report does not list GPO filtering by permissions.

Helpful commands when inspecting GPO links:
Get-ADOrganizationalUnit -Filter {Name -eq 'Production'} | Select-Object -ExpandProperty LinkedGroupPolicyObjects
Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName, LinkedGroupPolicyObjects
Get-ADObject -Identity 'OU=HR,DC=wingtiptoys,DC=local' -Property gPLink
#>
Function Get-GPLink {
    Param(
        [Parameter()]
        [string]
        $Path
    )
    
        # Requires RSAT installed and features enabled
        Import-Module GroupPolicy
        Import-Module ActiveDirectory
    
        # Pick a DC to target
        $Server = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName
    
        # Grab a list of all GPOs
        $GPOs = Get-GPO -All -Server $Server | Select-Object ID, Path, DisplayName, GPOStatus, WMIFilter, CreationTime, ModificationTime, User, Computer
    
        # Create a hash table for fast GPO lookups later in the report.
        # Hash table key is the policy path which will match the gPLink attribute later.
        # Hash table value is the GPO object with properties for reporting.
        $GPOsHash = @{}
        ForEach ($GPO in $GPOs) {
            $GPOsHash.Add($GPO.Path,$GPO)
        }
    
        # Empty array to hold all possible GPO link SOMs
        $gPLinks = @()
    
        If ($PSBoundParameters.ContainsKey('Path')) {
    
            $gPLinks += `
             Get-ADObject -Server $Server -Identity $Path -Properties name, distinguishedName, gPLink, gPOptions |
             Select-Object name, distinguishedName, gPLink, gPOptions
    
        } Else {
    
            # GPOs linked to the root of the domain
            #  !!! Get-ADDomain does not return the gPLink attribute
            $gPLinks += `
             Get-ADObject -Server $Server -Identity (Get-ADDomain).distinguishedName -Properties name, distinguishedName, gPLink, gPOptions |
             Select-Object name, distinguishedName, gPLink, gPOptions
    
            # GPOs linked to OUs
            #  !!! Get-GPO does not return the gPLink attribute
            $gPLinks += `
             Get-ADOrganizationalUnit -Server $Server -Filter * -Properties name, distinguishedName, gPLink, gPOptions |
             Select-Object name, distinguishedName, gPLink, gPOptions
    
            # GPOs linked to sites
            $gPLinks += `
             Get-ADObject -Server $Server -LDAPFilter '(objectClass=site)' -SearchBase "CN=Sites,$((Get-ADRootDSE).configurationNamingContext)" -SearchScope OneLevel -Properties name, distinguishedName, gPLink, gPOptions |
             Select-Object name, distinguishedName, gPLink, gPOptions
        }
    
        # Empty report array
        $report = @()
    
        # Loop through all possible GPO link SOMs collected
        ForEach ($SOM in $gPLinks) {
            # Filter out policy SOMs that have a policy linked
            If ($SOM.gPLink) {
    
                # If an OU has 'Block Inheritance' set (gPOptions=1) and no GPOs linked,
                # then the gPLink attribute is no longer null but a single space.
                # There will be no gPLinks to parse, but we need to list it with BlockInheritance.
                If ($SOM.gPLink.length -gt 1) {
                    # Use @() for force an array in case only one object is returned (limitation in PS v2)
                    # Example gPLink value:
                    #   [LDAP://cn={7BE35F55-E3DF-4D1C-8C3A-38F81F451D86},cn=policies,cn=system,DC=wingtiptoys,DC=local;2][LDAP://cn={046584E4-F1CD-457E-8366-F48B7492FBA2},cn=policies,cn=system,DC=wingtiptoys,DC=local;0][LDAP://cn={12845926-AE1B-49C4-A33A-756FF72DCC6B},cn=policies,cn=system,DC=wingtiptoys,DC=local;1]
                    # Split out the links enclosed in square brackets, then filter out
                    # the null result between the closing and opening brackets ][
                    $links = @($SOM.gPLink -split {$_ -eq '[' -or $_ -eq ']'} | Where-Object {$_})
                    # Use a for loop with a counter so that we can calculate the precedence value
                    For ( $i = $links.count - 1 ; $i -ge 0 ; $i-- ) {
                        # Example gPLink individual value (note the end of the string):
                        #   LDAP://cn={7BE35F55-E3DF-4D1C-8C3A-38F81F451D86},cn=policies,cn=system,DC=wingtiptoys,DC=local;2
                        # Splitting on '/' and ';' gives us an array every time like this:
                        #   0: LDAP:
                        #   1: (null value between the two //)
                        #   2: distinguishedName of policy
                        #   3: numeric value representing gPLinkOptions (LinkEnabled and Enforced)
                        $GPOData = $links[$i] -split {$_ -eq '/' -or $_ -eq ';'}
                        # Add a new report row for each GPO link
                        $report += New-Object -TypeName PSCustomObject -Property @{
                            Name              = $SOM.Name;
                            OUDN              = $SOM.distinguishedName;
                            PolicyDN          = $GPOData[2];
                            Precedence        = $links.count - $i
                            GUID              = "{$($GPOsHash[$($GPOData[2])].ID)}";
                            DisplayName       = $GPOsHash[$GPOData[2]].DisplayName;
                            GPOStatus         = $GPOsHash[$GPOData[2]].GPOStatus;
                            WMIFilter         = $GPOsHash[$GPOData[2]].WMIFilter.Name;
                            GPOCreated        = $GPOsHash[$GPOData[2]].CreationTime;
                            GPOModified       = $GPOsHash[$GPOData[2]].ModificationTime;
                            UserVersionDS     = $GPOsHash[$GPOData[2]].User.DSVersion;
                            UserVersionSysvol = $GPOsHash[$GPOData[2]].User.SysvolVersion;
                            ComputerVersionDS = $GPOsHash[$GPOData[2]].Computer.DSVersion;
                            ComputerVersionSysvol = $GPOsHash[$GPOData[2]].Computer.SysvolVersion;
                            Config            = $GPOData[3];
                            LinkEnabled       = [bool](!([int]$GPOData[3] -band 1));
                            Enforced          = [bool]([int]$GPOData[3] -band 2);
                            BlockInheritance  = [bool]($SOM.gPOptions -band 1)
                        } # End Property hash table
                    } # End For
                }
            }
        } # End ForEach
    
        # Output the results to CSV file for viewing in Excel
        $report |
         Select-Object OUDN, BlockInheritance, LinkEnabled, Enforced, Precedence, `
          DisplayName, GPOStatus, WMIFilter, GUID, GPOCreated, GPOModified, `
          UserVersionDS, UserVersionSysvol, ComputerVersionDS, ComputerVersionSysvol, PolicyDN
    }
    
    <#########################################################################sdg#>
    
    <#
    .SYNOPSIS
    Used to discover GPOs that are not linked anywhere in the domain.
    .DESCRIPTION
    All GPOs in the domain are returned. The Linked property indicates true if any links exist.  The property is blank if no links exist.
    .EXAMPLE
    Get-GPUnlinked | Out-GridView
    .EXAMPLE
    Get-GPUnlinked | Where-Object {!$_.Linked} | Out-GridView
    .NOTES
    This function does not look for GPOs linked to sites.
    Use the Get-GPLink function to view those.
    #>
    Function Get-GPUnlinked {
    
        Import-Module GroupPolicy
        Import-Module ActiveDirectory
    
        # BUILD LIST OF ALL POLICIES IN A HASH TABLE FOR QUICK LOOKUP
        $AllPolicies = Get-ADObject -Filter * -SearchBase "CN=Policies,CN=System,$((Get-ADDomain).Distinguishedname)" -SearchScope OneLevel -Property DisplayName, whenCreated, whenChanged
        $GPHash = @{}
        ForEach ($Policy in $AllPolicies) {
            $GPHash.Add($Policy.DistinguishedName,$Policy)
        }
    
        # BUILD LIST OF ALL LINKED POLICIES
        $AllLinkedPolicies = Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty LinkedGroupPolicyObjects -Unique
        $AllLinkedPolicies += Get-ADDomain | Select-Object -ExpandProperty LinkedGroupPolicyObjects -Unique
    
        # FLAG EACH ONE WITH A LINKED PROPERTY
        ForEach ($Policy in $AllLinkedPolicies) {
            $GPHash[$Policy].Linked = $true
        }
    
        # POLICY LINKED STATUS
        $GPHash.Values | Select-Object whenCreated, whenChanged, Linked, DisplayName, Name, DistinguishedName
    
        ### NOTE THAT whenChanged IS NOT A REPLICATED VALUE
    }
    
    <#########################################################################sdg#>
    
    
    # HELPER FUNCTION FOR Copy-GPRegistryValue
    Function DownTheRabbitHole {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String[]]
        $rootPaths,
        [Parameter()]
        [String]
        $SourceGPO,
        [Parameter()]
        [String]
        $DestinationGPO
    )
    
        $ErrorActionPreference = 'Continue'
    
        ForEach ($rootPath in $rootPaths) {
    
            Write-Verbose "SEARCHING PATH [$SourceGPO] [$rootPath]"
            Try {
                $children = Get-GPRegistryValue -Name $SourceGPO -Key $rootPath -Verbose -ErrorAction Stop
            }
            Catch {
                Write-Warning "REGISTRY PATH NOT FOUND [$SourceGPO] [$rootPath]"
                $children = $null
            }
    
            $Values = $children | Where-Object {-not [string]::IsNullOrEmpty($_.PolicyState)}
            If ($Values) {
                ForEach ($Value in $Values) {
                    If ($Value.PolicyState -eq "Delete") {
                        Write-Verbose "SETTING DELETE [$SourceGPO] [$($Value.FullKeyPath):$($Value.Valuename)]"
                        If ([string]::IsNullOrEmpty($_.Valuename)) {
                            Write-Warning "EMPTY VALUENAME, POTENTIAL SETTING FAILURE, CHECK MANUALLY [$SourceGPO] [$($Value.FullKeyPath):$($Value.Valuename)]"
                            Set-GPRegistryValue -Disable -Name $DestinationGPO -Key $Value.FullKeyPath -Verbose | Out-Null
                        } Else {
    
                            # Warn if overwriting an existing value in the DestinationGPO.
                            # This usually does not get triggered for DELETE settings.
                            Try {
                                $OverWrite = $true
                                $AlreadyThere = Get-GPRegistryValue -Name $DestinationGPO -Key $rootPath -ValueName $Value.Valuename -Verbose -ErrorAction Stop
                            }
                            Catch {
                                $OverWrite = $false
                            }
                            Finally {
                                If ($OverWrite) {
                                    Write-Warning "OVERWRITING PREVIOUS VALUE [$SourceGPO] [$($Value.FullKeyPath):$($Value.Valuename)] [$($AlreadyThere.Value -join ';')]"
                                }
                            }
    
                            Set-GPRegistryValue -Disable -Name $DestinationGPO -Key $Value.FullKeyPath -ValueName $Value.Valuename -Verbose | Out-Null
                        }
                    } Else {
                        # PolicyState = "Set"
                        Write-Verbose "SETTING SET [$SourceGPO] [$($Value.FullKeyPath):$($Value.Valuename)]"
    
                        # Warn if overwriting an existing value in the DestinationGPO.
                        # This can occur when consolidating multiple GPOs that may define the same setting, or when re-running a copy.
                        # We do not check to see if the values match.
                        Try {
                            $OverWrite = $true
                            $AlreadyThere = Get-GPRegistryValue -Name $DestinationGPO -Key $rootPath -ValueName $Value.Valuename -Verbose -ErrorAction Stop
                        }
                        Catch {
                            $OverWrite = $false
                        }
                        Finally {
                            If ($OverWrite) {
                                Write-Warning "OVERWRITING PREVIOUS VALUE [$SourceGPO] [$($Value.FullKeyPath):$($Value.Valuename)] [$($AlreadyThere.Value -join ';')]"
                            }
                        }
    
                        $Value | Set-GPRegistryValue -Name $DestinationGPO -Verbose | Out-Null
                    }
                }
            }
                    
            $subKeys = $children | Where-Object {[string]::IsNullOrEmpty($_.PolicyState)} | Select-Object -ExpandProperty FullKeyPath
            if ($subKeys) {
                DownTheRabbitHole -rootPaths $subKeys -SourceGPO $SourceGPOSingle -DestinationGPO $DestinationGPO -Verbose
            }
        }
    }
    
    
    <#
    .SYNOPSIS
    Copies GPO registry settings from one or more policies to another.
    .DESCRIPTION
    Long description
    .PARAMETER Mode
    Indicates which half of the GPO settings to copy.  Three possible values: All, User, Computer.
    .PARAMETER SourceGPO
    Display name of one or more GPOs from which to copy settings.
    .PARAMETER DestinationGPO
    Display name of destination GPO to receive the settings.
    If the destination GPO does not exist, then it creates it.
    .EXAMPLE
    Copy-GPRegistryValue -Mode All -SourceGPO "IE Test" -DestinationGPO "NewMergedGPO" -Verbose
    .EXAMPLE
    Copy-GPRegistryValue -Mode All -SourceGPO "foo", "Starter User", "Starter Computer" -DestinationGPO "NewMergedGPO" -Verbose
    .EXAMPLE
    Copy-GPRegistryValue -Mode User -SourceGPO 'User Settings' -DestinationGPO 'New Merged GPO' -Verbose
    .EXAMPLE
    Copy-GPRegistryValue -Mode Computer -SourceGPO 'Computer Settings' -DestinationGPO 'New Merged GPO' -Verbose
    .NOTES
    Helpful commands when inspecting GPO links:
    Get-ADOrganizationalUnit -Filter {Name -eq 'Production'} | Select-Object -ExpandProperty LinkedGroupPolicyObjects
    Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName, LinkedGroupPolicyObjects
    Get-ADObject -Identity 'OU=HR,DC=wingtiptoys,DC=local' -Property gPLink
    #>
    Function Copy-GPRegistryValue {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('All','User','Computer')]
        [String]
        $Mode = 'All',
        [Parameter()]
        [String[]]
        $SourceGPO,
        [Parameter()]
        [String]
        $DestinationGPO
    )
        Import-Module GroupPolicy -Verbose:$false
    
        $ErrorActionPreference = 'Continue'
    
        Switch ($Mode) {
            'All'      {$rootPaths = "HKCU\Software","HKLM\System","HKLM\Software"; break}
            'User'     {$rootPaths = "HKCU\Software"                              ; break}
            'Computer' {$rootPaths = "HKLM\System","HKLM\Software"                ; break}
        }
        
        If (Get-GPO -Name $DestinationGPO -ErrorAction SilentlyContinue) {
            Write-Verbose "DESTINATION GPO EXISTS [$DestinationGPO]"
        } Else {
            Write-Verbose "CREATING DESTINATION GPO [$DestinationGPO]"
            New-GPO -Name $DestinationGPO -Verbose | Out-Null
        }
    
        $ProgressCounter = 0
        $ProgressTotal   = @($SourceGPO).Count   # Syntax for PSv2 compatibility
        ForEach ($SourceGPOSingle in $SourceGPO) {
    
            Write-Progress -PercentComplete ($ProgressCounter / $ProgressTotal * 100) -Activity "Copying GPO settings to: $DestinationGPO" -Status "From: $SourceGPOSingle"
    
            If (Get-GPO -Name $SourceGPOSingle -ErrorAction SilentlyContinue) {
    
                Write-Verbose "SOURCE GPO EXISTS [$SourceGPOSingle]"
    
                DownTheRabbitHole -rootPaths $rootPaths -SourceGPO $SourceGPOSingle -DestinationGPO $DestinationGPO -Verbose
    
                Get-GPOReport -Name $SourceGPOSingle -ReportType Xml -Path "$pwd\report_$($SourceGPOSingle).xml"
                $nonRegistry = Select-String -Path "$pwd\report_$($SourceGPOSingle).xml" -Pattern "<Extension " -SimpleMatch | Where-Object {$_ -notlike "*RegistrySettings*"}
                If (($nonRegistry | Measure-Object).Count -gt 0) {
                    Write-Warning "SOURCE GPO CONTAINS NON-REGISTRY SETTINGS FOR MANUAL COPY [$SourceGPOSingle]"
                    Write-Warning ($nonRegistry -join "`r`n")
                }
    
            } Else {
                Write-Warning "SOURCE GPO DOES NOT EXIST [$SourceGPOSingle]"
            }
    
            $ProgressCounter++
        }
    
        Write-Progress -Activity "Copying GPO settings to: $DestinationGPO" -Completed -Status "Complete"
    
    }
    
    <#########################################################################sdg#>
    BREAK
    
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
    