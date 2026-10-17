import helix.app.BaseApp;
import helix.debug.FpsOverlay;
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
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.time.Time;

/** A glTF model on a lit stage, under a circling camera: a sports car from Kenney's Car Kit with two headlights added in Blender (spot lights
	under its body, KHR_lights_punctual), a .gltf whose buffer and texture are files beside it, all loaded with it. Its parts are found by name
	once and kept: the wheels turn, and H switches the headlights. D drives the car around a circle and parks it; C rides along, through a camera
	parented to the car (behind it and above, looking ahead), and back to the circling camera. O stops the circling camera; Escape quits where
	quitting means anything. */
class App extends BaseApp {
	static inline var MODEL = "models/car-kit/sedan-sports-headlights.gltf";

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	// The chase camera: under the car once it's loaded, so it follows it.
	var chase = new Camera3D();
	var chasing = false;
	var driving = false;
	var travel = 0.;
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var car:Null<Node3D>;
	var wheels:Array<Node3D> = [];
	var beams:Array<Node3D> = [];
	var status = 'loading $MODEL';
	var orbit = true;
	var headlights = true;
	var angle = 0.;
	var roll = 0.;

	override public function init():Void {
		Window.title = "HeliX model";
		Window.requestSize(1000, 600);
		stage = new Stage3D(Graphics.instance);
		stage.setAmbient(0xffffffff, .2);
		// Framed for 16:9: the whole circle across on a phone held upright too, riding along or not.
		camera.minAspect = 16 / 9;
		chase.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 2;
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0x616164ff;
		ground.roughness = .9;
		stage.add(new Model(Mesh.plane(14, 14), ground));

		Models.load(MODEL, result -> switch result {
			case Ready(file):
				car = file.instantiate("car");
				car.setScale(1.5, 1.5, 1.5);
				for (name in ["wheel-front-left", "wheel-front-right", "wheel-back-left", "wheel-back-right"])
					wheels.push(car.find(name));
				for (name in ["headlight-left", "headlight-right"])
					beams.push(car.find(name));
				stage.add(car);
				// Behind and above it, looking ahead; in the car's own units.
				chase.setPosition(0, 1.8, -4.5);
				chase.lookAt(0, .4, 2);
				car.addChild(chase);
				status = MODEL;
				for (warning in file.warnings)
					trace('$MODEL: $warning');
			case Failed(message):
				status = message;
			case Cancelled:
		});
		batch = new Batch2D(Graphics.instance);
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (car != null && input.isFramePressed(Key.H)) {
			headlights = !headlights;
			for (beam in beams)
				beam.visible = headlights;
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
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		camera.setView(7 * Math.sin(angle), 3, 7 * Math.cos(angle), 0, .5, 0);
		chase.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(chasing ? chase : camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += batch.drawTextWrapped('HeliX glTF model: $status', vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		batch.drawTextWrapped("D: drive   C: ride along   O: the camera   H: the headlights"
			+ (Host.canQuit() ? "   ESC: quit" : ""), vx
			+ 12, y, 16,
			vw
			- 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
