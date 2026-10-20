// Снимок страницы в настоящем Chrome, чётко (x2): весь экран или один блок.
//   node scripts/shots/shot.mjs <url> <out.png> <width> <height> [selector|-] [js-before] [pad]
// js-before выполняется на странице перед снимком: заполнить поле, нажать кнопку. Ширина < 600 — как телефон.
import { spawn } from 'node:child_process';
import { writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
const [,, url, out, width, height, sel = '-', js = '', pad = '0'] = process.argv;
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9300 + Math.floor(Math.random() * 500);
const dir = `${tmpdir()}/vibewiki-chrome-${port}`;
const p = spawn(chrome, ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', `--window-size=${width},${height}`, 'about:blank'], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws;
for (let i = 0; i < 60; i++) { try { const t = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); ws = new WebSocket(t.find(x => x.type === 'page').webSocketDebuggerUrl); break; } catch { await sleep(200); } }
await new Promise(r => ws.onopen = r);
let id = 0; const wait = {};
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && wait[m.id]) wait[m.id](m.result); };
const send = (method, params = {}) => new Promise(r => { wait[++id] = r; ws.send(JSON.stringify({ id, method, params })); });
const mobile = +width < 600;
await send('Emulation.setDeviceMetricsOverride', { width: +width, height: +height, deviceScaleFactor: 2, mobile });
await send('Page.navigate', { url }); await sleep(1500);
if (js) { await send('Runtime.evaluate', { expression: js }); await sleep(600); }
let clip = { x: 0, y: 0, width: +width, height: +height, scale: 1 };
if (sel !== '-') {
  const r = await send('Runtime.evaluate', { returnByValue: true, expression: `(()=>{const b=document.querySelector(${JSON.stringify(sel)}).getBoundingClientRect();return {x:b.x+scrollX,y:b.y+scrollY,w:b.width,h:b.height}})()` });
  const b = r.result.value, P = +pad;
  clip = { x: Math.max(0, b.x - P), y: Math.max(0, b.y - P), width: b.w + 2 * P, height: b.h + 2 * P, scale: 1 };
}
const s = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true, clip });
writeFileSync(out, Buffer.from(s.data, 'base64'));
console.log(out, JSON.stringify(clip));
ws.close(); p.kill();
setTimeout(() => rmSync(dir, { recursive: true, force: true }), 500);
