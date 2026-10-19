import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.math.Interpolate;
import helix.math.Random;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.render2d.Texture2D;
import helix.render3d.Animator;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight;
import helix.render3d.Environment;
import helix.render3d.Environments;
import helix.render3d.Material;
import helix.render3d.Mesh;
import helix.render3d.Model;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Node3D;
import helix.render3d.Stage3D;
import helix.scene.Pointer;
import helix.time.Time;
import helix.ui.Box;
import helix.ui.Button;
import helix.ui.Label;
import helix.ui.Panel;
import helix.ui.Tile;
import helix.ui.Ui;

/** A character creator's dressing room: a character on a turntable in a studio's light, dressed slot by slot (head, body, legs, feet, and
	what she holds) from Quaternius's Ultimate Modular Women, ten outfits whose parts mix freely. Each slot's parts are tiles, their pictures
	rendered from the parts themselves (render targets) as their files load; a slot's files load only when its tab is opened, through the
	Models the program shares (here the one on the stage and the one the pictures are taken of), and an Outfit (this example's, over the
	framework's binding and attachment queries) wears each choice on
	the skeleton by joint name, a held part at a joint. Drag to turn her, the wheel to come closer; the camera frames the slot being dressed.
	Poses play her animations; Random and Reset dress her at once. Pointer, keys (arrows, Tab, Enter; Q and E change slot) or a pad. */
class App extends BaseApp {
	static inline var DIR = "models/modular-women/";
	static var LOOKS = [
		"Casual",
		"Adventurer",
		"Formal",
		"Medieval",
		"Punk",
		"SciFi",
		"Soldier",
		"Suit",
		"Witch",
		"Worker"
	];
	static var SLOTS = ["Head", "Body", "Legs", "Feet", "Hand"];
	static var HELD = ["Sword", "Gun"];
	static var POSES = ["Idle", "Wave", "Sword_Slash", "Punch_Right", "Run", "Roll"];
	static var POSE_NAMES = ["Idle", "Wave", "Slash", "Punch", "Run", "Roll"];
	static inline var THUMB = 128;
	// Where the room's camera frames each slot: the height looked at, and how far away.
	static var FOCUS = ["Head" => 1.6, "Body" => 1.2, "Legs" => .62, "Feet" => .16, "Hand" => 1.0];
	static var DISTANCE = ["Head" => 1.5, "Body" => 2.8, "Legs" => 2.8, "Feet" => 1.9, "Hand" => 2.4];

	var stage:Stage3D;
	var camera = new Camera3D();
	var animations:Null<ModelFile>;
	var character:Null<Node3D>;
	var animator:Null<Animator>;
	var outfit:Outfit;
	var environment:Null<Environment>;
	// The pictures: a stage of its own with a second character, dressed in one part at a time, drawn into each tile's texture.
	var studio:Stage3D;
	var model:Null<Node3D>;
	var modelOutfit:Outfit;
	var shot = new Camera3D();
	var thumbs:Map<String, Texture2D> = [];
	var wanted:Array<{slot:String, path:String}> = [];
	// The 2D screen.
	var ui:Ui;
	var screen = new Stage2D();
	var camera2D = new Camera2D();
	var hud = new Camera2D();
	var pointer:Pointer;
	var batch:Batch2D;
	var fps = new FpsOverlay();
	var layout:Box;
	var panel:Panel;
	// The window's shape, as the layout was last arranged for it (shape), and whether it's upright: a phone held so, the panel under her.
	var shaped = "";
	var portrait = false;
	var tabs:Array<Button> = [];
	var tiles:Array<Tile> = [];
	var poses:Array<Button> = [];
	var random:Button;
	// The Random button's deals, from a seed, so a run deals the same looks again and a check can replay them.
	var deals = new Random();
	var reset:Button;
	var title:Label;
	var slot = "Body";
	var status = "Loading";
	// The turntable and the camera's ease toward the slot's framing.
	var turn = .35;
	var zoom = 1.;
	var dragFrom:Null<Float> = null;
	var focus = 1.;
	var distance = 3.;

	override public function init():Void {
		Window.title = "HeliX dressing room";
		Window.requestSize(1280, 720);
		var gpu = Graphics.instance;
		stage = new Stage3D(gpu);
		studio = new Stage3D(gpu);
		for (s in [stage, studio]) {
			s.setAmbient(0xd8e0ffff, .3);
			var key = new DirectionalLight();
			key.intensity = 2.2;
			key.lookAt(-.5, -.8, -.6);
			if (s == stage) {
				key.shadowCasting = true;
				key.shadowDistance = 5;
			}
			s.add(key);
		}
		// The turntable: a low disc on a dark floor.
		var floor = new Material();
		floor.baseColor = 0x22252eff;
		floor.roughness = .95;
		stage.add(new Model(Mesh.plane(30, 30), floor));
		var plinth = new Material();
		plinth.baseColor = 0x8a8f9cff;
		plinth.roughness = .4;
		plinth.metallic = .2;
		var disc = new Model(Mesh.cylinder(.8, .06, 64), plinth);
		disc.setPosition(0, .03, 0);
		stage.add(disc);
		outfit = new Outfit(Models.instance);
		modelOutfit = new Outfit(Models.instance);
		Environments.load("environments/studio_small_09_1k.hdr", value -> light(value));
		// Her look before she's here: the Outfit wears it once the skeleton arrives.
		dress(["Casual", "Casual", "Casual", "Casual"], null);
		Models.load(DIR + "Animations.glb", file -> place(file), message -> status = message);
		batch = new Batch2D(gpu);
		buildScreen();
		open("Body");
	}

	// The panel on the right: the slots' tabs, a grid of ten tiles, the poses, and Random and Reset.
	// The studio's environment in: it lights both stages.
	function light(value:Environment):Void {
		environment = value;
		for (s in [stage, studio])
			s.setEnvironment(value, .9);
	}

	// The skeleton's file in: her copy on the stage, animated and wearing her outfit, and the pictures' copy in the studio.
	function place(file:ModelFile):Void {
		animations = file;
		character = file.instantiate("character");
		character.setPosition(0, .06, 0);
		stage.add(character);
		animator = new Animator(character);
		outfit.skeleton = character;
		model = file.instantiate("model");
		studio.add(model);
		// The pictures' character holds still, in the idle pose's first frame.
		var still = new Animator(model);
		var idle = file.getClip("Idle");
		if (idle != null) {
			still.play(idle, false);
			still.update(0);
		}
		modelOutfit.skeleton = model;
		pose("Idle");
	}

	function buildScreen():Void {
		pointer = new Pointer(Input.instance);
		pointer.addStage2D(screen, camera2D);
		ui = new Ui(screen, camera2D, pointer, Input.instance);
		panel = ui.panel("wardrobe");
		title = ui.label("Dressing room");
		title.node.textSize = 26;
		panel.add(title);
		var tabRow = Box.row();
		tabRow.gap = ui.theme.gap;
		for (s in SLOTS) {
			var tab = ui.button(s, 'tab ${s.toLowerCase()}');
			panel.adopt(tab);
			tabRow.add(tab.box);
			tabs.push(tab);
		}
		panel.content.add(tabRow);
		var grid = Box.column();
		grid.gap = 8;
		for (r in 0...2) {
			var row = Box.row();
			row.gap = 8;
			for (c in 0...5) {
				var tile = ui.tile(null, "", 72, 'tile ${r * 5 + c}');
				panel.adopt(tile);
				row.add(tile.box);
				tiles.push(tile);
			}
			grid.add(row);
		}
		panel.content.add(grid);
		var poseLabel = ui.label("Pose");
		panel.add(poseLabel);
		var poseRow = Box.row();
		poseRow.gap = ui.theme.gap;
		for (i in 0...POSES.length) {
			var button = ui.button(POSE_NAMES[i], 'pose ${POSES[i].toLowerCase()}');
			panel.adopt(button);
			poseRow.add(button.box);
			poses.push(button);
		}
		panel.content.add(poseRow);
		var actions = Box.row();
		actions.gap = ui.theme.gap;
		random = ui.button("Random");
		reset = ui.button("Reset");
		for (b in [random, reset]) {
			panel.adopt(b);
			actions.add(b.box);
		}
		panel.content.add(actions);
		layout = Box.stack();
		layout.setSizing(Grow(1), Grow(1));
		layout.setPadding(12, 12, 12, 12);
		layout.add(panel.box);
	}

	// The panel for the window's shape (ScreenShape's designs): on the right, or upright along the bottom (five tiles still fit across the
	// upright design's 560 units). The layout is arranged into all that's visible.
	function shape(name:String):Void {
		shaped = name;
		portrait = name == "portrait";
		var box = panel.box;
		if (portrait) {
			box.setSizing(Grow(1), Fit);
			box.setAnchor(Stretch, End);
		} else {
			box.setSizing(Fixed(600), Fit);
			box.setAnchor(End, Center, -12, 0);
		}
	}

	// The part file for slot in look (a held part's own name for the hand).
	static function path(slot:String, look:String):String
		return slot == "Hand" ? DIR + look + ".glb" : DIR + '${look}_$slot.glb';

	// What slot's tiles offer: the ten outfits' parts, or the held parts and nothing.
	static function choices(slot:String):Array<Null<String>>
		return slot == "Hand" ? [for (h in HELD) h].concat([null]) : LOOKS.map(l -> (l : Null<String>));

	// Dresses her: head, body, legs and feet from looks (in SLOTS' order), and held in her hand (null: nothing).
	function dress(looks:Array<String>, held:Null<String>):Void {
		for (i in 0...4)
			outfit.choose(SLOTS[i], path(SLOTS[i], looks[i]));
		choose("Hand", held);
	}

	// A held part hangs from the joint its file hangs it from (her right hand's), as any part's rigid models do.
	function choose(s:String, look:Null<String>):Void
		outfit.choose(s, look == null ? null : path(s, look));

	// Opens slot's tab: its tiles show its parts, whose files load now (if they haven't), each pictured once it's in.
	function open(s:String):Void {
		slot = s;
		var offered = choices(s);
		for (i in 0...tiles.length) {
			var tile = tiles[i],
				look = i < offered.length ? offered[i] : null,
				shown = i < offered.length;
			tile.visible = shown;
			if (!shown)
				continue;
			tile.caption = look == null ? "Empty" : look;
			tile.texture = null;
			if (look == null)
				continue;
			var p = path(s, look);
			if (thumbs.exists(p))
				tile.texture = thumbs[p];
			else {
				wanted.push({slot: s, path: p});
				Models.load(p, _ -> {});
			}
		}
		for (t in tabs)
			t.text = t.text.split(" ")[0] + (t.text.split(" ")[0] == s ? " *" : "");
		ui.reset();
	}

	// A part's picture, once its file and the pictures' character are in: worn alone, framed as its slot is, drawn into a texture of its own.
	// At most two a frame, so a tab of ten fills in over a few frames.
	function takePictures():Void {
		if (model == null)
			return;
		var taken = 0;
		for (w in wanted.copy()) {
			if (taken >= 2)
				break;
			if (!Models.isLoaded(w.path)) {
				if (!Models.isLoading(w.path))
					wanted.remove(w);
				continue;
			}
			wanted.remove(w);
			for (s in SLOTS)
				modelOutfit.choose(s, null);
			modelOutfit.choose(w.slot, w.path);
			var texture = Texture2D.renderTarget(Graphics.instance, THUMB, THUMB);
			aim(modelOutfit.getNodes(w.slot), w.slot == "Hand");
			Graphics.beginTargetPass(texture.handle, 0x2a / 255, 0x2f / 255, 0x3c / 255, 1);
			studio.draw(shot);
			Graphics.endTargetPass();
			thumbs[w.path] = texture;
			taken++;
		}
		for (s in SLOTS)
			modelOutfit.choose(s, null);
		// Shown on the tiles of the tab that's open.
		var offered = choices(slot);
		for (i in 0...offered.length)
			if (offered[i] != null) {
				var t = thumbs[path(slot, offered[i])];
				if (t != null && tiles[i].texture != t)
					tiles[i].texture = t;
			}
	}

	// Points the pictures' camera at nodes, fitted to where they are in the still pose: a rigid mesh's bounds in the world, a skinned one's
	// joints as posed (its bounds are its bind pose's, arms out), padded by how far their vertices reach. From the front a little to the side,
	// or for a held part from her right, its length across the picture.
	function aim(nodes:Array<Node3D>, held:Bool):Void {
		var min = [1e9, 1e9, 1e9],
			max = [-1e9, -1e9, -1e9],
			world = new helix.render3d.Mat4();
		function add(x:Float, y:Float, z:Float, pad:Float) {
			var p = [x, y, z];
			for (a in 0...3) {
				min[a] = Math.min(min[a], p[a] - pad);
				max[a] = Math.max(max[a], p[a] + pad);
			}
		}
		function walk(node:Node3D) {
			var model = Std.downcast(node, Model);
			var mesh = model != null ? model.mesh : null;
			if (mesh != null && mesh.skinned) {
				// Only the joints this part weights (its skin may name every joint of the skeleton), each padded by how far its vertices reach, at
				// most a hand's breadth: a long bone's reach would frame far more than the part.
				var reach = mesh.getJointReach(model.skin);
				for (j in 0...model.jointCount)
					if (reach != null && reach[j] >= 0) {
						model.getJoint(j).computeWorld(world);
						add(world.get(12), world.get(13), world.get(14), Math.min(reach[j] * .55, .12));
					}
			} else if (mesh != null) {
				node.computeWorld(world);
				for (corner in 0...8) {
					var x = (corner & 1) == 0 ? mesh.minX : mesh.maxX,
						y = (corner & 2) == 0 ? mesh.minY : mesh.maxY,
						z = (corner & 4) == 0 ? mesh.minZ : mesh.maxZ;
					add(world.get(0) * x
						+ world.get(4) * y
						+ world.get(8) * z
						+ world.get(12),
						world.get(1) * x
						+ world.get(5) * y
						+ world.get(9) * z
						+ world.get(13),
						world.get(2) * x
						+ world.get(6) * y
						+ world.get(10) * z
						+ world.get(14), 0);
				}
			}
			for (i in 0...node.childCount)
				walk(node.getChild(i));
		}
		for (node in nodes)
			walk(node);
		var cx = (min[0] + max[0]) / 2,
			cy = (min[1] + max[1]) / 2,
			cz = (min[2] + max[2]) / 2;
		// Far enough that the box's height and breadth fit the 30-degree view, a little margin around, plus half its depth.
		var high = (max[1] - min[1]) / 2,
			broad = Math.max(max[0] - min[0], max[2] - min[2]) / 2;
		var d = Math.max(.08, Math.max(high, broad)) / Math.tan(15 * Math.PI / 180) * 1.12 + broad;
		shot.setViewport(THUMB, THUMB);
		shot.fovY = 30;
		shot.near = .02;
		shot.far = 50;
		if (held)
			shot.setView(cx - d, cy + d * .2, cz + d * .25, cx, cy, cz);
		else
			shot.setView(cx + d * .35, cy + d * .15, cz + d, cx, cy, cz);
	}

	function pose(name:String):Void {
		if (animations == null || animator == null)
			return;
		var clip = animations.getClip(name);
		if (clip != null)
			animator.play(clip, name == "Idle" || name == "Run", .25);
	}

	// The tab Q or E moves to, by direction.
	function step(direction:Int):Void
		open(SLOTS[(SLOTS.indexOf(slot) + direction + SLOTS.length) % SLOTS.length]);

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		var window = Window.instance, presentation = Screen.instance;
		var width = window.framebufferWidth, height = window.framebufferHeight;
		var wanted = ScreenShape.update();
		if (wanted != shaped)
			shape(wanted);
		presentation.apply(camera2D);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		Box.arrange(layout, vx, vy, vw, vh, batch.font);
		pointer.update();
		ui.update();
		for (i in 0...tabs.length)
			if (tabs[i].clicked)
				open(SLOTS[i]);
		if (!ui.capturingKeys || ui.focused == null) {
			if (input.isFramePressed(Key.Q))
				step(-1);
			if (input.isFramePressed(Key.E))
				step(1);
		}
		var offered = choices(slot);
		for (i in 0...offered.length)
			if (tiles[i].clicked)
				choose(slot, offered[i]);
		for (i in 0...poses.length)
			if (poses[i].clicked)
				pose(POSES[i]);
		if (random.clicked) {
			dress([for (_ in 0...4) deals.pick(LOOKS)], deals.nextBool(1 / 3) ? null : deals.pick(HELD));
		}
		if (reset.clicked)
			dress(["Casual", "Casual", "Casual", "Casual"], null);
		if (Host.canQuit() && ui.backPressed)
			Host.quit();
		// Which tile shows what she wears in the open slot.
		var worn = outfit.getChoice(slot);
		for (i in 0...offered.length)
			tiles[i].selected = offered[i] == null ? worn == null : worn == path(slot, offered[i]);
		// The turntable: a drag on the room (beside the panel, or above it) turns her; the wheel or a pinch comes closer.
		var box = panel.box,
			px = presentation.toUnitsX(input.pointerX),
			py = presentation.toUnitsY(input.pointerY);
		if (input.pointerFramePressed && (portrait ? py < box.y : px < box.x))
			dragFrom = input.pointerX;
		if (!input.pointerDown)
			dragFrom = null;
		if (dragFrom != null) {
			turn += (input.pointerX - dragFrom) * .01;
			dragFrom = input.pointerX;
		}
		zoom = Interpolate.clamp(zoom - input.wheelY * .001 + (input.getTouchGestureScale(true) - 1) * -.5, .5, 1.6);
		if (dragFrom == null)
			turn += dt * .15;
		// The camera eases toward the slot's framing.
		focus = Interpolate.damp(focus, FOCUS[slot], 6, dt);
		distance = Interpolate.damp(distance, DISTANCE[slot] * zoom, 6, dt);
		if (character != null)
			character.setRotation(0, turn, 0);
		if (animator != null)
			animator.update(dt);
		takePictures();
		var loading = Models.loadingCount;
		status = character == null ? "Loading her" : loading > 0 ? 'Loading $loading part${loading == 1 ? "" : "s"}' : 'Dressing: $slot';
		for (s in SLOTS) {
			var error = outfit.getError(s);
			if (error != null)
				status = error;
		}
		fps.update(dt, Time.frameCpu);

		camera.setViewport(width, height);
		camera.fovY = 35;
		camera.near = .05;
		camera.far = 100;
		if (portrait) {
			// Her above the panel, in the framebuffer over it, centered.
			var top = Std.int(Math.max(1, Math.min(height, (box.y - vy) * presentation.scaleY + presentation.areaY)));
			camera.setViewportArea(0, 0, width, top);
			camera.setView(0, focus + distance * .12, distance, 0, focus, 0);
		} else {
			// Her on the left of the room, the panel on the right: the camera looks a little right of her.
			var side = distance * .42;
			camera.setView(side, focus + distance * .12, distance, side, focus, 0);
		}
		stage.drawShadows(camera);
		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		screen.draw(batch, camera2D);
		batch.drawText(status, vx + 24, portrait ? box.y - 30 : vy + vh - 40, 18, 0xc8d0e8ff);
		batch.drawText(portrait ? "drag: turn   pinch: closer" : "drag: turn   wheel: closer   Q / E: slot   arrows, Enter, or a pad", vx + 24, vy + 24, 16,
			0x8a92a8ff);
		batch.end();
		hud.setViewport(width, height);
		hud.pixels(Window.pixelRatio);
		batch.begin(hud);
		fps.draw(batch, width / Window.pixelRatio - 130, 8);
		batch.end();
		Graphics.endFrame();
	}

	override public function cleanup():Void {
		stage.destroy();
		studio.destroy();
		batch.destroy();
		for (t in thumbs)
			t.destroy(Graphics.instance);
	}
}
