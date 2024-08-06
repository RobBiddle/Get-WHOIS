---
Module Name: Get-WHOIS
online version: https://github.com/RobBiddle/Get-WHOIS/
schema: 2.0.0
---

# Get-WHOIS

## Installation

### PowerShell Gallery

<https://www.powershellgallery.com/packages/Get-WHOIS/>

```powershell
Install-Module -Name Get-WHOIS
```

## SYNOPSIS

Gets WHOIS information for a domain name by querying the WHOIS server for the domain name.

## SYNTAX

```powershell
Get-WHOIS [-DomainName] <String> [[-OutputFormat] <String>] [[-whoisServer] <String>] [[-whoisPort] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION

Queries the WHOIS server for a domain name and returns summary information by default,
the Registrar, Creation Date, Expiration Date, and DNS Name Servers.
The WHOIS server is determined by the TLD of the domain name, unless specified.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-WHOIS -DomainName whois-servers.net
```

This will return the following information:

```yaml
CreationDate               : 1999-03-31T05:00:00Z
DaysUntilExpiration        : 236
DomainName                 : WHOIS-SERVERS.NET
DomainStatus               : {clientDeleteProhibited https://icann.org/epp#clientDeleteProhibited, clientTransferProhibited https://icann.org/epp#clientTransferProhibited,
                             clientUpdateProhibited https://icann.org/epp#clientUpdateProhibited}
Lastupdateofwhoisdatabase  : 2024-08-06T15:36:03Z <<<
NameServer                 : {UDNS1.ULTRADNS.NET, UDNS2.ULTRADNS.NET}
Registrar                  : Tucows Domains Inc.
RegistrarAbuseContactEmail : domainabuse@tucows.com
RegistrarAbuseContactPhone : +1.4165350123
RegistrarIANAID            : 69
RegistrarURL               : http://www.tucows.com
RegistrarWHOISServer       : whois.tucows.com
RegistryDomainID           : 4846261_DOMAIN_NET-VRSN
RegistryExpiryDate         : 2025-03-31T04:00:00Z
UpdatedDate                : 2024-03-02T05:01:56Z
WhoisServerName            : whois.verisign-grs.com
NameServers                : {UDNS1.ULTRADNS.NET, UDNS2.ULTRADNS.NET}
WhoisLookupService         : whois-servers.net
```

### EXAMPLE 2

```powershell
Get-WHOIS -DomainName "whois-servers.net" -OutputFormat "detail"
```

This will return the full WHOIS response for the domain name.

## PARAMETERS

### -DomainName

The domain name to query in FQDN format.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -OutputFormat

The output format for the WHOIS information.
Valid values are "summary" and "detail".

"summary" is the default value and returns a PSCustomObject.
The properties returned will vary based on the WHOIS results returned.
Most results will at least return:
CreationDate,
DaysUntilExpiration (a calculated value returned as an integer),
DomainName,
NameServer,
NameServers (alias property of NameServer for backwards compatibility)
Registrar,
UpdatedDate
WhoisLookupService
WhoisServerName

For reference, here are the properties returned by [Example 1](https://github.com/RobBiddle/Get-WHOIS/tree/main?tab=readme-ov-file#example-1):

```powershell
   TypeName: System.Management.Automation.PSCustomObject

Name                       MemberType    Definition
----                       ----------    ----------
NameServers                AliasProperty NameServers = NameServer
Equals                     Method        bool Equals(System.Object obj)
GetHashCode                Method        int GetHashCode()
GetType                    Method        type GetType()
ToString                   Method        string ToString()
CreationDate               NoteProperty  string CreationDate=1999-03-31T05:00:00Z
DaysUntilExpiration        NoteProperty  int DaysUntilExpiration=236
DomainName                 NoteProperty  string DomainName=WHOIS-SERVERS.NET
DomainStatus               NoteProperty  Object[] DomainStatus=System.Object[]
Lastupdateofwhoisdatabase  NoteProperty  string Lastupdateofwhoisdatabase=2024-08-06T15:36:03Z <<<
NameServer                 NoteProperty  Object[] NameServer=System.Object[]
Registrar                  NoteProperty  string Registrar=Tucows Domains Inc.
RegistrarAbuseContactEmail NoteProperty  string RegistrarAbuseContactEmail=domainabuse@tucows.com
RegistrarAbuseContactPhone NoteProperty  string RegistrarAbuseContactPhone=+1.4165350123
RegistrarIANAID            NoteProperty  string RegistrarIANAID=69
RegistrarURL               NoteProperty  string RegistrarURL=http://www.tucows.com
RegistrarWHOISServer       NoteProperty  string RegistrarWHOISServer=whois.tucows.com
RegistryDomainID           NoteProperty  string RegistryDomainID=4846261_DOMAIN_NET-VRSN
RegistryExpiryDate         NoteProperty  string RegistryExpiryDate=2025-03-31T04:00:00Z
UpdatedDate                NoteProperty  string UpdatedDate=2024-03-02T05:01:56Z
WhoisLookupService         NoteProperty  System.String WhoisLookupService=whois-servers.net
WhoisServerName            NoteProperty  string WhoisServerName=whois.verisign-grs.com
```

"detail" returns the full WHOIS response.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Summary
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -whoisPort

The port to use when querying the WHOIS server.
If not specified, the default port of 43 is used.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 43
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -whoisServer

The FQDN of a WHOIS server to query for the domain name.
If not specified, the WHOIS server is determined by the TLD of the domain name.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

```yaml
Type: Selected.System.Management.Automation.PSCustomObject
```

## NOTES

Author: Robert D.Biddle
Date: 2023-10-18
Get-WHOIS - PowerShell Module to lookup WHOIS information for a domain name.
Copyright (C) 2023 Robert D. Biddle

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.
If not, see \<<https://www.gnu.org/licenses/\>>.

## RELATED LINKS

[https://github.com/RobBiddle/Get-WHOIS/](https://github.com/RobBiddle/Get-WHOIS/)
