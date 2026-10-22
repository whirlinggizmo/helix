import helix.graphics.Color;
import helix.graphics.PostProcess;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;
import helix.render2d.View2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.View3D;
import helix.shader.Pixelate;
import helix.shader.Vignette;
import helix.time.Time;

/** Views on the stage (helix.render2d.View2D, helix.render3d.View3D; docs/DISPLAY_MODEL.md), nothing drawn by hand:
	- a 2D world wider than the window, shown through a camera that scrolls across it (the arrows push it)
	- the same world again in a minimap, a view inside a panel on the stage, its camera showing all of it, a frame over it marking what the big
	  view sees
	- a 3D view in a corner, a cube turning in its level's light (an Environment3D on the level's root), pixelated by a chain of its own
	  (View.postProcess), so drawn into a texture and placed in the 2D's order: the minimap's panel overlaps it (the panel's edge overlaps it)
	- the title straight on the stage, in pixels, over all of it
	- a vignette over everything, the stage's own chain (Stage.postProcess) */
class App extends helix.App {
	static inline var WORLD_WIDTH = 2400.;
	static inline var WORLD_HEIGHT = 600.;

	var world = new Node2D();
	var worldCamera = new Camera2D();
	var mapCamera = new Camera2D();
	var marker = Shape2D.rectangle(1, 1, 0xffffd040);
	var cube = new Model3D(Mesh3D.cube(1, 1, 1), new Material3D());
	var scroll = 0.;

	override public function init():Void {
		Window.title = "HeliX views";
		Stage.color = 0xff14161c;
		// A vignette over everything the stage draws, a chain of the stage's own.
		Stage.postProcess = new PostProcess();
		Stage.postProcess.add(new Vignette(.6));
		// The world: a ground and a row of posts, colors running along it.
		world.addChild(Shape2D.rectangle(WORLD_WIDTH, 40, 0xff2f6b3a));
		world.getChild(0).setPosition(0, WORLD_HEIGHT - 40);
		for (i in 0...24) {
			var post = Shape2D.rectangle(40, 80 + (i % 5) * 40, Color.fromChannels(0x30 + i * 8, 0x60, 0xe0 - i * 6));
			post.setPivot(0, 1);
			post.setPosition(40 + i * 100, WORLD_HEIGHT - 40);
			world.addChild(post);
		}
		marker.outline = 4;
		var big = new View2D(world, worldCamera);
		Stage.addChild(big);

		// The 3D view: a cube under a sun, in its level's light.
		var level = new Node3D(),
			sun = new DirectionalLight3D(),
			eye = new Camera3D();
		// The place's light, on the level's root: a soft blue ambient under the sun.
		level.environment = new Environment3D();
		level.environment.setAmbient(0xffa0b4dc, .35);
		sun.lookAt(-.4, -1, -.3);
		sun.intensity = 2.5;
		level.addChild(sun);
		cube.material.baseColor = 0xffe8a33c;
		level.addChild(cube);
		eye.setView(0, 1.5, 3.5, 0, 0, 0);
		var view3D = new View3D(level, eye, 240, 180);
		// Pixelated by a chain of its own: drawn into a texture first, so it sits in the 2D's order (the panel below overlaps it).
		view3D.postProcess = new PostProcess();
		view3D.postProcess.add(new Pixelate(4));
		view3D.setPosition(20, 60);
		Stage.addChild(view3D);

		// The minimap: a panel, and in it the same world through a camera showing all of it, the big view's sight marked.
		var panel = Shape2D.rectangle(500, 140, 0xff23283a);
		panel.setPosition(200, 200);
		Stage.addChild(panel);
		var map = new View2D(world, mapCamera, 480, 120);
		map.setPosition(210, 210);
		Stage.addChild(map);
		Stage.addChild(marker);

		var title = new Text2D("HeliX views: a world, its minimap and a 3D view, nothing drawn by hand. Arrows scroll", 16, 0xffebeef5);
		title.setPosition(20, 20);
		Stage.addChild(title);
	}

	override public function update(dt:Float):Void {
		var push = (Input.isDown(Key.Right) ? 1 : 0) - (Input.isDown(Key.Left) ? 1 : 0);
		scroll = push != 0 ? scroll + push * 600 * dt : scroll + 120 * dt;
		var ratio = Window.pixelRatio, seen = Window.width;
		scroll = scroll % (WORLD_WIDTH - seen);
		if (scroll < 0)
			scroll += WORLD_WIDTH - seen;
		// The big view: a world unit a logical pixel, its left edge at the scroll.
		worldCamera.zoom = ratio;
		worldCamera.setPosition(scroll + seen / 2, WORLD_HEIGHT - Window.height / 2);
		// The minimap: all of the world in its 480 x 120.
		mapCamera.zoom = ratio * Math.min(480 / WORLD_WIDTH, 120 / WORLD_HEIGHT);
		mapCamera.setPosition(WORLD_WIDTH / 2, WORLD_HEIGHT / 2);
		// The big view's sight, marked over the minimap, at the minimap's scale.
		var scale = Math.min(480 / WORLD_WIDTH, 120 / WORLD_HEIGHT);
		marker.setSize(seen * scale, Window.height * scale);
		marker.setPosition(210 + scroll * scale, 210 + (WORLD_HEIGHT - Window.height) * scale);
		cube.setRotation(.4, Time.time * .8, 0);
	}
}
