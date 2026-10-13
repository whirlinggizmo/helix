import helix.app.BaseApp;
import helix.app.Ticker;
import helix.host.IHost;
import helix.input.IInput;
import helix.debug.Autopilot;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

class App extends BaseApp {
	var host:IHost;
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

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		var seed = Std.parseInt(host.diagnostics.getOption("seed", "12345"));
		game = new Game(seed == null ? 12345 : seed);
		host.window.setTitle("HeliX Blocks");
		batch = new Batch2D(host.graphics);
		ticker = new Ticker(host.input);
		ticker.setMaxSteps(6);
		renderer = new Renderer(host.graphics, batch);
		host.diagnostics.expose(inspect);
		var script = host.diagnostics.getOption("autopilot", "");
		if (script != "")
			host.assets.load(script, result -> switch result {
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
			width: host.getFramebufferWidth(),
			height: host.getFramebufferHeight()
		};

	function step():Void {
		var source:IInput = host.input;
		if (pilot != null) {
			source = pilot.advance(game.probe);
			if (pilot.isDone()) {
				host.diagnostics.publish(inspect());
				pilot = null;
				stopped = host.diagnostics.getOption("autoclose", "0") == "1";
				if (stopped)
					host.quit();
				return;
			}
		}
		game.step(controls.read(source, ticks, game, layout, camera));
		source.consume();
		ticks++;
	}

	override public function frame(dt:Float):Void {
		if (stopped || host.getFramebufferWidth() <= 0 || host.getFramebufferHeight() <= 0)
			return;
		layout.update(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.fit(0, 0, layout.worldWidth, layout.worldHeight);
		if (!host.isFocused() && game.state == "playing")
			game.state = "paused";
		ticker.advance(host.getFrameElapsed(), () -> if (!stopped) step());
		renderer.render(game, layout, camera, ticks);
	}

	override public function cleanup():Void {
		batch.destroy();
		host.graphics.shutdown();
	}
}
