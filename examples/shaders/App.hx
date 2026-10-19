import helix.app.BaseApp;
import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Sampling;
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
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;
import helix.shaders.Unlit;
import helix.time.Time;

/** Materials drawn by shaders of the example's own (shaders/*.glsl, surface shaders packed into .hxshader assets and loaded at run time):
	- left: toon shading (the lights in flat bands, a rim light) on every material of the Kenney sports car
	- middle: a sphere dissolving and coming back through a noise texture, with a glowing edge (the time, a texture, discard), double sided so
		its inside shows through the holes
	- right: a sphere of water rippling in waves (a vertex hook moves the surface), with glints and the sky at grazing angles
	- above the middle: a cube drawn by a shader of HeliX's library (helix.shaders.Unlit), packed into the program: nothing to load
	A sun and a point light circling in front light the stage; the shaders read them as the stage's own does. Edit a .glsl while the dev server
	runs and its material reloads in place (a library shader's too, in src/helix/shaders).

	1 / 2: the sun / the point light on and off; Escape: quit, where quitting means anything. Options: autopilot (a script under assets/: the
	time is then held, the window the autopilot's page's size, so its samples of the frame compare across targets) and autoclose (1: quit once
	the script is done); the probes are ready (everything loaded), sun and lamp. */
class App extends BaseApp {
	static inline var FLOOR_Y = -.5;

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var shaders:Shaders;
	var sun:DirectionalLight;
	var lamp:PointLight;
	var marker:Model;
	var dissolve = new Material();
	var water = new Material();
	var car:Null<ModelFile>;
	var toon:Null<Shader>;
	var status = "loading the shaders";
	var unlit:Unlit;
	var pilot:Null<Autopilot>;
	var published = false;
	var placed = false;
	var dissolving = false;
	var watering = false;

	// The time the autopilot holds the stage at, and its window's size (the autopilot's browser page's), so its samples compare across targets.
	static inline var HELD_TIME = 2.;
	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;

	override public function init():Void {
		Window.title = "HeliX shaders";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
			Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .15);
		camera.setView(0, 1.2, 5, 0, .3, 0);
		// Framed for 16:9: all three models on a phone held upright too.
		camera.minAspect = 16 / 9;
		sun = new DirectionalLight();
		sun.color = 0xfff4e4ff;
		sun.intensity = 1.5;
		sun.lookAt(-.4, -.7, -.6);
		stage.add(sun);
		lamp = new PointLight();
		lamp.color = 0x78beffff;
		lamp.intensity = 9;
		lamp.range = 8;
		stage.add(lamp);
		var glow = new Material();
		glow.lit = false;
		glow.baseColor = 0x87ceebff;
		marker = new Model(Mesh.sphere(.05), glow);
		stage.add(marker);
		// A floor, dark so the lights show on it.
		var floor = new Material();
		floor.baseColor = 0x383839ff;
		floor.roughness = .8;
		var plane = new Model(Mesh.plane(6, 6), floor);
		plane.setPosition(0, FLOOR_Y, 0);
		stage.add(plane);
		// Both sides: the inside shows through the holes.
		dissolve.doubleSided = true;
		var sphere = new Model(Mesh.sphere(.5, 32, 64), dissolve);
		sphere.setPosition(0, .1, 0);
		stage.add(sphere);
		// Finely divided, so its waves are smooth.
		var rippling = new Model(Mesh.sphere(.5, 96, 192), water);
		rippling.setPosition(1.9, .1, 0);
		stage.add(rippling);
		// The library's Unlit: a flat color, no light, and nothing to load.
		var flat = new Material();
		unlit = new Unlit(flat);
		unlit.color = 0xff8a00ff;
		var cube = new Model(Mesh.cube(.3, .3, .3), flat);
		cube.setPosition(0, 1.05, 0);
		cube.setRotation(.5, .7, 0);
		stage.add(cube);

		Models.load("models/car-kit/sedan-sports.glb", file -> place(file));
		Textures.load("textures/noise.png", true, texture -> useNoise(texture));
		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/toon.hxshader", shader -> useToon(shader), message -> status = message);
		shaders.load("shaders/dissolve.hxshader", shader -> useDissolve(shader), message -> status = message);
		shaders.load("shaders/water.hxshader", shader -> useWater(shader), message -> status = message);
	}

	// The autopilot's script in: the input it plays from now on.
	function startPilot(bytes:haxe.io.Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed));

	function probe(name:String):Dynamic
		return switch name {
			case "ready": placed && toon != null && dissolving && watering && noise != null;
			case "sun": sun.visible;
			case "lamp": lamp.visible;
			default: throw 'Unknown probe ' + name;
		}

	// The car's file in: a copy of it on the left, toon shaded once that shader is in.
	function place(file:ModelFile):Void {
		car = file;
		placed = true;
		var node = file.instantiate("car");
		node.setPosition(-1.9, FLOOR_Y, 0);
		node.setRotation(0, .4, 0);
		node.setScale(.75, .75, .75);
		stage.add(node);
		toonCar();
	}

	// The noise texture in: the dissolve's, tiling.
	function useNoise(texture:Texture2D):Void {
		// The shader samples it twice across: it tiles.
		texture.sampling = new Sampling(true, Repeat, Repeat);
		if (dissolve.shaderParameters != null)
			dissolve.shaderParameters.setTexture("noise_texture", texture);
		noise = texture;
	}

	// The toon shader in: the car's, once it's in too.
	function useToon(shader:Shader):Void {
		toon = shader;
		toonCar();
	}

	// The dissolve shader in: the middle sphere's, with the noise once that's in.
	function useDissolve(shader:Shader):Void {
		dissolve.setShader(shader);
		dissolving = true;
		var p = dissolve.shaderParameters;
		p.setValues("color", [.55, .6, .7, 1]);
		p.setValues("edge_color", [4, 1.2, .2]);
		p.setFloat("speed", .15);
		if (noise != null)
			p.setTexture("noise_texture", noise);
		status = "";
	}

	// The water shader in: the right sphere's, its waves and colors.
	function useWater(shader:Shader):Void {
		water.setShader(shader);
		watering = true;
		var p = water.shaderParameters;
		p.setFloat("amplitude", .03);
		p.setFloat("frequency", 2.5);
		p.setFloat("wave_speed", 3);
		p.setValues("low_color", [0, .03, .1, 1]);
		p.setValues("high_color", [.05, .3, .35, 1]);
		p.setValues("sky_color", [.35, .45, .6, 1]);
		p.setFloat("shininess", 120);
	}

	var noise:Null<helix.render2d.Texture2D>;

	// Toon shading on every material of the car, once both the car and the shader are here.
	function toonCar():Void {
		if (car == null || toon == null)
			return;
		for (material in car.materials) {
			material.setShader(toon);
			material.shaderParameters.setFloat("bands", 3);
			material.shaderParameters.setFloat("rim", .35);
		}
	}

	override public function frame(dt:Float):Void {
		// The window's input, or the autopilot's: a tick a frame, none while a sample waits for its frame.
		var input:Null<IInput> = Input.instance;
		if (pilot != null) {
			input = pilot.done ? null : pilot.advance(name -> probe(name));
			if (pilot.awaitingFrame)
				input = null;
		}
		if (input != null) {
			if (Host.canQuit() && input.isFramePressed(Key.Escape))
				Host.quit();
			if (input.isFramePressed(Key.Digit1))
				sun.visible = !sun.visible;
			if (input.isFramePressed(Key.Digit2)) {
				lamp.visible = !lamp.visible;
				marker.visible = lamp.visible;
			}
		}
		// The game's clock: paused, the motion stops; held under the autopilot.
		var time = pilot != null ? HELD_TIME : Time.clock.time;
		stage.time = time;
		fps.update(dt, Time.frameCpu);
		// Circling in front of the models, toward the camera: always in view, and far enough not to wash them out.
		var lx = Math.cos(time * .7) * 2.2,
			ly = .8 + Math.sin(time * .7),
			lz = 1.6 + Math.sin(time * .7) * .4;
		lamp.setPosition(lx, ly, lz);
		marker.setPosition(lx, ly, lz);
		var gpu = Graphics.instance,
			width = Window.framebufferWidth,
			height = Window.framebufferHeight;
		camera.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		gpu.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX shaders: materials drawn by the example's own surface shaders", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		y += batch.drawTextWrapped('left to right: toon, dissolve, water   [1] sun ${sun.visible ? "on" : "off"}  [2] point light ${lamp.visible ? "on" : "off"}',
			vx
			+ 12, y, 16,
			vw
			- 24, 0xc8c8c8ff)
			+ 4;
		if (status != "")
			batch.drawTextWrapped(status, vx + 12, y, 16, vw - 24, 0xff8080ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		gpu.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({game: {sun: sun.visible, lamp: lamp.visible}, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
