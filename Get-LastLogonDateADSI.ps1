# enter a distinguished name for either an OU or a container
$LDAPdn = 'LDAP://DC=my,DC=test,DC=com'
$results = @()

Get-Content $PSScriptRoot\listofaccounts.txt | ForEach-Object {

    $userToCheck = $_
    $Searcher = New-Object DirectoryServices.DirectorySearcher$
    $Searcher.Filter = "(&(objectCategory=person)(sAMAccountName=$userToCheck))"
    
    $Searcher.SearchRoot = $LDAPdn
    $account = $Searcher.FindOne()

    if ($account -ne '') 
    {
        [string]$lastlogonTimestamp = ($account.properties).lastlogontimestamp
    
        $results += [PSCustomObject]@{
            UserName = [string]($account.Properties).samaccountname
            LastLogonDate = [datetime]::FromFileTime([int64]$lastlogonTimestamp)
            Enabled  = ([string]($account.Properties).useraccountcontrol -band 0x2) -ne 2
        }

    }
}

$results | export-csv $PSScriptRoot\output.csv -NoTypeInformation