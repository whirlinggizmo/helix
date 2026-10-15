import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Mat4;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.ModelFile.ImageSource;
import helix.render3d.Node;
import helix.render3d.Node.NodeKind;

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
		check(!m.makePerspective(0, 1, .1, 10) && !m.makePerspective(1, 1, 1, .5) && near(m.get(0), 1), "A bad perspective is refused and changes nothing");
		check(!m.makeLookAt(1, 2, 3, 1, 2, 3, 0, 1, 0)
			&& !m.makeLookAt(0, 0, 0, 0, 5, 0, 0, 1, 0), "A view onto itself or along up is refused");
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
		product.makeProduct(m, m);
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
		var file = @:privateAccess new helix.render3d.ModelFile(helix.render3d.Gltf.read(sys.io.File.getBytes("examples/assets/models/toy_car.glb")));
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
		// A camera node: under a parent turned a quarter about y and moved, it sees from the parent's point down the turned -z (toward -x).
		var rig = Node.group(),
			lens = new Camera3D(),
			mount = Node.camera(lens);
		rig.setPosition(5, 1, 0);
		rig.setRotation(0, Math.PI / 2, 0);
		rig.add(mount);
		lens.getViewProjection();
		check(near(lens.getEyeX(), 5) && near(lens.getEyeY(), 1) && near(lens.getEyeZ(), 0), "A camera node's eye is its world position");
		check(Math.abs(lens.getTargetX() - lens.getEyeX() + 1) < 1e-9
			&& Math.abs(lens.getTargetZ() - lens.getEyeZ()) < 1e-9, "It looks down its turned -z");
		check(mount.getKind() == CameraNode && mount.getCamera() == lens && lens.getNode() == mount, "The node and its camera know each other");
		var other = Node.camera(lens);
		check(mount.getCamera() == null && lens.getNode() == other, "A camera on another node moves there");
		var turned = Node.group();
		turned.setRotation(.3, -.5, 1.2);
		check(near(turned.getRotationX(), .3) && near(turned.getRotationY(), -.5) && near(turned.getRotationZ(), 1.2),
			"Its rotation's angles read back as set (y within -pi/2..pi/2)");
		turned.setPosition(1, 2, 3);
		var m = turned.getMatrix();
		check(m.length == 16 && m[12] == 1 && m[13] == 2 && m[14] == 3, "Its matrix holds its place in the last column");
		// .gltf: a triangle whose buffer is inline (a data: URI), and one whose buffer is a file beside it; relative paths resolved.
		var data = haxe.io.Bytes.alloc(36);
		for (k in 0...9)
			data.setFloat(k * 4, [0, 0, 0, 1, 0, 0, 0, 1, 0][k]);
		function gltfText(uri:String):String
			return haxe.Json.stringify({
				asset: {version: "2.0"},
				buffers: [{byteLength: 36, uri: uri}],
				bufferViews: [{buffer: 0, byteLength: 36}],
				accessors: [
					{
						bufferView: 0,
						componentType: 5126,
						count: 3,
						type: "VEC3"
					}
				],
				meshes: [{primitives: [{attributes: {POSITION: 0}}]}],
				nodes: [{mesh: 0, name: "tri"}],
				scenes: [{nodes: [0]}],
				images: [{uri: "Textures/colormap.png"}],
				textures: [{source: 0}],
				materials: [{pbrMetallicRoughness: {baseColorTexture: {index: 0}}}]
			});
		var embedded = helix.render3d.Gltf.read(haxe.io.Bytes.ofString(gltfText("data:application/octet-stream;base64," + haxe.crypto.Base64.encode(data))));
		check(embedded.getMissingBuffers().length == 0 && embedded.floats(0)[3] == 1, "An inline buffer is read from its data: URI");
		var apart = helix.render3d.Gltf.read(haxe.io.Bytes.ofString(gltfText("tri.bin")));
		check(apart.getMissingBuffers().length == 1
			&& apart.getMissingBuffers()[0].uri == "tri.bin", "A buffer in a file of its own waits for it");
		apart.setBuffer(0, data);
		var triangle = @:privateAccess new helix.render3d.ModelFile(apart);
		check(triangle.instantiate().find("tri") != null, "With its buffer set, the model builds");
		var sources = @:privateAccess triangle.images();
		check(sources.length == 1
			&& sources[0].source.match(File("Textures/colormap.png")), "An image file beside the model is named by its uri");
		check(helix.render3d.Gltf.resolve("models/car/car.gltf", "Textures/colormap.png") == "models/car/Textures/colormap.png"
			&& helix.render3d.Gltf.resolve("models/car/car.gltf", "../shared/a%20b.png") == null
			&& helix.render3d.Gltf.resolve("models/car/car.gltf", "../shared/ab.png") == "models/shared/ab.png"
			&& helix.render3d.Gltf.resolve("models/car.gltf", "../../x.png") == null
			&& helix.render3d.Gltf.resolve("models/car.gltf", "https://example.com/x.png") == null,
			"URIs resolve beside the model, inside the assets");
		shadows();
		flags();
		lightChoice();
		cullingAndCasters();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// Shadows: which lights cast and how their settings take, which models cast into a layer, what the lit shader is told, and a sun's map holding
	// its texels in place as the camera moves.
	static function shadows():Void {
		check(!new Light(Point).setShadowCasting(true) && new Light(Spot).setShadowCasting(true), "A point light doesn't cast; a spot does");
		var sunLight = new Light(Directional);
		check(sunLight.setShadowCasting(true) && sunLight.isShadowCasting(), "The sun casts when asked");
		check(sunLight.setShadowMapSize(3000) && sunLight.getShadowMapSize() == 2048 && sunLight.setShadowMapSize(9999)
			&& sunLight.getShadowMapSize() == 4096 && sunLight.setShadowMapSize(1) && sunLight.getShadowMapSize() == 256 && !sunLight.setShadowMapSize(0),
			"Map sizes round down to a power of two, 256 to 4096");
		check(!sunLight.setShadowBias(-1, 0) && !sunLight.setShadowDistance(0) && sunLight.setShadowStrength(3) && sunLight.getShadowStrength() == 1,
			"Bad settings are refused; strength is clamped");
		sunLight.setShadowMapSize(1024);
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var sun = Node.light(sunLight);
		sun.lookAt(-.3, -1, -.2);
		stage.add(sun);
		stage.add(Node.model(Mesh.plane(20, 20), new Material()));
		var pillar = Node.model(Mesh.cube(.5, 2, .5), new Material());
		pillar.setPosition(0, 1, 0);
		stage.add(pillar);
		var glass = Node.model(Mesh.cube(1, 1, 1), new Material(), 0xffffff80);
		glass.setPosition(3, 1, 0);
		stage.add(glass);
		var kept = Node.model(Mesh.cube(1, 1, 1), new Material());
		check(kept.setShadowCasting(false) && !kept.isShadowCasting() && !Node.group().setShadowCasting(true), "Only a model casts, unless told not to");
		stage.add(kept);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 6, 12, 0, 0, 0);
		stage.drawShadows(view);
		check(gpu.shadowPasses.join(",") == "0" && stage.getShadowCasterCount() == 2 && stage.getShadowDrawCallCount() == 2,
			"The sun's layer gets the floor and the pillar, not the see-through model or the one that doesn't cast");
		var map = @:privateAccess stage.lightViewProjection;
		var middle = clip(map, 0, 0, 0);
		check(Math.abs(middle[0]) < 1 && Math.abs(middle[1]) < 1 && Math.abs(middle[2]) < 1, "What the camera looks at is inside the sun's map");
		// A point's place in texels keeps its fraction as the camera slides: the map moves by whole texels.
		function texelPhase():Float {
			var at = clip(@:privateAccess stage.lightViewProjection, 1.234, 0, -.567),
				u = (at[0] * .5 + .5) * 1024;
			return u - Math.floor(u);
		}
		var phase = texelPhase(), held = true;
		for (k in 1...6) {
			view.setView(k * .0137, 6, 12 - k * .0291, k * .0137, 0, -k * .0291);
			stage.drawShadows(view);
			held = held && Math.abs(texelPhase() - phase) < 1e-3;
		}
		check(held, "The sun's texels stay put in the world as the camera moves");
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		var fs = gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
		check(fs.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_SPOT + 8) == 0
			&& fs.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_SPOT + 24) == -1,
			"The sun reads layer 0; light slots without a light read none");
		check(fs.getFloat(@:privateAccess helix.render3d.Stage3D.SHADOW_PARAMS) == 1 / 1024
			&& fs.getFloat(@:privateAccess helix.render3d.Stage3D.SHADOW_PARAMS + 64) == 1
			&& fs.getFloat(@:privateAccess helix.render3d.Stage3D.SHADOW_PARAMS + 76) == 0,
			"A texel in uv, full strength, an orthographic map");
		sunLight.setShadowCasting(false);
		gpu.shadowPasses = [];
		stage.drawShadows(view);
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		fs = gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
		check(gpu.shadowPasses.length == 0 && fs.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_SPOT + 8) == -1,
			"With no casting light, no passes and no shadows");
		// A spot: a perspective map whose cone holds what it points at.
		var spotLight = new Light(Spot);
		spotLight.setCone(.3, .5);
		spotLight.setRange(30);
		spotLight.setShadowCasting(true);
		var spot = Node.light(spotLight);
		spot.setPosition(0, 8, 4);
		spot.lookAt(0, 0, 0);
		stage.add(spot);
		stage.drawShadows(view);
		var below = clip(@:privateAccess stage.lightViewProjection, 0, 0, 0),
			aside = clip(@:privateAccess stage.lightViewProjection, 8, 0, 0);
		check(Math.abs(below[0] / below[3]) < 1e-6 && Math.abs(below[2] / below[3]) < 1, "The spot's map centers what it points at");
		check(Math.abs(aside[0] / aside[3]) > 1, "Past its cone is outside its map");
		stage.destroy();
	}

	// The three flags: enabled takes the subtree, visible only the node's own output, pickable only picks.
	static function flags():Void {
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var group = Node.model(Mesh.cube(1, 1, 1), new Material()),
			child = Node.model(Mesh.cube(1, 1, 1), new Material());
		child.setPosition(2, 0, 0);
		group.add(child);
		stage.add(group);
		var lamp = Node.light(new Light(Point));
		stage.add(lamp);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 2, 8, 0, 0, 0);
		function draw():Int {
			gpu.beginFrame(800, 600, 0);
			stage.draw(view);
			return stage.getDrawnNodeCount();
		}
		check(draw() == 2 && @:privateAccess stage.lights.length == 1, "Both models drawn, the lamp shining");
		group.setVisible(false);
		lamp.setVisible(false);
		check(draw() == 1 && @:privateAccess stage.lights.length == 0, "A hidden model's child still drawn; a hidden light doesn't shine");
		group.setVisible(true);
		group.setEnabled(false);
		check(draw() == 0 && child.isEnabled(), "A disabled model takes its child with it; the child's own flag kept");
		group.setEnabled(true);
		check(draw() == 2 && group.isPickable(), "Enabled again, both drawn");
	}

	// Lights chosen per model: a table of the 16 that reach the drawn models most, each model lit by the 8 of those that reach it most.
	static function lightChoice():Void {
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var left = Node.model(Mesh.cube(1, 1, 1), new Material()),
			right = Node.model(Mesh.cube(1, 1, 1), new Material());
		left.setPosition(-10, 0, 0);
		right.setPosition(10, 0, 0);
		stage.add(left);
		stage.add(right);
		// Twenty lamps of range 3: ten by the right model, then ten by the left, the left's nearest last.
		var lamps = [];
		for (k in 0...20) {
			var light = new Light(Point);
			light.setRange(3);
			var lamp = Node.light(light);
			lamp.setPosition(k < 10 ? 10 : -10, 1 + (k % 10) * .1, 0);
			if (k == 19)
				lamp.setPosition(-10, .6, 0);
			lamps.push(lamp);
			stage.add(lamp);
		}
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 5, 30, 0, 0, 0);
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		var table:Array<Node> = @:privateAccess stage.table;
		check(table.length == 16, "Twenty lamps reaching the models: a table of 16");
		var items:Array<Dynamic> = @:privateAccess stage.drawn;
		function lightsOf(model:Node):Array<Node> {
			for (item in items)
				if (item.node == model)
					return [for (t in (item.lights : Array<Int>)) if (t >= 0) table[t]];
			return null;
		}
		var mine = lightsOf(left);
		check(mine.length == 8 && mine[0] == lamps[19] && [for (l in mine) if (l.getX() != -10) l].length == 0,
			"The left model: 8 of its own lamps, the nearest (the last found) first");
		check([for (l in lightsOf(right)) if (l.getX() != 10) l].length == 0, "The right model: only lamps that reach it");
		// The old limit: the first four found lit everything, so a model by the fifth lamp went dark.
		var stage2 = new helix.render3d.Stage3D(gpu),
			far = Node.model(Mesh.cube(1, 1, 1), new Material());
		far.setPosition(50, 0, 0);
		stage2.add(far);
		for (k in 0...5) {
			var light = new Light(Point);
			light.setRange(2);
			var lamp = Node.light(light);
			lamp.setPosition(k < 4 ? -50 : 50, 1, 0);
			stage2.add(lamp);
		}
		var sun = new Light(Directional);
		stage2.add(Node.light(sun));
		view.setView(50, 5, 20, 50, 0, 0);
		stage2.draw(view);
		var only:Array<Dynamic> = @:privateAccess stage2.drawn,
			t2:Array<Node> = @:privateAccess stage2.table;
		var lit = [for (t in (only[0].lights : Array<Int>)) if (t >= 0) t2[t]];
		check(lit.length == 2 && lit[0].getX() == 50 && lit[1].getLight().getKind() == Directional,
			"The fifth lamp lights the model beside it, the sun everything; lamps out of range don't");
		var u = gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
		check(u.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_POSITION) == 50
			|| u.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_POSITION + 16) == 50,
			"The table, as the shader reads it");
	}

	// The culling switch, and libwgf's shadow case: a caster above the view whose shadow falls into it is kept, one aside is dropped.
	static function cullingAndCasters():Void {
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var floor = Node.model(Mesh.plane(10, 10), new Material()),
			high = Node.model(Mesh.cube(1, 1, 1), new Material()),
			aside = Node.model(Mesh.cube(1, 1, 1), new Material());
		high.setPosition(0, 40, 0);
		aside.setPosition(200, 1, 0);
		stage.add(floor);
		stage.add(high);
		stage.add(aside);
		var sunLight = new Light(Directional);
		sunLight.setShadowCasting(true);
		var sun = Node.light(sunLight);
		// Straight down: up can't be +y then (lookAt would refuse), so it's -z.
		check(sun.lookAt(0, -1, 0, 0, 0, -1), "A sun aimed straight down");
		stage.add(sun);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 6, 8, 0, 0, 0);
		stage.drawShadows(view);
		check(stage.getShadowCasterCount() == 2, "The floor and the cube high above (its shadow falls into view) cast; the one aside doesn't");
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		check(stage.getDrawnNodeCount() == 1 && stage.isCulling(), "Only the floor is in view");
		stage.setCulling(false);
		stage.drawShadows(view);
		stage.draw(view);
		check(stage.getDrawnNodeCount() == 3 && stage.getShadowCasterCount() == 3, "Culling off: everything drawn, every caster cast");
	}
}
