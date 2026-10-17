import helix.app.BaseApp;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** The window: its size, place, fullscreen, and monitors. Arrows move it 50 pixels, = and - grow and shrink it by 10%, F toggles fullscreen where the
	window can be, M moves it to the next monitor, H hides it for two seconds (it keeps running), Esc quits where quitting means anything.
	Where programs don't place their windows (the web, a Wayland desktop) moving and changing monitor say "not supported here". */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();
	var status = "press a key";
	var hiddenFor = 0.;

	override public function init():Void {
		Window.setTitle("HeliX window");
		Window.requestSize(900, 400);
		batch = new Batch2D(Graphics.instance);
	}

	function report(what:String, ok:Bool):Void
		status = what + ": " + (ok ? "done" : "not supported here");

	override public function frame(dt:Float):Void {
		var input = Input.instance,
			window = Window.instance,
			width = window.getWidth(),
			height = window.getHeight(),
			x = window.getX(),
			y = window.getY();
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Left))
			report("move", window.requestPosition(x - 50, y));
		if (input.isFramePressed(Key.Right))
			report("move", window.requestPosition(x + 50, y));
		if (input.isFramePressed(Key.Up))
			report("move", window.requestPosition(x, y - 50));
		if (input.isFramePressed(Key.Down))
			report("move", window.requestPosition(x, y + 50));
		if (input.isFramePressed(Key.Equal))
			report("grow", window.requestSize(Std.int(width * 1.1), Std.int(height * 1.1)));
		if (input.isFramePressed(Key.Minus))
			report("shrink", window.requestSize(Std.int(width / 1.1), Std.int(height / 1.1)));
		// A request: fullscreen() answers on a later frame.
		if (input.isFramePressed(Key.F)) {
			status = "fullscreen: " + (window.requestFullscreen(!window.isFullscreen()) ? "asked for" : "not supported here");
		}
		if (input.isFramePressed(Key.H)) {
			window.requestVisible(false);
			hiddenFor = 2;
			report("hide for 2 s", true);
		}
		if (hiddenFor > 0 && (hiddenFor -= dt) <= 0) {
			window.requestVisible(true);
			report("show", true);
		}
		if (input.isFramePressed(Key.M))
			report("monitor", window.requestMonitorIndex((window.getMonitorIndex() + 1) % window.getMonitorCount()));
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		Graphics.beginFrame(window.getFramebufferWidth(), window.getFramebufferHeight(), 0x181c26ff);
		batch.begin(camera);
		var row = vy + 12;
		row += Text2D.drawWrapped(batch,
			"HeliX window   arrows: move   =/-: size   "
			+ (window.canFullscreen() ? "F: fullscreen" : "(no fullscreen here)")
			+ "   M: next monitor   H: hide",
			vx
			+ 12, row, 16, vw
			- 24, 0xf5f5f5ff)
			+ 12;
		row += Text2D.drawWrapped(batch,
			'window: $width x $height at ($x, $y)   fullscreen: '
			+ (window.isFullscreen() ? "yes" : "no")
			+ "   focused: "
			+ (Window.isFocused() ? "yes" : "no"),
			vx
			+ 12, row, 16, vw
			- 24, 0xc8c8c8ff)
			+ 4;
		row += Text2D.drawWrapped(batch, status, vx + 12, row, 16, vw - 24, 0xffcb00ff) + 12;
		for (m in 0...window.getMonitorCount()) {
			row += Text2D.drawWrapped(batch,
				(m == window.getMonitorIndex() ? "> " : "  ")
				+
				'monitor $m "${window.getMonitorName(m)}": ${window.getMonitorWidth(m)} x ${window.getMonitorHeight(m)} at (${window.getMonitorX(m)}, ${window.getMonitorY(m)})',
				vx
				+ 12, row, 16, vw
				- 24, 0xc8c8c8ff)
				+ 2;
		}
		batch.end();
		Graphics.endFrame();
	}
}
