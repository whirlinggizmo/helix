package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.graphics.Color;
import helix.graphics.IGraphics;
import helix.texture.Sampling;
import helix.graphics.SpriteEffect;
import helix.math.Bounds3D;
import helix.texture.Texture2D;

/** A Renderer3D's sprites, texts (a text a sprite a glyph, in its plane) and emitters (an instanced draw each, with the particle3d program),
	drawn with the sprite3d program: each draw it collects the sprites in view (culled by the sphere their quad can
	reach), sorts them (opaque and masked ones by texture and effect; blended ones back to front; added ones by texture and effect), writes
	their records (where the pivot goes and the facing, size and pivot, texture region, their own axes, the alpha mode, the tint) in that order
	into one upload, and draws each run of a texture and effect as one instanced draw (through the effect's sprite3D variant for a sprite with
	one): the opaque ones after the opaque models, the blended ones among the see-through models (fed to it back to front), the added ones
	last. A camera-facing sprite's axes are the camera's, uniforms of the draw. */
@:noCompletion
@:allow(helix)
class Sprites3D {
	static inline var RECORD_FLOATS = 24;

	var gpu:IGraphics;
	// By phase: 0 opaque and masked, 1 blended, 2 added.
	var pipelines:helix.graphics.Pipelines;
	var corners:Int;
	var indices:Int;
	var capacity = 256;
	var instanceBuffer:Int;
	var records:Bytes;
	var uniforms = Bytes.alloc(Sprite3DProgram.vertexUniformBytes);
	var items:Array<SpriteItem> = [];
	var drawn:Array<SpriteItem> = [];
	var count = 0;
	// Where each phase's items start in drawn, and the next blended one to draw.
	var blendStart = 0;
	var addStart = 0;
	var nextBlend = 0;
	var draws = 0;
	var font:Null<helix.font.Font>;
	// Emitters: the draw's particles in one upload, and those in view, sorted, each its first record and count.
	var particleCapacity = 1024;
	var particleBuffer:Int;
	var particleRecords:Bytes;
	var emitters:Array<EmitterItem> = [];
	var emitterCount = 0;
	var dt = 0.;
	// The stage's time this draw (what effects see), and each effect drawn a key, so the sort groups a texture's sprites by it.
	var time = 0.;
	var effectKeys = new haxe.ds.ObjectMap<SpriteEffect, Int>();
	var nextEffectKey = 1;
	var nextEmitter = 0;
	var emitterBlendStart = 0;
	var emitterAddStart = 0;
	// The camera's axes this draw, and the upright facing's right.
	var cameraRight = [1., 0, 0];
	var cameraUp = [0., 1, 0];
	var upright = [1., 0, 0];

	/** Sprites on gpu: their quad and instance buffer. */
	function new(gpu:IGraphics) {
		this.gpu = gpu;
		pipelines = helix.graphics.Pipelines.of(gpu);
		var quad = Bytes.alloc(4 * Sprite3DProgram.stride), at = 0;
		for (c in [-.5, -.5, .5, -.5, .5, .5, -.5, .5]) {
			quad.setFloat(at, c);
			at += 4;
		}
		corners = gpu.createStaticBuffer(quad, quad.length, false);
		var order = Bytes.alloc(24);
		for (i in 0...6)
			order.setInt32(i * 4, [0, 1, 2, 0, 2, 3][i]);
		indices = gpu.createStaticBuffer(order, 24, true);
		instanceBuffer = gpu.createBuffer(capacity * Sprite3DProgram.instanceStride);
		records = Bytes.alloc(capacity * Sprite3DProgram.instanceStride);
		particleBuffer = gpu.createBuffer(particleCapacity * Particle3DProgram.instanceStride);
		particleRecords = Bytes.alloc(particleCapacity * Particle3DProgram.instanceStride);
	}

	/** Sprites drawn by the last draw (in view). */
	var drawnSpriteCount(get, never):Int;

	function get_drawnSpriteCount():Int
		return count;

	/** Draws of the last draw: one a run of a texture and effect. */
	var drawCallCount(get, never):Int;

	function get_drawCallCount():Int
		return draws;

	/** Starts a draw at time, seconds of the stage's clock (what effects see), dt after the last: no sprites or emitters yet. */
	function begin(dt:Float, time:Float):Void {
		count = 0;
		draws = 0;
		emitterCount = 0;
		this.dt = dt;
		this.time = time;
		effectKeys.clear();
		nextEffectKey = 1;
	}

	/** Advances node's emitter (its world matrix up to date) by the draw's dt, where the node is now, unless still (under a paused node:
		held as it is), and adds it to the draw when it has particles to draw. Not culled: particles reach past where it is. */
	function visitEmitter(node:Particles3D, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float, forwardZ:Float, still = false):Void {
		var emitter = node.emitter, w = node.worldMatrix;
		if (!still)
			advanceEmitter(node);
		if (!emitter.drawable)
			return;
		if (emitterCount == emitters.length)
			emitters.push(new EmitterItem());
		var it = emitters[emitterCount++];
		it.emitter = emitter;
		it.phase = switch emitter.alphaMode {
			case Blend: 1;
			case Add: 2;
			case _: 0;
		};
		it.depth = (w.get(12) - eyeX) * forwardX + (w.get(13) - eyeY) * forwardY + (w.get(14) - eyeZ) * forwardZ;
		it.order = emitterCount;
	}

	/** Moves an emitter node's particles on by this draw's time, at its place, without drawing them (a hidden emitter's). */
	function advanceEmitter(node:Particles3D):Void {
		var w = node.worldMatrix;
		node.emitter.advance(dt, w.get(12), w.get(13), w.get(14));
	}

	// The font a text without its own draws in: the built-in one, made when first needed.
	function builtIn():helix.font.Font {
		if (font == null)
			font = helix.font.Font.builtIn(gpu);
		return font;
	}

	function item():SpriteItem {
		if (count == items.length)
			items.push(new SpriteItem());
		var it = items[count];
		it.order = count;
		count++;
		return it;
	}

	/** Adds a text's glyphs (its world matrix up to date) unless it is out of view: each a sprite in the text's plane, blended. */
	function visitText(node:Text3D, planes:Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		var text = node.text;
		if (text.length == 0)
			return;
		var font = node.font != null ? node.font : builtIn(),
			size = node.textSize;
		node.drawnFont = font;
		var w = node.worldMatrix, x = w.get(12), y = w.get(13), z = w.get(14);
		var width = font.measure(text, size), unit = size / font.size;
		// Culled by its bounds (measureQuad, Node3D.computeBounds's).
		measureQuad(w, node.facing, node.pivotX, node.pivotY, width, size, culling.clear());
		if (!inView(planes, culling))
			return;
		var depth = (x - eyeX) * forwardX + (y - eyeY) * forwardY + (z - eyeZ) * forwardZ;
		// From the block's top-left (the pivot's share of its size away), the pen on the baseline.
		var penX = -node.pivotX * width,
			top = -node.pivotY * size,
			baseline = top + font.ascent * unit;
		for (i in 0...text.length) {
			var code = text.charCodeAt(i), glyph = font.getGlyph(code);
			if (glyph != null) {
				if (glyph.width > 0) {
					var it = item();
					it.node = node;
					it.sprite = null;
					it.facing = node.facing;
					it.tint = node.color;
					it.texture = font.texture;
					it.effect = null;
					it.effectKey = 0;
					it.phase = 1;
					it.depth = depth;
					it.glyph = true;
					it.distanceField = font.distanceField;
					it.u0 = glyph.u0;
					it.v0 = glyph.v0;
					it.u1 = glyph.u1;
					it.v1 = glyph.v1;
					it.gx = penX + glyph.x * unit;
					it.gy = baseline + glyph.y * unit;
					it.gw = glyph.width * unit;
					it.gh = glyph.height * unit;
				}
				penX += glyph.advance * unit;
			}
			if (i + 1 < text.length)
				penX += font.getKerning(code, text.charCodeAt(i + 1)) * unit;
		}
	}

	/** Adds a sprite (its world matrix up to date) unless it is out of view: planes are the camera's six (a, b, c, d each), and its depth
		is along forward from the eye. */
	function visit(node:Sprite3D, planes:Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		var texture = node.texture;
		if (texture == null)
			return;
		var w = node.worldMatrix;
		var x = w.get(12), y = w.get(13), z = w.get(14);
		// Culled by its bounds (measureQuad, Node3D.computeBounds's).
		measureQuad(w, node.facing, node.pivotX, node.pivotY, node.spriteWidth, node.spriteHeight, culling.clear());
		if (!inView(planes, culling))
			return;
		var it = item();
		it.node = node;
		it.sprite = node;
		it.facing = node.facing;
		it.tint = node.tint;
		it.texture = texture;
		it.effect = node.effect;
		it.effectKey = 0;
		if (node.effect != null) {
			var key = effectKeys.get(node.effect);
			if (key == null)
				effectKeys.set(node.effect, key = nextEffectKey++);
			it.effectKey = key;
		}
		it.glyph = false;
		it.phase = switch node.alphaMode {
			case Blend: 1;
			case Add: 2;
			case _: 0;
		};
		it.depth = (x - eyeX) * forwardX + (y - eyeY) * forwardY + (z - eyeZ) * forwardZ;
	}

	/** Takes camera's axes for the picks that follow (pickSprite, pickText), as it shows the sprites now. */
	function preparePick(camera:Camera3D):Void
		cameraAxes(camera, camera.forwardX, camera.forwardY, camera.forwardZ);

	/** Tests a sprite against ray as the camera given to preparePick shows it (its quad, facing as drawn): the distance along the ray, recorded
		in hit when nearer than best, else best. A sprite without a texture, or a see-through one (blended or added, its tint's alpha under a
		half), isn't hit. */
	function pickSprite(node:Sprite3D, ray:Ray3D, best:Float, hit:PickHit3D):Float {
		if (node.texture == null)
			return best;
		if ((node.alphaMode == Blend || node.alphaMode == Add) && Color.getAlpha(node.tint) < 128)
			return best;
		return pickQuad(node, node.facing, node.pivotX, node.pivotY, node.spriteWidth, node.spriteHeight, ray, best, hit);
	}

	/** Tests a text against ray as the camera given to preparePick shows it (its whole block, facing as drawn), as pickSprite. A text without
		text, or a faint one (its color's alpha under a half), isn't hit. */
	function pickText(node:Text3D, ray:Ray3D, best:Float, hit:PickHit3D):Float {
		if (node.text.length == 0 || Color.getAlpha(node.color) < 128)
			return best;
		var font = node.font != null ? node.font : builtIn();
		node.drawnFont = font;
		return pickQuad(node, node.facing, node.pivotX, node.pivotY, font.measure(node.text, node.textSize), node.textSize, ray, best, hit);
	}

	/** The four corners of a sprite's quad in the world, as the camera given to preparePick shows it and a pick tests it, into out (x, y, z each,
		top-left, top-right, bottom-right, bottom-left); false, out unchanged, for one a pick doesn't hit (as pickSprite). */
	function spriteQuad(node:Sprite3D, out:Array<Float>):Bool {
		if (node.texture == null || (node.alphaMode == Blend || node.alphaMode == Add) && Color.getAlpha(node.tint) < 128)
			return false;
		quadCorners(node, node.facing, node.pivotX, node.pivotY, node.spriteWidth, node.spriteHeight, out);
		return true;
	}

	/** A text's block as spriteQuad gives a sprite's quad; false for one a pick doesn't hit (as pickText). */
	function textQuad(node:Text3D, out:Array<Float>):Bool {
		if (node.text.length == 0 || Color.getAlpha(node.color) < 128)
			return false;
		var font = node.font != null ? node.font : builtIn();
		quadCorners(node, node.facing, node.pivotX, node.pivotY, font.measure(node.text, node.textSize), node.textSize, out);
		return true;
	}

	// The axes of a quad width x tall world units (before its scale), facing as given, into quadRight and quadUp; its size as scaled into
	// quadWidth and quadTall, and the scales along them into quadScaleX and quadScaleUp.
	var quadRight:Array<Float> = [1, 0, 0];
	var quadUp:Array<Float> = [0, 1, 0];
	var quadWidth = 0.;
	var quadTall = 0.;
	var quadScaleX = 0.;
	var quadScaleUp = 0.;

	function placeQuad(node:Node3D, facing:SpriteFacing3D, width:Float, tall:Float):Void {
		var w = node.worldMatrix;
		var sx = length(w, 0),
			sy = length(w, 4),
			sz = length(w, 8),
			height = facing == Ground ? sz : sy;
		quadScaleX = sx;
		quadScaleUp = height;
		quadWidth = width * sx;
		quadTall = tall * height;
		switch facing {
			case Camera:
				quadRight = cameraRight;
				quadUp = cameraUp;
			case Upright:
				quadRight = upright;
				quadUp = [0, 1, 0];
			case Ground:
				quadRight = [w.get(0) / sx, w.get(1) / sx, w.get(2) / sx];
				quadUp = [-w.get(8) / sz, -w.get(9) / sz, -w.get(10) / sz];
			case _:
				quadRight = [w.get(0) / sx, w.get(1) / sx, w.get(2) / sx];
				quadUp = [w.get(4) / sy, w.get(5) / sy, w.get(6) / sy];
		}
	}

	// A quad's corners about its pivot (placeQuad's), into out as spriteQuad gives them.
	function quadCorners(node:Node3D, facing:SpriteFacing3D, pivotX:Float, pivotY:Float, width:Float, tall:Float, out:Array<Float>):Void {
		placeQuad(node, facing, width, tall);
		var w = node.worldMatrix, right = quadRight, up = quadUp;
		var left = -pivotX * quadWidth,
			rightEdge = (1 - pivotX) * quadWidth,
			top = pivotY * quadTall,
			bottom = (pivotY - 1) * quadTall;
		var k = 0;
		for (corner in [[left, top], [rightEdge, top], [rightEdge, bottom], [left, bottom]])
			for (axis in 0...3)
				out[k++] = w.get(12 + axis) + right[axis] * corner[0] + up[axis] * corner[1];
	}

	// A quad width x tall world units (before its scale) about its pivot, facing as given, against ray.
	function pickQuad(node:Node3D, facing:SpriteFacing3D, pivotX:Float, pivotY:Float, width:Float, tall:Float, ray:Ray3D, best:Float, hit:PickHit3D):Float {
		placeQuad(node, facing, width, tall);
		var w = node.worldMatrix, right = quadRight, up = quadUp;
		var sx = quadScaleX, height = quadScaleUp;
		width = quadWidth;
		tall = quadTall;
		// Where the ray meets its plane, then whether that's inside its rectangle about the pivot.
		var nx = right[1] * up[2] - right[2] * up[1],
			ny = right[2] * up[0] - right[0] * up[2],
			nz = right[0] * up[1] - right[1] * up[0];
		var dx = ray.directionX, dy = ray.directionY, dz = ray.directionZ;
		var facingRay = nx * dx + ny * dy + nz * dz;
		if (Math.abs(facingRay) < 1e-9)
			return best;
		var px = w.get(12),
			py = w.get(13),
			pz = w.get(14),
			ox = ray.originX,
			oy = ray.originY,
			oz = ray.originZ;
		var t = ((px - ox) * nx + (py - oy) * ny + (pz - oz) * nz) / facingRay;
		if (t < 0 || t >= best)
			return best;
		var hx = ox + dx * t - px,
			hy = oy + dy * t - py,
			hz = oz + dz * t - pz;
		var a = hx * right[0] + hy * right[1] + hz * right[2],
			b = hx * up[0] + hy * up[1] + hz * up[2];
		if (a < -pivotX * width || a > (1 - pivotX) * width || b < (pivotY - 1) * tall || b > pivotY * tall)
			return best;
		var nl = Math.sqrt(nx * nx + ny * ny + nz * nz),
			sign = facingRay > 0 ? -1 : 1;
		hit.record(node, t, ox + dx * t, oy + dy * t, oz + dz * t, sx > 0 ? a / sx : 0, height > 0 ? b / height : 0, 0, sign * nx / nl, sign * ny / nl,
			sign * nz / nl);
		return t;
	}

	/** The box a quad width x tall (before its scale) about its pivot can reach, placed by world, into out: facing the camera, whichever
		way that is (the box around the sphere it turns in); upright, turning about y (the box around the cylinder it turns in); on the ground or
		free, exactly its corners' box, as it's turned. */
	static function measureQuad(world:Mat4, facing:SpriteFacing3D, pivotX:Float, pivotY:Float, width:Float, tall:Float, out:Bounds3D):Void {
		var x = world.get(12), y = world.get(13), z = world.get(14);
		switch facing {
			case Camera:
				var scale = Math.max(length(world, 0), Math.max(length(world, 4), length(world, 8)));
				var fx = Math.max(pivotX, 1 - pivotX) * width,
					fy = Math.max(pivotY, 1 - pivotY) * tall;
				var r = Math.sqrt(fx * fx + fy * fy) * scale;
				out.expand(x - r, y - r, z - r).expand(x + r, y + r, z + r);
			case Upright:
				var r = Math.max(pivotX, 1 - pivotX) * width * length(world, 0),
					up = tall * length(world, 4);
				out.expand(x - r, y + (pivotY - 1) * up, z - r).expand(x + r, y + pivotY * up, z + r);
			case _:
				// Its corners in its node's space: free in the x-y plane, on the ground in x and -z.
				for (corner in 0...4) {
					var a = (corner & 1 == 0 ? -pivotX : 1 - pivotX) * width,
						b = (corner < 2 ? pivotY : pivotY - 1) * tall;
					var lx = a, ly = facing == Ground ? 0 : b, lz = facing == Ground ? -b : 0.;
					out.expand(world.get(0) * lx
						+ world.get(4) * ly
						+ world.get(8) * lz
						+ x, world.get(1) * lx
						+ world.get(5) * ly
						+ world.get(9) * lz
						+ y,
						world.get(2) * lx
						+ world.get(6) * ly
						+ world.get(10) * lz
						+ z);
				}
		}
	}

	// The box a sprite or text in view is culled by, reused.
	static var culling = new Bounds3D();

	// Whether box reaches inside every one of the camera's six planes (a, b, c, d each): its corner farthest along each plane's normal.
	static function inView(planes:Vector<Float>, box:Bounds3D):Bool {
		for (p in 0...6) {
			var a = planes[p * 4],
				b = planes[p * 4 + 1],
				c = planes[p * 4 + 2];
			if (a * (a > 0 ? box.maxX : box.minX)
				+ b * (b > 0 ? box.maxY : box.minY)
				+ c * (c > 0 ? box.maxZ : box.minZ)
				+ planes[p * 4 + 3] < 0)
				return false;
		}
		return true;
	}

	static inline function length(w:Mat4, column:Int):Float
		return Math.sqrt(w.get(column) * w.get(column) + w.get(column + 1) * w.get(column + 1) + w.get(column + 2) * w.get(column + 2));

	static function compare(a:SpriteItem, b:SpriteItem):Int {
		if (a.phase != b.phase)
			return a.phase - b.phase;
		if (a.phase == 1)
			return a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : a.order - b.order;
		if (a.texture.handle != b.texture.handle)
			return a.texture.handle - b.texture.handle;
		if (a.effectKey != b.effectKey)
			return a.effectKey - b.effectKey;
		return a.order - b.order;
	}

	/** Sorts the sprites collected, writes their records into one upload and the draw's uniforms: viewProjection, and the camera's right and up
		(from forward and its up), and the upright facing's right. */
	function prepare(viewProjection:Mat4, camera:Camera3D, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		cameraAxes(camera, forwardX, forwardY, forwardZ);
		viewProjection.writeTo(uniforms);
		var values = cameraRight.concat([0]).concat(cameraUp).concat([0]).concat(upright).concat([0]);
		for (i in 0...values.length)
			uniforms.setFloat(64 + i * 4, values[i]);
		finishPrepare(viewProjection);
	}

	// The camera's right is forward across its up; its up, right across forward; upright, the right flattened onto the ground.
	function cameraAxes(camera:Camera3D, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		var ux = camera.upX, uy = camera.upY, uz = camera.upZ;
		var rx = forwardY * uz - forwardZ * uy,
			ry = forwardZ * ux - forwardX * uz,
			rz = forwardX * uy - forwardY * ux;
		var rl = Math.sqrt(rx * rx + ry * ry + rz * rz);
		if (rl > 0) {
			rx /= rl;
			ry /= rl;
			rz /= rl;
		}
		var hl = Math.sqrt(rx * rx + rz * rz);
		cameraRight = [rx, ry, rz];
		cameraUp = [
			ry * forwardZ - rz * forwardY,
			rz * forwardX - rx * forwardZ,
			rx * forwardY - ry * forwardX
		];
		upright = [hl > 0 ? rx / hl : 1, 0, hl > 0 ? rz / hl : 0];
	}

	function finishPrepare(viewProjection:Mat4):Void {
		drawn.resize(count);
		for (i in 0...count)
			drawn[i] = items[i];
		drawn.sort((a, b) -> compare(a, b));
		blendStart = addStart = count;
		for (i in 0...count) {
			if (drawn[i].phase >= 1 && blendStart == count)
				blendStart = i;
			if (drawn[i].phase == 2) {
				addStart = i;
				break;
			}
		}
		nextBlend = blendStart;
		if (count > capacity) {
			while (capacity < count)
				capacity *= 2;
			gpu.destroyBuffer(instanceBuffer);
			instanceBuffer = gpu.createBuffer(capacity * Sprite3DProgram.instanceStride);
			records = Bytes.alloc(capacity * Sprite3DProgram.instanceStride);
		}
		for (i in 0...count)
			write(i, drawn[i]);
		if (count > 0)
			gpu.updateBuffer(instanceBuffer, records, count * Sprite3DProgram.instanceStride);
		prepareEmitters(viewProjection);
	}

	// The emitters in view sorted as sprites are (by phase; blended back to front), their particles in one upload, and each its uniforms.
	function prepareEmitters(viewProjection:Mat4):Void {
		var list = emitters.slice(0, emitterCount);
		list.sort((a,
				b) -> a.phase != b.phase ? a.phase - b.phase : a.phase == 1 ? (a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : a.order - b.order) : a.order
				- b.order);
		for (i in 0...emitterCount)
			emitters[i] = list[i];
		var total = 0;
		for (i in 0...emitterCount)
			total += emitters[i].emitter.particleCount;
		if (total > particleCapacity) {
			while (particleCapacity < total)
				particleCapacity *= 2;
			gpu.destroyBuffer(particleBuffer);
			particleBuffer = gpu.createBuffer(particleCapacity * Particle3DProgram.instanceStride);
			particleRecords = Bytes.alloc(particleCapacity * Particle3DProgram.instanceStride);
		}
		var at = 0;
		emitterBlendStart = emitterAddStart = emitterCount;
		for (i in 0...emitterCount) {
			var it = emitters[i];
			if (it.phase >= 1 && emitterBlendStart == emitterCount)
				emitterBlendStart = i;
			if (it.phase == 2 && emitterAddStart == emitterCount)
				emitterAddStart = i;
			it.first = at;
			it.count = it.emitter.writeRecords(particleRecords, at * Particle3DProgram.instanceStride);
			at += it.count;
			if (it.uniforms == null)
				it.uniforms = Bytes.alloc(Particle3DProgram.vertexUniformBytes);
			it.emitter.writeUniforms(it.uniforms, viewProjection, cameraRight, cameraUp);
		}
		nextEmitter = emitterBlendStart;
		if (at > 0)
			gpu.updateBuffer(particleBuffer, particleRecords, at * Particle3DProgram.instanceStride);
	}

	function drawEmitter(it:EmitterItem):Void {
		var texture = it.emitter.texture;
		gpu.draw(pipelines.particle3D(cast it.phase), [corners, particleBuffer], indices, 0, 6, it.first, it.count, [texture.handle], [texture.sampling],
			[it.uniforms]);
		draws++;
	}

	function write(index:Int, item:SpriteItem):Void {
		var node = item.sprite,
			w = item.node.worldMatrix,
			at = index * Sprite3DProgram.instanceStride,
			texture = item.texture;
		inline function put(offset:Int, a:Float, b:Float, c:Float, d:Float):Void {
			records.setFloat(at + offset, a);
			records.setFloat(at + offset + 4, b);
			records.setFloat(at + offset + 8, c);
			records.setFloat(at + offset + 12, d);
		}
		var facing = item.facing;
		var sx = length(w, 0), sy = length(w, 4), sz = length(w, 8);
		if (item.glyph) {
			writeGlyph(at, item, w, facing, sx, sy, sz);
			return;
		}
		put(Sprite3DProgram.positionOffset, w.get(12), w.get(13), w.get(14), facing == Camera ? 0 : facing == Upright ? 1 : 2);
		// Ground lies along the node's z, its texture's top toward -z; anything else along its y.
		var height = facing == Ground ? sz : sy;
		put(Sprite3DProgram.sizeOffset, node.spriteWidth * sx, node.spriteHeight * height, node.pivotX, node.pivotY);
		var rx = node.regionX,
			ry = node.regionY,
			rw = node.regionWidth,
			rh = node.regionHeight,
			tw = texture.width,
			th = texture.height;
		if (rw > 0 && rh > 0)
			put(Sprite3DProgram.regionOffset, rx / tw, ry / th, (rx + rw) / tw, (ry + rh) / th);
		else
			put(Sprite3DProgram.regionOffset, 0, 0, 1, 1);
		put(Sprite3DProgram.rightOffset, sx > 0 ? w.get(0) / sx : 1, sx > 0 ? w.get(1) / sx : 0, sx > 0 ? w.get(2) / sx : 0, 0);
		var alpha = switch node.alphaMode {
			case Opaque: -1.;
			case Mask: Math.max(node.alphaCutoff, 1e-4);
			case _: 0.;
		};
		if (facing == Ground)
			put(Sprite3DProgram.upOffset, sz > 0 ? -w.get(8) / sz : 0, sz > 0 ? -w.get(9) / sz : 0, sz > 0 ? -w.get(10) / sz : -1, alpha);
		else
			put(Sprite3DProgram.upOffset, sy > 0 ? w.get(4) / sy : 0, sy > 0 ? w.get(5) / sy : 1, sy > 0 ? w.get(6) / sy : 0, alpha);
		var tint = item.tint;
		put(Sprite3DProgram.tintOffset, Color.getRed(tint) / 255, Color.getGreen(tint) / 255, Color.getBlue(tint) / 255, Color.getAlpha(tint) / 255);
	}

	// A glyph: a sprite with its own axes (the text's plane), its top-left at its place in the text, tinted as the text (a distance field
	// marked in the alpha).
	function writeGlyph(at:Int, item:SpriteItem, w:Mat4, facing:SpriteFacing3D, sx:Float, sy:Float, sz:Float):Void {
		var right:Array<Float>, up:Array<Float>, height = sy;
		switch facing {
			case Camera:
				right = cameraRight;
				up = cameraUp;
			case Upright:
				right = upright;
				up = [0, 1, 0];
			case Ground:
				right = [w.get(0) / sx, w.get(1) / sx, w.get(2) / sx];
				up = [-w.get(8) / sz, -w.get(9) / sz, -w.get(10) / sz];
				height = sz;
			case _:
				right = [w.get(0) / sx, w.get(1) / sx, w.get(2) / sx];
				up = [w.get(4) / sy, w.get(5) / sy, w.get(6) / sy];
		}
		var ox = item.gx * sx, oy = -item.gy * height;
		inline function put(offset:Int, a:Float, b:Float, c:Float, d:Float):Void {
			records.setFloat(at + offset, a);
			records.setFloat(at + offset + 4, b);
			records.setFloat(at + offset + 8, c);
			records.setFloat(at + offset + 12, d);
		}
		put(Sprite3DProgram.positionOffset, w.get(12)
			+ right[0] * ox + up[0] * oy, w.get(13)
			+ right[1] * ox + up[1] * oy,
			w.get(14)
			+ right[2] * ox + up[2] * oy, 2);
		put(Sprite3DProgram.sizeOffset, item.gw * sx, item.gh * height, 0, 0);
		put(Sprite3DProgram.regionOffset, item.u0, item.v0, item.u1, item.v1);
		put(Sprite3DProgram.rightOffset, right[0], right[1], right[2], 0);
		put(Sprite3DProgram.upOffset, up[0], up[1], up[2], 0);
		var tint = item.tint;
		put(Sprite3DProgram.tintOffset, Color.getRed(tint) / 255, Color.getGreen(tint) / 255, Color.getBlue(tint) / 255,
			Color.getAlpha(tint) / 255 + (item.distanceField ? 2 : 0));
	}

	// Draws drawn[from..to) as runs of a texture and effect through phase's pipeline: the framework's, or the effect's sprite3D variant's.
	function drawRange(from:Int, to:Int, phase:Int):Void {
		var i = from;
		while (i < to) {
			var last = i, texture = drawn[i].texture, effect = drawn[i].effect;
			while (last + 1 < to && drawn[last + 1].texture == texture && drawn[last + 1].effect == effect)
				last++;
			if (effect != null) {
				var program = effect.shader.sprite3D, textures = [], samplings = [];
				var blocks = effect.bind(program, texture, texture.sampling, time, uniforms, textures, samplings);
				gpu.draw(pipelines.spriteEffect3D(program.handle, cast phase), [corners, instanceBuffer], indices, 0, 6, i, last - i + 1, textures, samplings,
					blocks);
			} else
				gpu.draw(pipelines.sprite3D(cast phase), [corners, instanceBuffer], indices, 0, 6, i, last - i + 1, [texture.handle], [texture.sampling],
					[uniforms]);
			draws++;
			i = last + 1;
		}
	}

	/** Draws the opaque and masked sprites, then emitters. */
	function drawOpaque():Void {
		drawRange(0, blendStart, 0);
		for (i in 0...emitterBlendStart)
			drawEmitter(emitters[i]);
	}

	/** Draws the blended sprites and emitters farther than depth along the view not yet drawn, back to front together: called before each
		see-through model run. */
	function drawBlendedBeyond(depth:Float):Void
		while (true) {
			var sprite = nextBlend < addStart ? drawn[nextBlend].depth : Math.NEGATIVE_INFINITY,
				emitter = nextEmitter < emitterAddStart ? emitters[nextEmitter].depth : Math.NEGATIVE_INFINITY;
			if (Math.max(sprite, emitter) <= depth)
				return;
			if (sprite >= emitter) {
				// The sprites farther than both the next emitter and depth, at least one.
				var end = nextBlend + 1, limit = Math.max(emitter, depth);
				while (end < addStart && drawn[end].depth > limit)
					end++;
				drawRange(nextBlend, end, 1);
				nextBlend = end;
			} else
				drawEmitter(emitters[nextEmitter++]);
		}

	/** Draws the blended sprites and emitters left, then the added ones. */
	function drawRest():Void {
		drawBlendedBeyond(Math.NEGATIVE_INFINITY);
		drawRange(addStart, count, 2);
		for (i in emitterAddStart...emitterCount)
			drawEmitter(emitters[i]);
	}

	/** Frees its buffers and built-in font. */
	function destroy():Void {
		if (font != null)
			font.destroy(gpu);
		gpu.destroyBuffer(corners);
		gpu.destroyBuffer(indices);
		gpu.destroyBuffer(instanceBuffer);
		gpu.destroyBuffer(particleBuffer);
	}

	// Gives renderer its sprites if it has none (Renderer3D.sprites): the first sprite, text or emitter it lists does, so a program that
	// makes none links none of this.

	@:allow(helix.render3d)
	static function attach(renderer:Renderer3D):Void {
		if (renderer.sprites != null)
			return;
		var sprites = new Sprites3D(@:privateAccess renderer.gpu);
		renderer.sprites = {
			part: sprites,
			begin: (dt, time) -> sprites.begin(dt, time),
			prepare: (viewProjection, camera, forwardX, forwardY, forwardZ) -> sprites.prepare(viewProjection, camera, forwardX, forwardY, forwardZ),
			preparePick: camera -> sprites.preparePick(camera),
			drawOpaque: () -> sprites.drawOpaque(),
			drawBlendedBeyond: depth -> sprites.drawBlendedBeyond(depth),
			drawRest: () -> sprites.drawRest(),
			drawnSpriteCount: () -> sprites.drawnSpriteCount,
			drawCallCount: () -> sprites.drawCallCount,
			destroy: () -> sprites.destroy()
		};
	}
}

/** A sprite in view this draw. Pooled. */
private class SpriteItem {
	/** Its node: a sprite, or the text the glyph is of. */
	public var node:Node3D;

	/** Its node as a sprite; null for a glyph. */
	public var sprite:Null<Sprite3D>;

	/** How it faces: its sprite's or text's. */
	public var facing:SpriteFacing3D = Camera;

	/** Its tint, 0xAARRGGBB: its sprite's, or its text's color. */
	public var tint = 0xffffffff;

	/** Its texture. */
	public var texture:Texture2D;

	/** The effect it draws through (its sprite's), or null. */
	public var effect:Null<SpriteEffect>;

	/** Its effect's key this draw (0 for none), which the sort groups by. */
	public var effectKey = 0;

	/** 0 opaque or masked, 1 blended, 2 added. */
	public var phase = 0;

	/** Its pivot's distance along the camera's view. */
	public var depth = 0.;

	/** Its place in the walk: ties keep it. */
	public var order = 0;

	/** Whether it is a text's glyph (and so the fields below are its). */
	public var glyph = false;

	/** Whether the glyph's texture is a distance field. */
	public var distanceField = false;

	/** The glyph's texture region. */
	public var u0 = 0.;

	/** The region's top. */
	public var v0 = 0.;

	/** The region's right. */
	public var u1 = 0.;

	/** The region's bottom. */
	public var v1 = 0.;

	/** The glyph's top-left in the text's plane from its node's position, world units before scale, y down. */
	public var gx = 0.;

	/** Its y, down. */
	public var gy = 0.;

	/** The glyph's width, world units before scale. */
	public var gw = 0.;

	/** Its height. */
	public var gh = 0.;

	/** An empty item, filled by the walk. */
	public function new() {}
}

/** An emitter in view this draw. Pooled. */
private class EmitterItem {
	/** Its emitter. */
	public var emitter:helix.particle.Emitter;

	/** 0 opaque or masked, 1 blended, 2 added. */
	public var phase = 0;

	/** Its place's distance along the camera's view. */
	public var depth = 0.;

	/** Its place in the walk: ties keep it. */
	public var order = 0;

	/** Its first record in the draw's upload. */
	public var first = 0;

	/** Its records there. */
	public var count = 0;

	/** Its draw's uniforms. */
	public var uniforms:Null<Bytes>;

	/** An empty item, filled by the walk. */
	public function new() {}
}
