// raylib's textures_bunnymark in three.js, spawning from the query string (count=N, or incrementCount=N startCount=M) as the other contenders do, two ways:
// variant=instanced (the default): one InstancedMesh of a 32 x 32 textured quad, a matrix and a color an instance, the matrices rewritten
// each frame; variant=sprite: one THREE.Sprite a bunny, each with its own SpriteMaterial (a Sprite's color is its material's).
import * as THREE from 'three';

const params = new URLSearchParams(location.search);
const variant = params.get('variant') === 'sprite' ? 'sprite' : 'instanced';
const contender = 'three-' + variant;
// incrementCount=N adds N bunnies each 60 frames, from startCount=M bunnies (N without it).
const incrementCount = Number(params.get('incrementCount') || 0);
const ramp = incrementCount > 0;
const count = ramp ? Number(params.get('startCount') || incrementCount) : Number(params.get('count') || 1000);
const W = 800, H = 450, TW = 32, TH = 32;

// xorshift32 from 2463534242, the same in every contender, so every bunny starts the same.
let seed = 0x92D68CA2;
function rnd(min, max) {
	let x = seed;
	x ^= x << 13; x >>>= 0;
	x ^= x >>> 17;
	x ^= x << 5; x >>>= 0;
	seed = x;
	return min + (x >>> 8) % (max - min + 1);
}

const canvas = document.getElementById('canvas');
const renderer = new THREE.WebGLRenderer({canvas, antialias: false, alpha: false, powerPreference: 'high-performance'});
renderer.setPixelRatio(1);
renderer.setSize(W, H, false);
renderer.setClearColor(0xf5f5f5, 1); // RAYWHITE
renderer.outputColorSpace = THREE.LinearSRGBColorSpace; // no color conversion, as raylib draws
const scene = new THREE.Scene();
// Pixels, y down, as raylib's screen.
const camera = new THREE.OrthographicCamera(0, W, 0, H, -1, 1);
camera.position.z = 0;

const bunnies = []; // {x, y, sx, sy, r, g, b}
function spawn(n) {
	for (let i = 0; i < n; i++) {
		const px = rnd(0, W - TW), py = rnd(40, H - TH);
		const sx = rnd(-250, 250) / 60, sy = rnd(-250, 250) / 60;
		const r = rnd(50, 240), g = rnd(80, 240), b = rnd(100, 240);
		bunnies.push({x: px, y: py, sx, sy, r, g, b});
	}
}

const texture = new THREE.TextureLoader().load('wabbit_alpha.png', start);
texture.colorSpace = THREE.NoColorSpace;
texture.magFilter = texture.minFilter = THREE.NearestFilter;
texture.generateMipmaps = false;
texture.flipY = false; // the camera's y runs down, which flips the image back

// --- instanced ---
let mesh = null, capacity = 0;
const geometry = new THREE.PlaneGeometry(TW, TH);
geometry.translate(TW / 2, TH / 2, 0); // the quad from its top left, as DrawTexture places it
const instancedMaterial = new THREE.MeshBasicMaterial({map: texture, transparent: true, depthTest: false, depthWrite: false, side: THREE.DoubleSide});
function ensureCapacity(n) {
	if (n <= capacity) return;
	const wanted = Math.max(n, capacity * 2, 1000);
	const made = new THREE.InstancedMesh(geometry, instancedMaterial, wanted);
	made.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
	made.frustumCulled = false;
	// Identities, their translation written each frame; colors as spawned.
	const a = made.instanceMatrix.array;
	for (let i = 0; i < wanted; i++) { a[i * 16] = 1; a[i * 16 + 5] = 1; a[i * 16 + 10] = 1; a[i * 16 + 15] = 1; }
	const color = new THREE.Color();
	for (let i = 0; i < bunnies.length; i++) { const b = bunnies[i]; made.setColorAt(i, color.setRGB(b.r / 255, b.g / 255, b.b / 255)); }
	if (mesh) { scene.remove(mesh); mesh.dispose(); }
	mesh = made; capacity = wanted;
	scene.add(mesh);
}
let colored = 0; // instances whose color is set
function drawInstanced() {
	ensureCapacity(bunnies.length);
	if (colored < bunnies.length) {
		const color = new THREE.Color();
		for (let i = colored; i < bunnies.length; i++) { const b = bunnies[i]; mesh.setColorAt(i, color.setRGB(b.r / 255, b.g / 255, b.b / 255)); }
		mesh.instanceColor.needsUpdate = true;
		colored = bunnies.length;
	}
	const a = mesh.instanceMatrix.array;
	for (let i = 0; i < bunnies.length; i++) {
		const b = bunnies[i];
		a[i * 16 + 12] = Math.trunc(b.x);
		a[i * 16 + 13] = Math.trunc(b.y);
	}
	mesh.count = bunnies.length;
	mesh.instanceMatrix.needsUpdate = true;
	renderer.render(scene, camera);
}

// --- sprites ---
// Sprites don't show through the y-down camera, so they take the usual y-up one and their y is flipped, still to whole pixels.
const spriteCamera = new THREE.OrthographicCamera(0, W, H, 0, -1, 1);
const spriteTexture = texture.clone();
spriteTexture.flipY = true;
const sprites = [];
function drawSprites() {
	while (sprites.length < bunnies.length) {
		const b = bunnies[sprites.length];
		const material = new THREE.SpriteMaterial({map: spriteTexture, color: new THREE.Color(b.r / 255, b.g / 255, b.b / 255), depthTest: false, depthWrite: false});
		const sprite = new THREE.Sprite(material);
		sprite.scale.set(TW, TH, 1);
		sprite.frustumCulled = false;
		scene.add(sprite);
		sprites.push(sprite);
	}
	for (let i = 0; i < bunnies.length; i++) {
		const b = bunnies[i];
		sprites[i].position.set(Math.trunc(b.x) + TW / 2, H - Math.trunc(b.y) - TH / 2, 0);
	}
	renderer.render(scene, spriteCamera);
}

const draw = variant === 'sprite' ? drawSprites : drawInstanced;

let frame = -1, last = 0, firstFrameMs = 0, windowStart = 0, maxCount = 0, done = false;
const deltas = [];
function tick() {
	if (done) return;
	const now = performance.now();
	if (frame < 0) spawn(count); else deltas.push(now - last);
	last = now;
	frame++;
	for (const b of bunnies) {
		b.x += b.sx; b.y += b.sy;
		if (b.x + TW / 2 > W || b.x + TW / 2 < 0) b.sx *= -1;
		if (b.y + TH / 2 > H || b.y + TH / 2 - 40 < 0) b.sy *= -1;
	}
	draw();
	if (frame === 0) {
		firstFrameMs = performance.now();
		if (params.get('debug')) console.log('DEBUG children=' + scene.children.length + ' calls=' + renderer.info.render.calls + ' tris=' + renderer.info.render.triangles + ' mapImage=' + !!texture.image + ' first=' + JSON.stringify(bunnies[0]));
	}
	if (!ramp) {
		if (deltas.length === 720) {
			const timed = deltas.slice(120), sorted = timed.slice().sort((a, b) => a - b);
			const mean = timed.reduce((s, d) => s + d, 0) / timed.length;
			console.log(JSON.stringify({contender, target: 'page', mode: 'count', count, mean_ms: mean, median_ms: sorted[300], p95_ms: sorted[570], fps: 1000 / mean, first_frame_ms: firstFrameMs}));
			done = true;
			return;
		}
	} else if (deltas.length >= 120 && (deltas.length - 120) % 60 === 0) {
		if (deltas.length > 120) {
			const fps = 60 * 1000 / (now - windowStart);
			if (fps >= 59 && bunnies.length < 2000000) { maxCount = bunnies.length; spawn(incrementCount); }
			else {
				console.log(JSON.stringify({contender, target: 'page', mode: 'ramp', max_count: maxCount, last_fps: fps, first_frame_ms: firstFrameMs}));
				done = true;
				return;
			}
		}
		windowStart = now;
	}
	requestAnimationFrame(tick);
}
function start() { requestAnimationFrame(tick); }
