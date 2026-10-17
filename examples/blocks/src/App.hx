import helix.app.BaseApp;
import helix.app.Ticker;
import helix.host.Services;
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
		var seed = Std.parseInt(Services.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		Services.window.setTitle("HeliX Blocks");
		batch = new Batch2D(Services.graphics);
		ticker = new Ticker(Services.input);
		ticker.setMaxSteps(6);
		renderer = new Renderer(Services.graphics, batch);
		var script = Services.getOption("autopilot", "");
		if (script != "")
			Services.assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString(), name -> Services.screenshots.take(name));
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
			width: Services.window.getFramebufferWidth(),
			height: Services.window.getFramebufferHeight()
		};

	function step():Void {
		var source:IInput = Services.input;
		if (pilot != null) {
			source = pilot.advance(game.probe);
			if (pilot.isDone()) {
				Services.harness.publish(inspect());
				pilot = null;
				stopped = Services.getOption("autoclose", "0") == "1";
				if (stopped)
					Services.quit();
				return;
			}
		}
		game.step(controls.read(source, ticks, game, layout, camera));
		source.consume();
		ticks++;
	}

	override public function frame(dt:Float):Void {
		if (stopped || Services.window.getFramebufferWidth() <= 0 || Services.window.getFramebufferHeight() <= 0)
			return;
		layout.update(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight());
		camera.setViewport(Services.window.getFramebufferWidth(), Services.window.getFramebufferHeight());
		camera.fit(0, 0, layout.worldWidth, layout.worldHeight);
		if (!Services.window.isFocused() && game.state == "playing")
			game.state = "paused";
		ticker.advance(Services.getFrameElapsed(), () -> if (!stopped) step());
		// The well's camera fits the layout; the presentation only sizes its text.
		ScreenShape.update();
		renderer.render(game, layout, camera, Services.presentation, ticks);
	}

	override public function cleanup():Void {
		batch.destroy();
	}
}
