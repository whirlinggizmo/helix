import haxe.io.Bytes;
import helix.app.BaseApp;
import helix.assets.Assets;
import helix.assets.Storage;
import helix.audio.Audio;
import helix.audio.AudioClip;
import helix.audio.AudioPlayback;
import helix.audio.AudioStream;
import helix.audio.Bus;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Actions;
import helix.input.Anchor;
import helix.input.Binding;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.input.PadAxis;
import helix.input.PadButton;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.render2d.Texture2D;
import helix.scene.Pointer;
import helix.time.Time;
import helix.ui.Box;
import helix.ui.Button;
import helix.ui.Label;
import helix.ui.ListView;
import helix.ui.Panel;
import helix.ui.ProgressBar;
import helix.ui.Slider;
import helix.ui.TextField;
import helix.ui.Toggle;
import helix.ui.Ui;

/** A game's menus (helix.ui): a main menu, settings, controls and a scrolling list of levels, the main menu in a nine-slice panel, the others
	in the theme's rounded ones, every widget's corners rounded too, laid out in a 1280 x 720 design fitted to the window, used alike by the
	pointer, keys (arrows, Tab, Enter, Escape) and a pad (D-pad, South, East). Nothing is called back: each frame the example asks the widgets
	what happened. Settings set the master, music and effects buses (Audio.master, music, effects) with music playing under them, a short
	effect played as the effects slider is let go, and mute the music; Controls lists an Actions map's actions with their bindings, a Rebind
	button capturing the next key, pad button, axis or touch for one (Escape cancels) and Reset; both are saved through Storage and loaded at
	start. A progress bar fills; the status in the corner is anchored there. Escape on the main menu quits where quitting means anything.
	Options: autopilot (a script under assets/; the menus and the actions then read its input, and the settings are saved under keys of its
	own, removed first, so a run starts from the defaults and leaves a player's alone), audio (0 for silence) and autoclose (1: quit once the
	script is done). The probes: screen, focus (the focused widget's name), loaded, jump (its bindings' text, joined by ", "), capturing, jumpDown, masterVolume, musicVolume,
	effectsVolume and musicMuted. */
class App extends BaseApp {
	static final PROBES = [
		"screen",
		"focus",
		"loaded",
		"jump",
		"capturing",
		"jumpDown",
		"masterVolume",
		"musicVolume",
		"effectsVolume",
		"musicMuted"
	];

	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var hud = new Camera2D();
	var pointer:Pointer;
	var ui:Null<Ui>;
	var fps = new FpsOverlay();
	var layout:Box;
	var screen = "main";
	var status = "";
	var loading = 0.;
	// The screens' panels and widgets.
	var main:Panel;
	var settings:Panel;
	var controls:Panel;
	var levels:Panel;
	var play:Button;
	var openSettings:Button;
	var openControls:Button;
	var openLevels:Button;
	var quit:Button;
	var master:Slider;
	var music:Slider;
	var effects:Slider;
	var muteMusic:Toggle;
	var name:TextField;
	var back:Button;
	var rows:Array<{action:String, bindings:Label, rebind:Button}> = [];
	var live:Label;
	var reset:Button;
	var backFromControls:Button;
	var list:ListView;
	var start:Button;
	var backFromLevels:Button;
	var bar:ProgressBar;
	var corner:Label;
	// The player's controls, and the Storage keys they and the buses are saved under.
	var actions:Actions;
	var actionsKey = "actions";
	var busesKey = "audio";
	var loads = 0;
	// The action a rebind waits for a press for, or "".
	var rebinding = "";
	// The buses' volumes changed by a slider and not yet saved (saved once the pointer is let go), and whether effects was one.
	var unsaved = false;
	var effectsMoved = false;
	var song:Null<AudioPlayback>;
	var click:Null<AudioClip>;
	var pilot:Null<Autopilot>;
	var published = false;

	override public function init():Void {
		Window.title = "HeliX ui";
		Window.requestSize(1000, 600);
		batch = new Batch2D();
		if (Host.getOption("audio", "1") != "0") {
			Audio.instance.loadStream("audio/music/a_hero_is_born.mp3", stream -> playMusic(stream));
			Audio.instance.loadClip("audio/sfx/click_004.ogg", clip -> click = clip);
		}
		var script = Host.getOption("autopilot", "");
		if (script == "")
			build(Input.instance);
		else
			Assets.load(script, bytes -> {
				pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name), name -> ui.press(name));
				// A run of its own: its saves apart from a player's, and gone before it starts, so every run begins from the defaults.
				actionsKey = "autopilot-actions";
				busesKey = "autopilot-audio";
				build(pilot.input);
			}, message -> throw 'Autopilot load failed: ' + message);
	}

	// The music opened: played on the music bus, looping, the playback holding the stream.
	function playMusic(stream:AudioStream):Void {
		song = Audio.music.play(stream, true, .5);
		stream.release();
	}

	// The screens, read from input (the window's, or the autopilot's), and the controls and the buses' volumes loaded.
	function build(input:IInput):Void {
		pointer = new Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new Ui(stage, camera, pointer, input);
		this.ui = ui;
		actions = new Actions(input);
		actions.bind("jump", Keyboard(Key.Space));
		actions.bind("jump", Pad(PadButton.South));
		actions.bind("move", KeyboardPair(Key.Left, Key.Right));
		actions.bind("move", Axis(PadAxis.LeftX, 0, .15));
		actions.bind("fire", Keyboard(Key.Z));
		actions.bind("fire", Pad(PadButton.West));
		actions.bind("fire", TouchRegion(Anchor.BottomRight, -120, -120, 96, 96));

		var frame = panelImage();
		main = ui.panel("main");
		main.setFrame(frame, 6, 6, 6, 6, 0x262c3cff);
		var title = ui.label("HeliX ui");
		title.node.textSize = 32;
		play = ui.button("Play", "play");
		openSettings = ui.button("Settings", "openSettings");
		openControls = ui.button("Controls", "openControls");
		openLevels = ui.button("Levels", "openLevels");
		quit = ui.button("Quit", "quit");
		quit.enabled = Host.canQuit();
		for (w in [title, play, openSettings, openControls, openLevels, quit])
			main.add(w);

		settings = ui.panel("settings");
		var heading = ui.label("Settings");
		heading.node.textSize = 26;
		master = ui.slider("Master", 0, 100, 100, 10, "masterVolume");
		music = ui.slider("Music", 0, 100, 100, 10, "musicVolume");
		effects = ui.slider("Effects", 0, 100, 100, 10, "effectsVolume");
		muteMusic = ui.toggle("Mute music", false, "muteMusic");
		name = ui.textField("", "your name", 16, "name");
		back = ui.button("Back", "backFromSettings");
		for (w in [heading, master, music, effects, muteMusic, name, back])
			settings.add(w);

		controls = ui.panel("controls");
		var heading = ui.label("Controls");
		heading.node.textSize = 26;
		controls.add(heading);
		for (action in actions.names) {
			var label = ui.label(action),
				bindings = ui.label(""),
				rebind = ui.button("Rebind", 'rebind-$action');
			label.box.setSizing(Fixed(70), Fit);
			bindings.box.setSizing(Grow(1), Fit);
			var row = Box.row();
			row.gap = ui.theme.gap;
			row.setAlign(Start, Center);
			for (w in [label, bindings, rebind]) {
				controls.adopt(w);
				row.add(w.box);
			}
			controls.content.add(row);
			rows.push({action: action, bindings: bindings, rebind: rebind});
		}
		live = ui.label("");
		live.node.color = 0x9aa2b8ff;
		controls.add(live);
		reset = ui.button("Reset", "reset");
		backFromControls = ui.button("Back", "backFromControls");
		var buttons = Box.row();
		buttons.gap = ui.theme.gap;
		for (b in [reset, backFromControls]) {
			controls.adopt(b);
			buttons.add(b.box);
		}
		controls.content.add(buttons);

		levels = ui.panel("levels");
		list = ui.list([
			for (i in 0...30)
				'Level ${i + 1}: ${["The Belt", "Ice Field", "Debris", "The Rift", "Dark Side"][i % 5]}'
		], 6, "levels");
		start = ui.button("Start", "start");
		backFromLevels = ui.button("Back", "backFromLevels");
		levels.add(list);
		levels.adopt(start);
		levels.adopt(backFromLevels);
		var buttons = Box.row();
		buttons.gap = ui.theme.gap;
		buttons.add(start.box);
		buttons.add(backFromLevels.box);
		levels.content.add(buttons);
		bar = ui.progress(0);
		corner = ui.label("");
		corner.node.color = 0x9aa2b8ff;
		// The design: the panels centered, the bar along the bottom, the status in the corner.
		layout = Box.stack();
		layout.setSizing(Grow(1), Grow(1));
		for (panel in [main, settings, controls, levels])
			panel.box.setAnchor(Center, Center);
		main.box.setSizing(Fixed(360), Fit);
		settings.box.setSizing(Fixed(480), Fit);
		controls.box.setSizing(Fixed(640), Fit);
		levels.box.setSizing(Fixed(520), Fit);
		bar.box.setSizing(Fixed(400), Fixed(10));
		bar.box.setAnchor(Center, End, 0, -24);
		corner.box.setAnchor(End, End, -16, -48);
		for (w in [main, settings, controls, levels, bar, corner])
			layout.add(w.box);
		show("main");

		if (pilot != null)
			Storage.remove(actionsKey, _ -> Storage.remove(busesKey, _ -> loadSettings()));
		else
			loadSettings();
	}

	// The saved controls and buses, over the defaults; the sliders and the toggle set from the buses.
	function loadSettings():Void {
		actions.load(actionsKey, () -> loads++, message -> {
			trace('Controls not loaded: $message');
			loads++;
		});
		Audio.loadBuses(busesKey, () -> {
			for (pair in [
				{slider: master, bus: Audio.master},
				{slider: music, bus: Audio.music},
				{slider: effects, bus: Audio.effects}
			])
				pair.slider.value = Math.round(pair.bus.volume * 100);
			muteMusic.on = Audio.music.muted;
			loads++;
		}, message -> {
			trace('Volumes not loaded: $message');
			loads++;
		});
	}

	// A frame image for the panels' nine-slice: a light border, a darker inside, its corners cut.
	function panelImage():Texture2D {
		var size = 16, pixels = Bytes.alloc(size * size * 4);
		for (y in 0...size)
			for (x in 0...size) {
				var edge = x < 2 || y < 2 || x >= size - 2 || y >= size - 2,
					cut = (x < 2 || x >= size - 2) && (y < 2 || y >= size - 2);
				var at = (y * size + x) * 4, value = edge ? 255 : 150;
				pixels.set(at, value);
				pixels.set(at + 1, value);
				pixels.set(at + 2, value);
				pixels.set(at + 3, cut ? 0 : 255);
			}
		return Texture2D.fromRgba(Graphics.instance, size, size, pixels);
	}

	function show(which:String):Void {
		screen = which;
		main.visible = which == "main";
		settings.visible = which == "settings";
		controls.visible = which == "controls";
		levels.visible = which == "levels";
		ui.reset();
	}

	// The action's bindings as a remap screen shows them, joined by ", ".
	function describe(action:String):String
		return [for (b in actions.bindings(action)) Actions.describe(b)].join(", ");

	// A named value for the autopilot, and the final game it publishes.
	function probe(name:String):Dynamic
		return switch name {
			case "screen": screen;
			case "focus": ui.focusedName;
			case "loaded": loads == 2;
			case "jump": describe("jump");
			case "capturing": actions.capturing;
			case "jumpDown": actions.isDown("jump");
			case "masterVolume": Audio.master.volume;
			case "musicVolume": Audio.music.volume;
			case "effectsVolume": Audio.effects.volume;
			case "musicMuted": Audio.music.muted;
			default: throw 'Unknown probe ' + name;
		}

	// A slider moved: its bus at its level at once, saved once the pointer lets go.
	function setVolume(slider:Slider, bus:Bus):Void {
		if (!slider.changed)
			return;
		bus.volume = slider.value / 100;
		unsaved = true;
		effectsMoved = effectsMoved || slider == effects;
	}

	override public function frame(dt:Float):Void {
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		if (ui == null) {
			// The autopilot's script still loading.
			Graphics.beginFrame(width, height, 0x14161cff);
			Graphics.endFrame();
			return;
		}
		if (pilot != null && !pilot.done)
			pilot.advance(name -> probe(name));
		// The design for the window's shape, grown to its edges: the layout arranged into all that's visible.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		for (row in rows)
			row.bindings.text = actions.capturing && rebinding == row.action ? "Press a key or button..." : describe(row.action);
		Box.arrange(layout, vx, vy, vw, vh, batch.font);
		pointer.update();
		// While a rebind waits for its press, the screen waits too: the press is the binding's, not the menu's.
		if (!actions.capturing) {
			ui.update();
			// Asked, never told: what happened this frame.
			switch screen {
				case "main":
					if (play.clicked)
						status = 'Playing as ${name.text == "" ? "nobody" : name.text}, master ${master.value}%, music ${muteMusic.on ? "muted" : '${music.value}%'}';
					if (openSettings.clicked)
						show("settings");
					if (openControls.clicked)
						show("controls");
					if (openLevels.clicked)
						show("levels");
					if (quit.clicked || ui.backPressed && Host.canQuit())
						Host.quit();
				case "settings":
					setVolume(master, Audio.master);
					setVolume(music, Audio.music);
					setVolume(effects, Audio.effects);
					if (muteMusic.changed) {
						Audio.music.muted = muteMusic.on;
						status = 'Music ${muteMusic.on ? "muted" : "on"}';
						Audio.saveBuses(busesKey);
					}
					if (name.submitted)
						status = 'Hello, ${name.text}';
					if (back.clicked || ui.backPressed && !name.submitted && ui.focused != name)
						show("main");
				case "controls":
					for (row in rows)
						if (row.rebind.clicked)
							rebind(row);
					if (reset.clicked) {
						actions.reset();
						actions.save(actionsKey);
						status = "Controls reset";
					}
					if (backFromControls.clicked || ui.backPressed)
						show("main");
				case "levels":
					if (list.changed || list.activated || start.clicked) {
						var chosen = list.selectedIndex;
						status = chosen < 0 ? "Choose a level" : (list.activated || start.clicked ? "Starting " : "Chose ") + list.items[chosen];
					}
					if (backFromLevels.clicked || ui.backPressed)
						show("main");
			}
		}
		// A slider's change saved once it's let go (a drag ends; a key's step at once), the effect played at the effects bus's new level.
		if (unsaved && !ui.input.pointerDown) {
			unsaved = false;
			Audio.saveBuses(busesKey);
			if (effectsMoved && click != null)
				Audio.play(click);
			effectsMoved = false;
		}
		var move = Math.round(actions.axis("move") * 100) / 100;
		live.text = 'jump ${actions.isDown("jump") ? "down" : "up"}   move ${move}   fire ${actions.isDown("fire") ? "down" : "up"}';
		loading = (loading + dt * .2) % 1;
		bar.value = loading;
		corner.text = 'focus: ${ui.focusedName == "" ? "none" : ui.focusedName}${ui.capturingKeys ? " (keys)" : ""}';
		fps.update(dt, Time.frameCpu);

		Graphics.beginFrame(width, height, 0x14161cff);
		batch.begin(camera);
		stage.draw(batch, camera);
		batch.drawTextWrapped(status, vx + vw / 2, vy + vh - 80, 18, vw - 32, 0xc8d0e8ff, Center);
		batch.drawTextWrapped("pointer, arrows / Tab / Enter / Escape, or a pad", vx + vw / 2, vy + 40, 16, vw - 32, 0x7a8298ff, Center);
		// The frame rate in the window's own pixels, in the same batch.
		hud.setViewport(width, height);
		hud.pixels(Window.pixelRatio);
		batch.camera = hud;
		fps.draw(batch, 12, 10);
		batch.end();
		Graphics.endFrame();
		if (pilot != null && pilot.done && !published) {
			published = true;
			var game:Dynamic = {};
			for (name in PROBES)
				Reflect.setField(game, name, probe(name));
			TestHarness.publish({game: game, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	// Waits for the next press for the row's action: the row reads "Press a key or button..." until it's taken (then saved) or Escape
	// cancels.
	function rebind(row:{action:String, bindings:Label, rebind:Button}):Void {
		if (actions.capture(row.action, binding -> {
			actions.save(actionsKey);
			status = '${row.action}: ${describe(row.action)}';
		}, () -> status = "Rebind cancelled"))
			rebinding = row.action;
	}

	override public function cleanup():Void
		batch.destroy();
}
