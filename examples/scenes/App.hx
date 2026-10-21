import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.scene.Loader;
import helix.scene.Scene;
import helix.scene.Scenes;
import helix.scene.Splash;
import helix.scene.Transition.Fade;
import helix.tween.Ease;
import helix.host.ScreenShape;

/** A game's flow on a scene stack (helix.scene.Scenes), a movie-like opening: the built-in Splash fading in (the logo, "press any key"
	until a press unlocks audio, or three seconds for the impatient), a title, a level whose files load behind the built-in Loading scene,
	which holds once loaded until a press ("loaded, go"), a pause menu pushed over the level (Escape; the level pauses under it) and popped,
	and back to the title; a fade between the screens. The window losing focus pauses the game's clock and the top scene. Its settings come
	from its config.json beside the program (Host.config, read as the program starts): showSplash, splashSeconds, splashMaxWait, clickToContinue (the
	loading screen's hold) and tip, with a "development" profile that skips the splash and the hold (the run option config=development, or the
	file's "profile"), and the run option quick=1 skips every wait and transition. Options: autopilot (a script under assets/), fast (1: up
	to 120 ticks a frame under autopilot) and autoclose (1: quit once the script is done); the probes are scene, count, loaded, loading,
	visited and activated. Escape on the title quits where quitting means anything. */
class App extends helix.App {
	/** Every scene entered, in order: what the autopilot's run is judged by. Kept across a hot reload (@:hot). */
	@:hot public static var visited:Array<String> = [];

	/** The one batch the scenes draw with, kept across a hot reload. */
	@:hot public static var batch:Batch2D;

	var scenes:Scenes;
	var pilot:Null<Autopilot>;
	var fast = false;
	var published = false;

	override public function init():Void {
		scenes = new Scenes();
		Window.title = "HeliX scenes";
		Window.requestSize(960, 540);
		batch = new Batch2D();
		// The loading screen stays once loaded, for a press, with a caption and a tip (a level may bring its own: Scene.loadingScene),
		// as the config says.
		var loading = cast(scenes.loadingScene, helix.scene.Loading);
		loading.holdForPress = Host.getOptionBool("clickToContinue", true);
		loading.text = "Loading the field";
		loading.tip = Host.getOption("tip", "");
		var script = Host.getOption("autopilot", "");
		fast = Host.getOption("fast", "0") == "1";
		if (script != "")
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		else
			start();
	}

	// The autopilot's script in: the pilot made, then the game started.
	function startPilot(bytes:haxe.io.Bytes):Void {
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name));
		// The window of a headless run isn't focused: its ticks run regardless.
		scenes.pauseOnBlur = false;
		start();
	}

	// The splash first, with the logo once it's in (or without it), unless the config skips it.
	function start():Void {
		if (!Host.getOptionBool("showSplash", true)) {
			scenes.push(new Title());
			return;
		}
		Textures.load("sprites/logo/wg-logo-white-alpha.png", true, logo -> splash(logo), _ -> splash(null));
	}

	// The splash, showing logo (or nothing, when it didn't load), then the title.
	function splash(logo:Null<Texture2D>):Void {
		var shown = new Splash(logo, Host.getOptionFloat("splashSeconds", 1), new Title());
		shown.maxWait = Host.getOptionFloat("splashMaxWait", 0);
		scenes.push(shown, new Fade(.8));
	}

	function probe(name:String):Dynamic {
		var top = scenes.top;
		return switch name {
			case "scene": top == null ? "" : top.name;
			case "count": scenes.count;
			case "loaded": top != null && (top.loader == null || top.loader.done);
			case "loading": scenes.loading;
			case "visited": visited.length;
			case "activated": scenes.input.activated;
			case "transitioning": scenes.transitioning;
			default: throw 'Unknown probe ' + name;
		}
	}

	override public function frame(dt:Float):Void {
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		if (pilot != null && !pilot.done && scenes.top != null) {
			// The script's ticks, each a sixtieth of a second to the scenes, many a frame when fast; none until the splash is up (its logo loads first).
			for (_ in 0...(fast ? 120 : 1)) {
				var source:IInput = pilot.advance(name -> probe(name));
				if (pilot.done)
					break;
				scenes.input = source;
				scenes.update(1 / 60);
				source.consume();
			}
		} else
			scenes.update(dt);
		if (scenes.top == null) {
			Graphics.beginFrame(width, height, 0x14161cff);
			Graphics.endFrame();
		} else
			scenes.draw();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({game: {scene: probe("scene"), visited: visited}, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		scenes.destroy();
		batch.destroy();
	}
}

/** The title: Enter or a tap starts the level, with a fade; Escape quits where quitting means anything. */
class Title extends Scene {
	var camera = new Camera2D();

	override public function enter():Void
		App.visited.push(this.name);

	override public function update(dt:Float):Void {
		var input = scenes.input;
		if (input.isFramePressed(Key.Enter) || input.pointerFramePressed)
			scenes.replace(new Play(), new Fade(.6));
		else if (input.isFramePressed(Key.Escape) && Host.canQuit())
			Host.quit();
	}

	override public function draw():Void {
		Draw.screen(camera, 0x1c1e26ff, "HeliX scenes", "Enter or tap: play" + (Host.canQuit() ? "   Escape: quit" : ""));
	}
}

/** The level: its two textures load first, behind the loading scene; then the logo bounces about. Escape pushes the pause menu. */
class Play extends Scene {
	var loads:Null<Loader>;
	var logo:Null<Texture2D>;
	var tiles:Null<Texture2D>;
	var camera = new Camera2D();
	var time = 0.;

	override public function enter():Void {
		App.visited.push(this.name);
		loads = new Loader();
		loads.texture("sprites/logo/wg-logo-white-alpha.png", true, texture -> logo = texture);
		loads.texture("textures/tiles.png", false, texture -> tiles = texture);
	}

	override function get_loader():Null<Loader>
		return loads;

	override public function update(dt:Float):Void {
		time += dt;
		if (scenes.input.isFramePressed(Key.Escape))
			scenes.push(new Pause(), new Fade(.3, 0x00000080));
	}

	override public function draw():Void {
		var p = Draw.screen(camera, 0x10281cff, "Playing", "Escape: pause");
		var vx = p.visibleX,
			vy = p.visibleY,
			vw = p.visibleWidth,
			vh = p.visibleHeight;
		App.batch.begin(camera);
		// The logo bouncing across, the tiles sheet in the corner.
		var x = vx + 60 + (vw - 120 - 120) * (.5 + .5 * Math.sin(time * 1.2)),
			y = vy + vh * .45 + Ease.bounceOut((time * .7) % 1) * 80 - 40;
		if (logo != null)
			App.batch.sprite(logo, x, y, 120, 120);
		if (tiles != null)
			App.batch.sprite(tiles, vx + vw - 140, vy + vh - 140, 120, 120);
		App.batch.end();
	}
}

/** The pause menu over the level, which waits under it: Escape pops back, T goes to the title. */
class Pause extends Scene {
	var camera = new Camera2D();

	override public function enter():Void
		App.visited.push(this.name);

	override public function update(dt:Float):Void {
		var input = scenes.input;
		if (input.isFramePressed(Key.Escape))
			scenes.pop(new Fade(.3, 0x00000080));
		else if (input.isFramePressed(Key.T)) {
			scenes.pop();
			scenes.replace(new Title(), new Fade(.6));
		}
	}

	override public function draw():Void {
		Draw.screen(camera, 0x262c3cff, "Paused", "Escape: resume   T: title");
	}
}

/** A screen's drawing the scenes share: the frame begun in a color, a title and a line of help in the design for the window's shape. */
class Draw {
	/** Begins the frame in color and draws title and help; returns the presentation, for drawing more in the visible area. */
	public static function screen(camera:Camera2D, color:Int, title:String, help:String):helix.host.Presentation {
		ScreenShape.update();
		var p = Screen.instance;
		p.apply(camera);
		var vx = p.visibleX, vy = p.visibleY, vw = p.visibleWidth;
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, color);
		App.batch.begin(camera);
		var y = vy + 36;
		y += App.batch.drawTextWrapped(title, vx + 12, y, 22, vw - 24, 0xf5f5f5ff) + 4;
		App.batch.drawTextWrapped(help, vx + 12, y, 15, vw - 24, 0xc8c8c8ff);
		App.batch.end();
		return p;
	}
}
