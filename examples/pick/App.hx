import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Animator;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.PickHit;
import helix.render3d.Stage3D;

/** Every kind a Stage3D picks, under the pointer (the earlier frameworks' pick): a cube, a sphere, a sprite and a text made pickable (their
	quads as drawn), a car from a glTF file (its triangles), and a walking character (her triangles as posed now, not as bound). The hit's
	point is marked, its normal drawn, and its node, distance and point shown. O stops the circling camera; Escape quits where quitting means
	anything. */
class App extends BaseApp {
	var stage:Stage3D;
	var batch:Batch2D;
	var batch3D:Batch3D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var hit = new PickHit();
	var picked:Null<PickHit>;
	var animator:Null<Animator>;
	var orbit = true;
	var angle = .3;

	override public function init():Void {
		Services.window.setTitle("HeliX pick");
		Services.window.requestSize(1000, 600);
		var gpu = Services.graphics;
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		// Framed for 16:9: everything pickable in view on a phone held upright too.
		camera.setMinAspect(16 / 9);
		var sun = new Light(Directional);
		sun.setIntensity(2.5);
		var sunNode = Node.light(sun);
		sunNode.lookAt(-.4, -1, -.5);
		stage.add(sunNode);
		var ground = new Material();
		ground.setBaseColor(0x3a3f4aff);
		var floor = Node.model(Mesh.plane(14, 14), ground);
		floor.setName("the ground");
		stage.add(floor);
		var red = new Material(), blue = new Material();
		red.setBaseColor(0xd2503cff);
		blue.setBaseColor(0x3c78d2ff);
		var cube = Node.model(Mesh.cube(1.2, 1.2, 1.2), red);
		cube.setName("a cube");
		cube.setPosition(-3, .6, 1);
		cube.setRotation(0, .6, 0);
		stage.add(cube);
		var sphere = Node.model(Mesh.sphere(.8), blue);
		sphere.setName("a sphere");
		sphere.setPosition(-1, .8, -1.5);
		stage.add(sphere);
		var label = Node.text3D("PICK ME", .5, 0xf5d25aff);
		label.setName("a text");
		// Text lets picks through unless asked.
		label.setPickable(true);
		label.setPosition(1, 2.4, -2);
		stage.add(label);
		Services.textures.load("sprites/logo/wg-logo-white-alpha.png", true, result -> switch result {
			case Ready(texture):
				var logo = Node.sprite(texture, 0x7ab4ffff);
				logo.setName("a sprite");
				logo.setSpriteSize(1.4, 1.4);
				logo.setPosition(-3, 2.6, -1);
				stage.add(logo);
			case _:
		});
		var models = new Models(Services.assets, Services.textures);
		models.load("models/car-kit/sedan-sports.glb", result -> switch result {
			case Ready(file):
				var car = file.instantiate("a car");
				car.setPosition(3, 0, 1);
				car.setRotation(0, -.8, 0);
				stage.add(car);
			case _:
		});
		// The character: a skeleton and its clips, her outfit bound to it by joint name, walking in place.
		var files = new Map<String, ModelFile>(),
			names = ["Animations", "Casual_Body", "Casual_Head", "Casual_Legs", "Casual_Feet"];
		for (name in names)
			models.load('models/modular-women/$name.glb', result -> switch result {
				case Ready(file):
					files[name] = file;
					if (Lambda.count(files) == names.length) dress(files);
				case _:
			});
		batch = new Batch2D(gpu);
		batch3D = new Batch3D(gpu);
	}

	function dress(files:Map<String, ModelFile>):Void {
		var animations = files["Animations"],
			character = animations.instantiate("a character");
		character.setPosition(.8, 0, .8);
		stage.add(character);
		for (part in ["Casual_Body", "Casual_Head", "Casual_Legs", "Casual_Feet"])
			for (model in skinned(files[part].instantiate()))
				if (model.bindSkeleton(character)) {
					model.getParent().remove(model);
					model.setName("a character's " + part.split("_")[1].toLowerCase());
					character.add(model);
				}
		animator = new Animator(character);
		animator.play(animations.getClip("Walk"));
	}

	static function skinned(node:Node):Array<Node> {
		var out = node.getKind() == Model && node.getMesh().isSkinned() ? [node] : [];
		for (i in 0...node.getChildCount())
			out = out.concat(skinned(node.getChild(i)));
		return out;
	}

	// The node's name, or its parent's (a file's parts are named for the node holding them).
	static function nameOf(node:Node):String {
		var at = node;
		while (at != null && at.getName() == "")
			at = at.getParent();
		return at == null ? "a node" : at.getName();
	}

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (orbit)
			angle += dt * .2;
		if (animator != null)
			animator.update(dt);
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(9 * Math.sin(angle), 5, 9 * Math.cos(angle), 0, 1, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(hud);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();
		picked = stage.pick(camera, input.getPointerX(), input.getPointerY(), hit);

		Services.graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch3D.begin(camera);
		if (picked != null) {
			var x = picked.getPoint(0),
				y = picked.getPoint(1),
				z = picked.getPoint(2);
			batch3D.sphere(x, y, z, .06, 0xffe040ff);
			batch3D.line(x, y, z, x + picked.getNormal(0) * .6, y + picked.getNormal(1) * .6, z + picked.getNormal(2) * .6, 0x40ff80ff);
		}
		batch3D.end();
		batch.begin(hud);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, "HeliX pick: move the pointer over anything", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		var line = picked == null ? "nothing under the pointer" : '${nameOf(picked.getNode())}   ${Math.round(picked.getDistance() * 100) / 100} away   at '
			+ [for (a in 0...3) Math.round(picked.getPoint(a) * 100) / 100].join(", ") + '   facing ' +
				[for (a in 0...3) Math.round(picked.getNormal(a) * 100) / 100].join(", ");
		y += Text2D.drawWrapped(batch, line, vx + 12, y, 16, vw - 24, 0xc8c8c8ff) + 4;
		Text2D.drawWrapped(batch, "O: the camera" + (Services.canQuit() ? "   ESC: quit" : ""), vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
		batch3D.destroy();
	}
}
