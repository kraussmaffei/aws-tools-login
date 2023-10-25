# aws-tools-login

A shell script and github action to login / logout kraussmaffei aws codeartifact package and ecr docker repository

## Usage

1. Set up Aws Authorization (e.g. with aws sso [Authorization with sso](#authorization-with-sso))
2. Login to aws tools (codeartifact, ecr)
    * With Scripts [Scripts usage](#scripts-usage)
    * With Links [Short links usage](#short-links-usage)
3. Use tools (pip, poetry, docker)

### Scripts usage

#### Python

To perform a login:

```bash
python3 ./aws_tools.py \
    --aws-profile <your-aws-profile> \
    --aws-region <your-region> \
    --domain <domain-of-your-codeartifact> \
    --domain-owner-account <owner-account-of-your-codeartifact> \
    login \
    --ecr \
    --pip \
    --poetry \
    --twine
```

To perform a logout:

```bash
python3 ./aws_tools.py \
    --aws-profile <your-aws-profile> \
    --aws-region <your-region> \
    --domain <domain-of-your-codeartifact> \
    --domain-owner-account <owner-account-of-your-codeartifact> \
    logout \
    --ecr \
    --pip \
    --poetry \
    --twine

```

#### Powershell

In the meanwhile Powershell is available for many OSes. It is even available on Docker!

For Linux, see <https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3>

For MacOS, see <https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.3>

For Docker, see <https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-in-docker?view=powershell-7.3>

For Windows, see <https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3>

> **Note**
> You have to install Powershell version >= 7

To perform a login

```pwsh
./aws-tools-login.ps1 `
    -AwsProfile <your-aws-profile> `
    -AwsRegion <your-region> `
    -SsoStartUrl <the-start-url-of-your-sso> `
    -CodeArtifactDomain <domain-of-your-codeartifact> `
    -CodeArtifactDomainOwner <owner-account-of-your-codeartifact>
```

To perform a login

```pwsh
./aws-tools-logout.ps1
```

#### Bash

 ``` shell
$ ./login.sh --help

   Usage: login.sh [--profile AWS_PROFILE] [--debug] [--dry-run]


   optional arguments:
     -h, --help                   show this help message and exit
     -p, --profile AWS_PROFILE    The aws profile to use for logging in to aws
     -d, --debug                  run in debug mode
     --dry-run                    do a dry run, dont change any files
 ```

 ``` shell
./logout.sh
 ```

## Short links usage

 ``` shell
 curl -L https://git.io/aws-tools-login | bash -s -- --profile "PROFILE"
 curl -L https://git.io/aws-tools-logout | bash
 ```

# Aws Authorization for using login commands

## Authorization with sso

``` shell
$ aws configure sso                                                                                                                                                       
SSO start URL [None]: https://d-9967392836.awsapps.com/start#/                                                                                                                                                                         
SSO Region [None]: eu-central-1                                                                                                                                                                                                        
There are X AWS accounts available to you.
Using the account ID 304998364617
There are X roles available to you.
Using the role name "DeveloperBase"
CLI default client Region [None]: eu-central-1                                                                                                                                                                                         
CLI default output format [None]: json                                                                                                                                                                                                 
CLI profile name [DeveloperBase-304998364617]:                                                                                                                                                                                         

To use this profile, specify the profile name using --profile, as shown:

aws s3 ls --profile DeveloperBase-304998364617
```
