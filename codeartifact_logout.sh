#!/bin/bash
set -e

# config
REPOSITORY=dss
DOMAIN=kraussmaffei
DOMAIN_OWNER=304998364617
REGION=eu-central-1

# poetry
if command -v poetry &>/dev/null; then
  poetry config --unset http-basic.$REPOSITORY
  poetry config --unset repositories.$REPOSITORY
  poetry config --unset pypi-token.$REPOSITORY
fi

# pip
if command -v pip &>/dev/null; then
  pip config unset global.extra-index-url
fi

# twine
if command -v twine &>/dev/null; then
  sed -i '/\[codeartifact\]/,/\[/ { /\[codeartifact\]/d; /\[/b; d }' ~/.pypirc
fi
