import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.IHost;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** 2D shapes, text and input: a marker follows the mouse, typing shows what was typed (Backspace takes the last character back),
	and Escape quits where quitting means anything. The frame rate is drawn at the top. */
class App extends BaseApp {
	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var fps = new FpsOverlay();
	var typed = "";

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX hello");
		host.window.setSize(800, 600);
		batch = new Batch2D(host.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		if (input.isFramePressed(Key.Backspace) && typed.length > 0)
			typed = typed.substr(0, typed.length - 1);
		if (typed.length + input.getText().length < 64)
			typed += input.getText();
		fps.update(dt, host.diagnostics.getFrameCpu());
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.pixels(host.getPixelRatio());
		host.graphics.beginFrame(camera.getFramebufferWidth(), camera.getFramebufferHeight(), 0xf5f5f5ff);
		batch.begin(camera);
		// filled and outlined rectangles
		batch.rect(40, 40, 200, 120, 0x66bfffff);
		batch.frame(40, 40, 200, 120, 1, 0x0052acff);
		// a line, a triangle, circles
		batch.line(40, 200, 240, 320, 1, 0xe62937ff);
		batch.triangle(320, 60, 280, 180, 360, 180, 0xffcb00ff);
		batch.circle(440, 120, 60, 0xc87affff);
		batch.circleLines(440, 120, 60, 1, 0x000000ff);
		// a marker that follows the mouse
		if (input.getPointerX() >= 0)
			batch.circle(camera.screenToWorldX(input.getPointerX()), camera.screenToWorldY(input.getPointerY()), 8, 0xbe2137ff);
		// text
		Text2D.draw(batch, "HeliX", 40, 360, 32, 0x505050ff);
		Text2D.draw(batch, typed != "" ? typed : "type something", 40, 410, 16, typed != "" ? 0x0052acff : 0x828282ff);
		if (host.canQuit())
			Text2D.draw(batch, "press Esc to quit", 40, 440, 16, 0x828282ff);
		fps.draw(batch, 40, 12);
		batch.end();
		host.graphics.endFrame();
	}
}
