import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;

/** 3D with a 2D overlay: a camera orbiting the origin over a grid and the axes, a solid cube in its wire frame and two spheres, depth-tested, then
	text drawn over them. Escape quits where quitting means anything. */
class App extends BaseApp {
	var batch3D:Batch3D;
	var batch2D:Batch2D;
	var camera3D = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();

	override public function init():Void {
		Services.window.setTitle("HeliX hello3d");
		Services.window.requestSize(900, 700);
		batch3D = new Batch3D(Services.graphics);
		batch2D = new Batch2D(Services.graphics);
		// Framed for 16:9: the spheres either side stay in view on a phone held upright too.
		camera3D.setMinAspect(16 / 9);
	}

	override public function frame(dt:Float):Void {
		if (Services.canQuit() && Services.input.isFramePressed(Key.Escape))
			Services.quit();
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		// The camera circles the origin, 16 units out and 9 up, at 0.4 radians a second.
		var angle = Services.getTime() * .4;
		camera3D.setViewport(width, height);
		camera3D.setView(Math.cos(angle) * 16, 9, Math.sin(angle) * 16, 0, 1, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera2D);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		Services.graphics.beginFrame(width, height, 0x1c1c26ff);
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
		y += Text2D.drawWrapped(batch2D, "HeliX 3D", vx + 12, y, 24, vw - 24, 0xf5f5f5ff) + 4;
		Text2D.drawWrapped(batch2D, "orbiting Camera3D, depth-tested Batch3D", vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		fps.draw(batch2D, vx + 12, vy + 10);
		batch2D.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		batch3D.destroy();
		batch2D.destroy();
	}
}
