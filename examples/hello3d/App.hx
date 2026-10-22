import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.ScreenShape;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.render3d.Camera3D;
import helix.render3d.Drawing3D;
import helix.render3d.Node3D;
import helix.render3d.Orbit3D;
import helix.render3d.View3D;
import helix.time.Time;

/** 3D with a 2D overlay: a View3D on the stage, its camera orbiting the origin over a grid and the axes, a solid cube in its wire frame and
	two spheres (a Drawing3D in the tree it shows), depth-tested, then text drawn over them on the stage (a Drawing2D). Escape quits where quitting means
	anything. */
class App extends helix.App {
	var camera3D = new Camera3D();
	var text = new Drawing2D();
	var fps = new FpsOverlay();
	// The camera circles the origin, 16 units out and 9 up, at 0.4 radians a second, starting on the +x side.
	var orbit = new Orbit3D(16, 9, .4, 1, Math.PI / 2);

	override public function init():Void {
		Window.title = "HeliX hello3d";
		Window.requestSize(900, 700);
		Stage.color = 0xff1c1c26;
		// Framed for 16:9: the spheres either side stay in view on a phone held upright too.
		camera3D.minAspect = 16 / 9;
		var level = new Node3D(), drawing = new Drawing3D();
		drawing.grid(20, 1, 0xff505050);
		drawing.line(0, 0, 0, 5, 0, 0, 0xffe62937);
		drawing.line(0, 0, 0, 0, 5, 0, 0xff00e430);
		drawing.line(0, 0, 0, 0, 0, 5, 0xff0079f1);
		drawing.cube(0, 1, 0, 2, 2, 2, 0xff66bfff);
		drawing.cubeWires(0, 1, 0, 2.02, 2.02, 2.02, 0xff0052ac);
		drawing.sphere(5, 1.5, 0, 1.5, 0xffffcb00);
		drawing.sphere(-5, 1.5, 0, 1.5, 0xffbe2137);
		level.addChild(drawing);
		Stage.addChild(new View3D(level, camera3D));
		Stage.addChild(text);
		Stage.addChild(fps);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		fps.update(dt, Time.frameCpu);
		orbit.update(dt);
		orbit.apply(camera3D);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		text.clear();
		var y = vy + 36;
		y += text.drawTextWrapped("HeliX 3D", vx + 12, y, 24, vw - 24, 0xfff5f5f5) + 4;
		text.drawTextWrapped("orbiting Camera3D, depth-tested Drawing3D", vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		fps.setPosition(vx + 12, vy + 10);
	}
}
