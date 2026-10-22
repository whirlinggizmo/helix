import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Light;
import helix.render3d.Mat4;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile.ImageSource;
import helix.render3d.Node3D;
import helix.render3d.PointLight;
import helix.render3d.Ray;
import helix.render3d.SpotLight;

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
		var vp = camera.viewProjection;
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
		// A lens shift: the axis half the viewport's half-width right and a quarter of its half-height down, at every depth, the view as wide.
		camera.lensShiftX = .5;
		camera.lensShiftY = -.25;
		var shifted = clip(camera.viewProjection, 0, 0, 0),
			deeper = clip(camera.viewProjection, 0, 0, -5),
			top = clip(camera.viewProjection, 0, 10 * Math.tan(Math.PI / 8), 0);
		check(near(shifted[0] / shifted[3], .5) && near(shifted[1] / shifted[3], -.25) && near(deeper[0] / deeper[3], .5) && near(deeper[1] / deeper[3], -.25),
			"A lens shift moves the axis across the viewport at every depth");
		check(near(top[1] / top[3], .75), "A lens shift keeps the field of view's height");
		var axisRay = new Ray();
		check(camera.computeRay(600, 250, axisRay)
			&& near(axisRay.directionX, 0)
			&& near(axisRay.directionY, 0)
			&& axisRay.directionZ < 0,
			"The ray through the shifted center runs down the axis");
		camera.projection = Orthographic;
		var flatShifted = clip(camera.viewProjection, 0, 0, 0);
		check(near(flatShifted[0], .5) && near(flatShifted[1], -.25), "An orthographic view shifts alike");
		camera.projection = Perspective;
		camera.lensShiftX = Math.NaN;
		camera.lensShiftY = Math.POSITIVE_INFINITY;
		check(camera.lensShiftX == 0 && camera.lensShiftY == 0, "A lens shift not finite is 0");
		camera.setView(10, 0, 0, 0, 0, 0);
		var right = clip(camera.viewProjection, 0, 0, -1);
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
			var v = shape.vertices, ix = shape.indices, facing = true;
			for (t in 0...Std.int(shape.indexCount / 3)) {
				var p = [for (k in 0...3) ix.getInt32((t * 3 + k) * 4) * Lit3DProgram.stride];
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
				var n = p[0] + Lit3DProgram.normalOffset;
				facing = facing && cx * v.getFloat(n) + cy * v.getFloat(n + 4) + cz * v.getFloat(n + 8) > 0;
			}
			check(facing, "Generated triangles face out, counter-clockwise");
		}
		// Tangents: unit length, perpendicular to the normal, along increasing u (a sphere's u runs around it from +x toward -z, left to right seen from outside).
		var ball = Mesh.sphere(1, 8, 16),
			bv = ball.vertices,
			tangentsOk = true;
		for (i in 0...ball.vertexCount) {
			var at = i * Lit3DProgram.stride,
				n = at + Lit3DProgram.normalOffset,
				t = at + Lit3DProgram.tangentOffset;
			var tx = bv.getFloat(t),
				ty = bv.getFloat(t + 4),
				tz = bv.getFloat(t + 8),
				w = bv.getFloat(t + 12);
			var length = Math.sqrt(tx * tx + ty * ty + tz * tz);
			var dot = tx * bv.getFloat(n) + ty * bv.getFloat(n + 4) + tz * bv.getFloat(n + 8);
			tangentsOk = tangentsOk && Math.abs(length - 1) < 1e-5 && Math.abs(dot) < 1e-5 && (w == 1 || w == -1);
		}
		check(tangentsOk, "Tangents are unit length, perpendicular to their normals, with a sign");
		var equator = (4 * 17 + 0) * Lit3DProgram.stride + Lit3DProgram.tangentOffset; // ring 4 of 8 (the equator), segment 0: at +x
		check(Math.abs(bv.getFloat(equator + 8) + 1) < 1e-5, "At the equator's +x, the tangent follows u toward -z");
		var box = Mesh.cube(1, 2, 3);
		check(near(box.minX, -.5) && near(box.maxY, 1) && near(box.maxZ, 1.5) && box.indexCount == 36, "A cube's box and triangles");
		// Vertices are float32: 0.6 comes back as 0.6000000238.
		var capsule = Mesh.capsule(.3, 1.2);
		check(Math.abs(capsule.maxY - .6) < 1e-6 && Math.abs(capsule.minY + .6) < 1e-6, "A capsule is its height from end to end");
		// Nodes: a child's world is its parent's times its own, recomputed when the parent moves.
		var parent = new Node3D(), child = new Model(box, new Material());
		parent.addChild(child);
		parent.setPosition(1, 2, 3);
		child.setPosition(0, 1, 0);
		@:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.worldMatrix, true);
		check(near(child.worldMatrix.get(12), 1) && near(child.worldMatrix.get(13), 3), "A child is placed through its parent");
		var bounds = new haxe.ds.Vector<Float>(6);
		check(child.computeWorldBounds(bounds) && near(bounds[0], .5) && near(bounds[3], 1.5) && near(bounds[1], 2) && near(bounds[4], 4)
			&& near(bounds[2], 1.5) && near(bounds[5], 4.5),
			"A rigid model's world bounds are its vertices placed through its parents");
		check(!new Model().computeWorldBounds(bounds) && near(bounds[0], .5), "A model with no vertices has no bounds, out left alone");
		parent.setPosition(0, 0, 0);
		var changed = @:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.worldMatrix, changed);
		check(changed && near(child.worldMatrix.get(13), 1), "A parent's move reaches its child");
		check(! @:privateAccess child.update(parent.worldMatrix, false), "Nothing changed: nothing recomputed");
		parent.x = 4;
		changed = @:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.worldMatrix, changed);
		check(changed && parent.x == 4 && near(child.worldMatrix.get(12), 4), "Assigning x moves the node in the world");
		parent.y = 2;
		parent.z = -1;
		parent.scaleX = 2;
		parent.scaleY = 3;
		parent.scaleZ = 4;
		changed = @:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.worldMatrix, changed);
		check(changed && near(child.worldMatrix.get(13), 5) && near(child.worldMatrix.get(14), -1) && near(child.worldMatrix.get(0), 2)
			&& near(child.worldMatrix.get(10), 4),
			"Assigning y, z and the scales move it too");
		parent.setPosition(0, 0, 0);
		parent.setScale(1, 1, 1);
		@:privateAccess parent.update(null, false);
		@:privateAccess child.update(parent.worldMatrix, true);
		var looker = new Node3D();
		check(looker.lookAt(0, 0, -5) && @:privateAccess looker.update(null, false), "lookAt turns a node");
		check(near(looker.worldMatrix.get(10), 1), "Looking down -z leaves z as it was");
		looker.lookAt(5, 0, 0);
		@:privateAccess looker.update(null, false);
		check(near(-looker.worldMatrix.get(8), 1) && near(looker.worldMatrix.get(5), 1), "lookAt points -z at the target, y up");
		check(!parent.addChild(parent) && !child.addChild(parent), "A node can't hold itself or its ancestor");
		// attach keeps a node's world place under a moved, turned, scaled parent; parent = keeps its local one.
		var holder = new Node3D(), held = new Node3D(), world = new Mat4();
		holder.setPosition(10, 0, 0);
		holder.setRotation(0, Math.PI / 2, 0);
		holder.setScale(2, 2, 2);
		held.setPosition(1, 2, 3);
		check(holder.addChildInPlace(held) && held.parent == holder, "attach makes it a child");
		held.computeWorld(world);
		check(near(world.get(12), 1) && near(world.get(13), 2) && near(world.get(14), 3), "An attached node keeps its world position");
		check(!held.addChildInPlace(holder) && holder.parent == null, "attach refuses an ancestor as add does");
		held.parent = null;
		held.setPosition(1, 2, 3);
		held.parent = holder;
		held.computeWorld(world);
		check(held.parent == holder && near(world.get(12), 10 + 2 * 3) && near(world.get(13), 4), "parent = keeps its local transform");
		held.parent = null;
		check(held.parent == null && holder.childCount == 0, "parent = null takes it from its parent");
		var spot = new SpotLight();
		check(spot.setCone(.1, .2) && !spot.setCone(.3, .2) && !spot.setCone(.1, Math.PI / 2) && spot.outerCone == .2, "A spot's cones: inner <= outer < pi/2");
		spot.intensity = -1;
		spot.range = -1;
		check(spot.intensity == 0 && spot.range == 0, "A light's negative intensity and range are 0");
		// A glTF file read whole: the toy car (examples/assets/models/toy_car.glb).
		var file = @:privateAccess new helix.render3d.ModelFile(helix.render3d.Gltf.read(sys.io.File.getBytes("examples/assets/models/toy_car.glb")));
		var car = file.instantiate("car");
		var wheel = Std.downcast(car.find("wheel_rl"), Model),
			beam = Std.downcast(car.find("headlight_l_beam"), SpotLight),
			cabin = Std.downcast(car.find("cabin"), Model);
		check(wheel != null && wheel.mesh.indexCount > 0, "A model file's models are found by name");
		check(beam != null && near(beam.outerCone, .5), "KHR_lights_punctual becomes lights of their kinds");
		check(cabin != null && cabin.material.blended && file.warnings.length == 0, "alphaMode BLEND, and nothing the file uses is unread");
		check(@:privateAccess file.images().length == 1, "One embedded image, the paint's");
		var again = file.instantiate();
		check(Std.downcast(again.find("wheel_rl"), Model).mesh == wheel.mesh && again.find("headlight_l_beam") != beam,
			"Copies share meshes and materials, not lights");
		check(!new Node3D().setMatrix([1, 0, 0, 0])
			&& near(Mesh.fromArrays([0, 0, 0, 1, 0, 0, 0, 1, 0], null, null, null, null).vertices.getFloat(Lit3DProgram.normalOffset + 8), 1),
			"Missing normals are worked out (a triangle in x, y faces +z)");
		var sided = new Material();
		check(!sided.doubleSided, "Materials draw one side by default");
		sided.doubleSided = true;
		check(sided.doubleSided, "A material can draw both sides");
		// A camera is a node: under a parent turned a quarter about y and moved, it sees from the parent's point down the turned -z (toward -x).
		var rig = new Node3D(), lens = new Camera3D();
		check(near(lens.eyeZ, 10) && near(lens.forwardZ, -1), "A camera starts at 0, 0, 10 looking at the origin");
		lens.setPosition(0, 0, 0);
		rig.setPosition(5, 1, 0);
		rig.setRotation(0, Math.PI / 2, 0);
		rig.addChild(lens);
		check(near(lens.eyeX, 5) && near(lens.eyeY, 1) && near(lens.eyeZ, 0), "A camera's eye is its world position");
		check(Math.abs(lens.forwardX + 1) < 1e-9 && Math.abs(lens.forwardZ) < 1e-9, "It looks down its turned -z");
		check(lens.setView(0, 0, 2, 0, 0, 0) && near(lens.eyeX, 7) && Math.abs(lens.forwardX + 1) < 1e-9, "setView places it relative to its parent");
		check(!lens.setView(1, 1, 1, 1, 1, 1) && near(lens.eyeX, 7), "A view from the target refused, the camera left where it was");
		rig.setPosition(0, 0, 0);
		// The origin, 2 ahead of the camera now at x 2: in the middle of its view.
		var seen = lens.viewProjection;
		check(near(seen.get(12) / seen.get(15), 0)
			&& near(seen.get(13) / seen.get(15), 0)
			&& near(lens.eyeX, 2), "Its view follows its parent's move");
		var turned = new Node3D();
		turned.setRotation(.3, -.5, 1.2);
		check(near(turned.rotationX, .3) && near(turned.rotationY, -.5) && near(turned.rotationZ, 1.2),
			"Its rotation's angles read back as set (y within -pi/2..pi/2)");
		turned.setPosition(1, 2, 3);
		var m = turned.matrix;
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
		check(embedded.missingBuffers.length == 0 && embedded.floats(0)[3] == 1, "An inline buffer is read from its data: URI");
		var apart = helix.render3d.Gltf.read(haxe.io.Bytes.ofString(gltfText("tri.bin")));
		check(apart.missingBuffers.length == 1 && apart.missingBuffers[0].uri == "tri.bin", "A buffer in a file of its own waits for it");
		apart.setBuffer(0, data);
		var triangle = @:privateAccess new helix.render3d.ModelFile(apart);
		check(triangle.instantiate().find("tri") != null, "With its buffer set, the model builds");
		var sources = @:privateAccess triangle.images();
		check(sources.length == 1
			&& sources[0].source.match(File("Textures/colormap.png")), "An image file beside the model is named by its uri");
		check(helix.assets.AssetPath.resolve("models/car/car.gltf", "Textures/colormap.png") == "models/car/Textures/colormap.png"
			&& helix.assets.AssetPath.resolve("models/car/car.gltf", "../shared/a%20b.png") == null
			&& helix.assets.AssetPath.resolve("models/car/car.gltf", "../shared/ab.png") == "models/shared/ab.png"
			&& helix.assets.AssetPath.resolve("models/car.gltf", "../../x.png") == null
			&& helix.assets.AssetPath.resolve("models/car.gltf", "https://example.com/x.png") == null,
			"URIs resolve beside the model, inside the assets");
		// Cameras: a perspective one and an orthographic one as Camera3D nodes at their nodes' transforms, a node with a mesh and a camera the
		// model with the camera a child of its name plus "_camera", and each copy with cameras of its own.
		var rig = @:privateAccess new helix.render3d.ModelFile(helix.render3d.Gltf.read(haxe.io.Bytes.ofString(haxe.Json.stringify({
			asset: {version: "2.0"},
			buffers: [
				{byteLength: 36, uri: "data:application/octet-stream;base64," + haxe.crypto.Base64.encode(data)}
			],
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
			cameras: ([
				{type: "perspective", perspective: {yfov: .9, znear: .2, zfar: 50}},
				{
					type: "orthographic",
					orthographic: {
						xmag: 4,
						ymag: 3,
						znear: .1,
						zfar: 20
					}
				},
				{type: "perspective", perspective: {yfov: 1, znear: 1}}
			] : Array<Dynamic>),
			nodes: ([
				{name: "eye", camera: 0, translation: [1, 2, 3]},
				{name: "flat", camera: 1},
				{name: "body", mesh: 0, camera: 2}
			] : Array<Dynamic>),
			scenes: [{nodes: [0, 1, 2]}]
		}))));
		var set = rig.instantiate("set"),
			eye = Std.downcast(set.find("eye"), Camera3D),
			flat = Std.downcast(set.find("flat"), Camera3D),
			body = Std.downcast(set.find("body"), Model);
		check(eye != null && near(eye.fovY, .9) && near(eye.near, .2) && near(eye.far, 50) && eye.projection == Perspective,
			"A perspective camera node is a Camera3D with the file's yfov, znear and zfar");
		check(near(eye.x, 1) && near(eye.y, 2) && near(eye.z, 3) && near(eye.eyeX, 1) && near(eye.forwardZ, -1) && near(eye.upY, 1),
			"It sits at its node's transform, looking down -z with +y up");
		check(flat != null && flat.projection == Orthographic && near(flat.orthographicHeight, 6) && near(flat.near, .1) && near(flat.far, 20),
			"An orthographic camera's height is twice its ymag");
		check(near(flat.eyeZ, 0) && near(flat.forwardZ, -1), "A camera node without a transform is at the origin, not Camera3D's starting place");
		var bodyCamera = Std.downcast(set.find("body_camera"), Camera3D);
		check(body != null && body.mesh.indexCount == 3 && bodyCamera != null && bodyCamera.parent == body,
			"A node with a mesh and a camera is the model, the camera its child named after it");
		check(near(bodyCamera.fovY, 1) && near(bodyCamera.near, 1) && near(bodyCamera.far, 1000), "An absent zfar leaves Camera3D's default far");
		var setAgain = rig.instantiate();
		check(setAgain.find("eye") != eye
			&& Std.downcast(setAgain.find("eye"), Camera3D) != null
			&& setAgain.find("body_camera") != bodyCamera,
			"Copies have cameras of their own");
		shadows();
		flags();
		lightChoice();
		cullingAndCasters();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// Shadows: which lights cast and how their settings take, which models cast into a layer, what the lit shader is told, and a sun's map holding
	// its texels in place as the camera moves.
	static function shadows():Void {
		var point = new PointLight(), spot = new SpotLight();
		point.shadowCasting = true;
		spot.shadowCasting = true;
		check(!point.shadowCasting && spot.shadowCasting, "A point light doesn't cast; a spot does");
		var sun = new DirectionalLight();
		sun.shadowCasting = true;
		check(sun.shadowCasting, "The sun casts when asked");
		var sizes = [];
		for (size in [3000, 9999, 1, 0]) {
			sun.shadowMapSize = size;
			sizes.push(sun.shadowMapSize);
		}
		check(sizes.join(",") == "2048,4096,256,256", "Map sizes round down to a power of two, 256 to 4096");
		sun.shadowDistance = 0;
		sun.shadowStrength = 3;
		check(!sun.setShadowBias(-1, 0) && sun.shadowDistance == 1e-6 && sun.shadowStrength == 1,
			"A negative bias is refused; distance and strength are clamped");
		sun.shadowDistance = 50;
		sun.shadowMapSize = 1024;
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		sun.lookAt(-.3, -1, -.2);
		stage.add(sun);
		stage.add(new Model(Mesh.plane(20, 20), new Material()));
		var pillar = new Model(Mesh.cube(.5, 2, .5), new Material());
		pillar.setPosition(0, 1, 0);
		stage.add(pillar);
		var glass = new Model(Mesh.cube(1, 1, 1), new Material());
		glass.tint = 0xffffff80;
		glass.setPosition(3, 1, 0);
		stage.add(glass);
		var kept = new Model(Mesh.cube(1, 1, 1), new Material());
		check(kept.shadowCasting, "A model casts by default");
		kept.shadowCasting = false;
		check(!kept.shadowCasting, "A model told not to doesn't");
		stage.add(kept);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 6, 12, 0, 0, 0);
		stage.drawShadows(view);
		check(gpu.shadowPasses.join(",") == "0" && stage.shadowCasterCount == 2 && stage.shadowDrawCallCount == 2,
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
		sun.shadowCasting = false;
		gpu.shadowPasses = [];
		stage.drawShadows(view);
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		fs = gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
		check(gpu.shadowPasses.length == 0 && fs.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_SPOT + 8) == -1,
			"With no casting light, no passes and no shadows");
		// A spot: a perspective map whose cone holds what it points at.
		var spot = new SpotLight();
		spot.setCone(.3, .5);
		spot.range = 30;
		spot.shadowCasting = true;
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
		var group = new Model(Mesh.cube(1, 1, 1), new Material()),
			child = new Model(Mesh.cube(1, 1, 1), new Material());
		child.setPosition(2, 0, 0);
		group.addChild(child);
		stage.add(group);
		var lamp = new PointLight();
		stage.add(lamp);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 2, 8, 0, 0, 0);
		function draw():Int {
			gpu.beginFrame(800, 600, 0);
			stage.draw(view);
			return stage.drawnNodeCount;
		}
		check(draw() == 2 && @:privateAccess stage.lights.length == 1, "Both models drawn, the lamp shining");
		group.visible = false;
		lamp.visible = false;
		check(draw() == 1 && @:privateAccess stage.lights.length == 0, "A hidden model's child still drawn; a hidden light doesn't shine");
		group.visible = true;
		group.enabled = false;
		check(draw() == 0 && child.enabled, "A disabled model takes its child with it; the child's own flag kept");
		group.enabled = true;
		check(draw() == 2 && group.pickable, "Enabled again, both drawn");
		// The stage's lists of kinds follow the tree: a model of two parts added under a node already on it draws both; taken off, or under a
		// node off the stage, nothing; moved back, both again.
		var two = new Model(Mesh.cube(1, 1, 1), new Material()),
			holder = new Node3D(),
			aside = new Node3D();
		two.addPart(Mesh.sphere(.5), new Material());
		child.addChild(holder);
		holder.addChild(two);
		check(two.partCount == 2 && draw() == 4, "A model's parts draw each, added under a node on the stage");
		aside.addChild(two);
		check(draw() == 2 && two.parent == aside, "Moved under a node off the stage, it isn't drawn");
		holder.addChild(two);
		check(draw() == 4, "Moved back, it is");
		group.removeChild(child);
		check(draw() == 1, "Taking a node off takes what's under it");
	}

	// Lights chosen per model: a table of the 16 that reach the drawn models most, each model lit by the 8 of those that reach it most.
	static function lightChoice():Void {
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var left = new Model(Mesh.cube(1, 1, 1), new Material()),
			right = new Model(Mesh.cube(1, 1, 1), new Material());
		left.setPosition(-10, 0, 0);
		right.setPosition(10, 0, 0);
		stage.add(left);
		stage.add(right);
		// Twenty lamps of range 3: ten by the right model, then ten by the left, the left's nearest last.
		var lamps = [];
		for (k in 0...20) {
			var lamp = new PointLight();
			lamp.range = 3;
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
		var table:Array<Light> = @:privateAccess stage.table;
		check(table.length == 16, "Twenty lamps reaching the models: a table of 16");
		var items:Array<Dynamic> = @:privateAccess stage.drawn;
		function lightsOf(model:Model):Array<Light> {
			for (item in items)
				if (item.node == model)
					return [for (t in (item.lights : Array<Int>)) if (t >= 0) table[t]];
			return null;
		}
		var mine = lightsOf(left);
		check(mine.length == 8 && mine[0] == lamps[19] && [for (l in mine) if (l.x != -10) l].length == 0,
			"The left model: 8 of its own lamps, the nearest (the last found) first");
		check([for (l in lightsOf(right)) if (l.x != 10) l].length == 0, "The right model: only lamps that reach it");
		// The old limit: the first four found lit everything, so a model by the fifth lamp went dark.
		var stage2 = new helix.render3d.Stage3D(gpu),
			far = new Model(Mesh.cube(1, 1, 1), new Material());
		far.setPosition(50, 0, 0);
		stage2.add(far);
		for (k in 0...5) {
			var lamp = new PointLight();
			lamp.range = 2;
			lamp.setPosition(k < 4 ? -50 : 50, 1, 0);
			stage2.add(lamp);
		}
		var sun = new DirectionalLight();
		stage2.add(sun);
		view.setView(50, 5, 20, 50, 0, 0);
		stage2.draw(view);
		var only:Array<Dynamic> = @:privateAccess stage2.drawn,
			t2:Array<Light> = @:privateAccess stage2.table;
		var lit = [for (t in (only[0].lights : Array<Int>)) if (t >= 0) t2[t]];
		check(lit.length == 2 && lit[0].x == 50 && lit[1] == sun, "The fifth lamp lights the model beside it, the sun everything; lamps out of range don't");
		var u = gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
		check(u.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_POSITION) == 50
			|| u.getFloat(@:privateAccess helix.render3d.Stage3D.LIGHT_POSITION + 16) == 50,
			"The table, as the shader reads it");
	}

	// The culling switch, and libwgf's shadow case: a caster above the view whose shadow falls into it is kept, one aside is dropped.
	static function cullingAndCasters():Void {
		var gpu = new Render2DTests.CountingGraphics(),
			stage = new helix.render3d.Stage3D(gpu);
		var floor = new Model(Mesh.plane(10, 10), new Material()),
			high = new Model(Mesh.cube(1, 1, 1), new Material()),
			aside = new Model(Mesh.cube(1, 1, 1), new Material());
		high.setPosition(0, 40, 0);
		aside.setPosition(200, 1, 0);
		stage.add(floor);
		stage.add(high);
		stage.add(aside);
		var sun = new DirectionalLight();
		sun.shadowCasting = true;
		// Straight down: up can't be +y then (lookAt would refuse), so it's -z.
		check(sun.lookAt(0, -1, 0, 0, 0, -1), "A sun aimed straight down");
		stage.add(sun);
		var view = new Camera3D();
		view.setViewport(800, 600);
		view.setView(0, 6, 8, 0, 0, 0);
		stage.drawShadows(view);
		check(stage.shadowCasterCount == 2, "The floor and the cube high above (its shadow falls into view) cast; the one aside doesn't");
		gpu.beginFrame(800, 600, 0);
		stage.draw(view);
		check(stage.drawnNodeCount == 1 && stage.culling, "Only the floor is in view");
		stage.culling = false;
		stage.drawShadows(view);
		stage.draw(view);
		check(stage.drawnNodeCount == 3 && stage.shadowCasterCount == 3, "Culling off: everything drawn, every caster cast");
	}
}
