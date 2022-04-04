<#
    .SYNOPSIS
    Login to codearticact for pip.

    .DESCRIPTION
    This script configures pip for the use of a closed source aws codeartifact repository.
    It assumes that the user is already logged in to aws using aws sso.

    .PARAMETER AwsProfile
    Specifies the name of the aws profile which will be used to access codeartifact.

    .PARAMETER Region
    Aws region of the codeartficact repository.

    .PARAMETER Domain
    Domain name of the codeartifact repository.

    .PARAMETER DomainOwner
    Account number for the codeartifact repository.

    .PARAMETER Repository
    Name of the codeartifact repository.
  
    .INPUTS
    None. You cannot pipe objects to login.ps1.

    .OUTPUTS
    None. login.ps1 does not generate any output.

    .EXAMPLE
    PS> .\login.ps1

  .EXAMPLE
    PS> .\login.ps1 -Profile OtherProfileName

#>


param ($AwsProfile='DeveloperBase-304998364617', $Region='eu-central-1', $Domain = 'kraussmaffei', $DomainOwner = '304998364617', $Repository = 'dss')

$ErrorActionPreference="Stop"
$CodeartifactAuthToken = aws --profile $AwsProfile --region $Region codeartifact get-authorization-token --domain $Domain --domain-owner $DomainOwner --query authorizationToken --output text

if (pip) {
    Write-Output "Configuring pip..."
    pip $verbose config set global.index-url "https://aws:$CodeartifactAuthToken@$Domain-$DomainOwner.d.codeartifact.$Region.amazonaws.com/pypi/$Repository/simple/"
    pip $verbose config set global.extra-index-url "https://aws:$CodeartifactAuthToken@$Domain-$DomainOwner.d.codeartifact.$Region.amazonaws.com/pypi/$Repository-upstream/simple/"
}
else {
    Write-Output "Pip not found and therefore not configured."
}
