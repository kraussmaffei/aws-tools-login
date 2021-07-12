const exec = require('@actions/exec');

async function cleanup() {
  await exec.exec('pip', ['config', 'unset', 'global.index-url'], {silent: true});
  await exec.exec('pip', ['config', 'unset', 'global.extra-index-url'], {silent: true});
  //eslint-disable-next-line
  await exec.exec('sed', ['-i', '/\[codeartifact\]/,/\[/ { /\[codeartifact\]/d; /\[/b; d }', '~/.pypirc'], {silent: true});
}

module.exports = cleanup;

/* istanbul ignore next */
if (require.main === module) {
  cleanup();
}