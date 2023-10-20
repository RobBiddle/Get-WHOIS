<#
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
#>

# Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot Source Function Files
@($Public + $Private) | ForEach-Object {
    $FileToImport = $_
    Try {
        .$FileToImport.FullName
    }
    Catch {
        Write-Error -Message "Failed to import: $($FileToImport.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.Basename -Cmdlet $Public.Basename