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
import helix.render2d.Shape2D;
import helix.render2d.Text2D;
import helix.render2d.Stage2D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.scene.Pointer;
import helix.time.Time;

/** A scene under the pointer (the earlier frameworks' scene3d): eight shapes in a ring about a sphere, a cube turning above them, under a
	circling camera. The shape under the pointer lightens; a click selects it or lets it go. A HUD over the world (a Stage2D) has a button that
	stops and starts the camera: pressing it captures the pointer, so the shapes under it see nothing until it's released. Everything is
	asked of a helix.scene.Pointer each frame; nothing is told to the nodes. Escape quits where quitting means anything. */
class App extends BaseApp {
	static var COLORS = [
		0xe0523aff,
		0xe0a33aff,
		0xc8d23aff,
		0x5ad23aff,
		0x3ad2b4ff,
		0x3a8ce0ff,
		0x6a4ae0ff,
		0xd24ab4ff
	];

	var stage:Stage3D;
	var hud = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera3D();
	var hudCamera = new Camera2D();
	var pointer:Pointer;
	var fps = new FpsOverlay();
	var shapes:Array<Model> = [];
	var selected:Array<Model> = [];
	var spinner:Model;
	var button:Shape2D;
	var label:Text2D;
	var orbit = true;
	var angle = 0.;
	var spin = 0.;

	override public function init():Void {
		Window.title = "HeliX scene3d";
		Window.requestSize(1000, 600);
		// Framed for 16:9: the whole ring on a phone held upright too.
		camera.minAspect = 16 / 9;
		stage = new Stage3D(Graphics.instance);
		stage.setAmbient(0xffffffff, .25);
		var sun = new DirectionalLight();
		sun.intensity = 2.5;
		sun.lookAt(-.4, -1, -.3);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0x3a3f4aff;
		// The ground isn't something to pick: the pointer passes it (an unpickable node).
		var floor = new Model(Mesh.plane(16, 16), ground);
		floor.pickable = false;
		stage.add(floor);
		for (i in 0...8) {
			var a = i / 8 * Math.PI * 2, material = new Material();
			material.baseColor = COLORS[i];
			var cube = new Model(Mesh.cube(1, 1, 1), material);
			cube.name = 'cube ${i + 1}';
			cube.setPosition(4 * Math.cos(a), .5, 4 * Math.sin(a));
			stage.add(cube);
			shapes.push(cube);
		}
		var white = new Material();
		white.baseColor = 0xe8e8f0ff;
		var sphere = new Model(Mesh.sphere(1), white);
		sphere.name = "sphere";
		sphere.setPosition(0, 1, 0);
		stage.add(sphere);
		shapes.push(sphere);
		spinner = new Model(Mesh.cube(.8, .8, .8), white);
		spinner.name = "spinner";
		spinner.setPosition(0, 3, 0);
		stage.add(spinner);
		shapes.push(spinner);
		// The HUD: a button over the world (placed each frame, under the title), and what's selected.
		button = Shape2D.rectangle(170, 36, 0x2a3040ff);
		hud.add(button);
		label = new Text2D("", 16, 0xf5f5f5ff);
		hud.add(label);
		pointer = new Pointer(Input.instance);
		pointer.addStage3D(stage, camera);
		pointer.addStage2D(hud, hudCamera);
		batch = new Batch2D(Graphics.instance);
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		// The HUD in the design for the window's shape; the button sits under the title, however many lines it wraps to.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hudCamera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		var title = "HeliX scene3d: click shapes to select them";
		var buttonY = vy + 36 + batch.font.measureWrapped(title, 20, vw - 24) + 6;
		button.setPosition(vx + 12, buttonY);
		label.setPosition(vx + 24, buttonY + 10);
		camera.setView(10 * Math.sin(angle), 6, 10 * Math.cos(angle), 0, 1, 0);
		// Asked once a frame, after input and with the cameras placed: what's under the pointer, pressed and clicked.
		pointer.update();
		if (pointer.isClicked(button))
			orbit = !orbit;
		for (shape in shapes)
			if (pointer.isClicked(shape)) {
				if (selected.indexOf(shape) >= 0)
					selected.remove(shape);
				else
					selected.push(shape);
			}
		for (shape in shapes)
			shape.tint = selected.indexOf(shape) >= 0 ? 0xffffffff : pointer.isHovered(shape) ? 0xc8c8c8ff : 0x8c8c8cff;
		button.color = pointer.isDown(button) ? 0x56607aff : pointer.isHovered(button) ? 0x3c4458ff : 0x2a3040ff;
		label.text = orbit ? "stop the camera" : "start the camera";
		if (orbit)
			angle += dt * .25;
		spin += dt;
		spinner.setRotation(spin * .7, spin, 0);
		fps.update(dt, Time.frameCpu);

		Graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(hudCamera);
		hud.draw(batch, hudCamera);
		var hovered:Null<Node3D> = Std.isOfType(pointer.hovered, Node3D) ? cast pointer.hovered : null;
		batch.drawTextWrapped(title, vx + 12, vy + 36, 20, vw - 24, 0xf5f5f5ff);
		var y = buttonY + 36 + 10;
		y += batch.drawTextWrapped('under the pointer: ${hovered != null ? hovered.name : pointer.isHovered(button) ? "the button" : "nothing"}'
			+ '   selected: ${selected.length == 0 ? "none" : [for (s in selected) s.name].join(", ")}'
			+ (pointer.captured ? "   (the HUD has the pointer)" : ""),
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff)
			+ 4;
		if (Host.canQuit())
			batch.drawText("ESC: quit", vx + 12, y, 16, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
