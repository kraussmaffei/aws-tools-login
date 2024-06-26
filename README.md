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
SSO start URL [None]: https://kraussmaffei-imm.awsapps.com/start/                                                                                                                                                                         
SSO Region [None]: eu-central-1                                                                                                                                                                                                        
There are X AWS accounts available to you.
Using the account ID 304998364617
There are X roles available to you.
Using the role name "KMDeveloperBasePermSet"
CLI default client Region [None]: eu-central-1                                                                                                                                                                                         
CLI default output format [None]: json                                                                                                                                                                                                 
CLI profile name [KMDeveloperBasePermSet-304998364617]:                                                                                                                                                                                         

To use this profile, specify the profile name using --profile, as shown:

aws s3 ls --profile KMDeveloperBasePermSet-304998364617
```
