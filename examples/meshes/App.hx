import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Shapes made in code on a Stage3D: plane, cube, sphere, cylinder, cone, capsule and torus in a row on a floor, each its own color, lit by a
	sun and an ambient light, the camera turning around them. O stops and starts the camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var orbit = true;
	var angle = 0.;

	override public function init():Void {
		Services.window.setTitle("HeliX meshes");
		Services.window.requestSize(1000, 600);
		stage = new Stage3D(Services.graphics);
		stage.setAmbient(0xffffffff, .25);
		// Framed for 16:9: the whole row across on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var sun = new Light(Directional);
		sun.setIntensity(3);
		var sunNode = Node.light(sun);
		sunNode.lookAt(-.5, -1, -.4);
		stage.add(sunNode);

		var ground = new Material();
		ground.setBaseColor(0x474a4dff);
		ground.setRoughness(.9);
		stage.add(Node.model(Mesh.plane(12, 12), ground));

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
			material.setBaseColor(shapes[i].color);
			material.setRoughness(.45);
			var node = Node.model(shapes[i].mesh, material);
			node.setPosition((i - (shapes.length - 1) / 2) * 1.4, shapes[i].y, 0);
			stage.add(node);
		}
		batch = new Batch2D(Services.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (orbit)
			angle += dt * .2;
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(9 * Math.sin(angle), 3.5, 9 * Math.cos(angle), 0, .4, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera2D);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		Services.graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX generated meshes: plane, cube, sphere, cylinder, cone, capsule, torus", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		Text2D.drawWrapped(batch, (orbit ? "O: stop the camera" : "O: turn the camera")
			+ (Services.canQuit() ? "   ESC: quit" : ""), vx
			+ 12, y, 16, vw
			- 24,
			0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
