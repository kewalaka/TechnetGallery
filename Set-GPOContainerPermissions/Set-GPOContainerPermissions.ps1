
<#
.Synopsis
   This script allows groups to be added to the default ACL for group policy objects,
   either with modify or read only permissions, this can be use to  ensures that a specific set
   of permissions are applied by default to new Group Policy Objects (GPOs).
   
   It works by modifying the defaultSecurityDescriptor attribute on the Group-Policy-Container
   schema class object.

   You must be a member of the Schema Admins group to perform this task.

.DESCRIPTION
  
  This script will modify the defaultSecurityDescriptor attribute on the Group-Policy-Container
  schema class object, which ensures that a specific set of permissions are applied by default
  to new Group Policy Objects (GPOs).

  It's been setup to add groups with either/or:
  - Modify Permissions
  - Read Permissions

  This is the defaultSecurityDescriptor of the Group-Policy-Container class object:
    D:P(A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;DA)(A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;EA)
    (A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;CO)(A;CI;RPWPCCDCLCLORCWOWDSDDTSW;;;SY)
    (A;CI;RPLCLORC;;;AU)(OA;CI;CR;edacfd8f-ffb3-11d1-b41d-00a0c968f939;;AU)(A;CI;LCRPLORC;;;ED)

  Where...
  - (A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;DA) = Domain Admins
  - (A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;EA) = Enterprise Admins
  - (A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;CO) = Creator Owner
  - (A;CI;RPWPCCDCLCLORCWOWDSDDTSW;;;SY) = System
  - (A;CI;RPLCLORC;;;AU) = Authenticated Users
  - (OA;CI;CR;edacfd8f-ffb3-11d1-b41d-00a0c968f939;;AU) = Authenticated Users
  - (A;CI;LCRPLORC;;;ED) = Enterprise Domain Controllers

  This translates to the following:

  ACE Type:
  - A = ACCESS ALLOWED
  - OA = OBJECT ACCESS ALLOWED: ONLY APPLIES TO A SUBSET OF THE OBJECT(S).
 
  ACE Flags:
  - CI = CONTAINER INHERIT: Child objects that are containers, such as directories, inherit the ACE as an explicit ACE.

  Permissions:
  - RC = Read Permissions
  - SD = Delete
  - WD = Modify Permissions
  - WO = Modify Owner
  - RP = Read All Properties
  - WP = Write-Verbose All Properties
  - CC = Create All Child Objects
  - DC = Delete All Child Objects
  - LC = List Contents
  - SW = All Validated Writes
  - LO = List Object
  - DT = Delete Subtree
  - CR = All Extended Rights

  Trustee:
  - DA = Domain Admins
  - EA = Enterprise Admins
  - CO = Creator Owner
  - SY = System
  - AU = Authenticated Users
  - ED = Enterprise Domain Controllers

  So we simply need to append these:
  - (A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;<Creator Owners Group Sid>)

  Some good references to help you understand this further:
  - http://www.sdmsoftware.com/general-stuff/group-policy-delegation/
  - http://support.microsoft.com/kb/321476
  - http://clintboessen.blogspot.com/2011/08/ad-delegation-how-to-set-default.html
  - https://blogs.technet.microsoft.com/askds/2008/04/18/the-security-descriptor-definition-language-of-love-part-1/
  - https://blogs.technet.microsoft.com/askds/2008/05/07/the-security-descriptor-definition-language-of-love-part-2/

  This script is based on:
  - A script Jeremy Saunders.
    http://www.jhouseconsulting.com/2016/06/29/script-to-modify-the-defaultsecuritydescriptor-attribute-on-the-group-policy-container-schema-class-object-1668
  - A script published by Peter Hinchley 10th Oct 2015: Set Default Permissions for New Group Policy Objects
    http://hinchley.net/2015/10/10/set-default-permissions-for-new-group-policy-objects/

.NOTES
  
  Original script name: Modify-GroupPolicyContainer.ps1
  
  Release 1.3
  
  Original Written by Jeremy Saunders (jeremy@jhouseconsulting.com) 11th November 2011
  Modified by Jeremy Saunders (jeremy@jhouseconsulting.com) 28th June 2016
    - To remove use of Quest AD cmdlets

  Modified by Stu (kewalaka@gmail.com) 20th December 2020
    - changed to a cmdlet, added parameter sets and modified to support 'Whatif'.

.EXAMPLE
  # To provide 'GPO Admins' modify rights to the default security group for group policies
  Set-GPOContainerPermissions -ModifyGroup 'GPO Admins'

.EXAMPLE
  # To provide 'GPO Read Only' read only rights to the default security group for group policies
  Set-GPOContainerPermissions -ReadOnlyGroup 'GPO Read Only'

.EXAMPLE
  # To reset permissions to defaults
  Set-GPOContainerPermissions -Reset

.EXAMPLE
  # To run in 'whatif' mode and advise what will be changed.
  Set-GPOContainerPermissions -ModifyGroup 'MyGroup' -WhatIf

#>
function Set-GPOContainerPermissions {
    [CmdletBinding(DefaultParameterSetName = 'Update', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    Param
    (
        # Add the specified group with read only permissions
        [Parameter(ParameterSetName = 'Update', Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$ReadOnlyGroup,

        # Add the specified group with modify permissions
        [Parameter(ParameterSetName = 'Update', Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$ModifyGroup,

        # Reset GPO container permissions to the default
        [Parameter(ParameterSetName = 'Reset', Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [switch]$ResetDefault
    )

    Begin {

        # honour settings passed 
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }

    Process {

        $defaultDescriptor = @"
        D:P(A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;DA)(A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;EA)(A;CI;RPWPCCDCLCLOLORCWOWDSDDTSW;;;CO)(A;CI;RPWPCCDCLCLORCWOWDSDDTSW;;;SY)(A;CI;RPLCLORC;;;AU)(OA;CI;CR;edacfd8f-ffb3-11d1-b41d-00a0c968f939;;AU)(A;CI;LCRPLORC;;;ED)
"@        
        if (-not $ResetDefault -and $ReadOnlyGroup -eq "" -and $ModifyGroup -eq "") {
            Write-Warning "Specify either a read only group, a modify group, or both.  Otherwise, specify -Reset to set back to defaults"
            return
        }
        
        # Get Group Membership of current user
        $groups = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups | ForEach-Object {
            $_.Translate([System.Security.Principal.NTAccount])
        }
    
        # Check if current user is a member of Schema Admins
        $IsMemberOfSchemaAdmins = (($groups -like "*\Schema Admins").Count -gt 0)
    
        If ($IsMemberOfSchemaAdmins) {
            Write-Verbose "The current user is a member of the Schema Admins group." 
    
            # Import the Active Directory Module
            try {
                Import-Module ActiveDirectory    
            }
            catch {
                Write-Warning "Active Directory PowerShell module could not be loaded, is it installed?"
                return   
            }
    
            # Get Domain information.
            $domain = Get-ADDomain
    
            # Get Schema Master FSMO role holder.
            $SchemaMaster = (Get-ADForest -Server $domain.Forest).SchemaMaster
            Write-Verbose "The Schema Master is: $SchemaMaster" 
    
            # Get the Naming Context (NC) for the Schema
            $schemaNamingContext = (Get-ADRootDSE).schemaNamingContext
    
            # Get existing security descriptor for group policy container from schema partition in Active Directory.
            $descriptor = ($container = Get-ADObject -Server $SchemaMaster "CN=Group-Policy-Container,$schemaNamingContext" -Properties defaultSecurityDescriptor).defaultSecurityDescriptor
            Write-Verbose "The existing security descriptor is: $descriptor" 
    
            $message = 'Group policy default ACL:'
    
            If ($ResetDefault) {
                $descriptor = $defaultDescriptor
                $message += " reset to default settings." 
            }
    
            If ($ReadOnlyGroup -ne "") {
                Write-Verbose "Adding the read only group '$ReadOnlyGroup' to the security descriptor." 
    
                switch ($ReadOnlyGroup) {
                    "Domain Computers" {
                        # Use the commonly used acronym of DC for the well-known SID
                        $reader = "DC";
                        Break
                    }
                    "Authenticated Users" {
                        # Use the commonly used acronym of AU for the well-known SID
                        $reader = "AU";
                        Break
                    }
                    default {
                        # Get SID of ReadOnlyGroup.
                        $reader = New-Object System.Security.Principal.NTAccount($domain.NetBIOSName, "$ReadOnlyGroup") 
                        try {
                            $reader = $reader.Translate([System.Security.Principal.SecurityIdentifier]).value
                        }
                        catch {
                            Write-Warning "Group '$ReadOnlyGroup' can not be found in AD."
                            return
                        }
                    }
                }
    
                # Set the access control entry for the Read Only group.
                $descriptor = $descriptor + "(A;CI;LCRPLORC;;;$reader)"
                $message = " add group '$ReadOnlyGroup' (read only rights)"
            }
    
            If ($ModifyGroup -ne "") {
                Write-Verbose "Adding the modify group '$ModifyGroup' to the security descriptor." 
                # Get SID of ModifyGroup.
                $modifier = New-Object System.Security.Principal.NTAccount($domain.NetBIOSName, "$ModifyGroup")
                try {
                    $modifier = $modifier.Translate([System.Security.Principal.SecurityIdentifier]).value                    
                }
                catch {
                    Write-Warning "Group '$ModifyGroup' can not be found in AD."
                    return                    
                }
                # Set the access control entry for the Modify group.
                $descriptor = $descriptor + "(A;CI;RPWPCCDCLCLORCWOWDSDDTSW;;;$modifier)"

                $message += " add group '$ModifyGroup' (modify rights)"
            }

            if ($Force -or $PSCmdlet.ShouldProcess($message)) {
                Write-Verbose ('[{0}] Reached command' -f $MyInvocation.MyCommand)
                # Concatenate the access control entries with the existing security descriptor.
                $container | Set-ADObject -Replace @{defaultSecurityDescriptor = "$descriptor"; } -Server $SchemaMaster

                $newDescriptor = (Get-ADObject -Server $SchemaMaster "CN=Group-Policy-Container,$schemaNamingContext" -Properties defaultSecurityDescriptor).defaultSecurityDescriptor
                Write-Verbose "The new security descriptor after the change is: $newDescriptor"                
            }
    
        }
        Else {
            write-warning "The current user is NOT a member of the Schema Admins group." 
            write-warning "This is a requirement to run this script." 
        }
    }
}

<# suggested alternative method mentioned by Vincent Daily on disqus

Just because I don't like to work with strings :)

$GPODefault = "CN=Group-Policy-Container"
$GPOIdentity = "$GPODefault,$((Get-ADRootDSE).SchemaNamingContext)"
$GPOSchema = Get-ADObject -Identity $GPOIdentity -Properties "defaultSecurityDescriptor"

$GPOSchemaSD = new-object System.Security.AccessControl.RawSecurityDescriptor($GPOSchema.defaultSecurityDescriptor)

#Domain Computers
#from well-known SID https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/security-identifiers-in-windows
$DomainComputers = new-object System.Security.Principal.SecurityIdentifier `
([System.Security.Principal.WellKnownSidType]::AccountComputersSid,(Get-ADDomain).DomainSID)

# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.commonace.-ctor?redirectedfrom=MSDN&view=net-5.0#System_Security_AccessControl_CommonAce__ctor_System_Security_AccessControl_AceFlags_System_Security_AccessControl_AceQualifier_System_Int32_System_Security_Principal_SecurityIdentifier_System_Boolean_System_Byte___
$GPOSchemaACE = New-Object System.Security.AccessControl.CommonAce(
[System.Security.AccessControl.AceFlags]::ContainerInherit,
[System.Security.AccessControl.AceQualifier]::AccessAllowed,
[System.DirectoryServices.ActiveDirectoryRights]::GenericRead,
$DomainComputers, $false, $null)
$GPOSchemaSD.DiscretionaryAcl.InsertAce($GPOSchemaSD.DiscretionaryAcl.Count,$GPOSchemaACE)
$GPOSchemaSDNew = $GPOSchemaSD.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)

#Uncomment to write to your AD
#Set-ADObject -Identity $GPOIdentity -Replace @{defaultSecurityDescriptor=$GPOSchemaSDNew}

#>