package helix.debug;

import helix.math.Bounds3D;
import helix.render3d.Camera3D;
import helix.render3d.Drawing3D;
import helix.render3d.Mat4;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.Renderer3D;

/** What picks test and what drawing culls by, drawn in a 3D tree for finding why a click misses: add it to the tree to look at (the one a
	View3D shows) at its origin, unturned and unscaled. Each frame it draws every shown node's box, square to the world, as computeBounds
	measures it and drawing culls by it (boundsColor), and for each node a pick can hit, what the pick tests (hitColor): its hitArea, a
	sprite's or text's quad as it faces the camera now, a model's triangles as posed (but for parts too see-through to hit). Nothing is drawn
	for what a pick doesn't test. The flags hold as for a pick: a hidden node and everything under it are left out, an unpickable one's gets
	no pick shape. Depth-tested as any drawing, so what's inside a model is hidden by it. Never picked. */
@:access(helix.render3d.Node3D)
@:access(helix.render3d.HitArea3D)
@:access(helix.render3d.Renderer3D)
class PickOverlay3D extends Drawing3D {
	var box = new Bounds3D();

	/** An overlay drawing hit shapes in hitColor (green unless given) and boxes in boundsColor (orange unless given). */
	public function new(hitColor = 0xff33ff66, boundsColor = 0xffffa020) {
		super();
		this.hitColor = hitColor;
		this.boundsColor = boundsColor;
		pickable = false;
	}

	/** Whether it draws what a pick tests on each node it can hit. On to start. */
	public var pickShapes = true;

	/** Whether it draws each shown node's own box, square to the world (an AABB: Node3D.computeBounds's, what drawing culls by). On to start. */
	public var drawBounds = true;

	/** The color of what each node is hit by, 0xAARRGGBB. */
	public var hitColor:Int;

	/** The color of each node's box, 0xAARRGGBB. */
	public var boundsColor:Int;

	// Each draw: the tree it's in looked at again, as camera shows it, then drawn.
	override function drawOwn(camera:Camera3D, renderer:Renderer3D, first:Bool, last:Bool):Void {
		clear();
		this.renderer = renderer;
		sprites = renderer.sprites != null ? renderer.sprites.part : null;
		if (sprites != null)
			renderer.sprites.preparePick(camera);
		var root:Node3D = this;
		while (root.parent != null)
			root = root.parent;
		visit(root, true);
		super.drawOwn(camera, renderer, first, last);
	}

	// The renderer drawing it this draw, whose pick it shows, and its sprites, which place a facing quad as a pick tests it (null when it
	// has none).
	var renderer:Null<Renderer3D>;
	var sprites:Null<Any>;
	var corners:Array<Float> = [];

	function visit(node:Node3D, hittable:Bool):Void {
		if (node == this || !node.visible)
			return;
		hittable = hittable && node.pickable;
		var world = node.worldMatrix;
		box.clear();
		node.measureOwnWorld(world, box);
		if (drawBounds && !box.isEmpty) {
			var width = box.maxX - box.minX,
				height = box.maxY - box.minY,
				depth = box.maxZ - box.minZ;
			cubeWires((box.minX + box.maxX) / 2, (box.minY + box.maxY) / 2, (box.minZ + box.maxZ) / 2, width, height, depth, boundsColor);
		}
		if (pickShapes && hittable)
			drawPickShape(node, world);
		for (i in 0...node.childCount)
			visit(node.getChild(i), hittable);
	}

	// What a pick tests on node, as the renderer's pick does: its hit area; a sprite's or text's quad as it faces now; a model's triangles,
	// posed, but for parts a pick passes over. Nothing for what a pick doesn't hit.
	function drawPickShape(node:Node3D, world:Mat4):Void {
		var area = node.hitArea;
		if (area != null) {
			if (area.round)
				sphereWires(world, area.x, area.y, area.z, area.halfWidth);
			else
				turnedBox(world, area.x
					- area.halfWidth, area.y
					- area.halfHeight, area.z
					- area.halfDepth, area.x
					+ area.halfWidth,
					area.y
					+ area.halfHeight, area.z
					+ area.halfDepth);
		} else if (Std.isOfType(node, Model3D)) {
			if (renderer == null)
				return;
			renderer.pickTriangles(cast node, corners);
			var k = 0;
			while (k + 9 <= corners.length) {
				for (edge in 0...3) {
					var a = k + edge * 3, b = k + (edge + 1) % 3 * 3;
					line(corners[a], corners[a + 1], corners[a + 2], corners[b], corners[b + 1], corners[b + 2], hitColor);
				}
				k += 9;
			}
		} else if (sprites != null && node.hitQuad(sprites, corners))
			for (k in 0...4) {
				var next = (k + 1) % 4;
				line(corners[k * 3], corners[k * 3 + 1], corners[k * 3 + 2], corners[next * 3], corners[next * 3 + 1], corners[next * 3 + 2], hitColor);
			}
	}

	// A sphere of radius about x, y, z in a node's own space as a circle on each of its three planes, placed by its world matrix, in hitColor.
	function sphereWires(world:Mat4, x:Float, y:Float, z:Float, radius:Float):Void {
		var steps = 32;
		for (plane in 0...3) {
			var lastX = 0., lastY = 0., lastZ = 0.;
			for (k in 0...steps + 1) {
				var angle = k / steps * Math.PI * 2,
					c = Math.cos(angle) * radius,
					s = Math.sin(angle) * radius;
				var lx = x + (plane == 0 ? c : plane == 1 ? 0 : s),
					ly = y + (plane == 0 ? s : plane == 1 ? c : 0),
					lz = z + (plane == 0 ? 0 : plane == 1 ? s : c);
				var px = placeX(world, lx, ly, lz),
					py = placeY(world, lx, ly, lz),
					pz = placeZ(world, lx, ly, lz);
				if (k > 0)
					line(lastX, lastY, lastZ, px, py, pz, hitColor);
				lastX = px;
				lastY = py;
				lastZ = pz;
			}
		}
	}

	// The edges of the box x0..x1, y0..y1, z0..z1 in a node's own space, placed by its world matrix, in hitColor.
	function turnedBox(world:Mat4, x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float):Void {
		var corners = [];
		for (k in 0...8) {
			var lx = k & 1 == 0 ? x0 : x1,
				ly = k & 2 == 0 ? y0 : y1,
				lz = k & 4 == 0 ? z0 : z1;
			corners.push(placeX(world, lx, ly, lz));
			corners.push(placeY(world, lx, ly, lz));
			corners.push(placeZ(world, lx, ly, lz));
		}
		// Corners a and b share an edge when their numbers differ in one bit.
		for (a in 0...8)
			for (bit in [1, 2, 4])
				if (a & bit == 0) {
					var b = a | bit;
					line(corners[a * 3], corners[a * 3 + 1], corners[a * 3 + 2], corners[b * 3], corners[b * 3 + 1], corners[b * 3 + 2], hitColor);
				}
	}

	// A point in a node's own space placed by its world matrix (column-major).
	static inline function placeX(m:Mat4, x:Float, y:Float, z:Float):Float
		return m.get(0) * x + m.get(4) * y + m.get(8) * z + m.get(12);

	static inline function placeY(m:Mat4, x:Float, y:Float, z:Float):Float
		return m.get(1) * x + m.get(5) * y + m.get(9) * z + m.get(13);

	static inline function placeZ(m:Mat4, x:Float, y:Float, z:Float):Float
		return m.get(2) * x + m.get(6) * y + m.get(10) * z + m.get(14);
}
