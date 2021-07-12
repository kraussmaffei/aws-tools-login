const exec = require('@actions/exec');

async function cleanup() {
  await exec.exec('pip', ['config', 'unset', 'global.index-url'], {silent: true});
}

module.exports = cleanup;

/* istanbul ignore next */
if (require.main === module) {
  cleanup();
}