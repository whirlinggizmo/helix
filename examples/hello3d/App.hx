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
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.time.Time;

/** 3D with a 2D overlay: a camera orbiting the origin over a grid and the axes, a solid cube in its wire frame and two spheres, depth-tested, then
	text drawn over them. Escape quits where quitting means anything. */
class App extends BaseApp {
	var batch3D:Batch3D;
	var batch2D:Batch2D;
	var camera3D = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	// The camera circles the origin, 16 units out and 9 up, at 0.4 radians a second, starting on the +x side.
	var orbit = new Orbit(16, 9, .4, 1, Math.PI / 2);

	override public function init():Void {
		Window.title = "HeliX hello3d";
		Window.requestSize(900, 700);
		batch3D = new Batch3D();
		batch2D = new Batch2D();
		// Framed for 16:9: the spheres either side stay in view on a phone held upright too.
		camera3D.minAspect = 16 / 9;
	}

	override public function frame(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		orbit.update(dt);
		camera3D.setViewport(width, height);
		orbit.apply(camera3D);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x1c1c26ff);
		batch3D.begin(camera3D);
		batch3D.grid(20, 1, 0x505050ff);
		batch3D.line(0, 0, 0, 5, 0, 0, 0xe62937ff);
		batch3D.line(0, 0, 0, 0, 5, 0, 0x00e430ff);
		batch3D.line(0, 0, 0, 0, 0, 5, 0x0079f1ff);
		batch3D.cube(0, 1, 0, 2, 2, 2, 0x66bfffff);
		batch3D.cubeWires(0, 1, 0, 2.02, 2.02, 2.02, 0x0052acff);
		batch3D.sphere(5, 1.5, 0, 1.5, 0xffcb00ff);
		batch3D.sphere(-5, 1.5, 0, 1.5, 0xbe2137ff);
		batch3D.end();

		batch2D.begin(camera2D);
		var y = vy + 36;
		y += batch2D.drawTextWrapped("HeliX 3D", vx + 12, y, 24, vw - 24, 0xf5f5f5ff) + 4;
		batch2D.drawTextWrapped("orbiting Camera3D, depth-tested Batch3D", vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		fps.draw(batch2D, vx + 12, vy + 10);
		batch2D.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		batch3D.destroy();
		batch2D.destroy();
	}
}
