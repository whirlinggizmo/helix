package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.graphics.BlendMode;
import helix.graphics.IGraphics;
import helix.graphics.Sampling;
import helix.render2d.Texture2D;
import helix.render3d.Light.LightKind;
import helix.render3d.Node.NodeKind;

/** A retained 3D scene: nodes under a root, drawn by draw(camera) inside a frame. A draw walks the tree as it is now (each world matrix
	worked out only where something changed), gathers the first four lights it finds, places each model's box and culls it against the
	camera's view, sorts the opaque models so alike ones (same mesh and material) are together and the see-through ones back to front after
	them, writes each model's instance record (its matrix's rows, its normals' matrix's rows, its tint), and draws each run of alike models as
	one instanced draw. Lit by its lights and its ambient light, glTF metallic-roughness (Material).

	Shadows: lights that cast them (Light.setShadowCasting, up to the four the stage lights by) each draw the models that cast into a layer of
	a shadow map, in drawShadows, which comes before the frame's screen pass (beginFrame) as any pass into a texture does; draw then reads the
	maps the last drawShadows made. A directional light's map is a square over what the camera sees out to its shadow distance, its texels
	the same size and in the same places in the world as the camera moves and turns, so its shadows' edges hold still; a spot's covers its
	cone.

	Environment: an environment map (Environments.load) lights its lit models as well (setEnvironment), diffuse light from all around and
	reflections sharp to blurred by roughness, and can stand behind everything (setBackground). Its lit color, which can run past 1, comes
	into what a screen shows by its exposure and tone mapping (setExposure, setTonemap: Khronos PBR Neutral at 0 EV to start); its sprites,
	text and particles are display colors, untouched. */
class Stage3D {
	// Lights: the first 64 a walk finds are considered; the 16 that reach the drawn models most are the table the shaders read, and each model
	// is lit by the 8 of those that reach it most (libwgt's, wgrender-c's); the first 4 that cast have shadows.
	static inline var GATHERED_LIGHTS = 64;
	static inline var TABLE_LIGHTS = 16;
	static inline var MODEL_LIGHTS = 8;
	static inline var SHADOW_LIGHTS = 4;
	// The fragment block's layout (lit3d_shared.glsl's lit3d_fs_members): the table's four arrays, then the shadows', tone mapping and the
	// environment.
	static inline var LIGHT_POSITION = 80;
	static inline var LIGHT_DIRECTION = LIGHT_POSITION + TABLE_LIGHTS * 16;
	static inline var LIGHT_RADIANCE = LIGHT_DIRECTION + TABLE_LIGHTS * 16;
	static inline var LIGHT_SPOT = LIGHT_RADIANCE + TABLE_LIGHTS * 16;
	static inline var SHADOW_MATRIX = LIGHT_SPOT + TABLE_LIGHTS * 16;
	static inline var SHADOW_PARAMS = SHADOW_MATRIX + SHADOW_LIGHTS * 64;
	static inline var SHADOW_TINT = SHADOW_PARAMS + 2 * SHADOW_LIGHTS * 16;
	static inline var TONEMAP = SHADOW_TINT + SHADOW_LIGHTS * 16;
	static inline var ENVIRONMENT = TONEMAP + 16;
	static inline var IRRADIANCE = ENVIRONMENT + 16;
	// How far a directional light's map starts behind what the camera sees: casters out of view still cast into it.
	static inline var SHADOW_PULLBACK = 50.;
	// Per shadow layer, what the shaders read: its matrix (16), a texel in uv, a texel in world units, bias constant and slope, strength, near,
	// far, perspective (1 or 0), tint rgb (linear), bias texels to depth units.
	static inline var LAYER_FLOATS = 30;

	var gpu:IGraphics;
	var root = Node.group();
	var ambientColor = 0xffffffff;
	var ambientIntensity = 0.;
	var pipelines:helix.graphics.Pipelines;
	var white:Texture2D;
	var flat:Texture2D;
	var capacity = 1024;
	var instanceBuffer:Int;
	var records:Bytes;
	var vertexUniforms = Bytes.alloc(64);
	var fragmentUniforms = Bytes.alloc(Lit3DLayout.fragmentUniformBytes);
	var items:Array<Item> = [];
	var drawn:Array<Item> = [];
	var count = 0;
	var lights:Array<Node> = [];
	var planes = new Vector<Float>(24);
	var inverse = new Mat4();
	var eyeX = 0.;
	var eyeY = 0.;
	var eyeZ = 0.;
	var forwardX = 0.;
	var forwardY = 0.;
	var forwardZ = -1.;
	var draws = 0;
	var stack:Array<Node> = [];
	var sprites:Sprites3D;
	var time = 0.;
	// The clock at the last draw: emitters advance by the difference.
	var drawnTime = Math.NaN;
	var stackChanged:Array<Bool> = [];
	// Shadows: the walk gathering casters rather than drawing; the casters (every model that casts, in view or not) and those of one layer.
	var gathering = false;
	var casters:Array<Caster> = [];
	var casterCount = 0;
	var layerCasters:Array<Caster> = [];
	var casterCapacity = 256;
	var casterBuffer:Int;
	var casterRecords:Bytes;
	// Skinned casters' records (Skinneddepth3DLayout's: the world matrix's rows, then the first joint), apart from the others'.
	var skinnedCasterCapacity = 16;
	var skinnedCasterBuffer:Int;
	var skinnedCasterRecords:Bytes;
	// The joints of the pass's skinned models, and the skinned models the walk met, placed once it has posed every joint.
	var palette:JointPalette;
	// Picking: the walk testing what it meets against a ray, the nearest hit so far, a skinned model's vertices posed on the CPU.
	var picking = false;
	var pickRay = new Ray();
	var pickHit:PickHit;
	var pickBest = 0.;
	var pickCamera:Null<Camera3D>;
	var pickInverse = new Mat4();
	var pickPalette:JointPalette;
	var posedVertices = new Vector<Float>(0);
	var skinned:Array<Node> = [];
	var posed = new Vector<Float>(6);
	// The shadow map (layers of the size the last drawShadows needed), and a map of one texel that stands in when there are none.
	var shadowMap = 0;
	var shadowMapSize = 0;
	var shadowMapLayers = 0;
	var noShadows:Int;
	// The lights the last drawShadows gave a layer, in layer order, and what each layer's readers need.
	var shadowLights:Array<Node> = [];
	var shadowLayers = new Vector<Float>(SHADOW_LIGHTS * LAYER_FLOATS);
	// The table this draw's shaders read; for choosing it, each gathered light's constants, its best score, its place in the table, each
	// model's scores, and a model's best eight so far.
	var table:Array<Node> = [];
	var lightData = new Vector<Float>(GATHERED_LIGHTS * 10);
	var cones = new Vector<Float>(GATHERED_LIGHTS * 2);
	var best = new Vector<Float>(GATHERED_LIGHTS);
	var tableOf = new Vector<Int>(GATHERED_LIGHTS);
	var itemScores = new Vector<Float>(0);
	var slotScores = new Vector<Float>(8);
	var shadowDraws = 0;
	var shadowCasters = 0;
	var lightView = new Mat4();
	var lightProjection = new Mat4();
	var lightViewProjection = new Mat4();
	var lightPlanes = new Vector<Float>(24);
	var depthUniforms = Bytes.alloc(Depth3DLayout.vertexUniformBytes);
	// The environment lighting the models, and the one behind them, with their settings.
	var environment:Null<Environment>;
	var environmentIntensity = 1.;
	var environmentRotation = 0.;
	var background:Null<Environment>;
	var backgroundBlur = 0.;
	var tonemap = Tonemap.Neutral;
	var exposure = 0.;
	// A black cube that stands in when there's no environment, and the BRDF table, made with the first environment.
	var noEnvironment:Int;
	var brdf:Null<Texture2D>;
	var backgroundUniforms = [
		Bytes.alloc(Background3DLayout.vertexUniformBytes),
		Bytes.alloc(Background3DLayout.fragmentUniformBytes)
	];

	/** An empty stage drawing on gpu, unlit: no lights and no ambient light until they're added. */
	public function new(gpu:IGraphics) {
		this.gpu = gpu;
		pipelines = helix.graphics.Pipelines.of(gpu);
		var pixel = Bytes.alloc(4);
		pixel.fill(0, 4, 255);
		white = Texture2D.fromRgba(gpu, 1, 1, pixel);
		// A normal map's "straight out": the default, which the shader skips anyway when a material has none.
		var normal = Bytes.alloc(4);
		normal.set(0, 128);
		normal.set(1, 128);
		normal.set(2, 255);
		normal.set(3, 255);
		flat = Texture2D.fromRgba(gpu, 1, 1, normal, true);
		instanceBuffer = gpu.createBuffer(capacity * Lit3DLayout.instanceStride);
		records = Bytes.alloc(capacity * Lit3DLayout.instanceStride);
		sprites = new Sprites3D(gpu);
		casterBuffer = gpu.createBuffer(casterCapacity * Depth3DLayout.instanceStride);
		casterRecords = Bytes.alloc(casterCapacity * Depth3DLayout.instanceStride);
		skinnedCasterBuffer = gpu.createBuffer(skinnedCasterCapacity * Skinneddepth3DLayout.instanceStride);
		skinnedCasterRecords = Bytes.alloc(skinnedCasterCapacity * Skinneddepth3DLayout.instanceStride);
		palette = new JointPalette(gpu);
		pickPalette = new JointPalette(gpu);
		noShadows = gpu.createShadowMap(1, 1);
		var black = Bytes.alloc(6 * 4);
		for (face in 0...6)
			black.set(face * 4 + 3, 255);
		noEnvironment = gpu.createCubeTexture(1, [black], Rgba8);
	}

	/** The node everything on the stage hangs from. */
	public function getRoot():Node
		return root;

	/** Adds node to the stage, as the root's last child. */
	public function add(node:Node):Bool
		return root.add(node);

	/** Takes node from the stage's root. */
	public function remove(node:Node):Bool
		return root.remove(node);

	/** The ambient light's color, 0xRRGGBBAA (sRGB). */
	public function getAmbientColor():Int
		return ambientColor;

	/** The ambient light's intensity. */
	public function getAmbientIntensity():Float
		return ambientIntensity;

	/** The light reaching everything evenly, from no direction: color 0xRRGGBBAA (sRGB) times intensity. False for an intensity under 0. */
	public function setAmbient(color:Int, intensity:Float):Bool {
		if (!(intensity >= 0))
			return false;
		ambientColor = color;
		ambientIntensity = intensity;
		return true;
	}

	/** The environment lighting the lit models, or null. */
	public function getEnvironment():Null<Environment>
		return environment;

	/** How strongly the environment lights them, and the background shows: 1 as its file has it. */
	public function getEnvironmentIntensity():Float
		return environmentIntensity;

	/** How far the environment, and the background, turn about +y, in radians. */
	public function getEnvironmentRotation():Float
		return environmentRotation;

	/** Lights the lit models with environment (null: none) as well as the lights and the ambient light: its intensity (1 as its file has it)
		and its turn about +y (radians), which the background shares. False, changing nothing, for an intensity under 0. */
	public function setEnvironment(environment:Null<Environment>, intensity = 1., rotation = 0.):Bool {
		if (!(intensity >= 0) || !Math.isFinite(rotation))
			return false;
		this.environment = environment;
		environmentIntensity = intensity;
		environmentRotation = rotation;
		return true;
	}

	/** The environment drawn behind everything, or null. */
	public function getBackground():Null<Environment>
		return background;

	/** How blurred the background is: 0 sharp to 1 its blurriest. */
	public function getBackgroundBlur():Float
		return backgroundBlur;

	/** Draws environment (null: none) behind everything, before the models, at blur 0 (sharp, the image's own resolution) to 1 (blurred to a
		few texels), turned and as bright as setEnvironment says, tone mapped as the models are. False, changing nothing, for a blur outside
		0..1. */
	public function setBackground(environment:Null<Environment>, blur = 0.):Bool {
		if (!(blur >= 0 && blur <= 1))
			return false;
		background = environment;
		backgroundBlur = blur;
		return true;
	}

	/** How lit color comes into the screen's 0..1 after the exposure. */
	public function getTonemap():Tonemap
		return tonemap;

	/** Sets how lit color comes into the screen's 0..1 after the exposure. */
	public function setTonemap(value:Tonemap):Void
		tonemap = value;

	/** The exposure in stops (EV): each one doubles the light before the tone mapping; 0 to start. */
	public function getExposure():Float
		return exposure;

	/** Sets the exposure in stops. False for one that isn't finite. */
	public function setExposure(value:Float):Bool {
		if (!Math.isFinite(value))
			return false;
		exposure = value;
		return true;
	}

	/** The seconds surface shaders see (helix_time): what the app last set. */
	public function getTime():Float
		return time;

	/** Sets the seconds surface shaders see, for whatever moves with time in them; emitters advance by how far it moved since the last draw. */
	public function setTime(seconds:Float):Void
		time = seconds;

	/** Whether draws leave out what's out of view (models, sprites and text, and shadow casters out of a light's): on to start. */
	public function isCulling():Bool
		return culling;

	/** Culls, or draws everything (to measure what culling saves). */
	public function setCulling(value:Bool):Void
		culling = value;

	var culling = true;

	// m's view's planes into out; with culling off, planes everything is inside.
	function viewPlanes(m:Mat4, out:Vector<Float>):Void {
		if (culling) {
			planesOf(m, out);
			return;
		}
		for (p in 0...6) {
			out[p * 4] = out[p * 4 + 1] = out[p * 4 + 2] = 0;
			out[p * 4 + 3] = 1;
		}
	}

	/** Models and sprites drawn by the last draw (in view). */
	public function getDrawnNodeCount():Int
		return count + sprites.getDrawnSpriteCount();

	/** Draws of the last draw: one a run of alike models, or of sprites of one texture. */
	public function getDrawCallCount():Int
		return draws + sprites.getDrawCallCount();

	/** Draws into shadow maps by the last drawShadows: one a run of casters alike in mesh, in each light's layer. */
	public function getShadowDrawCallCount():Int
		return shadowDraws;

	/** Casters drawn into shadow maps by the last drawShadows, counted in each light's layer they reach. */
	public function getShadowCasterCount():Int
		return shadowCasters;

	static inline function linear(channel:Int):Float {
		var c = channel / 255;
		return c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}

	/** Draws the shadows of its casting lights (Light.setShadowCasting; the first four lights found) for what camera sees: each light's casters
		into its layer of the shadow map, a pass each. Outside any pass, before the frame's screen pass (beginFrame), each frame shadows move;
		draws after use them. With no casting light or no caster, there are no shadows. */
	public function drawShadows(camera:Camera3D):Void {
		shadowDraws = 0;
		shadowCasters = 0;
		shadowLights.resize(0);
		var viewProjection = camera.getViewProjection();
		eyeX = camera.getEyeX();
		eyeY = camera.getEyeY();
		eyeZ = camera.getEyeZ();
		lights.resize(0);
		casterCount = 0;
		gathering = true;
		walk();
		gathering = false;
		palette.clear();
		for (i in 0...casterCount)
			if (casters[i].skinned)
				casters[i].jointBase = palette.add(casters[i].node);
		palette.upload();
		var size = 0;
		for (node in lights)
			if (node.getLight().isShadowCasting() && shadowLights.length < SHADOW_LIGHTS) {
				shadowLights.push(node);
				size = Std.int(Math.max(size, node.getLight().getShadowMapSize()));
			}
		if (shadowLights.length == 0 || casterCount == 0) {
			shadowLights.resize(0);
			return;
		}
		if (shadowMap == 0 || shadowMapSize != size || shadowMapLayers != shadowLights.length) {
			if (shadowMap != 0)
				gpu.destroyTexture(shadowMap);
			shadowMap = gpu.createShadowMap(size, shadowLights.length);
			shadowMapSize = size;
			shadowMapLayers = shadowLights.length;
		}
		for (layer in 0...shadowLights.length) {
			var light = shadowLights[layer].getLight(),
				at = layer * LAYER_FLOATS;
			var fit = light.getKind() == Spot ? fitSpot(shadowLights[layer], size) : fitDirectional(shadowLights[layer], camera, size);
			for (i in 0...16)
				shadowLayers[at + i] = lightViewProjection.get(i);
			shadowLayers[at + 16] = 1 / size;
			shadowLayers[at + 17] = fit.texelWorld;
			shadowLayers[at + 18] = light.getShadowBiasConstant();
			shadowLayers[at + 19] = light.getShadowBiasSlope();
			shadowLayers[at + 20] = light.getShadowStrength();
			shadowLayers[at + 21] = fit.near;
			shadowLayers[at + 22] = fit.far;
			shadowLayers[at + 23] = fit.perspective ? 1 : 0;
			var tint = light.getShadowColor();
			shadowLayers[at + 24] = linear(tint >>> 24);
			shadowLayers[at + 25] = linear((tint >>> 16) & 255);
			shadowLayers[at + 26] = linear((tint >>> 8) & 255);
			// The bias is in texels, what acne is made of; an orthographic map's depth units are its range.
			shadowLayers[at + 27] = fit.far > fit.near ? fit.texelWorld / (fit.far - fit.near) : 0;
			drawLayer(layer);
		}
	}

	// Fits a directional light's map to what camera sees out to its shadow distance, into lightViewProjection: a square around the view's slice
	// from the near plane, as wide as the slice's bounding sphere (so its texels keep their size as the camera turns), its corner snapped to
	// whole texels of a light space fixed to the world (so its shadows don't crawl as the camera moves), from SHADOW_PULLBACK behind the slice.
	function fitDirectional(node:Node, camera:Camera3D, size:Int):{
		texelWorld:Float,
		near:Float,
		far:Float,
		perspective:Bool
	} {
		var w = node.getWorldMatrix(),
			distance = node.getLight().getShadowDistance();
		var dx = -w.get(8),
			dy = -w.get(9),
			dz = -w.get(10),
			dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (dl > 0) {
			dx /= dl;
			dy /= dl;
			dz /= dl;
		} else {
			dx = dz = 0;
			dy = -1;
		}
		// The camera's frame: forward, right and up.
		var fx = camera.getTargetX() - eyeX,
			fy = camera.getTargetY() - eyeY,
			fz = camera.getTargetZ() - eyeZ;
		var fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
		fx /= fl;
		fy /= fl;
		fz /= fl;
		var ux = camera.getUpX(), uy = camera.getUpY(), uz = camera.getUpZ();
		var rx = fy * uz - fz * uy,
			ry = fz * ux - fx * uz,
			rz = fx * uy - fy * ux;
		var rl = Math.sqrt(rx * rx + ry * ry + rz * rz);
		rx /= rl;
		ry /= rl;
		rz /= rl;
		ux = ry * fz - rz * fy;
		uy = rz * fx - rx * fz;
		uz = rx * fy - ry * fx;
		var aspect = camera.getViewportWidth() / camera.getViewportHeight(),
			orthographic = camera.isOrthographic();
		var corners = new Vector<Float>(24), cx = 0., cy = 0., cz = 0.;
		for (p in 0...2) {
			var z = p == 0 ? (orthographic ? 0 : camera.getNear()) : distance;
			var halfHeight = orthographic ? camera.getOrthographicHeight() / 2 : Math.tan(camera.getFovY() / 2) * z,
				halfWidth = halfHeight * aspect;
			for (c in 0...4) {
				var x = c & 1 != 0 ? halfWidth : -halfWidth,
					y = c & 2 != 0 ? halfHeight : -halfHeight,
					at = (p * 4 + c) * 3;
				corners[at] = eyeX + fx * z + rx * x + ux * y;
				corners[at + 1] = eyeY + fy * z + ry * x + uy * y;
				corners[at + 2] = eyeZ + fz * z + rz * x + uz * y;
				cx += corners[at] / 8;
				cy += corners[at + 1] / 8;
				cz += corners[at + 2] / 8;
			}
		}
		// The slice's bounding sphere, its radius rounded up to a sixteenth so rounding error doesn't change it frame to frame.
		var radius = 0.;
		for (i in 0...8) {
			var ex = corners[i * 3] - cx,
				ey = corners[i * 3 + 1] - cy,
				ez = corners[i * 3 + 2] - cz;
			radius = Math.max(radius, Math.sqrt(ex * ex + ey * ey + ez * ez));
		}
		radius = Math.ceil(radius * 16) / 16;
		// Light space: from the world's origin along the light, so a texel is the same place in the world whichever way the camera moves.
		var flat = Math.abs(dy) > .99;
		lightView.makeLookAt(0, 0, 0, dx, dy, dz, 0, flat ? 0 : 1, flat ? 1 : 0);
		var vx = lightView.get(0) * cx + lightView.get(4) * cy + lightView.get(8) * cz;
		var vy = lightView.get(1) * cx + lightView.get(5) * cy + lightView.get(9) * cz;
		// The view looks down -z: depth grows that way.
		var depth = -(lightView.get(2) * cx + lightView.get(6) * cy + lightView.get(10) * cz);
		var side = radius * 2, texel = side / size;
		var left = Math.floor((vx - radius) / texel) * texel,
			bottom = Math.floor((vy - radius) / texel) * texel;
		var near = depth - radius - SHADOW_PULLBACK, far = depth + radius;
		lightProjection.makeOrthographicBox(left, left + side, bottom, bottom + side, near, far);
		lightViewProjection.makeProduct(lightProjection, lightView);
		return {
			texelWorld: texel,
			near: near,
			far: far,
			perspective: false
		};
	}

	// Fits a spot's map to its cone into lightViewProjection: a perspective from its position down its axis, a little wider than the cone, out to
	// its range (or its shadow distance, the nearer).
	function fitSpot(node:Node, size:Int):{
		texelWorld:Float,
		near:Float,
		far:Float,
		perspective:Bool
	} {
		var light = node.getLight(), w = node.getWorldMatrix();
		var dx = -w.get(8),
			dy = -w.get(9),
			dz = -w.get(10),
			dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (dl > 0) {
			dx /= dl;
			dy /= dl;
			dz /= dl;
		} else {
			dx = dz = 0;
			dy = -1;
		}
		var reach = light.getRange() > 0 ? Math.min(light.getRange(), light.getShadowDistance()) : light.getShadowDistance();
		var cosOuter = Math.cos(light.getOuterCone());
		var fovY = 2 * Math.acos(cosOuter < -.99 ? -.99 : cosOuter > 1 ? 1 : cosOuter) * 1.1;
		fovY = fovY > 2.8 ? 2.8 : fovY < .02 ? .02 : fovY;
		var px = w.get(12),
			py = w.get(13),
			pz = w.get(14),
			flat = Math.abs(dy) > .99;
		lightView.makeLookAt(px, py, pz, px + dx, py + dy, pz + dz, 0, flat ? 0 : 1, flat ? 1 : 0);
		lightProjection.makePerspective(fovY, 1, reach * .01, reach);
		lightViewProjection.makeProduct(lightProjection, lightView);
		return {
			texelWorld: 2 * Math.tan(fovY / 2) * reach / size,
			near: reach * .01,
			far: reach,
			perspective: true
		};
	}

	// Draws layer's casters into it, through lightViewProjection: those its view reaches, alike meshes one draw.
	function drawLayer(layer:Int):Void {
		viewPlanes(lightViewProjection, lightPlanes);
		layerCasters.resize(0);
		for (i in 0...casterCount) {
			var c = casters[i];
			if (inside(lightPlanes, c.cx, c.cy, c.cz, c.rx, c.ry, c.rz))
				layerCasters.push(c);
		}
		gpu.beginShadowPass(shadowMap, layer);
		// Skinned casters after the others, each kind's alike meshes together.
		layerCasters.sort((a, b) -> a.skinned != b.skinned ? (a.skinned ? 1 : -1) : a.mesh.id - b.mesh.id);
		var n = 0;
		while (n < layerCasters.length && !layerCasters[n].skinned)
			n++;
		drawSkinnedCasters(n);
		layerCasters.resize(n);
		if (n > 0) {
			if (n > casterCapacity) {
				while (casterCapacity < n)
					casterCapacity *= 2;
				gpu.destroyBuffer(casterBuffer);
				gpu.destroyBuffer(skinnedCasterBuffer);
				palette.destroy();
				casterBuffer = gpu.createBuffer(casterCapacity * Depth3DLayout.instanceStride);
				casterRecords = Bytes.alloc(casterCapacity * Depth3DLayout.instanceStride);
			}
			for (i in 0...n) {
				var w = layerCasters[i].node.getWorldMatrix(),
					at = i * Depth3DLayout.instanceStride;
				for (row in 0...3)
					for (col in 0...4)
						casterRecords.setFloat(at + Depth3DLayout.model0Offset + row * 16 + col * 4, w.get(col * 4 + row));
			}
			gpu.updateBuffer(casterBuffer, casterRecords, n * Depth3DLayout.instanceStride);
			lightViewProjection.writeTo(depthUniforms);
			var uniforms = [depthUniforms], i = 0;
			while (i < n) {
				var last = i, mesh = layerCasters[i].mesh;
				while (last + 1 < n && layerCasters[last + 1].mesh == mesh)
					last++;
				gpu.draw(pipelines.depth3D(), [mesh.getVertexBuffer(gpu), casterBuffer], mesh.getIndexBuffer(gpu), 0, mesh.getIndexCount(), i, last - i + 1,
					[], [], uniforms);
				shadowDraws++;
				i = last + 1;
			}
			shadowCasters += n;
		}
		gpu.endTargetPass();
	}

	// Draws the layer's skinned casters, those from first on in layerCasters, through the skinned depth program.
	function drawSkinnedCasters(first:Int):Void {
		var n = layerCasters.length - first;
		if (n <= 0)
			return;
		if (n > skinnedCasterCapacity) {
			while (skinnedCasterCapacity < n)
				skinnedCasterCapacity *= 2;
			gpu.destroyBuffer(skinnedCasterBuffer);
			skinnedCasterBuffer = gpu.createBuffer(skinnedCasterCapacity * Skinneddepth3DLayout.instanceStride);
			skinnedCasterRecords = Bytes.alloc(skinnedCasterCapacity * Skinneddepth3DLayout.instanceStride);
		}
		for (i in 0...n) {
			var c = layerCasters[first + i],
				w = c.node.getWorldMatrix(),
				at = i * Skinneddepth3DLayout.instanceStride;
			for (row in 0...3)
				for (col in 0...4)
					skinnedCasterRecords.setFloat(at + Skinneddepth3DLayout.model0Offset + row * 16 + col * 4, w.get(col * 4 + row));
			skinnedCasterRecords.setFloat(at + Skinneddepth3DLayout.skinOffset, c.jointBase);
		}
		gpu.updateBuffer(skinnedCasterBuffer, skinnedCasterRecords, n * Skinneddepth3DLayout.instanceStride);
		lightViewProjection.writeTo(depthUniforms);
		var uniforms = [depthUniforms], i = 0;
		while (i < n) {
			var last = i, mesh = layerCasters[first + i].mesh;
			while (last + 1 < n && layerCasters[first + last + 1].mesh == mesh)
				last++;
			gpu.draw(pipelines.skinnedDepth3D(), [mesh.getVertexBuffer(gpu), skinnedCasterBuffer, mesh.getSkinBuffer(gpu)], mesh.getIndexBuffer(gpu), 0,
				mesh.getIndexCount(), i, last - i + 1, [palette.getTexture()], [Sampling.NEAREST], uniforms);
			shadowDraws++;
			i = last + 1;
		}
		shadowCasters += n;
	}

	/** What's under framebuffer pixel x, y (from the top-left, as the pointer is) seen through camera: the nearest model, sprite or text it shows there, into
		hit (a new one when not given), or null for nothing (or a point outside camera's viewport). Drawing doesn't matter, the flags do: a
		disabled node and all under it are passed over, an unpickable one lets the ray through to what's behind (its children still hit), a
		hidden one is hit. Models are hit by their triangles (a skinned one's as posed now), from either side; a see-through one (its material
		blended or its tint) only where its alpha reaches a half. Sprites and text are hit by their quads as drawn (a text by its whole block), not yet by their texels. World matrices are brought up to date, as a draw does. */
	public function pick(camera:Camera3D, x:Float, y:Float, ?hit:PickHit):Null<PickHit>
		return camera.computeRay(x, y, pickRay) ? pickAlong(pickRay, camera, hit) : null;

	/** The nearest model, sprite or text along ray, as pick says, into hit (a new one when not given); null for none. Sprites and text face as
		camera shows them: without a camera, only models are hit. */
	public function pickAlong(ray:Ray, ?camera:Camera3D, ?hit:PickHit):Null<PickHit> {
		pickCamera = camera;
		var result = hit != null ? hit : new PickHit();
		result.clear();
		if (ray != pickRay)
			pickRay.set(ray.getOriginX(), ray.getOriginY(), ray.getOriginZ(), ray.getDirectionX(), ray.getDirectionY(), ray.getDirectionZ());
		pickHit = result;
		pickBest = Math.POSITIVE_INFINITY;
		picking = true;
		walk();
		picking = false;
		return result.getNode() == null ? null : result;
	}

	// Where the ray enters the box boxX..boxRZ (0 when it starts inside), or infinity when it misses.
	function rayBox():Float {
		var lo = 0., hi = Math.POSITIVE_INFINITY;
		for (axis in 0...3) {
			var o = axis == 0 ? pickRay.getOriginX() : axis == 1 ? pickRay.getOriginY() : pickRay.getOriginZ(),
				d = axis == 0 ? pickRay.getDirectionX() : axis == 1 ? pickRay.getDirectionY() : pickRay.getDirectionZ(),
				c = axis == 0 ? boxX : axis == 1 ? boxY : boxZ,
				reach = axis == 0 ? boxRX : axis == 1 ? boxRY : boxRZ;
			if (Math.abs(d) < 1e-12) {
				if (o < c - reach || o > c + reach)
					return Math.POSITIVE_INFINITY;
				continue;
			}
			var a = (c - reach - o) / d, b = (c + reach - o) / d;
			if (a > b) {
				var t = a;
				a = b;
				b = t;
			}
			lo = Math.max(lo, a);
			hi = Math.min(hi, b);
			if (lo > hi)
				return Math.POSITIVE_INFINITY;
		}
		return lo;
	}

	// Tests a model's triangles against the ray, in its own space, keeping the nearest hit: after its box, which must be nearer than the best.
	function pickModel(node:Node):Void {
		var material = node.getMaterial(),
			alpha = (node.getTint() & 255) / 255;
		if ((material.isBlended() || alpha < 1) && alpha * (material.getBaseColor() & 255) / 255 < .5)
			return;
		placeBox(node);
		if (rayBox() >= pickBest)
			return;
		var mesh = node.getMesh(),
			w = node.getWorldMatrix(),
			inv = pickInverse;
		if (!inv.makeInverse(w))
			return;
		var ox = pickRay.getOriginX(),
			oy = pickRay.getOriginY(),
			oz = pickRay.getOriginZ();
		var dx = pickRay.getDirectionX(),
			dy = pickRay.getDirectionY(),
			dz = pickRay.getDirectionZ();
		// The ray in the model's space: the same t reaches the same point, so distances stay the world's.
		var lox = inv.get(0) * ox + inv.get(4) * oy + inv.get(8) * oz + inv.get(12),
			loy = inv.get(1) * ox + inv.get(5) * oy + inv.get(9) * oz + inv.get(13),
			loz = inv.get(2) * ox + inv.get(6) * oy + inv.get(10) * oz + inv.get(14);
		var ldx = inv.get(0) * dx + inv.get(4) * dy + inv.get(8) * dz,
			ldy = inv.get(1) * dx + inv.get(5) * dy + inv.get(9) * dz,
			ldz = inv.get(2) * dx + inv.get(6) * dy + inv.get(10) * dz;
		var count = mesh.getVertexCount(),
			vertices = mesh.getVertices(),
			indices = mesh.getIndices();
		var positions = posedVertices;
		if (positions.length < count * 3)
			positions = posedVertices = new Vector<Float>(count * 3);
		if (isSkinned(node))
			pose(node, mesh, positions);
		else
			for (i in 0...count)
				for (c in 0...3)
					positions[i * 3 + c] = vertices.getFloat(i * Lit3DLayout.stride + Lit3DLayout.positionOffset + c * 4);
		var found = false, hitT = 0., hnx = 0., hny = 0., hnz = 0.;
		var i = 0, n = mesh.getIndexCount();
		while (i < n) {
			var a = indices.getInt32(i * 4) * 3,
				b = indices.getInt32(i * 4 + 4) * 3,
				c = indices.getInt32(i * 4 + 8) * 3;
			i += 3;
			// Möller–Trumbore, either face.
			var e1x = positions[b] - positions[a],
				e1y = positions[b + 1] - positions[a + 1],
				e1z = positions[b + 2] - positions[a + 2];
			var e2x = positions[c] - positions[a],
				e2y = positions[c + 1] - positions[a + 1],
				e2z = positions[c + 2] - positions[a + 2];
			var px = ldy * e2z - ldz * e2y,
				py = ldz * e2x - ldx * e2z,
				pz = ldx * e2y - ldy * e2x;
			var det = e1x * px + e1y * py + e1z * pz;
			if (Math.abs(det) < 1e-12)
				continue;
			var sx = lox - positions[a],
				sy = loy - positions[a + 1],
				sz = loz - positions[a + 2];
			var u = (sx * px + sy * py + sz * pz) / det;
			if (u < 0 || u > 1)
				continue;
			var qx = sy * e1z - sz * e1y,
				qy = sz * e1x - sx * e1z,
				qz = sx * e1y - sy * e1x;
			var v = (ldx * qx + ldy * qy + ldz * qz) / det;
			if (v < 0 || u + v > 1)
				continue;
			var t = (e2x * qx + e2y * qy + e2z * qz) / det;
			if (t < 0 || t >= pickBest || (found && t >= hitT))
				continue;
			found = true;
			hitT = t;
			hnx = e1y * e2z - e1z * e2y;
			hny = e1z * e2x - e1x * e2z;
			hnz = e1x * e2y - e1y * e2x;
		}
		if (!found)
			return;
		// The normal into the world by the inverse's transpose, made a unit vector, turned to face back along the ray.
		var nx = inv.get(0) * hnx + inv.get(1) * hny + inv.get(2) * hnz,
			ny = inv.get(4) * hnx + inv.get(5) * hny + inv.get(6) * hnz,
			nz = inv.get(8) * hnx + inv.get(9) * hny + inv.get(10) * hnz;
		var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (length > 0) {
			nx /= length;
			ny /= length;
			nz /= length;
		}
		if (nx * dx + ny * dy + nz * dz > 0) {
			nx = -nx;
			ny = -ny;
			nz = -nz;
		}
		pickBest = hitT;
		pickHit.record(node, hitT, ox + dx * hitT, oy + dy * hitT, oz + dz * hitT, lox + ldx * hitT, loy + ldy * hitT, loz + ldz * hitT, nx, ny, nz);
	}

	// A skinned model's vertices as posed now, in its own space, into out: each moved by its joints' matrices as the GPU blends them.
	function pose(node:Node, mesh:Mesh, out:Vector<Float>):Void {
		pickPalette.clear();
		var base = pickPalette.add(node),
			vertices = mesh.getVertices(),
			skin = mesh.getSkinData();
		for (i in 0...mesh.getVertexCount()) {
			var at = i * Lit3DLayout.stride + Lit3DLayout.positionOffset,
				s = i * Skinned3DLayout.skinStride;
			var x = vertices.getFloat(at),
				y = vertices.getFloat(at + 4),
				z = vertices.getFloat(at + 8);
			var px = 0., py = 0., pz = 0.;
			for (k in 0...4) {
				var weight = skin.getFloat(s + Skinned3DLayout.weightsOffset + k * 4);
				if (weight <= 0)
					continue;
				var j = base + Std.int(skin.getFloat(s + Skinned3DLayout.jointsOffset + k * 4) + .5);
				px += weight * (pickPalette.getMatrix(j, 0, 0) * x + pickPalette.getMatrix(j, 0, 1) * y + pickPalette.getMatrix(j, 0, 2) * z
					+ pickPalette.getMatrix(j, 0, 3));
				py += weight * (pickPalette.getMatrix(j, 1, 0) * x + pickPalette.getMatrix(j, 1, 1) * y + pickPalette.getMatrix(j, 1, 2) * z
					+ pickPalette.getMatrix(j, 1, 3));
				pz += weight * (pickPalette.getMatrix(j, 2, 0) * x + pickPalette.getMatrix(j, 2, 1) * y + pickPalette.getMatrix(j, 2, 2) * z
					+ pickPalette.getMatrix(j, 2, 3));
			}
			out[i * 3] = px;
			out[i * 3 + 1] = py;
			out[i * 3 + 2] = pz;
		}
	}

	/** Draws the stage in the open frame, through camera, in its viewport. */
	public function draw(camera:Camera3D):Void {
		var viewProjection = camera.getViewProjection();
		viewPlanes(viewProjection, planes);
		eyeX = camera.getEyeX();
		eyeY = camera.getEyeY();
		eyeZ = camera.getEyeZ();
		var fx = camera.getTargetX() - eyeX,
			fy = camera.getTargetY() - eyeY,
			fz = camera.getTargetZ() - eyeZ;
		var fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
		forwardX = fx / fl;
		forwardY = fy / fl;
		forwardZ = fz / fl;
		count = 0;
		draws = 0;
		lights.resize(0);
		sprites.begin(Math.isNaN(drawnTime) ? 0 : Math.max(0, time - drawnTime));
		drawnTime = time;
		walk();
		drawn.resize(count);
		for (i in 0...count)
			drawn[i] = items[i];
		drawn.sort(compare);
		if (count > capacity) {
			while (capacity < count)
				capacity *= 2;
			gpu.destroyBuffer(instanceBuffer);
			instanceBuffer = gpu.createBuffer(capacity * Lit3DLayout.instanceStride);
			records = Bytes.alloc(capacity * Lit3DLayout.instanceStride);
		}
		palette.clear();
		for (i in 0...count)
			if (drawn[i].skinned)
				drawn[i].jointBase = palette.add(drawn[i].node);
		palette.upload();
		chooseLights();
		for (i in 0...count)
			writeRecord(i, drawn[i]);
		gpu.updateBuffer(instanceBuffer, records, count * Lit3DLayout.instanceStride);
		gpu.applyViewport(camera.getViewportX(), camera.getFramebufferHeight() - camera.getViewportY() - camera.getViewportHeight(),
			camera.getViewportWidth(), camera.getViewportHeight());
		viewProjection.writeTo(vertexUniforms);
		writeScene();
		if (background != null)
			drawBackground(viewProjection);
		sprites.prepare(viewProjection, camera, forwardX, forwardY, forwardZ);
		// The opaque models, the opaque and masked sprites, the see-through models with the blended sprites between them back to front, then the
		// blended sprites nearer than any of those and the added ones.
		var i = 0, opaqueSprites = false;
		while (i < count) {
			var last = i;
			while (last + 1 < count && alike(drawn[i], drawn[last + 1]))
				last++;
			if (drawn[i].blended) {
				if (!opaqueSprites) {
					sprites.drawOpaque();
					opaqueSprites = true;
				}
				sprites.drawBlendedBeyond(drawn[i].depth);
			}
			drawRun(i, last - i + 1);
			i = last + 1;
		}
		if (!opaqueSprites)
			sprites.drawOpaque();
		sprites.drawRest();
	}

	// The background, behind everything: the environment's background cube in each pixel's direction, through the inverse view-projection.
	function drawBackground(viewProjection:Mat4):Void {
		inverse.makeInverse(viewProjection);
		var u = backgroundUniforms[1];
		for (i in 0...16)
			u.setFloat(i * 4, inverse.get(i));
		u.setFloat(64, environmentIntensity);
		u.setFloat(68, backgroundBlur * (background.getBackgroundMipCount() - 1));
		u.setFloat(72, Math.cos(environmentRotation));
		u.setFloat(76, Math.sin(environmentRotation));
		u.setFloat(80, tonemap);
		u.setFloat(84, Math.pow(2, exposure));
		gpu.draw(pipelines.background3D(), [], 0, 0, 3, 0, 1, [background.getBackgroundTexture()], [Sampling.LINEAR], backgroundUniforms);
	}

	// The tree depth first, each node's world matrix brought up to date on the way down; disabled nodes skip their children.
	function walk():Void {
		stack.resize(0);
		stackChanged.resize(0);
		// The root's own transform places everything on the stage.
		var rootChanged = root.update(null, false);
		for (i in 0...root.getChildCount()) {
			stack.push(root.getChild(root.getChildCount() - 1 - i));
			stackChanged.push(rootChanged);
		}
		while (stack.length > 0) {
			var node = stack.pop(), parentChanged = stackChanged.pop();
			if (!node.isEnabled())
				continue;
			var parent = node.getParent();
			var changed = node.update(parent.getWorldMatrix(), parentChanged);
			// Hidden, its own output is skipped (an emitter still moves on); it stays placed, and its children are walked.
			var shown = node.isVisible();
			switch (node.getKind()) {
				case Model if (picking && node.isPickable() && isSkinned(node)):
					skinned.push(node);
				case Model if (picking && node.isPickable()):
					pickModel(node);
				case SpriteNode | TextNode if (picking && node.isPickable() && pickCamera != null):
					pickBest = sprites.pick(node, pickCamera, pickRay, pickBest, pickHit);
				case _ if (picking):
				case EmitterNode if (!gathering && !shown):
					sprites.advanceEmitter(node);
				case _ if (!shown):
				case Model if (isSkinned(node)):
					skinned.push(node);
				case Model if (gathering):
					gatherCaster(node);
				case Model:
					visitModel(node);
				case LightNode:
					if (lights.length < GATHERED_LIGHTS)
						lights.push(node);
				case _ if (gathering):
				case SpriteNode:
					sprites.visit(node, planes, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);
				case TextNode:
					sprites.visitText(node, planes, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);
				case EmitterNode:
					sprites.visitEmitter(node, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);
				case Group | CameraNode:
			}
			for (i in 0...node.getChildCount()) {
				stack.push(node.getChild(node.getChildCount() - 1 - i));
				stackChanged.push(changed);
			}
		}
		// Skinned models once every joint is where this frame has it: their boxes are their joints'.
		for (node in skinned)
			if (picking)
				pickModel(node);
			else if (gathering)
				gatherCaster(node);
			else
				visitModel(node);
		skinned.resize(0);
	}

	// A model whose mesh follows joints it's bound to (a skinned mesh not bound draws as bound, still).
	static inline function isSkinned(node:Node):Bool
		return node.getJointCount() > 0 && node.getMesh().isSkinned();

	// The six planes of m's view (Gribb and Hartmann), each ax + by + cz + d >= 0 inside, into out.
	static function planesOf(m:Mat4, out:Vector<Float>):Void
		for (p in 0...6) {
			var row = Std.int(p / 2), sign = p % 2 == 0 ? 1. : -1.;
			for (c in 0...4)
				out[p * 4 + c] = m.get(c * 4 + 3) + sign * m.get(c * 4 + row);
			var length = Math.sqrt(out[p * 4] * out[p * 4] + out[p * 4 + 1] * out[p * 4 + 1] + out[p * 4 + 2] * out[p * 4 + 2]);
			if (length > 0)
				for (c in 0...4)
					out[p * 4 + c] /= length;
		}

	// Whether the box centered at c reaching r along each world axis is at least partly inside planes.
	static function inside(planes:Vector<Float>, cx:Float, cy:Float, cz:Float, rx:Float, ry:Float, rz:Float):Bool {
		for (p in 0...6) {
			var a = planes[p * 4],
				b = planes[p * 4 + 1],
				c = planes[p * 4 + 2];
			if (a * (cx + (a >= 0 ? rx : -rx)) + b * (cy + (b >= 0 ? ry : -ry)) + c * (cz + (c >= 0 ? rz : -rz)) + planes[p * 4 + 3] < 0)
				return false;
		}
		return true;
	}

	// A model's box in the world, into boxX..boxRZ: its mesh's box's center moved, each world axis's reach the absolute matrix times the half
	// extents.
	var boxX = 0.;
	var boxY = 0.;
	var boxZ = 0.;
	var boxRX = 0.;
	var boxRY = 0.;
	var boxRZ = 0.;

	function placeBox(node:Node):Void {
		if (isSkinned(node) && JointPalette.computePosedBox(node, posed)) {
			boxX = posed[0];
			boxY = posed[1];
			boxZ = posed[2];
			boxRX = posed[3];
			boxRY = posed[4];
			boxRZ = posed[5];
			return;
		}
		var mesh = node.getMesh(), w = node.getWorldMatrix();
		var hx = (mesh.getMaxX() - mesh.getMinX()) / 2,
			hy = (mesh.getMaxY() - mesh.getMinY()) / 2,
			hz = (mesh.getMaxZ() - mesh.getMinZ()) / 2;
		var mx = (mesh.getMaxX() + mesh.getMinX()) / 2,
			my = (mesh.getMaxY() + mesh.getMinY()) / 2,
			mz = (mesh.getMaxZ() + mesh.getMinZ()) / 2;
		boxX = w.get(0) * mx + w.get(4) * my + w.get(8) * mz + w.get(12);
		boxY = w.get(1) * mx + w.get(5) * my + w.get(9) * mz + w.get(13);
		boxZ = w.get(2) * mx + w.get(6) * my + w.get(10) * mz + w.get(14);
		boxRX = Math.abs(w.get(0)) * hx + Math.abs(w.get(4)) * hy + Math.abs(w.get(8)) * hz;
		boxRY = Math.abs(w.get(1)) * hx + Math.abs(w.get(5)) * hy + Math.abs(w.get(9)) * hz;
		boxRZ = Math.abs(w.get(2)) * hx + Math.abs(w.get(6)) * hy + Math.abs(w.get(10)) * hz;
	}

	// A model that casts, in view or not (see-through ones don't).
	function gatherCaster(node:Node):Void {
		if (!node.isShadowCasting() || node.getMaterial().isBlended() || node.getTint() & 255 < 255)
			return;
		placeBox(node);
		if (casterCount == casters.length)
			casters.push(new Caster());
		var c = casters[casterCount++];
		c.node = node;
		c.mesh = node.getMesh();
		c.skinned = isSkinned(node);
		c.cx = boxX;
		c.cy = boxY;
		c.cz = boxZ;
		c.rx = boxRX;
		c.ry = boxRY;
		c.rz = boxRZ;
	}

	function visitModel(node:Node):Void {
		var mesh = node.getMesh(), w = node.getWorldMatrix();
		placeBox(node);
		var cx = boxX, cy = boxY, cz = boxZ;
		if (!inside(planes, cx, cy, cz, boxRX, boxRY, boxRZ))
			return;
		if (count == items.length)
			items.push(new Item());
		var item = items[count];
		item.node = node;
		item.mesh = mesh;
		item.material = node.getMaterial();
		item.skinned = isSkinned(node);
		item.blended = item.material.isBlended() || node.getTint() & 255 < 255;
		// A placement that mirrors (its matrix's determinant below 0) turns the triangles' winding over.
		item.mirrored = w.get(0) * (w.get(5) * w.get(10) - w.get(9) * w.get(6)) - w.get(4) * (w.get(1) * w.get(10) - w.get(9) * w.get(2))
			+ w.get(8) * (w.get(1) * w.get(6) - w.get(5) * w.get(2)) < 0;
		item.depth = (cx - eyeX) * forwardX + (cy - eyeY) * forwardY + (cz - eyeZ) * forwardZ;
		item.cx = cx;
		item.cy = cy;
		item.cz = cz;
		item.rx = boxRX;
		item.ry = boxRY;
		item.rz = boxRZ;
		item.order = count;
		count++;
	}

	static function compare(a:Item, b:Item):Int {
		if (a.blended != b.blended)
			return a.blended ? 1 : -1;
		if (a.blended)
			return a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : a.order - b.order;
		if (a.material.id != b.material.id)
			return a.material.id - b.material.id;
		if (a.mesh.id != b.mesh.id)
			return a.mesh.id - b.mesh.id;
		if (a.skinned != b.skinned)
			return a.skinned ? 1 : -1;
		if (a.mirrored != b.mirrored)
			return a.mirrored ? 1 : -1;
		return a.order - b.order;
	}

	static inline function alike(a:Item, b:Item):Bool
		return a.mesh == b.mesh && a.material == b.material && a.blended == b.blended && a.mirrored == b.mirrored && a.skinned == b.skinned;

	// The record: the world matrix's rows, the normals' matrix's rows (the inverse transpose's; the first's w the tangents' handedness, the
	// second's whether shadows fall on it), the tint (linear).
	function writeRecord(index:Int, item:Item):Void {
		var w = item.node.getWorldMatrix(), r = inverse, at = index * Lit3DLayout.instanceStride;
		inverse.makeInverse(w);
		for (row in 0...3)
			for (col in 0...4)
				records.setFloat(at + Lit3DLayout.model0Offset + row * 16 + col * 4, w.get(col * 4 + row));
		// The w of the normals' first row: the tangents' handedness, -1 where the placement mirrors them.
		var mirrored = r.get(0) * (r.get(5) * r.get(10) - r.get(9) * r.get(6)) - r.get(4) * (r.get(1) * r.get(10) - r.get(9) * r.get(2))
			+ r.get(8) * (r.get(1) * r.get(6) - r.get(5) * r.get(2)) < 0;
		for (row in 0...3)
			for (col in 0...4)
				records.setFloat(at + Lit3DLayout.normal0Offset + row * 16 + col * 4,
					col < 3 ? r.get(row * 4 +
						col) : row == 0 ? (mirrored ? -1 : 1) : row == 1 ? (item.node.isShadowReceiving() ? 1 : 0) : item.skinned ? item.jointBase : 0);
		for (k in 0...MODEL_LIGHTS)
			records.setFloat(at + (k < 4 ? Lit3DLayout.lights0Offset + k * 4 : Lit3DLayout.lights1Offset + (k - 4) * 4), item.lights[k]);
		var tint = item.node.getTint();
		records.setFloat(at + Lit3DLayout.tintOffset, linear(tint >>> 24));
		records.setFloat(at + Lit3DLayout.tintOffset + 4, linear((tint >>> 16) & 255));
		records.setFloat(at + Lit3DLayout.tintOffset + 8, linear((tint >>> 8) & 255));
		records.setFloat(at + Lit3DLayout.tintOffset + 12, (tint & 255) / 255);
	}

	// The table: the gathered lights that reach the drawn models most (each light's best score over them), at most TABLE_LIGHTS, in the order
	// found; then each model's own: the table's lights that reach it most, at most MODEL_LIGHTS, the nearest-reaching first. Each light's
	// constants are worked out once, each light and model scored once, and nothing is made per model (libwgt's insertion into fixed slots).
	function chooseLights():Void {
		var n = lights.length;
		prepareLights();
		if (itemScores.length < count * n)
			itemScores = new Vector<Float>(count * n * 2);
		for (l in 0...n)
			best[l] = 0;
		for (i in 0...count) {
			var item = drawn[i];
			for (l in 0...n) {
				var score = scoreLight(l, item);
				itemScores[i * n + l] = score;
				if (score > best[l])
					best[l] = score;
			}
		}
		// The table: the TABLE_LIGHTS best, kept in the order found.
		table.resize(0);
		for (l in 0...n) {
			tableOf[l] = -1;
			if (best[l] <= 0)
				continue;
			var better = 0;
			for (o in 0...n)
				if (best[o] > best[l] || best[o] == best[l] && o < l)
					better++;
			if (better < TABLE_LIGHTS) {
				tableOf[l] = table.length;
				table.push(lights[l]);
			}
		}
		for (i in 0...count) {
			var item = drawn[i], chosen = 0;
			for (l in 0...n) {
				var t = tableOf[l], score = itemScores[i * n + l];
				if (t < 0 || score <= 0)
					continue;
				// Into the descending list, ties in table order.
				var at = chosen;
				while (at > 0 && slotScores[at - 1] < score)
					at--;
				if (at >= MODEL_LIGHTS)
					continue;
				if (chosen < MODEL_LIGHTS)
					chosen++;
				var j = chosen - 1;
				while (j > at) {
					slotScores[j] = slotScores[j - 1];
					item.lights[j] = item.lights[j - 1];
					j--;
				}
				slotScores[at] = score;
				item.lights[at] = t;
			}
			for (k in chosen...MODEL_LIGHTS)
				item.lights[k] = -1;
		}
	}

	// Each gathered light's constants for scoring, once a draw: its brightness, place, range, kind, direction and cone.
	function prepareLights():Void {
		var n = lights.length;
		if (lightData.length < n * 10)
			lightData = new Vector<Float>(GATHERED_LIGHTS * 10);
		for (l in 0...n) {
			var light = lights[l].getLight(), color = light.getColor(), w = lights[l].getWorldMatrix(), at = l * 10;
			lightData[at] = (.2126 * linear(color >>> 24) + .7152 * linear((color >>> 16) & 255) + .0722 * linear((color >>> 8) & 255)) * light.getIntensity();
			lightData[at + 1] = w.get(12);
			lightData[at + 2] = w.get(13);
			lightData[at + 3] = w.get(14);
			lightData[at + 4] = light.getRange();
			lightData[at + 5] = light.getKind() == Directional ? 0 : light.getKind() == Point ? 1 : 2;
			var dx = -w.get(8),
				dy = -w.get(9),
				dz = -w.get(10),
				dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
			lightData[at + 6] = dl > 0 ? dx / dl : 0;
			lightData[at + 7] = dl > 0 ? dy / dl : -1;
			lightData[at + 8] = dl > 0 ? dz / dl : 0;
			lightData[at + 9] = 0;
			cones[l * 2] = Math.cos(light.getInnerCone());
			cones[l * 2 + 1] = Math.cos(light.getOuterCone());
		}
	}

	// How much gathered light l reaches item's box (libwgt's estimate): its brightness, through its falloff at the box's nearest point and its
	// cone at the box's center; 0 for one that can't reach it.
	function scoreLight(l:Int, item:Item):Float {
		var at = l * 10, score = lightData[at];
		if (score <= 0 || lightData[at + 5] == 0)
			return score;
		var px = lightData[at + 1],
			py = lightData[at + 2],
			pz = lightData[at + 3],
			range = lightData[at + 4];
		var nx = Math.max(item.cx - item.rx, Math.min(px, item.cx + item.rx)) - px,
			ny = Math.max(item.cy - item.ry, Math.min(py, item.cy + item.ry)) - py,
			nz = Math.max(item.cz - item.rz, Math.min(pz, item.cz + item.rz)) - pz;
		var d2 = nx * nx + ny * ny + nz * nz;
		if (range > 0 && d2 >= range * range)
			return 0;
		// The shader's falloff: inverse square (from 0.1 out), windowed to nothing at the range.
		score /= Math.max(d2, .01);
		if (range > 0) {
			var q2 = d2 / (range * range),
				window = Math.max(0, Math.min(1, 1 - q2 * q2));
			score *= window * window;
		}
		if (lightData[at + 5] == 2) {
			var tx = item.cx - px,
				ty = item.cy - py,
				tz = item.cz - pz,
				tl = Math.sqrt(tx * tx + ty * ty + tz * tz);
			// Inside a box the light's in, its cone can't miss it.
			if (tl > 1e-6 && (Math.abs(tx) > item.rx || Math.abs(ty) > item.ry || Math.abs(tz) > item.rz)) {
				var c = (tx * lightData[at + 6] + ty * lightData[at + 7] + tz * lightData[at + 8]) / tl,
					inner = cones[l * 2],
					outer = cones[l * 2 + 1];
				score *= inner - outer <= 1e-6 ? (c >= outer ? 1 : 0) : smooth(outer, inner, c);
			}
		}
		return score;
	}

	static inline function smooth(edge0:Float, edge1:Float, x:Float):Float {
		var t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
		return t * t * (3 - 2 * t);
	}

	// The fragment uniforms the whole draw shares: the camera, the ambient light, the lights and their shadows (the material is a run's).
	function writeScene():Void {
		var u = fragmentUniforms;
		u.setFloat(0, eyeX);
		u.setFloat(4, eyeY);
		u.setFloat(8, eyeZ);
		u.setFloat(12, 0);
		u.setFloat(16, linear(ambientColor >>> 24) * ambientIntensity);
		u.setFloat(20, linear((ambientColor >>> 16) & 255) * ambientIntensity);
		u.setFloat(24, linear((ambientColor >>> 8) & 255) * ambientIntensity);
		u.setFloat(28, 0);
		for (i in 0...TABLE_LIGHTS) {
			var position = LIGHT_POSITION + i * 16,
				direction = LIGHT_DIRECTION + i * 16,
				radiance = LIGHT_RADIANCE + i * 16,
				spot = LIGHT_SPOT + i * 16;
			if (i >= table.length) {
				for (k in 0...4) {
					u.setFloat(position + k * 4, 0);
					u.setFloat(direction + k * 4, 0);
					u.setFloat(radiance + k * 4, 0);
					u.setFloat(spot + k * 4, k == 2 ? -1 : 0);
				}
				continue;
			}
			var node = table[i],
				light = node.getLight(),
				w = node.getWorldMatrix();
			var dx = -w.get(8),
				dy = -w.get(9),
				dz = -w.get(10),
				dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
			u.setFloat(position, w.get(12));
			u.setFloat(position + 4, w.get(13));
			u.setFloat(position + 8, w.get(14));
			u.setFloat(position + 12, light.getRange());
			u.setFloat(direction, dl > 0 ? dx / dl : 0);
			u.setFloat(direction + 4, dl > 0 ? dy / dl : -1);
			u.setFloat(direction + 8, dl > 0 ? dz / dl : 0);
			u.setFloat(direction + 12, light.getKind() == Spot ? 2 : light.getKind() == Point ? 1 : 0);
			u.setFloat(spot, Math.cos(light.getInnerCone()));
			u.setFloat(spot + 4, Math.cos(light.getOuterCone()));
			// Its shadow slot: its layer of the map the last drawShadows made, or -1.
			u.setFloat(spot + 8, shadowLights.indexOf(node));
			u.setFloat(spot + 12, 0);
			var color = light.getColor(), intensity = light.getIntensity();
			u.setFloat(radiance, linear(color >>> 24) * intensity);
			u.setFloat(radiance + 4, linear((color >>> 16) & 255) * intensity);
			u.setFloat(radiance + 8, linear((color >>> 8) & 255) * intensity);
			u.setFloat(radiance + 12, 0);
		}
		// Each shadow layer: its matrix, then params, extra and tint (each four floats a layer).
		for (layer in 0...SHADOW_LIGHTS) {
			var at = layer * LAYER_FLOATS;
			for (k in 0...16)
				u.setFloat(SHADOW_MATRIX + layer * 64 + k * 4, layer < shadowLights.length ? shadowLayers[at + k] : 0);
			for (k in 0...12)
				u.setFloat(SHADOW_PARAMS + Std.int(k / 4) * SHADOW_LIGHTS * 16 + layer * 16 + (k % 4) * 4,
					layer < shadowLights.length ? shadowLayers[at + 16 + k] : 0);
			for (k in 0...4)
				u.setFloat(SHADOW_TINT + layer * 16 + k * 4, layer < shadowLights.length ? shadowLayers[at + 24 + k] : 0);
		}
		// Tone mapping, then the environment: its intensity (0 for none), last mip, rotation, and irradiance.
		u.setFloat(TONEMAP, tonemap);
		u.setFloat(TONEMAP + 4, Math.pow(2, exposure));
		u.setFloat(TONEMAP + 8, 0);
		u.setFloat(TONEMAP + 12, 0);
		u.setFloat(ENVIRONMENT, environment != null ? environmentIntensity : 0);
		u.setFloat(ENVIRONMENT + 4, EnvironmentBake.MIP_COUNT - 1);
		u.setFloat(ENVIRONMENT + 8, Math.cos(environmentRotation));
		u.setFloat(ENVIRONMENT + 12, Math.sin(environmentRotation));
		var irradiance = environment != null ? environment.getIrradiance() : null;
		for (k in 0...9)
			for (c in 0...4)
				u.setFloat(IRRADIANCE + k * 16 + c * 4, irradiance != null && c < 3 ? irradiance[k * 3 + c] : 0);
		if (environment != null && brdf == null)
			brdf = Texture2D.fromRgba(gpu, EnvironmentBake.BRDF_SIZE, EnvironmentBake.BRDF_SIZE, EnvironmentBake.getBrdfTable(), true);
	}

	// A run of alike models: the material's uniforms, then one instanced draw.
	function drawRun(first:Int, runCount:Int):Void {
		var item = drawn[first],
			material = item.material,
			color = material.getBaseColor(),
			u = fragmentUniforms;
		u.setFloat(32, linear(color >>> 24));
		u.setFloat(36, linear((color >>> 16) & 255));
		u.setFloat(40, linear((color >>> 8) & 255));
		u.setFloat(44, (color & 255) / 255);
		u.setFloat(48, material.getMetallic());
		u.setFloat(52, material.getRoughness());
		u.setFloat(56, material.isLit() ? 1 : 0);
		u.setFloat(60, 0);
		var emissive = material.getEmissive(),
			strength = material.getEmissiveStrength(),
			normal = material.getNormalTexture();
		u.setFloat(64, linear(emissive >>> 24) * strength);
		u.setFloat(68, linear((emissive >>> 16) & 255) * strength);
		u.setFloat(72, linear((emissive >>> 8) & 255) * strength);
		u.setFloat(76, normal == null ? 0 : material.getNormalScale());
		var base = material.getTexture();
		if (base == null)
			base = white;
		if (normal == null)
			normal = flat;
		var shader = material.getShader(),
			shadows = shadowLights.length > 0 ? shadowMap : noShadows,
			cube = environment != null ? environment.getLightingTexture() : noEnvironment,
			table = brdf != null ? brdf.getHandle() : white.getHandle();
		// A skinned model draws through the skinned program, its joints from the palette; a surface shader isn't skinned yet, so it's ignored.
		if (item.skinned) {
			gpu.draw(pipelines.skinned3D(blendOf(item), item.material.isDoubleSided(), item.mirrored),
				[item.mesh.getVertexBuffer(gpu), instanceBuffer, item.mesh.getSkinBuffer(gpu)], item.mesh.getIndexBuffer(gpu), 0, item.mesh.getIndexCount(),
				first, runCount, [base.getHandle(), normal.getHandle(), shadows, cube, table, palette.getTexture()], [
					base.getSampling(),
					normal.getSampling(),
					Sampling.NEAREST,
					Sampling.LINEAR,
					Sampling.LINEAR,
					Sampling.NEAREST
				], [vertexUniforms, u]);
			draws++;
			return;
		}
		if (shader == null) {
			gpu.draw(pipelines.lit3D(blendOf(item), item.material.isDoubleSided(), item.mirrored), [item.mesh.getVertexBuffer(gpu), instanceBuffer],
				item.mesh.getIndexBuffer(gpu), 0, item.mesh.getIndexCount(), first, runCount, [base.getHandle(), normal.getHandle(), shadows, cube, table], [
					base.getSampling(),
					normal.getSampling(),
					Sampling.NEAREST,
					Sampling.LINEAR,
					Sampling.LINEAR
				], [vertexUniforms, u]);
			draws++;
			return;
		}
		// An app's surface shader: the stage's blocks with the time after them, the shader's own values, its own textures (white where unset).
		var blocks = [for (size in shader.getBlockSizes()) size > 0 ? Bytes.alloc(size) : null];
		if (blocks.length > 0 && blocks[0] != null) {
			blocks[0].blit(0, vertexUniforms, 0, vertexUniforms.length);
			blocks[0].setFloat(vertexUniforms.length, time);
		}
		if (blocks.length > 1 && blocks[1] != null) {
			blocks[1].blit(0, u, 0, u.length);
			blocks[1].setFloat(u.length, time);
		}
		var parameters = material.getShaderParameters();
		parameters.write(blocks);
		var own = parameters.getTextureSlots(), textures = [], samplings = [];
		for (slot in shader.getTextureSlots()) {
			while (textures.length < slot) {
				textures.push(0);
				samplings.push(Sampling.NEAREST);
			}
			if (slot >= 2 && slot <= 4) {
				textures.push(slot == 2 ? shadows : slot == 3 ? cube : table);
				samplings.push(slot == 2 ? Sampling.NEAREST : Sampling.LINEAR);
				continue;
			}
			var texture = slot == 0 ? base : slot == 1 ? normal : own.exists(slot) ? own[slot] : white;
			textures.push(texture.getHandle());
			samplings.push(texture.getSampling());
		}
		gpu.draw(pipelines.surface(shader.getHandle(), blendOf(item), item.material.isDoubleSided(), item.mirrored),
			[item.mesh.getVertexBuffer(gpu), instanceBuffer], item.mesh.getIndexBuffer(gpu), 0, item.mesh.getIndexCount(), first, runCount, textures,
			samplings, blocks);
		draws++;
	}

	// How item's colors meet what's behind: blended (see-through) or opaque.
	static inline function blendOf(item:Item):helix.graphics.BlendMode
		return item.blended ? Alpha : Opaque;

	/** Frees the stage's own GPU objects (its instance buffers, shadow maps, BRDF table and stand-in textures); meshes, textures and
		environments are their owners' to free, and the pipelines the GPU's (Pipelines). */
	public function destroy():Void {
		sprites.destroy();
		gpu.destroyBuffer(instanceBuffer);
		gpu.destroyBuffer(casterBuffer);
		gpu.destroyTexture(noShadows);
		if (shadowMap != 0)
			gpu.destroyTexture(shadowMap);
		white.destroy(gpu);
		flat.destroy(gpu);
		gpu.destroyTexture(noEnvironment);
		if (brdf != null)
			brdf.destroy(gpu);
	}
}

/** A model in view this draw. Pooled. */
private class Item {
	/** The model's node. */
	public var node:Node;

	/** Its mesh. */
	public var mesh:Mesh;

	/** Its material. */
	public var material:Material;

	/** Whether it is see-through (its material's or its tint's alpha). */
	public var blended = false;

	/** Whether its placement mirrors it, so its front faces wind clockwise. */
	public var mirrored = false;

	/** Whether it follows joints (Stage3D.isSkinned). */
	public var skinned = false;

	/** Its first joint in the palette, when skinned. */
	public var jointBase = 0;

	/** Its box's center's distance along the camera's view. */
	public var depth = 0.;

	/** Its place in the walk: ties keep it. */
	public var order = 0;

	/** Its box in the world: its center. */
	public var cx = 0.;

	/** Its box's center, y. */
	public var cy = 0.;

	/** Its box's center, z. */
	public var cz = 0.;

	/** Its box's reach along x from its center. */
	public var rx = 0.;

	/** Its box's reach along y. */
	public var ry = 0.;

	/** Its box's reach along z. */
	public var rz = 0.;

	/** The table entries of the lights lighting it, the nearest-reaching first, -1 past the last. */
	public var lights = [for (_ in 0...8) -1];

	/** An empty item, filled by the walk. */
	public function new() {}
}

/** A model that casts shadows, gathered by drawShadows. Pooled. */
private class Caster {
	/** The model's node. */
	public var node:Node;

	/** Its mesh. */
	public var mesh:Mesh;

	/** Whether it follows joints. */
	public var skinned = false;

	/** Its first joint in the palette, when skinned. */
	public var jointBase = 0;

	/** Its box's center in the world, x. */
	public var cx = 0.;

	/** Its box's center, y. */
	public var cy = 0.;

	/** Its box's center, z. */
	public var cz = 0.;

	/** Its box's reach along world x. */
	public var rx = 0.;

	/** Its box's reach along world y. */
	public var ry = 0.;

	/** Its box's reach along world z. */
	public var rz = 0.;

	/** An empty caster, filled by the walk. */
	public function new() {}
}
