import helix.app.BaseApp;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** The window: its size, place, fullscreen, and monitors. Arrows move it 50 pixels, = and - grow and shrink it by 10%, F toggles fullscreen where the
	window can be, M moves it to the next monitor, H hides it for two seconds (it keeps running), Esc quits where quitting means anything.
	Where programs don't place their windows (the web, a Wayland desktop) moving and changing monitor say "not supported here". */
class App extends BaseApp {
	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
	var status = "press a key";
	var hiddenFor = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX window");
		services.window.setSize(900, 400);
		batch = new Batch2D(services.graphics);
	}

	function report(what:String, ok:Bool):Void
		status = what + ": " + (ok ? "done" : "not supported here");

	override public function frame(dt:Float):Void {
		var input = services.input,
			window = services.window,
			width = window.getWidth(),
			height = window.getHeight(),
			x = window.getX(),
			y = window.getY();
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.Left))
			report("move", window.setPosition(x - 50, y));
		if (input.isFramePressed(Key.Right))
			report("move", window.setPosition(x + 50, y));
		if (input.isFramePressed(Key.Up))
			report("move", window.setPosition(x, y - 50));
		if (input.isFramePressed(Key.Down))
			report("move", window.setPosition(x, y + 50));
		if (input.isFramePressed(Key.Equal))
			report("grow", window.setSize(Std.int(width * 1.1), Std.int(height * 1.1)));
		if (input.isFramePressed(Key.Minus))
			report("shrink", window.setSize(Std.int(width / 1.1), Std.int(height / 1.1)));
		// A request: fullscreen() answers on a later frame.
		if (input.isFramePressed(Key.F)) {
			status = "fullscreen: " + (window.requestFullscreen(!window.isFullscreen()) ? "asked for" : "not supported here");
		}
		if (input.isFramePressed(Key.H)) {
			window.setVisible(false);
			hiddenFor = 2;
			report("hide for 2 s", true);
		}
		if (hiddenFor > 0 && (hiddenFor -= dt) <= 0) {
			window.setVisible(true);
			report("show", true);
		}
		if (input.isFramePressed(Key.M))
			report("monitor", window.setMonitor((window.getMonitor() + 1) % window.getMonitorCount()));
		camera.setViewport(services.window.getFramebufferWidth(), services.window.getFramebufferHeight());
		camera.pixels(services.window.getPixelRatio());
		services.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0x181c26ff);
		batch.begin(camera);
		var row = 12.;
		Text2D.draw(batch,
			"HeliX window   arrows: move   =/-: size   " + (window.canFullscreen() ? "F: fullscreen" : "(no fullscreen here)") + "   M: next monitor   H: hide",
			12, row, 16, 0xf5f5f5ff);
		row += 32;
		Text2D.draw(batch,
			'window: $width x $height at ($x, $y)   fullscreen: '
			+ (window.isFullscreen() ? "yes" : "no")
			+ "   focused: "
			+ (services.window.isFocused() ? "yes" : "no"),
			12, row, 16, 0xc8c8c8ff);
		row += 24;
		Text2D.draw(batch, status, 12, row, 16, 0xffcb00ff);
		row += 32;
		for (m in 0...window.getMonitorCount()) {
			Text2D.draw(batch,
				(m == window.getMonitor() ? "> " : "  ") +
				'monitor $m "${window.getMonitorName(m)}": ${window.getMonitorWidth(m)} x ${window.getMonitorHeight(m)} at (${window.getMonitorX(m)}, ${window.getMonitorY(m)})',
				12, row, 16, 0xc8c8c8ff);
			row += 22;
		}
		batch.end();
		services.graphics.endFrame();
	}
}
