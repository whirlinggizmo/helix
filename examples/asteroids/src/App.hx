import helix.time.Ticker;
import helix.debug.Autopilot;
import helix.asset.Assets;
import helix.debug.TestHarness;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.time.Time;
import helix.input.IInput;
import helix.render2d.Camera2D;
import helix.render2d.Drawing2D;
import helix.render2d.Node2D;
import helix.render2d.Stage;
import helix.render2d.View2D;
import helix.ui.Layout2D;
import helix.ui.Sizing2D;
import helix.ui.Alignment2D;
import helix.ui.Button;
import helix.ui.Ui;
import helix.host.ScreenShape;

/** Asteroids: menus, flight, splitting rocks and waves at a fixed 60 Hz, letterboxed: the field a View2D on the stage, the HUD and the
	menus over it on the stage, both drawn again each frame into Drawing2Ds (Renderer). Options: seed, audio (0 for silence), autopilot (a
	script under assets/), fast (1: up to 120 ticks a frame under autopilot) and autoclose (1: quit once the script is done). */
class App extends helix.App {
	// The field: a drawing in world units, shown letterboxed through camera.
	var field = new Drawing2D();
	var camera = new Camera2D();
	var view:View2D;
	// The presentation's units (the stage's), to place the field's view in.
	var hudCamera = new Camera2D();
	// The score, the lives and the menu's panel, on the stage over the field.
	var hud = new Drawing2D();
	var renderer:Renderer;
	var ticker:Ticker;
	var game:Game;
	var input = new Controls();
	// The menus: helix.ui buttons on the stage over the HUD, asked each frame; a click is a request the next tick takes.
	var ui:Ui;
	var layout:Layout2D;
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

	// The autopilot's script in: the pilot made, and the game prepared once the sounds are in too.
	function startPilot(bytes:haxe.io.Bytes):Void {
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), name -> ui.press(name));
		pilotReady = true;
		prepare();
	}

	override public function init():Void {
		audioEnabled = Host.getOption("audio", "1") == "1";
		fast = Host.getOption("fast", "0") == "1";
		Window.title = "HeliX Asteroids";
		var seed = Std.parseInt(Host.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		Stage.color = Renderer.BACKGROUND;
		var world = new Node2D();
		world.addChild(field);
		view = new View2D(world, camera);
		Stage.addChild(view);
		Stage.addChild(hud);
		renderer = new Renderer(field, hud);
		menus();
		ticker = new Ticker();
		ticker.maxSteps = 6;
		var script = Host.getOption("autopilot", "");
		pilotReady = script == "";
		if (!pilotReady)
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		sounds = new Sounds(error -> {
			if (error != null)
				throw 'Sound load failed: ' + error;
			soundReady = true;
			prepare();
		});
	}

	// The title's Play, and game over's Play again and Title, in the HUD's units, as the renderer's panel has them.
	function menus():Void {
		var theme = new helix.ui.Theme();
		theme.faceColor = 0xff1f293d;
		theme.hoveredColor = 0xff303d57;
		theme.pressedColor = 0xff46587a;
		theme.focusColor = 0xff73d9ff;
		theme.textColor = 0xffd9e6f7;
		theme.textSize = 22;
		theme.widgetHeight = 52;
		theme.gap = 12;
		theme.cornerRadius = 12;
		ui = new Ui(theme);
		play = ui.button("PLAY", "play");
		again = ui.button("PLAY AGAIN", "again");
		toTitle = ui.button("TITLE", "title");
		var column = Layout2D.column();
		column.setSizing(Fixed(300), Fit);
		column.gap = theme.gap;
		column.setAlign(Start, Stretch);
		column.setAnchor(Start, Start, 330, 390);
		for (b in [play, again, toTitle])
			column.add(b.layout);
		layout = Layout2D.stack();
		layout.setSizing(Fixed(Game.W), Fixed(Game.H));
		layout.add(column);
	}

	// The menu for the game's state: its buttons shown, a new screen begun when it changes (keys held into it do nothing).
	function updateMenu():Void {
		var state = game.state == "playing" ? "" : game.state;
		if (state != menuState) {
			menuState = state;
			play.visible = state == "title";
			again.visible = state == "gameover";
			toTitle.visible = state == "gameover";
			ui.reset();
		}
		play.text = ready ? "PLAY" : "LOADING";
		play.enabled = ready;
		Layout2D.arrange(layout, Renderer.getHudX(), Renderer.getHudY(), Game.W, Game.H, ui.font);
		ui.update();
		if (play.clicked || again.clicked)
			wantStart = true;
		if (toTitle.clicked)
			wantTitle = true;
	}

	function prepare():Void {
		if (ready || !soundReady || !pilotReady)
			return;
		if (pilot != null)
			game = new Game(pilot.seed);
		ready = true;
	}

	function inspect():Dynamic
		return {
			ready: ready,
			game: game.snapshot(),
			menu: {focus: ui.focusedName},
			autopilot: pilot == null ? null : pilot.snapshot,
			vertices: Stage.vertexCount,
			draws: Stage.drawCallCount,
			width: Window.framebufferWidth,
			height: Window.framebufferHeight,
			focused: Window.focused
		};

	/** One tick; false once the autopilot is done or the game quit. */
	function step():Bool {
		if (stopped)
			return false;
		if (pilot != null) {
			pilot.advance(name -> game.probe(name));
			if (pilot.done)
				return false;
		}
		input.read();
		// The UI decides the menu while it has the keys (Enter on Title isn't also a start); a click is taken here, by a tick.
		if (ui.capturingKeys)
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
		Input.consume();
		sounds.play(game, audioEnabled, Window.focused);
		return true;
	}

	override public function update(dt:Float):Void {
		if (stopped || Window.framebufferWidth <= 0 || Window.framebufferHeight <= 0)
			return;
		ScreenShape.update();
		Screen.apply(hudCamera);
		// The field's letterbox in framebuffer pixels (Field), the view placed over it in the stage's units; the view sets the same viewport.
		Field.view(camera, Window.framebufferWidth, Window.framebufferHeight);
		var left = hudCamera.screenToWorldX(camera.viewportX),
			top = hudCamera.screenToWorldY(camera.viewportY);
		view.setPosition(left, top);
		view.width = hudCamera.screenToWorldX(camera.viewportX + camera.viewportWidth) - left;
		view.height = hudCamera.screenToWorldY(camera.viewportY + camera.viewportHeight) - top;
		if (ready) {
			if (pilot != null && fast) {
				for (_ in 0...120)
					if (!step())
						break;
			} else if (Window.focused)
				ticker.advance(Time.clock.elapsed, () -> step());
			else
				sounds.play(game, false, false);
		}
		updateMenu();
		renderer.render(game);
		if (pilot != null && pilot.done) {
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
	}
}
