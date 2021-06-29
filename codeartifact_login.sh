# config
REPOSITORY=dss
DOMAIN=kraussmaffei
DOMAIN_OWNER=304998364617
REGION=eu-central-1

# envs
CODEARTIFACT_REPOSITORY_URL=$(aws --region eu-central-1 codeartifact get-repository-endpoint --domain $DOMAIN --domain-owner $DOMAIN_OWNER --repository $REPOSITORY --format pypi --query repositoryEndpoint --output text)
CODEARTIFACT_AUTH_TOKEN=$(aws --region eu-central-1 codeartifact get-authorization-token --domain $DOMAIN --domain-owner $DOMAIN_OWNER --query authorizationToken --output text)
CODEARTIFACT_USER=aws

# poetry
if command -v poetry &>/dev/null; then
  poetry config http-basic.$REPOSITORY $CODEARTIFACT_USER $CODEARTIFACT_AUTH_TOKEN
  poetry config repositories.$REPOSITORY $CODEARTIFACT_REPOSITORY_URL
  poetry config pypi-token.$REPOSITORY $CODEARTIFACT_AUTH_TOKEN
fi

# pip
if command -v pip &>/dev/null; then
  pip config set global.extra-index-url https://aws:$CODEARTIFACT_AUTH_TOKEN@$DOMAIN-$DOMAIN_OWNER.d.codeartifact.$REGION.amazonaws.com/pypi/$REPOSITORY/simple/
fi

# twine
if command -v twine &>/dev/null; then
  export TWINE_USERNAME=aws
  export TWINE_PASSWORD=$CODEARTIFACT_AUTH_TOKEN
  export TWINE_REPOSITORY=https://$DOMAIN-$DOMAIN_OWNER.d.codeartifact.$REGION.amazonaws.com/pypi/$REPOSITORY/
  export TWINE_REPOSITORY_URL=https://$DOMAIN-$DOMAIN_OWNER.d.codeartifact.$REGION.amazonaws.com/pypi/$REPOSITORY/
  export TWINE_NON_INTERACTIVE=true
fi
