import Render2DTests.CountingGraphics;
import helix.host.Presentation;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.StageService;
import helix.render2d.View2D;
import helix.render3d.Camera3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.View3D;

/** Views (helix.render2d.View2D, helix.render3d.View3D) on the stage: a 2D view's camera given its rectangle in framebuffer pixels, scaled
	with the view and filling what shows it at a size of 0; its tree drawn through its camera, clipped; views nested, their rectangles inside
	the outer view's; a view showing a tree it's in skipped, not drawn forever; a tree two views show drawn by both; a 3D view drawn, its
	camera given its rectangle, lit by its own environment, else its tree's first; picking through them, 2D before 3D, a paused tree passed
	over, and the pointer reading the stage. */
@:access(helix)
class ViewTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var gpu = new CountingGraphics(), presentation = new Presentation();
		@:privateAccess presentation.refit(800, 600, 1);
		var stage = new StageService(gpu, presentation);

		// A view 200 x 100 at 100, 50, showing a world through a camera of its own.
		var world = new Node2D(), camera = new Camera2D();
		world.addChild(Shape2D.rectangle(10, 10, 0xff102030));
		world.addChild(Shape2D.circle(5, 0xff66bfff));
		var view = new View2D(world, camera, 200, 100);
		view.setPosition(100, 50);
		stage.addChild(view);
		stage.draw(0);
		check(camera.viewportX == 100 && camera.viewportY == 50 && camera.viewportWidth == 200 && camera.viewportHeight == 100,
			"Its camera's viewport is its rectangle, in framebuffer pixels");
		check(@:privateAccess view.tree.drawnNodeCount == 2 && stage.drawnNodeCount == 1, "Its tree drawn through it; the view counted on the stage");
		view.setScale(2, 2);
		stage.draw(0);
		check(camera.viewportWidth == 400 && camera.viewportHeight == 200, "Scaled with the view");
		view.width = 0;
		stage.draw(0);
		check(camera.viewportX == 0 && camera.viewportY == 0 && camera.viewportWidth == 800 && camera.viewportHeight == 600,
			"A size of 0: the whole area of what shows it");

		// A view in the world the first view shows: its rectangle in the outer view's camera, inside the outer view.
		view.width = 400;
		view.height = 300;
		view.setScale(1, 1);
		view.setPosition(0, 0);
		camera.setPosition(200, 150);
		var inner = new Node2D(), innerCamera = new Camera2D();
		inner.addChild(Shape2D.rectangle(4, 4, 0xffffffff));
		var minimap = new View2D(inner, innerCamera, 100, 50);
		minimap.setPosition(10, 20);
		world.addChild(minimap);
		stage.draw(0);
		check(innerCamera.viewportX == 10 && innerCamera.viewportY == 20 && innerCamera.viewportWidth == 100 && innerCamera.viewportHeight == 50,
			"A nested view's rectangle through the view it's in");
		check(@:privateAccess minimap.tree.drawnNodeCount == 1, "A nested view's tree drawn");

		// A view showing the world it's in: refused, the frame drawn.
		var loop = new View2D(world, new Camera2D(), 50, 50);
		world.addChild(loop);
		stage.draw(0);
		check(@:privateAccess loop.tree.drawnNodeCount == 0 && gpu.framesEnded > 0, "A view of a tree it's in is skipped, not drawn forever");
		world.removeChild(loop);

		// The same world through a second view on the stage: both draw it.
		var second = new View2D(world, new Camera2D(), 100, 100);
		second.setPosition(500, 0);
		stage.addChild(second);
		stage.draw(0);
		check(@:privateAccess second.tree.drawnNodeCount == 3 && @:privateAccess view.tree.drawnNodeCount == 3, "One tree, two views, drawn by both");

		// A 3D view: its tree drawn under the 2D, through its camera sized to its rectangle.
		var level = new Node3D(), eye = new Camera3D();
		level.addChild(new Model3D(Mesh3D.cube(1, 1, 1), new Material3D()));
		eye.setView(0, 2, 5, 0, 0, 0);
		var view3D = new View3D(level, eye, 320, 240, gpu);
		view3D.setPosition(40, 30);
		stage.addChild(view3D);
		stage.draw(0);
		check(eye.viewportX == 40 && eye.viewportY == 30 && eye.viewportWidth == 320 && eye.viewportHeight == 240, "A 3D view's camera sized to its rectangle");
		check(view3D.drawnNodeCount == 1, "Its tree drawn");
		// Between the stage and its world: the point it looks at seen at its rectangle's middle, in the stage's units, and that stage point's
		// ray back to the ground there.
		@:privateAccess helix.render2d.Stage.bind(stage);
		var middle = view3D.project(0, 0, 0);
		check(middle != null && Math.abs(middle.x - 200) < 1e-6 && Math.abs(middle.y - 150) < 1e-6, "The point it looks at, at its middle on the stage");
		var ray = view3D.computeRay(200, 150),
			floor = ray != null ? ray.pointAt(ray.hitHeight(0)) : null;
		check(floor != null && Math.abs(floor.x) < 1e-6 && Math.abs(floor.z) < 1e-6, "That stage point's ray reaches the ground at the point");
		check(view3D.computeRay(10, 10) == null, "A stage point outside it has no ray");
		@:privateAccess helix.render2d.Stage.bind(null);
		stage.draw(0);
		check(view3D.drawnNodeCount == 1, "And again, its shadows prepared before the frame");
		check(@:privateAccess view3D.world.ambientIntensity == 0, "No environment anywhere: no ambient light");

		// The place's light: the root's, then the first in the tree, and the view's own over either.
		var place = new Environment3D();
		place.setAmbient(0xff8090a0, .4);
		level.environment = place;
		stage.draw(0);
		check(@:privateAccess view3D.world.ambientIntensity == .4 && @:privateAccess view3D.world.ambientColor == 0xff8090a0,
			"The root's environment lights it");
		level.environment = null;
		var group = new Node3D(), inner = new Environment3D();
		inner.setAmbient(0xffffffff, .7);
		group.environment = inner;
		level.addChild(group);
		stage.draw(0);
		check(@:privateAccess view3D.world.ambientIntensity == .7, "Else the first in its tree (a scene file's group under the root)");
		var flat = new Environment3D();
		flat.setAmbient(0xffffffff, 1);
		view3D.environment = flat;
		stage.draw(0);
		check(@:privateAccess view3D.world.ambientIntensity == 1, "The view's own overrides the tree's");
		check(!place.setAmbient(0xffffffff, -1) && !place.setMap(null, -1) && !place.setBackground(null, 2) && place.ambientIntensity == .4,
			"An environment refuses a negative intensity and a blur past 1, changing nothing");

		// A Drawing3D: drawn where its node is, after the models, by the renderer's batch.
		var debug = new helix.render3d.Drawing3D();
		debug.grid(4, 1, 0xff404040);
		debug.cubeWires(0, 1, 0, 1, 1, 1, 0xffffff00);
		debug.setPosition(2, 0, 0);
		level.addChild(debug);
		stage.draw(0);
		var batch3:helix.render3d.Batch3D = @:privateAccess view3D.world.ownBatch;
		check(debug.callCount == 2 && batch3 != null && batch3.vertexCount > 0, "A Drawing3D drawn by the view's renderer");
		var data:haxe.io.Bytes = @:privateAccess batch3.lines;
		check(Math.abs(data.getFloat(Color3DProgram.positionOffset) - (2 - 2)) < 1e-5, "Carried by its node's transform (the grid's first line at x -2 + 2)");
		level.removeChild(debug);

		// Picking through the stage: a node on it, one a 2D view shows, a 3D view's model under the 2D, a paused tree passed over.
		view3D.environment = null;
		var picks = new StageService(gpu, presentation);
		var button = Shape2D.rectangle(100, 40, 0xff3366cc),
			shown = new Node2D(),
			target = Shape2D.rectangle(50, 50, 0xffffffff);
		button.setPosition(600, 500);
		shown.addChild(target);
		var window = new View2D(shown, new Camera2D(), 200, 200);
		window.camera.setPosition(25, 25);
		window.setPosition(300, 300);
		var scene = new Node3D(),
			eye3D = new Camera3D(),
			box = new Model3D(Mesh3D.cube(2, 2, 2), new Material3D());
		scene.addChild(box);
		eye3D.setView(0, 0, 5, 0, 0, 0);
		var world3D = new View3D(scene, eye3D, 0, 0, gpu);
		picks.addChild(world3D);
		picks.addChild(window);
		picks.addChild(button);
		picks.draw(0);
		check(picks.pick(620, 510) == button, "A node on the stage");
		check(picks.pick(400, 400) == target, "A node a 2D view shows, through its camera");
		check(picks.pick(100, 100) == null && picks.pick(400, 300) == box, "Nothing, then a 3D view's model where no 2D is");
		check(picks.pick(400, 400) == target, "2D before the 3D under it (the box is there too)");
		shown.paused = true;
		check(picks.pick(400, 400) == box, "A paused tree isn't picked: the 3D under it is");
		shown.paused = false;
		// The pointer, with no stages of its own, reads the stage.
		var input = new helix.input.InputState(),
			pointer = new helix.scene.Pointer(input);
		@:privateAccess helix.render2d.Stage.bind(picks);
		input.pointerEvent(400, 400, false);
		pointer.update();
		check(pointer.hovered == target && pointer.hit3D == null, "The pointer over the stage's views");
		input.pointerEvent(400, 300, false);
		pointer.update();
		check(pointer.hovered == box && pointer.hit3D != null, "and over the 3D under them, with its hit");
		@:privateAccess helix.render2d.Stage.bind(null);

		// A view with effects: drawn into a texture before the frame (from its second, at the size it was shown), then placed in the 2D's
		// order; picked in the texture's space.
		window.postProcess = new helix.graphics.PostProcess(gpu);
		picks.draw(0);
		check(@:privateAccess window.output == null, "The first frame: its size known, nothing drawn yet");
		picks.draw(0);
		var output = @:privateAccess window.output;
		check(output != null && output.width == 200 && output.height == 200, "Then drawn into a texture its size");
		check(picks.pick(400, 400) == target, "Picked through its texture's space");
		window.destroy();
		check(@:privateAccess window.output == null, "destroy frees its texture");
		// A 3D view inside a view with effects: drawn into that view's scene with its 2D, not on the screen under everything.
		var holder = new Node2D(),
			inner3D = new View3D(scene, new Camera3D(), 100, 100, gpu);
		inner3D.camera.setView(0, 0, 5, 0, 0, 0);
		holder.addChild(inner3D);
		var effected = new View2D(holder, new Camera2D(), 200, 200);
		effected.camera.setPosition(100, 100);
		effected.postProcess = new helix.graphics.PostProcess(gpu);
		var only = new StageService(gpu, presentation);
		only.addChild(effected);
		only.draw(0);
		only.draw(0);
		check(inner3D.drawnNodeCount == 1 && inner3D.camera.viewportWidth == 100 && @:privateAccess only.shadows.length == 0,
			"Drawn into the view's texture (its camera sized there), not deferred to the screen");
		effected.destroy();
		inner3D.destroy();
		only.destroy();

		// A picture taken when asked: a 3D tree drawn into a texture, its camera sized to it; a view's clear color and texture.
		var picture = helix.texture.Texture2D.renderTarget(64, 48, gpu);
		var portrait = new View3D(scene, new Camera3D(), 0, 0, gpu);
		portrait.camera.setView(0, 0, 5, 0, 0, 0);
		gpu.targetPasses = [];
		portrait.drawToTexture(picture, 0xff102030);
		check(gpu.targetPasses.length == 1
			&& gpu.targetPasses[0] == picture.handle
			&& portrait.camera.viewportWidth == 64
			&& portrait.drawnNodeCount == 1,
			"drawToTexture: one pass into the target, the camera sized to it, the tree drawn");
		var tinted = new View2D(shown, new Camera2D(), 50, 50);
		tinted.color = 0xff336699;
		tinted.postProcess = new helix.graphics.PostProcess(gpu);
		check(tinted.texture == null, "No texture before its first");
		portrait.destroy();
		world3D.destroy();
		picks.destroy();
		view3D.destroy();
		stage.destroy();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
