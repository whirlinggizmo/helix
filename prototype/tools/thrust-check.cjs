// Exercise normal gameplay while observing actual Web Audio loop/gain behavior.
const path = require('node:path');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {parseArgs} = require('node:util');
const root = path.resolve(__dirname, '..');
const {chromium} = require(path.join(root, 'build/tools/node_modules/playwright'));
const {values} = parseArgs({options: {browser: {type: 'string'}, url: {type: 'string', default: 'http://127.0.0.1:8050/'}}});
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

(async () => {
  const artifacts = {};
  for (const file of ['app.js', 'assets/sounds/thrust-v4.ogg']) {
    const response = await fetch(new URL(file, values.url));
    assert.equal(response.status, 200, file);
    const identity = sha(Buffer.from(await response.arrayBuffer()));
    assert.equal(identity, sha(fs.readFileSync(path.join(root, 'build/web', file))), 'Served artifact differs: '+file);
    artifacts[file] = identity;
  }
  const browser = await chromium.launch({executablePath: values.browser, headless: true, args: ['--no-sandbox', '--use-angle=vulkan']});
  try {
    const page = await browser.newPage({viewport: {width: 800, height: 600}});
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.addInitScript(() => {
      window.engineProbe = [];
      const create = AudioContext.prototype.createBufferSource;
      AudioContext.prototype.createBufferSource = function () {
        const node = create.call(this), connect = node.connect, start = node.start, stop = node.stop;
        let gain, entry;
        node.connect = function (target, ...rest) {
          if (target.gain) gain = target;
          return connect.call(this, target, ...rest);
        };
        node.start = function (...args) {
          if (this.loop) {
            const pcm = this.buffer.getChannelData(0);
            let sum = 0, peak = 0, steps = 0, cross = 0, first = 0, second = 0;
            for (const v of pcm) {sum += v*v; peak = Math.max(peak, Math.abs(v));}
            for (let i=1; i<pcm.length; i++) steps += (pcm[i]-pcm[i-1])**2;
            const half = pcm.length/2;
            for (let i=0; i<half; i++) {
              cross += pcm[i]*pcm[i+half]; first += pcm[i]**2; second += pcm[i+half]**2;
            }
            entry = {started: performance.now(), stopped: null, frames: pcm.length,
              duration: this.buffer.duration, rms: Math.sqrt(sum/pcm.length), peak,
              seamStep: Math.abs(pcm[0]-pcm[pcm.length-1]),
              adjacentStepRms: Math.sqrt(steps/(pcm.length-1)),
              halfLoopCorrelation: cross/Math.sqrt(first*second),
              gainAtStart: gain.gain.value, levels: []};
            window.engineProbe.push(entry);
            const timer = setInterval(() => {
              entry.levels.push(gain.gain.value);
              if (entry.stopped !== null) clearInterval(timer);
            }, 10);
          }
          return start.apply(this, args);
        };
        node.stop = function (...args) {
          if (entry) entry.stopped = performance.now();
          return stop.apply(this, args);
        };
        return node;
      };
    });
    const url = new URL(values.url); url.searchParams.set('frames', '3600');
    await page.goto(url.href);
    await page.waitForFunction(() => window.inspect && window.inspect().ready);
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.inspect().game.state === 'playing');
    await page.keyboard.down('w'); await page.keyboard.down('Space');
    await page.waitForFunction(() => window.engineProbe.length > 0);
    await page.waitForTimeout(2400);
    const held = await page.evaluate(() => ({game: window.inspect().game, loops: window.hostInfo().audioLoops, probe: window.engineProbe}));
    assert.equal(held.game.deaths, 0);
    assert.equal(held.loops, 1); assert.equal(held.probe.length, 1);
    assert.equal(held.probe[0].stopped, null);
    assert.equal(held.probe[0].frames, 88200); assert(held.probe[0].rms > .08);
    assert(held.probe[0].peak < 1);
    assert(held.probe[0].seamStep < 4*held.probe[0].adjacentStepRms);
    assert(held.probe[0].halfLoopCorrelation < .8, 'Two halves should not repeat the same one-second phrase');
    assert(held.probe[0].levels.some(v => Math.abs(v-.65) < 1e-6));
    await page.keyboard.up('w'); await page.keyboard.up('Space');
    await page.waitForFunction(() => window.hostInfo().audioLoops === 0);
    const released = await page.evaluate(() => window.engineProbe);
    assert(released[0].stopped > released[0].started+2000);
    assert(released[0].levels.some(v => v > .01 && v < .1));
    assert.deepEqual(errors, []);
    const report = {passed: true, browser: browser.version(),
      method: 'Normal keyboard gameplay; instrumented Web Audio sources/gains; no audible-quality claim',
      holdMs: 2400, oneLoopBeyondClipDuration: true, rampObserved: true,
      loopStoppedOnRelease: true, probe: released, artifacts};
    fs.writeFileSync(path.join(root, '../results/thrust-audio.json'), JSON.stringify(report, null, 2)+'\n');
    console.log(JSON.stringify({...report, probe: released.map(p => ({...p, levels: [...new Set(p.levels)]}))}));
  } finally {await browser.close();}
})().catch(e => {console.error(e); process.exitCode = 1;});
