@('samAccountName1', 'samAccountName2') | foreach {
    $username = $_
    Write-Host "`nChecking...$username"
    $u = get-aduser $username -properties *,'msDS-UserPasswordExpiryTimeComputed'
    Write-Host "Password expires:" $([datetime]::fromfiletime($u.'msDS-UserPasswordExpiryTimeComputed'))
    Write-Host "Account expires:" $($u.AccountExpirationDate)
    Write-Host "Account enabled:" $($u.Enabled)
}

