// One run of the bunnymark page (tools/bunnymark.py runs it): serves DIR on 127.0.0.1, opens index.html?QUERY in a headless Chromium on the GPU
// (Vulkan on Linux, Metal on macOS), waits up to TIMEOUT seconds for the program's JSON line on the console, and prints
// {result, errors, renderer} as JSON: result is the program's line (null when none came), renderer the WebGL renderer's name.
// BROWSER is a Chromium to run, or "" for Playwright's own (the repository's, build/tools, or the one HELIX_PLAYWRIGHT names).
const [browserPath, directory, query, timeout] = require('./cli.cjs').args(__filename, ['browser', 'directory', 'query', 'timeout']);
const path = require('path'), http = require('http'), fs = require('fs');
const {chromium} = require(process.env.HELIX_PLAYWRIGHT || path.join(__dirname, '../build/tools/node_modules/playwright'));
const GPU = process.platform === 'linux' ? ['--use-angle=vulkan'] : process.platform === 'darwin' ? ['--use-angle=metal'] : [];
const TYPES = {'.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png'};
const root = path.resolve(directory);

// Serves the directory, on a port the system picks.
function serve() {
	const server = http.createServer((request, response) => {
		let file = path.normalize(path.join(root, decodeURIComponent(new URL(request.url, 'http://x').pathname)));
		if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
		if (!file.startsWith(root) || !fs.existsSync(file)) { response.writeHead(404); response.end(); return; }
		response.writeHead(200, {'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store'});
		fs.createReadStream(file).pipe(response);
	});
	return new Promise(resolve => server.listen(0, '127.0.0.1', () => resolve(server)));
}

(async () => {
	const server = await serve();
	const browser = await chromium.launch({executablePath: browserPath || undefined, headless: true,
		args: ['--no-sandbox', '--mute-audio', '--autoplay-policy=no-user-gesture-required', ...GPU]});
	const errors = [];
	try {
		const page = await browser.newPage({viewport: {width: 800, height: 600}});
		let found;
		const line = new Promise(resolve => found = resolve);
		page.on('pageerror', e => errors.push(e.message));
		page.on('console', m => {
			const text = m.text();
			if (text.startsWith('{') && text.includes('"contender"')) found(JSON.parse(text));
			else if (m.type() === 'error') errors.push('console: ' + text);
		});
		await page.goto(`http://127.0.0.1:${server.address().port}/index.html?${query}`);
		const result = await Promise.race([line, new Promise(resolve => setTimeout(() => resolve(null), Number(timeout) * 1000))]);
		if (!result) errors.push(`no result in ${timeout} seconds`);
		const renderer = await page.evaluate(() => {
			const gl = document.createElement('canvas').getContext('webgl2');
			const info = gl && gl.getExtension('WEBGL_debug_renderer_info');
			return gl ? (info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER)) : null;
		});
		console.log(JSON.stringify({result, errors, renderer}));
	} finally {
		await browser.close();
		server.close();
	}
})().then(() => process.exit(0)).catch(e => { console.error(e.stack || String(e)); process.exit(1); });
