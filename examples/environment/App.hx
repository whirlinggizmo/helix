import helix.assets.Assets;
import helix.debug.FpsOverlay;
import helix.graphics.Color;
import helix.graphics.Graphics;
import helix.graphics.Shaders;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Textures;
import helix.render3d.Camera3D;
import helix.render3d.Environment;
import helix.render3d.Environments;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.render3d.Tonemap;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit;

/** Image-based light, a background and tone mapping: the material spheres (red plastic above, gold below, roughness 0 to 1 left to right), a
	normal-mapped sphere, a pearl (a surface shader of the example's own that lets the stage shade it) and a car, lit by an environment alone,
	no lights and no ambient light. Metals mirror the world around them; rougher
	surfaces blur it. Each environment is a 1K .hdr from Poly Haven, prepared as it loads a few milliseconds a frame (Environments); until it's
	ready the stage is lit by nothing, and the readout says how long it took.

	E: environment (sunset, studio, none); B: background (sharp, soft, blurred, off); T: tone mapping (Neutral, ACES, none); UP / DOWN:
	exposure, half a stop a press; LEFT / RIGHT: turn the environment; O: orbit the camera or hold it; Escape: quit, where quitting means
	anything. */
class App extends helix.App {
	static inline var COLUMNS = 5;
	static inline var SPACING = 1.35;
	static var PATHS = ["environments/venice_sunset_1k.hdr", "environments/studio_small_09_1k.hdr"];
	static var NAMES = ["sunset", "studio", "none"];
	static var BLURS = [0., .35, .8];
	static var BLUR_NAMES = ["sharp", "soft", "blurred", "off"];
	static var TONEMAPS = [Tonemap.Neutral, Tonemap.Aces, Tonemap.None];
	static var TONEMAP_NAMES = ["Neutral", "ACES", "none"];

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var environments:Array<Null<Environment>> = [null, null];
	var loadMs:Array<Float> = [0, 0];
	var current = 0;
	var blur = 1;
	var tonemap = 0;
	var exposure = 0.;
	var rotation = 0.;
	// The camera, circling.
	var orbit = new Orbit(7.5, 1.8, .15, 1.2);
	var turning:Array<Node3D> = [];
	var shaders:Shaders;

	// A linear color as 0xAARRGGBB, sRGB-encoded.
	static function color(r:Float, g:Float, b:Float):Int {
		inline function encode(c:Float):Int
			return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
		return Color.fromChannels(encode(r), encode(g), encode(b));
	}

	function sphere(mesh:Mesh, x:Float, y:Float, base:Int, metallic:Float, roughness:Float):Material {
		var material = new Material();
		material.baseColor = base;
		material.metallic = metallic;
		material.roughness = roughness;
		var node = new Model(mesh, material);
		node.setPosition(x, y, 0);
		stage.add(node);
		turning.push(node);
		return material;
	}

	override public function init():Void {
		Window.title = "HeliX environment";
		Window.requestSize(1000, 700);
		batch = new Batch2D();
		stage = new Stage3D();
		// Framed for 16:9: every column of spheres on a phone held upright too.
		camera.minAspect = 16 / 9;
		var ball = Mesh.sphere(.5, 32, 64);
		for (c in 0...COLUMNS) {
			var x = (c - (COLUMNS - 1) / 2) * SPACING,
				roughness = c / (COLUMNS - 1);
			sphere(ball, x, 2.7, color(.8, .05, .04), 0, roughness);
			sphere(ball, x, 1.35, color(1, .77, .34), 1, roughness);
		}
		var tiles = sphere(ball, -SPACING, 0, color(.6, .6, .62), 0, .35);
		Textures.load("textures/tiles_normal.png", true, texture -> tiles.normalTexture = texture);
		sphere(ball, -2 * SPACING, 0, color(.95, .95, .95), 1, .1);
		var pearl = sphere(ball, 0, 0, color(.9, .88, .85), 0, .2);
		shaders = new Shaders(Assets.instance, Graphics.instance);
		shaders.load("shaders/pearl.hxshader", shader -> pearl.setShader(shader));
		Models.load("models/car-kit/sedan-sports.glb", file -> place(file));
		for (i in 0...PATHS.length) {
			var started = Time.time;
			Environments.load(PATHS[i], environment -> prepared(i, environment, started));
		}
	}

	// The car's file in: a copy of it turning beside the spheres.
	function place(file:ModelFile):Void {
		var car = file.instantiate("car");
		car.setPosition(2.7, -.5, .2);
		car.setScale(1.1, 1.1, 1.1);
		stage.add(car);
		turning.push(car);
	}

	// Environment i prepared, its load begun at started: kept, with how long it took.
	function prepared(i:Int, environment:Environment, started:Float):Void {
		environments[i] = environment;
		loadMs[i] = (Time.time - started) * 1000;
		// Said in the log too, so a run without a screen shows how long the bake took.
		trace('${NAMES[i]} ready in ${Math.round(loadMs[i])} ms');
	}

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.E))
			current = (current + 1) % NAMES.length;
		if (input.isFramePressed(Key.B))
			blur = (blur + 1) % BLUR_NAMES.length;
		if (input.isFramePressed(Key.T))
			tonemap = (tonemap + 1) % TONEMAPS.length;
		if (input.isFramePressed(Key.Up))
			exposure += .5;
		if (input.isFramePressed(Key.Down))
			exposure -= .5;
		if (input.isDown(Key.Left))
			rotation -= dt;
		if (input.isDown(Key.Right))
			rotation += dt;
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		// The game's clock: paused, the motion stops.
		var time = Time.clock.time;
		// The orbit starts once everything is in (both environments bake at the start): from the front, so a picture taken then (the site's,
		// once nothing loads) sees the rows, not their ends.
		if (!Host.busy)
			orbit.update(dt);
		for (node in turning)
			node.setRotation(0, time * .3, 0);
		fps.update(dt, Time.frameCpu);

		var environment = current < PATHS.length ? environments[current] : null;
		stage.setEnvironment(environment, 1, rotation);
		stage.setBackground(blur < BLURS.length ? environment : null, blur < BLURS.length ? BLURS[blur] : 0);
		stage.tonemap = TONEMAPS[tonemap];
		stage.exposure = exposure;

		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		// The readout in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var title = "HeliX environment: image-based light, a background and tone mapping";
		var state = current == PATHS.length ? "" : environment == null ? " (preparing)" : ' (ready in ${Math.round(loadMs[current])} ms)';
		var readout = '[E] ${NAMES[current]}$state   [B] background ${BLUR_NAMES[blur]}   [T] ${TONEMAP_NAMES[tonemap]}   '
			+ 'UP/DOWN exposure ${exposure >= 0 ? "+" : ""}$exposure EV   LEFT/RIGHT turn   [O] camera';
		// The band's height is the readout's, wrapped.
		var wrap = vw - 24, font = batch.font;
		var readoutY = vy + 36 + font.measureWrapped(title, 20, wrap) + 3,
			bottom = readoutY + font.measureWrapped(readout, 16, wrap) - 2;

		Graphics.beginFrame(width, height, 0xff14161c);
		stage.draw(camera);
		batch.begin(hud);
		// A dark band behind the readout, which a bright sky would wash out.
		batch.rect(vx, vy, vw, bottom - vy, 0x8c000000);
		batch.drawTextWrapped(title, vx + 12, vy + 36, 20, wrap, 0xfff5f5f5);
		batch.drawTextWrapped(readout, vx + 12, readoutY, 16, wrap, 0xffc8c8c8);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		for (environment in environments)
			if (environment != null)
				Environments.release(environment);
		stage.destroy();
		batch.destroy();
	}
}
