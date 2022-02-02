[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $Navn
)
Write-Host "Hei $Navn!"