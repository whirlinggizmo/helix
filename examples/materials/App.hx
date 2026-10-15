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
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** glTF metallic-roughness materials made in code, one sphere mesh under them all. Top row: plastic (metallic 0), roughness 0 to 1 left to
	right; middle row: gold (metallic 1), the same steps; bottom row: unlit, emissive, normal mapped and see-through, turning so the normal map
	moves. A sun, an orbiting blue point light (its marker an unlit sphere) and a little ambient light. 1 toggles the sun, 2 the lamp; Escape
	quits where quitting means anything. */
class App extends BaseApp {
	static inline var COLUMNS = 5;
	static inline var SPACING = 1.35;

	var services:Services;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var sun:Node;
	var lamp:Node;
	var marker:Node;
	var bottom:Array<Node> = [];
	var time = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	// A linear color (as the earlier frameworks' examples give them) as 0xRRGGBBAA, sRGB-encoded.
	static function color(r:Float, g:Float, b:Float, a = 1.):Int {
		inline function encode(c:Float):Int
			return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
		return encode(r) << 24 | encode(g) << 16 | encode(b) << 8 | Math.round(a * 255);
	}

	static function pbr(base:Int, metallic:Float, roughness:Float):Material {
		var material = new Material();
		material.setBaseColor(base);
		material.setMetallic(metallic);
		material.setRoughness(roughness);
		return material;
	}

	function sphere(mesh:Mesh, x:Float, y:Float, material:Material):Node {
		var node = Node.model(mesh, material);
		node.setPosition(x, y, 0);
		stage.add(node);
		return node;
	}

	override public function init():Void {
		services.window.setTitle("HeliX materials");
		services.window.requestSize(1000, 700);
		stage = new Stage3D(services.graphics);
		stage.setAmbient(0xffffffff, .12);
		camera.setView(0, 1.6, 7.5, 0, 1.2, 0);

		var sunLight = new Light(Directional);
		sunLight.setColor(0xfff4e4ff);
		sunLight.setIntensity(3);
		sun = Node.light(sunLight);
		sun.lookAt(-.4, -.7, -.6);
		stage.add(sun);
		var lampLight = new Light(Point);
		lampLight.setColor(0x78beffff);
		lampLight.setIntensity(8);
		lampLight.setRange(10);
		lamp = Node.light(lampLight);
		stage.add(lamp);
		var glow = new Material();
		glow.setBaseColor(0x66bfffff);
		glow.setLit(false);
		marker = Node.model(Mesh.sphere(.06, 8, 16), glow);
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
		unlit.setBaseColor(0x66bfffff);
		unlit.setLit(false);
		bottom.push(sphere(ball, -2 * SPACING, 0, unlit));
		var emissive = pbr(color(.05, .05, .05), 0, .6);
		emissive.setEmissive(color(1, .35, .05));
		bottom.push(sphere(ball, -SPACING, 0, emissive));
		var tiles = pbr(color(.6, .6, .62), 0, .45);
		services.textures.load("textures/tiles_normal.png", true, result -> switch result {
			case Ready(texture): tiles.setNormalTexture(texture);
			case Failed(message): trace(message);
			case Cancelled:
		});
		bottom.push(sphere(ball, 0, 0, tiles));
		bottom.push(sphere(ball, SPACING, 0, pbr(color(.3, .9, .5, .35), 0, .1)));
		batch = new Batch2D(services.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.Digit1))
			sun.setVisible(!sun.isVisible());
		if (input.isFramePressed(Key.Digit2))
			lamp.setVisible(!lamp.isVisible());
		time += dt;
		var lx = Math.cos(time * .7) * 4,
			ly = 1.4 + Math.sin(time * .9) * 1.2,
			lz = Math.sin(time * .7) * 1.5 + 2;
		lamp.setPosition(lx, ly, lz);
		marker.setPosition(lx, ly, lz);
		marker.setVisible(lamp.isVisible());
		for (node in bottom)
			node.setRotation(0, time * .5, 0);
		fps.update(dt, services.getFrameCpu());
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera2D.setViewport(width, height);
		camera2D.pixels(services.window.getPixelRatio());

		services.graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		Text2D.draw(batch, "HeliX materials: metallic-roughness, unlit, emissive, normal map, blend", 12, 36, 18, 0xf5f5f5ff);
		Text2D.draw(batch,
			'roughness 0 -> 1 (left to right)   rows: plastic, gold   [1] sun ${sun.isVisible() ? "on" : "off"}  [2] lamp ${lamp.isVisible() ? "on" : "off"}',
			12, 62, 15, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
