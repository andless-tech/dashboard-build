import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { spawnSync } from 'node:child_process'

const dir = mkdtempSync(join(tmpdir(), 'dashboard-release-notes-'))
try {
  for (const [target, filenames] of Object.entries({
    'dashboard-windows-x64': ['app.exe'], 'dashboard-macos-intel': ['app.dmg'],
    'dashboard-macos-apple-silicon': ['app.dmg'], 'dashboard-linux-x64': ['app.deb', 'app.AppImage'],
  })) {
    mkdirSync(join(dir, 'artifacts', target), { recursive: true })
    for (const name of filenames) writeFileSync(join(dir, 'artifacts', target, name), 'test fixture')
  }
  const notes = { force: true, app: 'dashboard', channel: 'release', version: '0.0.42', changelog: '改善操控\n连接排查更清楚', release_notes_url: 'https://www.andless.tech/changelog/desktop/0.0.42/' }
  const env = { ...process.env, APP_VERSION: '0.0.42', SOURCE_SHA: 'a'.repeat(40), FORCE_UPDATE: 'true', CHANNEL: 'release', ARTIFACTS_DIR: join(dir, 'artifacts'), RELEASE_FILES_DIR: join(dir, 'release-files'), MANIFEST_PATH: join(dir, 'manifest.json'), RELEASE_NOTES_METADATA: join(dir, 'notes.json') }
  delete env.GITHUB_OUTPUT
  const run = () => spawnSync('bash', [new URL('./prepare-dashboard-release.sh', import.meta.url).pathname], { env, encoding: 'utf8' })
  writeFileSync(env.RELEASE_NOTES_METADATA, JSON.stringify(notes))
  const result = run()
  assert.equal(result.status, 0, result.stderr)
  const manifest = JSON.parse(readFileSync(env.MANIFEST_PATH, 'utf8'))
  assert.equal(manifest.changelog, notes.changelog)
  assert.equal(manifest.release_notes_url, notes.release_notes_url)
  assert.equal(manifest.force, true)
  assert.equal(manifest.device_requirements.minimum_firmware, '1.0.13')
  assert.equal(Object.keys(manifest.artifacts).length, 5)
  for (const change of [{ force: false }, { app: 'firmware' }, { version: '0.0.41' }, { channel: 'debug' }, { changelog: '' }, { changelog: '中'.repeat(6000) }, { release_notes_url: 'https://other.example/' }]) {
    writeFileSync(env.RELEASE_NOTES_METADATA, JSON.stringify({ ...notes, ...change }))
    assert.notEqual(run().status, 0, JSON.stringify(change))
  }
  writeFileSync(env.RELEASE_NOTES_METADATA, JSON.stringify({ ...notes, version: 'wrong' }) + '\n' + JSON.stringify(notes))
  assert.notEqual(run().status, 0, 'multiple JSON objects must fail')
  console.log('Canonical desktop notes: success, wrong metadata rejection and existing policy/artifacts preserved')
} finally { rmSync(dir, { recursive: true, force: true }) }
