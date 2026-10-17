import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
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

	override public function init():Void {
		Services.window.setTitle("HeliX lights");
		Services.window.requestSize(1000, 600);
		stage = new Stage3D(Services.graphics);
		stage.setAmbient(0x5a6ea0ff, .05);
		camera.setView(0, 4.5, 10, 0, 1, 0);
		// Framed for 16:9: all the row across on a phone held upright too.
		camera.setMinAspect(16 / 9);

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

		grid = new Batch3D(Services.graphics);
		batch = new Batch2D(Services.graphics);
	}

	static function onOff(node:Node):String
		return node.isVisible() ? "on " : "off";

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (input.isFramePressed(Key.Digit1))
			sun.setVisible(!sun.isVisible());
		if (input.isFramePressed(Key.Digit2))
			lamp.setVisible(!lamp.isVisible());
		if (input.isFramePressed(Key.Digit3))
			spot.setVisible(!spot.isVisible());
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		time += dt;
		// The point light orbits through the row; the spot sweeps left and right.
		var lx = Math.sin(time * .6) * 5, lz = Math.cos(time * .6) * 2;
		lamp.setPosition(lx, 1.2, lz);
		marker.setPosition(lx, 1.2, lz);
		marker.setVisible(lamp.isVisible());
		spot.lookAt(Math.sin(time * .8) * .7, 5, 1.7);
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera2D);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		Services.graphics.beginFrame(width, height, 0x0c0d12ff);
		grid.begin(camera);
		grid.grid(20, 1, 0x282a32ff);
		grid.end();
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX lights: directional, point, spot", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		Text2D.drawWrapped(batch, '[1] sun ${onOff(sun)}   [2] point light ${onOff(lamp)}   [3] spotlight ${onOff(spot)}', vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		grid.destroy();
		batch.destroy();
	}
}
