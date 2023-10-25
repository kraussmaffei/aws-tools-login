param (
  [Parameter(Mandatory = $true)]
  [string]$AwsProfile,

  [Parameter(Mandatory = $true)]
  $AwsRegion,

  [Parameter(Mandatory = $true)]
  $SsoStartUrl,

  [Parameter(Mandatory = $true)]
  [string]$CodeArtifactDomain,

  [Parameter(Mandatory = $true)]
  [string]$CodeArtifactDomainOwner
)

class AWSEnvironment {
  [string]$AwsProfile
  [string]$AwsRegion
  [string]$SsoStartUrl
  [string]$SsoSessionName

  AWSEnvironment([string]$AwsProfile, [string]$AwsRegion, [string]$SsoStartUrl) {
    # $this.AwsProfile = "KMDeveloperBasePermSet-304998364617"
    $this.AwsProfile = $AwsProfile
    $this.AwsRegion = $AwsRegion
    # $this.SsoStartUrl = "https://d-9967392836.awsapps.com/start#/"
    $this.SsoStartUrl = $SsoStartUrl
    $this.SsoSessionName = "aws-tools-login"
  }
}

class CodeArtifact {
  [string]$Domain
  [string]$DomainOwner
  [string]$DurationSecond

  CodeArtifact([string]$Domain, [string]$DomainOwner) {
    $this.Domain = $Domain
    # $this.Domain = "kraussmaffei"
    $this.DomainOwner = $DomainOwner
    # $this.DomainOwner = "304998364617"
    $this.DurationSecond = "43200"
  }
}


function Confirm-ModuleImported ($name) {
  if (Get-Module | Where-Object { $_.Name -eq $name }) {
    return $true
  }
  else {
    return $false
  }
}

function Confirm-ModuleAvailableOnDisk ($name) {
  if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $name }) {
    return $true
  }
  else {
    return $false
  }
}

function Confirm-ModuleAvailableOnline ($name) {
  if (Find-Module -Name $name | Where-Object { $_.Name -eq $name }) {
    return $true
  }
  else {
    return $false
  }
}

function Install-AwsToolsInstaller () {
  $psModule = "AWS.Tools.Installer"
  if (!(Confirm-ModuleImported $psModule)) {
    if (!(Confirm-ModuleAvailableOnDisk $psModule)  ) {
      if (Confirm-ModuleAvailableOnline $psModule) {
        Install-Module -Name $psModule -Force -Verbose -Scope CurrentUser
      }
      else {
        Write-Output "The module $psName is neither imported nor available on hard disk or online. Exiting!"
        EXIT 1
      }
    }
    Import-Module -Name $psModule -Verbose
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

function Confirm-AwsProfileExist ($profileName) {
  $profiles = Invoke-Expression -Command "aws configure list-profiles"
  return $profiles -contains $profileName
}

function Set-AwsProfile ([AWSEnvironment]$awsEnvironment) {
  $awsConfig = Get-Content -Path "$HOME/.aws/config"
  if (!(Test-Path -Path $awsConfig)) {
    New-Item -ItemType Directory -Force -Path
  }
  $awsToolsLoginSessionHeader = "[sso-session $($awsEnvironment.SsoSessionName)]"
  if (!($awsConfig -contains $awsToolsLoginSessionHeader)) {
    Add-Content -Path "$HOME/.aws/config" -Value "$awsToolsLoginSessionHeader"
    Add-Content -Path "$HOME/.aws/config" -Value "sso_start_url = $($awsEnvironment.SsoStartUrl)"
    Add-Content -Path "$HOME/.aws/config" -Value "sso_region = $($awsEnvironment.AwsRegion)"
    Add-Content -Path "$HOME/.aws/config" -Value "sso_registration_scopes = sso:account:access"
  }

  $awsProfileHeader = "[profile $($awsEnvironment.AwsProfile)]"
  if (!($awsConfig -contains $awsProfileHeader)) {
    $ssoSession = Invoke-Expression -Command "aws configure get profile.$($awsEnvironment.AwsProfile).sso_session"
    if (!($ssoSession)) { 
      Invoke-Expression -Command "aws configure set profile.$($awsEnvironment.AwsProfile).sso_session $($awsEnvironment.SsoSessionName)"
    }
    
    $ssoRoleName = Invoke-Expression -Command "aws configure get profile.$($awsEnvironment.AwsProfile).sso_role_name"
    if (!($ssoRoleName)) { 
      Invoke-Expression -Command "aws configure set profile.$($awsEnvironment.AwsProfile).sso_role_name $($awsEnvironment.AwsProfile.Split("-")[0,2])"
    }

    $ssoAccountId = Invoke-Expression -Command "aws configure get profile.$($awsEnvironment.AwsProfile).sso_account_id"
    if (!($ssoAccountId)) { 
      Invoke-Expression -Command "aws configure set profile.$($awsEnvironment.AwsProfile).sso_account_id $($awsEnvironment.AwsProfile.Split("-")[1,2])" 
    }

    $region = Invoke-Expression -Command "aws configure get profile.$($awsEnvironment.AwsProfile).region"
    if (!($region)) {
      Invoke-Expression -Command "aws configure set profile.$($awsEnvironment.AwsProfile).region $($awsEnvironment.AwsRegion)"
    }

    $output = Invoke-Expression -Command "aws configure get profile.$($awsEnvironment.AwsProfile).output"
    if (!($output)) {
      Invoke-Expression -Command "aws configure set profile.$($awsEnvironment.AwsProfile).output json"
    }
  }
}

function Request-AwsSSOLogin([AWSEnvironment]$awsEnvironment) {
  $account = Invoke-Expression -Command "aws sts get-caller-identity --query Account --profile $($awsEnvironment.AwsProfile) --region $($awsEnvironment.AwsRegion)" -ErrorAction SilentlyContinue
  if (!($account)) {
    Invoke-Expression -Command "aws sso login --profile $($awsEnvironment.AwsProfile) --sso-session $($awsEnvironment.SsoSessionName)"
  }
}

function Get-CodeartifactAuthToken([AWSEnvironment]$awsEnvironment, [CodeArtifact]$codeartifact) {
  $token = (Get-CAAuthorizationToken -ProfileName $awsEnvironment.AwsProfile -Region $awsEnvironment.AwsRegion -Domain $codeartifact.Domain -DomainOwner $codeartifact.DomainOwner -DurationSecond $codeartifact.DurationSecond).AuthorizationToken
  return $token
}

function Install-AwsCli ([string]$destination) {
  if (!(Confirm-ToolExists "aws")) {
    If (!(test-path -PathType container $destination)) {
      New-Item -ItemType Directory -Path $destination
    }

    if ($IsLinux) {
      $file = "awscliv2.zip"
      Invoke-WebRequest -Uri "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -OutFile $destination/$file
      Expand-Archive -Path $destination/$file -DestinationPath $destination
      Invoke-Expression -Command "sudo $destination/aws/install"
  
    }
    elseif ($IsMacOS) {
      $file = "AWSCLIV2.pkg"
      Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.pkg" -OutFile $destination/$file
      Expand-Archive -Path $destination/$file -DestinationPath $destination

      $choiceChangesXMLPath = "./$destination/choices.xml"
      Build-XML -path $choiceChangesXMLPath

      Invoke-Expression -Command "installer -pkg AWSCLIV2.pkg -target CurrentUserHomeDirectory -applyChoiceChangesXML $choiceChangesXMLPath"
      Invoke-Expression -Command "sudo ln -s $destination/aws-cli/aws /usr/local/bin/aws"
      Invoke-Expression -Command "sudo ln -s $destination/aws-cli/aws_completer /usr/local/bin/aws_completer"
    }
    elseif ($IsWindows) {
      Invoke-Expression -Command "msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi"
    }
    else {
      Write-Output "Your OS is not supported!"
      EXIT 1
    }
  }
}

function Build-XML ($path) {
  $doc = New-Object System.Xml.XmlDocument
  $docType = New-Object System.Xml.XmlDocumentType
  $xmlDecl = $doc.CreateXmlDeclaration("1.0", "UTF-8", $null)

  $root = $doc.DocumentElement
  $doc.InsertBefore($xmlDecl, $root)

  $docType = $doc.CreateDocumentType("plist", "-//Apple//DTD PLIST 1.0//EN", "http://www.apple.com/DTDs/PropertyList-1.0.dtd", $null)
  $doc.AppendChild($docType)
  $plist = $doc.AppendChild($doc.CreateElement("plist"))
  $array = $plist.AppendChild($doc.CreateElement("array"))
  $dict = $array.AppendChild($doc.CreateElement("dict"))
  
  $choiceAttribute = $doc.CreateTextNode("choiceAttribute")
  $dict.AppendChild($doc.CreateElement("key"))
  $dict.LastChild.AppendChild($choiceAttribute)
  
  $customLocation = $doc.CreateTextNode("customLocation")
  $dict.AppendChild($doc.CreateElement("string"))
  $dict.LastChild.AppendChild($customLocation)

  $attributeSetting = $doc.CreateTextNode("attributeSetting")
  $dict.AppendChild($doc.CreateElement("key"))
  $dict.LastChild.AppendChild($attributeSetting)
  
  $username = $doc.CreateTextNode($HOME)
  $dict.AppendChild($doc.CreateElement("string"))
  $dict.LastChild.AppendChild($username)

  $choiceIdentifier = $doc.CreateTextNode("choiceIdentifier")
  $dict.AppendChild($doc.CreateElement("key"))
  $dict.LastChild.AppendChild($choiceIdentifier)
  
  $default = $doc.CreateTextNode("default")
  $dict.AppendChild($doc.CreateElement("string"))
  $dict.LastChild.AppendChild($default)


  # Save the XML document
  $doc.OuterXml | Set-Content $path
}

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  $name = [System.IO.Path]::GetRandomFileName()
  $item = New-Item -Path $parent -Name $name -ItemType "directory" -ErrorAction SilentlyContinue
  return $item.FullName
}

if (($PSVersionTable).PSVersion.Major -lt 7) {
  Write-Output "Update powershell to version 7! Your version is incompatible."
  EXIT 1
}

$tempDir = New-TemporaryDirectory
Install-AwsCli $tempDir
Remove-Item $tempDir -Recurse -Force

Install-AwsToolsInstaller
Install-AWSToolsModule AWS.Tools.ECR, AWS.Tools.CodeArtifact, AWS.Tools.SSO, AWS.Tools.SSOOIDC  -CleanUp -Force
if (!(Confirm-ModuleImported AWS.Tools.SSO)) {
  Import-Module AWS.Tools.SSO
}
if (!(Confirm-ModuleImported AWS.Tools.SSOOIDC)) {
  Import-Module AWS.Tools.SSOOIDC
}

$awsEnvironment = [AWSEnvironment]::new($AwsProfile, $AwsRegion, $SsoStartUrl)
$codeartifact = [CodeArtifact]::new($CodeArtifactDomain, $CodeArtifactDomainOwner)

if (!(Confirm-AwsProfileExist -profileName $awsEnvironment.AwsProfile)) {
  Set-AwsProfile -awsEnvironment $awsEnvironment
}
Request-AwsSSOLogin $awsEnvironment

if (Confirm-ToolExists "docker") {
  Write-Output "Logging in to ecr..."
  Invoke-Expression -Command (Get-ECRLoginCommand -ProfileName $awsEnvironment.AwsProfile -Region $awsEnvironment.AwsRegion).Command
}

$codeartifactAuthToken = Get-CodeartifactAuthToken $awsEnvironment $codeartifact
if (Confirm-ToolExists "pip") {
  Write-Output "Configuring pip..."
  Invoke-Expression -Command "pip config set global.index-url https://aws:$codeartifactAuthToken@$($codeartifact.Domain)-$($codeartifact.DomainOwner).d.codeartifact.$($awsEnvironment.AwsRegion).amazonaws.com/pypi/dss/simple/"
  Invoke-Expression -Command "pip config set global.extra-index-url https://aws:$codeartifactAuthToken@$($codeartifact.Domain)-$($codeartifact.DomainOwner).d.codeartifact.$($awsEnvironment.AwsRegion).amazonaws.com/pypi/dss-upstream/simple/"
}

if (Confirm-ToolExists "poetry") {
  Write-Output "Configuring poetry..."
  Invoke-Expression -Command "poetry -vvv config repositories.dss https://$($codeartifact.DomainOwner).d.codeartifact.$($awsEnvironment.AwsRegion).amazonaws.com/pypi/dss/simple/"
  Invoke-Expression -Command "poetry config http-basic.dss aws $codeartifactAuthToken"

  Invoke-Expression -Command "poetry -vvv config repositories.dss-upstream https://$($codeartifact.DomainOwner).d.codeartifact.$($awsEnvironment.AwsRegion).amazonaws.com/pypi/dss-upstream/simple/"
  Invoke-Expression -Command "poetry config http-basic.dss-upstream aws $codeartifactAuthToken"
}

if (Confirm-ToolExists "twine") {
  Write-Output "Configuring twine..."
  Invoke-Expression -Command "aws --profile $($awsEnvironment.AwsProfile) --region $($awsEnvironment.AwsRegion) codeartifact login --tool twine --domain $($codeartifact.Domain) --domain-owner $($codeartifact.DomainOwner) --repository dss"
}
