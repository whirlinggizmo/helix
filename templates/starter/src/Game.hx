import helix.graphics.Graphics;
import helix.host.Window;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;

/** The game: init once the services are bound, frame once a display refresh, cleanup as the window closes. What needs a service (a
	Batch2D, a texture) is made in init, not in a field initializer: the object exists before HeliX does. */
class Game extends helix.App {
	var batch:Batch2D;
	var camera = new Camera2D();

	override public function init():Void {
		Window.title = "{title}";
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		// A world unit a logical pixel, from the top left: an unsized camera covers the framebuffer.
		camera.pixels(Window.pixelRatio);
		Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0xff202840);
		batch.begin(camera);
		batch.rect(40, 40, 320, 160, 0xff66bfff);
		batch.drawText("{title}", 60, 90, 48, 0xff102030);
		batch.end();
		Graphics.endFrame();
	}
}
