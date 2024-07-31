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
            $parsedResponse = $whoisResponse -split "\r?\n" | Where-Object { $_ -match ":" }
            $properties = @{}
            
            foreach ($line in $parsedResponse) {
                if ($line -match '^(.*?):\s*(.*)') {
                    $name = $matches[1].Trim()
                    $value = $matches[2].Trim()
            
                    # Remove special characters from the property name, except for spaces
                    # $name = $name -replace '[^a-zA-Z0-9\s]', ''
            
                    # Remove special characters from the property name, including spaces
                    $name = $name -replace '[^a-zA-Z0-9]', ''
            
                    # Remove leading and trailing spaces
                    $name = $name.Trim()
            
                    $matchFound = $false
                    $DesiredPropertyNames = @("Created", "Creation", "Updated", "Expiration", "Expires", "Expiry", "Date", "Email", "Server", "Status", "Registrant", "Registrar", "Registry", "Domain", "IANA")
                    foreach ($DesiredPropertyName in $DesiredPropertyNames) {
                        if ($name -imatch $DesiredPropertyName) {
                            $matchFound = $true
                        }
                    }
            
                    if (-not $matchFound) {
                        continue
                    }
            
                    $IgnoredStringFound = $false
                    $IgnoredNameStrings = @("NOTICE", "TERMS OF USE", "https")
                    foreach ($IgnoredString in $IgnoredNameStrings) {
                        if ($name -imatch $IgnoredString) {
                            # Write-Verbose "The line contains the ignored string: $IgnoredString"
                            $IgnoredStringFound = $true
                        }
                    }
            
                    if ($IgnoredStringFound) {
                        continue
                    }
            
                    if ($properties.ContainsKey($name)) {
                        if ($properties[$name] -isnot [array]) {
                            $properties[$name] = @($properties[$name])
                        }
                        $properties[$name] += $value
                    }
                    else {
                        $properties[$name] = $value
                    }
                }
            }
            
            # Calculate Days Until Expiration
            # Define a list of possible property names for expiration dates
            $expirationPropertyNames = @("ExpirationDate", "ExpiryDate", "Expires", "RegistryExpiryDate")
            
            # Initialize variable to store the days until expiration
            $DaysUntilExpiration = $null
            
            # Loop through each property name to find the first one that exists and calculate the days until expiration
            foreach ($propertyName in $expirationPropertyNames) {
                if ($properties[$propertyName]) {
                    $DaysUntilExpiration = (New-TimeSpan -Start (Get-Date) -End $properties[$propertyName]).Days
                    $properties["DaysUntilExpiration"] = $DaysUntilExpiration
                    break # Exit the loop once the first valid expiration date is found and processed
                }
            }

            # Add the WHOIS server name to the properties
            $properties["WhoisServerName"] = $wServerName

            # Create a new ordered dictionary to hold sorted properties
            $sortedProperties = [ordered]@{}
            
            # Sort the properties and add them to the sorted ordered dictionary
            $properties.GetEnumerator() | Sort-Object Name | ForEach-Object {
                $sortedProperties[$_.Key] = $_.Value
            }
            
            # Convert the sorted ordered dictionary directly to a PSCustomObject
            $whoisObject = [PSCustomObject]$sortedProperties

            # Add alias property for NameServers
            # This is being done to avoid creating a breaking change
            if ($whoisObject.NameServer -and (-not $whoisObject.NameServers)) {
                $whoisObject | Add-Member -MemberType AliasProperty -Name NameServers -Value NameServer -Force
            }

            # Add property for WhoisLookupServiceUsed
            if ($whoisDnsServers.FoundVia) {
                $whoisObject | Add-Member -MemberType NoteProperty -Name WhoisLookupService -Value ($whoisDnsServers.FoundVia | Select-Object -Unique) -Force
            }

            # Output the object
            $whoisObject
        }
        else {
            $whoisResponse
        }
    }
}
