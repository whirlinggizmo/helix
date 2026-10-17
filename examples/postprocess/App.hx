import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.PostProcess;
import helix.graphics.ScreenEffect;
import helix.graphics.Shaders;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Screen effects over the finished frame (PostProcess, ScreenEffect). The frame is an ordinary lit stage: the Kenney sports car on a floor, generated
	shapes, a circling point light. The effects are the example's own shaders (shaders/vignette.glsl and scanlines.glsl, packed into
	.hxshader assets and loaded at run time):
	- the vignette darkens the corners and warms the middle
	- the scanlines darken alternating rows, shift red and blue apart, and flicker
	Both apply in the order given, each on or off. Their parameters are set by name any frame: the vignette breathes in and out, and the arrow
	keys change how dark it gets. Edit a .glsl while the dev server runs and the effect reloads in place.

	1 / 2: the vignette / the scanlines on and off; Up / Down: the vignette's strength; Space: stop the breathing; O: stop the camera; Escape:
	quit, where quitting means anything. */
class App extends BaseApp {
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var post:PostProcess;
	var shaders:Shaders;
	var vignette:Null<ScreenEffect>;
	var scanlines:Null<ScreenEffect>;
	var lamp:Node;
	var strength = .8;
	var breathing = true;
	var orbit = true;
	var angle = 0.;
	var status = "loading the effects";

	override public function init():Void {
		Services.window.setTitle("HeliX postprocess");
		Services.window.requestSize(1000, 600);
		var gpu = Services.graphics;
		batch = new Batch2D(gpu);
		post = new PostProcess(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .2);
		// Framed for 16:9: the car and the shapes around it in view on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(2);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var lampLight = new Light(Point);
		lampLight.setColor(0xff9a4aff);
		lampLight.setIntensity(12);
		lamp = Node.light(lampLight);
		stage.add(lamp);
		var floor = new Material();
		floor.setBaseColor(0x5c6066ff);
		floor.setRoughness(.9);
		stage.add(Node.model(Mesh.plane(14, 14), floor));
		var shapes = [Mesh.sphere(.6), Mesh.cube(1, 1, 1), Mesh.torus(.5, .18), Mesh.cone(.5, 1.1)];
		var colors = [0x3b82f6ff, 0xe5484dff, 0xf5b942ff, 0x46a758ff];
		for (i in 0...shapes.length) {
			var material = new Material();
			material.setBaseColor(colors[i]);
			material.setRoughness(.35);
			var model = Node.model(shapes[i], material);
			var a = i / shapes.length * Math.PI * 2 + .4;
			model.setPosition(Math.cos(a) * 3.5, .6, Math.sin(a) * 3.5);
			stage.add(model);
		}
		new Models(Services.assets, Services.textures).load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				var car = file.instantiate("car");
				car.setScale(1.5, 1.5, 1.5);
				stage.add(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});

		shaders = new Shaders(Services.assets, gpu);
		shaders.load("shaders/vignette.hxshader", result -> switch result {
			case Ready(shader):
				vignette = new ScreenEffect(gpu, shader);
				vignette.getParameters().setFloat("radius", .35);
				vignette.getParameters().setColor("tint", 0xfff2deff);
				status = "";
			case Failed(message):
				status = message;
			case Cancelled:
		});
		shaders.load("shaders/scanlines.hxshader", result -> switch result {
			case Ready(shader):
				scanlines = new ScreenEffect(gpu, shader);
				scanlines.getParameters().setFloat("lines", 240);
				scanlines.getParameters().setFloat("darkness", .35);
				scanlines.getParameters().setFloat("offset", 1.5);
				scanlines.getParameters().setFloat("flicker", 1);
			case Failed(message):
				status = message;
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		if (input.isFramePressed(Key.Digit1) && vignette != null)
			vignette.setEnabled(!vignette.isEnabled());
		if (input.isFramePressed(Key.Digit2) && scanlines != null)
			scanlines.setEnabled(!scanlines.isEnabled());
		if (input.isFramePressed(Key.Space))
			breathing = !breathing;
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (input.isDown(Key.Up))
			strength = Math.min(1, strength + dt * .5);
		if (input.isDown(Key.Down))
			strength = Math.max(0, strength - dt * .5);
		// The game's clock: paused, the motion stops.
		var time = Services.clock.getTime();
		if (orbit)
			angle += dt * .2;
		fps.update(dt, Services.getFrameCpu());
		lamp.setPosition(Math.cos(time) * 2.5, 1.2, Math.sin(time) * 2.5);
		if (vignette != null)
			vignette.getParameters().setFloat("strength", strength * (breathing ? .75 + .25 * Math.sin(time * 2) : 1));
		var gpu = Services.graphics,
			width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(9 * Math.sin(angle), 4.5, 9 * Math.cos(angle), 0, .5, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		// The scene into a texture, the effects but the last through two more, then the screen.
		post.beginScene(width, height, 0x14161cff);
		stage.draw(camera);
		post.endScene([for (e in [vignette, scanlines]) if (e != null) e], time);
		gpu.beginFrame(width, height, 0x000000ff);
		post.present();
		batch.begin(hud);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX postprocess: screen effects over the finished frame", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		inline function onOff(e:Null<ScreenEffect>):String
			return e == null ? "loading" : e.isEnabled() ? "on" : "off";
		y += Text2D.drawWrapped(batch,
			'[1] vignette ${onOff(vignette)}  [2] scanlines ${onOff(scanlines)}  [Up/Down] strength ${Math.round(strength * 100) / 100}  [Space] breathing ${breathing ? "on" : "off"}  [O] camera',
			vx + 12, y, 16, vw - 24, 0xc8c8c8ff)
			+ 4;
		if (status != "")
			Text2D.drawWrapped(batch, status, vx + 12, y, 16, vw - 24, 0xff8080ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		gpu.endFrame();
	}

	override public function cleanup():Void {
		for (e in [vignette, scanlines])
			if (e != null)
				shaders.release(e.getShader());
		post.destroy();
		stage.destroy();
		batch.destroy();
	}
}
