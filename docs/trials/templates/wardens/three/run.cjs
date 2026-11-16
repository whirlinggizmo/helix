// Bundles the game (src/main.ts or src/main.js) with esbuild into dist/app.js, then opens index.html in headless Chromium at 1280 x 720,
// muted, for --seconds (5), printing the page's console and errors and saving a screenshot at each of --shots (the last second) as
// shots/shot-<second>.png. --query is the page's query, as ?enemies=50&seed=1. What the page saves (its local storage) is kept between
// runs, as the page is served at one port for each directory. --gpu runs it on the GPU (for timing, outside the sandbox) in place of SwiftShader; --frames=W,N prints frames W + 1 to N's mean
// and 95th percentile time, from one animation frame to the next, and ends there.
const fs = require('fs'), path = require('path'), http = require('http'), {execFileSync} = require('child_process');
const options = Object.fromEntries(process.argv.slice(2).map(a => a.replace(/^--/, '').split(/=(.*)/s).slice(0, 2)));
const root = __dirname, seconds = Number(options.seconds || 5);
const shots = (options.shots || String(seconds)).split(',').map(Number);
const entry = ['src/main.ts', 'src/main.js'].find(f => fs.existsSync(path.join(root, f)));
if (!entry) { console.error('run.cjs: no src/main.ts or src/main.js'); process.exit(1); }
try {
	execFileSync(path.join(root, 'node_modules/.bin/esbuild'), [entry, '--bundle', '--format=esm', '--sourcemap', '--outfile=dist/app.js', '--log-level=warning'], {cwd: root, stdio: 'inherit'});
} catch (e) { process.exit(1); }
const TYPES = {'.html': 'text/html', '.js': 'text/javascript', '.map': 'application/json', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
	'.glb': 'model/gltf-binary', '.gltf': 'model/gltf+json', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.mp3': 'audio/mpeg', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2'};
const server = http.createServer((request, response) => {
	let file = path.normalize(path.join(root, decodeURIComponent(new URL(request.url, 'http://x').pathname)));
	if (!file.startsWith(root)) { response.writeHead(403); response.end(); return; }
	if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
	if (!fs.existsSync(file)) { response.writeHead(404); response.end(); return; }
	response.writeHead(200, {'Content-Type': TYPES[path.extname(file).toLowerCase()] || 'application/octet-stream'});
	fs.createReadStream(file).pipe(response);
});
// The port, from the directory's path, so the page's origin and so its saves stay from one run to the next.
const port = 20000 + [...root].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 20000, 0);
server.listen(port, '127.0.0.1', async () => {
	const {chromium} = require(process.env.HELIX_PLAYWRIGHT);
	const profile = path.join(process.env.XDG_DATA_HOME || path.join(root, '.data'), 'browser');
	const gpu = 'gpu' in options ? ['--use-angle=vulkan'] : ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'];
	const context = await chromium.launchPersistentContext(profile, {headless: true, viewport: {width: 1280, height: 720},
		args: ['--no-sandbox', '--mute-audio', '--autoplay-policy=no-user-gesture-required', ...gpu]});
	try {
		const page = context.pages()[0] || await context.newPage();
		page.on('console', m => console.log(`console.${m.type()}: ${m.text()}`));
		page.on('pageerror', e => console.log(`page error: ${e.stack || e.message}`));
		page.on('requestfailed', r => console.log(`request failed: ${r.url()}`));
		page.on('response', r => { if (r.status() >= 400) console.log(`${r.status()}: ${r.url()}`); });
		await page.goto(`http://127.0.0.1:${server.address().port}/${options.query || ''}`);
		if (options.frames) {
			const [skip, last] = options.frames.split(',').map(Number);
			const times = await page.evaluate(([skip, last]) => new Promise(done => {
				const times = []; let before = 0, n = 0;
				const step = now => { if (n > skip) times.push(now - before); before = now; if (++n > last) done(times); else requestAnimationFrame(step); };
				requestAnimationFrame(step);
			}), [skip, last]);
			times.sort((a, b) => a - b);
			const mean = times.reduce((a, b) => a + b, 0) / times.length;
			console.log(JSON.stringify({frames: times.length, meanFrameTime: mean / 1000, p95FrameTime: times[Math.floor(times.length * .95)] / 1000}));
		} else {
			fs.mkdirSync(path.join(root, 'shots'), {recursive: true});
			let at = 0;
			for (const s of [...shots].sort((a, b) => a - b)) {
				await page.waitForTimeout((s - at) * 1000);
				at = s;
				await page.screenshot({path: path.join(root, 'shots', `shot-${s}.png`)});
				console.log(`run.cjs: shots/shot-${s}.png`);
			}
			if (seconds > at) await page.waitForTimeout((seconds - at) * 1000);
		}
	} finally {
		await context.close();
		server.close();
	}
});
