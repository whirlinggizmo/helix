// Builds the game (build.hxml) for a page and runs it there: node run.cjs [arguments], each --name or --name=value, the program's
// arguments as the page's query gives them (Sys.args()). The native build is type-checked first (haxe build.hxml --no-output), then
// the page is built from build.hxml's lines, less its -cpp line and its helix-raylib-asset-host define, as app.js beside index.html,
// and opened in headless Chromium (Playwright's own, on SwiftShader) at 1280 x 720, muted. What the page logs and its errors are
// printed, and each file it downloads (a screenshot TakeScreenshot saves) is saved in this directory under its name. The run ends
// when the program has (it waits on no frame, timer or fetch for a second) or after 60 seconds. What the page saves (its local
// storage) is kept between runs, as the page is served at one port for each directory.
const fs = require('fs'), path = require('path'), http = require('http'), {spawnSync} = require('child_process');
const root = __dirname, CAP = 60;
const query = [];
for (const a of process.argv.slice(2)) {
	const m = /^--([^=]+)(?:=(.*))?$/s.exec(a);
	if (!m) { console.error(`run.cjs: ${a}: an argument is --name or --name=value`); process.exit(1); }
	query.push(encodeURIComponent(m[1]) + (m[2] === undefined ? '' : '=' + encodeURIComponent(m[2])));
}
const haxe = args => spawnSync('haxe', args, {cwd: root, stdio: 'inherit'}).status === 0;
if (!haxe(['build.hxml', '--no-output'])) { console.error('run.cjs: the native build has errors'); process.exit(1); }
const lines = fs.readFileSync(path.join(root, 'build.hxml'), 'utf8').split('\n').filter(l => !l.startsWith('-cpp') && !l.includes('helix-raylib-asset-host'));
fs.writeFileSync(path.join(root, 'page.hxml'), ['# Written by run.cjs from build.hxml.', ...lines, '-js app.js', '-D js-es=6'].join('\n') + '\n');
if (!haxe(['page.hxml'])) { console.error('run.cjs: the page build has errors'); process.exit(1); }

const TYPES = {'.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg'};
const server = http.createServer((request, response) => {
	let file = path.normalize(path.join(root, decodeURIComponent(new URL(request.url, 'http://x').pathname)));
	if (!file.startsWith(root)) { response.writeHead(403); response.end(); return; }
	if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
	if (!fs.existsSync(file)) { response.writeHead(404); response.end(); return; }
	response.writeHead(200, {'Content-Type': TYPES[path.extname(file).toLowerCase()] || 'application/octet-stream'});
	fs.createReadStream(file).pipe(response);
});

// In the page: counts the frames, timers and fetches the page waits on, and calls helixRunEnded once it has waited on none for a second.
function watch() {
	const waiting = new Set(), frame = window.requestAnimationFrame.bind(window), cancelFrame = window.cancelAnimationFrame.bind(window);
	const timeout = window.setTimeout.bind(window), interval = window.setInterval.bind(window), fetched = window.fetch.bind(window);
	const clearTimeout = window.clearTimeout.bind(window), clearInterval = window.clearInterval.bind(window);
	let idle = performance.now(), fetches = 0;
	const busy = () => { idle = performance.now(); };
	window.requestAnimationFrame = f => { const id = frame(t => { waiting.delete('f' + id); busy(); f(t); }); waiting.add('f' + id); return id; };
	window.cancelAnimationFrame = id => { waiting.delete('f' + id); cancelFrame(id); };
	window.setTimeout = (f, ms, ...a) => { const id = timeout(() => { waiting.delete('t' + id); busy(); typeof f === 'function' ? f(...a) : eval(f); }, ms); waiting.add('t' + id); return id; };
	window.setInterval = (f, ms, ...a) => { const id = interval(() => { busy(); f(...a); }, ms); waiting.add('t' + id); return id; };
	window.clearTimeout = window.clearInterval = id => { waiting.delete('t' + id); busy(); clearTimeout(id); };
	window.fetch = (...a) => { fetches++; return fetched(...a).finally(() => { fetches--; busy(); }); };
	const check = interval(() => {
		if (document.readyState !== 'complete' || waiting.size > 0 || fetches > 0) busy();
		else if (performance.now() - idle > 1000) { clearInterval(check); window.helixRunEnded(); }
	}, 100);
}

// The port, from the directory's path, so the page's origin and so its saves stay from one run to the next.
const port = 20000 + [...root].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 20000, 0);
server.listen(port, '127.0.0.1', async () => {
	const {chromium} = require(process.env.HELIX_PLAYWRIGHT);
	const profile = path.join(process.env.XDG_DATA_HOME || path.join(root, '.data'), 'browser');
	const context = await chromium.launchPersistentContext(profile, {headless: true, viewport: {width: 1280, height: 720}, acceptDownloads: true,
		args: ['--no-sandbox', '--mute-audio', '--autoplay-policy=no-user-gesture-required', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']});
	let stopped = false;
	try {
		const page = context.pages()[0] || await context.newPage();
		const saves = [];
		// The browser's own lines for a file that isn't there and the driver's are left out: the program logs what it couldn't load.
		page.on('console', m => { if (!/^Failed to load resource|^\[\.WebGL-/.test(m.text())) console.log(m.text()); });
		page.on('pageerror', e => console.log(`page error: ${e.stack || e.message}`));
		page.on('download', d => saves.push(d.saveAs(path.join(root, path.basename(d.suggestedFilename()))).then(
			() => console.log(`run.cjs: saved ${path.basename(d.suggestedFilename())}`), e => console.log(`run.cjs: ${d.suggestedFilename()} wasn't saved: ${e.message}`))));
		const ended = new Promise(resolve => context.exposeFunction('helixRunEnded', resolve));
		await context.addInitScript(watch);
		await page.goto(`http://127.0.0.1:${port}/${query.length ? '?' + query.join('&') : ''}`);
		stopped = await Promise.race([ended.then(() => false), new Promise(resolve => setTimeout(() => resolve(true), CAP * 1000))]);
		await Promise.all(saves);
		console.log(stopped ? `run.cjs: stopped after ${CAP} seconds, as the program hadn't ended (CloseWindow)` : 'run.cjs: the program ended');
	} finally {
		await context.close();
		server.close();
	}
	process.exit(stopped ? 1 : 0);
});
