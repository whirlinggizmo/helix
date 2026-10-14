import helix.app.BaseApp;
import helix.app.Ticker;
import helix.host.Services;
import helix.input.IInput;
import helix.debug.Autopilot;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

class App extends BaseApp {
	var services:Services;
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

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		var seed = Std.parseInt(services.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		services.window.setTitle("HeliX Blocks");
		batch = new Batch2D(services.graphics);
		ticker = new Ticker(services.input);
		ticker.setMaxSteps(6);
		renderer = new Renderer(services.graphics, batch);
		var script = services.getOption("autopilot", "");
		if (script != "")
			services.assets.load(script, result -> switch result {
				case Loaded(bytes):
					pilot = new Autopilot(bytes.toString());
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
			draws: batch.getDrawCount(),
			portrait: layout.portrait,
			zoom: camera.getZoom(),
			width: services.window.getFramebufferWidth(),
			height: services.window.getFramebufferHeight()
		};

	function step():Void {
		var source:IInput = services.input;
		if (pilot != null) {
			source = pilot.advance(game.probe);
			if (pilot.isDone()) {
				services.harness.publish(inspect());
				pilot = null;
				stopped = services.getOption("autoclose", "0") == "1";
				if (stopped)
					services.quit();
				return;
			}
		}
		game.step(controls.read(source, ticks, game, layout, camera));
		source.consume();
		ticks++;
	}

	override public function frame(dt:Float):Void {
		if (stopped || services.window.getFramebufferWidth() <= 0 || services.window.getFramebufferHeight() <= 0)
			return;
		layout.update(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.fit(0, 0, layout.worldWidth, layout.worldHeight);
		if (!services.window.isFocused() && game.state == "playing")
			game.state = "paused";
		ticker.advance(services.getFrameElapsed(), () -> if (!stopped) step());
		renderer.render(game, layout, camera, ticks);
	}

	override public function cleanup():Void {
		batch.destroy();
	}
}
