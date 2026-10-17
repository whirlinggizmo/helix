import Render2DTests.CountingGraphics;
import helix.render3d.Camera3D;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.PickHit;
import helix.render3d.Ray;
import helix.render3d.Skin;
import helix.render3d.Sprite3D;
import helix.render3d.Stage3D;
import helix.render3d.Text3D;

/** Picking: the ray through a pixel (perspective, orthographic, a viewport area), the nearest model along it, its point, distance and
	normal, the three flags, a see-through model, and a skinned one picked where it's posed, not at rest. */
class PickTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, within = 1e-4):Bool
		return Math.abs(a - b) < within;

	public static function main():Void {
		rays();
		models();
		skinned();
		sprites();
		pointer();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function camera():Camera3D {
		var c = new Camera3D();
		c.setViewport(800, 600);
		c.setView(0, 0, 10, 0, 0, 0);
		return c;
	}

	static function rays():Void {
		var c = camera(), ray = new Ray();
		check(c.computeRay(400, 300, ray) && near(ray.directionZ, -1) && near(ray.originX, 0) && near(ray.originZ, 10 - c.near),
			"The middle pixel looks straight ahead, from the near plane");
		check(c.computeRay(800 - 1e-6, 300, ray) && ray.directionX > 0, "Right of the middle, to the right");
		check(c.computeRay(400, 0, ray) && ray.directionY > 0, "The top row looks up: y is turned over");
		check(!c.computeRay(-1, -1, ray) && !c.computeRay(800, 300, ray), "Off the viewport: no ray");
		// An orthographic camera's rays run parallel, each from its own place (wgrender-c's 526ff15: picks built a perspective and missed).
		c.setOrthographic(6, .1, 100);
		check(c.computeRay(400, 0, ray) && near(ray.directionY, 0) && near(ray.originY, 3), "Orthographic: parallel rays from the edge");
		// A viewport area: its own middle looks straight ahead; outside it, nothing.
		var area = camera();
		check(area.setViewportArea(400, 0, 400, 300)
			&& area.computeRay(600, 150, ray)
			&& near(ray.directionX, 0)
			&& near(ray.directionY, 0)
			&& !area.computeRay(100, 150, ray),
			"A viewport area's middle looks ahead; a point outside it has no ray");
	}

	static function models():Void {
		var stage = new Stage3D(new CountingGraphics()), c = camera();
		var front = new Model(Mesh.cube(2, 2, 2), new Material()),
			back = new Model(Mesh.cube(2, 2, 2), new Material());
		front.setPosition(0, 0, 2);
		back.setPosition(0, 0, -2);
		stage.add(back);
		stage.add(front);
		var hit = stage.pick(c, 400, 300);
		check(hit != null && hit.node == front && near(hit.getPoint(2), 3) && near(hit.distance, 7 - c.near),
			"The nearer cube, at its face, the distance from the near plane");
		check(near(hit.getNormal(2), 1) && near(hit.getLocalPoint(2), 1), "The face's normal toward the camera; the point in the cube's space");
		check(stage.pick(c, 10, 10) == null, "Nothing in a corner");
		front.visible = false;
		check(stage.pick(c, 400, 300).node == front, "A hidden model is still hit");
		front.pickable = false;
		check(stage.pick(c, 400, 300).node == back, "An unpickable one lets the ray through");
		front.pickable = true;
		var child = new Model(Mesh.cube(1, 1, 1), new Material());
		child.setPosition(0, 0, 3);
		front.addChild(child);
		front.pickable = false;
		check(stage.pick(c, 400, 300).node == child, "An unpickable node's child is still hit");
		front.enabled = false;
		check(stage.pick(c, 400, 300).node == back, "A disabled node takes its children with it");
		front.enabled = true;
		front.pickable = true;
		// See-through: hit only where its alpha reaches a half.
		var glass = new Material();
		glass.blended = true;
		glass.baseColor = 0xffffff40;
		child.material = glass;
		check(stage.pick(c, 400, 300).node == front, "A faint see-through model isn't hit");
		// Stretched: a slanted face's normal goes by the inverse transpose (the plane x + z = 0, x stretched 4 times: x / 4 + z = 0), a unit
		// vector toward the camera.
		var slab = new Model(Mesh.fromArrays([-1., -1, 1, 1, -1, -1, 0, 1, 0], null, null, null, null), new Material());
		slab.setScale(4, 1, 1);
		var side = new Stage3D(new CountingGraphics());
		side.add(slab);
		var slanted = side.pick(c, 400, 300), length = Math.sqrt(1 / 16 + 1);
		check(slanted != null
			&& near(slanted.getNormal(0), .25 / length)
			&& near(slanted.getNormal(2), 1 / length)
			&& near(slanted.getPoint(2), 0),
			"A stretched face's normal by the inverse transpose, a unit vector toward the camera");
		var inside = new Camera3D();
		inside.setViewport(800, 600);
		inside.setView(0, 0, 0, 0, 0, -1);
		var room = new Stage3D(new CountingGraphics());
		room.add(new Model(Mesh.cube(2, 2, 2), new Material()));
		var fromInside = room.pick(inside, 400, 300);
		check(fromInside != null && fromInside.getNormal(2) > 0, "From inside, the normal faces back along the ray");
		var kept = new PickHit();
		check(stage.pick(c, 400, 300, kept) == kept && stage.pick(c, 10, 10, kept) == null && kept.node == null,
			"A given hit is filled in, and cleared on a miss");
	}

	static function skinned():Void {
		// A strip along x on two joints, the knee at x 1; posed with the knee at x 40, it's there, not where it was bound.
		var mesh = Mesh.fromArrays([0., 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 1, 1, 0], null, null, null, null,
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0], [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);
		var skin = new Skin(["hip", "knee"], [
			1., 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 1
		]);
		var character = new Node3D(), hip = new Node3D(), knee = new Node3D();
		hip.name = "hip";
		knee.name = "knee";
		knee.setPosition(1, 0, 0);
		hip.addChild(knee);
		character.addChild(hip);
		var model = new Model(mesh, new Material());
		character.addChild(model);
		model.bindSkeleton(character, skin);
		var stage = new Stage3D(new CountingGraphics());
		stage.add(character);
		var c = new Camera3D();
		c.setViewport(800, 600);
		knee.setPosition(40, 0, 0);
		c.setView(40.6, .3, 10, 40.6, .3, 0);
		var hit = stage.pick(c, 400, 300);
		check(hit != null && hit.node == model && near(hit.getPoint(0), 40.6) && near(hit.getLocalPoint(0), 40.6),
			"A skinned model is hit where its joints put it");
		c.setView(1.6, .3, 10, 1.6, .3, 0);
		check(stage.pick(c, 400, 300) == null, "Not where it was bound (wgrender-c's 6e79587: ghost arms in the rest pose)");
		// Gear swapped: the old part's model off the character, a new one (the strip a unit higher) bound to the same skeleton; the next pick
		// tests the new one as posed, and the old is gone.
		character.removeChild(model);
		var gear = Mesh.fromArrays([0., 1, 0, 1, 1, 0, 0, 2, 0, 1, 1, 0, 2, 1, 0, 1, 2, 0], null, null, null, null,
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0], [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);
		var worn = new Model(gear, new Material());
		check(worn.bindSkeleton(character, skin), "The new part binds to the same skeleton");
		character.addChild(worn);
		c.setView(40.6, .3, 10, 40.6, .3, 0);
		check(stage.pick(c, 400, 300) == null, "Where the old part was posed: nothing now");
		c.setView(40.6, 1.3, 10, 40.6, 1.3, 0);
		var swapped = stage.pick(c, 400, 300);
		check(swapped != null && swapped.node == worn, "The new part, where the skeleton poses it");
	}

	// The framebuffer pixel a world point is drawn at, through c.
	static function pixel(c:Camera3D, x:Float, y:Float, z:Float):Array<Float> {
		var m = c.viewProjection;
		var cx = m.get(0) * x + m.get(4) * y + m.get(8) * z + m.get(12),
			cy = m.get(1) * x + m.get(5) * y + m.get(9) * z + m.get(13),
			cw = m.get(3) * x + m.get(7) * y + m.get(11) * z + m.get(15);
		return [(cx / cw * .5 + .5) * c.viewportWidth, (.5 - cy / cw * .5) * c.viewportHeight];
	}

	static function sprites():Void {
		var gpu = new CountingGraphics(), stage = new Stage3D(gpu), c = camera();
		c.setView(0, 4, 10, 0, 0, 0);
		var logo = new Sprite3D(helix.render2d.Texture2D.fromRgba(gpu, 2, 2, haxe.io.Bytes.alloc(16)));
		logo.setSpriteSize(2, 2);
		logo.setPosition(3, 0, 0);
		stage.add(logo);
		var at = pixel(c, 3.8, .8, 0), hit = stage.pick(c, at[0], at[1]);
		check(hit != null && hit.node == logo, "A camera-facing sprite, near its corner");
		at = pixel(c, 4.3, 0, 0);
		check(stage.pick(c, at[0], at[1]) == null, "Past its edge: missed");
		var label = new Text3D("PICK ME", 1);
		label.setPosition(-3, 0, 0);
		stage.add(label);
		at = pixel(c, -3, 0, 0);
		check(stage.pick(c, at[0], at[1]) == null, "A text isn't pickable until asked");
		label.pickable = true;
		hit = stage.pick(c, at[0], at[1]);
		check(hit != null && hit.node == label, "A text by its block");
		// In front of a model, the sprite wins; behind it, the model does.
		var box = new Model(Mesh.cube(1, 1, 1), new Material());
		box.setPosition(3, 0, -2);
		stage.add(box);
		at = pixel(c, 3, 0, 0);
		check(stage.pick(c, at[0], at[1]).node == logo, "The sprite before the box");
		logo.setPosition(3, 0, -4);
		at = pixel(c, 3, 0, -2);
		check(stage.pick(c, at[0], at[1]).node == box, "The box before the sprite");
	}

	// The pointer over a world and a HUD: hover, press, a click released over what was pressed, a drag released elsewhere, and capture.
	static function pointer():Void {
		var gpu = new CountingGraphics(), world = new Stage3D(gpu), c = camera(), input = new helix.input.InputState();
		var cube = new Model(Mesh.cube(2, 2, 2), new Material());
		world.add(cube);
		var hud = new helix.render2d.Stage2D(),
			hudCamera = new helix.render2d.Camera2D();
		hudCamera.setViewport(800, 600);
		hudCamera.pixels(1);
		var button = helix.render2d.Node2D.rectangle(100, 40);
		button.setPosition(10, 10);
		hud.add(button);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage3D(world, c);
		pointer.addStage2D(hud, hudCamera);
		function frame(x:Float, y:Float, down:Bool):Void {
			input.endFrame();
			input.pointerEvent(x, y, down);
			pointer.update();
		}
		frame(400, 300, false);
		check(pointer.isHovered(cube) && pointer.hit3D != null && !pointer.isPressed(cube), "The cube under the pointer, its hit at hand");
		frame(400, 300, true);
		check(pointer.isPressed(cube) && pointer.isDown(cube) && !pointer.captured, "Pressed on the cube; the world doesn't capture");
		frame(400, 300, false);
		check(pointer.isClicked(cube) && !pointer.isDown(cube), "Released over it: a click");
		frame(400, 300, true);
		frame(10, 590, true);
		check(pointer.isDown(cube) && !pointer.isHovered(cube), "Dragged off: still held");
		frame(10, 590, false);
		check(!pointer.isClicked(cube) && pointer.held == null, "Released elsewhere: no click");
		// The HUD over the world: its button first, and a press on it captures the pointer from the world.
		frame(50, 30, false);
		check(pointer.isHovered(button), "The HUD's button, drawn over the world, first");
		frame(50, 30, true);
		check(pointer.captured && pointer.isPressed(button), "A press on the HUD captures");
		frame(400, 300, true);
		check(pointer.hovered == null && pointer.isDown(button), "Captured: the world under the pointer sees nothing");
		frame(400, 300, false);
		check(!pointer.captured && !pointer.isClicked(button), "Released off the button: no click, the capture let go");
		frame(400, 300, false);
		check(pointer.isHovered(cube), "The world has the pointer again");
	}
}
