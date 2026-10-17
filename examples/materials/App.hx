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
import helix.render2d.Textures;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;
import helix.time.Time;

/** glTF metallic-roughness materials made in code, one sphere mesh under them all. Top row: plastic (metallic 0), roughness 0 to 1 left to
	right; middle row: gold (metallic 1), the same steps; bottom row: unlit, emissive, normal mapped and see-through, turning so the normal map
	moves. A sun, an orbiting blue point light (its marker an unlit sphere) and a little ambient light. 1 toggles the sun, 2 the lamp; Escape
	quits where quitting means anything. */
class App extends BaseApp {
	static inline var COLUMNS = 5;
	static inline var SPACING = 1.35;

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var sun:DirectionalLight;
	var lamp:PointLight;
	var marker:Model;
	var bottom:Array<Node3D> = [];

	// A linear color (as the earlier frameworks' examples give them) as 0xRRGGBBAA, sRGB-encoded.
	static function color(r:Float, g:Float, b:Float, a = 1.):Int {
		inline function encode(c:Float):Int
			return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
		return encode(r) << 24 | encode(g) << 16 | encode(b) << 8 | Math.round(a * 255);
	}

	static function pbr(base:Int, metallic:Float, roughness:Float):Material {
		var material = new Material();
		material.baseColor = base;
		material.metallic = metallic;
		material.roughness = roughness;
		return material;
	}

	function sphere(mesh:Mesh, x:Float, y:Float, material:Material):Model {
		var node = new Model(mesh, material);
		node.setPosition(x, y, 0);
		stage.add(node);
		return node;
	}

	override public function init():Void {
		Window.title = "HeliX materials";
		Window.requestSize(1000, 700);
		stage = new Stage3D();
		stage.setAmbient(0xffffffff, .12);
		camera.setView(0, 1.6, 7.5, 0, 1.2, 0);
		// Framed for 16:9: all five columns across on a phone held upright too.
		camera.minAspect = 16 / 9;

		sun = new DirectionalLight();
		sun.color = 0xfff4e4ff;
		sun.intensity = 3;
		sun.lookAt(-.4, -.7, -.6);
		stage.add(sun);
		lamp = new PointLight();
		lamp.color = 0x78beffff;
		lamp.intensity = 8;
		lamp.range = 10;
		stage.add(lamp);
		var glow = new Material();
		glow.baseColor = 0x66bfffff;
		glow.lit = false;
		marker = new Model(Mesh.sphere(.06, 8, 16), glow);
		stage.add(marker);

		// Rows of roughness steps: red plastic, then gold.
		var ball = Mesh.sphere(.5, 24, 48);
		for (c in 0...COLUMNS) {
			var x = (c - (COLUMNS - 1) / 2) * SPACING,
				roughness = c / (COLUMNS - 1);
			sphere(ball, x, 2.7, pbr(color(.8, .05, .04), 0, roughness));
			sphere(ball, x, 1.35, pbr(color(1, .77, .34), 1, roughness));
		}
		var unlit = new Material();
		unlit.baseColor = 0x66bfffff;
		unlit.lit = false;
		bottom.push(sphere(ball, -2 * SPACING, 0, unlit));
		var emissive = pbr(color(.05, .05, .05), 0, .6);
		emissive.setEmissive(color(1, .35, .05));
		bottom.push(sphere(ball, -SPACING, 0, emissive));
		var tiles = pbr(color(.6, .6, .62), 0, .45);
		Textures.load("textures/tiles_normal.png", true, texture -> tiles.normalTexture = texture);
		bottom.push(sphere(ball, 0, 0, tiles));
		bottom.push(sphere(ball, SPACING, 0, pbr(color(.3, .9, .5, .35), 0, .1)));
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Digit1))
			sun.visible = !sun.visible;
		if (input.isFramePressed(Key.Digit2))
			lamp.visible = !lamp.visible;
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		var lx = Math.cos(time * .7) * 4,
			ly = 1.4 + Math.sin(time * .9) * 1.2,
			lz = Math.sin(time * .7) * 1.5 + 2;
		lamp.setPosition(lx, ly, lz);
		marker.setPosition(lx, ly, lz);
		marker.visible = lamp.visible;
		for (node in bottom)
			node.setRotation(0, time * .5, 0);
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

		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX materials: metallic-roughness, unlit, emissive, normal map, blend", vx + 12, y, 18, vw - 24, 0xf5f5f5ff) + 4;
		batch.drawTextWrapped('roughness 0 -> 1 (left to right)   rows: plastic, gold   [1] sun ${sun.visible ? "on" : "off"}  [2] lamp ${lamp.visible ? "on" : "off"}',
			vx
			+ 12, y, 15, vw
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
