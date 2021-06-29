#!/bin/bash
set -e

# usage function
function usage()
{
   cat << HEREDOC

   Usage: $progname [--profile AWS_PROFILE] [--debug] [--dry-run]


   optional arguments:
     -h, --help                   show this help message and exit
     -p, --profile AWS_PROFILE    The aws profile to use for logging in to aws
     -d, --debug                  run in debug mode
     --dry-run                    do a dry run, dont change any files

HEREDOC
}

# initialize variables
progname=$(basename $0)
REPOSITORY=dss
DOMAIN=kraussmaffei
DOMAIN_OWNER=304998364617
REGION=eu-central-1
debug=""
verbose=""
dryrun=false
profile=""

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h | --help ) usage; exit; ;;
    -p | --profile )
      profile="$2"
      shift # past argument
      shift # past value
      ;;
    -d | --debug )
      debug="--debug"
      verbose="-vvv"
      shift # past argument
      ;;
    --dry-run )
      dryrun=true
      shift # past argument
      ;;
    * ) usage; exit; ;;  # unknown option
  esac
done

# Print usage in case parameters are empty
if [ -z "$profile" ]
then
   echo "Some or all of the parameters are empty";
   usage
   exit
fi

# login
CODEARTIFACT_REPOSITORY_URL=$(aws $debug --profile $profile --region eu-central-1 codeartifact get-repository-endpoint --domain $DOMAIN --domain-owner $DOMAIN_OWNER --repository $REPOSITORY --format pypi --query repositoryEndpoint --output text)
CODEARTIFACT_AUTH_TOKEN=$(aws $debug --profile $profile --region eu-central-1 codeartifact get-authorization-token --domain $DOMAIN --domain-owner $DOMAIN_OWNER --query authorizationToken --output text)
CODEARTIFACT_USER=aws

# configure
if [ "$dryrun" = true ] ; then
  aws $debug --profile $profile --region $REGION ecr get-login-password
  echo "Login successful but no files configured. Run without dry-run to configure your tools.";
else
  # poetry
  if command -v poetry &>/dev/null; then
    poetry $verbose config http-basic.$REPOSITORY $CODEARTIFACT_USER $CODEARTIFACT_AUTH_TOKEN
    poetry $verbose config repositories.$REPOSITORY $CODEARTIFACT_REPOSITORY_URL
    poetry $verbose config pypi-token.$REPOSITORY $CODEARTIFACT_AUTH_TOKEN
  fi

  # pip
  if command -v pip &>/dev/null; then
    pip $verbose config set global.extra-index-url https://aws:$CODEARTIFACT_AUTH_TOKEN@$DOMAIN-$DOMAIN_OWNER.d.codeartifact.$REGION.amazonaws.com/pypi/$REPOSITORY/simple/
  fi

  # twine
  if command -v twine &>/dev/null; then
      aws $debug --profile $profile --region eu-central-1 codeartifact login --tool twine --domain $DOMAIN --domain-owner $DOMAIN_OWNER --repository $REPOSITORY
  fi

  # docker
  if command -v docker &>/dev/null; then
        aws $debug --profile $profile --region $REGION ecr get-login-password | docker $debug login --username AWS --password-stdin $DOMAIN_OWNER.dkr.ecr.$REGION.amazonaws.com
  fi
fi
