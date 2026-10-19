import helix.app.BaseApp;
import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.PostProcess;
import helix.graphics.ScreenEffect;
import helix.graphics.Screenshots;
import helix.graphics.Shader;
import helix.graphics.Shaders;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;
import helix.shaders.Tonemap;
import helix.time.Time;

/** Screen effects over the finished frame (PostProcess, ScreenEffect). The frame is an ordinary lit stage: the Kenney sports car on a floor, generated
	shapes, a circling point light. The effects are the example's own shaders (shaders/vignette.glsl and scanlines.glsl, packed into
	.hxshader assets and loaded at run time):
	- the vignette darkens the corners and warms the middle
	- the scanlines darken alternating rows, shift red and blue apart, and flicker
	Both apply in the order added to the chain (PostProcess.add), each on or off. Their parameters are set by name any frame: the vignette breathes in and out, and the arrow
	keys change how dark it gets. Edit a .glsl while the dev server runs and the effect reloads in place.

	H puts the library's tone mapping (helix.shaders.Tonemap) first in the chain, so the scene is drawn HDR (half floats, where the GPU draws
	them) and tone mapped there rather than by the stage: the frame should look the same, the effects reading it tone mapped as before.

	1 / 2: the vignette / the scanlines on and off; H: the HDR scene; Up / Down: the vignette's strength; Space: stop the breathing; O: stop the
	camera; Escape:
	quit, where quitting means anything. Options: autopilot (a script under assets/: the time and the camera are then held, the window the
	autopilot's page's size, so its samples of the frame compare across targets) and autoclose (1: quit once the script is done); the probes
	are ready (the car and both effects in), hdr (PostProcess.hdr) and vignette (on). */
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
	// The HDR scene's tone mapping, when it's on.
	var tonemap:Null<Tonemap>;
	var placed = false;
	var pilot:Null<Autopilot>;
	var published = false;

	// The time the autopilot holds the stage at, and its window's size (the autopilot's browser page's), so its samples compare across targets.
	static inline var HELD_TIME = 2.;
	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;

	// The camera, circling.
	var orbit = new Orbit(9, 4.5, .2, .5);
	var status = "loading the effects";

	override public function init():Void {
		Window.title = "HeliX postprocess";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			orbit.running = false;
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
			Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		post = new PostProcess(gpu, stage);
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
		Models.load("models/car-kit/sedan-sports.glb", file -> place(file));

		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/vignette.hxshader", shader -> makeVignette(shader), message -> status = message);
		shaders.load("shaders/scanlines.hxshader", shader -> makeScanlines(shader), message -> status = message);
	}

	// The autopilot's script in: the input it plays from now on.
	function startPilot(bytes:haxe.io.Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed));

	function probe(name:String):Dynamic
		return switch name {
			case "ready": placed && vignette != null && scanlines != null;
			case "hdr": post.hdr;
			case "vignette": vignette != null && vignette.enabled;
			default: throw 'Unknown probe ' + name;
		}

	// The car's file in: a copy of it in the middle.
	function place(file:ModelFile):Void {
		var car = file.instantiate("car");
		car.setScale(1.5, 1.5, 1.5);
		stage.add(car);
		placed = true;
	}

	// The vignette's shader in: its effect, warm at the edges.
	function makeVignette(shader:Shader):Void {
		vignette = new ScreenEffect(Graphics.instance, shader);
		vignette.parameters.setFloat("radius", .35);
		vignette.parameters.setColor("tint", 0xfff2deff);
		// The vignette before the scanlines, whichever loads first.
		if (scanlines != null)
			post.remove(scanlines);
		post.add(vignette);
		if (scanlines != null)
			post.add(scanlines);
		status = "";
	}

	// The scanlines' shader in: its effect, 240 lines flickering.
	function makeScanlines(shader:Shader):Void {
		scanlines = new ScreenEffect(Graphics.instance, shader);
		scanlines.parameters.setFloat("lines", 240);
		scanlines.parameters.setFloat("darkness", .35);
		scanlines.parameters.setFloat("offset", 1.5);
		scanlines.parameters.setFloat("flicker", 1);
		post.add(scanlines);
	}

	// The tone mapping first in the chain, or out of it: with it there the scene is HDR, the effects after it reading the tone-mapped frame.
	function toggleHdr():Void {
		if (tonemap != null) {
			post.remove(tonemap);
			tonemap = null;
			return;
		}
		tonemap = new Tonemap();
		var after = [for (e in [vignette, scanlines]) if (e != null) e];
		for (e in after)
			post.remove(e);
		post.add(tonemap);
		for (e in after)
			post.add(e);
	}

	override public function frame(dt:Float):Void {
		// The window's input, or the autopilot's: a tick a frame, none while a sample waits for its frame.
		var input:Null<IInput> = Input.instance;
		if (pilot != null) {
			input = pilot.done ? null : pilot.advance(name -> probe(name));
			if (pilot.awaitingFrame)
				input = null;
		}
		if (input != null)
			control(input, dt);
		// The game's clock: paused, the motion stops.
		var time = pilot != null || Host.getOption("autopilot", "") != "" ? HELD_TIME : Time.clock.time;
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		lamp.setPosition(Math.cos(time) * 2.5, 1.2, Math.sin(time) * 2.5);
		if (vignette != null)
			vignette.parameters.setFloat("strength", strength * (breathing ? .75 + .25 * Math.sin(time * 2) : 1));
		var gpu = Graphics.instance,
			width = Window.framebufferWidth,
			height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
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
		post.endScene(time);
		gpu.beginFrame(width, height, 0x000000ff);
		post.present();
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX postprocess: screen effects over the finished frame", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		inline function onOff(e:Null<ScreenEffect>):String
			return e == null ? "loading" : e.enabled ? "on" : "off";
		y += batch.drawTextWrapped('[1] vignette ${onOff(vignette)}  [2] scanlines ${onOff(scanlines)}  [Up/Down] strength ${Math.round(strength * 100) / 100}  [H] HDR ${tonemap == null ? "off" : post.hdr ? "on" : "unavailable"}  [Space] breathing ${breathing ? "on" : "off"}  [O] camera',
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff)
			+ 4;
		if (status != "")
			batch.drawTextWrapped(status, vx + 12, y, 16, vw - 24, 0xff8080ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		gpu.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({game: {hdr: post.hdr, vignette: vignette != null && vignette.enabled}, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	// The keys, from the window or the autopilot.
	function control(input:IInput, dt:Float):Void {
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Digit1) && vignette != null)
			vignette.enabled = !vignette.enabled;
		if (input.isFramePressed(Key.Digit2) && scanlines != null)
			scanlines.enabled = !scanlines.enabled;
		if (input.isFramePressed(Key.H))
			toggleHdr();
		if (input.isFramePressed(Key.Space))
			breathing = !breathing;
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		if (input.isDown(Key.Up))
			strength = Math.min(1, strength + dt * .5);
		if (input.isDown(Key.Down))
			strength = Math.max(0, strength - dt * .5);
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
