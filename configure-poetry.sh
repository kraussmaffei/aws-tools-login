#!/bin/bash

# this script is used in the Dockerfiles files of all containers to configure poetry
# changing this script will have immediate effect on all containers. use with caution!!!!

set -e

URLS=( $(grep 'index-url =' $HOME/.config/pip/pip.conf | awk '{print $3}') )
REGEX="https://(.+?):(.+?)@(.+?)-(.+?)\.d\.codeartifact\.(.+?)\.amazonaws.com/pypi/(.+?)/simple/"

for item in ${URLS[@]}; do
    if [[ $item =~ $REGEX ]]; then
        USERNAME=${BASH_REMATCH[1]};
        CODEARTIFACT_AUTH_TOKEN=${BASH_REMATCH[2]};
        DOMAIN=${BASH_REMATCH[3]};
        DOMAIN_OWNER=${BASH_REMATCH[4]};
        REGION=${BASH_REMATCH[5]};
        REPOSITORY=${BASH_REMATCH[6]};
    fi
    poetry config repositories.$REPOSITORY "https://$DOMAIN-$DOMAIN_OWNER.d.codeartifact.$REGION.amazonaws.com/pypi/$REPOSITORY/simple/";
    poetry config http-basic.$REPOSITORY ${USERNAME} $CODEARTIFACT_AUTH_TOKEN;
done
poetry config installer.max-workers 10
