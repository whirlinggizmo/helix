import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Sampling;
import helix.graphics.Shader;
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
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Materials drawn by shaders of the example's own (shaders/*.glsl, surface shaders packed into .hxshader assets and loaded at run time):
	- left: toon shading (the lights in flat bands, a rim light) on every material of the Kenney sports car
	- middle: a sphere dissolving and coming back through a noise texture, with a glowing edge (the time, a texture, discard), double sided so
		its inside shows through the holes
	- right: a sphere of water rippling in waves (a vertex hook moves the surface), with glints and the sky at grazing angles
	A sun and a point light circling in front light the stage; the shaders read them as the stage's own does. Edit a .glsl while the dev server
	runs and its material reloads in place.

	1 / 2: the sun / the point light on and off; Escape: quit, where quitting means anything. */
class App extends BaseApp {
	static inline var FLOOR_Y = -.5;

	var services:Services;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var shaders:Shaders;
	var sun:Node;
	var lamp:Node;
	var marker:Node;
	var dissolve = new Material();
	var water = new Material();
	var car:Null<ModelFile>;
	var toon:Null<Shader>;
	var status = "loading the shaders";
	var time = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX shaders");
		services.window.setSize(1000, 600);
		var gpu = services.graphics;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .15);
		camera.setView(0, 1.2, 5, 0, .3, 0);
		var sunLight = new Light(Directional);
		sunLight.setColor(0xfff4e4ff);
		sunLight.setIntensity(1.5);
		sun = Node.light(sunLight);
		sun.lookAt(-.4, -.7, -.6);
		stage.add(sun);
		var lampLight = new Light(Point);
		lampLight.setColor(0x78beffff);
		lampLight.setIntensity(9);
		lampLight.setRange(8);
		lamp = Node.light(lampLight);
		stage.add(lamp);
		var glow = new Material();
		glow.setLit(false);
		glow.setBaseColor(0x87ceebff);
		marker = Node.model(Mesh.sphere(.05), glow);
		stage.add(marker);
		// A floor, dark so the lights show on it.
		var floor = new Material();
		floor.setBaseColor(0x383839ff);
		floor.setRoughness(.8);
		var plane = Node.model(Mesh.plane(6, 6), floor);
		plane.setPosition(0, FLOOR_Y, 0);
		stage.add(plane);
		// Both sides: the inside shows through the holes.
		dissolve.setDoubleSided(true);
		var sphere = Node.model(Mesh.sphere(.5, 32, 64), dissolve);
		sphere.setPosition(0, .1, 0);
		stage.add(sphere);
		// Finely divided, so its waves are smooth.
		var rippling = Node.model(Mesh.sphere(.5, 96, 192), water);
		rippling.setPosition(1.9, .1, 0);
		stage.add(rippling);

		new Models(services.assets, services.textures).load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				car = file;
				var node = file.instantiate("car");
				node.setPosition(-1.9, FLOOR_Y, 0);
				node.setRotation(0, .4, 0);
				node.setScale(.75, .75, .75);
				stage.add(node);
				toonCar();
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		services.textures.load("textures/noise.png", true, result -> switch result {
			case Ready(texture):
				// The shader samples it twice across: it tiles.
				texture.setSampling(new Sampling(true, Repeat, Repeat));
				if (dissolve.getShaderParameters() != null)
					dissolve.getShaderParameters().setTexture("noise_texture", texture);
				noise = texture;
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		shaders = new Shaders(services.assets, gpu);
		shaders.load("shaders/toon.hxshader", result -> switch result {
			case Ready(shader):
				toon = shader;
				toonCar();
			case Failed(message):
				status = message;
			case Cancelled:
		});
		shaders.load("shaders/dissolve.hxshader", result -> switch result {
			case Ready(shader):
				dissolve.setShader(shader);
				var p = dissolve.getShaderParameters();
				p.setValues("color", [.55, .6, .7, 1]);
				p.setValues("edge_color", [4, 1.2, .2]);
				p.setFloat("speed", .15);
				if (noise != null)
					p.setTexture("noise_texture", noise);
				status = "";
			case Failed(message):
				status = message;
			case Cancelled:
		});
		shaders.load("shaders/water.hxshader", result -> switch result {
			case Ready(shader):
				water.setShader(shader);
				var p = water.getShaderParameters();
				p.setFloat("amplitude", .03);
				p.setFloat("frequency", 2.5);
				p.setFloat("wave_speed", 3);
				p.setValues("low_color", [0, .03, .1, 1]);
				p.setValues("high_color", [.05, .3, .35, 1]);
				p.setValues("sky_color", [.35, .45, .6, 1]);
				p.setFloat("shininess", 120);
			case Failed(message):
				status = message;
			case Cancelled:
		});
	}

	var noise:Null<helix.render2d.Texture2D>;

	// Toon shading on every material of the car, once both the car and the shader are here.
	function toonCar():Void {
		if (car == null || toon == null)
			return;
		for (material in car.getMaterials()) {
			material.setShader(toon);
			material.getShaderParameters().setFloat("bands", 3);
			material.getShaderParameters().setFloat("rim", .35);
		}
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.Digit1))
			sun.setVisible(!sun.isVisible());
		if (input.isFramePressed(Key.Digit2)) {
			lamp.setVisible(!lamp.isVisible());
			marker.setVisible(lamp.isVisible());
		}
		time += dt;
		stage.setTime(time);
		fps.update(dt, services.getFrameCpu());
		// Circling in front of the models, toward the camera: always in view, and far enough not to wash them out.
		var lx = Math.cos(time * .7) * 2.2,
			ly = .8 + Math.sin(time * .7),
			lz = 1.6 + Math.sin(time * .7) * .4;
		lamp.setPosition(lx, ly, lz);
		marker.setPosition(lx, ly, lz);
		var gpu = services.graphics,
			width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		hud.setViewport(width, height);
		hud.pixels(services.window.getPixelRatio());

		gpu.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(hud);
		Text2D.draw(batch, "HeliX shaders: materials drawn by the example's own surface shaders", 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch,
			'toon      dissolve      water        [1] sun ${sun.isVisible() ? "on" : "off"}  [2] point light ${lamp.isVisible() ? "on" : "off"}', 12, 64, 16,
			0xc8c8c8ff);
		if (status != "")
			Text2D.draw(batch, status, 12, 88, 16, 0xff8080ff);
		fps.draw(batch, 12, 10);
		batch.end();
		gpu.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
