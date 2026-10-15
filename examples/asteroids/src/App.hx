import helix.app.BaseApp;
import helix.app.Ticker;
import helix.debug.Autopilot;
import helix.host.Services;
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
	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
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

	public function new(services:Services) {
		super();
		this.services = services;
		audioEnabled = services.getOption("audio", "1") == "1";
		fast = services.getOption("fast", "0") == "1";
	}

	override public function init():Void {
		services.window.setTitle("HeliX Asteroids");
		var seed = Std.parseInt(services.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		batch = new Batch2D(services.graphics);
		renderer = new Renderer(services.graphics, batch);
		menus();
		ticker = new Ticker(services.input);
		ticker.setMaxSteps(6);
		var script = services.getOption("autopilot", "");
		pilotReady = script == "";
		if (!pilotReady)
			services.assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString(), name -> services.screenshots.take(name), name -> ui.press(name));
					pilotReady = true;
					prepare();
				case Failed(message): throw 'Autopilot load failed: ' + message;
				case Cancelled:
			});
		sounds = new Sounds(services.audioResources, error -> {
			if (error != null)
				throw 'Sound load failed: ' + error;
			soundReady = true;
			prepare();
		});
	}

	// The title's Play, and game over's Play again and Title, in the field's units, as the renderer's panel has them.
	function menus():Void {
		pointer = new Pointer(services.input);
		pointer.addStage2D(hud, camera);
		var theme = new helix.ui.Theme();
		theme.face = 0x1f293dff;
		theme.hovered = 0x303d57ff;
		theme.pressed = 0x46587aff;
		theme.focus = 0x73d9ffff;
		theme.text = 0xd9e6f7ff;
		theme.textSize = 22;
		theme.height = 52;
		theme.gap = 12;
		theme.corner = 12;
		ui = new Ui(hud, camera, pointer, services.input, theme);
		play = ui.button("PLAY", "play");
		again = ui.button("PLAY AGAIN", "again");
		toTitle = ui.button("TITLE", "title");
		var column = Box.column().setSize(Fixed(300), Fit).setGap(theme.gap).setAlign(Start, Stretch);
		for (b in [play, again, toTitle])
			column.add(b.getBox());
		layout = Box.stack().setSize(Fixed(Game.W), Fixed(Game.H)).add(column.setAnchor(Start, Start, 330, 390));
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
		Box.arrange(layout, 0, 0, Game.W, Game.H, batch.getFont());
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
			width: services.window.getFramebufferWidth(),
			height: services.window.getFramebufferHeight(),
			focused: services.window.isFocused()
		};

	/** One tick; false once the autopilot is done or the game quit. */
	function step():Bool {
		if (stopped)
			return false;
		var source:IInput = services.input;
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
		if (input.quit && services.canQuit()) {
			services.quit();
			stopped = true;
			return false;
		}
		game.step(input);
		source.consume();
		sounds.play(game, audioEnabled, services.window.isFocused());
		return true;
	}

	override public function frame(dt:Float):Void {
		if (stopped || services.window.getFramebufferWidth() <= 0 || services.window.getFramebufferHeight() <= 0)
			return;
		Field.view(camera, services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		if (ready) {
			if (pilot != null && fast) {
				for (_ in 0...120)
					if (!step())
						break;
			} else if (services.window.isFocused())
				ticker.advance(services.getFrameElapsed(), () -> step());
			else
				sounds.play(game, false, false);
		}
		updateMenu();
		renderer.render(game, camera, hud);
		if (pilot != null && pilot.isDone()) {
			services.harness.publish(inspect());
			pilot = null;
			if (services.getOption("autoclose", "0") == "1") {
				stopped = true;
				services.quit();
			}
		}
	}

	override public function cleanup():Void {
		sounds.cleanup();
		batch.destroy();
	}
}
