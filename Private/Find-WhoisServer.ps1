
<#
.SYNOPSIS
    Queries DNS for the WHOIS server for a domain name.
.DESCRIPTION
    Function to lookup the WHOIS server for a domain name by querying the WHOIS DNS server for the TLD of the domain name.
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
    $whoisDnsServersForTld = Resolve-DnsName "$tld.whois-servers.net" | Select-Object -Property *
    $whoisDnsServersForTld | Where-Object IPAddress
}