#!/bin/bash
set -e

# config
REPOSITORY=dss
DOMAIN=kraussmaffei
DOMAIN_OWNER=304998364617
REGION=eu-central-1

# pip
if command -v pip &>/dev/null; then
  pip config unset global.index-url
  pip config unset global.extra-index-url
fi

# twine
if command -v twine &>/dev/null; then
  sed -i '/\[codeartifact\]/,/\[/ { /\[codeartifact\]/d; /\[/b; d }' ~/.pypirc
fi

# docker
if command -v docker &>/dev/null; then
  docker logout "$DOMAIN_OWNER.dkr.ecr.$REGION.amazonaws.com"
fi
