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
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.SpotLight;
import helix.render3d.Stage3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit;

/** A glTF model on a lit stage, under a circling camera: a sports car from Kenney's Car Kit with two headlights added in Blender (spot lights
	on its body, KHR_lights_punctual), a .gltf whose buffer and texture are files beside it, all loaded with it. Its wheels and headlights are
	found by name once and kept: the wheels turn, H switches the headlights, D drives the car round a circle and parks it, and C rides along
	through a second camera under the car (behind it and above, looking ahead), and back. Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var MODEL = "models/car-kit/sedan-sports-headlights.gltf";

	var stage:Stage3D;
	var batch:Batch2D;
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	// The camera going round the stage, and where it goes.
	var orbitCamera = new Camera3D();
	var orbit = new Orbit(7, 3, .25, .5);
	// The camera riding along: under the car once it's in, so it goes where the car goes.
	var rideCamera = new Camera3D();
	var riding = false;
	var car:Null<Node3D>;
	var wheels:Array<Node3D> = [];
	var headlights:Array<SpotLight> = [];
	var driving = false;
	// Where round its circle the car is, in radians, and how far its wheels have turned.
	var driveAngle = 0.;
	var wheelSpin = 0.;
	var caption = 'loading $MODEL';

	override public function init():Void {
		Window.title = "HeliX model";
		Window.requestSize(1000, 600);
		stage = new Stage3D();
		batch = new Batch2D();
		stage.setAmbient(0xffffffff, .2);
		var sun = new DirectionalLight();
		sun.intensity = 2;
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0xff616164;
		ground.roughness = .9;
		stage.add(new Model(Mesh.plane(14, 14), ground));
		// Framed for 16:9: the whole circle across on a phone held upright too, riding along or not.
		orbitCamera.minAspect = 16 / 9;
		rideCamera.minAspect = 16 / 9;

		Models.load(MODEL, file -> place(file), message -> caption = message);
	}

	// The car's file in. instantiate makes a tree of the file's nodes under a Node3D named "car", each named as in Blender: a Model for each node
	// with a mesh (wheel-front-left, wheel-front-right, wheel-back-left, wheel-back-right and body), the spoiler a Model under the body, and the
	// body's two lights, headlight-left and headlight-right, SpotLights under it shining ahead (the car's +z).
	function place(file:ModelFile):Void {
		car = file.instantiate("car");
		car.setScale(1.5, 1.5, 1.5);
		for (name in ["wheel-front-left", "wheel-front-right", "wheel-back-left", "wheel-back-right"])
			wheels.push(car.find(name));
		for (name in ["headlight-left", "headlight-right"])
			headlights.push(cast(car.find(name), SpotLight));
		stage.add(car);
		// Behind the car and above it, looking ahead, in its own units: a child, so the car carries it.
		rideCamera.setView(0, 1.8, -4.5, 0, .4, 2);
		car.addChild(rideCamera);
		caption = MODEL;
		for (warning in file.warnings)
			trace('$MODEL: $warning');
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		if (car != null) {
			if (Input.isFramePressed(Key.H))
				for (light in headlights)
					light.visible = !light.visible;
			if (Input.isFramePressed(Key.D))
				driving = !driving;
			if (Input.isFramePressed(Key.C))
				riding = !riding;
			if (driving) {
				// A circle of 3, facing the way it goes: its +z along the circle's tangent.
				driveAngle += dt * .5;
				car.setPosition(3 * Math.cos(driveAngle), 0, 3 * Math.sin(driveAngle));
				car.setRotation(0, -driveAngle, 0);
			}
			wheelSpin += dt * 3;
			for (wheel in wheels)
				wheel.setRotation(wheelSpin, 0, 0);
		}
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		orbitCamera.setViewport(width, height);
		orbit.apply(orbitCamera);
		rideCamera.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		Screen.apply(hud);
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;

		Graphics.beginFrame(width, height, 0xff14161c);
		stage.draw(riding ? rideCamera : orbitCamera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped('HeliX glTF model: $caption', vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		var keys = "D: drive   C: ride along   H: the headlights" + (Host.canQuit() ? "   ESC: quit" : "");
		batch.drawTextWrapped(keys, vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
