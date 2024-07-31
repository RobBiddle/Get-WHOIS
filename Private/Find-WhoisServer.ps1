
<#
.SYNOPSIS
    Finds the WHOIS server for a domain name.
.DESCRIPTION
    Function to lookup the WHOIS server for a domain name.
    Initially this will attempt to resolve the WHOIS server for the TLD using whois-servers.net.
    If that fails, it will attempt to find the WHOIS server for the TLD using the IANA WHOIS Service.
.NOTES
    Author: Robert D. Biddle
    Date: 2023-10-18
    Find-WhoisServer - PowerShell function to lookup WHOIS server for a domain name.
    Copyright (C) 2023 Robert D. Biddle

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
.LINK
    https://github.com/RobBiddle/Get-WHOIS/
.EXAMPLE
    Find-WhoisServer -DomainName "whois-servers.net"
    This will return the following information:

    Address      : 192.30.45.30
    IPAddress    : 192.30.45.30
    QueryType    : A
    IP4Address   : 192.30.45.30
    Name         : whois.verisign-grs.com
    Type         : A
    CharacterSet : Unicode
    Section      : Answer
    DataLength   : 4
    TTL          : 30
.PARAMETER DomainName
    The domain name to query in FQDN format.
#>
function Find-WhoisServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
                if ($_ -match "^\b((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}\b$") {
                    $true
                }
                else {
                    throw "Invalid DomainName format."
                }
            })]
        [string]$DomainName
    )

    $tld = $DomainName.Split(".")[-1]
    Write-Verbose "TLD: $tld"

    # Attempt to resolve the WHOIS server for the TLD using whois-servers.net
    # whois-servers.net is a service that provides WHOIS server information via DNS
    try {
        Write-Verbose "Attempting to resolve WHOIS server for TLD $tld via DNS using whois-servers.net."
        $whoisDnsServers = Resolve-DnsName "$tld.whois-servers.net" -ErrorAction Stop
        $whoisDnsServers | Add-Member -MemberType NoteProperty -Name FoundVia -Value "whois-servers.net" -PassThru
        $whoisDnsServers = $whoisDnsServers | Select-Object -Property * | Where-Object IP4Address
    }
    catch {
        Write-Verbose "Failed to resolve WHOIS server for TLD $tld using whois-servers.net."
    }

    # Attempt to find the WHOIS server for the TLD using the IANA WHOIS Service
    # The IANA WHOIS Service is provided using the WHOIS protocol on port 43
    # https://www.iana.org/help/whois
    # Data is returned in a colon delimited "key: value" format. Comment lines begin with a "%" symbol. Text is encoded using UTF-8.
    # The URL to query will look like this: https://www.iana.org/whois?q=$tld
    if (-not $whoisDnsServers) {
        try {
            Write-Verbose "Attempting to find WHOIS server for TLD $tld via WHOIS protocol using IANA WHOIS Service."
            # Fetch the raw HTML content
            $ianaResponse = Invoke-WebRequest -Uri "https://www.iana.org/whois?q=$tld" -ErrorAction Stop
            $rawHtmlContent = $ianaResponse.Content
            
            # Convert HTML content to string
            $htmlAsString = $rawHtmlContent.ToString()
    
            # Use regex to find the WHOIS server URL in the HTML content
            $whoisServerRegex = 'whois:\s*(?<WhoisServer>[^\s]+)'
            if ($htmlAsString -match $whoisServerRegex) {
                $whoisDnsServersForTld = $matches['WhoisServer']
                Write-Verbose "Found WHOIS Server: $whoisDnsServersForTld"
            } else {
                Write-Verbose "Failed to find WHOIS server for TLD $tld using IANA WHOIS Service."
            }
    
            $whoisDnsServers = Resolve-DnsName $whoisDnsServersForTld -ErrorAction Stop
            $whoisDnsServers | Add-Member -MemberType NoteProperty -Name FoundVia -Value "IANA WHOIS Service" -PassThru
            $whoisDnsServers | Select-Object -Property * | Where-Object IP4Address
        }
        catch {
            Write-Verbose "Failed to find WHOIS server for TLD $tld using IANA WHOIS Service."
        }
        
        if (-not $whoisDnsServers) {
            Write-Error "Failed to find WHOIS server for TLD $tld."
        }
    }
}
