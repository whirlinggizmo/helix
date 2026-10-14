import helix.app.BaseApp;
import helix.app.Ticker;
import helix.debug.Autopilot;
import helix.host.Services;
import helix.input.IInput;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

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
	var menu = new Menu();
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
		ticker = new Ticker(services.input);
		ticker.setMaxSteps(6);
		var script = services.getOption("autopilot", "");
		pilotReady = script == "";
		if (!pilotReady)
			services.assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString());
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
			menu: {selected: menu.selected, hovered: menu.hovered},
			autopilot: pilot == null ? null : pilot.getSnapshot(),
			vertices: batch.getVertexCount(),
			draws: batch.getDrawCount(),
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
		menu.update(game, input, source, camera);
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
		renderer.render(game, camera, menu, ready);
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
