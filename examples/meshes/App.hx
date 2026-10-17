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
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Stage3D;
import helix.time.Time;

/** Shapes made in code on a Stage3D: plane, cube, sphere, cylinder, cone, capsule and torus in a row on a floor, each its own color, lit by a
	sun and an ambient light, the camera turning around them. O stops and starts the camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	// The camera, circling.
	var orbit = new Orbit(9, 3.5, .2, .4);

	override public function init():Void {
		Window.title = "HeliX meshes";
		Window.requestSize(1000, 600);
		stage = new Stage3D();
		stage.setAmbient(0xffffffff, .25);
		// Framed for 16:9: the whole row across on a phone held upright too.
		camera.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 3;
		sun.lookAt(-.5, -1, -.4);
		stage.add(sun);

		var ground = new Material();
		ground.baseColor = 0x474a4dff;
		ground.roughness = .9;
		stage.add(new Model(Mesh.plane(12, 12), ground));

		// Each shape, how high its center sits (so it rests on the floor), and its color.
		var shapes:Array<{mesh:Mesh, y:Float, color:Int}> = [
			{mesh: Mesh.plane(1, 1, 4), y: .01, color: 0xedededff},
			{mesh: Mesh.cube(.9, .9, .9), y: .45, color: 0xf3957cff},
			{mesh: Mesh.sphere(.5, 24, 48), y: .5, color: 0x7cc3f3ff},
			{mesh: Mesh.cylinder(.45, 1, 40), y: .5, color: 0x95e79fff},
			{mesh: Mesh.cone(.5, 1.1, 40), y: .55, color: 0xf9e17cff},
			{mesh: Mesh.capsule(.35, 1.2, 16, 40), y: .6, color: 0xdb9fedff},
			{mesh: Mesh.torus(.4, .15, 48, 24), y: .15, color: 0xf3bccbff}
		];
		for (i in 0...shapes.length) {
			var material = new Material();
			material.baseColor = shapes[i].color;
			material.roughness = .45;
			var node = new Model(shapes[i].mesh, material);
			node.setPosition((i - (shapes.length - 1) / 2) * 1.4, shapes[i].y, 0);
			stage.add(node);
		}
		batch = new Batch2D();
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX generated meshes: plane, cube, sphere, cylinder, cone, capsule, torus", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		var keys = (orbit.running ? "O: stop the camera" : "O: turn the camera") + (Host.canQuit() ? "   ESC: quit" : "");
		batch.drawTextWrapped(keys, vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
