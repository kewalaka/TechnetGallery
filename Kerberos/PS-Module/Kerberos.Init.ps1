if ([IntPtr]::Size -eq 8)
{
	Add-Type -Path $PSScriptRoot\KerberosLibx64.dll
}
else
{
	Add-Type -Path $PSScriptRoot\KerberosLibx86.dll
}

#using Update-FormatData and not FormatsToProcess in the PSD1 as FormatsToProcess does not offer
#putting format data in front of the default data. This is required to make the new formatter the default ones.
Update-FormatData -PrependPath $PSScriptRoot\Kerberos.format.ps1xml

if ([IntPtr]::Size -eq 8)
{
	Write-Host "64-Bit Types added" -ForegroundColor DarkGreen
}
else
{
	Write-Host "32-Bit Types added" -ForegroundColor DarkGreen
}
Write-Host "Kerberos Module loaded" -ForegroundColor DarkGreen