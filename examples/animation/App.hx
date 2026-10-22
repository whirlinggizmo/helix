import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.render3d.Animator3D;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Environment3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.ModelFile3D;
import helix.render3d.Models3D;
import helix.render3d.Node3D;
import helix.render3d.View3D;
import helix.time.Time;
import helix.host.ScreenShape;
import helix.render3d.Orbit3D;

/** Skinned characters and skeletal animation, from Quaternius's Ultimate Modular Women: a skeleton and its clips from a file of animations
	alone, and her parts from files of their own (a head, a body, legs and feet, each a skinned mesh), each bound to that skeleton by its joints'
	names (Model3D.bindSkeleton; dressing her slot by slot, and hanging what she holds, is the dressing room's), in a level shown by a View3D,
	her clip's name and the keys on the stage over it. 1 to 8 play a clip, crossfading from
	the one before over a quarter second (F: cut instead); Space pauses. O stops the circling camera; Escape quits where quitting means anything. */
class App extends helix.App {
	static inline var DIR = "models/modular-women/";
	static var CLIPS = ["Idle", "Walk", "Run", "Wave", "Sword_Slash", "Punch_Right", "Roll", "Death"];
	static var PARTS = ["Casual_Head", "Casual_Body", "Casual_Legs", "Casual_Feet"];

	var level = new Node3D();
	var camera = new Camera3D();
	var hud = new Drawing2D();
	var fps = new FpsOverlay();
	var character:Null<Node3D>;
	// Her parts' files as they land, bound to her skeleton once both are in.
	var parts:Array<ModelFile3D> = [];
	var animator:Null<Animator3D>;
	var animations:Null<ModelFile3D>;
	var status = "loading";
	var fade = true;
	var paused = false;
	// The camera, circling.
	var orbit = new Orbit3D(3, 1.6, .3, .9);

	override public function init():Void {
		Window.title = "HeliX animation";
		Window.requestSize(1000, 600);
		camera.minAspect = 16 / 9;
		Stage.color = 0xff1c1e26;
		level.environment = new Environment3D();
		level.environment.setAmbient(0xffc8d2ff, .35);
		var sun = new DirectionalLight3D();
		sun.intensity = 2.5;
		sun.shadowCasting = true;
		sun.shadowDistance = 8;
		sun.lookAt(-.4, -1, -.6);
		level.addChild(sun);
		var ground = new Material3D();
		ground.baseColor = 0xff5a5f6a;
		ground.roughness = .9;
		level.addChild(new Model3D(Mesh3D.plane(10, 10), ground));
		// Her parts, each a skinned mesh in a file of its own: bound to her skeleton once it and they are in, in whatever order.
		for (name in PARTS)
			Models3D.load(DIR + name + ".glb", file -> addPart(file), message -> status = '$name: $message');
		// The skeleton: the animations file's, which has no meshes.
		Models3D.load(DIR + "Animations.glb", file -> place(file), message -> status = 'Animations: $message');
		Stage.addChild(new View3D(level, camera));
		Stage.addChild(hud);
		Stage.addChild(fps);
	}

	// A part's skinned models bound to her skeleton by joint name and moved under her, so they follow her clips.
	// A part's file in: kept, and worn if she's here.
	function addPart(file:ModelFile3D):Void {
		parts.push(file);
		wear(file);
	}

	// The skeleton's file in: her copy of it in the level, animated, wearing the parts already in.
	function place(file:ModelFile3D):Void {
		animations = file;
		character = file.instantiate("character");
		level.addChild(character);
		animator = new Animator3D(character);
		for (file in parts)
			wear(file);
		play(0);
	}

	function wear(file:ModelFile3D):Void {
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

	override public function update(dt:Float):Void {
		var input = Input.instance;
		if (Host.canQuit() && input.isFramePressed(Key.Escape))
			Host.quit();
		if (input.isFramePressed(Key.O))
			orbit.running = !orbit.running;
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
		orbit.update(dt);
		fps.update(dt, Time.frameCpu);
		orbit.apply(camera);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		hud.clear();
		var y = vy + 36, title = 'HeliX animation: $status${animator != null && animator.fading ? "  (fading)" : ""}',
			clips = [for (i in 0...CLIPS.length) '${i + 1} ${CLIPS[i]}'].join("  ");
		y += hud.drawTextWrapped(title, vx + 12, y, 20, vw - 24, 0xfff5f5f5) + 3;
		y += hud.drawTextWrapped(clips, vx + 12, y, 16, vw - 24, 0xffc8c8c8) + 3;
		hud.drawTextWrapped('F: ${fade ? "crossfade" : "cut"}   Space: ${paused ? "resume" : "pause"}   O: the camera'
			+ (Host.canQuit() ? "   ESC: quit" : ""), vx
			+ 12, y,
			16, vw
			- 24, 0xffc8c8c8);
		fps.setPosition(vx + 12, vy + 10);
	}
}
