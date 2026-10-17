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
import helix.render2d.Texture2D;
import helix.render2d.Textures;
import helix.render3d.Animator;
import helix.render3d.Batch3D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.PickHit;
import helix.render3d.Sprite3D;
import helix.render3d.Stage3D;
import helix.render3d.Text3D;
import helix.time.Time;

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
	// The camera, circling.
	var orbit = new Orbit(9, 5, 0, 1, 0, .2, .3);

	override public function init():Void {
		Window.title = "HeliX pick";
		Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .3);
		// Framed for 16:9: everything pickable in view on a phone held upright too.
		camera.minAspect = 16 / 9;
		var sun = new DirectionalLight();
		sun.intensity = 2.5;
		sun.lookAt(-.4, -1, -.5);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0x3a3f4aff;
		var floor = new Model(Mesh.plane(14, 14), ground);
		floor.name = "the ground";
		stage.add(floor);
		var red = new Material(), blue = new Material();
		red.baseColor = 0xd2503cff;
		blue.baseColor = 0x3c78d2ff;
		var cube = new Model(Mesh.cube(1.2, 1.2, 1.2), red);
		cube.name = "a cube";
		cube.setPosition(-3, .6, 1);
		cube.setRotation(0, .6, 0);
		stage.add(cube);
		var sphere = new Model(Mesh.sphere(.8), blue);
		sphere.name = "a sphere";
		sphere.setPosition(-1, .8, -1.5);
		stage.add(sphere);
		var label = new Text3D("PICK ME", .5, 0xf5d25aff);
		label.name = "a text";
		// Text lets picks through unless asked.
		label.pickable = true;
		label.setPosition(1, 2.4, -2);
		stage.add(label);
		Textures.load("sprites/logo/wg-logo-white-alpha.png", true, texture -> placeLogo(texture));
		Models.load("models/car-kit/sedan-sports.glb", file -> placeCar(file));
		// The character: a skeleton and its clips, her outfit bound to it by joint name, walking in place.
		var files = new Map<String, ModelFile>(),
			names = ["Animations", "Casual_Body", "Casual_Head", "Casual_Legs", "Casual_Feet"];
		for (name in names)
			Models.load('models/modular-women/$name.glb', file -> gather(files, name, file, names.length));
		batch = new Batch2D(gpu);
		batch3D = new Batch3D(gpu);
	}

	// The logo's texture in: a sprite of it, pickable.
	function placeLogo(texture:Texture2D):Void {
		var logo = new Sprite3D(texture, 0x7ab4ffff);
		logo.name = "a sprite";
		logo.setSpriteSize(1.4, 1.4);
		logo.setPosition(-3, 2.6, -1);
		stage.add(logo);
	}

	// The car's file in: a copy of it, turned a little.
	function placeCar(file:ModelFile):Void {
		var car = file.instantiate("a car");
		car.setPosition(3, 0, 1);
		car.setRotation(0, -.8, 0);
		stage.add(car);
	}

	// One of the character's files in, kept by name: she's dressed once all count of them are.
	function gather(files:Map<String, ModelFile>, name:String, file:ModelFile, count:Int):Void {
		files[name] = file;
		if (Lambda.count(files) == count)
			dress(files);
	}

	function dress(files:Map<String, ModelFile>):Void {
		var animations = files["Animations"],
			character = animations.instantiate("a character");
		character.setPosition(.8, 0, .8);
		stage.add(character);
		for (part in ["Casual_Body", "Casual_Head", "Casual_Legs", "Casual_Feet"])
			for (model in skinned(files[part].instantiate()))
				if (model.bindSkeleton(character)) {
					model.parent = null;
					model.name = "a character's " + part.split("_")[1].toLowerCase();
					character.addChild(model);
				}
		animator = new Animator(character);
		animator.play(animations.getClip("Walk"));
	}

	static function skinned(node:Node3D):Array<Model> {
		var model = Std.downcast(node, Model);
		var out = model != null && model.mesh.skinned ? [model] : [];
		for (i in 0...node.childCount)
			out = out.concat(skinned(node.getChild(i)));
		return out;
	}

	// The node's name, or its parent's (a file's parts are named for the node holding them).
	static function nameOf(node:Node3D):String {
		var at = node;
		while (at != null && at.name == "")
			at = at.parent;
		return at == null ? "a node" : at.name;
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
		orbit.update(dt);
		if (animator != null)
			animator.update(dt);
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		picked = stage.pick(camera, input.pointerX, input.pointerY, hit);

		Graphics.beginFrame(width, height, 0x1c1e26ff);
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
		y += batch.drawTextWrapped("HeliX pick: move the pointer over anything", vx + 12, y, 20, vw - 24, 0xf5f5f5ff) + 3;
		var line = picked == null ? "nothing under the pointer" : '${nameOf(picked.node)}   ${Math.round(picked.distance * 100) / 100} away   at '
			+ [for (a in 0...3) Math.round(picked.getPoint(a) * 100) / 100].join(", ") + '   facing ' +
				[for (a in 0...3) Math.round(picked.getNormal(a) * 100) / 100].join(", ");
		y += batch.drawTextWrapped(line, vx + 12, y, 16, vw - 24, 0xc8c8c8ff) + 4;
		batch.drawTextWrapped("O: the camera" + (Host.canQuit() ? "   ESC: quit" : ""), vx + 12, y, 16, vw - 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
		batch3D.destroy();
	}
}
