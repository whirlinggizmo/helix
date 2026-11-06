package helix.render;

import helix.geometry.Frustum3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.math.Vector3D;
import helix.platform.Blend;
import helix.platform.CullFace;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderPipelineState;
import helix.services.shaders.ShaderSharedTexture;
import helix.services.shaders.ShaderUniform;

/** `Batch3D`'s shadow work: at each `begin`, the casting lights chosen (the first 4 in `lights` that cast), their maps fitted (a
	directional light's cascades to the views, snapped to its texels, or to its box; a spot's cone; a point's six faces), written into the
	`Lighting` block, and a shadow pass made for each map, into a shadow map of the frame's; at each mesh drawn casting, its depth drawn
	into the passes whose volume holds it, as its color draw places it.

	It is linked only by a light casting (`install`, which `Light3D.castsShadow` calls), so a program casting no shadow carries none of
	it. */
@:noCompletion
@:allow(helix.render)
@:access(helix.render.Batch3D)
@:access(helix.render.BatchLighting)
@:access(helix.render.Renderer)
@:access(helix.render.RenderPass)
@:access(helix.render.RenderDraw)
@:access(helix.render.RenderFill)
@:access(helix.render.RenderView)
@:access(helix.render.RenderStream)
@:access(helix.render.GpuMesh3D)
@:access(helix.render.Texture2D)
class BatchShadows {
	// The most lights casting in a batch, and the most maps they have.
	static inline final MOST_LIGHTS = 4;
	static inline final MOST_MAPS = 24;
	// The floats a light is read as (Light3D.writeLight).
	static inline final FLOATS = 16;
	// A spot's or a point's near plane, a share of its far plane's distance, as lighting.glsl's HELIX_SHADOW_NEAR.
	static inline final NEAR = 1 / 512;

	/** Makes the batches cast shadows from their next `begin`. */
	static function install():Void {
		#if helix_render_no_shadows
		throw "helix-render: built without shadows (-D helix_render_no_shadows), so no light can cast; build without the define";
		#end
		if (BatchLighting.makeShadows == null)
			BatchLighting.makeShadows = attach;
	}

	/** Gives a batch's lit work its shadows, through the hooks it calls. */
	static function attach(lighting:BatchLighting):Void {
		var s = new BatchShadows(lighting);
		lighting.shadowsBegin = s.begin;
		lighting.batch.shadowMesh = s.castMesh;
		lighting.batch.shadowInstanced = s.castInstanced;
	}

	final lighting:BatchLighting;
	final batch:Batch3D;
	final renderer:Renderer;
	// The casters' shaders: depth alone, and one cutting by alphaCutoff, made at the first cut-out caster.
	final depthShader:Shader;
	var cutShader:Null<Shader> = null;
	final shadowMatrices:ShaderUniform;
	final shadowParams:ShaderUniform;
	final shadowColors:ShaderUniform;
	final shadowCascadeSplits:ShaderUniform;
	// The shadow map the views' draws read, this begin's.
	final shared = new ShaderSharedTexture(0, Sampling.LINEAR);
	// This begin's maps: each one's matrix, the volume it covers, its pass, and how many there are.
	final matrices = [for (_ in 0...MOST_MAPS) new Matrix3D()];
	final volumes = [for (_ in 0...MOST_MAPS) new Frustum3D()];
	final passes:Array<RenderPass> = [];
	var mapCount = 0;
	// The bone palettes uploaded before this begin's passes.
	final uploaded:Array<Int> = [];
	// The shadow maps, one for each begin of a frame that casts, by its place in the frame; the frame they were counted in.
	final maps:Array<{handle:Int, size:Int, layerCount:Int}> = [];
	var mapsUsed = 0;
	var mapsFrame = -1;
	// The casters' pipeline states, by indexing and cull.
	final states = new Map<Int, ShaderPipelineState>();
	// Scratch values, reused.
	final view = new Matrix3D();
	final projection = new Matrix3D();
	final scratch = new Matrix3D();
	final inverse = new Matrix3D();
	final box = new Bounds3D();
	final moved = new Vector3D();
	final corners:Array<Float> = [];
	final floats = [0., 0, 0, 0];
	final ends = [0., 0, 0, 0];

	function new(lighting:BatchLighting) {
		this.lighting = lighting;
		batch = lighting.batch;
		renderer = batch.renderer;
		depthShader = RenderShaders.compileOwn("mesh.vert", "shadow.frag");
		var lit = lighting.shader;
		shadowMatrices = lit.getUniform("shadowMatrices");
		shadowParams = lit.getUniform("shadowParams");
		shadowColors = lit.getUniform("shadowColors");
		shadowCascadeSplits = lit.getUniform("shadowCascadeSplits");
		renderer.live.set(this, dispose);
	}

	/** Frees the shadow maps. */
	function dispose():Void {
		for (m in maps)
			renderer.graphics.disposeTexture(m.handle);
		maps.resize(0);
	}

	/** Chooses the casting lights as `begin` reads them, writes each one's index into the lights read, fits their maps to the views, writes
		them into the block, shares this begin's shadow map with the views and makes a pass for each map. */
	function begin(views:Array<View3D>):Void {
		mapCount = 0;
		passes.resize(0);
		uploaded.resize(0);
		var lights = batch.lights, f = lighting.lights;
		var size = 0, castCount = 0, splitsTaken = false;
		for (i in 0...lights.length) {
			var light = lights[i], at = i * FLOATS;
			var kind = Std.int(f[at + 7]);
			if (!light.castsShadow || kind == 3 || castCount == MOST_LIGHTS)
				continue;
			var shadow = light.shadow;
			f[at + 14] = castCount;
			if (shadow.mapSize > size)
				size = shadow.mapSize;
			var first = mapCount, mode = 0;
			if (kind == 0) {
				lookAlong(f[at + 4], f[at + 5], f[at + 6]);
				if (shadow.bounds != null) {
					mode = 1;
					fitBox(shadow.bounds);
				} else {
					mode = splitsTaken ? 1 : 0;
					fitCascades(views, shadow, mode == 0);
					splitsTaken = true;
				}
			} else if (kind == 2) {
				mode = 2;
				var reach = f[at + 3] > 0 ? Math.min(f[at + 3], shadow.distance) : shadow.distance;
				var outer = Math.acos(Math.max(-1, Math.min(1, f[at + 13])));
				var half = Math.min(Math.atan(Math.tan(outer) * (1 + 2 * (shadow.radius + 2) / shadow.mapSize)), 1.5);
				var dx = f[at + 4], dy = f[at + 5], dz = f[at + 6];
				var up = Math.abs(dy) > .99;
				Matrix3D.fromLookAt(f[at], f[at + 1], f[at + 2], f[at] + dx, f[at + 1] + dy, f[at + 2] + dz, 0, up ? 0 : 1, up ? 1 : 0, view);
				Matrix3D.fromPerspective(half * 2, 1, reach * NEAR, reach, projection);
				addMap(view, projection);
			} else {
				mode = 3;
				var reach = f[at + 3] > 0 ? Math.min(f[at + 3], shadow.distance) : shadow.distance;
				var fov = 2 * Math.atan(1 + 2 * (shadow.radius + 2) / shadow.mapSize);
				Matrix3D.fromPerspective(fov, 1, reach * NEAR, reach, projection);
				var x = f[at], y = f[at + 1], z = f[at + 2];
				for (face in 0...6) {
					var axis = face >> 1, sign = face & 1 == 0 ? 1 : -1;
					var tx = axis == 0 ? sign : 0,
						ty = axis == 1 ? sign : 0,
						tz = axis == 2 ? sign : 0;
					Matrix3D.fromLookAt(x, y, z, x + tx, y + ty, z + tz, 0, axis == 1 ? 0 : -1, axis == 1 ? sign : 0, view);
					addMap(view, projection);
				}
			}
			var count = mapCount - first;
			lighting.block.writeVector(shadowParams, first + 32 * count + 256 * mode + 1024 * Math.round(shadow.radius * 16), shadow.bias, shadow.slopeBias,
				shadow.normalOffset, castCount);
			Light3D.writeRadiance(shadow.color, 1, floats, 0);
			lighting.block.writeVector(shadowColors, floats[0], floats[1], floats[2], shadow.strength, castCount);
			castCount++;
		}
		if (castCount == 0)
			return;
		for (k in 0...mapCount)
			lighting.block.writeMatrix(shadowMatrices, matrices[k], k);
		var handle = mapFor(size, mapCount);
		shared.texture = handle;
		for (i in 0...views.length)
			batch.viewPool[i].scene.shareTexture("shadowTexture", shared);
		// The passes come before the frame's other passes, after those made before them.
		var list = renderer.passes;
		var at = 0;
		while (at < list.length && list[at].begin != null)
			at++;
		for (k in 0...mapCount) {
			var p = new RenderPass(null, handle, size, size, null);
			var layer = k;
			p.begin = graphics -> graphics.beginShadowPass(handle, layer);
			passes.push(p);
			list.insert(at + k, p);
		}
	}

	// Sets view to look along a direction from the origin.
	function lookAlong(dx:Float, dy:Float, dz:Float):Void {
		var up = Math.abs(dy) > .99;
		Matrix3D.fromLookAt(0, 0, 0, dx, dy, dz, 0, up ? 0 : 1, up ? 1 : 0, view);
	}

	// Adds a map of a view and a projection.
	function addMap(view:Matrix3D, projection:Matrix3D):Void {
		if (mapCount == MOST_MAPS)
			throw "helix-render: more than 24 shadow maps in a batch";
		Matrix3D.compose(view, projection, matrices[mapCount]);
		Frustum3D.fromMatrix(matrices[mapCount], volumes[mapCount]);
		mapCount++;
	}

	// A directional light's one map over a box, square, the light looking along view.
	function fitBox(bounds:Bounds3D):Void {
		box.makeEmpty();
		for (corner in 0...8) {
			view.transformPoint(corner & 1 == 0 ? bounds.minX : bounds.maxX, corner & 2 == 0 ? bounds.minY : bounds.maxY,
				corner & 4 == 0 ? bounds.minZ : bounds.maxZ, moved);
			box.expand(moved.x, moved.y, moved.z);
		}
		var half = Math.max(box.maxX - box.minX, box.maxY - box.minY) / 2,
			cx = box.centerX,
			cy = box.centerY;
		var margin = (box.maxZ - box.minZ) * .01 + 1e-4;
		Matrix3D.fromOrthographic(cx - half, cx + half, cy - half, cy + half, -box.maxZ - margin, -box.minZ + margin, projection);
		addMap(view, projection);
	}

	// A directional light's cascades over the views out to its distance, split by its cascadeSplit, each a square around the slice's
	// sphere snapped to the map's texels, reaching back toward the light; their ends written to shadowCascadeSplits where asked.
	function fitCascades(views:Array<View3D>, shadow:LightShadow3D, writeEnds:Bool):Void {
		var count = shadow.cascadeCount;
		// The first view's near and far depths, and where each cascade ends.
		slice(views[0]);
		var near = corners[24], far = corners[25];
		var reach = Math.max(Math.min(shadow.distance, far), near + 1e-3);
		var logNear = Math.max(near, .01);
		for (i in 0...4) {
			var t = Math.min(i + 1, count) / count;
			var even = near + (reach - near) * t;
			ends[i] = i + 1 >= count ? reach : even + (logNear * Math.pow(reach / logNear, t) - even) * shadow.cascadeSplit;
		}
		if (writeEnds)
			lighting.block.writeVector(shadowCascadeSplits, ends[0], ends[1], ends[2], ends[3]);
		for (c in 0...count) {
			var from = c == 0 ? near : ends[c - 1], to = ends[c];
			// The slice's corners in every view, their middle, and the sphere around them.
			var points:Array<Float> = [];
			for (v in views) {
				slice(v);
				var dn = corners[24], df = corners[25];
				for (e in 0...4)
					for (d in [from, to]) {
						var t = df - dn > 1e-9 ? (d - dn) / (df - dn) : 0;
						for (axis in 0...3)
							points.push(corners[e * 3 + axis] + (corners[12 + e * 3 + axis] - corners[e * 3 + axis]) * t);
					}
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
			var texel = radius * 2 / shadow.mapSize;
			var cx = Math.floor(moved.x / texel) * texel,
				cy = Math.floor(moved.y / texel) * texel;
			var back = 2 * Math.max(radius, shadow.distance);
			Matrix3D.fromOrthographic(cx - radius, cx + radius, cy - radius, cy + radius, -moved.z - radius - back, -moved.z + radius, projection);
			addMap(view, projection);
		}
	}

	// A view's frustum into corners: its four near corners, then its four far ones, x, y and z each, in the world; then its near and far
	// depths along its axis.
	function slice(v:View3D):Void {
		corners.resize(26);
		Matrix3D.compose(v.viewMatrix, v.projectionMatrix, scratch);
		if (scratch.invert(inverse) == null)
			inverse.makeIdentity();
		var m = inverse.values, w = v.viewMatrix.values;
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
		inline function depth(k:Int):Float
			return -(w[2] * corners[k * 3] + w[6] * corners[k * 3 + 1] + w[10] * corners[k * 3 + 2] + w[14]);
		corners[24] = depth(0);
		corners[25] = depth(4);
	}

	/** This begin's shadow map, of a size and a number of layers: the frame's next, made again where it is too small. */
	function mapFor(size:Int, layerCount:Int):Int {
		if (mapsFrame != renderer.frameNumber) {
			mapsFrame = renderer.frameNumber;
			mapsUsed = 0;
		}
		var i = mapsUsed++;
		var m = i < maps.length ? maps[i] : null;
		if (m != null && m.size == size && m.layerCount >= layerCount)
			return m.handle;
		var graphics = renderer.graphics;
		if (m != null) {
			var old = m.handle;
			renderer.release(() -> graphics.disposeTexture(old));
		}
		var made = {handle: graphics.createShadowMap(size, layerCount), size: size, layerCount: layerCount};
		if (i < maps.length)
			maps[i] = made;
		else
			maps.push(made);
		return made.handle;
	}

	/** The pipeline state casters are drawn with: depth alone, opaque, tested and written, culled as their color draw is. */
	function stateFor(indexed:Bool, cull:CullFace):ShaderPipelineState {
		var code = (indexed ? 1 : 0) | (cull : Int) << 1;
		var state = states.get(code);
		if (state == null)
			states.set(code, state = ShaderPipelineState.CLIP_SCALE.with({
				primitive: Triangles,
				indexed: indexed,
				blend: Blend.OPAQUE,
				depthTest: LessEqual,
				depthWrite: true,
				cull: cull,
				colorWrite: None,
				depthOnly: true
			}));
		return state;
	}

	/** Whether a material casts in this begin: a light casting, the batch's and its castShadows on, its faces filled. */
	function casts(material:Material3D):Bool
		return mapCount > 0 && batch.castShadows && material.castShadows && batch.polygonMode == Fill;

	/** A caster's values but its matrix, written on its shader's fill: its material's alpha and cut for a cut-out one, its skin. */
	function fillCaster(material:Material3D, skinned:Bool, boneTexture:Int, boneOffset:Int):RenderFill {
		var s = depthShader;
		if (material.alphaCutoff > 0) {
			if (cutShader == null)
				cutShader = RenderShaders.compileOwn("mesh.vert", "shadow-cut.frag");
			s = cutShader;
		}
		var fill = batch.fillFor(s);
		fill.values.base = null;
		fill.values.scene = batch.viewPool[0].scene;
		var white = renderer.white.handle;
		var base = material.baseColorTexture, alpha = material.alphaTexture;
		fill.color(fill.baseColor, material.baseColor);
		fill.texture(fill.baseColorTexture, base == null ? white : base.drawnHandle(), base == null ? Sampling.LINEAR : base.sampling);
		fill.texture(fill.alphaTexture, alpha == null ? white : alpha.drawnHandle(), alpha == null ? Sampling.LINEAR : alpha.sampling);
		fill.float(fill.alphaCutoff, material.alphaCutoff);
		fill.matrix2D(fill.textureTransform, material.textureTransform);
		fill.integer(fill.vertexColors, material.vertexColors ? 1 : 0);
		fill.integer(fill.skinned, skinned ? 1 : 0);
		fill.integer(fill.boneOffset, boneOffset);
		fill.integer(fill.morphTargetCount, 0);
		if (skinned && boneTexture != 0)
			fill.texture(fill.boneTexture, boneTexture, Sampling.NEAREST);
		fill.planes(batch.clipPlanes);
		fill.matrix(fill.normalMatrix, Batch3D.identity);
		if (boneTexture != 0 && uploaded.indexOf(boneTexture) < 0) {
			// The palette is uploaded before the color pass that first reads it; the shadow passes come before it.
			uploaded.push(boneTexture);
			for (chunk in batch.paletteChunks)
				if (chunk.handle == boneTexture) {
					var graphics = renderer.graphics;
					passes[0].updates.push(() -> graphics.updateTexture(chunk.handle, 0, 0, 256, chunk.rows, chunk.bytes));
				}
		}
		return fill;
	}

	/** Records a caster's draw into a pass, noting the textures it reads. */
	function record(pass:RenderPass, draw:RenderDraw, fill:RenderFill):Void {
		fill.values.capture(draw.snapshot);
		for (t in draw.snapshot.textures)
			if (t != 0)
				renderer.reads.set(t, true);
		pass.addDraw(draw);
	}

	/** Draws a mesh's depth into each map whose volume holds it, placed, skinned and cut as its color draw is. */
	function castMesh(mesh:GpuMesh3D, material:Material3D, transform:Matrix3D, state:Null<MeshState3D>, bounds:Bounds3D, skinning:Null<Array<Matrix3D>>,
			boneTexture:Int, boneOffset:Int):Void {
		if (!casts(material))
			return;
		if (mesh.disposed)
			throw "helix-render: a draw of a disposed mesh";
		var count = mesh.indexed ? mesh.triangleCount * 3 : mesh.vertexCount - mesh.vertexCount % 3;
		if (count <= 0)
			return;
		Batch3D.transformBox(bounds, transform, box);
		var reached = false;
		for (k in 0...mapCount)
			if (volumes[k].intersectsBounds(box))
				reached = true;
		if (!reached)
			return;
		var skinned = skinning != null && mesh.hasJoints;
		if (skinned && boneTexture == 0 && batch.fillFor(depthShader).boneTexture.declared) {
			boneTexture = batch.bones(skinning);
			boneOffset = batch.paletteOffset;
		}
		var fill = fillCaster(material, skinned, boneTexture, boneOffset);
		fill.matrix(fill.model, transform);
		var cull = state != null && state.cull != null ? state.cull : material.cull;
		var spec = renderer.pipelineFor(fill.shader, stateFor(mesh.indexBuffer != 0, cull), mesh.layout);
		for (k in 0...mapCount) {
			if (!volumes[k].intersectsBounds(box))
				continue;
			fill.matrix(fill.modelViewProjection, Matrix3D.compose(transform, matrices[k], scratch));
			var d = renderer.makeDraw(spec);
			d.setBuffer(0, mesh.buffer);
			d.setBuffer(1, batch.identityInstance);
			d.indexBuffer = mesh.indexBuffer;
			d.first = 0;
			d.count = count;
			record(passes[k], d, fill);
		}
	}

	/** Draws a mesh's instanced copies' depth into every map, those copies a map's volume holds. */
	function castInstanced(mesh:GpuMesh3D, material:Material3D, transforms:Array<Matrix3D>, parent:Null<Matrix3D>, firstIndex:Int, copyCount:Int):Void {
		if (!casts(material))
			return;
		if (mesh.disposed)
			throw "helix-render: a draw of a disposed mesh";
		var count = mesh.indexed ? mesh.triangleCount * 3 : mesh.vertexCount - mesh.vertexCount % 3;
		if (count <= 0)
			return;
		var stream = batch.instances, first = stream.count, kept = 0;
		for (i in firstIndex...firstIndex + copyCount) {
			var copy = transforms[i];
			Batch3D.transformBox(mesh.bounds, parent == null ? copy : Matrix3D.compose(copy, parent, scratch), box);
			var reached = false;
			for (k in 0...mapCount)
				if (volumes[k].intersectsBounds(box))
					reached = true;
			if (!reached)
				continue;
			var at = stream.reserve(1), b = stream.bytes, m = copy.values;
			b.blit(at, batch.instanceTemplate, 0, GpuMesh3D.INSTANCE_STRIDE);
			for (k in 0...16)
				b.setFloat(at + k * 4, m[k]);
			kept++;
		}
		if (kept == 0)
			return;
		var model = parent == null ? Batch3D.identity : parent;
		var fill = fillCaster(material, false, 0, 0);
		fill.matrix(fill.model, model);
		var spec = renderer.pipelineFor(fill.shader, stateFor(mesh.indexBuffer != 0, material.cull), mesh.layout);
		for (k in 0...mapCount) {
			fill.matrix(fill.modelViewProjection, Matrix3D.compose(model, matrices[k], scratch));
			var d = renderer.makeDraw(spec);
			d.setBuffer(0, mesh.buffer);
			d.setBuffer(1, 0, stream);
			d.indexBuffer = mesh.indexBuffer;
			d.first = 0;
			d.count = count;
			d.firstInstance = first;
			d.instanceCount = kept;
			record(passes[k], d, fill);
		}
	}
}
