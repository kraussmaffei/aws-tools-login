const core = require('@actions/core');
const exec = require('@actions/exec');
const codeArtifact = require('@aws-sdk/client-codeartifact');

async function run() {
  const account = core.getInput('account', { required: true });
  const region = core.getInput('region', { required: true });
  const awsTool = core.getInput('aws-tool', { required: true });
  const codeartifactRepository = core.getInput('codeartifact-repository', { required: false });
  const codeartifactDomain = core.getInput('codeartifact-domain', { required: false });

  switch(awsTool) {
    case 'codeartifact-pypi':
      codeartifact(account, region, codeartifactDomain, codeartifactRepository, 'pypi');
      break;
  }

}

async function codeartifact(account, region, codeartifactDomain, codeartifactRepository, type) {
    const client = new codeArtifact.CodeartifactClient({ region: region });
    const authCommand = new codeArtifact.GetAuthorizationTokenCommand({
        domain: codeartifactDomain,
        domainOwner: account,
        durationSeconds: 0
    });

    core.debug(`AWS CodeArtifact Login(Auth) ${account}-${region}-${codeartifactDomain}-${codeartifactRepository}`);

    const response = await client.send(authCommand);
    const authToken = response.authorizationToken;
    if (response.authorizationToken === undefined) {
        throw Error(`AWS CodeArtifact Authentication Failed: ${response.$metadata.httpStatusCode} (${response.$metadata.requestId})`);
    }

    switch(type) {
        case 'pypi':
            var indexUrl = `https://aws:${authToken}@${codeartifactDomain}-${account}.d.codeartifact.${region}.amazonaws.com/pypi/${codeartifactRepository}/simple/`
            var extraIndexUrl = `https://aws:${authToken}@${codeartifactDomain}-${account}.d.codeartifact.${region}.amazonaws.com/pypi/dss-upstream/simple/`
            await exec.exec('pip', ['config', 'set', 'global.index-url', indexUrl], {silent: true});
            await exec.exec('pip', ['config', 'set', 'global.extra-index-url', extraIndexUrl], {silent: true});
            break;
    }
}

module.exports = run;

/* istanbul ignore next */
if (require.main === module) {
    run();
}