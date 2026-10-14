import haxe.io.Bytes;
import helix.app.BaseApp;
import helix.debug.FpsOverlay;
import helix.host.Services;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render2d.Texture2D;
import helix.scene.Pointer;
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

/** A game's menus (helix.ui): a main menu, settings (a toggle, a slider, a name typed in) and a scrolling list of levels, in nine-slice panels
	laid out in a 1280 x 720 design fitted to the window, used alike by the pointer, keys (arrows, Tab, Enter, Escape) and a pad (D-pad, South,
	East). Nothing is called back: each frame the example asks the widgets what happened. A progress bar fills; the status in the corner is
	anchored there. Escape on the main menu quits where quitting means anything. */
class App extends BaseApp {
	var services:Services;
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

	public function new(services:Services) {
		super();
		this.services = services;
	}

	override public function init():Void {
		services.window.setTitle("HeliX ui");
		services.window.setSize(1000, 600);
		batch = new Batch2D(services.graphics);
		pointer = new Pointer(services.input);
		pointer.addStage2D(stage, camera);
		ui = new Ui(stage, camera, pointer, services.input);
		var frame = panelImage();
		main = ui.panel("main");
		main.setFrame(frame, 6, 6, 6, 6, 0x262c3cff);
		var title = ui.label("HeliX ui");
		title.getNode().setTextSize(32);
		play = ui.button("Play");
		openSettings = ui.button("Settings");
		openLevels = ui.button("Levels");
		quit = ui.button("Quit");
		quit.setEnabled(services.canQuit());
		for (w in [title, play, openSettings, openLevels, quit])
			main.add(w);
		settings = ui.panel("settings");
		settings.setFrame(frame, 6, 6, 6, 6, 0x262c3cff);
		sound = ui.toggle("Sound", true);
		volume = ui.slider("Volume", 0, 10, 7, 1);
		name = ui.textField("", "your name", 16);
		back = ui.button("Back");
		var heading = ui.label("Settings");
		heading.getNode().setTextSize(26);
		for (w in [heading, sound, volume, name, back])
			settings.add(w);
		levels = ui.panel("levels");
		levels.setFrame(frame, 6, 6, 6, 6, 0x262c3cff);
		list = ui.list([
			for (i in 0...30) 'Level ${i + 1}: ${["The Belt", "Ice Field", "Debris", "The Rift", "Dark Side"][i % 5]}'
		], 6);
		start = ui.button("Start");
		backFromLevels = ui.button("Back");
		levels.add(list).adopt(start).adopt(backFromLevels);
		levels.getContent().add(Box.row().setGap(ui.getTheme().gap).add(start.getBox()).add(backFromLevels.getBox()));
		bar = ui.progress(0);
		corner = ui.label("");
		corner.getNode().setColor(0x9aa2b8ff);
		// The design: the panels centered, the bar along the bottom, the status in the corner.
		layout = Box.stack()
			.setSize(Grow(1), Grow(1))
			.add(main.getBox().setSize(Fixed(360), Fit).setAnchor(Center, Center))
			.add(settings.getBox().setSize(Fixed(480), Fit).setAnchor(Center, Center))
			.add(levels.getBox().setSize(Fixed(520), Fit).setAnchor(Center, Center))
			.add(bar.getBox().setSize(Fixed(400), Fixed(10)).setAnchor(Center, End, 0, -24))
			.add(corner.getBox().setAnchor(End, End, -16, -48));
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
		return Texture2D.fromRgba(services.graphics, size, size, pixels);
	}

	function show(which:String):Void {
		screen = which;
		main.setVisible(which == "main");
		settings.setVisible(which == "settings");
		levels.setVisible(which == "levels");
		ui.reset();
	}

	override public function frame(dt:Float):Void {
		var input = services.input;
		var width = services.window.getFramebufferWidth(),
			height = services.window.getFramebufferHeight();
		camera.setViewport(width, height);
		// The 1280 x 720 design, fitted into the window.
		camera.fit(0, 0, 1280, 720);
		Box.arrange(layout, 0, 0, 1280, 720, batch.getFont());
		pointer.update();
		ui.update();
		// Asked, never told: what happened this frame.
		switch screen {
			case "main":
				if (play.isClicked())
					status = 'Playing as ${name.getText() == "" ? "nobody" : name.getText()}, sound ${sound.getValue() ? "on" : "off"}, volume ${volume.getValue()}';
				if (openSettings.isClicked())
					show("settings");
				if (openLevels.isClicked())
					show("levels");
				if (quit.isClicked() || ui.isBackPressed() && services.canQuit())
					services.quit();
			case "settings":
				if (sound.isChanged())
					status = 'Sound ${sound.getValue() ? "on" : "off"}';
				if (volume.isChanged())
					status = 'Volume ${volume.getValue()}';
				if (name.isSubmitted())
					status = 'Hello, ${name.getText()}';
				if (back.isClicked() || ui.isBackPressed() && !name.isSubmitted() && ui.getFocused() != name)
					show("main");
			case "levels":
				if (list.isChanged() || list.isActivated() || start.isClicked()) {
					var chosen = list.getSelected();
					status = chosen < 0 ? "Choose a level" : (list.isActivated()
						|| start.isClicked() ? "Starting " : "Chose ") + list.getItems()[chosen];
				}
				if (backFromLevels.isClicked() || ui.isBackPressed())
					show("main");
		}
		loading = (loading + dt * .2) % 1;
		bar.setValue(loading);
		corner.setText('focus: ${ui.getFocusedName() == "" ? "none" : ui.getFocusedName()}${ui.hasKeys() ? " (keys)" : ""}');
		fps.update(dt, services.getFrameCpu());

		services.graphics.beginFrame(width, height, 0x14161cff);
		batch.begin(camera);
		stage.draw(batch, camera);
		Text2D.draw(batch, status, 640, 650, 18, 0xc8d0e8ff, Center);
		Text2D.draw(batch, "pointer, arrows / Tab / Enter / Escape, or a pad", 640, 24, 16, 0x7a8298ff, Center);
		// The frame rate in the window's own pixels, in the same batch.
		hud.setViewport(width, height);
		hud.pixels(services.window.getPixelRatio());
		batch.setCamera(hud);
		fps.draw(batch, 12, 10);
		batch.end();
		services.graphics.endFrame();
	}

	override public function cleanup():Void
		batch.destroy();
}
