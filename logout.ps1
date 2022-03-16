<#
    .SYNOPSIS
    Logut pip from codeartifact.

    .DESCRIPTION
    This script resets pip for the use of the standard pypi repositories.

    .INPUTS
    None. You cannot pipe objects to login.ps1.

    .OUTPUTS
    None. login.ps1 does not generate any output.

    .EXAMPLE
    PS> .\logout.ps1
#>
$ErrorActionPreference="Stop"

if (pip) {
  Write-Output "Resetting pip...}"
  pip config unset global.index-url
  pip config unset global.extra-index-url
} else {
    Write-Output "Pip not found and therefore not configured."
}