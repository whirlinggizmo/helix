// One page run for tools/compare/compare.py: serves DIRECTORY on 127.0.0.1 (a port the system picks), opens index.html?QUERY in
// Chromium on the GPU with its frame rate cap lifted, waits up to TIMEOUT seconds for the program's JSON line on the console, and prints
// {result, files, renderer, errors} as JSON: result the program's line (null when none came), files the paths the page fetched with their
// sizes (for the size column), renderer the WebGL renderer's name and the frames a second requestAnimationFrame runs at.
// BROWSER is a Chromium to run, or "" for Playwright's own (build/tools, or the one HELIX_PLAYWRIGHT names). BACKEND is what ANGLE draws
// over: vulkan or gl. WIDTH and HEIGHT are the viewport's, in pixels. --headed opens the browser's window on the display; --headless, the
// default, runs it off screen.
const given = require('../cli.cjs').args(__filename, ['browser', 'directory', 'query', 'timeout', 'backend', 'width', 'height'],
	['--headed', '--headless']);
const [browserPath, directory, query, timeout, backend, width, height] = given;
const path = require('path'), http = require('http'), fs = require('fs');
const {chromium} = require(process.env.HELIX_PLAYWRIGHT || path.join(__dirname, '../../build/tools/node_modules/playwright'));
const TYPES = {'.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.json': 'application/json',
	'.pck': 'application/octet-stream', '.data': 'application/octet-stream', '.glb': 'model/gltf-binary', '.svg': 'image/svg+xml'};
const root = path.resolve(directory);
const fetched = [];

// Serves the directory, on a port the system picks, noting each file asked for.
function serve() {
	const server = http.createServer((request, response) => {
		let name = decodeURIComponent(new URL(request.url, 'http://x').pathname);
		if (name.endsWith('/')) name += 'index.html';
		const file = path.normalize(path.join(root, name));
		if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
			fetched.push({path: name, status: 404});
			response.writeHead(404);
			response.end();
			return;
		}
		fetched.push({path: name, status: 200, bytes: fs.statSync(file).size});
		response.writeHead(200, {'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store'});
		fs.createReadStream(file).pipe(response);
	});
	return new Promise(resolve => server.listen(0, '127.0.0.1', () => resolve(server)));
}

(async () => {
	const server = await serve();
	const browser = await chromium.launch({executablePath: browserPath || undefined, headless: !given.flags.has('--headed'),
		args: ['--no-sandbox', '--mute-audio', '--autoplay-policy=no-user-gesture-required', `--use-angle=${backend}`, '--disable-gpu-vsync',
			'--disable-frame-rate-limit']});
	const errors = [];
	let result = null;
	try {
		const page = await browser.newPage({viewport: {width: Number(width), height: Number(height)}});
		let found;
		const line = new Promise(resolve => found = resolve);
		page.on('pageerror', e => errors.push(e.message));
		page.on('console', m => {
			const text = m.text();
			if (text.startsWith('{') && text.includes('"contender"')) {
				try { found(JSON.parse(text)); } catch (e) { errors.push('console: ' + text.slice(0, 300)); }
			} else if (m.type() === 'error') errors.push('console: ' + text);
		});
		await page.goto(`http://127.0.0.1:${server.address().port}/index.html${query ? '?' + query : ''}`);
		result = await Promise.race([line, new Promise(resolve => setTimeout(() => resolve(null), Number(timeout) * 1000))]);
		if (!result) errors.push(`no result in ${timeout} seconds`);
		const renderer = await page.evaluate(async () => {
			const out = {};
			const gl = document.createElement('canvas').getContext('webgl2');
			if (gl) {
				const info = gl.getExtension('WEBGL_debug_renderer_info');
				out.webgl2 = info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
			}
			out.frameHz = await new Promise(resolve => {
				let n = 0, t0 = 0;
				const tick = t => { if (n === 0) t0 = t; if (++n === 61) resolve(60000 / (t - t0)); else requestAnimationFrame(tick); };
				requestAnimationFrame(tick);
			});
			return out;
		});
		console.log(JSON.stringify({result, files: fetched, renderer, errors}));
	} finally {
		await browser.close();
		server.close();
	}
})().then(() => process.exit(0)).catch(e => { console.error(e.stack || String(e)); process.exit(1); });
