import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.font.Fonts;
import helix.render2d.Stage;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Drawing3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.Text3D;
import helix.render3d.View3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit3D;

/** Text in the world, and 3D lines, in a View3D on the stage: labels facing the camera above a cube, a sphere and a panel (the built-in
	font), a sign whose text turns with its node (Komika, loaded from a file), and circles and a spiral drawn on the ground by a Drawing3D's
	lines. Text is sharp at any distance
	(a distance-field font), unlit and blended, laid out with the font's advances and kerning. O stops the camera; Escape quits where quitting
	means anything. */
class App extends helix.App {
	var level = new Node3D();
	var view:View3D;
	var camera = new Camera3D();
	var hud = new Drawing2D();
	var fps = new FpsOverlay();
	var sign:Node3D;
	var signText:Text3D;
	var cube:Model3D;
	// The camera, circling.
	var orbit = new Orbit3D(9, 4, .25, .8);

	// A model of mesh in color at x, y, z, with a label above it, facing the camera.
	function labelled(mesh:Mesh3D, color:Int, x:Float, y:Float, z:Float, label:String, labelHeight:Float):Model3D {
		var material = new Material3D();
		material.baseColor = color;
		material.roughness = .5;
		var model = new Model3D(mesh, material);
		model.setPosition(x, y, z);
		level.addChild(model);
		var text = new Text3D(label, .4, 0xfff5f5f5);
		text.setPosition(x, labelHeight, z);
		level.addChild(text);
		return model;
	}

	override public function init():Void {
		Window.title = "HeliX text3d";
		Window.requestSize(1000, 600);
		// Framed for 16:9: all three models and their labels on a phone held upright too.
		camera.minAspect = 16 / 9;
		Stage.color = 0xff1c1e26;
		level.environment = new Environment3D();
		level.environment.setAmbient(0xffffffff, .3);
		var sun = new DirectionalLight3D();
		sun.intensity = 2.5;
		sun.lookAt(-.5, -1, -.4);
		level.addChild(sun);
		cube = labelled(Mesh3D.cube(1, 1, 1), 0xff3b82f6, -3, .5, 0, "cube", 1.6);
		labelled(Mesh3D.sphere(.6), 0xffe5484d, 0, .6, 0, "sphere", 1.8);
		labelled(Mesh3D.cube(1.4, .9, .1), 0xff46a758, 3, .45, 0, "panel", 1.5);
		// A sign: a post, a board, and text on the board's face that turns with it.
		var wood = new Material3D();
		wood.baseColor = 0xff8b5a2b;
		wood.roughness = .9;
		sign = new Node3D();
		sign.setPosition(0, 0, -3);
		var post = new Model3D(Mesh3D.cube(.12, 1.6, .12), wood);
		post.setPosition(0, .8, 0);
		sign.addChild(post);
		var board = new Model3D(Mesh3D.cube(2.2, .8, .08), wood);
		board.setPosition(0, 1.6, 0);
		sign.addChild(board);
		signText = new Text3D("HeliX text", .45, 0xffffe68c);
		signText.facing = Free;
		signText.setPosition(0, 1.6, .05);
		sign.addChild(signText);
		level.addChild(sign);
		Fonts.load("fonts/Komika/KOMIKAH_.ttf", font -> signText.font = font);
		// The ground's lines: a grid, circles under each model, and a spiral around them all.
		var lines = new Drawing3D();
		lines.grid(16, 1, 0xff34373f);
		for (cx in [-3., 0, 3])
			for (k in 0...48) {
				var a = k / 48 * Math.PI * 2, b = (k + 1) / 48 * Math.PI * 2;
				lines.line(cx + Math.cos(a), .01, Math.sin(a), cx + Math.cos(b), .01, Math.sin(b), 0xff66bfff);
			}
		for (k in 0...200) {
			var a = k * .12, b = (k + 1) * .12;
			lines.line(Math.cos(a) * (1 + a * .25), .01, Math.sin(a) * (1 + a * .25), Math.cos(b) * (1 + b * .25), .01, Math.sin(b) * (1 + b * .25),
				0xffffcb00);
		}
		level.addChild(lines);
		view = new View3D(level, camera);
		Stage.addChild(view);
		Stage.addChild(hud);
		Stage.addChild(fps);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		if (Input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		cube.setRotation(0, time * .8, 0);
		sign.setRotation(0, Math.sin(time * .7) * .9, 0);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;
		fps.setPosition(vx + 12, vy + 10);
		hud.clear();
		var y = vy + 36;
		y += hud.drawTextWrapped("HeliX text3d: labels facing the camera, a sign's text turning with it, lines on the ground", vx + 12, y, 18, vw - 24,
			0xfff5f5f5)
			+ 4;
		hud.drawTextWrapped('${view.drawnNodeCount} models and glyphs in ${view.drawCallCount} draws   O: the camera', vx + 12, y, 16, vw - 24, 0xffc8c8c8);
	}
}
