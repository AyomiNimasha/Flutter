// Node 20: node --experimental-websocket tool/check_browser.mjs <browser path>
// Launches an isolated headless browser; never uses an existing user profile.
import {spawn} from 'node:child_process';
import {mkdir, mkdtemp, readFile, writeFile} from 'node:fs/promises';
import {resolve, join} from 'node:path';

const browserPath = process.argv[2];
if (!browserPath) throw new Error('Supply a Chromium browser executable path');
const output = resolve('build/browser-runtime');
await mkdir(output, {recursive: true});
const profile = await mkdtemp(join(output, 'profile-'));
const child = spawn(browserPath, [
  '--headless', '--no-first-run', '--no-default-browser-check',
  '--disable-dev-shm-usage', '--enable-unsafe-swiftshader',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
], {stdio: ['ignore', 'ignore', 'pipe'], windowsHide: true});
let log = '';
child.stderr.on('data', data => { log += data; });
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
let socket;
try {
  let port;
  for (let attempt = 0; attempt < 100; attempt++) {
    try { port = (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; break; }
    catch { await sleep(100); }
  }
  if (!port) throw new Error('Browser did not start: ' + log);
  const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
  socket = new WebSocket(targets.find(target => target.type === 'page').webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
  let nextId = 0;
  const pending = new Map();
  const exceptions = [];
  let photoRequest;
  let photoLoaded = false;
  socket.onmessage = event => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const waiter = pending.get(message.id);
      if (waiter) { pending.delete(message.id); message.error ? waiter.reject(message.error) : waiter.resolve(message.result); }
    } else if (message.method === 'Runtime.exceptionThrown') {
      exceptions.push(message.params.exceptionDetails);
    } else if (message.method === 'Network.responseReceived' &&
        message.params.response.url.endsWith('/welcome_pets.png') &&
        message.params.response.status === 200) {
      photoRequest = message.params.requestId;
    } else if (message.method === 'Network.loadingFinished' && message.params.requestId === photoRequest) {
      photoLoaded = true;
    } else if (message.method === 'Network.loadingFailed') {
      log += '\nNETWORK: ' + JSON.stringify(message.params);
    }
  };
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, {resolve, reject});
    socket.send(JSON.stringify({id, method, params}));
  });
  const evaluate = async expression => (await send('Runtime.evaluate', {expression, returnByValue: true})).result.value;
  await send('Runtime.enable');
  await send('Page.enable');
  await send('Network.enable');
  await send('Emulation.setDeviceMetricsOverride', {width: 1100, height: 950, deviceScaleFactor: 1, mobile: false});
  await send('Page.navigate', {url: 'http://localhost:8080/'});
  let ready = false;
  for (let attempt = 0; attempt < 120; attempt++) {
    // With a new empty profile, only the welcome screen requests this photo.
    // It is built after SQLite and repository initialization have completed.
    ready = photoLoaded && await evaluate(`document.body.dataset.pawshotsReady === 'true'`);
    if (ready || exceptions.length) break;
    await sleep(500);
  }
  if (ready) await sleep(1000); // Allow image decoding and paint to complete.
  const screenshot = await send('Page.captureScreenshot', {format: 'png'});
  await writeFile(join(output, 'welcome.png'), Buffer.from(screenshot.data, 'base64'));
  await writeFile(join(output, 'page.html'), await evaluate('document.documentElement.outerHTML'));
  await writeFile(join(output, 'browser.log'), log + '\nEXCEPTIONS: ' + JSON.stringify(exceptions));
  if (exceptions.length) throw new Error('Browser runtime exception: ' + JSON.stringify(exceptions));
  if (!ready) throw new Error('Welcome screen did not become ready within 60 seconds; inspect ' + output);
  console.log('PASS: SQLite initialized and the welcome screen rendered. Screenshot: ' + join(output, 'welcome.png'));
} finally {
  socket?.close();
  child.kill();
}
