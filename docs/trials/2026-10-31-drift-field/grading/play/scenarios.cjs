const {field, sleep, G} = require('./lib.cjs');
const path = require('path');
const playing = f => !!f.cam;
const notPlaying = f => !f.cam;
const ROCK = '130,130,130,255';
const INFLATE = 22;
const CELL = 10;

function levelFile(n, name) {
	return name.startsWith('level') ? path.join(G, process.env.BUILDS || 'builds', String(n), 'web', 'assets', 'levels', name + '.txt') : path.join(G, name + '.txt');
}
function distRect(c, r) {
	const dx = Math.max(r.x - c.x, 0, c.x - (r.x + r.w));
	const dy = Math.max(r.y - c.y, 0, c.y - (r.y + r.h));
	return Math.hypot(dx, dy);
}
function summarize(f) {
	const fl = field(f);
	const rocks = fl.rocks.filter(r => r.color == ROCK);
	const sidesOk = rocks.every(r => r.w >= 40 && r.w <= 160 && r.h >= 40 && r.h <= 160);
	let minClear = Infinity;
	for (const c of fl.crystals) for (const r of rocks) minClear = Math.min(minClear, distRect(c, r) - c.r);
	return {
		frame: f.n,
		cam: f.cam,
		fieldRect: fl.fieldRect,
		otherRects: fl.rocks.filter(r => r.color != ROCK),
		rocks: rocks.map(r => [r.x, r.y, r.w, r.h]),
		crystals: fl.crystals.map(c => [c.x, c.y]),
		crystalColor: fl.crystals[0] && fl.crystals[0].color,
		nRocks: rocks.length,
		nCrystals: fl.crystals.length,
		sidesOk,
		minCrystalRockGap: minClear,
		text: f.text
	};
}
const ship = f => ({x: f.cam.tx, y: f.cam.ty});
const num = (f, re) => {
	const m = f.text.match(re);
	return m ? Number(m[1]) : null;
};
const scoreOf = f => num(f, /Score: (-?\d+)/);
const levelOf = f => {
	const m = f.text.match(/Level: (\w+)/);
	return m ? m[1] : null;
};
const timeOf = f => num(f, /Time: (-?\d+)/);

async function start(g) {
	await g.press('space');
	return g.rec.waitFor(playing, 15000, 'play');
}
async function toTitle(g) {
	await g.press('esc');
	return g.rec.waitFor(notPlaying, 5000, 'title');
}

// ---- path finding on the recorded field

class Grid {
	constructor(f) {
		const fl = field(f);
		this.W = fl.fieldRect.w;
		this.H = fl.fieldRect.h;
		this.rocks = fl.rocks.filter(r => r.color == ROCK);
		this.nx = Math.ceil(this.W / CELL);
		this.ny = Math.ceil(this.H / CELL);
		this.free = new Uint8Array(this.nx * this.ny);
		for (let j = 0; j < this.ny; j++)
			for (let i = 0; i < this.nx; i++) this.free[j * this.nx + i] = this.pointFree((i + 0.5) * CELL, (j + 0.5) * CELL) ? 1 : 0;
	}
	pointFree(x, y, m = INFLATE) {
		if (x < m || y < m || x > this.W - m || y > this.H - m) return false;
		for (const r of this.rocks) if (x > r.x - m && x < r.x + r.w + m && y > r.y - m && y < r.y + r.h + m) return false;
		return true;
	}
	cell(x, y) {
		return [Math.min(this.nx - 1, Math.max(0, Math.floor(x / CELL))), Math.min(this.ny - 1, Math.max(0, Math.floor(y / CELL)))];
	}
	los(a, b, m = INFLATE) {
		const d = Math.hypot(b.x - a.x, b.y - a.y);
		const k = Math.max(1, Math.ceil(d / 4));
		for (let i = 0; i <= k; i++) if (!this.pointFree(a.x + ((b.x - a.x) * i) / k, a.y + ((b.y - a.y) * i) / k, m)) return false;
		return true;
	}
	// BFS from a point: distances and parents over free cells
	bfs(p) {
		const N = this.nx * this.ny;
		const dist = new Int32Array(N).fill(-1);
		const par = new Int32Array(N).fill(-1);
		let [i0, j0] = this.cell(p.x, p.y);
		// start at the nearest free cell
		let s = j0 * this.nx + i0;
		if (!this.free[s]) {
			let best = -1, bd = 1e9;
			for (let j = Math.max(0, j0 - 6); j < Math.min(this.ny, j0 + 7); j++)
				for (let i = Math.max(0, i0 - 6); i < Math.min(this.nx, i0 + 7); i++)
					if (this.free[j * this.nx + i] && (i - i0) ** 2 + (j - j0) ** 2 < bd) {
						bd = (i - i0) ** 2 + (j - j0) ** 2;
						best = j * this.nx + i;
					}
			if (best < 0) return null;
			s = best;
		}
		const q = new Int32Array(N);
		let h = 0, t = 0;
		q[t++] = s;
		dist[s] = 0;
		while (h < t) {
			const c = q[h++];
			const ci = c % this.nx, cj = (c - ci) / this.nx;
			for (let dj = -1; dj <= 1; dj++)
				for (let di = -1; di <= 1; di++) {
					if (!di && !dj) continue;
					const i = ci + di, j = cj + dj;
					if (i < 0 || j < 0 || i >= this.nx || j >= this.ny) continue;
					const n = j * this.nx + i;
					if (!this.free[n] || dist[n] >= 0) continue;
					if (di && dj && (!this.free[cj * this.nx + i] || !this.free[j * this.nx + ci])) continue;
					dist[n] = dist[c] + 1;
					par[n] = c;
					q[t++] = n;
				}
		}
		return {dist, par, s};
	}
	// the free cell nearest a target point, within r px
	nearFree(x, y, b, r = 26) {
		const [i0, j0] = this.cell(x, y);
		let best = -1, bd = 1e9;
		const k = Math.ceil(r / CELL);
		for (let j = Math.max(0, j0 - k); j < Math.min(this.ny, j0 + k + 1); j++)
			for (let i = Math.max(0, i0 - k); i < Math.min(this.nx, i0 + k + 1); i++) {
				const n = j * this.nx + i;
				if (!this.free[n] || (b && b.dist[n] < 0)) continue;
				const d = Math.hypot((i + 0.5) * CELL - x, (j + 0.5) * CELL - y);
				if (d <= r && d < bd) {
					bd = d;
					best = n;
				}
			}
		return best;
	}
	pathTo(b, n, from, goal) {
		const pts = [];
		for (let c = n; c >= 0; c = b.par[c]) {
			const i = c % this.nx, j = (c - i) / this.nx;
			pts.push({x: (i + 0.5) * CELL, y: (j + 0.5) * CELL});
		}
		pts.reverse();
		if (goal) pts.push(goal);
		// line of sight simplification
		const out = [];
		let cur = from;
		let k = 0;
		while (k < pts.length) {
			let far = k;
			for (let m = pts.length - 1; m > k; m--)
				if (this.los(cur, pts[m], INFLATE)) {
					far = m;
					break;
				}
			out.push(pts[far]);
			cur = pts[far];
			k = far + 1;
		}
		return out;
	}
}

class Steer {
	constructor(g) {
		this.g = g;
		this.held = new Set();
	}
	async set(keys) {
		const want = new Set(keys);
		for (const k of [...this.held]) if (!want.has(k)) {
			await this.g.keyUp(k);
			this.held.delete(k);
		}
		for (const k of want) if (!this.held.has(k)) {
			await this.g.keyDown(k);
			this.held.add(k);
		}
	}
	async release() {
		await this.set([]);
	}
}

// Steers along waypoints with the arrow keys; stops when done, stuck, or stop(f) is true.
async function follow(g, steer, pts, stop, maxMs = 15000) {
	const t0 = Date.now();
	let k = 0, lastProgress = Date.now(), lastPos = null;
	while (k < pts.length) {
		const f = await g.rec.waitFrames(1);
		if (stop && stop(f)) return 'stopped';
		if (!f.cam) return 'not playing';
		const p = ship(f);
		const w = pts[k];
		const dx = w.x - p.x, dy = w.y - p.y;
		if (Math.hypot(dx, dy) < 7) {
			k++;
			continue;
		}
		const keys = [];
		const tol = 3;
		if (dx > tol) keys.push('right');
		else if (dx < -tol) keys.push('left');
		if (dy > tol) keys.push('down');
		else if (dy < -tol) keys.push('up');
		await steer.set(keys);
		if (!lastPos || Math.hypot(p.x - lastPos.x, p.y - lastPos.y) > 2) {
			lastPos = p;
			lastProgress = Date.now();
		}
		if (Date.now() - lastProgress > 1200) {
			await steer.release();
			return 'stuck';
		}
		if (Date.now() - t0 > maxMs) {
			await steer.release();
			return 'timeout';
		}
	}
	await steer.release();
	return 'arrived';
}

async function goTo(g, steer, x, y) {
	const f = g.rec.last;
	const grid = new Grid(f);
	const b = grid.bfs(ship(f));
	if (!b) return 'no start';
	const n = grid.nearFree(x, y, b, 40);
	if (n < 0) return 'no goal';
	return follow(g, steer, grid.pathTo(b, n, ship(f), grid.pointFree(x, y, INFLATE - 6) ? {x, y} : null));
}

// Gathers crystals, nearest first, until stop(f) or none is reachable; records gathering checks.
async function gather(g, steer, stop, log) {
	const stuckOn = new Map();
	while (true) {
		const f = g.rec.last;
		if (!f.cam || stop(f)) break;
		const fl = field(f);
		const grid = new Grid(f);
		const b = grid.bfs(ship(f));
		if (!b) break;
		let best = null, bd = 1e9;
		for (const c of fl.crystals) {
			if (Math.abs(c.r - 8) > 1e-9) continue;
			const key = c.x + ',' + c.y;
			if ((stuckOn.get(key) || 0) >= 2) continue;
			const n = grid.nearFree(c.x, c.y, b, 22);
			if (n < 0) continue;
			if (b.dist[n] < bd) {
				bd = b.dist[n];
				best = {c, n, key};
			}
		}
		if (!best) {
			log.push('no reachable crystal at frame ' + f.n + ', ' + fl.crystals.length + ' left');
			return 'none';
		}
		const pts = grid.pathTo(b, best.n, ship(f), {x: best.c.x, y: best.c.y});
		const before = fl.crystals.length;
		const r = await follow(g, steer, pts, ff => stop(ff) || !ff.cam || field(ff).crystals.length < before);
		if (r == 'stuck' || r == 'timeout' || r == 'arrived') {
			const now = g.rec.last;
			if (now.cam && field(now).crystals.length >= before) stuckOn.set(best.key, (stuckOn.get(best.key) || 0) + 1);
		}
		if (r == 'not playing') break;
	}
	await steer.release();
	return 'done';
}

// Checks every pair of consecutive play frames of one level: crystals gone vs score added.
function gatherCheck(frames) {
	let events = 0, mismatches = [];
	for (let i = 1; i < frames.length; i++) {
		const a = frames[i - 1], b = frames[i];
		if (!a.cam || !b.cam || levelOf(a) != levelOf(b)) continue;
		const gone = field(a).crystals.length - field(b).crystals.length;
		const added = scoreOf(b) - scoreOf(a);
		if (gone || added) {
			events += gone;
			if (gone != added) mismatches.push({frame: b.n, gone, added});
		}
	}
	return {events, mismatches};
}

function screenToWorld(cam, sx, sy) {
	const a = (cam.rot * Math.PI) / 180;
	const dx = (sx - cam.ox) / cam.zoom, dy = (sy - cam.oy) / cam.zoom;
	return {x: cam.tx + dx * Math.cos(a) + dy * Math.sin(a), y: cam.ty - dx * Math.sin(a) + dy * Math.cos(a)};
}
function crossOf(f) {
	const ls = f.world.filter(c => c.name.startsWith('DrawLine'));
	if (ls.length < 2) return null;
	let sx = 0, sy = 0, k = 0;
	for (const c of ls.slice(0, 2)) {
		const a = c.args;
		let p, q;
		if (c.name == 'DrawLine') {
			p = {x: a[0], y: a[1]};
			q = {x: a[2], y: a[3]};
		} else {
			p = a[0];
			q = a[1];
		}
		sx += p.x + q.x;
		sy += p.y + q.y;
		k += 2;
	}
	return {x: sx / k, y: sy / k, calls: ls.slice(0, 2).map(c => c.name + ' ' + JSON.stringify(c.args.slice(0, 4)))};
}
// The map: what's drawn between the scissor and the frame, its bounds, the scissor and frame.
function mapOf(f) {
	let i = f.calls.findIndex(c => c.name == 'BeginScissorMode');
	if (i < 0) return null;
	const sc = f.calls[i].args;
	const inside = [];
	let frame = null;
	for (let k = i + 1; k < f.calls.length; k++) {
		const c = f.calls[k];
		if (c.name.startsWith('DrawRectangleLines')) {
			frame = c;
			break;
		}
		if (c.name == 'DrawText') break;
		inside.push(c);
	}
	let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
	const add = (x, y, w, h) => {
		x0 = Math.min(x0, x);
		y0 = Math.min(y0, y);
		x1 = Math.max(x1, x + w);
		y1 = Math.max(y1, y + h);
	};
	for (const c of inside) {
		const a = c.args;
		if (c.name == 'DrawRectangleRec') add(a[0].x, a[0].y, a[0].w, a[0].h);
		else if (c.name == 'DrawRectangle') add(a[0], a[1], a[2], a[3]);
		else if (c.name == 'DrawCircleV') add(a[0].x - a[1], a[0].y - a[1], 2 * a[1], 2 * a[1]);
		else if (c.name == 'DrawCircle') add(a[0] - a[2], a[1] - a[2], 2 * a[2], 2 * a[2]);
	}
	// the background rect drawn just before the scissor
	const bg = f.calls[i - 1];
	return {
		scissor: sc,
		background: bg ? bg.name + ' ' + JSON.stringify(bg.args) : null,
		frame: frame ? frame.name + ' ' + JSON.stringify(frame.args) : null,
		drawn: inside.length,
		bounds: [x0, y0, x1 - x0, y1 - y0],
		needsClip: x0 < sc[0] - 0.01 || y0 < sc[1] - 0.01 || x1 > sc[0] + sc[2] + 0.01 || y1 > sc[1] + sc[3] + 0.01
	};
}
function textsOf(f) {
	return f.texts.map(t => `${t.mode}:${JSON.stringify(t.s)}@${t.x},${t.y}`);
}

// Holds keys for ms and measures the ship's speed from its positions over the frames' arrival times.
async function measure(g, steer, keys, ms, opts = {}) {
	const first = g.rec.last.n;
	await steer.set(keys);
	const t0 = Date.now();
	if (opts.during) await opts.during(ms);
	else await sleep(ms);
	await steer.release();
	await g.rec.waitFrames(3);
	const fr = g.rec.frames.filter(f => f.n > first && f.cam);
	// moving frames
	const pos = fr.map(f => ({n: f.n, t: f.t, ...ship(f)}));
	const mv = [];
	for (let i = 1; i < pos.length; i++) {
		const d = Math.hypot(pos[i].x - pos[i - 1].x, pos[i].y - pos[i - 1].y);
		if (d > 0.01) mv.push(i);
	}
	if (mv.length < 10) return {error: 'too few moving frames', n: mv.length};
	const a = pos[mv[3]], b = pos[mv[mv.length - 4]];
	const dist = Math.hypot(b.x - a.x, b.y - a.y);
	const steps = [];
	for (let i = mv[3]; i <= mv[mv.length - 4]; i++) steps.push(Math.hypot(pos[i].x - pos[i - 1].x, pos[i].y - pos[i - 1].y));
	steps.sort((p, q) => p - q);
	const dts = [];
	for (let i = mv[3] + 1; i <= mv[mv.length - 4]; i++) dts.push(pos[i].t - pos[i - 1].t);
	dts.sort((p, q) => p - q);
	return {
		keys,
		frames: b.n - a.n,
		dist: +dist.toFixed(2),
		seconds: +((b.t - a.t) / 1000).toFixed(4),
		speed: +(dist / ((b.t - a.t) / 1000)).toFixed(1),
		medianStep: +steps[steps.length >> 1].toFixed(3),
		medianFrameMs: +dts[dts.length >> 1].toFixed(2),
		from: [a.x, a.y],
		to: [b.x, b.y],
		heldMs: Date.now() - t0
	};
}

// A straight run from p in direction d of length L, clear of rocks.
function clearDir(grid, p, dirs, L) {
	for (const d of dirs) {
		const n = Math.hypot(d[0], d[1]);
		if (grid.los(p, {x: p.x + (d[0] / n) * L, y: p.y + (d[1] / n) * L})) return d;
	}
	return null;
}

const DIRS = {right: [1, 0], left: [-1, 0], up: [0, -1], down: [0, 1]};
function keysFor(d) {
	const k = [];
	if (d[0] > 0) k.push('right');
	if (d[0] < 0) k.push('left');
	if (d[1] > 0) k.push('down');
	if (d[1] < 0) k.push('up');
	return k;
}

// Makes room: drives to a point with a clear run of L in some direction (straight and diagonal).
async function openSpace(g, steer, L) {
	const f = g.rec.last;
	const grid = new Grid(f);
	const p = ship(f);
	const straight = [[1, 0], [-1, 0], [0, 1], [0, -1]];
	const diag = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
	const s = clearDir(grid, p, straight, L), d = clearDir(grid, p, diag, L);
	if (s && d) return {s, d};
	// look for a spot with both
	for (let r = 50; r < 800; r += 50)
		for (let a = 0; a < 16; a++) {
			const q = {x: p.x + r * Math.cos((a * Math.PI) / 8), y: p.y + r * Math.sin((a * Math.PI) / 8)};
			if (!grid.pointFree(q.x, q.y)) continue;
			const s2 = clearDir(grid, q, straight, L), d2 = clearDir(grid, q, diag, L);
			if (s2 && d2) {
				await goTo(g, steer, q.x, q.y);
				return {s: s2, d: d2};
			}
		}
	return null;
}

module.exports = {
	summarize,
	playing,
	async smoke(make, tag) {
		const g = make(tag);
		await g.start();
		const t = g.rec.last;
		const f = await start(g);
		await g.rec.waitFrames(10);
		await g.screenshot(tag + '-' + g.kind);
		const r = {title: t.text, first: summarize(f), errors: g.rec.errors};
		await g.stop();
		return r;
	},
	async field(make, tag) {
		const g = make(tag);
		await g.start();
		const res = {};
		res.level1 = summarize(await start(g));
		await toTitle(g);
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// Drops on the title and in play.
	async drops(make, tag) {
		const g = make(tag);
		await g.start();
		const res = {};
		const watch = async (label, file, ms = 4500) => {
			const n0 = g.rec.last.n;
			await g.drop(file);
			await sleep(ms);
			const fr = g.rec.frames.filter(f => f.n > n0);
			const notes = fr.filter(f => /Not a level/.test(f.text));
			const play = fr.filter(f => f.cam);
			res[label] = {
				framesAfter: fr.length,
				playFrames: play.length,
				levelsSeen: [...new Set(play.map(levelOf))],
				firstPlay: play[0] ? summarize(play[0]) : null,
				note: notes.length ? notes[0].texts.filter(t => /Not a level/.test(t.s)).map(t => t.s)[0] : null,
				noteSeconds: notes.length ? +((notes[notes.length - 1].t - notes[0].t) / 1000).toFixed(2) : 0,
				lastText: g.rec.last.text
			};
			if (notes.length) {
				await sleep(0);
			}
			return res[label];
		};
		await watch('title_custom', levelFile(g.n, 'custom'));
		await g.screenshot('drop-title-custom-' + g.kind);
		await watch('title_custom_other', levelFile(g.n, 'custom-other-seed'));
		await watch('title_notlevel', levelFile(g.n, 'not-a-level'));
		// in play
		const f0 = await start(g);
		res.playBefore = {level: levelOf(f0), score: scoreOf(f0), crystals: field(f0).crystals.length};
		await watch('play_custom', levelFile(g.n, 'custom'), 2500);
		await g.screenshot('drop-play-custom-' + g.kind);
		await watch('play_notlevel', levelFile(g.n, 'not-a-level'), 2000);
		await g.screenshot('drop-play-notlevel-' + g.kind);
		const f1 = g.rec.last;
		res.playAfter = {playing: !!f1.cam, level: levelOf(f1), score: scoreOf(f1), text: f1.text};
		res.errors = g.rec.errors;
		res.exited = g.exited || null;
		await g.stop();
		return res;
	},

	// Speed straight and diagonal; frame-rate independence (throttled frames).
	async speed(make, tag, target) {
		const opts = {};
		if (tag.includes('slow') && target == 'page')
			opts.init = () => {
				// frames at ~20 a second
				window.requestAnimationFrame = cb => setTimeout(() => cb(performance.now()), 50);
			};
		const g = make(tag, opts);
		await g.start();
		await start(g);
		await g.rec.waitFrames(5);
		const steer = new Steer(g);
		const res = {};
		const sp = await openSpace(g, steer, 520);
		if (!sp) return {error: 'no open space'};
		await g.rec.waitFrames(5);
		let during;
		if (tag.includes('slow') && target == 'native') {
			// pause the program 40 ms of every 60 ms: fewer, longer frames
			during = async ms => {
				const end = Date.now() + ms;
				while (Date.now() < end) {
					g.proc.kill('SIGSTOP');
					await sleep(40);
					g.proc.kill('SIGCONT');
					await sleep(20);
				}
			};
		}
		res.straight = await measure(g, steer, keysFor(sp.s), 1500, {during});
		await g.rec.waitFrames(5);
		// back again for room
		res.straightBack = await measure(g, steer, keysFor([-sp.s[0], -sp.s[1]]), 1500, {during});
		await g.rec.waitFrames(5);
		res.diagonal = await measure(g, steer, keysFor(sp.d), 1500, {during});
		await g.rec.waitFrames(5);
		res.diagonalBack = await measure(g, steer, keysFor([-sp.d[0], -sp.d[1]]), 1500, {during});
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// Click to fly at zooms and turns; map; text; R.
	async click(make, tag) {
		const g = make(tag);
		await g.start();
		await start(g);
		const steer = new Steer(g);
		await g.rec.waitFrames(5);
		const res = {configs: []};
		await g.move(480, 270);
		const sw = () => g.rec.last.cam.ox * 2, sh = () => g.rec.last.cam.oy * 2;
		const wheel = async (up, k) => {
			for (let i = 0; i < k; i++) {
				await g.wheel(up);
				await sleep(40);
			}
			await g.rec.waitFrames(3);
			return g.rec.last.cam.zoom;
		};
		const turn = async (key, ms) => {
			const a = g.rec.last;
			await g.keyDown(key);
			await sleep(ms);
			await g.keyUp(key);
			await g.rec.waitFrames(3);
			const b = g.rec.last;
			// rate from the frames that turned
			const fr = g.rec.frames.filter(f => f.n > a.n && f.cam);
			let t0 = null, t1 = null, r0, r1;
			for (let i = 1; i < fr.length; i++)
				if (fr[i].cam.rot != fr[i - 1].cam.rot) {
					if (t0 == null) {
						t0 = fr[i - 1].t;
						r0 = fr[i - 1].cam.rot;
					}
					t1 = fr[i].t;
					r1 = fr[i].cam.rot;
				}
			return {from: a.cam.rot, to: b.cam.rot, rate: t0 == null ? 0 : +((r1 - r0) / ((t1 - t0) / 1000)).toFixed(1)};
		};
		const tryClick = async label => {
			await g.rec.waitFrames(3);
			const f = g.rec.last;
			const grid = new Grid(f);
			const cam = f.cam;
			const W = sw(), H = sh();
			const offs = [[180, -110], [-180, 110], [-200, -100], [200, 90], [120, 140], [-120, -140], [260, 0], [-260, 0], [0, -150], [0, 150], [90, -60], [-90, 60], [60, 40], [-60, -40]];
			let pick = null;
			for (const [ox, oy] of offs) {
				const sx = Math.round(W / 2 + ox), sy = Math.round(H / 2 + oy);
				if (sx > W - 220 && sy > H - 140) continue; // the map
				if (sy < 90) continue;
				const w = screenToWorld(cam, sx, sy);
				if (grid.pointFree(w.x, w.y, 24) && grid.los(ship(f), w, 20)) {
					pick = {sx, sy, w};
					break;
				}
			}
			const out = {label, cam, map: mapOf(f), texts: textsOf(f)};
			if (!pick) {
				out.error = 'no clear point';
				res.configs.push(out);
				return out;
			}
			await g.screenshot('click-' + label + '-' + g.kind);
			const n0 = g.rec.last.n;
			const crossP = g.rec.waitFor(ff => crossOf(ff), 4000, 'cross').catch(() => null);
			await g.click(pick.sx, pick.sy);
			let cf = await crossP;
			if (!cf) out.error = 'no cross drawn';
			const prev = g.rec.frames[g.rec.frames.indexOf(cf) - 1] || f;
			const expected = screenToWorld(prev.cam, pick.sx, pick.sy);
			out.screen = [pick.sx, pick.sy];
			out.expected = [+expected.x.toFixed(3), +expected.y.toFixed(3)];
			if (cf) {
				const c = crossOf(cf);
				out.cross = [c.x, c.y];
				out.crossErr = +Math.hypot(c.x - expected.x, c.y - expected.y).toFixed(3);
				out.crossCalls = c.calls;
			}
			let af;
			try {
				af = await g.rec.waitFor(ff => !crossOf(ff), 6000, 'arrival');
				await g.rec.waitFrames(2);
			} catch (e) {
				out.arrival = 'cross still drawn after 6 s';
			}
			const end = ship(g.rec.last);
			out.shipEnd = [+end.x.toFixed(3), +end.y.toFixed(3)];
			out.shipErr = +Math.hypot(end.x - expected.x, end.y - expected.y).toFixed(3);
			res.configs.push(out);
			return out;
		};
		// zoom 1, turn 0
		await tryClick('z1');
		// zoom out: clamp at 0.5
		res.zoomOut = await wheel(false, 12);
		await tryClick('z0.5');
		res.zoomIn = await wheel(true, 25);
		await tryClick('z2');
		await g.press('r');
		await g.rec.waitFrames(3);
		res.afterR1 = {zoom: g.rec.last.cam.zoom, rot: g.rec.last.cam.rot};
		res.turnQ = await turn('q', 500);
		await tryClick('z1-turnQ');
		res.turnE = await turn('e', 1500);
		await wheel(false, 12);
		await tryClick('z0.5-turnE');
		await wheel(true, 25);
		await tryClick('z2-turnE');
		await g.screenshot('turned-zoom2-' + g.kind);
		await g.press('r');
		await g.rec.waitFrames(3);
		res.afterR2 = {zoom: g.rec.last.cam.zoom, rot: g.rec.last.cam.rot};
		// key cancels a flight
		const crossP = g.rec.waitFor(ff => crossOf(ff), 4000, 'cross').catch(() => null);
		await g.click(Math.round(sw() / 2 + 200), Math.round(sh() / 2 - 100));
		const cb = await crossP;
		await g.press('left', 80);
		await g.rec.waitFrames(3);
		const p1 = ship(g.rec.last);
		await sleep(500);
		const p2 = ship(g.rec.last);
		res.keyCancels = {crossBefore: !!cb, crossAfter: !!crossOf(g.rec.last), movedAfterKey: +Math.hypot(p2.x - p1.x, p2.y - p1.y).toFixed(2)};
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// Window resizes: view, ship centered, text at edges, map.
	async resize(make, tag) {
		const g = make(tag);
		await g.start();
		await start(g);
		await g.rec.waitFrames(5);
		const res = {sizes: []};
		const look = async (w, h) => {
			if (w) await g.resize(w, h);
			await sleep(600);
			await g.rec.waitFrames(5);
			const f = g.rec.last;
			const t = f.texts.find(x => /Time/.test(x.s));
			res.sizes.push({
				asked: [w, h],
				camOffset: [f.cam.ox, f.cam.oy],
				shipCentered: true,
				texts: textsOf(f),
				timeText: t ? {x: t.x, y: t.y} : null,
				map: mapOf(f)
			});
			await g.screenshot(`resize-${w || 'start'}x${h || ''}-${g.kind}`);
		};
		await look(null, null);
		await look(1280, 720);
		await look(700, 420);
		await look(960, 540);
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// Rocks and the edge stop the ship; it slides.
	async collide(make, tag) {
		const g = make(tag);
		await g.start();
		await start(g);
		await g.rec.waitFrames(5);
		const steer = new Steer(g);
		const res = {};
		const f = g.rec.last;
		const grid = new Grid(f);
		const p = ship(f);
		const rocks = grid.rocks.slice().sort((a, b) => Math.hypot(a.x + a.w / 2 - p.x, a.y + a.h / 2 - p.y) - Math.hypot(b.x + b.w / 2 - p.x, b.y + b.h / 2 - p.y));
		const track = (n0, rock) => {
			const fr = g.rec.frames.filter(ff => ff.n > n0 && ff.cam).map(ff => ship(ff));
			return fr;
		};
		// approach a rock's left side, hold right + up: it should stop at the side and slide up
		for (const rock of rocks) {
			if (rock.h < 90) continue;
			const ax = rock.x - 30, ay = rock.y + rock.h - 25;
			if (!grid.pointFree(ax, ay) || !grid.pointFree(ax, rock.y - 40) || !grid.los({x: ax, y: ay}, {x: ax, y: rock.y - 40})) continue;
			if (!grid.los({x: ax, y: rock.y - 40}, {x: rock.x + rock.w + 40, y: rock.y - 40})) continue;
			const r = await goTo(g, steer, ax, ay);
			if (r != 'arrived') continue;
			await g.rec.waitFrames(3);
			const n0 = g.rec.last.n;
			await steer.set(['right', 'up']);
			await sleep(1300);
			await steer.release();
			await g.rec.waitFrames(3);
			const tr = track(n0);
			const xs = tr.map(q => q.x);
			const maxX = Math.max(...xs);
			// frames while beside the rock (y within its side)
			const beside = tr.filter(q => q.y > rock.y + 2 && q.y < rock.y + rock.h - 2);
			res.rock = {
				rock: [rock.x, rock.y, rock.w, rock.h],
				start: tr[0],
				end: tr[tr.length - 1],
				maxXBeside: beside.length ? Math.max(...beside.map(q => q.x)) : null,
				gapToSide: beside.length ? +(rock.x - Math.max(...beside.map(q => q.x))).toFixed(3) : null,
				yWhileBeside: beside.length ? [beside[0].y, beside[beside.length - 1].y] : null,
				passedOver: tr.some(q => q.x > rock.x && q.x < rock.x + rock.w && q.y > rock.y && q.y < rock.y + rock.h),
				passedTop: tr[tr.length - 1].y < rock.y
			};
			break;
		}
		// the left edge: hold left + down
		let r2;
		for (const y of [p.y, 300, 500, 700, 900, 400, 600, 800]) {
			if (!grid.los({x: 40, y}, {x: 40, y: y + 250}) || !grid.los({x: 40, y}, {x: 140, y})) continue;
			r2 = await goTo(g, steer, 90, y);
			if (r2 == 'arrived') break;
		}
		res.edgeApproach = r2;
		await g.rec.waitFrames(3);
		const n1 = g.rec.last.n;
		await steer.set(['left', 'down']);
		await sleep(1000);
		await steer.release();
		await g.rec.waitFrames(3);
		const tr = track(n1);
		res.edge = {start: tr[0], end: tr[tr.length - 1], minX: Math.min(...tr.map(q => q.x)), yMoved: tr[tr.length - 1].y - tr[0].y};
		// and the top edge, hold up + right
		await g.rec.waitFrames(3);
		let r3;
		for (const x of [p.x - 200, p.x, p.x + 300, 600, 1200, 900]) {
			if (!grid.los({x, y: 40}, {x: x - 200, y: 40}) || !grid.los({x, y: 40}, {x, y: 140})) continue;
			r3 = await goTo(g, steer, x, 90);
			if (r3 == 'arrived') break;
		}
		const n2 = g.rec.last.n;
		await steer.set(['up', 'left']);
		await sleep(700);
		await steer.release();
		await g.rec.waitFrames(3);
		const tr2 = track(n2);
		res.topEdge = {approach: r3, start: tr2[0], end: tr2[tr2.length - 1], minY: Math.min(...tr2.map(q => q.y)), xMoved: tr2[tr2.length - 1].x - tr2[0].x};
		await g.screenshot('collide-' + g.kind);
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// The whole campaign by autopilot, the best after a reload or restart, Escape.
	async flow(make, tag, target) {
		const opts = {};
		if (target == 'page')
			opts.init = () => {
				const s = AudioBufferSourceNode.prototype.start;
				AudioBufferSourceNode.prototype.start = function (...a) {
					console.log('SOUND buffer-source start');
					return s.apply(this, a);
				};
				const p = HTMLMediaElement.prototype.play;
				HTMLMediaElement.prototype.play = function (...a) {
					console.log('SOUND media play ' + this.src);
					return p.apply(this, a);
				};
			};
		const g = make(tag, opts);
		await g.start();
		const res = {levels: [], log: []};
		res.titleBefore = g.rec.last.text;
		const steer = new Steer(g);
		await start(g);
		for (let L = 1; L <= 4; L++) {
			let f;
			try {
				const fL = await g.rec.waitFor(ff => ff.cam && levelOf(ff) == String(L), 15000, 'level ' + L);
				f = await g.rec.waitFor(ff => ff.cam && levelOf(ff) == String(L) && field(ff).crystals.length > 0, 15000, 'level ' + L + ' field');
				if (fL.n != f.n) res.log.push(`level ${L}: "Level: ${L}" shown from frame ${fL.n} (${fL.text}; ${field(fL).crystals.length} crystals), its field from frame ${f.n}`);
			} catch (e) {
				break;
			}
			const info = {level: L, first: summarize(f), startFrame: f.n};
			const lv = String(L);
			info.gather = await gather(g, steer, ff => !ff.cam || levelOf(ff) != lv, res.log);
			// wait for the level to end
			let endF;
			try {
				endF = await g.rec.waitFor(ff => !ff.cam || levelOf(ff) != lv, 90000, 'level end');
			} catch (e) {
				info.error = 'level did not end';
			}
			const fr = g.rec.frames.filter(ff => ff.n >= f.n && ff.cam && levelOf(ff) == lv);
			info.endedAtTime = fr.length ? timeOf(fr[fr.length - 1]) : null;
			const last = fr[fr.length - 1];
			info.last = {frame: last.n, text: last.text, crystalsLeft: field(last).crystals.length};
			info.check = gatherCheck(fr);
			info.after = endF ? endF.text : null;
			res.levels.push(info);
			if (endF && !endF.cam) {
				// a message, or loading: wait to see what comes
				const seen = [];
				const t0 = Date.now();
				while (Date.now() - t0 < 8000) {
					const ff = await g.rec.waitFrames(1);
					if (!seen.length || seen[seen.length - 1].text != ff.text) seen.push({n: ff.n, t: ff.t, text: ff.text, play: !!ff.cam});
					if (ff.cam) break;
				}
				info.then = seen;
				if (!g.rec.last.cam) break;
			}
		}
		await g.screenshot('flow-end-' + g.kind);
		res.titleAfter = g.rec.last.text;
		res.sounds = g.rec.sounds ? g.rec.sounds.length : null;
		// Escape from the title: still running
		await g.press('esc');
		await sleep(800);
		res.escOnTitle = {exited: g.exited || null, text: g.rec.last.text, playing: !!g.rec.last.cam};
		if (g.rec.last.cam) {
			await toTitle(g);
		}
		res.errors = g.rec.errors.slice();
		// the best after a reload or restart
		if (target == 'page') {
			await g.reload();
			await sleep(1500);
			res.afterReload = g.rec.last.text;
			await g.stop();
		} else {
			await g.stop();
			res.exitedAfterStop = g.exited;
			const g2 = make(tag + '-restart', {xdg: g.xdg});
			await g2.start();
			await sleep(1500);
			res.afterRestart = g2.rec.last.text;
			await g2.stop();
		}
		return res;
	},

	// Time runs out short of the target.
	async timeout(make, tag) {
		const g = make(tag);
		await g.start();
		const f0 = await start(g);
		res = {first: f0.text};
		let mf;
		try {
			mf = await g.rec.waitFor(ff => !ff.cam, 75000, 'time out');
		} catch (e) {
			res.error = 'still playing';
		}
		const lastPlay = g.rec.frames.filter(ff => ff.cam).pop();
		res.lastPlay = lastPlay.text;
		res.playSeconds = +((lastPlay.t - f0.t) / 1000).toFixed(2);
		const seen = [];
		const t0 = Date.now();
		while (Date.now() - t0 < 6000) {
			const ff = await g.rec.waitFrames(1);
			if (!seen.length || seen[seen.length - 1].text != ff.text) seen.push({n: ff.n, s: +((ff.t - mf.t) / 1000).toFixed(2), text: ff.text});
		}
		res.then = seen;
		await g.screenshot('timeout-' + g.kind);
		res.errors = g.rec.errors;
		await g.stop();
		return res;
	},

	// The best is saved at once: gather 3, then reload / kill and restart, mid-level.
	async bestnow(make, tag, target) {
		const g = make(tag);
		await g.start();
		await start(g);
		const steer = new Steer(g);
		const res = {log: []};
		await gather(g, steer, ff => scoreOf(ff) >= 3, res.log);
		await g.rec.waitFrames(5);
		res.during = g.rec.last.text;
		await sleep(300);
		if (target == 'page') {
			await g.reload();
			await sleep(1500);
			res.afterReload = g.rec.last.text;
			await g.stop();
		} else {
			g.proc.kill('SIGKILL');
			await sleep(500);
			await g.stop();
			const g2 = make(tag + '-restart', {xdg: g.xdg});
			await g2.start();
			await sleep(1500);
			res.afterRestart = g2.rec.last.text;
			await g2.stop();
		}
		return res;
	}
};
let res;
// The right side of the first rock: approach and hold left + up.
module.exports.collideRight = async function (make, tag) {
	const g = make(tag);
	await g.start();
	await start(g);
	await g.rec.waitFrames(5);
	const steer = new Steer(g);
	const grid = new Grid(g.rec.last);
	const rock = grid.rocks[0];
	const ax = rock.x + rock.w + 30, ay = rock.y + rock.h - 25;
	const res = {rock: [rock.x, rock.y, rock.w, rock.h], approach: await goTo(g, steer, ax, ay)};
	await g.rec.waitFrames(3);
	const n0 = g.rec.last.n;
	await steer.set(['left', 'up']);
	await sleep(1300);
	await steer.release();
	await g.rec.waitFrames(3);
	const tr = g.rec.frames.filter(ff => ff.n > n0 && ff.cam).map(ship);
	const beside = tr.filter(q => q.y > rock.y + 2 && q.y < rock.y + rock.h - 2);
	res.start = tr[0];
	res.end = tr[tr.length - 1];
	res.minXBeside = beside.length ? Math.min(...beside.map(q => q.x)) : null;
	res.gapToSide = beside.length ? res.minXBeside - (rock.x + rock.w) : null;
	res.yWhileBeside = beside.length ? [beside[0].y, beside[beside.length - 1].y] : null;
	res.passedOver = tr.some(q => q.x > rock.x && q.x < rock.x + rock.w && q.y > rock.y && q.y < rock.y + rock.h);
	await g.screenshot('collide-right-' + g.kind);
	await g.stop();
	return res;
};
// After the fix: drops on the title and in play, the custom fields, the notice.
module.exports.drops2 = async function (make, tag) {
	const g = make(tag);
	await g.start();
	const steer = new Steer(g);
	const res = {};
	const dropPlay = async (label, name) => {
		const n0 = g.rec.last.n;
		const before = g.rec.last.text;
		await g.drop(levelFile(g.n, name));
		let f;
		try {
			f = await g.rec.waitFor(ff => ff.cam && field(ff).crystals.length > 0 && /Level: Custom/.test(ff.text), 8000, 'custom play');
		} catch (e) {
			res[label] = {error: String(e), before, text: g.rec.last.text};
			return null;
		}
		res[label] = {before, first: summarize(f), level: levelOf(f), text: f.text, framesToPlay: f.n - n0};
		return f;
	};
	const title = () => g.rec.waitFor(notPlaying, 8000, 'title');
	// 1. custom on the title, played to its end by gathering every crystal
	if (await dropPlay('title_custom', 'custom')) {
		await g.rec.waitFrames(3);
		await gather(g, steer, ff => !ff.cam || !/Custom/.test(ff.text), []);
		try {
			const e = await g.rec.waitFor(ff => !ff.cam, 40000, 'custom end');
			const lastPlay = g.rec.frames.filter(ff => ff.cam).pop();
			const seen = [];
			const t0 = Date.now();
			while (Date.now() - t0 < 5000) {
				const ff = await g.rec.waitFrames(1);
				if (!seen.length || seen[seen.length - 1].text != ff.text) seen.push({s: +((ff.t - e.t) / 1000).toFixed(2), text: ff.text, play: !!ff.cam});
			}
			res.title_custom.end = {lastPlay: lastPlay.text, after: seen};
		} catch (err) {
			res.title_custom.end = {error: String(err), text: g.rec.last.text};
		}
		await g.screenshot('fixed-after-custom-' + g.kind);
	}
	// 2. custom-other-seed, then custom again, on the title
	if (g.rec.last.cam) await toTitle(g);
	if (await dropPlay('title_other', 'custom-other-seed')) await toTitle(g);
	if (await dropPlay('title_custom_again', 'custom')) await toTitle(g);
	// 3. not a level on the title
	const notice = async (label, ms) => {
		const n0 = g.rec.last.n;
		const before = g.rec.last;
		await g.drop(levelFile(g.n, 'not-a-level'));
		await sleep(ms);
		const fr = g.rec.frames.filter(ff => ff.n > n0);
		const notes = fr.filter(ff => /Not a level/.test(ff.text));
		res[label] = {
			before: before.text,
			note: notes.length ? notes[0].texts.find(t => /Not a level/.test(t.s)).s : null,
			noteSeconds: notes.length ? +((notes[notes.length - 1].t - notes[0].t) / 1000).toFixed(2) : 0,
			playFrames: fr.filter(ff => ff.cam).length,
			levels: [...new Set(fr.filter(ff => ff.cam).map(levelOf))],
			after: g.rec.last.text
		};
	};
	await notice('title_notlevel', 4500);
	// 4. in play: custom replaces level 1
	const f1 = await start(g);
	await g.rec.waitFrames(30);
	if (await dropPlay('play_custom', 'custom')) {
		await g.screenshot('fixed-play-custom-' + g.kind);
		await toTitle(g);
	}
	// 5. in play: not a level leaves the game as it was
	const f2 = await start(g);
	await g.rec.waitFrames(30);
	const p0 = g.rec.last;
	await notice('play_notlevel', 4000);
	const p1 = g.rec.last;
	res.play_notlevel.state = {
		beforeLevel: levelOf(p0), afterLevel: levelOf(p1), playing: !!p1.cam,
		crystalsBefore: field(p0).crystals.length, crystalsAfter: p1.cam ? field(p1).crystals.length : null,
		timeBefore: timeOf(p0), timeAfter: timeOf(p1), sameField: p1.cam ? JSON.stringify(summarize(p0).rocks) == JSON.stringify(summarize(p1).rocks) : false
	};
	await g.screenshot('fixed-play-notlevel-' + g.kind);
	res.errors = g.rec.errors;
	res.exited = g.exited || null;
	await g.stop();
	return res;
};
