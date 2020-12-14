#region Get-Tickets
function Get-Tickets
{
<#
	.SYNOPSIS
		Get the Kerberos tickets of the current logon session
		
	.DESCRIPTION
		This cmdlet does prettt much the same like klist. It lists all the tickets in the Kerberos cache.
		
		The structure of the kerberos tickets returned is:
		- ServerName
        - Realm
        - StartTime
        - EndTime
        - RenewTime
        - EncryptionType
        - TicketFlags
	
	.INPUTS
		Nothing
	
	.OUTPUTS
		KerberosLib.KerberosTicket
			
	.EXAMPLE
		PS C:\> Get-Tickets

		ServerName                       Realm     StartTime            EndTime               Enc. Type               Flags
		----------                       -----     ---------            -------               ---------               -----
		krbtgt/F3.NET                    C1.F3.NET 8/24/2011 3:01:20 PM 8/25/2011 12:49:50 AM RC4_HMAC                OkAsDelegate, PreAuthent, Renewable,...
		krbtgt/C1.F3.NET                 C1.F3.NET 8/24/2011 2:49:50 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 PreAuthent, Renewable, Forwarded, Fo...
		krbtgt/C1.F3.NET                 C1.F3.NET 8/24/2011 2:49:50 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 PreAuthent, Initial, Renewable, Forw...
		cifs/f3dc1.f3.net                F3.NET    8/24/2011 3:01:20 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 OkAsDelegate, PreAuthent, Renewable,...
		LDAP/F3C1DC1.c1.f3.net/c1.f3.net C1.F3.NET 8/24/2011 2:55:55 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 OkAsDelegate, PreAuthent, Renewable,...
		cifs/f3c1ex1.c1.f3.net           C1.F3.NET 8/24/2011 2:49:54 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 PreAuthent, Renewable, Forwardable
		cifs/F3C1DC1.c1.f3.net           C1.F3.NET 8/24/2011 2:49:50 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 OkAsDelegate, PreAuthent, Renewable,...

		Description
		-----------
		Get all tickets from the cache
		
	.EXAMPLE
		PS C:\> Get-Tickets | Where-Object { $_.ServerName -like "krbtgt*" }
		
		ServerName       Realm     StartTime            EndTime               Enc. Type               Flags
		----------       -----     ---------            -------               ---------               -----
		krbtgt/F3.NET    C1.F3.NET 8/24/2011 3:01:20 PM 8/25/2011 12:49:50 AM RC4_HMAC                OkAsDelegate, PreAuthent, Renewable, Forwardable
		krbtgt/C1.F3.NET C1.F3.NET 8/24/2011 2:49:50 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 PreAuthent, Renewable, Forwarded, Forwardable
		krbtgt/C1.F3.NET C1.F3.NET 8/24/2011 2:49:50 PM 8/25/2011 12:49:50 AM AES256_CTS_HMAC_SHA1_96 PreAuthent, Initial, Renewable, Forwardable

		Description
		-----------
		Get all tickets from the cache and filters them to just the the TGTs
#>
	[cmdletBinding()]
	param( )
	
	begin { }
	
	process
	{
		[KerberosLib.KerberosTicketCache]::GetTickets()
	}
	
	end { }
}
#endregion

#region Remove-Tickets
function Remove-Tickets
{
<#
	.SYNOPSIS
		Removes or purges all Kerberos tickets of the current logon session
		
	.DESCRIPTION
		This cmdlet does prettt much the same like 'klist purge'. It purges all the tickets in the Kerberos cache.

	.INPUTS
		Nothing
	
	.OUTPUTS
		Nothing
			
	.EXAMPLE
		PS C:\> Remove-Tickets; Get-Tickets
		Kerberos tickets purged
		
		Description
		-----------
		Removes all tickets from the cache
		
	.EXAMPLE
		PS C:\> Remove-Tickets; Get-Tickets
		Kerberos tickets purged
		
		Description
		-----------
		Removes all tickets from the cache and verifies that with Get-Ticket
#>
	[cmdletBinding()]
	param( )
	
	begin { }
	
	process
	{
		[KerberosLib.KerberosTicketCache]::PurgeTickets()
		Write-Host "Kerberos tickets purged"
	}
	
	end { }
}
#endregion