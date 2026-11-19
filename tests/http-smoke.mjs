import assert from 'node:assert/strict';
import { setTimeout } from 'node:timers/promises';

const origin = 'http://127.0.0.1:3000';
const request = path => fetch(new URL(path, origin), {
  redirect: 'manual', signal: AbortSignal.timeout(5000),
});
let ready = false;
for (let i = 0; i < 60; i++) {
  try {
    const response = await request('/');
    await response.arrayBuffer();
    if (response.status === 200) { ready = true; break; }
  } catch {}
  await setTimeout(500);
}
assert(ready, 'SSR server must start and serve HTTP 200');
const assets = new Set();
for (const path of (process.env.SMOKE_ROUTES || '/').split(/\s+/).filter(Boolean)) {
  const response = await request(path);
  assert.equal(response.status, 200, path);
  assert.match(response.headers.get('content-type') || '', /text\/html/);
  const html = await response.text();
  assert.match(html, /__NUXT/, `${path}: Nuxt SSR payload`);
  assert.match(html, /<main[\s>]/, `${path}: rendered application content`);
  if (process.env.SMOKE_TEXT) assert(html.includes(process.env.SMOKE_TEXT), `${path}: application marker`);
  for (const match of html.matchAll(/(?:src|href)="(\/_nuxt\/[^"?#]+(?:\.js|\.css))(?:[?#][^"]*)?"/g)) assets.add(match[1]);
  console.log(`PASS HTTP 200 + SSR: ${path}`);
}
assert([...assets].some(path => path.endsWith('.js')), 'JavaScript assets must be present');
assert([...assets].some(path => path.endsWith('.css')), 'CSS assets must be present');
if (process.env.SMOKE_STATIC) assets.add(process.env.SMOKE_STATIC);
for (const path of assets) {
  const response = await request(path);
  assert.equal(response.status, 200, path);
  assert((await response.arrayBuffer()).byteLength > 0, `${path}: empty asset`);
}
assert.equal((await request('/__node_lts_missing_route__')).status, 404, 'unknown route');
console.log(`PASS ${assets.size} assets and expected HTTP 404`);
