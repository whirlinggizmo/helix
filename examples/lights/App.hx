import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Drawing3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.PointLight3D;
import helix.render3d.SpotLight3D;
import helix.render3d.View3D;
import helix.time.Time;
import helix.host.ScreenShape;

/** Directional, point and spot lights in a level shown by a View3D: five standing figures (capsules) on a grid (a Drawing3D), a dim warm sun, a cyan point light orbiting
	through them and fading with its range (its marker an unlit sphere), and a white spotlight sweeping across them from above. The level
	starts unlit but for a faint ambient light (an Environment3D on its root); every light here is explicit. 1, 2 and 3 toggle the sun, the point light and the spotlight; Escape quits where quitting means
	anything. */
class App extends helix.App {
	static inline var FIGURES = 5;

	var level = new Node3D();
	var camera = new Camera3D();
	var hud = new Drawing2D();
	var fps = new FpsOverlay();
	var sun:DirectionalLight3D;
	var lamp:PointLight3D;
	var marker:Model3D;
	var spot:SpotLight3D;

	override public function init():Void {
		Window.title = "HeliX lights";
		Window.requestSize(1000, 600);
		Stage.color = 0xff0c0d12;
		level.environment = new Environment3D();
		level.environment.setAmbient(0xff5a6ea0, .05);
		camera.setView(0, 4.5, 10, 0, 1, 0);
		// Framed for 16:9: all the row across on a phone held upright too.
		camera.minAspect = 16 / 9;

		var figure = Mesh3D.capsule(.3, 1.7, 16, 32), skin = new Material3D();
		skin.baseColor = 0xffd8d8d8;
		skin.roughness = .6;
		for (i in 0...FIGURES) {
			var node = new Model3D(figure, skin);
			node.setPosition(-4 + 2 * i, .85, i % 2 == 1 ? -.8 : .8);
			level.addChild(node);
		}

		sun = new DirectionalLight3D();
		sun.color = 0xffffd2a0;
		sun.intensity = 1.1;
		sun.lookAt(-.4, -1, -.6);
		level.addChild(sun);

		lamp = new PointLight3D();
		lamp.color = 0xff3cdcff;
		lamp.intensity = 20;
		lamp.range = 5;
		level.addChild(lamp);
		var glow = new Material3D();
		glow.baseColor = 0xff3cdcff;
		glow.lit = false;
		marker = new Model3D(Mesh3D.sphere(.12, 8, 16), glow);
		level.addChild(marker);

		spot = new SpotLight3D();
		spot.setCone(.14, .28);
		spot.intensity = 125;
		spot.setPosition(0, 6, 2);
		level.addChild(spot);

		var grid = new Drawing3D();
		grid.grid(20, 1, 0xff282a32);
		level.addChild(grid);
		Stage.addChild(new View3D(level, camera));
		Stage.addChild(hud);
		Stage.addChild(fps);
	}

	static function onOff(node:Node3D):String
		return node.visible ? "on " : "off";

	override public function update(dt:Float):Void {
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
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		hud.clear();
		var y = vy + 36;
		y += hud.drawTextWrapped("HeliX lights: directional, point, spot", vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		hud.drawTextWrapped('[1] sun ${onOff(sun)}   [2] point light ${onOff(lamp)}   [3] spotlight ${onOff(spot)}', vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		fps.setPosition(vx + 12, vy + 10);
	}
}
