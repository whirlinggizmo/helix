import helix.app.BaseApp;
import helix.debug.Autopilot;
import helix.host.Services;
import helix.input.IInput;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.scene.Loader;
import helix.scene.Scene;
import helix.scene.Scenes;
import helix.scene.Splash;
import helix.scene.Transition.Fade;
import helix.tween.Ease;

/** A game's flow on a scene stack (helix.scene.Scenes), a movie-like opening: the built-in Splash fading in (the logo, "press any key"
	until a press unlocks audio, or three seconds for the impatient), a title, a level whose files load behind the built-in Loading scene,
	which holds once loaded until a press ("loaded, go"), a pause menu pushed over the level (Escape; the level pauses under it) and popped,
	and back to the title; a fade between the screens. The window losing focus pauses the game's clock and the top scene. Its settings come
	from assets/config.json (Services.config, fetched as the program starts): showSplash, splashSeconds, splashMaxWait, clickToContinue (the
	loading screen's hold) and tip, with a "development" profile that skips the splash and the hold (the run option config=development, or the
	file's "profile"), and the run option quick=1 skips every wait and transition. Options: autopilot (a script under assets/), fast (1: up
	to 120 ticks a frame under autopilot) and autoclose (1: quit once the script is done); the probes are scene, count, loaded, loading,
	visited and activated. Escape on the title quits where quitting means anything. */
class App extends BaseApp {
	/** Every scene entered, in order: what the autopilot's run is judged by. */
	public static var visited:Array<String> = [];

	/** The one batch the scenes draw with. */
	public static var batch:Batch2D;

	var scenes = new Scenes();
	var pilot:Null<Autopilot>;
	var fast = false;
	var published = false;

	override public function init():Void {
		Services.window.setTitle("HeliX scenes");
		Services.window.requestSize(960, 540);
		batch = new Batch2D(Services.graphics);
		// The loading screen stays once loaded, for a press, with a caption and a tip (a level may bring its own: Scene.getLoadingScene),
		// as the config says.
		var loading = cast(scenes.getLoadingScene(), helix.scene.Loading);
		loading.setHoldForPress(Services.getOptionBool("clickToContinue", true));
		loading.setText("Loading the field");
		loading.setTip(Services.getOption("tip", ""));
		var script = Services.getOption("autopilot", "");
		fast = Services.getOption("fast", "0") == "1";
		if (script != "")
			Services.assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString(), name -> Services.screenshots.take(name));
					// The window of a headless run isn't focused: its ticks run regardless.
					scenes.setPauseOnBlur(false);
					start();
				case Failed(message): throw 'Autopilot load failed: ' + message;
				case Cancelled:
			});
		else
			start();
	}

	// The splash first, with the logo once it's in (or without it), unless the config skips it.
	function start():Void {
		if (!Services.getOptionBool("showSplash", true)) {
			scenes.push(new Title());
			return;
		}
		Services.textures.load("sprites/logo/wg-logo-white-alpha.png", true, result -> {
			var splash = new Splash(switch result {
				case Ready(logo): logo;
				case _: null;
			}, Services.getOptionFloat("splashSeconds", 1), new Title());
			splash.setMaxWait(Services.getOptionFloat("splashMaxWait", 0));
			scenes.push(splash, new Fade(.8));
		});
	}

	function probe(name:String):Dynamic {
		var top = scenes.getTop();
		return switch name {
			case "scene": top == null ? "" : top.getName();
			case "count": scenes.getCount();
			case "loaded": top != null && (top.getLoader() == null || top.getLoader().isDone());
			case "loading": scenes.isLoading();
			case "visited": visited.length;
			case "activated": scenes.getInput().isActivated();
			case "transitioning": scenes.isTransitioning();
			default: throw 'Unknown probe ' + name;
		}
	}

	override public function frame(dt:Float):Void {
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		if (pilot != null && !pilot.isDone() && scenes.getTop() != null) {
			// The script's ticks, each a sixtieth of a second to the scenes, many a frame when fast; none until the splash is up (its logo loads first).
			for (_ in 0...(fast ? 120 : 1)) {
				var source:IInput = pilot.advance(probe);
				if (pilot.isDone())
					break;
				scenes.setInput(source);
				scenes.update(1 / 60);
				source.consume();
			}
		} else
			scenes.update(dt);
		if (scenes.getTop() == null) {
			Services.graphics.beginFrame(width, height, 0x14161cff);
			Services.graphics.endFrame();
		} else
			scenes.draw();
		if (pilot != null && pilot.isDone() && !published) {
			published = true;
			Services.harness.publish({game: {scene: probe("scene"), visited: visited}, autopilot: pilot.getSnapshot()});
			if (Services.getOption("autoclose", "0") == "1")
				Services.quit();
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
		App.visited.push(getName());

	override public function update(dt:Float):Void {
		var input = scenes.getInput();
		if (input.isFramePressed(Key.Enter) || input.isPointerFramePressed())
			scenes.replace(new Play(), new Fade(.6));
		else if (input.isFramePressed(Key.Escape) && Services.canQuit())
			Services.quit();
	}

	override public function draw():Void {
		Draw.screen(camera, 0x1c1e26ff, "HeliX scenes", "Enter or tap: play" + (Services.canQuit() ? "   Escape: quit" : ""));
	}
}

/** The level: its two textures load first, behind the loading scene; then the logo bounces about. Escape pushes the pause menu. */
class Play extends Scene {
	var loader:Null<Loader>;
	var logo:Null<Texture2D>;
	var tiles:Null<Texture2D>;
	var camera = new Camera2D();
	var time = 0.;

	override public function enter():Void {
		App.visited.push(getName());
		loader = new Loader();
		loader.texture("sprites/logo/wg-logo-white-alpha.png", true, result -> switch result {
			case Ready(texture): logo = texture;
			case _:
		});
		loader.texture("textures/tiles.png", false, result -> switch result {
			case Ready(texture): tiles = texture;
			case _:
		});
	}

	override public function getLoader():Null<Loader>
		return loader;

	override public function update(dt:Float):Void {
		time += dt;
		if (scenes.getInput().isFramePressed(Key.Escape))
			scenes.push(new Pause(), new Fade(.3, 0x00000080));
	}

	override public function draw():Void {
		var p = Draw.screen(camera, 0x10281cff, "Playing", "Escape: pause");
		var vx = p.getVisibleX(),
			vy = p.getVisibleY(),
			vw = p.getVisibleWidth(),
			vh = p.getVisibleHeight();
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
		App.visited.push(getName());

	override public function update(dt:Float):Void {
		var input = scenes.getInput();
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
		var p = Services.presentation;
		p.apply(camera);
		var vx = p.getVisibleX(),
			vy = p.getVisibleY(),
			vw = p.getVisibleWidth();
		Services.graphics.beginFrame(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight(), color);
		App.batch.begin(camera);
		var y = vy + 36;
		y += Text2D.drawWrapped(App.batch, title, vx + 12, y, 22, vw - 24, 0xf5f5f5ff) + 4;
		Text2D.drawWrapped(App.batch, help, vx + 12, y, 15, vw - 24, 0xc8c8c8ff);
		App.batch.end();
		return p;
	}
}
