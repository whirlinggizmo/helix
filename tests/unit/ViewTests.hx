import Render2DTests.CountingGraphics;
import helix.host.Presentation;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.StageService;
import helix.render2d.View2D;
import helix.render3d.Camera3D;
import helix.render3d.Environment3D;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.View3D;

/** Views (helix.render2d.View2D, helix.render3d.View3D) on the stage: a 2D view's camera given its rectangle in framebuffer pixels, scaled
	with the view and filling what shows it at a size of 0; its tree drawn through its camera, clipped; views nested, their rectangles inside
	the outer view's; a view showing a tree it's in skipped, not drawn forever; a tree two views show drawn by both; a 3D view drawn, its
	camera given its rectangle, lit by its own environment, else its tree's first. */
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
		level.addChild(new Model(Mesh.cube(1, 1, 1), new Material()));
		eye.setView(0, 2, 5, 0, 0, 0);
		var view3D = new View3D(level, eye, 320, 240, gpu);
		view3D.setPosition(40, 30);
		stage.addChild(view3D);
		stage.draw(0);
		check(eye.viewportX == 40 && eye.viewportY == 30 && eye.viewportWidth == 320 && eye.viewportHeight == 240, "A 3D view's camera sized to its rectangle");
		check(view3D.drawnNodeCount == 1, "Its tree drawn");
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
		view3D.destroy();
		stage.destroy();
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
