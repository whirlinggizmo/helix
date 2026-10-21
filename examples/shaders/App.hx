import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.graphics.Shader;
import helix.graphics.Shaders;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render3d.AnimationClip;
import helix.render3d.Animator;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.PointLight;
import helix.render3d.Stage3D;
import helix.shaders.Dissolve;
import helix.shaders.HitFlash;
import helix.shaders.Outline;
import helix.shaders.Silhouette;
import helix.shaders.Toon;
import helix.shaders.Unlit;
import helix.shaders.Water;
import helix.time.Time;
import helix.host.ScreenShape;

/** Surface shaders in a lit scene: how to write one of one's own (the floor), beside HeliX's library (helix.shaders, packed into the program:
	nothing to load) where it meets the rest of the stage: shadows cast through a shader's discards and vertex hook, a silhouette through a
	wall on a character of layered parts, a flash on a library shader and on the stage's own shading. Every library shader alone, with its
	parameters, is the shader-gallery example's.
	- left: the Kenney sports car toon shaded (Toon: the lights in flat bands, a rim light), outlined (Outline, an extra pass)
	- middle: a sphere dissolving and coming back (Dissolve: the library's noise laid over it in its own space, discard, a glowing edge), its
		shadow dissolving with it
	- right: a sphere of water in waves (Water: a vertex hook, glints, the sky at grazing angles), its shadow moving with them
	- above the middle: a cube drawn by the library's Unlit
	- in front: a skinned character (Quaternius's Ultimate Modular Women) toon shaded, outlined, and seen through the wall before her
		(Silhouette); she and the wall flash on F (HitFlash, on a library shader and on the stage's own shading)
	- the floor: the example's own shader, shaders/checker.glsl (packed into an .hxshader asset and loaded at run time), lit by the stage
	A sun casting shadows and a point light circling in front light the stage; the shaders read them as the stage's own does. Edit a .glsl
	while the dev server runs and its material reloads in place (a library shader's too, in src/helix/shaders).

	1 / 2: the sun / the point light on and off; 3: the outlines; 4: the silhouette; 5: the dissolve held whole or running; 6: her toon
	shading or the stage's; 7: the water's own shading or the stage's (whose shadow is the sphere's, still); C: the camera close to her or on
	everything; F: a hit flash; T: under the autopilot, its held time half a second on (the waves and their shadow moved); Escape: quit, where
	quitting means anything. Options: autopilot (a script under assets/: the time is then held, the window the autopilot's page's size, so its
	samples of the frame compare across targets) and autoclose (1: quit once the script is done); the probes are ready (everything loaded),
	sun, lamp, outlines, silhouette, dissolving, toon, water, closeUp and time. */
class App extends helix.App {
	static inline var FLOOR_Y = -.5;
	static inline var WOMEN = "models/modular-women/";
	static var PARTS = ["Casual_Head", "Casual_Body", "Casual_Legs", "Casual_Feet"];

	var stage:Stage3D;
	var batch:Batch2D;
	var camera = new Camera3D();
	var hud = new Camera2D();
	var fps = new FpsOverlay();
	var shaders:Shaders;
	var sun:DirectionalLight;
	var lamp:PointLight;
	var marker:Model;
	var floor = new Material();
	var wallMaterial = new Material();
	var dissolve:Dissolve;
	var dissolving = true;
	var sea = new Material();
	var waterOn = true;
	var status = "loading";
	var unlit:Unlit;
	var pilot:Null<Autopilot>;
	var published = false;
	var checkered = false;
	// The car's copy and its outlines.
	var carPlaced = false;
	var outlines:Array<Outline> = [];
	// The character: her skeleton (the animations file's), her parts as they land, her clip, her materials' toon shading and flashes.
	var character:Null<Node3D>;
	var parts:Array<ModelFile> = [];
	var animator:Null<Animator>;
	var idle:Null<AnimationClip>;
	var worn = 0;
	var silhouettes:Array<Silhouette> = [];
	var toons:Array<Toon> = [];
	var flashes:Array<HitFlash> = [];
	var toonOn = true;
	var closeUp = false;

	// The time the autopilot holds the stage at, and its window's size (the autopilot's browser page's), so its samples compare across targets.
	static inline var HELD_TIME = 2.;

	// The time held under the autopilot: HELD_TIME, stepped on by T.
	var heldTime = HELD_TIME;

	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;

	override public function init():Void {
		Window.title = "HeliX shaders";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
			Window.requestSize(1000, 600);
		var gpu = Graphics.instance;
		batch = new Batch2D(gpu);
		stage = new Stage3D(gpu);
		stage.setAmbient(0xffffffff, .15);
		aim();
		// Framed for 16:9: everything on a phone held upright too.
		camera.minAspect = 16 / 9;
		sun = new DirectionalLight();
		sun.color = 0xfff4e4ff;
		sun.intensity = 1.5;
		sun.shadowCasting = true;
		sun.shadowDistance = 12;
		sun.lookAt(-.4, -.8, -.45);
		stage.add(sun);
		lamp = new PointLight();
		lamp.color = 0x78beffff;
		lamp.intensity = 9;
		lamp.range = 8;
		stage.add(lamp);
		var glow = new Material();
		glow.lit = false;
		glow.baseColor = 0x87ceebff;
		marker = new Model(Mesh.sphere(.05), glow);
		marker.shadowCasting = false;
		stage.add(marker);
		// The floor: drawn by the example's own shader once it's loaded (its squares' colors times the material's), the stage's shading until then.
		floor.baseColor = 0x808084ff;
		floor.roughness = .8;
		var plane = new Model(Mesh.plane(8, 6), floor);
		plane.setPosition(0, FLOOR_Y, 0);
		stage.add(plane);
		// Dissolving: both sides drawn, so the inside shows through the holes.
		var dissolving = new Material();
		dissolving.baseColor = 0x8c9bb4ff;
		dissolving.doubleSided = true;
		dissolve = new Dissolve(dissolving);
		// Large holes: the noise's cells a quarter of a unit, four across the sphere.
		dissolve.scale = .5;
		var sphere = new Model(Mesh.sphere(.5, 32, 64), dissolving);
		sphere.setPosition(0, .1, 0);
		stage.add(sphere);
		// Water, finely divided so its waves are smooth.
		new Water(sea);
		var rippling = new Model(Mesh.sphere(.5, 96, 192), sea);
		rippling.setPosition(1.9, .1, 0);
		stage.add(rippling);
		// The library's Unlit: a flat color, no light, and nothing to load.
		var flat = new Material();
		unlit = new Unlit(flat);
		unlit.color = 0xff8a00ff;
		var cube = new Model(Mesh.cube(.3, .3, .3), flat);
		cube.setPosition(0, 1.05, 0);
		cube.setRotation(.5, .7, 0);
		stage.add(cube);
		// A low wall before the character, the stage's own shading: her silhouette shows through it.
		wallMaterial.baseColor = 0x9a7b5cff;
		wallMaterial.roughness = .9;
		var wall = new Model(Mesh.cube(.9, .45, .08), wallMaterial);
		wall.setPosition(-.85, FLOOR_Y + .225, 1.65);
		stage.add(wall);
		flashes.push(new HitFlash(wallMaterial));

		Models.load("models/car-kit/sedan-sports.glb", file -> placeCar(file));
		for (name in PARTS)
			Models.load(WOMEN + name + ".glb", file -> addPart(file), message -> status = '$name: $message');
		Models.load(WOMEN + "Animations.glb", file -> placeCharacter(file), message -> status = 'Animations: $message');
		shaders = new Shaders(Assets.instance, gpu);
		shaders.load("shaders/checker.hxshader", shader -> useChecker(shader), message -> status = message);
	}

	// The autopilot's script in: the input it plays from now on.
	function startPilot(bytes:haxe.io.Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed));

	function probe(name:String):Dynamic
		return switch name {
			case "ready": carPlaced && checkered && character != null && worn == PARTS.length;
			case "sun": sun.visible;
			case "lamp": lamp.visible;
			case "outlines": outlines.length > 0 && outlines[0].enabled;
			case "silhouette": silhouettes.length > 0 && silhouettes[0].enabled;
			case "dissolving": dissolving;
			case "toon": toonOn;
			case "water": waterOn;
			case "closeUp": closeUp;
			case "time": heldTime;
			default: throw 'Unknown probe ' + name;
		}

	// The car's file in: a copy of it on the left, toon shaded and outlined, every model of it.
	function placeCar(file:ModelFile):Void {
		carPlaced = true;
		var node = file.instantiate("car");
		node.setPosition(-1.9, FLOOR_Y, 0);
		node.setRotation(0, .4, 0);
		node.setScale(.75, .75, .75);
		stage.add(node);
		for (material in file.materials)
			new Toon(material);
		var skinned = [], rigid = [];
		node.collectModels(skinned, rigid);
		for (model in rigid)
			outlines.push(new Outline(model, 0x101018ff, .03));
	}

	// The character's skeleton in: her copy of it in front, holding her idle clip's first pose (or playing it), wearing the parts already in.
	function placeCharacter(file:ModelFile):Void {
		var node = file.instantiate("character");
		node.setPosition(-.85, FLOOR_Y, 1.25);
		node.setScale(.55, .55, .55);
		node.setRotation(0, .5, 0);
		stage.add(node);
		character = node;
		animator = new Animator(node);
		idle = file.getClip("Idle");
		if (idle != null)
			animator.play(idle);
		for (part in parts)
			wear(part);
	}

	// A part's file in: kept, and worn if she's here.
	function addPart(file:ModelFile):Void {
		parts.push(file);
		wear(file);
	}

	// A part's skinned models bound to her skeleton by joint name and moved under her; toon shaded, outlined, seen through the wall, flashing.
	function wear(file:ModelFile):Void {
		if (character == null)
			return;
		var copy = file.instantiate("part"), skinned = [], rigid = [];
		copy.collectModels(skinned, rigid);
		for (model in skinned)
			if (model.bindSkeleton(character)) {
				model.parent = null;
				character.addChild(model);
				outlines.push(new Outline(model, 0x101018ff, .012));
				silhouettes.push(new Silhouette(model));
			} else
				status = '${model.name} names a joint the skeleton hasn\'t';
		for (material in file.materials) {
			toons.push(new Toon(material));
			flashes.push(new HitFlash(material));
		}
		worn++;
		if (worn == PARTS.length && status == "loading")
			status = "";
	}

	// The example's own shader in: the floor's, its colors and squares.
	function useChecker(shader:Shader):Void {
		floor.setShader(shader);
		var p = floor.shaderParameters;
		p.setValues("light_color", [1, 1, 1, 1]);
		p.setValues("dark_color", [.55, .55, .6, 1]);
		p.setFloat("cell", .5);
		checkered = true;
	}

	// The camera on the whole stage, or close to the character and the wall before her.
	function aim():Void
		if (closeUp)
			camera.setView(-.45, .35, 3.2, -.85, -.05, 1.3);
		else
			camera.setView(0, 1.4, 5.2, 0, .2, 0);

	// Her materials toon shaded (the library's Toon, on a skinned model: made again, as it was) or the stage's own shading (its rim kept).
	function toonCharacter(on:Bool):Void {
		toonOn = on;
		for (i in 0...toons.length)
			if (on)
				toons[i] = new Toon(toons[i].material);
			else
				toons[i].material.setShader(null);
	}

	override public function frame(dt:Float):Void {
		// The window's input, or the autopilot's: a tick a frame, none while a sample waits for its frame.
		var input:Null<IInput> = Input.instance;
		if (pilot != null) {
			input = pilot.done ? null : pilot.advance(name -> probe(name));
			if (pilot.awaitingFrame)
				input = null;
		}
		if (input != null) {
			if (Host.canQuit() && input.isFramePressed(Key.Escape))
				Host.quit();
			if (input.isFramePressed(Key.Digit1))
				sun.visible = !sun.visible;
			if (input.isFramePressed(Key.Digit2)) {
				lamp.visible = !lamp.visible;
				marker.visible = lamp.visible;
			}
			if (input.isFramePressed(Key.Digit3))
				for (outline in outlines)
					outline.enabled = !outline.enabled;
			if (input.isFramePressed(Key.Digit4))
				for (silhouette in silhouettes)
					silhouette.enabled = !silhouette.enabled;
			if (input.isFramePressed(Key.Digit5))
				dissolving = !dissolving;
			if (input.isFramePressed(Key.Digit6))
				toonCharacter(!toonOn);
			if (input.isFramePressed(Key.Digit7)) {
				waterOn = !waterOn;
				if (waterOn)
					new Water(sea);
				else
					sea.setShader(null);
			}
			if (pilot != null && input.isFramePressed(Key.T))
				heldTime += .5;
			if (input.isFramePressed(Key.C)) {
				closeUp = !closeUp;
				aim();
			}
			if (input.isFramePressed(Key.F))
				for (flash in flashes)
					flash.trigger(0xff3020ff, .25);
		}
		// The game's clock: paused, the motion stops; held under the autopilot, her pose with it.
		var time = pilot != null ? heldTime : Time.clock.time;
		stage.time = time;
		if (animator != null)
			animator.update(pilot != null ? 0 : dt);
		// Half gone at the autopilot's held time.
		dissolve.amount = dissolving ? .5 + .45 * Math.sin((time - HELD_TIME) * .9) : 0;
		fps.update(dt, Time.frameCpu);
		// Circling in front of the models, toward the camera: always in view, and far enough not to wash them out.
		var lx = Math.cos(time * .7) * 2.2,
			ly = .8 + Math.sin(time * .7),
			lz = 1.6 + Math.sin(time * .7) * .4;
		lamp.setPosition(lx, ly, lz);
		marker.setPosition(lx, ly, lz);
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		camera.setViewport(width, height);
		// The text in the design for the window's shape, wrapped to what's visible of it.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hud);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;

		stage.drawShadows(camera);
		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(hud);
		var y = vy + 36;
		y += batch.drawTextWrapped("HeliX shaders: the library's surface shaders and passes, and the example's own (the floor)", vx + 12, y, 20, vw - 24,
			0xf5f5f5ff)
			+ 3;
		var on = (value:Bool) -> value ? "on" : "off";
		y += batch.drawTextWrapped('[1] sun ${on(sun.visible)}  [2] point light ${on(lamp.visible)}  [3] outlines ${on(outlines.length > 0 && outlines[0].enabled)}'
			+
			'  [4] silhouette ${on(silhouettes.length > 0 && silhouettes[0].enabled)}  [5] dissolve ${on(dissolving)}  [6] toon ${on(toonOn)}  [7] water ${on(waterOn)}  [C] close up  [F] flash',
			vx
			+ 12, y, 16, vw
			- 24, 0xc8c8c8ff)
			+ 4;
		if (status != "")
			batch.drawTextWrapped(status, vx + 12, y, 16, vw - 24, 0xff8080ff);
		fps.draw(batch, vx + 12, vy + 10);
		batch.end();
		Graphics.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({
				game: {
					sun: sun.visible,
					lamp: lamp.visible,
					outlines: probe("outlines"),
					silhouette: probe("silhouette"),
					dissolving: dissolving,
					toon: toonOn,
					water: waterOn
				},
				autopilot: pilot.snapshot
			});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		stage.destroy();
		batch.destroy();
	}
}
