import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Shape2D;
import helix.render2d.Stage;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.View3D;
import helix.scene.Pointer;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit3D;

/** A scene under the pointer (the earlier frameworks' scene3d): eight shapes in a ring about a sphere, a cube turning above them, under a
	circling camera, shown by a View3D on the stage. The shape under the pointer lightens; a click selects it or lets it go. A HUD over the
	world (nodes on the stage after the view) has a button that stops and starts the camera: pressing it captures the pointer, so the shapes
	under it see nothing until it's released. Everything is asked of a helix.scene.Pointer each frame, which reads the stage (2D first, then
	the 3D view); nothing is told to the nodes. Escape quits where quitting means anything. */
class App extends helix.App {
	static var COLORS = [
		0xffe0523a,
		0xffe0a33a,
		0xffc8d23a,
		0xff5ad23a,
		0xff3ad2b4,
		0xff3a8ce0,
		0xff6a4ae0,
		0xffd24ab4
	];

	var level = new Node3D();
	var view:View3D;
	var camera = new Camera3D();
	var pointer:Pointer;
	var fps = new FpsOverlay();
	var hud = new Drawing2D();
	var shapes:Array<Model3D> = [];
	var selected:Array<Model3D> = [];
	var spinner:Model3D;
	var button:Shape2D;
	var label:Text2D;
	// The camera, circling.
	var orbit = new Orbit3D(10, 6, .25, 1);
	var spin = 0.;

	override public function init():Void {
		Window.title = "HeliX scene3d";
		Window.requestSize(1000, 600);
		Stage.color = 0xff1c1e26;
		// Framed for 16:9: the whole ring on a phone held upright too.
		camera.minAspect = 16 / 9;
		level.environment = new Environment3D();
		level.environment.setAmbient(0xffffffff, .25);
		var sun = new DirectionalLight3D();
		sun.intensity = 2.5;
		sun.lookAt(-.4, -1, -.3);
		level.addChild(sun);
		var ground = new Material3D();
		ground.baseColor = 0xff3a3f4a;
		// The ground isn't something to pick: the pointer passes it (an unpickable node).
		var floor = new Model3D(Mesh3D.plane(16, 16), ground);
		floor.pickable = false;
		level.addChild(floor);
		for (i in 0...8) {
			var a = i / 8 * Math.PI * 2, material = new Material3D();
			material.baseColor = COLORS[i];
			var cube = new Model3D(Mesh3D.cube(1, 1, 1), material);
			cube.name = 'cube ${i + 1}';
			cube.setPosition(4 * Math.cos(a), .5, 4 * Math.sin(a));
			level.addChild(cube);
			shapes.push(cube);
		}
		var white = new Material3D();
		white.baseColor = 0xffe8e8f0;
		var sphere = new Model3D(Mesh3D.sphere(1), white);
		sphere.name = "sphere";
		sphere.setPosition(0, 1, 0);
		level.addChild(sphere);
		shapes.push(sphere);
		spinner = new Model3D(Mesh3D.cube(.8, .8, .8), white);
		spinner.name = "spinner";
		spinner.setPosition(0, 3, 0);
		level.addChild(spinner);
		shapes.push(spinner);
		view = new View3D(level, camera);
		Stage.addChild(view);
		// The HUD over the world: a button (placed each frame, under the title), what's selected, and the text, which lets the pointer through.
		button = Shape2D.rectangle(170, 36, 0xff2a3040);
		Stage.addChild(button);
		label = new Text2D("", 16, 0xfff5f5f5);
		Stage.addChild(label);
		hud.pickable = false;
		Stage.addChild(hud);
		Stage.addChild(fps);
		pointer = new Pointer();
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		// The HUD in the design for the window's shape; the button sits under the title, however many lines it wraps to.
		ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;
		var title = "HeliX scene3d: click shapes to select them";
		var buttonY = vy + 36 + Stage.font.measureWrapped(title, 20, vw - 24) + 6;
		button.setPosition(vx + 12, buttonY);
		label.setPosition(vx + 24, buttonY + 10);
		orbit.apply(camera);
		// Asked once a frame, after input and with the camera placed: what's under the pointer, pressed and clicked.
		pointer.update();
		if (pointer.isClicked(button))
			orbit.running = !orbit.running;
		for (shape in shapes)
			if (pointer.isClicked(shape)) {
				if (selected.indexOf(shape) >= 0)
					selected.remove(shape);
				else
					selected.push(shape);
			}
		for (shape in shapes)
			shape.tint = selected.indexOf(shape) >= 0 ? 0xffffffff : pointer.isHovered(shape) ? 0xffc8c8c8 : 0xff8c8c8c;
		button.color = pointer.isDown(button) ? 0xff56607a : pointer.isHovered(button) ? 0xff3c4458 : 0xff2a3040;
		label.text = orbit.running ? "stop the camera" : "start the camera";
		orbit.update(dt);
		spin += dt;
		spinner.setRotation(spin * .7, spin, 0);
		fps.update(dt, Time.frameCpu);
		fps.setPosition(vx + 12, vy + 10);

		hud.clear();
		var hovered:Null<Node3D> = Std.isOfType(pointer.hovered, Node3D) ? cast pointer.hovered : null;
		hud.drawTextWrapped(title, vx + 12, vy + 36, 20, vw - 24, 0xfff5f5f5);
		var y = buttonY + 36 + 10;
		var status = 'under the pointer: ${hovered != null ? hovered.name : pointer.isHovered(button) ? "the button" : "nothing"}'
			+ '   selected: ${selected.length == 0 ? "none" : [for (s in selected) s.name].join(", ")}'
			+ (pointer.captured ? "   (the HUD has the pointer)" : "");
		y += hud.drawTextWrapped(status, vx + 12, y, 16, vw - 24, 0xffc8c8c8) + 4;
		if (Host.canQuit())
			hud.drawText("ESC: quit", vx + 12, y, 16, 0xffc8c8c8);
	}

	override public function cleanup():Void
		view.destroy();
}
