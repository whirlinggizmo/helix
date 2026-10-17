import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.time.Time;

/** 2D shapes, text and input: a marker follows the mouse, typing shows what was typed (Backspace takes the last character back),
	and Escape quits where quitting means anything. The frame rate is drawn at the top. */
class App extends BaseApp {
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var typed = "";

	override public function init():Void {
		Window.title = "HeliX hello";
		Window.requestSize(800, 600);
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.Backspace) && typed.length > 0)
			typed = typed.substr(0, typed.length - 1);
		if (typed.length + input.text.length < 64)
			typed += input.text;
		fps.update(dt, Time.frameCpu);
		// The drawing in the design for the window's shape, from the visible area's top-left corner.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var x = presentation.visibleX,
			y = presentation.visibleY,
			width = presentation.visibleWidth;
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xf5f5f5ff);
		batch.begin(camera);
		// filled and outlined rectangles
		batch.rect(x + 40, y + 40, 200, 120, 0x66bfffff);
		batch.frame(x + 40, y + 40, 200, 120, 1, 0x0052acff);
		// a line, a triangle, circles
		batch.line(x + 40, y + 200, x + 240, y + 320, 1, 0xe62937ff);
		batch.triangle(x + 320, y + 60, x + 280, y + 180, x + 360, y + 180, 0xffcb00ff);
		batch.circle(x + 440, y + 120, 60, 0xc87affff);
		batch.circleLines(x + 440, y + 120, 60, 1, 0x000000ff);
		// a marker that follows the mouse
		if (input.pointerX >= 0)
			batch.circle(camera.screenToWorldX(input.pointerX), camera.screenToWorldY(input.pointerY), 8, 0xbe2137ff);
		// text
		batch.drawText("HeliX", x + 40, y + 360, 32, 0x505050ff);
		var below = batch.drawTextWrapped(typed != "" ? typed : "type something", x + 40, y + 410, 16, width - 80, typed != "" ? 0x0052acff : 0x828282ff);
		if (Host.canQuit())
			batch.drawText("press Esc to quit", x + 40, y + 420 + below, 16, 0x828282ff);
		fps.draw(batch, x + 40, y + 12);
		batch.end();
		Graphics.endFrame();
	}
}
