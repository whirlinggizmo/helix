import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Mat4;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;

/** Mat4 and Camera3D: projection, view and their product, checked by where they put known points. */
class Render3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	// Clip coordinates of world point x, y, z through m: [x, y, z, w].
	static function clip(m:Mat4, x:Float, y:Float, z:Float):Array<Float> {
		var result = [];
		for (row in 0...4)
			result.push(m.get(row) * x + m.get(4 + row) * y + m.get(8 + row) * z + m.get(12 + row));
		return result;
	}

	static function main():Void {
		var m = new Mat4();
		check(near(m.get(0), 1) && near(m.get(5), 1) && near(m.get(1), 0), "A new matrix is the identity");
		check(!m.setPerspective(0, 1, .1, 10) && !m.setPerspective(1, 1, 1, .5) && near(m.get(0), 1), "A bad perspective is refused and changes nothing");
		check(!m.setLookAt(1, 2, 3, 1, 2, 3, 0, 1, 0)
			&& !m.setLookAt(0, 0, 0, 0, 5, 0, 0, 1, 0), "A view onto itself or along up is refused");
		var camera = new Camera3D();
		camera.setViewport(800, 400);
		var vp = camera.getViewProjection();
		var center = clip(vp, 0, 0, 0);
		check(near(center[0], 0) && near(center[1], 0) && near(center[3], 10), "The target is at the clip center, the eye's distance away");
		var nearPoint = clip(vp, 0, 0, 10 - .1),
			farPoint = clip(vp, 0, 0, 10 - 1000);
		check(near(nearPoint[2] / nearPoint[3], -1)
			&& Math.abs(farPoint[2] / farPoint[3] - 1) < 1e-6, "The clip planes are at depth -1 and 1");
		var edge = clip(vp, 0, 10 * Math.tan(Math.PI / 8), 0);
		check(near(edge[1] / edge[3], 1), "The field of view's edge is the clip edge");
		var side = clip(vp, 10 * Math.tan(Math.PI / 8) * 2, 0, 0);
		check(near(side[0] / side[3], 1), "Width follows the viewport's aspect");
		camera.setView(10, 0, 0, 0, 0, 0);
		var right = clip(camera.getViewProjection(), 0, 0, -1);
		check(right[0] / right[3] > 0, "Looking down -x from +x, -z is on the right: right-handed");
		var product = new Mat4();
		product.setProduct(m, m);
		check(near(product.get(0), 1) && near(product.get(15), 1), "The identity times itself");
		// Every generated shape: each triangle faces the way its vertices' normals do (counter-clockwise from outside), and the box is right.
		for (shape in [
			Mesh.plane(2, 3, 2),
			Mesh.cube(1, 2, 3),
			Mesh.sphere(.5, 8, 12),
			Mesh.cylinder(.5, 1, 12),
			Mesh.cone(.5, 1, 12),
			Mesh.capsule(.3, 1.2, 8, 12),
			Mesh.torus(.4, .1, 12, 8)
		]) {
			var v = shape.getVertices(), ix = shape.getIndices(), facing = true;
			for (t in 0...Std.int(shape.getIndexCount() / 3)) {
				var p = [for (k in 0...3) ix.getInt32((t * 3 + k) * 4) * Lit3DLayout.stride];
				var ax = v.getFloat(p[0]),
					ay = v.getFloat(p[0] + 4),
					az = v.getFloat(p[0] + 8);
				var ux = v.getFloat(p[1]) - ax,
					uy = v.getFloat(p[1] + 4) - ay,
					uz = v.getFloat(p[1] + 8) - az;
				var wx = v.getFloat(p[2]) - ax,
					wy = v.getFloat(p[2] + 4) - ay,
					wz = v.getFloat(p[2] + 8) - az;
				var cx = uy * wz - uz * wy,
					cy = uz * wx - ux * wz,
					cz = ux * wy - uy * wx;
				var n = p[0] + Lit3DLayout.normalOffset;
				facing = facing && cx * v.getFloat(n) + cy * v.getFloat(n + 4) + cz * v.getFloat(n + 8) > 0;
			}
			check(facing, "Generated triangles face out, counter-clockwise");
		}
		// Tangents: unit length, perpendicular to the normal, along increasing u (a sphere's u runs around it from +x toward -z, left to right seen from outside).
		var ball = Mesh.sphere(1, 8, 16),
			bv = ball.getVertices(),
			tangentsOk = true;
		for (i in 0...ball.getVertexCount()) {
			var at = i * Lit3DLayout.stride,
				n = at + Lit3DLayout.normalOffset,
				t = at + Lit3DLayout.tangentOffset;
			var tx = bv.getFloat(t),
				ty = bv.getFloat(t + 4),
				tz = bv.getFloat(t + 8),
				w = bv.getFloat(t + 12);
			var length = Math.sqrt(tx * tx + ty * ty + tz * tz);
			var dot = tx * bv.getFloat(n) + ty * bv.getFloat(n + 4) + tz * bv.getFloat(n + 8);
			tangentsOk = tangentsOk && Math.abs(length - 1) < 1e-5 && Math.abs(dot) < 1e-5 && (w == 1 || w == -1);
		}
		check(tangentsOk, "Tangents are unit length, perpendicular to their normals, with a sign");
		var equator = (4 * 17 + 0) * Lit3DLayout.stride + Lit3DLayout.tangentOffset; // ring 4 of 8 (the equator), segment 0: at +x
		check(Math.abs(bv.getFloat(equator + 8) + 1) < 1e-5, "At the equator's +x, the tangent follows u toward -z");
		var box = Mesh.cube(1, 2, 3);
		check(near(box.getMinX(), -.5) && near(box.getMaxY(), 1) && near(box.getMaxZ(), 1.5) && box.getIndexCount() == 36, "A cube's box and triangles");
		// Vertices are float32: 0.6 comes back as 0.6000000238.
		var capsule = Mesh.capsule(.3, 1.2);
		check(Math.abs(capsule.getMaxY() - .6) < 1e-6
			&& Math.abs(capsule.getMinY() + .6) < 1e-6, "A capsule is its height from end to end");
		// Nodes: a child's world is its parent's times its own, recomputed when the parent moves.
		var parent = Node.group(), child = Node.model(box, new Material());
		parent.add(child);
		parent.setPosition(1, 2, 3);
		child.setPosition(0, 1, 0);
		@:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.getWorldMatrix(), true);
		check(near(child.getWorldMatrix().get(12), 1) && near(child.getWorldMatrix().get(13), 3), "A child is placed through its parent");
		parent.setPosition(0, 0, 0);
		var changed = @:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.getWorldMatrix(), changed);
		check(changed && near(child.getWorldMatrix().get(13), 1), "A parent's move reaches its child");
		check(! @:privateAccess child.update(parent.getWorldMatrix(), false), "Nothing changed: nothing recomputed");
		var looker = Node.group();
		check(looker.lookAt(0, 0, -5) && @:privateAccess looker.update(null, false), "lookAt turns a node");
		check(near(looker.getWorldMatrix().get(10), 1), "Looking down -z leaves z as it was");
		looker.lookAt(5, 0, 0);
		@:privateAccess looker.update(null, false);
		check(near(-looker.getWorldMatrix().get(8), 1) && near(looker.getWorldMatrix().get(5), 1), "lookAt points -z at the target, y up");
		check(!parent.add(parent) && !child.add(parent), "A node can't hold itself or its ancestor");
		var spot = new Light(Spot);
		check(spot.setCone(.1, .2) && !spot.setCone(.3, .2) && !spot.setCone(.1, Math.PI / 2) && spot.getOuterCone() == .2,
			"A spot's cones: inner <= outer < pi/2");
		check(!spot.setIntensity(-1) && !spot.setRange(-1) && spot.getKind() == Spot, "A light refuses negative intensity and range");
		// A glTF file read whole: the toy car (examples/assets/models/toy_car.glb).
		var file = @:privateAccess new helix.render3d.ModelFile(helix.render3d.Gltf.readGlb(sys.io.File.getBytes("examples/assets/models/toy_car.glb")));
		var car = file.instantiate("car");
		var wheel = car.find("wheel_rl"),
			beam = car.find("headlight_l_beam"),
			cabin = car.find("cabin");
		check(wheel != null && wheel.getKind() == Model && wheel.getMesh().getIndexCount() > 0, "A model file's parts are found by name");
		check(beam != null
			&& beam.getKind() == LightNode
			&& beam.getLight().getKind() == Spot
			&& near(beam.getLight().getOuterCone(), .5),
			"KHR_lights_punctual becomes lights");
		check(cabin.getMaterial().isBlended() && file.getWarnings().length == 0, "alphaMode BLEND, and nothing the file uses is unread");
		check(@:privateAccess file.images().length == 1, "One embedded image, the paint's");
		var again = file.instantiate();
		check(again.find("wheel_rl").getMesh() == wheel.getMesh() && again.find("headlight_l_beam").getLight() != beam.getLight(),
			"Copies share meshes and materials, not lights");
		check(!Node.group().setMatrix([1, 0, 0, 0])
			&& near(Mesh.fromArrays([0, 0, 0, 1, 0, 0, 0, 1, 0], null, null, null, null).getVertices().getFloat(Lit3DLayout.normalOffset + 8), 1),
			"Missing normals are worked out (a triangle in x, y faces +z)");
		var sided = new Material();
		check(!sided.isDoubleSided(), "Materials draw one side by default");
		sided.setDoubleSided(true);
		check(sided.isDoubleSided(), "A material can draw both sides");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
