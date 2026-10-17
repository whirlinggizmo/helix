import helix.app.BaseApp;
import helix.assets.Assets;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.graphics.PostProcess;
import helix.graphics.ScreenEffect;
import helix.graphics.Shaders;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Models;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;
import helix.time.Time;

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
	var lamp:PointLight;
	var strength = .8;
	var breathing = true;
	var orbit = true;
	var angle = 0.;
	var status = "loading the effects";

	override public function init():Void {
		Window.title = "HeliX postprocess";
		Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		post = new PostProcess(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .2);
		// Framed for 16:9: the car and the shapes around it in view on a phone held upright too.
		camera.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 2;
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		lamp = new PointLight();
		lamp.color = 0xff9a4aff;
		lamp.intensity = 12;
		stage.add(lamp);
		var floor = new Material();
		floor.baseColor = 0x5c6066ff;
		floor.roughness = .9;
		stage.add(new Model(Mesh.plane(14, 14), floor));
		var shapes = [Mesh.sphere(.6), Mesh.cube(1, 1, 1), Mesh.torus(.5, .18), Mesh.cone(.5, 1.1)];
		var colors = [0x3b82f6ff, 0xe5484dff, 0xf5b942ff, 0x46a758ff];
		for (i in 0...shapes.length) {
			var material = new Material();
			material.baseColor = colors[i];
			material.roughness = .35;
			var model = new Model(shapes[i], material);
			var a = i / shapes.length * Math.PI * 2 + .4;
			model.setPosition(Math.cos(a) * 3.5, .6, Math.sin(a) * 3.5);
			stage.add(model);
		}
		Models.load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				var car = file.instantiate("car");
				car.setScale(1.5, 1.5, 1.5);
				stage.add(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});

		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/vignette.hxshader", result -> switch result {
			case Ready(shader):
				vignette = new ScreenEffect(gpu, shader);
				vignette.parameters.setFloat("radius", .35);
				vignette.parameters.setColor("tint", 0xfff2deff);
				status = "";
			case Failed(message):
				status = message;
			case Cancelled:
		});
		shaders.load("shaders/scanlines.hxshader", result -> switch result {
			case Ready(shader):
				scanlines = new ScreenEffect(gpu, shader);
				scanlines.parameters.setFloat("lines", 240);
				scanlines.parameters.setFloat("darkness", .35);
				scanlines.parameters.setFloat("offset", 1.5);
				scanlines.parameters.setFloat("flicker", 1);
			case Failed(message):
				status = message;
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Digit1) && vignette != null)
			vignette.enabled = !vignette.enabled;
		if (input.isFramePressed(Key.Digit2) && scanlines != null)
			scanlines.enabled = !scanlines.enabled;
		if (input.isFramePressed(Key.Space))
			breathing = !breathing;
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (input.isDown(Key.Up))
			strength = Math.min(1, strength + dt * .5);
		if (input.isDown(Key.Down))
			strength = Math.max(0, strength - dt * .5);
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		if (orbit)
			angle += dt * .2;
		fps.update(dt, Time.frameCpu);
		lamp.setPosition(Math.cos(time) * 2.5, 1.2, Math.sin(time) * 2.5);
		if (vignette != null)
			vignette.parameters.setFloat("strength", strength * (breathing ? .75 + .25 * Math.sin(time * 2) : 1));
		var gpu = Graphics.instance,
			width = Window.framebufferWidth,
			height = Window.framebufferHeight;
		camera.setViewport(width, height);
		camera.setView(9 * Math.sin(angle), 4.5, 9 * Math.cos(angle), 0, .5, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

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
			return e == null ? "loading" : e.enabled ? "on" : "off";
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
				shaders.release(e.shader);
		post.destroy();
		stage.destroy();
		batch.destroy();
	}
}
