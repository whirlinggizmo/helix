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
		Window.setTitle("HeliX Blocks");
		batch = new Batch2D(Graphics.instance);
		ticker = new Ticker(Input.instance);
		ticker.setMaxSteps(6);
		renderer = new Renderer(Graphics.instance, batch);
		var script = Host.getOption("autopilot", "");
		if (script != "")
			Assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name));
					game = new Game(pilot.getSeed());
				case Failed(message): throw 'Autopilot load failed: ' + message;
				case Cancelled:
			});
	}

	function inspect():Dynamic
		return {
			ready: true,
			game: game.snapshot(),
			ticks: ticks,
			vertices: batch.getVertexCount(),
			draws: batch.getDrawCallCount(),
			portrait: layout.portrait,
			zoom: camera.getZoom(),
			width: Window.getFramebufferWidth(),
			height: Window.getFramebufferHeight()
		};

	function step():Void {
		var source:IInput = Input.instance;
		if (pilot != null) {
			source = pilot.advance(game.probe);
			if (pilot.isDone()) {
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
		if (stopped || Window.getFramebufferWidth() <= 0 || Window.getFramebufferHeight() <= 0)
			return;
		layout.update(Window.getFramebufferWidth(), Window.getFramebufferHeight());
		camera.setViewport(Window.getFramebufferWidth(), Window.getFramebufferHeight());
		camera.fit(0, 0, layout.worldWidth, layout.worldHeight);
		if (!Window.isFocused() && game.state == "playing")
			game.state = "paused";
		ticker.advance(Time.clock.getElapsed(), () -> if (!stopped) step());
		// The well's camera fits the layout; the presentation only sizes its text.
		ScreenShape.update();
		renderer.render(game, layout, camera, Screen.instance, ticks);
	}

	override public function cleanup():Void {
		batch.destroy();
	}
}
