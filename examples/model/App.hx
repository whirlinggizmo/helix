import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
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

/** A glTF model on a lit stage, under a circling camera: the toy car (a checkered body, a see-through cabin, four wheels, emissive
	headlights with a spot light each), loaded through Models and placed once it's ready. Its parts are found by name once and kept: the
	wheels turn, and H switches the headlights' lights. O stops the camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var MODEL = "models/toy_car.glb";

	var host:IHost;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
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

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX model");
		host.window.setSize(1000, 600);
		stage = new Stage3D(host.graphics);
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

		new Models(host.assets, host.textures).load(MODEL, result -> switch result {
			case Ready(file):
				car = file.instantiate("toy_car");
				for (name in ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"])
					wheels.push(car.find(name));
				for (name in ["headlight_l_beam", "headlight_r_beam"])
					beams.push(car.find(name));
				stage.add(car);
				status = MODEL;
				for (warning in file.getWarnings())
					trace('$MODEL: $warning');
			case Failed(message):
				status = message;
			case Cancelled:
		});
		batch = new Batch2D(host.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (car != null && input.isFramePressed(Key.H)) {
			headlights = !headlights;
			for (beam in beams)
				beam.setVisible(headlights);
		}
		if (orbit)
			angle += dt * .25;
		roll += dt * 3;
		for (wheel in wheels)
			wheel.setRotation(roll, 0, 0);
		fps.update(dt, host.diagnostics.getFrameCpu());
		var width = host.getFramebufferWidth(),
			height = host.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(7 * Math.sin(angle), 3, 7 * Math.cos(angle), 0, .5, 0);
		camera2D.setViewport(width, height);
		camera2D.pixels(host.getPixelRatio());

		host.graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		Text2D.draw(batch, 'HeliX glTF model: $status', 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch, "O: the camera   H: the headlights" + (host.canQuit() ? "   ESC: quit" : ""), 12, 64, 16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		host.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
