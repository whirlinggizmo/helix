import helix.app.BaseApp;
import helix.time.Ticker;
import helix.debug.Autopilot;
import helix.assets.Assets;
import helix.audio.Audio;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.time.Time;
import helix.input.IInput;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.scene.Pointer;
import helix.ui.Box;
import helix.ui.Button;
import helix.ui.Ui;

/** Asteroids: menus, flight, splitting rocks and waves at a fixed 60 Hz, letterboxed. Options: seed, audio (0 for silence), autopilot (a
	script under assets/), fast (1: up to 120 ticks a frame under autopilot) and autoclose (1: quit once the script is done). */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();
	// The score, the lives and the menus, in the presentation's units.
	var hudCamera = new Camera2D();
	var renderer:Renderer;
	var ticker:Ticker;
	var game:Game;
	var input = new Controls();
	// The menus: helix.ui buttons over the field, asked each frame; a click is a request the next tick takes.
	var hud = new Stage2D();
	var pointer:Pointer;
	var ui:Ui;
	var layout:Box;
	var play:Button;
	var again:Button;
	var toTitle:Button;
	var menuState = "";
	var wantStart = false;
	var wantTitle = false;
	var sounds:Sounds;
	var pilot:Autopilot;
	var audioEnabled:Bool;
	var fast:Bool;
	var stopped = false;
	var ready = false;
	var soundReady = false;
	var pilotReady = true;

	public function new() {
		super();
		audioEnabled = Host.getOption("audio", "1") == "1";
		fast = Host.getOption("fast", "0") == "1";
	}

	override public function init():Void {
		Window.setTitle("HeliX Asteroids");
		var seed = Std.parseInt(Host.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		batch = new Batch2D(Graphics.instance);
		renderer = new Renderer(Graphics.instance, batch);
		menus();
		ticker = new Ticker(Input.instance);
		ticker.setMaxSteps(6);
		var script = Host.getOption("autopilot", "");
		pilotReady = script == "";
		if (!pilotReady)
			Assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), name -> ui.press(name));
					pilotReady = true;
					prepare();
				case Failed(message): throw 'Autopilot load failed: ' + message;
				case Cancelled:
			});
		sounds = new Sounds(Audio.instance, error -> {
			if (error != null)
				throw 'Sound load failed: ' + error;
			soundReady = true;
			prepare();
		});
	}

	// The title's Play, and game over's Play again and Title, in the HUD's units, as the renderer's panel has them.
	function menus():Void {
		pointer = new Pointer(Input.instance);
		pointer.addStage2D(hud, hudCamera);
		var theme = new helix.ui.Theme();
		theme.setFaceColor(0x1f293dff);
		theme.setHoveredColor(0x303d57ff);
		theme.setPressedColor(0x46587aff);
		theme.setFocusColor(0x73d9ffff);
		theme.setTextColor(0xd9e6f7ff);
		theme.setTextSize(22);
		theme.setWidgetHeight(52);
		theme.setGap(12);
		theme.setCornerRadius(12);
		ui = new Ui(hud, hudCamera, pointer, Input.instance, theme);
		play = ui.button("PLAY", "play");
		again = ui.button("PLAY AGAIN", "again");
		toTitle = ui.button("TITLE", "title");
		var column = Box.column();
		column.setSizing(Fixed(300), Fit);
		column.setGap(theme.getGap());
		column.setAlign(Start, Stretch);
		column.setAnchor(Start, Start, 330, 390);
		for (b in [play, again, toTitle])
			column.add(b.getBox());
		layout = Box.stack();
		layout.setSizing(Fixed(Game.W), Fixed(Game.H));
		layout.add(column);
	}

	// The menu for the game's state: its buttons shown, a new screen begun when it changes (keys held into it do nothing).
	function updateMenu():Void {
		var state = game.state == "playing" ? "" : game.state;
		if (state != menuState) {
			menuState = state;
			play.setVisible(state == "title");
			again.setVisible(state == "gameover");
			toTitle.setVisible(state == "gameover");
			ui.reset();
		}
		play.setText(ready ? "PLAY" : "LOADING");
		play.setEnabled(ready);
		Box.arrange(layout, Renderer.getHudX(Screen.instance), Renderer.getHudY(Screen.instance), Game.W, Game.H, batch.getFont());
		pointer.update();
		ui.update();
		if (play.isClicked() || again.isClicked())
			wantStart = true;
		if (toTitle.isClicked())
			wantTitle = true;
	}

	function prepare():Void {
		if (ready || !soundReady || !pilotReady)
			return;
		if (pilot != null)
			game = new Game(pilot.getSeed());
		ready = true;
	}

	function inspect():Dynamic
		return {
			ready: ready,
			game: game.snapshot(),
			menu: {focus: ui.getFocusedName()},
			autopilot: pilot == null ? null : pilot.getSnapshot(),
			vertices: batch.getVertexCount(),
			draws: batch.getDrawCallCount(),
			width: Window.getFramebufferWidth(),
			height: Window.getFramebufferHeight(),
			focused: Window.isFocused()
		};

	/** One tick; false once the autopilot is done or the game quit. */
	function step():Bool {
		if (stopped)
			return false;
		var source:IInput = Input.instance;
		if (pilot != null) {
			source = pilot.advance(game.probe);
			if (pilot.isDone())
				return false;
		}
		input.read(source);
		// The UI decides the menu while it has the keys (Enter on Title isn't also a start); a click is taken here, by a tick.
		if (ui.isCapturingKeys())
			input.start = false;
		input.start = input.start || wantStart;
		input.title = wantTitle;
		wantStart = wantTitle = false;
		if (input.quit && Host.canQuit()) {
			Host.quit();
			stopped = true;
			return false;
		}
		game.step(input);
		source.consume();
		sounds.play(game, audioEnabled, Window.isFocused());
		return true;
	}

	override public function frame(dt:Float):Void {
		if (stopped || Window.getFramebufferWidth() <= 0 || Window.getFramebufferHeight() <= 0)
			return;
		Field.view(camera, Window.getFramebufferWidth(), Window.getFramebufferHeight());
		ScreenShape.update();
		Screen.apply(hudCamera);
		if (ready) {
			if (pilot != null && fast) {
				for (_ in 0...120)
					if (!step())
						break;
			} else if (Window.isFocused())
				ticker.advance(Time.clock.getElapsed(), () -> step());
			else
				sounds.play(game, false, false);
		}
		updateMenu();
		renderer.render(game, camera, hudCamera, Screen.instance, hud);
		if (pilot != null && pilot.isDone()) {
			TestHarness.publish(inspect());
			pilot = null;
			if (Host.getOption("autoclose", "0") == "1") {
				stopped = true;
				Host.quit();
			}
		}
	}

	override public function cleanup():Void {
		sounds.cleanup();
		batch.destroy();
	}
}
