import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Font2D;
import helix.render2d.Fonts;
import helix.render2d.Text2D;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Text in the world, and 3D lines: labels facing the camera above a cube, a sphere and a panel (the built-in font), a sign whose text turns
	with its node (Komika, loaded from a file), and circles and a spiral drawn on the ground with Batch3D's lines. Text is sharp at any distance
	(a distance-field font), unlit and blended, laid out with the font's advances and kerning. O stops the camera; Escape quits where quitting
	means anything. */
class App extends BaseApp {
	var services:Services;
	var stage:Stage3D;
	var lines:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var sign:Node;
	var signText:Node;
	var cube:Node;
	var orbit = true;
	var angle = 0.;
	var time = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	// A model of mesh in color at x, y, z, with a label above it, facing the camera.
	function labelled(mesh:Mesh, color:Int, x:Float, y:Float, z:Float, label:String, labelHeight:Float):Node {
		var material = new Material();
		material.setBaseColor(color);
		material.setRoughness(.5);
		var model = Node.model(mesh, material);
		model.setPosition(x, y, z);
		stage.add(model);
		var text = Node.text3D(label, .4, 0xf5f5f5ff);
		text.setPosition(x, labelHeight, z);
		stage.add(text);
		return model;
	}

	override public function init():Void {
		services.window.setTitle("HeliX text3d");
		services.window.requestSize(1000, 600);
		// Framed for 16:9: all three models and their labels on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var gpu = services.graphics;
		batch = new Batch2D(gpu);
		lines = new Batch3D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(2.5);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		cube = labelled(Mesh.cube(1, 1, 1), 0x3b82f6ff, -3, .5, 0, "cube", 1.6);
		labelled(Mesh.sphere(.6), 0xe5484dff, 0, .6, 0, "sphere", 1.8);
		labelled(Mesh.cube(1.4, .9, .1), 0x46a758ff, 3, .45, 0, "panel", 1.5);
		// A sign: a post, a board, and text on the board's face that turns with it.
		var wood = new Material();
		wood.setBaseColor(0x8b5a2bff);
		wood.setRoughness(.9);
		sign = Node.group();
		sign.setPosition(0, 0, -3);
		var post = Node.model(Mesh.cube(.12, 1.6, .12), wood);
		post.setPosition(0, .8, 0);
		sign.add(post);
		var board = Node.model(Mesh.cube(2.2, .8, .08), wood);
		board.setPosition(0, 1.6, 0);
		sign.add(board);
		signText = Node.text3D("HeliX text", .45, 0xffe68cff);
		signText.setFacing(Free);
		signText.setPosition(0, 1.6, .05);
		sign.add(signText);
		stage.add(sign);
		new Fonts(services.assets, gpu).load("fonts/Komika/KOMIKAH_.ttf", result -> switch result {
			case Ready(font):
				signText.setFont(font);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		time += dt;
		if (orbit)
			angle += dt * .25;
		fps.update(dt, services.getFrameCpu());
		cube.setRotation(0, time * .8, 0);
		sign.setRotation(0, Math.sin(time * .7) * .9, 0);
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(Math.sin(angle) * 9, 4, Math.cos(angle) * 9, 0, .8, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update(services);
		var presentation = services.presentation;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		services.graphics.beginFrame(width, height, 0x1c1e26ff);
		lines.begin(camera);
		lines.grid(16, 1, 0x34373fff);
		// Circles on the ground under each model, and a spiral around them all.
		for (cx in [-3., 0, 3])
			for (k in 0...48) {
				var a = k / 48 * Math.PI * 2, b = (k + 1) / 48 * Math.PI * 2;
				lines.line(cx + Math.cos(a), .01, Math.sin(a), cx + Math.cos(b), .01, Math.sin(b), 0x66bfffff);
			}
		for (k in 0...200) {
			var a = k * .12, b = (k + 1) * .12;
			lines.line(Math.cos(a) * (1 + a * .25), .01, Math.sin(a) * (1 + a * .25), Math.cos(b) * (1 + b * .25), .01, Math.sin(b) * (1 + b * .25),
				0xffcb00ff);
		}
		lines.end();
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX text3d: labels facing the camera, a sign's text turning with it, lines on the ground", vx + 12, y, 18, vw - 24,
			0xf5f5f5ff)
			+ 4;
		Text2D.drawWrapped(batch, '${stage.getDrawnNodeCount()} models and glyphs in ${stage.getDrawCallCount()} draws   O: the camera', vx + 12, y, 16,
			vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		lines.destroy();
		batch.destroy();
	}
}
