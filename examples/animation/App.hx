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
import helix.render3d.Outfit;
import helix.render3d.Stage3D;
import helix.render3d.Wardrobe;

/** Skinned characters and skeletal animation, from Quaternius's Ultimate Modular Women: a skeleton and its clips from a file of animations
	alone, and an outfit from files of their own (a head, a body, legs and feet, each a skinned mesh), each bound to that skeleton by its joints'
	names (an Outfit: the dressing-room example dresses her slot by slot). 1 to 8 play a clip, crossfading from the one before over a quarter
	second (F: cut instead); G swaps the outfit at run time; S puts a sword in her right hand, hung from the joint its file hangs it from (a
	socket); Space pauses. O stops the circling camera; Escape quits where quitting means
	anything. */
class App extends BaseApp {
	static inline var DIR = "models/modular-women/";
	static var CLIPS = ["Idle", "Walk", "Run", "Wave", "Sword_Slash", "Punch_Right", "Roll", "Death"];
	static var OUTFITS = [
		["Casual_Body", "Casual_Legs", "Casual_Feet"],
		["Adventurer_Body", "Adventurer_Legs", "Adventurer_Feet"]
	];

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var character:Null<Node>;
	var outfit:Outfit;
	var animator:Null<Animator>;
	var animations:Null<ModelFile>;
	var look = 0;
	var status = "loading";
	var fade = true;
	var paused = false;
	var orbit = true;
	var angle = 0.;

	override public function init():Void {
		Services.window.setTitle("HeliX animation");
		Services.window.requestSize(1000, 600);
		camera.setMinAspect(16 / 9);
		stage = new Stage3D(Services.graphics);
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
		var models = new Models(Services.assets, Services.textures);
		// Her head and outfit chosen now, worn once her skeleton and their files are in.
		outfit = new Outfit(new Wardrobe(models.load));
		outfit.choose("head", DIR + "Casual_Head.glb");
		dress(0);
		// The skeleton: the animations file's, which has no meshes.
		models.load(DIR + "Animations.glb", result -> switch result {
			case Ready(file):
				animations = file;
				character = file.instantiate("character");
				stage.add(character);
				animator = new Animator(character);
				outfit.setSkeleton(character);
				play(0);
			case Failed(message):
				status = 'Animations: $message';
			case Cancelled:
		});
		batch = new Batch2D(Services.graphics);
	}

	// Body, legs and feet from OUTFITS[index].
	function dress(index:Int):Void {
		look = index;
		for (i in 0...3)
			outfit.choose(["body", "legs", "feet"][i], DIR + OUTFITS[index][i] + ".glb");
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

	override public function frame(dt:Float):Void {
		var input = Services.input;
		if (Services.canQuit() && input.isFramePressed(Key.Escape))
			Services.quit();
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
				dress(1 - look);
			if (input.isFramePressed(Key.S))
				outfit.choose("hand", outfit.getChoice("hand") == null ? DIR + "Sword.glb" : null);
			animator.update(dt);
		}
		if (orbit)
			angle += dt * .3;
		fps.update(dt, Services.getFrameCpu());
		var width = Services.window.getFramebufferWidth(),
			height = Services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		camera.setView(3 * Math.sin(angle), 1.6, 3 * Math.cos(angle), 0, .9, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Services.presentation;
		presentation.apply(camera2D);
		var vx = presentation.getVisibleX(),
			vy = presentation.getVisibleY(),
			vw = presentation.getVisibleWidth();

		stage.drawShadows(camera);
		Services.graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += Text2D.drawWrapped(batch, 'HeliX animation: $status${animator != null && animator.isFading() ? "  (fading)" : ""}', vx + 12, y, 20, vw - 24,
			0xf5f5f5ff)
			+ 3;
		y += Text2D.drawWrapped(batch, [for (i in 0...CLIPS.length) '${i + 1} ${CLIPS[i]}'].join("  "), vx + 12, y, 16, vw - 24, 0xc8c8c8ff) + 3;
		Text2D.drawWrapped(batch,
			'F: ${fade ? "crossfade" : "cut"}   G: outfit   S: sword   Space: ${paused ? "resume" : "pause"}   O: the camera'
			+ (Services.canQuit() ? "   ESC: quit" : ""),
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Services.graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
