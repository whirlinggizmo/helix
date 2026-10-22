import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.host.ScreenShape;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;

/** The window: its size, place, fullscreen, and monitors. Arrows move it 50 pixels, = and - grow and shrink it by 10%, F toggles fullscreen where the
	window can be, M moves it to the next monitor, H hides it for two seconds (it keeps running), Esc quits where quitting means anything.
	Where programs don't place their windows (the web, a Wayland desktop) moving and changing monitor say "not supported here". The text is a
	Drawing2D on the stage, drawn again each update. */
class App extends helix.App {
	var text = new Drawing2D();
	var status = "press a key";
	var hiddenFor = 0.;

	override public function init():Void {
		Window.title = "HeliX window";
		Window.requestSize(900, 400);
		Stage.color = 0xff181c26;
		Stage.addChild(text);
	}

	function report(what:String, ok:Bool):Void
		status = what + ": " + (ok ? "done" : "not supported here");

	override public function update(dt:Float):Void {
		var input = Input.instance, window = Window.instance, width = window.width, height = window.height, x = window.x, y = window.y;
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
			status = "fullscreen: " + (window.requestFullscreen(!window.fullscreen) ? "asked for" : "not supported here");
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
			report("monitor", window.requestMonitorIndex((window.monitorIndex + 1) % window.monitorCount));
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		text.clear();
		var row = vy + 12;
		row += text.drawTextWrapped("HeliX window   arrows: move   =/-: size   "
			+ (window.canFullscreen() ? "F: fullscreen" : "(no fullscreen here)")
			+ "   M: next monitor   H: hide",
			vx
			+ 12, row, 16, vw
			- 24, 0xfff5f5f5)
			+ 12;
		row += text.drawTextWrapped('window: $width x $height at ($x, $y)   fullscreen: ' + (window.fullscreen ? "yes" : "no") + "   focused: "
			+ (Window.focused ? "yes" : "no"),
			vx + 12, row, 16, vw - 24, 0xffc8c8c8)
			+ 4;
		row += text.drawTextWrapped(status, vx + 12, row, 16, vw - 24, 0xffffcb00) + 12;
		for (m in 0...window.monitorCount) {
			row += text.drawTextWrapped((m == window.monitorIndex ? "> " : "  ")
				+
				'monitor $m "${window.getMonitorName(m)}": ${window.getMonitorWidth(m)} x ${window.getMonitorHeight(m)} at (${window.getMonitorX(m)}, ${window.getMonitorY(m)})',
				vx
				+ 12, row, 16, vw
				- 24, 0xffc8c8c8)
				+ 2;
		}
	}
}
