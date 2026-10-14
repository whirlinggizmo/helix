import helix.app.BaseApp;
import helix.debug.FpsOverlay;
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

/** Many models that share a mesh and a material. Nothing here asks for instancing: it is what a Stage3D does when models agree on everything
	but where they stand and their tint. A field of 400 cubes shares one mesh and one material, so it is one draw; six cars share one file, so
	each of its parts is one draw for all six; a few cubes are see-through, and those keep their back-to-front order. SPACE gives every cube a
	material of its own instead: the same picture, drawn a cube at a time. The readout counts the models drawn and the draws they took.

	SPACE: a material each, or one shared; Escape: quit, where quitting means anything. */
class App extends BaseApp {
	static inline var SIDE = 20;
	static inline var CARS = 6;
	static inline var GLASS = 5;

	var services:Services;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var shared = new Material();
	var cubes:Array<Node> = [];
	var cars:Array<Node> = [];
	var ownMaterials = false;
	var time = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	// A colour around the hue circle for cube i.
	static function tint(i:Int):Int {
		var hue = i / (SIDE * SIDE) * Math.PI * 2;
		inline function channel(phase:Float):Int
			return Std.int(120 + 135 * Math.sin(hue + phase));
		return channel(0) << 24 | channel(2.1) << 16 | channel(4.2) << 8 | 255;
	}

	// One material for every cube, or one each: the same picture, batched or not.
	function setMaterials(own:Bool):Void {
		for (cube in cubes) {
			var material = shared;
			if (own) {
				material = new Material();
				material.setRoughness(.5);
			}
			cube.setMaterial(material);
		}
		ownMaterials = own;
	}

	override public function init():Void {
		services.window.setTitle("HeliX instancing");
		services.window.setSize(1000, 600);
		var gpu = services.graphics;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xa0b4dcff, .35);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(3);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var ground = new Material();
		ground.setBaseColor(0xb4b8bfff);
		ground.setRoughness(.9);
		var floor = Node.model(Mesh.plane(60, 60), ground);
		floor.setPosition(0, -.6, 0);
		stage.add(floor);

		// The field: one mesh, one material, a tint each.
		var cube = Mesh.cube(.6, .6, .6);
		shared.setRoughness(.5);
		for (i in 0...SIDE * SIDE) {
			var node = Node.model(cube, shared, tint(i));
			cubes.push(node);
			stage.add(node);
		}
		// See-through copies of the same cube: same mesh, same material, alpha in the tint.
		for (i in 0...GLASS) {
			var glass = Node.model(cube, shared, 0xffffff6e);
			glass.setPosition(i * 2 - 4, 5.2, 5);
			glass.setScale(2, 2, 2);
			stage.add(glass);
		}
		// Six cars from one file: each of its parts one draw for all six.
		new Models(services.assets, services.textures).load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				for (i in 0...CARS) {
					var car = file.instantiate('car $i');
					car.setPosition(i * 2.4 - 6, -.6, -2);
					car.setScale(1.5, 1.5, 1.5);
					cars.push(car);
					stage.add(car);
				}
			case Failed(message):
				trace(message);
			case Cancelled:
		});
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.Space))
			setMaterials(!ownMaterials);
		time += dt;
		fps.update(dt, services.getFrameCpu());
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(Math.sin(time * .15) * 22, 12, Math.cos(time * .15) * 22, 0, 1, 0);
		for (i in 0...cubes.length) {
			var x = (i % SIDE - SIDE / 2 + .5) * 1.5,
				z = (Std.int(i / SIDE) - SIDE / 2 + .5) * 1.5;
			cubes[i].setPosition(x, 2.4 + Math.sin(time * 1.5 + x * .6 + z * .4) * .5, z);
			cubes[i].setRotation(0, time * .3 + i, 0);
		}
		// One file, each its own turn.
		for (i in 0...cars.length)
			cars[i].setRotation(0, Math.PI + Math.sin(time + i * .35) * .6, 0);
		hud.setViewport(width, height);
		hud.pixels(services.window.getPixelRatio());

		services.graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(hud);
		Text2D.draw(batch, "HeliX instancing: models that share a mesh and a material go up as one draw", 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch,
			'${stage.getDrawnCount()} models in ${stage.getDrawCount()} draws   [SPACE] ${ownMaterials ? "a material each" : "one shared material"}', 12, 64,
			16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
