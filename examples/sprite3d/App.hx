import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.graphics.Shader;
import helix.graphics.Shaders;
import helix.graphics.SpriteEffect;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Sprite3D;
import helix.render3d.Stage3D;
import helix.shaders.SpriteDissolve;
import helix.shaders.SpriteFlash;
import helix.shaders.SpriteOutline;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit;

/** Textured sprites on a 3D stage, under a circling camera, over a grid (Batch3D) and a lit pedestal:
	- the logo, facing the camera as it circles, bobbing over the pedestal (blended by its alpha)
	- trees, cut from the tile sheet, upright: they turn to the camera about y only, and stand on their bottom edge (pivot 0.5, 1)
	- a flag on a sign post, as its node is turned (Free), and a coin flat on the ground (Ground)
	- the coin's glow, added over everything (Add), and masked flames that cut out where their texels fade
	Sprites are unlit and instanced: alike ones (a texture, an alpha mode, an effect) are one draw, and the readout counts them.
	Sprite effects (helix.shaders, as on 2D sprites): the trees share one SpriteOutline (1), read only inside each tree's cell of the sheet; the
	sign dissolves (SpriteDissolve, 2), its cut-out still masked; the logo flashes (SpriteFlash) on F. The flames shimmer (3) through the
	example's own sprite shader, shaders/heat.glsl (packed into an .hxshader asset and loaded at run time, new SpriteEffect(shader)), its
	parameters set by name.
	O stops the camera; Escape quits where quitting means anything. Options: autopilot (a script under assets/: the time and the camera are then
	held, the window the autopilot's page's size, so its samples of the frame compare across targets) and autoclose (1: quit once the script is
	done); the probes are ready (the textures and the heat in), outline, dissolving and shimmering. */
class App extends helix.App {
	var stage:Stage3D;
	var batch3D:Batch3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var logo:Sprite3D;
	var sign:Sprite3D;
	// The camera, circling.
	var orbit = new Orbit(8, 3.5, .3, 1);
	var trees:Array<Sprite3D> = [];
	var tileSprites:Array<Sprite3D> = [];
	var flames:Array<Sprite3D> = [];
	var outline:SpriteOutline;
	var dissolve:SpriteDissolve;
	var flash:SpriteFlash;
	var outlined = true;
	var dissolving = true;
	var shaders:Shaders;
	var heat:Null<SpriteEffect>;
	var shimmering = true;
	var loaded = 0;
	var pilot:Null<Autopilot>;
	// Whether an autopilot was asked for: the camera is held from the first frame, before its script is in.
	var piloted = false;
	var published = false;

	// The time the autopilot holds the stage at, and its window's size (the autopilot's browser page's), so its samples compare across targets.
	static inline var HELD_TIME = 2.;
	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;

	// A sprite of the tile sheet's cell x, y, width x height texels, placed at x, z on the ground.
	function tile(cell:Array<Int>, x:Float, z:Float, width:Float, height:Float):Sprite3D {
		var sprite = new Sprite3D(null);
		sprite.setRegion(cell[0], cell[1], cell[2], cell[3]);
		sprite.setSpriteSize(width, height);
		sprite.setPosition(x, 0, z);
		tileSprites.push(sprite);
		stage.add(sprite);
		return sprite;
	}

	override public function init():Void {
		outline = new SpriteOutline(0xffffffff, 1);
		dissolve = new SpriteDissolve();
		flash = new SpriteFlash();
		Window.title = "HeliX sprite3d";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			piloted = true;
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
			Window.requestSize(1000, 600);
		// Framed for 16:9: the pedestal and the trees around it on a phone held upright too.
		camera.minAspect = 16 / 9;
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		batch3D = new Batch3D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		var sun = new DirectionalLight();
		sun.intensity = 2.5;
		sun.lookAt(-.5, -1, -.3);
		stage.add(sun);
		var stone = new Material();
		stone.baseColor = 0x8a8f99ff;
		stone.roughness = .8;
		var pedestal = new Model(Mesh.cylinder(.6, 1), stone);
		pedestal.setPosition(0, .5, 0);
		stage.add(pedestal);

		logo = new Sprite3D(null);
		logo.setSpriteSize(1.6, 1.6);
		stage.add(logo);
		// Trees: upright, standing on their bottom edge.
		for (i in 0...6) {
			var a = i / 6 * Math.PI * 2 + .3;
			var tree = tile([2, 22, 16, 32], Math.cos(a) * 4, Math.sin(a) * 4, 1.2, 2.4);
			tree.facing = Upright;
			tree.setPivot(.5, 1);
			tree.setAlphaMode(Mask, .5);
			tree.effect = outline;
			trees.push(tree);
		}
		// A flag on a post, turned as its node is: a sign.
		sign = tile([22, 22, 16, 32], 2, -1.5, 1, 2);
		sign.facing = Free;
		sign.setPivot(.5, 1);
		sign.setAlphaMode(Mask);
		sign.effect = dissolve;
		// A coin lying on the ground, and its glow added over it.
		var coin = tile([42, 22, 16, 16], -2, 1.5, .8, .8);
		coin.facing = Ground;
		coin.setPosition(-2, .02, 1.5);
		coin.setAlphaMode(Mask);
		Textures.load("sprites/logo/wg-logo-white-alpha.png", true, texture -> useLogo(texture));
		Textures.load("textures/tiles.png", false, texture -> useTiles(texture));
		Textures.load("textures/flame.png", true, texture -> light(texture));
		logo.effect = flash;
		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/heat.hxshader", shader -> useHeat(shader));
	}

	// The example's own shader in: the flames shimmer, its parameters set by name.
	function useHeat(shader:Shader):Void {
		heat = new SpriteEffect(shader);
		heat.parameters.setFloat("amplitude", 16);
		heat.parameters.setFloat("waves", 1.5);
		heat.parameters.setFloat("speed", 1.2);
		shimmer();
		loaded++;
	}

	// The flames through the heat, or as the framework draws them.
	function shimmer():Void
		for (flame in flames)
			flame.effect = shimmering ? heat : null;

	// The autopilot's script in: the input it plays from now on.
	function startPilot(bytes:haxe.io.Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed));

	function probe(name:String):Dynamic
		return switch name {
			case "ready": loaded == 4;
			case "outline": outlined;
			case "dissolving": dissolving;
			case "shimmering": shimmering;
			default: throw 'Unknown probe ' + name;
		}

	// The logo's texture in: the billboard draws it, tinted blue.
	function useLogo(texture:Texture2D):Void {
		logo.texture = texture;
		logo.tint = 0x66bfffff;
		loaded++;
	}

	// The tile sheet in: every tile sprite draws its cell of it.
	function useTiles(texture:Texture2D):Void {
		for (sprite in tileSprites)
			sprite.texture = texture;
		loaded++;
	}

	// The flame sheet in: masked flames, cut out where their soft edges fade, a row of them behind the pedestal, and the coin's glow.
	function light(texture:Texture2D):Void {
		for (i in 0...5) {
			var flame = new Sprite3D(texture, 0xffa040ff);
			flame.setRegion(0, 0, 64, 64);
			flame.setSpriteSize(.9, .9);
			flame.setPivot(.5, 1);
			flame.facing = Upright;
			flame.setAlphaMode(Mask, .4);
			flame.setPosition(i * .8 - 1.6, 0, -2.5);
			flames.push(flame);
			stage.add(flame);
		}
		// The heat, when it came in first.
		if (heat != null)
			shimmer();
		// The coin's glow: a soft puff of the same sheet, gold, added over everything.
		var glow = new Sprite3D(texture, 0xffd25aff);
		glow.setRegion(0, 0, 64, 64);
		glow.setSpriteSize(1.4, 1.4);
		glow.setPosition(-2, .5, 1.5);
		glow.setAlphaMode(Add);
		stage.add(glow);
		loaded++;
	}

	override public function frame(dt:Float):Void {
		// The window's input, or the autopilot's: a tick a frame, none while a sample waits for its frame.
		var input:Null<IInput> = Input.instance;
		if (pilot != null) {
			input = pilot.done ? null : pilot.advance(name -> probe(name));
			if (pilot.awaitingFrame)
				input = null;
		}
		if (input != null) {
			if (Host.canQuit() && input.isFramePressed(Key.Escape))
				Host.quit();
			if (input.isFramePressed(Key.O))
				orbit.running = !orbit.running;
			if (input.isFramePressed(Key.Digit1)) {
				outlined = !outlined;
				for (tree in trees)
					tree.effect = outlined ? outline : null;
			}
			if (input.isFramePressed(Key.Digit2)) {
				dissolving = !dissolving;
				sign.effect = dissolving ? dissolve : null;
			}
			if (input.isFramePressed(Key.Digit3)) {
				shimmering = !shimmering;
				shimmer();
			}
			if (input.isFramePressed(Key.F))
				flash.trigger(0xffffffff, .4);
		}
		// The game's clock: paused, the motion stops; held under the autopilot, the camera with it.
		var time = piloted ? HELD_TIME : Time.clock.time;
		stage.time = time;
		orbit.update(piloted ? 0 : dt);
		// Half gone at the autopilot's held time, coming and going.
		dissolve.amount = .5 + .45 * Math.sin((time - HELD_TIME) * .9);
		fps.update(dt, Time.frameCpu);
		logo.setPosition(0, 2.1 + Math.sin(time * 2) * .2, 0);
		sign.setRotation(0, Math.sin(time) * .8, 0);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x1c1e26ff);
		batch3D.begin(camera);
		batch3D.grid(16, 1, 0x3c3f48ff);
		batch3D.end();
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX sprite3d: sprites facing the camera, upright, flat and free; masked, blended and added", vx + 12, y, 18, vw - 24,
			0xf5f5f5ff)
			+ 4;
		var on = (value:Bool) -> value ? "on" : "off";
		batch.drawTextWrapped('${stage.drawnNodeCount} models and sprites in ${stage.drawCallCount} draws   O: the camera  [1] outline ${on(outlined)}  [2] dissolve ${on(dissolving)}  [3] heat ${on(shimmering)}  [F] flash',
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({
				game: {outline: outlined, dissolving: dissolving, shimmering: shimmering},
				autopilot: pilot.snapshot
			});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		stage.destroy();
		batch3D.destroy();
		batch.destroy();
		if (heat != null)
			shaders.release(heat.shader);
	}
}
