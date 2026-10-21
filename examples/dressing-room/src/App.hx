import helix.assets.Assets;
import helix.debug.Autopilot;
import helix.debug.TestHarness;
import helix.debug.FpsOverlay;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Presentation;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.input.PointerGestures;
import helix.math.Interpolate;
import helix.math.Random;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Shape2D;
import helix.render2d.Stage2D;
import helix.render2d.Texture2D;
import helix.render3d.AnimationClip;
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
import helix.ui.Layout2D;
import helix.ui.Button;
import helix.ui.Dropdown;
import helix.ui.Label;
import helix.ui.Panel;
import helix.ui.Tile;
import helix.ui.Toggle;
import helix.ui.Ui;
import helix.host.ScreenShape;

/** A character creator's dressing room: a character on a turntable in a studio's light, dressed slot by slot (head, body, legs, feet, and
	what she holds) from Quaternius's Ultimate Modular Women, ten outfits whose parts mix freely. Each slot's parts are tiles, their pictures
	rendered from the parts themselves (render targets) as their files load; a slot's files load only when its tab is opened, through the
	Models the program shares (here the one on the stage and the one the pictures are taken of), and an Outfit (this example's, over the
	framework's binding and attachment queries) wears each choice on
	the skeleton by joint name, a held part at a joint. The camera starts on her whole and stays where it's put while she's dressed: drag to turn
	her, the wheel or a pinch to zoom (from close in to well back in the room), a double click or a double tap on her to frame the part under it
	(on a slot's tab, that slot), on the empty room to see her whole again. The turntable turns her slowly, on or off by its toggle or T.
	The Animation dropdown plays any of her animations, every clip in the animations file by a readable name, idles first; a play button
	plays the chosen one again from its start, and Loop says whether it goes on or plays once and goes back to her idle after, her idle the
	one for what she holds (a sword, a gun or nothing); choosing a clip sets Loop to the clip's own way (idles, walks and runs loop) and the
	player may flip it. Random and Reset dress her at once. The hint and status lines sit on dark bands, readable over the lit room. Pointer,
	keys (arrows, Tab, Enter; Q and E change slot) or a pad.

	Options: autopilot (a script under assets/: the turntable, her pose and the camera, on the Body framing, are then held from the first frame,
	the window the autopilot's page's size, so its samples of her and of the tiles' pictures compare across targets). */
class App extends helix.App {
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
	static inline var THUMB = 128;
	// The pictures' vertical view, 30 degrees in radians.
	static final SHOT_FOV = 30 * Math.PI / 180;
	// The autopilot's window size (its browser page's), so its samples compare across targets.
	static inline var PILOT_WIDTH = 800;
	static inline var PILOT_HEIGHT = 600;
	// What the room's camera frames, for each slot and for her whole, on her as she stands on the turntable: from the height and to the height
	// (world y), how far either side of the turntable's axis as she turns, and how far toward the camera she comes (the held part's reach for the
	// hand). Head and shoulders, the torso, hips to feet, lower legs and feet, what she holds, all of her.
	static var FRAMES = [
		"Whole" => [0, 2.0, .45, .25],
		"Head" => [1.42, 2.0, .3, .15],
		"Body" => [1.0, 1.68, .4, .2],
		"Legs" => [0, 1.22, .36, .2],
		"Feet" => [0, .52, .3, .2],
		"Hand" => [.6, 1.4, .5, .4]
	];
	// The room's camera's vertical view, a quarter turn (radians), and the share of the free area the framing may fill.
	static final ROOM_FOV = Math.PI / 4;
	static inline var ROOM_FILL = .88;
	// The zoom's limits: in to a quarter of a framing's distance, back to ROOM_REACH times her whole framing's, the room's floor around her.
	static inline var ZOOM_IN = .25;
	static inline var ROOM_REACH = 2.5;
	// Units kept clear above and below the framing in the free area, for the hint and the status lines.
	static inline var TEXT_ROOM = 56;

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
	var layout:Layout2D;
	var panel:Panel;
	// The window's shape, as the layout was last arranged for it (shape), and whether it's upright: a phone held so, the panel under her.
	var shaped = "";
	var portrait = false;
	var tabs:Array<Button> = [];
	var tiles:Array<Tile> = [];
	// The Animation dropdown and the clips it offers, in its order; the play button and the triangle drawn on it (the built-in font has no play
	// glyph), and the Loop toggle.
	var clipChoice:Dropdown;
	var clipList:Array<AnimationClip> = [];
	var playButton:Button;
	var playIcon:Shape2D;
	var looping:Toggle;
	var random:Button;
	// The Random button's deals, from a seed, so a run deals the same looks again and a check can replay them.
	var deals = new Random();
	var reset:Button;
	var turntable:Toggle;
	var title:Label;
	var slot = "Body";
	var status = "Loading";
	// The turntable and the camera's ease toward its framing (FRAMES' key, kept as slots are chosen; double clicks change it): where it looks
	// (x, y, z) and how far away. The key light, whose shadows reach past her as the camera backs away.
	var turn = .35;
	var zoom = 1.;
	var framing = "Whole";
	var dragFrom:Null<Float> = null;
	var gestures = new PointerGestures();
	var key:DirectionalLight;
	var focusX = 0.;
	var focus = 1.;
	var focusZ = 0.;
	var distance = 3.;
	// What she holds, the box around it as posed (for the hand's framing), and one model's (computeBounds's).
	var heldBox = new haxe.ds.Vector<Float>(6);
	var box = new haxe.ds.Vector<Float>(6);
	// The autopilot: whether one was asked for (the scene held from the first frame, before its script is in), and its final game published.
	var pilot:Null<Autopilot>;
	var piloted = false;
	var published = false;

	override public function init():Void {
		Window.title = "HeliX dressing room";
		var script = Host.getOption("autopilot", "");
		if (script != "") {
			piloted = true;
			Window.requestSize(PILOT_WIDTH, PILOT_HEIGHT);
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		} else
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
				this.key = key;
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

	// The panel on the right: the slots' tabs, a grid of ten tiles, the Animation row, and Random, Reset and the turntable.
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
		// The Animation dropdown: every clip in the file, the idles first, each kept in the file's order.
		var clips = file.clips;
		clipList = [for (c in clips) if (isIdle(c)) c].concat([for (c in clips) if (!isIdle(c)) c]);
		clipChoice.items = [for (c in clipList) readable(c.name)];
		clipChoice.selectedIndex = clipList.indexOf(file.getClip("Idle"));
		chooseClip(file.getClip("Idle"));
	}

	// A clip's first word, its name after the armature's ("CharacterArmature|Idle_Sword": "Idle").
	static function firstWord(clip:AnimationClip):String {
		var name = clip.name.substr(clip.name.lastIndexOf("|") + 1);
		return name.split("_")[0];
	}

	static function isIdle(clip:AnimationClip):Bool
		return firstWord(clip) == "Idle";

	// Whether a clip loops, by its name: idles, walks and runs go on (Idle_Gun_Shoot, Run_Left); the rest (a wave, a slash, a roll, a hit,
	// Death) play once.
	static function isLooping(clip:AnimationClip):Bool
		return ["Idle", "Walk", "Run"].indexOf(firstWord(clip)) >= 0;

	// A clip's name to show, as the file spells it but readable: the armature's part dropped, words apart at underscores and where a capital
	// follows a small letter ("CharacterArmature|HitRecieve_2": "Hit Recieve 2").
	static function readable(name:String):String {
		var bare = name.substr(name.lastIndexOf("|") + 1),
			out = new StringBuf();
		for (i in 0...bare.length) {
			var c = bare.charAt(i);
			if (c == "_") {
				out.add(" ");
				continue;
			}
			var before = i > 0 ? bare.charAt(i - 1) : "";
			if (before != ""
				&& before != "_"
				&& c != c.toLowerCase()
				&& before == before.toLowerCase()
				&& before != before.toUpperCase())
				out.add(" ");
			out.add(c);
		}
		return out.toString();
	}

	function buildScreen():Void {
		pointer = new Pointer(Input.instance);
		pointer.addStage2D(screen, camera2D);
		ui = new Ui(screen, camera2D, pointer, Input.instance);
		panel = ui.panel("wardrobe");
		title = ui.label("Dressing room");
		title.textSize = 26;
		panel.add(title);
		var tabRow = Layout2D.row();
		tabRow.gap = ui.theme.gap;
		for (s in SLOTS) {
			var tab = ui.button(s, 'tab ${s.toLowerCase()}');
			panel.adopt(tab);
			tabRow.add(tab.layout);
			tabs.push(tab);
		}
		panel.content.add(tabRow);
		var grid = Layout2D.column();
		grid.gap = 8;
		for (r in 0...2) {
			var row = Layout2D.row();
			row.gap = 8;
			for (c in 0...5) {
				var tile = ui.tile(null, "", 72, 'tile ${r * 5 + c}');
				panel.adopt(tile);
				row.add(tile.layout);
				tiles.push(tile);
			}
			grid.add(row);
		}
		panel.content.add(grid);
		panel.add(ui.separator());
		// Her animation: a label, a dropdown (its clips in once the animations file is: place), a square play button and Loop, in a row.
		var animationLabel = ui.label("Animation");
		clipChoice = ui.dropdown([], -1, "animation");
		clipChoice.hint = "Loading";
		playButton = ui.button("", "play");
		playButton.layout.widthSizing = Fixed(ui.theme.widgetHeight);
		looping = ui.toggle("Loop", true, "loop");
		var animationRow = Layout2D.row();
		animationRow.gap = ui.theme.gap;
		animationRow.setAlign(Start, Center);
		for (w in [animationLabel, clipChoice, playButton, looping]) {
			panel.adopt(w);
			animationRow.add(w.layout);
		}
		panel.content.add(animationRow);
		// The play button's triangle, over the UI's nodes (the dropdown's list opens over the tiles, never over it), not picked.
		var side = ui.theme.textSize * .4;
		playIcon = Shape2D.polygon([-side * .8, -side, side, 0, -side * .8, side], ui.theme.textColor);
		playIcon.pickable = false;
		screen.add(playIcon);
		var actions = Layout2D.row();
		actions.gap = ui.theme.gap;
		random = ui.button("Random");
		reset = ui.button("Reset");
		for (b in [random, reset]) {
			panel.adopt(b);
			actions.add(b.layout);
		}
		turntable = ui.toggle("Turntable", true, "turntable");
		panel.adopt(turntable);
		actions.add(turntable.layout);
		panel.content.add(actions);
		layout = Layout2D.stack();
		layout.setSizing(Grow(1), Grow(1));
		layout.setPadding(12, 12, 12, 12);
		layout.add(panel.layout);
	}

	// The panel for the window's shape (ScreenShape's designs): on the right as wide as its widest row, or upright along the bottom (five tiles still fit across the
	// upright design's 560 units). The layout is arranged into all that's visible.
	function shape(name:String):Void {
		shaped = name;
		portrait = name == "portrait";
		var panelLayout = panel.layout;
		if (portrait) {
			panelLayout.setSizing(Grow(1), Fit);
			panelLayout.setAnchor(Stretch, End);
		} else {
			panelLayout.setSizing(Fit, Fit);
			panelLayout.setAnchor(End, Center, -12, 0);
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

	// A held part hangs from the joint its file hangs it from (her right hand's), as any part's rigid models do; her idle changes to hold it.
	function choose(s:String, look:Null<String>):Void {
		outfit.choose(s, look == null ? null : path(s, look));
		if (s == "Hand")
			settle();
	}

	// Her idle for what she holds: the sword's, the gun's, or her plain one empty-handed.
	function getIdle():Null<AnimationClip> {
		if (animations == null)
			return null;
		var held = outfit.getChoice("Hand");
		for (h in HELD)
			if (held == path("Hand", h))
				return animations.getClip('Idle_$h');
		return animations.getClip("Idle");
	}

	// Her idle as what she holds changes: crossfaded to while she idles, or queued after the pose she's in.
	function settle():Void {
		var idle = getIdle();
		if (animator == null || idle == null || animations == null)
			return;
		var playing = animator.clip,
			idles = [animations.getClip("Idle")].concat([for (h in HELD) animations.getClip('Idle_$h')]);
		if (playing != null && idles.indexOf(playing) >= 0)
			animator.play(idle, true, piloted ? 0 : .25);
		else if (animator.queued != null)
			animator.queue(idle, true, .25);
	}

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

	// Points the pictures' camera at nodes, fitted to the box around their models as they're posed now (a skinned model's vertices moved by
	// its joints): from the front a little to the side, or for a held part from her right, its length across the picture. Near enough that
	// every corner of the box is inside the picture, a little margin around.
	function aim(nodes:Array<Node3D>, held:Bool):Void {
		var bounds = new haxe.ds.Vector<Float>(6);
		if (!computeBounds(nodes, bounds))
			return;
		var min = [bounds[0], bounds[1], bounds[2]],
			max = [bounds[3], bounds[4], bounds[5]];
		var center = [for (a in 0...3) (min[a] + max[a]) / 2];
		// The way to the eye from the box's center, and the picture's right and up square to it.
		var back = held ? [-1, .2, .25] : [.35, .15, 1.];
		var length = Math.sqrt(back[0] * back[0] + back[1] * back[1] + back[2] * back[2]);
		back = back.map(v -> v / length);
		var right = [back[2], 0, -back[0]];
		length = Math.sqrt(right[0] * right[0] + right[2] * right[2]);
		right = right.map(v -> v / length);
		var up = [
			back[1] * right[2] - back[2] * right[1],
			back[2] * right[0] - back[0] * right[2],
			back[0] * right[1] - back[1] * right[0]
		];
		// Each corner's distance across or up, over the view's slope with a margin of 8%, plus how far it stands toward the eye.
		var slope = Math.tan(SHOT_FOV / 2) / 1.08, d = .1;
		for (corner in 0...8) {
			var p = [
				for (a in 0...3)
					(corner >> a) & 1 == 0 ? min[a] - center[a] : max[a] - center[a]
			];
			function along(axis:Array<Float>):Float
				return p[0] * axis[0] + p[1] * axis[1] + p[2] * axis[2];
			d = Math.max(d, along(back) + Math.max(Math.abs(along(right)), Math.abs(along(up))) / slope);
		}
		shot.setViewport(THUMB, THUMB);
		shot.fovY = SHOT_FOV;
		shot.near = .02;
		shot.far = 50;
		shot.setView(center[0] + back[0] * d, center[1] + back[1] * d, center[2] + back[2] * d, center[0], center[1], center[2]);
	}

	// The room's camera: its framing (FRAMES; the Body's under the autopilot) fitted to the room left free by the panel (beside it, or above it
	// upright), less the text's lines, and centered there by a lens shift, so she is seen square on wherever the panel leaves room; the whole
	// window drawn. For the hand, the framing follows what she holds as she turns. Where it looks and how far away ease toward the framing's (at
	// once under the autopilot); the zoom scales the distance, held between ZOOM_IN and ROOM_REACH times her whole framing's.
	function frameRoom(presentation:Presentation, width:Int, height:Int, dt:Float):Void {
		var panelLayout = panel.layout,
			vx = presentation.visibleX,
			vy = presentation.visibleY;
		var left = vx, right = portrait ? vx + presentation.visibleWidth : panelLayout.x, top = vy + TEXT_ROOM,
			bottom = (portrait ? panelLayout.y : vy + presentation.visibleHeight) - TEXT_ROOM;
		// The free area in framebuffer pixels, at least a pixel each way.
		var x0 = presentation.toPixelsX(left),
			x1 = Math.max(x0 + 1, presentation.toPixelsX(right)),
			y0 = presentation.toPixelsY(top),
			y1 = Math.max(y0 + 1, presentation.toPixelsY(bottom));
		camera.setViewport(width, height);
		camera.fovY = ROOM_FOV;
		camera.near = .05;
		camera.far = 100;
		camera.lensShiftX = ((x0 + x1) / 2 - width / 2) / (width / 2);
		camera.lensShiftY = (height / 2 - (y0 + y1) / 2) / (height / 2);
		// Far enough that the framing's height fits the free area's height and its breadth its width (a pixel is as tall as it is wide), from
		// the nearest she comes.
		var framed = piloted ? "Body" : framing,
			slope = Math.tan(ROOM_FOV / 2);
		// How far a framing's height and breadth fit.
		function fitting(frame:Array<Float>):Float
			return Math.max((frame[1] - frame[0]) / 2 / ((y1 - y0) * ROOM_FILL), frame[2] / ((x1 - x0) * ROOM_FILL)) * height / slope + frame[3];
		var frame = FRAMES[framed], fit = fitting(frame);
		zoom = Interpolate.clamp(zoom, ZOOM_IN, ROOM_REACH * fitting(FRAMES["Whole"]) / fit);
		var lookX = 0., lookY = (frame[0] + frame[1]) / 2, lookZ = 0.;
		if (framed == "Hand" && computeBounds(outfit.getNodes("Hand"), heldBox)) {
			lookX = (heldBox[0] + heldBox[3]) / 2;
			lookY = (heldBox[1] + heldBox[4]) / 2;
			lookZ = (heldBox[2] + heldBox[5]) / 2;
		}
		focusX = piloted ? lookX : Interpolate.damp(focusX, lookX, 6, dt);
		focus = piloted ? lookY : Interpolate.damp(focus, lookY, 6, dt);
		focusZ = piloted ? lookZ : Interpolate.damp(focusZ, lookZ, 6, dt);
		distance = piloted ? fit * zoom : Interpolate.damp(distance, fit * zoom, 6, dt);
		camera.setView(focusX, focus + distance * .12, focusZ + distance, focusX, focus, focusZ);
		// The shadows reach a little past her, however far back the camera is (5 units near, the map's texels as fine as before).
		key.shadowDistance = Math.max(5, distance + 2);
	}

	// Frames the part under framebuffer pixel x, y (its slot's framing), or her whole for the room or nothing; the zoom back to 1.
	function focusAt(x:Float, y:Float):Void {
		var hit = stage.pick(camera, x, y);
		framing = "Whole";
		var node = hit == null ? null : hit.node;
		while (node != null && framing == "Whole") {
			for (s in SLOTS)
				if (outfit.getNodes(s).indexOf(node) >= 0)
					framing = s;
			node = node.parent;
		}
		zoom = 1;
	}

	// The box around the models at or under nodes as they are now (a skinned one's vertices as posed), into out (least x, y, z, then most); false
	// for none.
	function computeBounds(nodes:Array<Node3D>, out:haxe.ds.Vector<Float>):Bool {
		for (a in 0...3) {
			out[a] = Math.POSITIVE_INFINITY;
			out[3 + a] = Math.NEGATIVE_INFINITY;
		}
		function walk(node:Node3D) {
			var model = Std.downcast(node, Model);
			if (model != null && model.computeWorldBounds(box))
				for (a in 0...3) {
					out[a] = Math.min(out[a], box[a]);
					out[3 + a] = Math.max(out[3 + a], box[3 + a]);
				}
			for (i in 0...node.childCount)
				walk(node.getChild(i));
		}
		for (node in nodes)
			walk(node);
		return out[0] <= out[3];
	}

	// A clip chosen: Loop set to its own way (isLooping), and played.
	function chooseClip(chosen:Null<AnimationClip>):Void {
		if (chosen == null)
			return;
		looping.on = isLooping(chosen);
		animate(chosen);
	}

	// Plays clip from its start, faded in (at once, held at its first frame, under the autopilot): the plain Idle her idle for what she holds;
	// on while Loop is, or else once, back to her idle after.
	function animate(chosen:Null<AnimationClip>):Void {
		if (animations == null || animator == null || chosen == null)
			return;
		var idle = getIdle();
		var clip = chosen == animations.getClip("Idle") ? idle : chosen,
			loop = looping.on;
		if (clip == null)
			return;
		animator.play(clip, loop, piloted ? 0 : .25);
		if (!loop && idle != null)
			animator.queue(idle, true, .25);
	}

	// The autopilot's script in: it waits and samples the frame, its points on the wardrobe's widgets found by the UI, and presses nothing.
	function startPilot(bytes:haxe.io.Bytes):Void
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), null, (points, done, failed) -> Screenshots.sample(points, done, failed),
			(target, part, x, y, out) -> ui != null && ui.computePoint(target, part, x, y, out));

	// A named value for the autopilot. ready: she, her outfit, the light and the open slot's pictures are all in.
	function probe(name:String):Dynamic
		return switch name {
			case "ready": character != null && environment != null && !outfit.pending && isPictured();
			case "slot": slot;
			default: throw 'Unknown probe ' + name;
		}

	// Whether every part the open slot's tiles offer has its picture.
	function isPictured():Bool {
		for (look in choices(slot))
			if (look != null && !thumbs.exists(path(slot, look)))
				return false;
		return true;
	}

	// The tab Q or E moves to, by direction.
	function step(direction:Int):Void
		open(SLOTS[(SLOTS.indexOf(slot) + direction + SLOTS.length) % SLOTS.length]);

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		// The autopilot's tick: it presses nothing, only waits and samples the frame.
		if (pilot != null && !pilot.done)
			pilot.advance(name -> probe(name));
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
		Layout2D.arrange(layout, vx, vy, vw, vh, batch.font);
		pointer.update();
		ui.update();
		gestures.update(input, Time.time, false);
		for (i in 0...tabs.length)
			if (tabs[i].clicked) {
				open(SLOTS[i]);
				// A double click on a tab frames its slot.
				if (gestures.doubleTapped) {
					framing = SLOTS[i];
					zoom = 1;
				}
			}
		if (!ui.capturingKeys || ui.focused == null) {
			if (input.isFramePressed(Key.Q))
				step(-1);
			if (input.isFramePressed(Key.E))
				step(1);
			if (input.isFramePressed(Key.T))
				turntable.on = !turntable.on;
		}
		var offered = choices(slot);
		for (i in 0...offered.length)
			if (tiles[i].clicked)
				choose(slot, offered[i]);
		// A clip chosen plays at once, Loop set to its way; the play button, or Loop flipped, plays it again from its start.
		var chosen = clipChoice.selectedIndex >= 0 ? clipList[clipChoice.selectedIndex] : null;
		if (clipChoice.changed)
			chooseClip(chosen);
		else if (playButton.clicked || looping.changed)
			animate(chosen);
		playIcon.setPosition(playButton.layout.x + playButton.layout.width / 2, playButton.layout.y + playButton.layout.height / 2);
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
		// The turntable: a drag on the room (beside the panel, or above it) turns her; a double click there frames what's under it; the wheel or a
		// pinch zooms.
		var panelLayout = panel.layout;
		function inRoom(x:Float, y:Float):Bool
			return portrait ? presentation.toUnitsY(y) < panelLayout.y : presentation.toUnitsX(x) < panelLayout.x;
		if (input.pointerFramePressed && inRoom(input.pointerX, input.pointerY))
			dragFrom = input.pointerX;
		if (gestures.doubleTapped && !piloted && inRoom(gestures.startX, gestures.startY))
			focusAt(gestures.x, gestures.y);
		if (!input.pointerDown)
			dragFrom = null;
		if (dragFrom != null) {
			turn += (input.pointerX - dragFrom) * .01;
			dragFrom = input.pointerX;
		}
		// The wheel over the room zooms, a tenth a notch (wheelY counts notches, up closer); fingers spreading come closer as much as they spread.
		var notches = inRoom(input.pointerX, input.pointerY) ? input.wheelY : 0.;
		var pinch = input.getTouchGestureScale(true);
		// Held to its limits as the room is framed.
		zoom = zoom * Math.pow(.9, notches) / (pinch > 0 ? pinch : 1);
		if (piloted) {
			// Held under the autopilot: the turntable where it starts, the camera at the slot's framing, her pose at its first frame.
			turn = .35;
			zoom = 1;
		} else if (dragFrom == null && turntable.on)
			turn += dt * .15;
		if (character != null)
			character.setRotation(0, turn, 0);
		if (animator != null)
			animator.update(piloted ? 0 : dt);
		takePictures();
		var loading = Models.loadingCount;
		status = character == null ? "Loading her" : loading > 0 ? 'Loading $loading part${loading == 1 ? "" : "s"}' : 'Dressing: $slot';
		for (s in SLOTS) {
			var error = outfit.getError(s);
			if (error != null)
				status = error;
		}
		fps.update(dt, Time.frameCpu);

		frameRoom(presentation, width, height, dt);
		stage.drawShadows(camera);
		Graphics.beginFrame(width, height, 0x14161cff);
		stage.draw(camera);
		batch.begin(camera2D);
		screen.draw(batch, camera2D);
		caption(status, vx + 24, portrait ? panelLayout.y - 30 : vy + vh - 40, 18, 0xc8d0e8ff);
		caption(portrait ? "drag: turn   pinch: zoom   double-tap: focus" : "drag: turn   wheel: zoom   double-click: focus   T: turntable   Q / E: slot   arrows, Enter, or a pad",
			vx
			+ 24, vy
			+ 24, 16, 0x8a92a8ff);
		batch.end();
		hud.setViewport(width, height);
		hud.pixels(Window.pixelRatio);
		batch.begin(hud);
		fps.draw(batch, width / Window.pixelRatio - 130, 8);
		batch.end();
		Graphics.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			TestHarness.publish({game: {slot: slot}, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	// A line of text at x, y (its top left), size tall, on a band of the theme's panel color, a little see-through, rounded as its widgets are and
	// a padding wider each way, so it reads over the lit room whatever is behind it.
	function caption(text:String, x:Float, y:Float, size:Float, color:Int):Void {
		var theme = ui.theme, pad = theme.padding / 2;
		var font = theme.font != null ? theme.font : batch.font;
		batch.roundedRect(x - pad * 2, y - pad, font.measure(text, size) + pad * 4, size + pad * 2, theme.cornerRadius, (theme.panelColor & ~0xff) | 0xd0);
		batch.drawText(text, x, y, size, color, Left, font);
	}

	override public function cleanup():Void {
		stage.destroy();
		studio.destroy();
		batch.destroy();
		for (t in thumbs)
			t.destroy(Graphics.instance);
	}
}
