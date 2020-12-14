# TODO add a nice header
# This version also works on 2012R2 - returns the same output as the built in 2016 version
# but uses ADSI.
function Get-LocalGroupMember
{
    param (
        $Computer = $env:COMPUTERNAME,
        $Name = "Administrators"
    )
    $ADSIGroup = [ADSI]"WinNT://$Computer/$Name,group"
    $Members = @($ADSIGroup.psbase.Invoke("Members"))
    $results = @()
    # Format the Output
    $members | ForEach-Object {
        $name = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
        $class = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
        $path = $_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null)
    
        # Find out if this is a local or domain object
        if ($path -like "*/$Computer/*"){
            $Type = "Local"
        }
        else
        {
            $Type = "ActiveDirectory"
        }
        $results += [PSCustomObject] @{
           Name = $name
           ObjectClass = $class
           PrincipalSource = $type
        }
    }
    return $results
}