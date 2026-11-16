package helix.raylib.internal;

import helix.geometry.Frustum;
import helix.math.Aabb3D;
import helix.math.Matrix4;
import helix.math.Vector3;
import helix.services.shaders.ShaderUniform;

/** Holds the scene's shadows (the Lighting extra's `SetLightShadowCasting`, `BeginShadowMode` and `EndShadowMode`): the lights casting
	them, 4 at most, in the order turned on, and the shadow map their maps are layers of. The map is as large as the largest `mapSize` a
	casting light asks for, and each light's maps are whole layers of it.

	`BeginShadowMode` fits each casting light's maps (a directional light's cascades to the camera's view out to its distance, snapped to
	its texels, or one map over its box; a spot light's cone; a point light's six faces), adds a depth-only pass for each, and until
	`EndShadowMode` draws each caster into the passes whose view holds its bounds: a mesh through its program's caster (`Program.caster`:
	its own vertex stage writing depth alone), the batch through its program's. Every lit draw after it reads the maps, written into its
	program once a pass (`receive`).

	Linked only by a program calling `SetLightShadowCasting` or `BeginShadowMode`. */
@:noCompletion
@:access(helix.raylib.Light)
@:access(helix.raylib.Material)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.modules.RModels)
@:access(helix.raylib.modules.RCore)
class Shadows {
	/** The most lights casting shadows. */
	public static inline final MOST_LIGHTS = 4;

	// The most maps the lights have: four point lights' faces.
	static inline final MOST_MAPS = 24;
	// A spot or point light's near plane, a share of its reach, as shadows.glsl's HELIX_SHADOW_NEAR.
	static inline final NEAR = 1 / 512;
	// How the cascades split the distance: 0 evenly, 1 by the ratio of their ends.
	static inline final CASCADE_SPLIT = .6;
	// The receivers' uniforms, by the indices of a receiver's fields.
	static final FIELDS = [
		"helixShadowMatrices",
		"helixShadowParams",
		"helixShadowStrengths",
		"helixShadowSplits",
		"helixShadowView"
	];

	// The lights casting shadows, in the order turned on.
	static final casters:Array<helix.raylib.Light> = [];
	// The last pass's maps: each one's view and projection, both composed, the volume it covers and its pass in the frame being made;
	// and how many.
	static final views = [for (_ in 0...MOST_MAPS) new Matrix4()];
	static final projections = [for (_ in 0...MOST_MAPS) new Matrix4()];
	static final matrices = [for (_ in 0...MOST_MAPS) new Matrix4()];
	static final volumes = [for (_ in 0...MOST_MAPS) new Frustum()];
	static final passes:Array<Any> = [];
	static var mapCount = 0;
	// Each casting light's values, as shadows.glsl reads them (helixShadowParams and helixShadowSplits, four floats each;
	// helixShadowStrengths, one each), and how many lights; the camera's forward direction and w (helixShadowView).
	static final params:Array<Float> = [for (_ in 0...MOST_LIGHTS * 4) 0.];
	static final strengths:Array<Float> = [for (_ in 0...MOST_LIGHTS) 0.];
	static final splits:Array<Float> = [for (_ in 0...MOST_LIGHTS * 4) 0.];
	static final forward:Array<Float> = [0, 0, -1, 0];
	static var castCount = 0;
	// Which maps the draw being cast reaches, found from its bounds (bound); all when none are found.
	static final reached:Array<Bool> = [for (_ in 0...MOST_MAPS) true];
	static var bounded = false;
	// The shadow map, its size and layers, and the graphics it was made on; 0 until a pass.
	static var map = 0;
	static var mapSize = 0;
	static var mapLayers = 0;
	static var mapGraphics:Null<helix.platform.IGraphics> = null;
	// The shadow map's texture id (Textures.fromHandle), bound to the receivers' shadow samplers (ShadowSlots).
	static var mapId = 0;
	// What each program a lit draw is drawn through was given: the pass it was given the shadows of, and its uniforms of them.
	static final receivers = new Map<Program, Receiver>();
	// Each pass's number, from 1, which a receiver's stamp is checked against.
	static var stamp = 0;
	// Whether between BeginShadowMode and EndShadowMode, and what the pass replaced, put back at its end.
	static var active = false;
	static var savedEyes:Null<(add:() -> Void, mesh:Bool)->Void>;
	static var savedRunLighting:Null<(p:Program, data:haxe.io.Bytes, first:Int, count:Int, stride:Int) -> Void>;
	static var savedLighting:Null<(p:Program, mesh:helix.raylib.Mesh, model:Matrix4, transforms:Null<Array<helix.raylib.Matrix>>, count:Int) -> Void>;
	static var savedSurfacing:Null<(shader:helix.raylib.Shader, material:helix.raylib.Material, modelEmissive:Null<Array<Float>>) -> helix.raylib.Shader>;
	static var savedPass:Any;
	static var savedView:Null<Matrix4>;
	static var savedProjection:Null<Matrix4>;
	static var savedViewport:Null<Array<Int>>;
	static var savedScissor:Null<Array<Float>>;
	static var savedDepthTest = false;
	static var savedDepthMask = true;
	static var savedColorBlend = true;
	// Scratch values, reused.
	static final view = new Matrix4();
	static final projection = new Matrix4();
	static final cameraView = new Matrix4();
	static final cameraProjection = new Matrix4();
	static final scratch = new Matrix4();
	static final inverse = new Matrix4();
	static final moved = new Vector3();
	static final box = new Aabb3D();
	static final corners:Array<Float> = [for (_ in 0...26) 0.];
	static final points:Array<Float> = [];
	static final ends = [0., 0, 0, 0];

	/** Turns a light's shadows on, made as its options say (`Light.shadow`, set before). A fifth light's stay off, with a warning.

		@param light  The light. */
	public static function addCaster(light:helix.raylib.Light):Void {
		purge();
		if (!light.shadowCasting) {
			if (casters.length >= MOST_LIGHTS) {
				Runtime.log(helix.raylib.Raylib.LOG_WARNING, 'LIGHTING: A light\'s shadows are off: $MOST_LIGHTS lights cast shadows at most');
				return;
			}
			light.shadowCasting = true;
			casters.push(light);
		}
		SceneLights.receiving = receive;
	}

	// Drops the lights turned off or out of the scene (UnloadLight turns them off).
	static function purge():Void {
		var i = casters.length;
		while (i-- > 0)
			if (!casters[i].shadowCasting || !SceneLights.has(casters[i])) {
				casters[i].shadowCasting = false;
				casters[i].shadowIndex = 0;
				casters.splice(i, 1);
			}
	}

	/** Starts the shadow pass from a camera: the casting lights' maps fitted and a pass added for each, and the frame's draws cast into
		them until `end`.

		@param camera  The camera the frame is drawn from. */
	public static function begin(camera:helix.raylib.Camera3D):Void {
		var frame = Runtime.frame;
		if (active)
			end();
		frame.flush();
		purge();
		SceneLights.receiving = receive;
		var camera3D = helix.raylib.modules.RCore.camera3D(camera);
		// The screen's shape, as BeginMode3D's projection takes it on the screen.
		var screen = Runtime.screen;
		var width = screen == null ? frame.width : screen.width,
			height = screen == null ? frame.height : screen.height;
		camera3D.computeViewMatrix(cameraView);
		camera3D.computeProjectionMatrix(height > 0 ? width / height : 1, cameraProjection);
		var p = camera.position, t = camera.target;
		var fx = t.x - p.x, fy = t.y - p.y, fz = t.z - p.z;
		var fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
		if (fl == 0)
			fl = 1;
		forward[0] = fx / fl;
		forward[1] = fy / fl;
		forward[2] = fz / fl;
		forward[3] = -(forward[0] * p.x + forward[1] * p.y + forward[2] * p.z);
		mapCount = 0;
		castCount = 0;
		// The map's size, the largest a light casting asks for, which each of its maps fills.
		var size = 0;
		for (light in casters)
			if (light.enabled && light.shadow.mapSize > size)
				size = light.shadow.mapSize;
		for (light in casters) {
			light.shadowIndex = 0;
			if (!light.enabled)
				continue;
			var s = light.shadow, c = castCount;
			var first = mapCount, kind = 0;
			if (light.type == helix.raylib.Rlights.LIGHT_DIRECTIONAL) {
				lookAlong(light.target.x - light.position.x, light.target.y - light.position.y, light.target.z - light.position.z);
				if (s.bounds != null) {
					kind = 1;
					fitBox(s.bounds);
				} else
					fitCascades(s, c, size);
			} else {
				var reach = light.range > 0 ? light.range : s.distance;
				var margin = 1 + 2 * (s.softness + 2) / size;
				var x = light.position.x,
					y = light.position.y,
					z = light.position.z;
				if (light.type == SPOT) {
					kind = 2;
					var outer = Math.acos(Math.max(-1, Math.min(1, light.outerCosine)));
					var half = Math.min(Math.atan(Math.tan(outer) * margin), 1.5);
					var dx = light.target.x - x,
						dy = light.target.y - y,
						dz = light.target.z - z;
					var dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
					var up = dl == 0 || Math.abs(dy / dl) > .99;
					Matrix4.fromLookAt(x, y, z, x + dx, y + dy, z + dz, 0, up ? 0 : 1, up ? 1 : 0, view);
					Matrix4.fromPerspective(half * 2, 1, reach * NEAR, reach, projection);
					addMap(view, projection);
				} else {
					kind = 3;
					Matrix4.fromPerspective(2 * Math.atan(margin), 1, reach * NEAR, reach, projection);
					for (face in 0...6) {
						var axis = face >> 1, sign = face & 1 == 0 ? 1 : -1;
						var tx = axis == 0 ? sign : 0,
							ty = axis == 1 ? sign : 0,
							tz = axis == 2 ? sign : 0;
						Matrix4.fromLookAt(x, y, z, x + tx, y + ty, z + tz, 0, axis == 1 ? 0 : -1, axis == 1 ? sign : 0, view);
						addMap(view, projection);
					}
				}
			}
			var count = mapCount - first;
			params[c * 4] = first + 32 * count + 256 * kind + 1024 * Math.round(s.softness * 16);
			params[c * 4 + 1] = s.bias;
			params[c * 4 + 2] = s.slopeBias;
			params[c * 4 + 3] = s.normalOffset;
			strengths[c] = s.strength;
			castCount++;
			light.shadowIndex = castCount;
		}
		stamp++;
		active = true;
		if (castCount > 0) {
			mapFor(size, mapCount);
			passes.resize(0);
			for (k in 0...mapCount)
				passes.push(frame.addShadowPass(k, size));
			Frame.beginShadow = beginPass;
		}
		// The draws cast from here on, until end.
		savedEyes = frame.eyes;
		savedRunLighting = Frame.lighting;
		savedLighting = helix.raylib.modules.RModels.lighting;
		savedSurfacing = helix.raylib.modules.RModels.surfacing;
		savedPass = frame.currentPass;
		savedView = frame.view;
		savedProjection = frame.projection;
		savedViewport = frame.viewport;
		savedScissor = frame.scissor;
		savedDepthTest = frame.depthTest;
		savedDepthMask = frame.depthMask;
		savedColorBlend = frame.colorBlend;
		frame.eyes = eachMap;
		Frame.lighting = null;
		helix.raylib.modules.RModels.lighting = bound;
		helix.raylib.modules.RModels.surfacing = surface;
	}

	/** Ends the shadow pass: the batch cast, and the frame drawing as before it. */
	public static function end():Void {
		if (!active)
			return;
		var frame = Runtime.frame;
		frame.flush();
		active = false;
		frame.eyes = savedEyes;
		Frame.lighting = savedRunLighting;
		helix.raylib.modules.RModels.lighting = savedLighting;
		helix.raylib.modules.RModels.surfacing = savedSurfacing;
		frame.drawInto(savedPass);
		frame.view = savedView;
		frame.projection = savedProjection;
		frame.viewport = savedViewport;
		frame.scissor = savedScissor;
		frame.depthTest = savedDepthTest;
		frame.depthMask = savedDepthMask;
		frame.colorBlend = savedColorBlend;
	}

	static inline final SPOT = 2;

	// Sets view to look along a direction from the origin.
	static function lookAlong(dx:Float, dy:Float, dz:Float):Void {
		var l = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (l == 0) {
			dy = -1;
			l = 1;
		}
		var up = Math.abs(dy / l) > .99;
		Matrix4.fromLookAt(0, 0, 0, dx, dy, dz, 0, up ? 0 : 1, up ? 1 : 0, view);
	}

	// Adds a map of a view and a projection.
	static function addMap(v:Matrix4, p:Matrix4):Void {
		views[mapCount].copyFrom(v);
		projections[mapCount].copyFrom(p);
		Matrix4.compose(v, p, matrices[mapCount]);
		Frustum.fromMatrix(matrices[mapCount], volumes[mapCount]);
		mapCount++;
	}

	// A directional light's one map over a box, square, the light looking along view.
	static function fitBox(bounds:helix.raylib.BoundingBox):Void {
		box.makeEmpty();
		for (corner in 0...8) {
			view.transformPoint(corner & 1 == 0 ? bounds.min.x : bounds.max.x, corner & 2 == 0 ? bounds.min.y : bounds.max.y,
				corner & 4 == 0 ? bounds.min.z : bounds.max.z, moved);
			box.expand(moved.x, moved.y, moved.z);
		}
		var half = Math.max(box.maxX - box.minX, box.maxY - box.minY) / 2,
			cx = box.centerX,
			cy = box.centerY;
		var margin = (box.maxZ - box.minZ) * .01 + 1e-4;
		Matrix4.fromOrthographic(cx - half, cx + half, cy - half, cy + half, -box.maxZ - margin, -box.minZ + margin, projection);
		addMap(view, projection);
	}

	// A directional light's cascades over the camera's view out to its distance, each a square around its slice's sphere snapped to the
	// texels of a map of a size, reaching back toward the light; their ends written to the light's splits.
	static function fitCascades(s:helix.raylib.extras.ShadowOptions, c:Int, size:Int):Void {
		var count:Int = s.cascades;
		slice();
		var near = corners[24], far = corners[25];
		var reach = Math.max(Math.min(s.distance, far), near + 1e-3);
		var logNear = Math.max(near, .01);
		for (i in 0...4) {
			var t = Math.min(i + 1, count) / count;
			var even = near + (reach - near) * t;
			ends[i] = i + 1 >= count ? reach : even + (logNear * Math.pow(reach / logNear, t) - even) * CASCADE_SPLIT;
			splits[c * 4 + i] = ends[i];
		}
		for (k in 0...count) {
			var from = k == 0 ? near : ends[k - 1], to = ends[k];
			// The slice's corners, their middle, and the sphere around them.
			points.resize(0);
			var dn = corners[24], df = corners[25];
			for (e in 0...4)
				for (side in 0...2) {
					var d = side == 0 ? from : to;
					var t = df - dn > 1e-9 ? (d - dn) / (df - dn) : 0;
					for (axis in 0...3)
						points.push(corners[e * 3 + axis] + (corners[12 + e * 3 + axis] - corners[e * 3 + axis]) * t);
				}
			var n = Std.int(points.length / 3), mx = 0., my = 0., mz = 0.;
			for (i in 0...n) {
				mx += points[i * 3];
				my += points[i * 3 + 1];
				mz += points[i * 3 + 2];
			}
			mx /= n;
			my /= n;
			mz /= n;
			var radius = 0.;
			for (i in 0...n) {
				var dx = points[i * 3] - mx,
					dy = points[i * 3 + 1] - my,
					dz = points[i * 3 + 2] - mz;
				radius = Math.max(radius, Math.sqrt(dx * dx + dy * dy + dz * dz));
			}
			radius = Math.ceil(radius * 64 + 1) / 64;
			// The middle in the light's space, snapped to a texel there.
			view.transformPoint(mx, my, mz, moved);
			var texel = radius * 2 / size;
			var cx = Math.floor(moved.x / texel) * texel,
				cy = Math.floor(moved.y / texel) * texel;
			var back = 2 * Math.max(radius, s.distance);
			Matrix4.fromOrthographic(cx - radius, cx + radius, cy - radius, cy + radius, -moved.z - radius - back, -moved.z + radius, projection);
			addMap(view, projection);
		}
	}

	// The camera's frustum into corners: its four near corners, then its four far ones, x, y and z each, in the world; then its near and
	// far depths along its axis.
	static function slice():Void {
		Matrix4.compose(cameraView, cameraProjection, scratch);
		if (scratch.invert(inverse) == null)
			inverse.makeIdentity();
		var m = inverse.values, w = cameraView.values;
		for (k in 0...8) {
			var x = k & 1 == 0 ? -1. : 1,
				y = k & 2 == 0 ? -1. : 1,
				z = k < 4 ? -1. : 1;
			var h = m[3] * x + m[7] * y + m[11] * z + m[15];
			if (Math.abs(h) < 1e-12)
				h = 1e-12;
			for (axis in 0...3)
				corners[k * 3 + axis] = (m[axis] * x + m[4 + axis] * y + m[8 + axis] * z + m[12 + axis]) / h;
		}
		corners[24] = -(w[2] * corners[0] + w[6] * corners[1] + w[10] * corners[2] + w[14]);
		corners[25] = -(w[2] * corners[12] + w[6] * corners[13] + w[10] * corners[14] + w[14]);
	}

	// The shadow map, of a size and at least a number of layers: the last one, or a new one, the old freed once the frame is drawn.
	static function mapFor(size:Int, layers:Int):Void {
		var graphics = Runtime.graphics;
		if (map != 0 && mapGraphics == graphics && mapSize == size && mapLayers >= layers)
			return;
		if (map != 0 && mapGraphics == graphics) {
			var old = mapId;
			Runtime.frame.afterDraw(() -> Textures.release(old));
		}
		map = graphics.createShadowMap(size, layers);
		mapId = Textures.fromHandle(map);
		mapSize = size;
		mapLayers = layers;
		mapGraphics = graphics;
	}

	// The frame's eyes in the pass: what is added, added once for each map, a mesh's for those its bounds reach, the batch's through its
	// program's caster.
	static function eachMap(add:() -> Void, mesh:Bool):Void {
		var frame = Runtime.frame;
		var program = frame.program;
		if (!mesh) {
			// The sprites written out as quads, which the casters draw.
			var runs:Array<Dynamic> = frame.batch;
			for (i in 0...runs.length)
				if (runs[i].mode == Frame.SPRITES && runs[i].count > 0)
					runs[i] = frame.expand(runs[i]);
			var caster = casterOf(program).program;
			cut(caster, 0);
			frame.program = caster;
		}
		depthAlone(frame);
		for (k in 0...mapCount) {
			if (mesh && bounded && !reached[k])
				continue;
			frame.drawInto(passes[k]);
			frame.view = views[k];
			frame.projection = projections[k];
			frame.viewport = null;
			frame.scissor = null;
			add();
		}
		frame.program = program;
		bounded = false;
	}

	// Begins a shadow pass (Frame.beginShadow): into its map's layer.
	static function beginPass(target:Int):Void
		Runtime.graphics.beginShadowPass(map, -2 - target);

	// The state the casters are drawn in: depth tested and written, no color.
	static function depthAlone(frame:Frame):Void {
		frame.depthTest = true;
		frame.depthMask = true;
		frame.colorBlend = false;
	}

	// The draws' hook in the pass (RModels.lighting): which maps a mesh's bounds reach.
	static function bound(p:Program, mesh:helix.raylib.Mesh, model:Matrix4, transforms:Null<Array<helix.raylib.Matrix>>, count:Int):Void {
		bounded = true;
		if (!SceneLights.bound(mesh, model, transforms, count)) {
			for (k in 0...mapCount)
				reached[k] = true;
			return;
		}
		var b = SceneLights.box;
		box.set(b[0], b[1], b[2], b[3], b[4], b[5]);
		for (k in 0...mapCount)
			reached[k] = volumes[k].intersectsBounds(box);
	}

	// The draws' hook in the pass (RModels.surfacing): the draw made through its shader's caster, cut at its material's alpha cutoff.
	static function surface(shader:helix.raylib.Shader, m:helix.raylib.Material, modelEmissive:Null<Array<Float>>):helix.raylib.Shader {
		if (savedSurfacing != null)
			shader = savedSurfacing(shader, m, modelEmissive);
		var caster = casterOf(shader.program);
		cut(caster.program, m.alphaCutoff);
		depthAlone(Runtime.frame);
		return caster;
	}

	// The alpha cutoff a caster and its skinned twin cut at.
	static function cut(caster:Program, cutoff:Float):Void {
		var u = caster.shader.findUniform("alphaCutoff");
		if (u != null)
			caster.values.writeFloat(u, cutoff);
		var twin = caster.twin;
		if (twin != null && (u = twin.shader.findUniform("alphaCutoff")) != null)
			twin.values.writeFloat(u, cutoff);
	}

	/** Returns the shader the shadow pass draws through in a program's place, made with its first draw there: a compiled shader's
		shadow variant, or for a built-in shader the default vertex stage's, with its skinned twin, which place a vertex as each of them
		does. Its program is a twin of the program's (`Program.mirror`), given every uniform the program is, and writes depth alone.

		@param p  The program. */
	public static function casterOf(p:Program):helix.raylib.Shader {
		if (p.caster != null)
			return p.caster;
		var graphics = Runtime.graphics;
		var caster = new Program(graphics,
			p.casterSource != null ? new helix.services.shaders.Shader(p.casterSource, "shadow variant") : Defaults.shadowShader());
		caster.depthOnly = true;
		if (p.casterSource == null) {
			var skinned = new Program(graphics, Defaults.shadowSkinnedShader());
			skinned.depthOnly = true;
			caster.mirror(skinned);
		}
		// A twin, though not the program's skinned one.
		var twin = p.twin;
		p.mirror(caster);
		p.twin = twin;
		p.caster = new helix.raylib.Shader(caster.handle, helix.raylib.modules.RModels.locations(caster), caster);
		return p.caster;
	}

	// The draws' hook (SceneLights.receiving): the last pass's shadows written into a program a lit draw is drawn through, once a pass.
	static function receive(p:Program):Void {
		var r = receivers.get(p);
		if (r == null)
			receivers.set(p, r = new Receiver([for (name in FIELDS) p.shader.findUniform(name)]));
		if (r.stamp == stamp)
			return;
		r.stamp = stamp;
		var f = r.fields;
		if (f[0] == null)
			return;
		var values = p.values;
		for (k in 0...mapCount)
			values.writeMatrix(f[0], matrices[k], k);
		if (f[2] != null)
			values.writeVector(f[2], strengths[0], strengths[1], strengths[2], strengths[3]);
		for (c in 0...castCount) {
			var at = c * 4;
			if (f[1] != null)
				values.writeVector(f[1], params[at], params[at + 1], params[at + 2], params[at + 3], c);
			if (f[3] != null)
				values.writeVector(f[3], splits[at], splits[at + 1], splits[at + 2], splits[at + 3], c);
		}
		if (f[4] != null)
			values.writeVector(f[4], forward[0], forward[1], forward[2], forward[3]);
		ShadowSlots.bind(p, castCount > 0 ? mapId : 0);
	}
}

// What a program receiving the shadows was given: the pass whose shadows it holds, and its uniforms of them, by the indices of FIELDS.
private class Receiver {
	public var stamp = 0;
	public final fields:Array<Null<ShaderUniform>>;

	public function new(fields:Array<Null<ShaderUniform>>)
		this.fields = fields;
}
