import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Environment3D;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.View3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit;

/** Shapes made in code in a View3D's tree: plane, cube, sphere, cylinder, cone, capsule and torus in a row on a floor, each its own color, lit by a
	sun and an ambient light, the camera turning around them. O stops and starts the camera; Escape quits where quitting means anything. The text over them
	is a Drawing2D on the stage, drawn again each update. */
class App extends helix.App {
	var level = new Node3D();
	var camera = new Camera3D();
	var text = new Drawing2D();
	var fps = new FpsOverlay();
	// The camera, circling.
	var orbit = new Orbit(9, 3.5, .2, .4);

	override public function init():Void {
		Window.title = "HeliX meshes";
		Window.requestSize(1000, 600);
		Stage.color = 0xff14161c;
		level.environment = new Environment3D();
		level.environment.setAmbient(0xffffffff, .25);
		// Framed for 16:9: the whole row across on a phone held upright too.
		camera.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 3;
		sun.lookAt(-.5, -1, -.4);
		level.addChild(sun);

		var ground = new Material();
		ground.baseColor = 0xff474a4d;
		ground.roughness = .9;
		level.addChild(new Model(Mesh.plane(12, 12), ground));

		// Each shape, how high its center sits (so it rests on the floor), and its color.
		var shapes:Array<{mesh:Mesh, y:Float, color:Int}> = [
			{mesh: Mesh.plane(1, 1, 4), y: .01, color: 0xffededed},
			{mesh: Mesh.cube(.9, .9, .9), y: .45, color: 0xfff3957c},
			{mesh: Mesh.sphere(.5, 24, 48), y: .5, color: 0xff7cc3f3},
			{mesh: Mesh.cylinder(.45, 1, 40), y: .5, color: 0xff95e79f},
			{mesh: Mesh.cone(.5, 1.1, 40), y: .55, color: 0xfff9e17c},
			{mesh: Mesh.capsule(.35, 1.2, 16, 40), y: .6, color: 0xffdb9fed},
			{mesh: Mesh.torus(.4, .15, 48, 24), y: .15, color: 0xfff3bccb}
		];
		for (i in 0...shapes.length) {
			var material = new Material();
			material.baseColor = shapes[i].color;
			material.roughness = .45;
			var node = new Model(shapes[i].mesh, material);
			node.setPosition((i - (shapes.length - 1) / 2) * 1.4, shapes[i].y, 0);
			level.addChild(node);
		}
		Stage.addChild(new View3D(level, camera));
		Stage.addChild(text);
		Stage.addChild(fps);
	}

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		text.clear();
		var y = vy + 36;
		y += text.drawTextWrapped("HeliX generated meshes: plane, cube, sphere, cylinder, cone, capsule, torus", vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		var keys = (orbit.running ? "O: stop the camera" : "O: turn the camera") + (Host.canQuit() ? "   ESC: quit" : "");
		text.drawTextWrapped(keys, vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		fps.setPosition(vx + 12, vy + 10);
	}
}
