package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.graphics.IGraphics;
import helix.graphics.Sampling;
import helix.render2d.Texture2D;
import helix.render3d.Node.SpriteAlpha;
import helix.render3d.Node.SpriteFacing;

/** A Stage3D's sprites, drawn with the sprite3d program: each draw it collects the sprites in view (culled by the sphere their quad can
	reach), sorts them (opaque and masked ones by texture; blended ones back to front; added ones by texture), writes their records (where the
	pivot goes and the facing, size and pivot, texture region, their own axes, the alpha mode, the tint) in that order into one upload, and
	draws each run of a texture as one instanced draw: the opaque ones after the opaque models, the blended ones among the see-through models
	(fed to it back to front), the added ones last. A camera-facing sprite's axes are the camera's, uniforms of the draw. */
class Sprites3D {
	static inline var RECORD_FLOATS = 24;

	var gpu:IGraphics;
	// By phase: 0 opaque and masked, 1 blended, 2 added.
	var pipelines:Array<Int>;
	var corners:Int;
	var indices:Int;
	var capacity = 256;
	var instanceBuffer:Int;
	var records:Bytes;
	var uniforms = Bytes.alloc(Sprite3DLayout.vertexUniformBytes);
	var items:Array<SpriteItem> = [];
	var drawn:Array<SpriteItem> = [];
	var count = 0;
	// Where each phase's items start in drawn, and the next blended one to draw.
	var blendStart = 0;
	var addStart = 0;
	var nextBlend = 0;
	var draws = 0;

	/** Sprites on gpu: their pipelines, quad and instance buffer. */
	public function new(gpu:IGraphics) {
		this.gpu = gpu;
		pipelines = [
			gpu.createPipeline(Sprite3D, Opaque),
			gpu.createPipeline(Sprite3D, Alpha),
			gpu.createPipeline(Sprite3D, Additive)
		];
		var quad = Bytes.alloc(4 * Sprite3DLayout.stride), at = 0;
		for (c in [-.5, -.5, .5, -.5, .5, .5, -.5, .5]) {
			quad.setFloat(at, c);
			at += 4;
		}
		corners = gpu.createStaticBuffer(quad, quad.length, false);
		var order = Bytes.alloc(24);
		for (i in 0...6)
			order.setInt32(i * 4, [0, 1, 2, 0, 2, 3][i]);
		indices = gpu.createStaticBuffer(order, 24, true);
		instanceBuffer = gpu.createBuffer(capacity * Sprite3DLayout.instanceStride);
		records = Bytes.alloc(capacity * Sprite3DLayout.instanceStride);
	}

	/** Sprites drawn by the last draw (in view). */
	public function getDrawnCount():Int
		return count;

	/** Draws of the last draw: one a run of a texture. */
	public function getDrawCount():Int
		return draws;

	/** Starts a draw: no sprites yet. */
	public function begin():Void {
		count = 0;
		draws = 0;
	}

	/** Adds node (a sprite, its world matrix up to date) unless it is out of view: planes are the camera's six (a, b, c, d each), and its depth
		is along forward from the eye. */
	public function visit(node:Node, planes:Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		var texture = node.getTexture();
		if (texture == null)
			return;
		var w = node.getWorldMatrix();
		var x = w.get(12), y = w.get(13), z = w.get(14);
		// The sphere the quad can reach about its pivot, as scaled.
		var scale = Math.max(length(w, 0), Math.max(length(w, 4), length(w, 8)));
		var reachX = Math.max(node.getPivotX(), 1 - node.getPivotX()) * node.getSpriteWidth(),
			reachY = Math.max(node.getPivotY(), 1 - node.getPivotY()) * node.getSpriteHeight();
		var radius = Math.sqrt(reachX * reachX + reachY * reachY) * scale;
		for (p in 0...6)
			if (planes[p * 4] * x + planes[p * 4 + 1] * y + planes[p * 4 + 2] * z + planes[p * 4 + 3] < -radius)
				return;
		if (count == items.length)
			items.push(new SpriteItem());
		var item = items[count];
		item.node = node;
		item.texture = texture;
		item.phase = switch node.getAlphaMode() {
			case Blend: 1;
			case Add: 2;
			case _: 0;
		};
		item.depth = (x - eyeX) * forwardX + (y - eyeY) * forwardY + (z - eyeZ) * forwardZ;
		item.order = count;
		count++;
	}

	static inline function length(w:Mat4, column:Int):Float
		return Math.sqrt(w.get(column) * w.get(column) + w.get(column + 1) * w.get(column + 1) + w.get(column + 2) * w.get(column + 2));

	static function compare(a:SpriteItem, b:SpriteItem):Int {
		if (a.phase != b.phase)
			return a.phase - b.phase;
		if (a.phase == 1)
			return a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : a.order - b.order;
		if (a.texture.getHandle() != b.texture.getHandle())
			return a.texture.getHandle() - b.texture.getHandle();
		return a.order - b.order;
	}

	/** Sorts the sprites collected, writes their records into one upload and the draw's uniforms: viewProjection, and the camera's right and up
		(from forward and its up), and the upright facing's right. */
	public function prepare(viewProjection:Mat4, camera:Camera3D, forwardX:Float, forwardY:Float, forwardZ:Float):Void {
		drawn.resize(count);
		for (i in 0...count)
			drawn[i] = items[i];
		drawn.sort(compare);
		blendStart = addStart = count;
		for (i in 0...count) {
			if (drawn[i].phase >= 1 && blendStart == count)
				blendStart = i;
			if (drawn[i].phase == 2) {
				addStart = i;
				break;
			}
		}
		if (blendStart > addStart)
			blendStart = addStart;
		nextBlend = blendStart;
		if (count > capacity) {
			while (capacity < count)
				capacity *= 2;
			gpu.destroyBuffer(instanceBuffer);
			instanceBuffer = gpu.createBuffer(capacity * Sprite3DLayout.instanceStride);
			records = Bytes.alloc(capacity * Sprite3DLayout.instanceStride);
		}
		for (i in 0...count)
			write(i, drawn[i]);
		if (count > 0)
			gpu.updateBuffer(instanceBuffer, records, count * Sprite3DLayout.instanceStride);
		viewProjection.writeTo(uniforms);
		// The camera's right is forward across its up; its up, right across forward.
		var ux = camera.getUpX(), uy = camera.getUpY(), uz = camera.getUpZ();
		var rx = forwardY * uz - forwardZ * uy,
			ry = forwardZ * ux - forwardX * uz,
			rz = forwardX * uy - forwardY * ux;
		var rl = Math.sqrt(rx * rx + ry * ry + rz * rz);
		if (rl > 0) {
			rx /= rl;
			ry /= rl;
			rz /= rl;
		}
		var vx = ry * forwardZ - rz * forwardY,
			vy = rz * forwardX - rx * forwardZ,
			vz = rx * forwardY - ry * forwardX;
		// Upright: the right flattened onto the ground.
		var hl = Math.sqrt(rx * rx + rz * rz);
		var values = [rx, ry, rz, 0, vx, vy, vz, 0, hl > 0 ? rx / hl : 1, 0, hl > 0 ? rz / hl : 0, 0];
		for (i in 0...values.length)
			uniforms.setFloat(64 + i * 4, values[i]);
	}

	function write(index:Int, item:SpriteItem):Void {
		var node = item.node,
			w = node.getWorldMatrix(),
			at = index * Sprite3DLayout.instanceStride,
			texture = item.texture;
		inline function put(offset:Int, a:Float, b:Float, c:Float, d:Float):Void {
			records.setFloat(at + offset, a);
			records.setFloat(at + offset + 4, b);
			records.setFloat(at + offset + 8, c);
			records.setFloat(at + offset + 12, d);
		}
		var facing = node.getFacing();
		var sx = length(w, 0), sy = length(w, 4), sz = length(w, 8);
		put(Sprite3DLayout.positionOffset, w.get(12), w.get(13), w.get(14), facing == Camera ? 0 : facing == Upright ? 1 : 2);
		// Ground lies along the node's z, its texture's top toward -z; anything else along its y.
		var height = facing == Ground ? sz : sy;
		put(Sprite3DLayout.sizeOffset, node.getSpriteWidth() * sx, node.getSpriteHeight() * height, node.getPivotX(), node.getPivotY());
		var r = node.getRegion(),
			tw = texture.getWidth(),
			th = texture.getHeight();
		if (r[2] > 0 && r[3] > 0)
			put(Sprite3DLayout.regionOffset, r[0] / tw, r[1] / th, (r[0] + r[2]) / tw, (r[1] + r[3]) / th);
		else
			put(Sprite3DLayout.regionOffset, 0, 0, 1, 1);
		put(Sprite3DLayout.rightOffset, sx > 0 ? w.get(0) / sx : 1, sx > 0 ? w.get(1) / sx : 0, sx > 0 ? w.get(2) / sx : 0, 0);
		var alpha = switch node.getAlphaMode() {
			case Opaque: -1.;
			case Mask: Math.max(node.getAlphaCutoff(), 1e-4);
			case _: 0.;
		};
		if (facing == Ground)
			put(Sprite3DLayout.upOffset, sz > 0 ? -w.get(8) / sz : 0, sz > 0 ? -w.get(9) / sz : 0, sz > 0 ? -w.get(10) / sz : -1, alpha);
		else
			put(Sprite3DLayout.upOffset, sy > 0 ? w.get(4) / sy : 0, sy > 0 ? w.get(5) / sy : 1, sy > 0 ? w.get(6) / sy : 0, alpha);
		var tint = node.getTint();
		put(Sprite3DLayout.tintOffset, (tint >>> 24) / 255, ((tint >>> 16) & 255) / 255, ((tint >>> 8) & 255) / 255, (tint & 255) / 255);
	}

	// Draws drawn[from..to) as runs of a texture through phase's pipeline.
	function drawRange(from:Int, to:Int, phase:Int):Void {
		var i = from;
		while (i < to) {
			var last = i, texture = drawn[i].texture;
			while (last + 1 < to && drawn[last + 1].texture == texture)
				last++;
			gpu.drawMesh(pipelines[phase], corners, indices, 6, instanceBuffer, i, last - i + 1, [texture.getHandle()], [texture.getSampling()], [uniforms]);
			draws++;
			i = last + 1;
		}
	}

	/** Draws the opaque and masked sprites. */
	public function drawOpaque():Void
		drawRange(0, blendStart, 0);

	/** Draws the blended sprites farther than depth along the view not yet drawn: called before each see-through model run, back to front. */
	public function drawBlendedBeyond(depth:Float):Void {
		var end = nextBlend;
		while (end < addStart && drawn[end].depth > depth)
			end++;
		drawRange(nextBlend, end, 1);
		nextBlend = end;
	}

	/** Draws the blended sprites left, then the added ones. */
	public function drawRest():Void {
		drawRange(nextBlend, addStart, 1);
		nextBlend = addStart;
		drawRange(addStart, count, 2);
	}

	/** Frees its pipelines and buffers. */
	public function destroy():Void {
		for (p in pipelines)
			gpu.destroyPipeline(p);
		gpu.destroyBuffer(corners);
		gpu.destroyBuffer(indices);
		gpu.destroyBuffer(instanceBuffer);
	}
}

/** A sprite in view this draw. Pooled. */
private class SpriteItem {
	/** Its node. */
	public var node:Node;

	/** Its texture. */
	public var texture:Texture2D;

	/** 0 opaque or masked, 1 blended, 2 added. */
	public var phase = 0;

	/** Its pivot's distance along the camera's view. */
	public var depth = 0.;

	/** Its place in the walk: ties keep it. */
	public var order = 0;

	/** An empty item, filled by the walk. */
	public function new() {}
}
