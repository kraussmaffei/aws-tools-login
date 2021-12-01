#!/bin/bash
set -e

# config
REPOSITORY=dss
DOMAIN=kraussmaffei
DOMAIN_OWNER=304998364617
REGION=eu-central-1
bold=$(tput bold)
normal=$(tput sgr0)

# pip
if command -v pip &>/dev/null; then
  echo "${bold}Resetting pip...${normal}"
  pip config unset global.index-url
  pip config unset global.extra-index-url
fi

# twine
if command -v twine &>/dev/null; then
  echo "${bold}Resetting twine...${normal}"
  sed -i '/\[codeartifact\]/,/\[/ { /\[codeartifact\]/d; /\[/b; d }' ~/.pypirc
fi

# docker
if command -v docker &>/dev/null; then
  echo "${bold}Resetting docker...${normal}"
  docker logout "$DOMAIN_OWNER.dkr.ecr.$REGION.amazonaws.com"
fi

# poetry
if command -v poetry &>/dev/null; then
  echo "${bold}Resetting poetry...${normal}"
  poetry config repositories.dss --unset
  poetry config repositories.dss-upstream --unset
fi