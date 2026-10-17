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
import helix.render3d.Animator;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.time.Time;

/** Skinned characters and skeletal animation, from Quaternius's Ultimate Modular Women: a skeleton and its clips from a file of animations
	alone, and her parts from files of their own (a head, a body, legs and feet, each a skinned mesh), each bound to that skeleton by its joints'
	names (Model.bindSkeleton; dressing her slot by slot, and hanging what she holds, is the dressing room's). 1 to 8 play a clip, crossfading from
	the one before over a quarter second (F: cut instead); Space pauses. O stops the circling camera; Escape quits where quitting means anything. */
class App extends BaseApp {
	static inline var DIR = "models/modular-women/";
	static var CLIPS = ["Idle", "Walk", "Run", "Wave", "Sword_Slash", "Punch_Right", "Roll", "Death"];
	static var PARTS = ["Casual_Head", "Casual_Body", "Casual_Legs", "Casual_Feet"];

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var camera2D = new Camera2D();
	var fps = new FpsOverlay();
	var character:Null<Node3D>;
	// Her parts' files as they land, bound to her skeleton once both are in.
	var parts:Array<ModelFile> = [];
	var animator:Null<Animator>;
	var animations:Null<ModelFile>;
	var status = "loading";
	var fade = true;
	var paused = false;
	var orbit = true;
	var angle = 0.;

	override public function init():Void {
		Window.title = "HeliX animation";
		Window.requestSize(1000, 600);
		camera.minAspect = 16 / 9;
		stage = new Stage3D(Graphics.instance);
		stage.setAmbient(0xc8d2ffff, .35);
		var sun = new DirectionalLight();
		sun.intensity = 2.5;
		sun.shadowCasting = true;
		sun.shadowDistance = 8;
		sun.lookAt(-.4, -1, -.6);
		stage.add(sun);
		var ground = new Material();
		ground.baseColor = 0x5a5f6aff;
		ground.roughness = .9;
		stage.add(new Model(Mesh.plane(10, 10), ground));
		// Her parts, each a skinned mesh in a file of its own: bound to her skeleton once it and they are in, in whatever order.
		for (name in PARTS)
			Models.load(DIR + name + ".glb", file -> addPart(file), message -> status = '$name: $message');
		// The skeleton: the animations file's, which has no meshes.
		Models.load(DIR + "Animations.glb", file -> place(file), message -> status = 'Animations: $message');
		batch = new Batch2D(Graphics.instance);
	}

	// A part's skinned models bound to her skeleton by joint name and moved under her, so they follow her clips.
	// A part's file in: kept, and worn if she's here.
	function addPart(file:ModelFile):Void {
		parts.push(file);
		wear(file);
	}

	// The skeleton's file in: her copy of it on the stage, animated, wearing the parts already in.
	function place(file:ModelFile):Void {
		animations = file;
		character = file.instantiate("character");
		stage.add(character);
		animator = new Animator(character);
		for (file in parts)
			wear(file);
		play(0);
	}

	function wear(file:ModelFile):Void {
		if (character == null)
			return;
		var copy = file.instantiate("part"), skinned = [], rigid = [];
		copy.collectModels(skinned, rigid);
		for (model in skinned)
			if (model.bindSkeleton(character)) {
				model.parent = null;
				character.addChild(model);
			} else
				status = '${model.name} names a joint the skeleton hasn\'t';
	}

	function play(index:Int):Void {
		var clip = animations.getClip(CLIPS[index]);
		if (clip == null)
			status = 'no clip ${CLIPS[index]}';
		else if (!animator.play(clip, CLIPS[index] != "Death", fade ? .25 : 0))
			status = '${clip.name} moves nodes the skeleton hasn\'t';
		else
			status = clip.name;
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
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
				animator.speed = paused ? 0 : 1;
			}
			animator.update(dt);
		}
		if (orbit)
			angle += dt * .3;
		fps.update(dt, Time.frameCpu);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		camera.setView(3 * Math.sin(angle), 1.6, 3 * Math.cos(angle), 0, .9, 0);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		stage.drawShadows(camera);
		Graphics.beginFrame(width, height, 0x1c1e26ff);
		stage.draw(camera);
		batch.begin(camera2D);
		var y = vy + 36;
		y += batch.drawTextWrapped('HeliX animation: $status${animator != null && animator.fading ? "  (fading)" : ""}', vx + 12, y, 20, vw - 24, 0xf5f5f5ff)
			+ 3;
		y += batch.drawTextWrapped([for (i in 0...CLIPS.length) '${i + 1} ${CLIPS[i]}'].join("  "), vx + 12, y, 16, vw - 24, 0xc8c8c8ff) + 3;
		batch.drawTextWrapped('F: ${fade ? "crossfade" : "cut"}   Space: ${paused ? "resume" : "pause"}   O: the camera'
			+ (Host.canQuit() ? "   ESC: quit" : ""), vx
			+ 12, y,
			16, vw
			- 24, 0xc8c8c8ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
