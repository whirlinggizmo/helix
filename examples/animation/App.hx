import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;
import helix.render3d.Animator;
import helix.render3d.Camera3D;
import helix.render3d.Light;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node;
import helix.render3d.Stage3D;

/** Skinned characters and skeletal animation, from Quaternius's Ultimate Modular Women: a skeleton and its clips from a file of animations
	alone, and an outfit from files of their own (a head, a body, legs and feet, each a skinned mesh), each bound to that skeleton by its joints'
	names. 1 to 8 play a clip, crossfading from the one before over a quarter second (F: cut instead); G swaps the outfit at run time; S puts
	a sword in her right hand, parented to a joint (a socket); Space pauses. O stops the circling camera; Escape quits where quitting means
	anything. */
class App extends BaseApp {
	static inline var DIR = "models/modular-women/";
	static var CLIPS = ["Idle", "Walk", "Run", "Wave", "Sword_Slash", "Punch_Right", "Roll", "Death"];
	static var OUTFITS = [
		["Casual_Body", "Casual_Legs", "Casual_Feet"],
		["Adventurer_Body", "Adventurer_Legs", "Adventurer_Feet"]
	];

	var services:Services;
	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var files = new Map<String, ModelFile>();
	var waiting = 0;
	var character:Null<Node>;
	var animator:Null<Animator>;
	var animations:Null<ModelFile>;
	var outfit = 0;
	var worn:Array<Node> = [];
	var sword:Null<Node>;
	var status = "loading";
	var fade = true;
	var paused = false;
	var orbit = true;
	var angle = 0.;

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX animation");
		services.window.requestSize(1000, 600);
		stage = new Stage3D(services.graphics);
		stage.setAmbient(0xc8d2ffff, .35);
		var sun = new Light(Directional);
		sun.setIntensity(2.5);
		sun.setShadowCasting(true);
		sun.setShadowDistance(8);
		var sunNode = Node.light(sun);
		sunNode.lookAt(-.4, -1, -.6);
		stage.add(sunNode);
		var ground = new Material();
		ground.setBaseColor(0x5a5f6aff);
		ground.setRoughness(.9);
		stage.add(Node.model(Mesh.plane(10, 10), ground));
		var models = new Models(services.assets, services.textures);
		var names = ["Animations", "Casual_Head", "Sword"];
		for (outfit in OUTFITS)
			names = names.concat(outfit);
		for (name in names) {
			waiting++;
			models.load(DIR + name + ".glb", result -> switch result {
				case Ready(file):
					files[name] = file;
					for (warning in file.getWarnings())
						trace('$name: $warning');
					if (--waiting == 0) assemble();
				case Failed(message):
					status = '$name: $message';
				case Cancelled:
			});
		}
		batch = new Batch2D(services.graphics);
	}

	// Everything loaded: the skeleton (the animations file's, which has no meshes), the head and an outfit on it, the sword ready for her hand.
	function assemble():Void {
		animations = files["Animations"];
		character = animations.instantiate("character");
		stage.add(character);
		animator = new Animator(character);
		wear(files["Casual_Head"]);
		dress(0);
		var held = files["Sword"].instantiate();
		sword = held.find("Sword");
		sword.getParent().remove(sword);
		play(0);
	}

	// Binds each skinned model of file's to the character's skeleton by joint name and adds it; one whose joints aren't all there is refused.
	function wear(file:ModelFile):Array<Node> {
		var added = [], copy = file.instantiate();
		for (model in models(copy))
			if (model.bindSkeleton(character)) {
				model.getParent().remove(model);
				character.add(model);
				added.push(model);
			} else
				status = "a part whose joints the skeleton hasn't was refused";
		return added;
	}

	function dress(index:Int):Void {
		for (model in worn)
			character.remove(model);
		worn = [];
		outfit = index;
		for (part in OUTFITS[index])
			worn = worn.concat(wear(files[part]));
	}

	function play(index:Int):Void {
		var clip = animations.getClip(CLIPS[index]);
		if (clip == null)
			status = 'no clip ${CLIPS[index]}';
		else if (!animator.play(clip, CLIPS[index] != "Death", fade ? .25 : 0))
			status = '${clip.getName()} moves nodes the skeleton hasn\'t';
		else
			status = clip.getName();
	}

	static function models(node:Node):Array<Node> {
		var out = node.getKind() == Model && node.getMesh().isSkinned() ? [node] : [];
		for (i in 0...node.getChildCount())
			out = out.concat(models(node.getChild(i)));
		return out;
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		if (services.canQuit() && input.isFramePressed(Key.Escape))
			services.quit();
		if (input.isFramePressed(Key.O))
			orbit = !orbit;
		if (animator != null) {
			for (i in 0...CLIPS.length)
				if (input.isFramePressed(cast((Key.Digit1 : Int) + i)))
					play(i);
			if (input.isFramePressed(Key.F))
				fade = !fade;
			if (input.isFramePressed(Key.Space)) {
				paused = !paused;
				animator.setSpeed(paused ? 0 : 1);
			}
			if (input.isFramePressed(Key.G))
				dress(1 - outfit);
			if (input.isFramePressed(Key.S)) {
				if (sword.getParent() == null)
					character.find("Middle1.R").add(sword);
				else
					sword.getParent().remove(sword);
			}
			animator.update(dt);
		}
		if (orbit)
			angle += dt * .3;
		fps.update(dt, services.getFrameCpu());
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(3 * Math.sin(angle), 1.6, 3 * Math.cos(angle), 0, .9, 0);
		camera2D.setViewport(width, height);
		camera2D.pixels(services.window.getPixelRatio());

		stage.drawShadows(camera);
		services.graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(camera2D);
		Text2D.draw(batch, 'HeliX animation: $status${animator != null && animator.isFading() ? "  (fading)" : ""}', 12, 36, 20, 0xf5f5f5ff);
		Text2D.draw(batch, [for (i in 0...CLIPS.length) '${i + 1} ${CLIPS[i]}'].join("  "), 12, 64, 16, 0xc8c8c8ff);
		Text2D.draw(batch,
			'F: ${fade ? "crossfade" : "cut"}   G: outfit   S: sword   Space: ${paused ? "resume" : "pause"}   O: the camera' +
			(services.canQuit() ? "   ESC: quit" : ""),
			12, 88, 16, 0xc8c8c8ff);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
