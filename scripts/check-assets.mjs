import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
const root = new URL('../', import.meta.url);
const assets = JSON.parse(await readFile(new URL('data/assets.json', root)));
const items = JSON.parse(await readFile(new URL('data/items.json', root)));
for (const [id, asset] of Object.entries(assets)) {
  const data = await readFile(new URL(asset.path, root));
  assert.equal(createHash('sha256').update(data).digest('hex'), asset.sha256, id);
  assert.ok(asset.source && asset.license && asset.author, id);
  if (asset.type === 'model') {
    assert.equal(data.toString('utf8', 0, 4), 'glTF', id);
    const gltf = JSON.parse(data.toString('utf8', 20, 20 + data.readUInt32LE(12)));
    for (const dependency of [...(gltf.images || []), ...(gltf.buffers || [])]) {
      if (dependency.uri && !dependency.uri.startsWith('data:')) await readFile(new URL(dependency.uri, new URL(asset.path, root)));
    }
  }
}
for (const item of items) { assert.ok(assets[item.icon], item.id); if (item.model) assert.ok(assets[item.model], item.id); }
assert.equal(new Set(items.map(i => i.id)).size, items.length);
console.log(`Verified ${Object.keys(assets).length} licensed assets and ${items.length} item definitions`);
