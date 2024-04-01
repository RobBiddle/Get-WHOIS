<#
.SYNOPSIS
    Gets WHOIS information for a domain name by querying the WHOIS server for the domain name.
.DESCRIPTION
    Queries the WHOIS server for a domain name and returns summary information by default, 
    the Registrar, Creation Date, Expiration Date, and DNS Name Servers.
    The WHOIS server is determined by the TLD of the domain name, unless specified.
.NOTES
    Author: Robert D. Biddle
    Date: 2023-10-18
    Get-WHOIS - PowerShell Module to lookup WHOIS information for a domain name.
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
    Get-WHOIS -DomainName "whois-servers.net"
    This will return the following information:

    DomainName          : whois-servers.net
    CreationDate        : 1999-03-31 12:00:00 AM
    DaysUntilExpiration : 162
    ExpirationDate      : 2024-03-31 12:00:00 AM
    NameServers         : {UDNS1.ULTRADNS.NET, UDNS2.ULTRADNS.NET}
    Registrar           : TucowsDomainsInc.
    WhoisServerName     : whois.verisign-grs.com
.EXAMPLE
    Get-WHOIS -DomainName "whois-servers.net" -OutputFormat "detail"
    This will return the full WHOIS response for the domain name.
.PARAMETER DomainName
    The domain name to query in FQDN format.
.PARAMETER OutputFormat
    The output format for the WHOIS information.  Valid values are "summary" and "detail".
    
    "summary" is the default value and returns a PSCustomObject with Properties:
    DomainName, CreationDate, DaysUntilExpiration, ExpirationDate, NameServers, Registrar, WhoisServerName
    
    "detail" returns the full WHOIS response.
.PARAMETER whoisServer
    The FQDN of a WHOIS server to query for the domain name.
    If not specified, the WHOIS server is determined by the TLD of the domain name.
.PARAMETER whoisPort
    The port to use when querying the WHOIS server.
    If not specified, the default port of 43 is used.
.OUTPUTS
    Selected.System.Management.Automation.PSCustomObject
#>
function Get-WHOIS {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
                if ($_ -match "^\b((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}\b$") {
                    $true
                }
                else {
                    throw "Invalid FQDN format."
                }
            })]
        [string]$DomainName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("summary", "detail")]
        [string]$OutputFormat = "summary",

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$whoisServer,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [int]$whoisPort = 43
    )

    begin {
        # Import the Find-WhoisServer function
        . "$PSScriptRoot\..\Private\Find-WhoisServer.ps1"
    }
    process {
        if (-NOT $whoisServer) {
            # Set the appropriate WHOIS server and port based on the TLD of the domain name
            $whoisDnsServers = Find-WhoisServer -DomainName $DomainName
            $wServer = $whoisDnsServers | Where-Object IP4Address | Select-Object -first 1
        }
        else {
            $wServer = Resolve-DnsName $whoisServer | Where-Object IP4Address | Select-Object -first 1
        }

        # Get the IP address of the WHOIS server
        $wServerIP = ($wServer | Where-Object IP4Address).IP4Address | Select-Object -first 1
        # Get the name of the WHOIS server
        $wServerName = ($wServer | Where-Object IP4Address | Select-Object -first 1).Name
        # Query the WHOIS server for the domain name
        $whoisQuery = $DomainName + "`r`n"
        $whoisSocket = New-Object System.Net.Sockets.TcpClient($wServerIP, $whoisPort)
        $whoisStream = $whoisSocket.GetStream()
        $whoisWriter = New-Object System.IO.StreamWriter($whoisStream)
        $whoisWriter.WriteLine($whoisQuery)
        $whoisWriter.Flush()
        $whoisReader = New-Object System.IO.StreamReader($whoisStream)
        $whoisResponse = $whoisReader.ReadToEnd()
        $whoisReader.Close()
        $whoisWriter.Close()
        $whoisSocket.Close()
        if ($OutputFormat -eq "summary") {
            # Remove blank lines
            $whoisResponse = $whoisResponse -replace "`r`n`r`n", "`r`n"
            # Split whoisResponse into lines and parse the WHOIS response for the basic information
            $whoisResponse = $whoisResponse -split "`r`n"
            $Registrar = $whoisResponse | Select-String -Pattern "Registrar: " | Select-Object -First 1
            $Registrar = $registrar -replace "Registrar:", ""
            $Registrar = $registrar -replace "[\s-[\r\n]]+", ""
            $CreationDate = $whoisResponse | Select-String -Pattern "Creation Date: " | Select-Object -First 1
            $CreationDate = $CreationDate -replace "Creation Date:", ""
            $CreationDate = $(if($CreationDate) {Get-Date $CreationDate})
            $ExpirationDate = $whoisResponse | Select-String -Pattern "Registry Expiry Date: " | Select-Object -First 1
            $ExpirationDate = $ExpirationDate -replace "Registry Expiry Date:", ""
            $ExpirationDate = $(if($ExpirationDate) {Get-Date $ExpirationDate})
            $DaysUntilExpiration = $(if($ExpirationDate) {(New-TimeSpan -Start (Get-Date) -End (Get-Date $ExpirationDate)).Days})
            $NameServers = $whoisResponse | Select-String -Pattern "Name Server: " | Select-Object -Unique
            $NameServers = $NameServers -replace "Name Server:", ""
            $NameServers = $NameServers -replace "[\s-[\r\n]]+", ""
            $whoisSummary = @{
                DomainName          = $DomainName
                Registrar           = $Registrar
                CreationDate        = $CreationDate
                DaysUntilExpiration = $DaysUntilExpiration
                ExpirationDate      = $ExpirationDate
                NameServers         = @($NameServers)
                WhoisServerName     = $wServerName
            }

            # Return the basic information
            New-Object -TypeName PSCustomObject -Property $whoisSummary | Select-Object DomainName, CreationDate, DaysUntilExpiration, ExpirationDate, NameServers, Registrar, WhoisServerName
        }
        else {
            $whoisResponse
        }
    }
}
