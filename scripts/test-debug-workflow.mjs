import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'

const workflow = readFileSync(new URL('../.github/workflows/build-dashboard.yml', import.meta.url), 'utf8')
const validation = workflow.split('        run: |\n')[1].split('\n  resolve:')[0]
  .split('\n').map(line => line.replace(/^          /, '')).join('\n')
const defaults = { SOURCE_REF: 'main', RELEASE_TAG: '', PUBLISH_EXISTING: 'false', BUILD_TARGET: 'all', BUILD_MODE: 'release' }
for (const [overrides, valid] of [
  [{}, true],
  [{ BUILD_TARGET: 'windows' }, true],
  [{ BUILD_TARGET: 'windows', BUILD_MODE: 'debug' }, true],
  [{ BUILD_MODE: 'debug' }, false],
  [{ SOURCE_REF: 'v0.0.38', RELEASE_TAG: 'v0.0.38' }, true],
  [{ SOURCE_REF: 'v0.0.38', RELEASE_TAG: 'v0.0.38', BUILD_TARGET: 'windows', BUILD_MODE: 'debug' }, false],
  [{ BUILD_TARGET: 'windows', BUILD_MODE: 'debug', PUBLISH_EXISTING: 'true' }, false],
  [{ BUILD_MODE: 'invalid' }, false],
]) {
  const result = spawnSync('bash', ['-c', validation], { env: { ...process.env, ...defaults, ...overrides }, encoding: 'utf8' })
  assert.equal(result.status === 0, valid, JSON.stringify(overrides) + result.stderr)
}
assert.ok(workflow.includes("inputs.build_mode == 'debug' && '--debug' || ''"))
assert.ok(workflow.includes('debug/bundle/nsis/*.exe'))
assert.ok(workflow.includes("inputs.build_mode == 'debug' && '-debug' || ''"))
assert.match(workflow, /build_mode:\n[\s\S]*?default: release/)
console.log('Debug/release validation matrix and artifact wiring passed')
