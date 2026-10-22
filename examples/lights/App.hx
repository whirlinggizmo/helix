import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.PointLight;
import helix.render3d.SpotLight;
import helix.render3d.Stage3D;
import helix.time.Time;
import helix.host.ScreenShape;

/** Directional, point and spot lights on a Stage3D: five standing figures (capsules) on a grid, a dim warm sun, a cyan point light orbiting
	through them and fading with its range (its marker an unlit sphere), and a white spotlight sweeping across them from above. The stage starts
	unlit; every light here is explicit. 1, 2 and 3 toggle the sun, the point light and the spotlight; Escape quits where quitting means
	anything. */
class App extends helix.App {
	static inline var FIGURES = 5;

	var stage:Stage3D;
	var grid:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var sun:DirectionalLight;
	var lamp:PointLight;
	var marker:Model;
	var spot:SpotLight;

	override public function init():Void {
		Window.title = "HeliX lights";
		Window.requestSize(1000, 600);
		stage = new Stage3D();
		stage.setAmbient(0xff5a6ea0, .05);
		camera.setView(0, 4.5, 10, 0, 1, 0);
		// Framed for 16:9: all the row across on a phone held upright too.
		camera.minAspect = 16 / 9;

		var figure = Mesh.capsule(.3, 1.7, 16, 32), skin = new Material();
		skin.baseColor = 0xffd8d8d8;
		skin.roughness = .6;
		for (i in 0...FIGURES) {
			var node = new Model(figure, skin);
			node.setPosition(-4 + 2 * i, .85, i % 2 == 1 ? -.8 : .8);
			stage.add(node);
		}

		sun = new DirectionalLight();
		sun.color = 0xffffd2a0;
		sun.intensity = 1.1;
		sun.lookAt(-.4, -1, -.6);
		stage.add(sun);

		lamp = new PointLight();
		lamp.color = 0xff3cdcff;
		lamp.intensity = 20;
		lamp.range = 5;
		stage.add(lamp);
		var glow = new Material();
		glow.baseColor = 0xff3cdcff;
		glow.lit = false;
		marker = new Model(Mesh.sphere(.12, 8, 16), glow);
		stage.add(marker);

		spot = new SpotLight();
		spot.setCone(.14, .28);
		spot.intensity = 125;
		spot.setPosition(0, 6, 2);
		stage.add(spot);

		grid = new Batch3D();
		batch = new Batch2D();
	}

	static function onOff(node:Node3D):String
		return node.visible ? "on " : "off";

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (input.isFramePressed(Key.Digit1))
			sun.visible = !sun.visible;
		if (input.isFramePressed(Key.Digit2))
			lamp.visible = !lamp.visible;
		if (input.isFramePressed(Key.Digit3))
			spot.visible = !spot.visible;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		// The point light orbits through the row; the spot sweeps left and right.
		var lx = Math.sin(time * .6) * 5, lz = Math.cos(time * .6) * 2;
		lamp.setPosition(lx, 1.2, lz);
		marker.setPosition(lx, 1.2, lz);
		marker.visible = lamp.visible;
		spot.lookAt(Math.sin(time * .8) * .7, 5, 1.7);
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0xff0c0d12);
		grid.begin(camera);
		grid.grid(20, 1, 0xff282a32);
		grid.end();
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX lights: directional, point, spot", vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		batch.drawTextWrapped('[1] sun ${onOff(sun)}   [2] point light ${onOff(lamp)}   [3] spotlight ${onOff(spot)}', vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		grid.destroy();
		batch.destroy();
	}
}
