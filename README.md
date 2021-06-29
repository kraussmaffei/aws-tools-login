# codeartifact_login

A shell script and github action to login / logout kraussmaffei aws codeartifact package and ecr docker repository

# Usage

## Scripts Usage

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
$ ./logout.sh
 ```

## Short Links Usage

 ``` shell
 curl -L https://git.io/aws-tools-login | bash -s -- --profile "PROFILE"
 curl -L https://git.io/aws-tools-logout | bash
 ```

