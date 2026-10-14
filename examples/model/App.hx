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

/** A glTF model on a lit stage, under a circling camera: a sports car from Kenney's Car Kit with two headlights added in Blender (spot lights
	under its body, KHR_lights_punctual), a .gltf whose buffer and texture are files beside it, all loaded with it. Its parts are found by name
	once and kept: the wheels turn, and H switches the headlights. D drives the car around a circle and parks it; C rides along, through a camera node
	parented to the car (behind it and above, looking ahead), and back to the circling camera. O stops the circling camera; Escape quits where
	quitting means anything. */
class App extends BaseApp {
	static inline var MODEL = "models/car-kit/sedan-sports-headlights.gltf";

	var services:Services;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	// The chase camera: on a node of the car's, so it follows it.
	var chase = new Camera3D();
	var chaseNode:Node;
	var chasing = false;
	var driving = false;
	var travel = 0.;
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var car:Null<Node>;
	var wheels:Array<Node> = [];
	var beams:Array<Node> = [];
	var status = 'loading $MODEL';
	var orbit = true;
	var headlights = true;
	var angle = 0.;
	var roll = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX model");
		services.window.setSize(1000, 600);
		stage = new Stage3D(services.graphics);
		stage.setAmbient(0xffffffff, .2);
		var sunLight = new Light(Directional);
		sunLight.setIntensity(2);
		var sun = Node.light(sunLight);
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var ground = new Material();
		ground.setBaseColor(0x616164ff);
		ground.setRoughness(.9);
		stage.add(Node.model(Mesh.plane(14, 14), ground));

		new Models(services.assets, services.textures).load(MODEL, result -> switch result {
			case Ready(file):
				car = file.instantiate("car");
				car.setScale(1.5, 1.5, 1.5);
				for (name in ["wheel-front-left", "wheel-front-right", "wheel-back-left", "wheel-back-right"])
					wheels.push(car.find(name));
				for (name in ["headlight-left", "headlight-right"])
					beams.push(car.find(name));
				stage.add(car);
				// Behind and above it, looking ahead; in the car's own units.
				chaseNode = Node.camera(chase);
				chaseNode.setPosition(0, 1.8, -4.5);
				chaseNode.lookAt(0, .4, 2);
				car.add(chaseNode);
				status = MODEL;
				for (warning in file.getWarnings())
					trace('$MODEL: $warning');
			case Failed(message):
				status = message;
			case Cancelled:
		});
		batch = new Batch2D(services.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (car != null && input.isFramePressed(Key.H)) {
			headlights = !headlights;
			for (beam in beams)
				beam.setVisible(headlights);
		}
		if (car != null && input.isFramePressed(Key.D))
			driving = !driving;
		if (car != null && input.isFramePressed(Key.C))
			chasing = !chasing;
		if (orbit)
			angle += dt * .25;
		if (driving && car != null) {
			// A circle of 3, facing the way it goes: its +z along the circle's tangent.
			travel += dt * .5;
			car.setPosition(3 * Math.cos(travel), 0, 3 * Math.sin(travel));
			car.setRotation(0, -travel, 0);
		}
		roll += dt * 3;
		for (wheel in wheels)
			wheel.setRotation(roll, 0, 0);
		fps.update(dt, services.getFrameCpu());
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(7 * Math.sin(angle), 3, 7 * Math.cos(angle), 0, .5, 0);
		chase.setViewport(width, height);
		camera2D.setViewport(width, height);
		camera2D.pixels(services.window.getPixelRatio());

		services.graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(chasing ? chase : camera);
		batch.begin(camera2D);
		Text2D.draw(batch, 'HeliX glTF model: $status', 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch, "D: drive   C: ride along   O: the camera   H: the headlights"
			+ (services.canQuit() ? "   ESC: quit" : ""), 12, 64, 16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
