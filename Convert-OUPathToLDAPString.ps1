<#
.Synopsis
   This takes an OU path in a form like 'ad.contoso.com/someOU/someotherOU'
   and converts it into an LDAP string 'ou=someotherOU,ou=someOU,dc=ad,dc=contoso,dc=com'

   I may have my terminology wrong :-)

.EXAMPLE
   Convert-OUPathToLDAPString -OUPath 'ad.contoso.com/someOU/anotherOU'

.NOTES
   Author: Stu (kewalaka@gmail.com)
#>
function Convert-OUPathToLDAPString
{
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # The OU path to convert to an LDAP string, e.g. 'ad.contoso.com/someOU/someotherOU'
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]        
        $OUPath
    )

    $OUsplit = [array]$OUPath.split('/')

    $convertedOU = ""

    # using for interator explicitly rather than foreach to have access to current object easily
    # and ensure order
    for ($i=0; $i -lt $OUSplit.Count; $i++)
    {
        if ($i -eq 0)
        {
            # this is the root domain object
            # prepend with dc= & change '.' to dc=
            $convertedOU = "dc=$($Ousplit[$i].Replace(".",",dc="))"
        }
        else
        {
            # these are OUs
            # prepend with ou= & add to the front of the existing string
            $convertedOU = "ou=$($OUsplit[$i])," + $convertedOU
        }
    }

    return $convertedOU
}

Convert-OUPathToLDAPString -OUPath 'ad.northwind.com/Computers/Servers/Test Servers'