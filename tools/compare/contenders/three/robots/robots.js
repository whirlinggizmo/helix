// raylib's models_animation, many at once, in three.js: count=N robots (robot.glb) in a grid, each a SkinnedMesh clone with its own
// AnimationMixer set to frame (frame + 1 + i * 5) % frameCount of the first animation each frame, drawn unlit (MeshBasicMaterial with the
// model's map), skinned on the GPU as three does. Prints one JSON line like src/robots/Main.hx.
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {clone as cloneSkeleton} from 'three/addons/utils/SkeletonUtils.js';

const params = new URLSearchParams(location.search);
const count = Number(params.get('count') || 100);
const W = 1280, H = 720;
const cols = Math.ceil(Math.sqrt(count)), w = cols * 4;

const canvas = document.getElementById('canvas');
const renderer = new THREE.WebGLRenderer({canvas, antialias: false, alpha: false, powerPreference: 'high-performance'});
renderer.setPixelRatio(1);
renderer.setSize(W, H, false);
renderer.setClearColor(0xf5f5f5, 1);
renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(45, W / H, 0.1, 1000);
camera.position.set(0, 0.9 * w, 0.9 * w);
camera.lookAt(0, 1.5, 0);

new GLTFLoader().load('robot.glb', gltf => {
	const clip = gltf.animations[0];
	const frameCount = Math.round(clip.duration * 60) + 1;
	// Unlit, as helix-raylib's DrawModel draws there: each material's color (the robot has no maps) on a basic material, shared by every clone.
	const materials = new Map();
	let verts = 0, bones = 0;
	gltf.scene.traverse(o => {
		if (o.isMesh) {
			const m = o.material;
			if (params.get('debug')) console.log('DEBUG mesh ' + o.name + ' skinned=' + !!o.isSkinnedMesh + ' map=' + !!m.map + ' vertexColors=' + m.vertexColors + ' color=' + m.color.getHexString() + ' hasColorAttr=' + !!o.geometry.attributes.color + ' verts=' + o.geometry.attributes.position.count);
			if (!materials.has(m)) materials.set(m, new THREE.MeshBasicMaterial({map: m.map, color: m.color}));
			o.material = materials.get(m);
			verts += o.geometry.attributes.position.count;
			if (o.isSkinnedMesh) bones = o.skeleton.bones.length;
		}
	});
	for (const t of materials.keys()) if (t.map) { t.map.colorSpace = THREE.NoColorSpace; }
	const mixers = [];
	for (let i = 0; i < count; i++) {
		const robot = cloneSkeleton(gltf.scene);
		robot.position.set(((i % cols) - (cols - 1) / 2) * 4, 0, (Math.floor(i / cols) - (cols - 1) / 2) * 4);
		robot.traverse(o => { if (o.isMesh) o.frustumCulled = false; });
		scene.add(robot);
		const mixer = new THREE.AnimationMixer(robot);
		mixer.clipAction(clip).play();
		mixers.push(mixer);
	}
	let frame = 0, last = 0, upds = 0, done = false;
	const deltas = [];
	function tick() {
		if (done) return;
		const now = performance.now();
		if (frame >= 120) deltas.push(now - last);
		last = now;
		const t0 = performance.now();
		for (let i = 0; i < count; i++) mixers[i].setTime(((frame + 1 + i * 5) % frameCount) / 60);
		const u = performance.now() - t0;
		renderer.render(scene, camera);
		if (frame >= 120) upds += u;
		frame++;
		if (frame >= 720) {
			const sorted = deltas.slice().sort((a, b) => a - b);
			const sum = deltas.reduce((s, d) => s + d, 0);
			console.log(JSON.stringify({contender: 'three', target: 'page', count, verts, bones, mean_ms: sum / 600, p95_ms: sorted[570], upd_ms: upds / 600}));
			done = true;
			return;
		}
		requestAnimationFrame(tick);
	}
	requestAnimationFrame(tick);
}, undefined, e => console.log(JSON.stringify({contender: 'three', target: 'page', count, error: String(e && e.message || e)})));
