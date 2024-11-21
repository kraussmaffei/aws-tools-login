const core = require("@actions/core");
const exec = require("@actions/exec");
const codeArtifact = require("@aws-sdk/client-codeartifact");

async function run() {
  const account = core.getInput("account", { required: true });
  const region = core.getInput("region", { required: true });
  const awsTool = core.getInput("aws-tool", { required: true });
  const codeartifactRepository = core.getInput("codeartifact-repository", {
    required: false,
  });
  const codeartifactDomain = core.getInput("codeartifact-domain", {
    required: false,
  });

  switch (awsTool) {
    case "codeartifact-pip":
      codeartifact(
        account,
        region,
        codeartifactDomain,
        codeartifactRepository,
        "pip"
      );
      break;
    case "codeartifact-twine":
      codeartifact(
        account,
        region,
        codeartifactDomain,
        codeartifactRepository,
        "twine"
      );
      break;
    case "codeartifact-poetry":
      codeartifact(
        account,
        region,
        codeartifactDomain,
        codeartifactRepository,
        "poetry"
      );
      break;
    case "codeartifact-npm":
      codeartifact(
        account,
        region,
        codeartifactDomain,
        codeartifactRepository,
        "npm"
      );
      break;
  }
}

async function codeartifact(
  account,
  region,
  codeartifactDomain,
  codeartifactRepository,
  type
) {
  const client = new codeArtifact.CodeartifactClient({ region: region });
  const authCommand = new codeArtifact.GetAuthorizationTokenCommand({
    domain: codeartifactDomain,
    domainOwner: account,
    durationSeconds: 0,
  });
  const response = await client.send(authCommand);
  const authToken = response.authorizationToken;
  if (response.authorizationToken === undefined) {
    throw Error(
      `AWS CodeArtifact Authentication Failed: ${response.$metadata.httpStatusCode} (${response.$metadata.requestId})`
    );
  }
  const indexUrl = `${codeartifactDomain}-${account}.d.codeartifact.${region}.amazonaws.com/pypi/${codeartifactRepository}/simple/`;
  const extraIndexUrl = `${codeartifactDomain}-${account}.d.codeartifact.${region}.amazonaws.com/pypi/dss-upstream/simple/`;
  const npmUrl = `${codeartifactDomain}-${account}.d.codeartifact.${region}.on.aws/npm/${codeartifactRepository}/`;

  switch (type) {
    case "pip":
      core.debug(
        `AWS CodeArtifact Login(Auth) ${account}-${region}-${codeartifactDomain}-${codeartifactRepository}`
      );
      await exec.exec(
        "pip",
        [
          "config",
          "set",
          "global.index-url",
          `https://aws:${authToken}@${indexUrl}`,
        ],
        { silent: false }
      );
      await exec.exec(
        "pip",
        [
          "config",
          "set",
          "global.extra-index-url",
          `https://aws:${authToken}@${extraIndexUrl}`,
        ],
        { silent: false }
      );
      break;
    case "twine":
      await exec.exec(
        "aws",
        [
          "--region",
          "eu-central-1",
          "codeartifact",
          "login",
          "--tool",
          "twine",
          "--domain",
          codeartifactDomain,
          "--domain-owner",
          account,
          "--repository",
          codeartifactRepository,
        ],
        { silent: false }
      );
      break;
    case "poetry":
      await exec.exec(
        "poetry",
        [
          "config",
          `repositories.${codeartifactRepository}`,
          `https://${indexUrl}`,
        ],
        { silent: true }
      );
      await exec.exec(
        "poetry",
        [
          "config",
          `http-basic.${codeartifactRepository}`,
          "aws",
          `${authToken}`,
        ],
        { silent: true }
      );

      await exec.exec(
        "poetry",
        [
          "config",
          `repositories.${codeartifactRepository}`,
          `https://${extraIndexUrl}`,
        ],
        { silent: true }
      );
      await exec.exec(
        "poetry",
        ["config", "http-basic.dss-upstream", "aws", `${authToken}`],
        { silent: true }
      );
      break;
    case "npm":
      core.debug(
        `AWS CodeArtifact Login(Auth) ${account}-${region}-${codeartifactDomain}-${codeartifactRepository}`
      );
      await exec.exec(
        "npm",
        [
          "config",
          "set",
          `@${codeartifactDomain}:registry=https://${npmUrl}`,
          "--location",
          "project",
        ],
        { silent: true }
      );
      await exec.exec(
        "npm",
        [
          "config",
          "set",
          `//${npmUrl}:_authToken=${authToken}`,
          "--location",
          "project",
        ],
        { silent: true }
      );
      break;
  }
}

module.exports = run;

/* istanbul ignore next */
if (require.main === module) {
  run();
}
