class CodeArtifact {
  [string]$Domain
  [string]$DomainOwner
  [string]$Region

  CodeArtifact() {
    $this.Domain = "kraussmaffei"
    $this.DomainOwner = "304998364617"
    $this.Region = "eu-central-1"
  }
}

function Confirm-ToolExists($name) {
  if (Get-Command $name -ErrorAction Continue) {
    return $true
  }
  else {
    return $false
  }
}

$codeArtfact = [CodeArtifact]::new()
if (Confirm-ToolExists "docker") {
  Write-Output "Resetting docker..."
  Invoke-Expression -Command "docker logout $($codeArtfact.DomainOwner).dkr.ecr.$($codeArtfact.Region).amazonaws.com"
}

if (Confirm-ToolExists "pip") {
  Write-Output "Resetting pip..."
  Invoke-Expression -Command "pip config unset global.index-url"
  Invoke-Expression -Command "pip config unset global.extra-index-url"
}

if (Confirm-ToolExists "poetry") {
  Write-Output "Resetting poetry..."
  Invoke-Expression -Command "poetry -vvv config repositories.dss --unset"
  Invoke-Expression -Command "poetry -vvv config repositories.dss-upstream --unset"
}

if (Confirm-ToolExists "twine") {
  Write-Output "Resetting twine..."
  Remove-Item "$HOME/.pypirc" -Force
}
