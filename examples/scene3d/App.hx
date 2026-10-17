import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Node;
import helix.render3d.Stage3D;
import helix.scene.Pointer;

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
	var shapes:Array<Node> = [];
	var selected:Array<Node> = [];
	var spinner:Node;
	var button:Node2D;
	var label:Node2D;
	var orbit = true;
	var angle = 0.;
	var spin = 0.;

	override public function init():Void {
		Services.window.setTitle("HeliX scene3d");
		Services.window.requestSize(1000, 600);
		// Framed for 16:9: the whole ring on a phone held upright too.
		camera.setMinAspect(16 / 9);
		stage = new Stage3D(Services.graphics);
		stage.setAmbient(0xffffffff, .25);
		var sun = new Light(Directional);
		sun.setIntensity(2.5);
		var sunNode = Node.light(sun);
		sunNode.lookAt(-.4, -1, -.3);
		stage.add(sunNode);
		var ground = new Material();
		ground.setBaseColor(0x3a3f4aff);
		// The ground isn't something to pick: the pointer passes it (an unpickable node).
		var floor = Node.model(Mesh.plane(16, 16), ground);
		floor.setPickable(false);
		stage.add(floor);
		for (i in 0...8) {
			var a = i / 8 * Math.PI * 2, material = new Material();
			material.setBaseColor(COLORS[i]);
			var cube = Node.model(Mesh.cube(1, 1, 1), material);
			cube.setName('cube ${i + 1}');
			cube.setPosition(4 * Math.cos(a), .5, 4 * Math.sin(a));
			stage.add(cube);
			shapes.push(cube);
		}
		var white = new Material();
		white.setBaseColor(0xe8e8f0ff);
		var sphere = Node.model(Mesh.sphere(1), white);
		sphere.setName("sphere");
		sphere.setPosition(0, 1, 0);
		stage.add(sphere);
		shapes.push(sphere);
		spinner = Node.model(Mesh.cube(.8, .8, .8), white);
		spinner.setName("spinner");
		spinner.setPosition(0, 3, 0);
		stage.add(spinner);
		shapes.push(spinner);
		// The HUD: a button over the world (placed each frame, under the title), and what's selected.
		button = Node2D.rectangle(170, 36, 0x2a3040ff);
		hud.add(button);
		label = Node2D.text("", 16, 0xf5f5f5ff);
		hud.add(label);
		pointer = new Pointer(Services.input);
		pointer.addStage3D(stage, camera);
		pointer.addStage2D(hud, hudCamera);
		batch = new Batch2D(Services.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		// The HUD in the design for the window's shape; the button sits under the title, however many lines it wraps to.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(hudCamera);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		var title = "HeliX scene3d: click shapes to select them";
		var buttonY = vy + 36 + Text2D.measureWrapped(batch.getFont(), title, 20, vw - 24) + 6;
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
			shape.setTint(selected.indexOf(shape) >= 0 ? 0xffffffff : pointer.isHovered(shape) ? 0xc8c8c8ff : 0x8c8c8cff);
		button.setColor(pointer.isDown(button) ? 0x56607aff : pointer.isHovered(button) ? 0x3c4458ff : 0x2a3040ff);
		label.setText(orbit ? "stop the camera" : "start the camera");
		if (orbit)
			angle += dt * .25;
		spin += dt;
		spinner.setRotation(spin * .7, spin, 0);
		fps.update(dt, Services.getFrameCpu());

		Services.graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(hudCamera);
		hud.draw(batch, hudCamera);
		var hovered:Null<Node> = Std.isOfType(pointer.getHovered(), Node) ? cast pointer.getHovered() : null;
		Text2D.drawWrapped(batch, title, vx + 12, vy + 36, 20, vw - 24, 0xf5f5f5ff);
		var y = buttonY + 36 + 10;
		y += Text2D.drawWrapped(batch,
			'under the pointer: ${hovered != null ? hovered.getName() : pointer.isHovered(button) ? "the button" : "nothing"}'
			+ '   selected: ${selected.length == 0 ? "none" : [for (s in selected) s.getName()].join(", ")}'
			+ (pointer.isCaptured() ? "   (the HUD has the pointer)" : ""),
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff)
			+ 4;
		if (Services.canQuit())
			Text2D.draw(batch, "ESC: quit", vx + 12, y, 16, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
