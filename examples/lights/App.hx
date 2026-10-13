import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Directional, point and spot lights on a Stage3D: five standing figures (capsules) on a grid, a dim warm sun, a cyan point light orbiting
	through them and fading with its range (its marker an unlit sphere), and a white spotlight sweeping across them from above. The stage starts
	unlit; every light here is explicit. 1, 2 and 3 toggle the sun, the point light and the spotlight; Escape quits where quitting means
	anything. */
class App extends BaseApp {
	static inline var FIGURES = 5;

	var host:IHost;
	var stage:Stage3D;
	var grid:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var sun:Node;
	var lamp:Node;
	var marker:Node;
	var spot:Node;
	var time = 0.;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX lights");
		host.window.setSize(1000, 600);
		stage = new Stage3D(host.graphics);
		stage.setAmbient(0x5a6ea0ff, .05);
		camera.setView(0, 4.5, 10, 0, 1, 0);

		var figure = Mesh.capsule(.3, 1.7, 16, 32), skin = new Material();
		skin.setBaseColor(0xd8d8d8ff);
		skin.setRoughness(.6);
		for (i in 0...FIGURES) {
			var node = Node.model(figure, skin);
			node.setPosition(-4 + 2 * i, .85, i % 2 == 1 ? -.8 : .8);
			stage.add(node);
		}

		var sunLight = new Light(Directional);
		sunLight.setColor(0xffd2a0ff);
		sunLight.setIntensity(1.1);
		sun = Node.light(sunLight);
		sun.lookAt(-.4, -1, -.6);
		stage.add(sun);

		var lampLight = new Light(Point);
		lampLight.setColor(0x3cdcffff);
		lampLight.setIntensity(20);
		lampLight.setRange(5);
		lamp = Node.light(lampLight);
		stage.add(lamp);
		var glow = new Material();
		glow.setBaseColor(0x3cdcffff);
		glow.setLit(false);
		marker = Node.model(Mesh.sphere(.12, 8, 16), glow);
		stage.add(marker);

		var spotLight = new Light(Spot);
		spotLight.setCone(.14, .28);
		spotLight.setIntensity(125);
		spot = Node.light(spotLight);
		spot.setPosition(0, 6, 2);
		stage.add(spot);

		grid = new Batch3D(host.graphics);
		batch = new Batch2D(host.graphics);
	}

	static function onOff(node:Node):String
		return node.isVisible() ? "on " : "off";

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (input.isFramePressed(Key.Digit1))
			sun.setVisible(!sun.isVisible());
		if (input.isFramePressed(Key.Digit2))
			lamp.setVisible(!lamp.isVisible());
		if (input.isFramePressed(Key.Digit3))
			spot.setVisible(!spot.isVisible());
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		time += dt;
		// The point light orbits through the row; the spot sweeps left and right.
		var lx = Math.sin(time * .6) * 5, lz = Math.cos(time * .6) * 2;
		lamp.setPosition(lx, 1.2, lz);
		marker.setPosition(lx, 1.2, lz);
		marker.setVisible(lamp.isVisible());
		spot.lookAt(Math.sin(time * .8) * .7, 5, 1.7);
		fps.update(dt, host.diagnostics.getFrameCpu());
		var width = host.getFramebufferWidth(),
			height = host.getFramebufferHeight();
		camera.setViewport(width, height);
		camera2D.setViewport(width, height);
		camera2D.pixels(host.getPixelRatio());

		host.graphics.beginFrame(width, height, 0x0c0d12ff);
		grid.begin(camera);
		grid.grid(20, 1, 0x282a32ff);
		grid.end();
		stage.draw(camera);
		batch.begin(camera2D);
		Text2D.draw(batch, "HeliX lights: directional, point, spot", 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch, '[1] sun ${onOff(sun)}   [2] point light ${onOff(lamp)}   [3] spotlight ${onOff(spot)}', 12, 64, 16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		host.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		grid.destroy();
		batch.destroy();
	}
}
