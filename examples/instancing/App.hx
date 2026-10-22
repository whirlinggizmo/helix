import helix.debug.FpsOverlay;
import helix.graphics.Color;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
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
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit;

/** Many models that share a mesh and a material. Nothing here asks for instancing: it is what a Stage3D does when models agree on everything
	but where they stand and their tint. A field of 400 cubes shares one mesh and one material, so it is one draw; six cars share one file, so
	each of its parts is one draw for all six; a few cubes are see-through, and those keep their back-to-front order. SPACE gives every cube a
	material of its own instead: the same picture, drawn a cube at a time. The readout counts the models drawn and the draws they took.

	SPACE: a material each, or one shared; Escape: quit, where quitting means anything. */
class App extends helix.App {
	static inline var SIDE = 20;
	static inline var CARS = 6;
	static inline var GLASS = 5;

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var shared = new Material();
	var cubes:Array<Model> = [];
	var cars:Array<Node3D> = [];
	var ownMaterials = false;
	// The camera, circling on the game's clock.
	var orbit = new Orbit(22, 12, .15, 1);

	// A colour around the hue circle for cube i.
	static function tint(i:Int):Int {
		var hue = i / (SIDE * SIDE) * Math.PI * 2;
		inline function channel(phase:Float):Int
			return Std.int(120 + 135 * Math.sin(hue + phase));
		return Color.fromChannels(channel(0), channel(2.1), channel(4.2));
	}

	// One material for every cube, or one each: the same picture, batched or not.
	function setMaterials(own:Bool):Void {
		for (cube in cubes) {
			var material = shared;
			if (own) {
				material = new Material();
				material.roughness = .5;
			}
			cube.material = material;
		}
		ownMaterials = own;
	}

	override public function init():Void {
		Window.title = "HeliX instancing";
		Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffa0b4dc, .35);
		// Framed for 16:9: the whole field across on a phone held upright too.
		camera.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 3;
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0xffb4b8bf;
		ground.roughness = .9;
		var floor = new Model(Mesh.plane(60, 60), ground);
		floor.setPosition(0, -.6, 0);
		stage.add(floor);

		// The field: one mesh, one material, a tint each.
		var cube = Mesh.cube(.6, .6, .6);
		shared.roughness = .5;
		for (i in 0...SIDE * SIDE) {
			var node = new Model(cube, shared);
			node.tint = tint(i);
			cubes.push(node);
			stage.add(node);
		}
		// See-through copies of the same cube: same mesh, same material, alpha in the tint.
		for (i in 0...GLASS) {
			var glass = new Model(cube, shared);
			glass.tint = 0x6effffff;
			glass.setPosition(i * 2 - 4, 5.2, 5);
			glass.setScale(2, 2, 2);
			stage.add(glass);
		}
		// Six cars from one file: each of its parts one draw for all six.
		Models.load("models/car-kit/sedan-sports.glb", file -> place(file));
	}

	// The car's file in: six copies of it in a row.
	function place(file:ModelFile):Void
		for (i in 0...CARS) {
			var car = file.instantiate('car $i');
			car.setPosition(i * 2.4 - 6, -.6, -2);
			car.setScale(1.5, 1.5, 1.5);
			cars.push(car);
			stage.add(car);
		}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Space))
			setMaterials(!ownMaterials);
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		orbit.update(Time.clock.delta);
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		for (i in 0...cubes.length) {
			var x = (i % SIDE - SIDE / 2 + .5) * 1.5,
				z = (Std.int(i / SIDE) - SIDE / 2 + .5) * 1.5;
			cubes[i].setPosition(x, 2.4 + Math.sin(time * 1.5 + x * .6 + z * .4) * .5, z);
			cubes[i].setRotation(0, time * .3 + i, 0);
		}
		// One file, each its own turn.
		for (i in 0...cars.length)
			cars[i].setRotation(0, Math.PI + Math.sin(time + i * .35) * .6, 0);
		// The readout in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0xff1c1e26);
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX instancing: models that share a mesh and a material go up as one draw", vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		batch.drawTextWrapped('${stage.drawnNodeCount} models in ${stage.drawCallCount} draws   [SPACE] ${ownMaterials ? "a material each" : "one shared material"}',
			vx
			+ 12,
			y, 16, vw
			- 24, 0xffc8c8c8);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
