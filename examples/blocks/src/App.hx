import helix.app.BaseApp;
import helix.time.Ticker;
import helix.assets.Assets;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.time.Time;
import helix.input.IInput;
import helix.debug.Autopilot;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

class App extends BaseApp {
	var game:Game;
	var controls = new Controls();
	var layout = new Layout();
	var camera = new Camera2D();
	var batch:Batch2D;
	var renderer:Renderer;
	var pilot:Autopilot;
	var ticker:Ticker;
	var ticks = 0;
	var stopped = false;

	override public function init():Void {
		var seed = Std.parseInt(Host.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		Window.title = "HeliX Blocks";
		batch = new Batch2D(Graphics.instance);
		ticker = new Ticker(Input.instance);
		ticker.maxSteps = 6;
		renderer = new Renderer(Graphics.instance, batch);
		var script = Host.getOption("autopilot", "");
		if (script != "")
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
	}

	// The autopilot's script in: the pilot made, and a game of its seed.
	function startPilot(bytes:haxe.io.Bytes):Void {
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name));
		game = new Game(pilot.seed);
	}

	function inspect():Dynamic
		return {
			ready: true,
			game: game.snapshot(),
			ticks: ticks,
			vertices: batch.vertexCount,
			draws: batch.drawCallCount,
			portrait: layout.portrait,
			zoom: camera.zoom,
			width: Window.framebufferWidth,
			height: Window.framebufferHeight
		};

	function step():Void {
		var source:IInput = Input.instance;
		if (pilot != null) {
			source = pilot.advance(name -> game.probe(name));
			if (pilot.done) {
				TestHarness.publish(inspect());
				pilot = null;
				stopped = Host.getOption("autoclose", "0") == "1";
				if (stopped)
					Host.quit();
				return;
			}
		}
		game.step(controls.read(source, ticks, game, layout, camera));
		source.consume();
		ticks++;
	}

	override public function frame(dt:Float):Void {
		if (stopped || Window.framebufferWidth <= 0 || Window.framebufferHeight <= 0)
			return;
		layout.update(Window.framebufferWidth, Window.framebufferHeight);
		camera.setViewport(Window.framebufferWidth, Window.framebufferHeight);
		camera.fit(0, 0, layout.worldWidth, layout.worldHeight);
		if (!Window.focused && game.state == "playing")
			game.state = "paused";
		ticker.advance(Time.clock.elapsed, () -> if (!stopped) step());
		// The well's camera fits the layout; the presentation only sizes its text.
		ScreenShape.update();
		renderer.render(game, layout, camera, Screen.instance, ticks);
	}

	override public function cleanup():Void {
		batch.destroy();
	}
}
