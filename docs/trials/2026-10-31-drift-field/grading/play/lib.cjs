// Drivers for grading: one interface over a page (Playwright, Chromium) and a native program (xdotool on a private display).
const path = require('path');
const fs = require('fs');
const http = require('http');
const cp = require('child_process');
const G = path.resolve(__dirname, '..');
const {chromium} = require('/home/rknopf/projects/github/whirlinggizmo/helix-2.0/build/tools/node_modules/playwright');

function tokens(s) {
	return s.match(/"(?:[^"\\]|\\.)*"|\S+/g) || [];
}
function value(t) {
	if (t[0] == '"') return JSON.parse(t);
	if (t[0] == '(') {
		const [x, y] = t.slice(1, -1).split(',').map(Number);
		return {x, y};
	}
	if (t[0] == '[') {
		const [x, y, w, h] = t.slice(1, -1).split(',').map(Number);
		return {x, y, w, h};
	}
	if (t[0] == '#') return t.slice(1).split(',').map(Number);
	if (t.startsWith('cam(')) {
		const [ox, oy, tx, ty, rot, zoom] = t.slice(4, -1).split(',').map(Number);
		return {ox, oy, tx, ty, rot, zoom};
	}
	if (t == 'null') return null;
	if (t == 'true' || t == 'false') return t == 'true';
	const n = Number(t);
	return isNaN(n) ? t : n;
}

/** Collects REC lines into frames. */
class Recorder {
	constructor(logPath) {
		this.frames = [];
		this.current = [];
		this.log = fs.createWriteStream(logPath);
		this.errors = [];
		this.waiters = [];
	}
	line(s, t) {
		this.log.write(s + '\n');
		if (s.startsWith('SOUND')) (this.sounds = this.sounds || []).push({t, frame: this.last ? this.last.n + 1 : 0, s});
		if (!s.startsWith('REC ')) return;
		const rest = s.slice(4);
		const sp = rest.indexOf(' ');
		const n = Number(rest.slice(0, sp));
		const r2 = rest.slice(sp + 1);
		const sp2 = r2.indexOf(' ');
		const name = sp2 < 0 ? r2 : r2.slice(0, sp2);
		const args = sp2 < 0 ? [] : tokens(r2.slice(sp2 + 1)).map(value);
		this.current.push({name, args});
		if (name == 'EndDrawing') {
			const f = analyse({n, t, calls: this.current});
			this.current = [];
			this.frames.push(f);
			for (const w of this.waiters.slice()) w(f);
		}
	}
	get last() {
		return this.frames[this.frames.length - 1];
	}
	/** Waits for a frame satisfying pred (checking frames from now on), up to ms. */
	waitFor(pred, ms = 10000, what = 'condition') {
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => {
				this.waiters = this.waiters.filter(x => x != w);
				reject(new Error('timeout waiting for ' + what));
			}, ms);
			const w = f => {
				if (pred(f)) {
					clearTimeout(timer);
					this.waiters = this.waiters.filter(x => x != w);
					resolve(f);
				}
			};
			this.waiters.push(w);
		});
	}
	frames_(k) {
		return this.waitFrames(k);
	}
	async waitFrames(k) {
		const start = this.last ? this.last.n : -1;
		return this.waitFor(f => f.n >= start + k, 20000, k + ' frames');
	}
}

/** Splits a frame's calls into world, map and screen parts. */
function analyse(f) {
	let mode = 'screen';
	f.world = [];
	f.map = [];
	f.screen = [];
	f.texts = [];
	f.scissors = [];
	for (const c of f.calls) {
		if (c.name == 'BeginMode2D') {
			mode = 'world';
			f.cam = c.args[0];
			continue;
		}
		if (c.name == 'EndMode2D') {
			mode = 'screen';
			continue;
		}
		if (c.name == 'BeginScissorMode') {
			f.scissors.push(c.args);
			mode = 'map';
			continue;
		}
		if (c.name == 'EndDrawing') continue;
		if (c.name == 'DrawText') f.texts.push({s: c.args[0], x: c.args[1], y: c.args[2], size: c.args[3], mode});
		(mode == 'world' ? f.world : mode == 'map' ? f.map : f.screen).push(c);
	}
	f.text = f.texts.map(t => t.s).join(' | ');
	return f;
}

/** The rectangles and circles drawn in world coordinates, normalised. */
function shapes(f) {
	const rects = [], circles = [];
	for (const c of f.world) {
		const a = c.args;
		if (c.name == 'DrawRectangleRec') rects.push({x: a[0].x, y: a[0].y, w: a[0].w, h: a[0].h, color: a[1].join(',')});
		else if (c.name == 'DrawRectangle') rects.push({x: a[0], y: a[1], w: a[2], h: a[3], color: a[4].join(',')});
		else if (c.name == 'DrawRectangleV') rects.push({x: a[0].x, y: a[0].y, w: a[1].x, h: a[1].y, color: a[2].join(',')});
		else if (c.name == 'DrawCircleV') circles.push({x: a[0].x, y: a[0].y, r: a[1], color: a[2].join(',')});
		else if (c.name == 'DrawCircle') circles.push({x: a[0], y: a[1], r: a[2], color: a[3].join(',')});
	}
	return {rects, circles};
}

/** The field from a frame's shapes: the field rect (at 0,0, first), rocks and crystals. */
function field(f) {
	const {rects, circles} = shapes(f);
	const fieldRect = rects[0];
	const rocks = rects.slice(1);
	const crystals = circles.filter(c => Math.abs(c.r - 8) < 1e-9);
	return {fieldRect, rocks, crystals, rects, circles};
}

function serve(directory) {
	const root = path.resolve(directory);
	const TYPES = {'.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png', '.wav': 'audio/wav', '.txt': 'text/plain'};
	const server = http.createServer((request, response) => {
		let file = path.normalize(path.join(root, decodeURIComponent(new URL(request.url, 'http://x').pathname)));
		if (!file.startsWith(root)) {
			response.writeHead(403);
			response.end();
			return;
		}
		if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
		if (!fs.existsSync(file)) {
			response.writeHead(404);
			response.end();
			return;
		}
		response.writeHead(200, {'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream'});
		fs.createReadStream(file).pipe(response);
	});
	return new Promise(resolve => server.listen(0, '127.0.0.1', () => resolve(server)));
}

const PAGE_KEYS = {left: 'ArrowLeft', right: 'ArrowRight', up: 'ArrowUp', down: 'ArrowDown', esc: 'Escape', space: 'Space'};
const X_KEYS = {left: 'Left', right: 'Right', up: 'Up', down: 'Down', esc: 'Escape', space: 'space'};
const sleep = ms => new Promise(r => setTimeout(r, ms));

class PageGame {
	constructor(n, tag, opts = {}) {
		this.n = n;
		this.tag = tag;
		this.opts = opts;
		this.kind = 'page';
		this.rec = new Recorder(path.join(G, 'play', String(n), tag + '.page.log'));
	}
	async start() {
		this.server = await serve(path.join(G, process.env.BUILDS || 'builds', String(this.n), 'web'));
		const port = this.server.address().port;
		if ([8060, 8061, 8064, 8443, 8488].includes(port)) throw new Error('forbidden port');
		this.browser = this.opts.browser || (await chromium.launch({headless: true, args: ['--no-sandbox', '--mute-audio', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']}));
		this.context = this.opts.context || (await this.browser.newContext({viewport: {width: 960, height: 540}}));
		this.page = await this.context.newPage();
		if (this.opts.init) await this.page.addInitScript(this.opts.init);
		this.page.on('console', m => {
			const t = performance.now();
			if (m.type() == 'error') this.rec.errors.push('console: ' + m.text());
			this.rec.line(m.text(), t);
		});
		this.page.on('pageerror', e => this.rec.errors.push('pageerror: ' + e.message));
		await this.page.goto(`http://127.0.0.1:${port}/`);
		await this.rec.waitFrames(5);
	}
	async reload() {
		await this.page.reload();
		await sleep(500);
		await this.rec.waitFrames(5);
	}
	async keyDown(k) {
		await this.page.keyboard.down(PAGE_KEYS[k] || 'Key' + k.toUpperCase());
	}
	async keyUp(k) {
		await this.page.keyboard.up(PAGE_KEYS[k] || 'Key' + k.toUpperCase());
	}
	async press(k, ms = 60) {
		await this.keyDown(k);
		await sleep(ms);
		await this.keyUp(k);
	}
	async click(x, y) {
		await this.page.mouse.move(x, y);
		await sleep(30);
		await this.page.mouse.down();
		await sleep(60);
		await this.page.mouse.up();
	}
	async move(x, y) {
		await this.page.mouse.move(x, y);
	}
	async wheel(up) {
		// one notch: up zooms in
		await this.page.mouse.wheel(0, up ? -100 : 100);
	}
	async resize(w, h) {
		await this.page.setViewportSize({width: w, height: h});
	}
	async drop(file) {
		const name = path.basename(file);
		const text = fs.readFileSync(file, 'utf8');
		await this.page.evaluate(([name, text]) => {
			const canvas = document.querySelector('canvas');
			const dt = new DataTransfer();
			dt.items.add(new File([text], name, {type: 'text/plain'}));
			const r = canvas.getBoundingClientRect();
			for (const type of ['dragenter', 'dragover', 'drop'])
				canvas.dispatchEvent(new DragEvent(type, {dataTransfer: dt, bubbles: true, cancelable: true, clientX: r.width / 2, clientY: r.height / 2}));
		}, [name, text]);
	}
	async screenshot(name) {
		await this.page.screenshot({path: path.join(G, 'play', String(this.n), name + '.png')});
	}
	async stop() {
		try {
			await this.page.close();
		} catch (e) {}
		if (!this.opts.context) await this.context.close();
		if (!this.opts.browser) await this.browser.close();
		this.server.close();
		this.rec.log.end();
	}
}

function x(args) {
	return cp.execFileSync('xdotool', args, {encoding: 'utf8'}).trim();
}

class NativeGame {
	constructor(n, tag, opts = {}) {
		this.n = n;
		this.tag = tag;
		this.opts = opts;
		this.kind = 'native';
		this.rec = new Recorder(path.join(G, 'play', String(n), tag + '.native.log'));
		this.xdg = opts.xdg || path.join(G, 'xdg', `${n}-${tag}`);
	}
	async start() {
		fs.mkdirSync(this.xdg, {recursive: true});
		const env = Object.assign({}, process.env, {XDG_DATA_HOME: this.xdg});
		this.proc = cp.spawn('./native/Main', [], {cwd: path.join(G, process.env.BUILDS || 'builds', String(this.n)), env, stdio: ['ignore', 'pipe', 'pipe']});
		this.exited = null;
		this.proc.on('exit', (code, sig) => (this.exited = {code, sig}));
		let buf = '';
		this.proc.stdout.on('data', d => {
			const t = performance.now();
			buf += d.toString();
			let i;
			while ((i = buf.indexOf('\n')) >= 0) {
				this.rec.line(buf.slice(0, i), t);
				buf = buf.slice(i + 1);
			}
		});
		this.proc.stderr.on('data', d => {
			const s = d.toString();
			this.rec.log.write('STDERR ' + s);
			if (s.trim()) this.rec.errors.push('stderr: ' + s.trim());
		});
		await this.rec.waitFrames(3);
		for (let i = 0; i < 50 && !this.win; i++) {
			try {
				this.win = x(['search', '--pid', String(this.proc.pid)]).split('\n').pop();
			} catch (e) {
				await sleep(100);
			}
		}
		try {
			x(['windowactivate', '--sync', this.win]);
		} catch (e) {}
		x(['windowfocus', '--sync', this.win]);
		await sleep(300);
		await this.rec.waitFrames(3);
	}
	async keyDown(k) {
		x(['keydown', X_KEYS[k] || k]);
	}
	async keyUp(k) {
		x(['keyup', X_KEYS[k] || k]);
	}
	async press(k, ms = 60) {
		await this.keyDown(k);
		await sleep(ms);
		await this.keyUp(k);
	}
	async move(px, py) {
		x(['mousemove', '--window', this.win, String(px), String(py)]);
	}
	async click(px, py) {
		x(['mousemove', '--window', this.win, String(px), String(py)]);
		await sleep(50);
		x(['mousedown', '1']);
		await sleep(60);
		x(['mouseup', '1']);
	}
	async wheel(up) {
		x(['click', up ? '4' : '5']);
	}
	async resize(w, h) {
		x(['windowsize', this.win, String(w), String(h)]);
	}
	/** An XDND drop from a GTK drag source window, moved by xdotool onto the game window's centre. */
	async drop(file) {
		const src = cp.spawn('python3', [path.join(__dirname, 'dragsource.py'), file], {stdio: ['ignore', 'pipe', 'inherit']});
		await new Promise(r => src.stdout.on('data', d => d.toString().includes('READY') && r()));
		const geo = x(['getwindowgeometry', '--shell', this.win]);
		const g = Object.fromEntries(geo.split('\n').map(l => l.split('=')));
		const tx = Number(g.X) + Number(g.WIDTH) / 2, ty = Number(g.Y) + Number(g.HEIGHT) / 2;
		x(['mousemove', '1650', '200']);
		await sleep(200);
		x(['mousedown', '1']);
		await sleep(100);
		for (let i = 1; i <= 20; i++) {
			x(['mousemove', String(Math.round(1650 + (tx - 1650) * i / 20)), String(Math.round(200 + (ty - 200) * i / 20))]);
			await sleep(30);
		}
		await sleep(200);
		x(['mousemove', String(Math.round(tx + 1)), String(Math.round(ty))]);
		await sleep(200);
		x(['mouseup', '1']);
		await new Promise(r => {
			src.on('exit', r);
			setTimeout(r, 3000);
		});
		try {
			src.kill();
		} catch (e) {}
		try {
			x(['windowactivate', '--sync', this.win]);
		} catch (e) {}
		await sleep(200);
	}
	async screenshot(name) {
		cp.execFileSync('import', ['-window', this.win, path.join(G, 'play', String(this.n), name + '.png')]);
	}
	async stop() {
		if (!this.exited) {
			this.proc.kill('SIGTERM');
			for (let i = 0; i < 30 && !this.exited; i++) await sleep(100);
			if (!this.exited) this.proc.kill('SIGKILL');
		}
		this.rec.log.end();
	}
}

module.exports = {PageGame, NativeGame, field, shapes, sleep, analyse, G};
