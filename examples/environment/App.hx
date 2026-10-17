import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Shaders;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.Environment;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.Stage3D;
import helix.render3d.Tonemap;

/** Image-based light, a background and tone mapping: the material spheres (red plastic above, gold below, roughness 0 to 1 left to right), a
	normal-mapped sphere, a pearl (a surface shader of the example's own that lets the stage shade it) and a car, lit by an environment alone,
	no lights and no ambient light. Metals mirror the world around them; rougher
	surfaces blur it. Each environment is a 1K .hdr from Poly Haven, prepared as it loads a few milliseconds a frame (Environments); until it's
	ready the stage is lit by nothing, and the readout says how long it took.

	E: environment (sunset, studio, none); B: background (sharp, soft, blurred, off); T: tone mapping (Neutral, ACES, none); UP / DOWN:
	exposure, half a stop a press; LEFT / RIGHT: turn the environment; O: orbit the camera or hold it; Escape: quit, where quitting means
	anything. */
class App extends BaseApp {
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
	var orbit = true;
	var angle = 0.;
	var turning:Array<Node> = [];
	var shaders:Shaders;

	// A linear color as 0xRRGGBBAA, sRGB-encoded.
	static function color(r:Float, g:Float, b:Float):Int {
		inline function encode(c:Float):Int
			return Math.round((c <= .0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - .055) * 255);
		return encode(r) << 24 | encode(g) << 16 | encode(b) << 8 | 255;
	}

	function sphere(mesh:Mesh, x:Float, y:Float, base:Int, metallic:Float, roughness:Float):Material {
		var material = new Material();
		material.setBaseColor(base);
		material.setMetallic(metallic);
		material.setRoughness(roughness);
		var node = Node.model(mesh, material);
		node.setPosition(x, y, 0);
		stage.add(node);
		turning.push(node);
		return material;
	}

	override public function init():Void {
		Services.window.setTitle("HeliX environment");
		Services.window.requestSize(1000, 700);
		batch = new Batch2D(Services.graphics);
		stage = new Stage3D(Services.graphics);
		// Framed for 16:9: every column of spheres on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var ball = Mesh.sphere(.5, 32, 64);
		for (c in 0...COLUMNS) {
			var x = (c - (COLUMNS - 1) / 2) * SPACING,
				roughness = c / (COLUMNS - 1);
			sphere(ball, x, 2.7, color(.8, .05, .04), 0, roughness);
			sphere(ball, x, 1.35, color(1, .77, .34), 1, roughness);
		}
		var tiles = sphere(ball, -SPACING, 0, color(.6, .6, .62), 0, .35);
		Services.textures.load("textures/tiles_normal.png", true, result -> switch result {
			case Ready(texture): tiles.setNormalTexture(texture);
			case Failed(message): trace(message);
			case Cancelled:
		});
		sphere(ball, -2 * SPACING, 0, color(.95, .95, .95), 1, .1);
		var pearl = sphere(ball, 0, 0, color(.9, .88, .85), 0, .2);
		shaders = new Shaders(Services.assets, Services.graphics);
		shaders.load("shaders/pearl.hxshader", result -> switch result {
			case Ready(shader): pearl.setShader(shader);
			case Failed(message): trace(message);
			case Cancelled:
		});
		new Models(Services.assets, Services.textures).load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				var car = file.instantiate("car");
				car.setPosition(2.7, -.5, .2);
				car.setScale(1.1, 1.1, 1.1);
				stage.add(car);
				turning.push(car);
			case Failed(message):
				trace(message);
			case Cancelled:
		});
		for (i in 0...PATHS.length) {
			var started = Services.getTime();
			Services.environments.load(PATHS[i], result -> switch result {
				case Ready(environment):
					environments[i] = environment;
					loadMs[i] = (Services.getTime() - started) * 1000;
					// Said in the log too, so a run without a screen shows how long the bake took.
					trace('${NAMES[i]} ready in ${Math.round(loadMs[i])} ms');
				case Failed(message):
					trace(message);
				case Cancelled:
			});
		}
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
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
			orbit = !orbit;
		// The game's clock: paused, the motion stops.
		var time = Services.clock.getTime();
		// The orbit starts once everything is in (both environments bake at the start): from the front, so a picture taken then (the site's,
		// once nothing loads) sees the rows, not their ends.
		if (orbit && !Services.isBusy())
			angle += dt * .15;
		for (node in turning)
			node.setRotation(0, time * .3, 0);
		fps.update(dt, Services.getFrameCpu());

		var environment = current < PATHS.length ? environments[current] : null;
		stage.setEnvironment(environment, 1, rotation);
		stage.setBackground(blur < BLURS.length ? environment : null, blur < BLURS.length ? BLURS[blur] : 0);
		stage.setTonemap(TONEMAPS[tonemap]);
		stage.setExposure(exposure);

		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(7.5 * Math.sin(angle), 1.8, 7.5 * Math.cos(angle), 0, 1.2, 0);
		// The readout in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		var title = "HeliX environment: image-based light, a background and tone mapping";
		var state = current == PATHS.length ? "" : environment == null ? " (preparing)" : ' (ready in ${Math.round(loadMs[current])} ms)';
		var readout = '[E] ${NAMES[current]}$state   [B] background ${BLUR_NAMES[blur]}   [T] ${TONEMAP_NAMES[tonemap]}   '
			+ 'UP/DOWN exposure ${exposure >= 0 ? "+" : ""}$exposure EV   LEFT/RIGHT turn   [O] camera';
		// The band's height is the readout's, wrapped.
		var wrap = vw - 24, font = batch.getFont();
		var readoutY = vy + 36 + Text2D.measureWrapped(font, title, 20, wrap) + 3,
			bottom = readoutY + Text2D.measureWrapped(font, readout, 16, wrap) - 2;

		Services.graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(hud);
		// A dark band behind the readout, which a bright sky would wash out.
		batch.rect(vx, vy, vw, bottom - vy, 0x0000008c);
		Text2D.drawWrapped(batch, title, vx + 12, vy + 36, 20, wrap, 0xf5f5f5ff);
		Text2D.drawWrapped(batch, readout, vx + 12, readoutY, 16, wrap, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		for (environment in environments)
			if (environment != null)
				Services.environments.release(environment);
		stage.destroy();
		batch.destroy();
	}
}
