const exec = require('@actions/exec');
const core = require('@actions/core');

async function cleanup() {
  core.info("Listing pip config:")
  await exec.exec('pip', ['config', 'list']).catch((reason) => {
    core.warning("Wasn't able to list pip config")
    core.warning(reason)
  });
  await exec.exec('pip', ['config', 'unset', 'global.index-url'], { silent: true }).catch((reason) => {
    core.warning("Wasn't able to unset global.index-url")
    core.warning(reason)
  });
  await exec.exec('pip', ['config', 'unset', 'global.extra-index-url'], { silent: true }).catch((reason) => {
    core.warning("Wasn't able to unset global.extra-index-url")
    core.warning(reason)
  });
  //eslint-disable-next-line
  await exec.exec('sed', ['-i', '/\[codeartifact\]/,/\[/ { /\[codeartifact\]/d; /\[/b; d }', '~/.pypirc'], { silent: true }).catch((reason) => {
    core.warning("Wasn't able to remove codeartifact section from ~/.pypirc")
    core.warning(reason)
  });
}

module.exports = cleanup;

/* istanbul ignore next */
if (require.main === module) {
  cleanup();
}
