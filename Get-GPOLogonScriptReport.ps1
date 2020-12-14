<#
    .SYSNOPSIS
        Generates a report showing all logon scripts being used in a GPO.

    .DESCRIPTION
        Generates a report showing all logon scripts being used in a GPO. Scans all of the GPOs in a domain.

    .NOTES
        Name: Get-GPOLogonScriptReport
        Author: Boe Prox
        Created: 05 Oct 2013

    .EXAMPLE
        .\Get-GPOLogonScriptReport.ps1 | Export-Csv -NotTypeInformation -Path 'GPOLogonScripts.csv'

        Description
        -----------
        Generates a report of all GPOs using logon scripts and then exports the data to a CSV file.
#>
Try {
    Import-Module GroupPolicy -ErrorAction Stop
    $gpos = @(Get-GPO -All)
    $count = $gpos.count
    $i=0
    ForEach ($gpo in $gpos) {
        Start-Sleep -Seconds 5
        $i++
        Write-Progress -Activity 'GPO Scan' -Status ("GPO: {0}" -f $gpo.DisplayName) -PercentComplete (($i/$count)*100)
        $xml = [xml]($gpo | Get-GPOReport -ReportType XML)
        #User logon script
        $userScripts = @($xml.GPO.User.ExtensionData | Where {$_.Name -eq 'Scripts'})
        If ($userScripts.count -gt 0) {
            $userScripts.extension.Script | ForEach {
                New-Object PSObject -Property @{
                    GPOName = $gpo.DisplayName
                    ID = $gpo.ID
                    GPOState = $gpo.GpoStatus
                    GPOType = 'User'
                    Type = $_.Type
                    Script = $_.command
                    ScriptType = $_.command -replace '.*\.(.*)','$1'
                }
            }
        }
        #Computer logon script
        $computerScripts = @($xml.GPO.Computer.ExtensionData | Where {$_.Name -eq 'Scripts'})
        If ($computerScripts.count -gt 0) {
            $computerScripts.extension.Script | ForEach {
                New-Object PSObject -Property @{
                    GPOName = $gpo.DisplayName
                    ID = $gpo.ID
                    GPOState = $gpo.GpoStatus
                    GPOType = 'Computer'
                    Type = $_.Type
                    Script = $_.command
                    ScriptType = $_.command -replace '.*\.(.*)','$1'
                }
            }
        }
    }
} Catch {
    Write-Warning ("{0}" -f $_.exception.message)
}

