import haxe.io.Bytes;
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

/** A game's menus (helix.ui): a main menu, settings (a toggle, a slider, a name typed in) and a scrolling list of levels, the main menu in a
	nine-slice panel, the others in the theme's rounded ones, every widget's corners rounded too, laid out in a 1280 x 720 design fitted to the
	window, used alike by the pointer, keys (arrows, Tab, Enter, Escape) and a pad (D-pad, South, East). Nothing is called back: each frame
	the example asks the widgets what happened. A progress bar fills; the status in the corner is anchored there. Escape on the main menu quits
	where quitting means anything. */
class App extends BaseApp {
	var stage = new Stage2D();
	var batch:Batch2D;
	var camera = new Camera2D();
	var hud = new Camera2D();
	var pointer:Pointer;
	var ui:Ui;
	var fps = new FpsOverlay();
	var layout:Box;
	var screen = "main";
	var status = "";
	var loading = 0.;
	// The screens' panels and widgets.
	var main:Panel;
	var settings:Panel;
	var levels:Panel;
	var play:Button;
	var openSettings:Button;
	var openLevels:Button;
	var quit:Button;
	var sound:Toggle;
	var volume:Slider;
	var name:TextField;
	var back:Button;
	var list:ListView;
	var start:Button;
	var backFromLevels:Button;
	var bar:ProgressBar;
	var corner:Label;

	override public function init():Void {
		Window.title = "HeliX ui";
		Window.requestSize(1000, 600);
		batch = new Batch2D();
		pointer = new Pointer(Input.instance);
		pointer.addStage2D(stage, camera);
		ui = new Ui(stage, camera, pointer, Input.instance);
		var frame = panelImage();
		main = ui.panel("main");
		main.setFrame(frame, 6, 6, 6, 6, 0x262c3cff);
		var title = ui.label("HeliX ui");
		title.node.textSize = 32;
		play = ui.button("Play");
		openSettings = ui.button("Settings");
		openLevels = ui.button("Levels");
		quit = ui.button("Quit");
		quit.enabled = Host.canQuit();
		for (w in [title, play, openSettings, openLevels, quit])
			main.add(w);
		settings = ui.panel("settings");
		sound = ui.toggle("Sound", true);
		volume = ui.slider("Volume", 0, 10, 7, 1);
		name = ui.textField("", "your name", 16);
		back = ui.button("Back");
		var heading = ui.label("Settings");
		heading.node.textSize = 26;
		for (w in [heading, sound, volume, name, back])
			settings.add(w);
		levels = ui.panel("levels");
		list = ui.list([
			for (i in 0...30)
				'Level ${i + 1}: ${["The Belt", "Ice Field", "Debris", "The Rift", "Dark Side"][i % 5]}'
		], 6);
		start = ui.button("Start");
		backFromLevels = ui.button("Back");
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
		for (panel in [main, settings, levels])
			panel.box.setAnchor(Center, Center);
		main.box.setSizing(Fixed(360), Fit);
		settings.box.setSizing(Fixed(480), Fit);
		levels.box.setSizing(Fixed(520), Fit);
		bar.box.setSizing(Fixed(400), Fixed(10));
		bar.box.setAnchor(Center, End, 0, -24);
		corner.box.setAnchor(End, End, -16, -48);
		for (w in [main, settings, levels, bar, corner])
			layout.add(w.box);
		show("main");
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
		levels.visible = which == "levels";
		ui.reset();
	}

	override public function frame(dt:Float):Void {
		var input = Input.instance;
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		// The design for the window's shape, grown to its edges: the layout arranged into all that's visible.
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(camera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth,
			vh = presentation.visibleHeight;
		Box.arrange(layout, vx, vy, vw, vh, batch.font);
		pointer.update();
		ui.update();
		// Asked, never told: what happened this frame.
		switch screen {
			case "main":
				if (play.clicked)
					status = 'Playing as ${name.text == "" ? "nobody" : name.text}, sound ${sound.on ? "on" : "off"}, volume ${volume.value}';
				if (openSettings.clicked)
					show("settings");
				if (openLevels.clicked)
					show("levels");
				if (quit.clicked || ui.backPressed && Host.canQuit())
					Host.quit();
			case "settings":
				if (sound.changed)
					status = 'Sound ${sound.on ? "on" : "off"}';
				if (volume.changed)
					status = 'Volume ${volume.value}';
				if (name.submitted)
					status = 'Hello, ${name.text}';
				if (back.clicked || ui.backPressed && !name.submitted && ui.focused != name)
					show("main");
			case "levels":
				if (list.changed || list.activated || start.clicked) {
					var chosen = list.selectedIndex;
					status = chosen < 0 ? "Choose a level" : (list.activated || start.clicked ? "Starting " : "Chose ") + list.items[chosen];
				}
				if (backFromLevels.clicked || ui.backPressed)
					show("main");
		}
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
	}

	override public function cleanup():Void
		batch.destroy();
}
