import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** 2D shapes, text and input: a marker follows the mouse, typing shows what was typed (Backspace takes the last character back),
	and Escape quits where quitting means anything. The frame rate is drawn at the top. */
class App extends BaseApp {
	var services:Services;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var typed = "";

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX hello");
		services.window.requestSize(800, 600);
		batch = new Batch2D(services.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.Backspace) && typed.length > 0)
			typed = typed.substr(0, typed.length - 1);
		if (typed.length + input.getText().length < 64)
			typed += input.getText();
		fps.update(dt, services.getFrameCpu());
		// The drawing in the design for the window's shape, from the visible area's top-left corner.
		ScreenShape.update(services);
		var presentation = services.presentation;
		presentation.apply(camera);
		var x = presentation.getVisibleX(),
			y = presentation.getVisibleY(),
			width = presentation.getVisibleWidth();
		services.graphics.beginFrame(services.window.getFramebufferWidth(), services.window.getFramebufferHeight(), 0xf5f5f5ff);
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
		if (input.getPointerX() >= 0)
			batch.circle(camera.screenToWorldX(input.getPointerX()), camera.screenToWorldY(input.getPointerY()), 8, 0xbe2137ff);
		// text
		Text2D.draw(batch, "HeliX", x + 40, y + 360, 32, 0x505050ff);
		var below = Text2D.drawWrapped(batch, typed != "" ? typed : "type something", x + 40, y + 410, 16, width - 80, typed != "" ? 0x0052acff : 0x828282ff);
		if (services.canQuit())
			Text2D.draw(batch, "press Esc to quit", x + 40, y + 420 + below, 16, 0x828282ff);
		fps.draw(batch, x + 40, y + 12);
		batch.end();
		services.graphics.endFrame();
	}
}
