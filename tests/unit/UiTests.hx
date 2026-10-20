import Render2DTests.CountingGraphics;
import helix.render2d.Font2D;
import helix.render2d.Shape2D;
import helix.render2d.Text2D;
import helix.ui.Layout2D;
import helix.ui.Layout2D.Layout2DDirection;
import helix.ui.Layout2D.Sizing;

/** The UI's layout: rows, columns and stacks, sizes fixed, fitted, growing and shared, padding, gaps, alignment and anchors, and the nodes
	placed by their pivots; the widgets used by keys, the pointer and typing; the color picker's HSV, hex and input. */
class UiTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	public static function main():Void {
		var font = Font2D.builtIn(new CountingGraphics());
		layout(font);
		widgets(font);
		typing(font);
		tiles(font);
		hsv();
		colors(font);
		theming(font);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// Tiles in a grid (rows of a column), with a button under them: arrows and the D-pad move focus across and down the grid on screen, Tab in
	// the order made; a tile is clicked or activated, marked selected, and its picture arrives later.
	static function tiles(font:Font2D):Void {
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		camera.setViewport(800, 600);
		camera.pixels(1);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new helix.ui.Ui(stage, camera, pointer, input);
		var grid = Layout2D.column(), cells = [];
		grid.gap = 8;
		for (r in 0...2) {
			var row = Layout2D.row();
			row.gap = 8;
			for (c in 0...3) {
				var tile = ui.tile(null, 'Part ${r * 3 + c}', 64);
				cells.push(tile);
				row.add(tile.layout);
			}
			grid.add(row);
		}
		var done = ui.button("Done");
		grid.add(done.layout);
		var layout = holding(sized(Grow(1), Grow(1)), [grid]);
		grid.setAnchor(Center, Center);
		var batch = new helix.render2d.Batch2D(new CountingGraphics());
		function frame(?keys:Array<helix.input.Key>, ?x:Float, ?y:Float, ?down:Bool):Void {
			input.endFrame();
			if (keys != null)
				for (k in keys) {
					input.keyEvent(k, true);
					input.keyEvent(k, false);
				}
			if (x != null)
				input.pointerEvent(x, y, down == true);
			Layout2D.arrange(layout, 0, 0, 800, 600, font);
			batch.begin(camera);
			stage.draw(batch, camera);
			batch.end();
			pointer.update();
			ui.update();
		}
		frame();
		frame([Down]);
		check(ui.focused == cells[0], "Down: the first tile");
		frame([Right]);
		frame([Down]);
		check(ui.focused == cells[4], "Right then Down: across the row, then down the column, on screen");
		frame([Left]);
		frame([Up]);
		check(ui.focused == cells[0], "Left then Up: back");
		frame([Down]);
		frame([Down]);
		check(ui.focused == done, "Down from the grid's bottom row: the button under it");
		frame([Up]);
		check(ui.focused == cells[3] || ui.focused == cells[4], "Up from the button: back into the grid's bottom row");
		frame([Tab]);
		check(ui.focused == cells[4] || ui.focused == cells[5], "Tab: the next in the order made");
		var middle = cells[1].layout;
		frame(middle.x + middle.width / 2, middle.y + middle.height / 2, true);
		frame(middle.x + middle.width / 2, middle.y + middle.height / 2, false);
		check(cells[1].clicked && ui.focused == cells[1], "A tile is clicked, focus with it");
		for (t in cells)
			t.selected = t == cells[1];
		frame();
		check(cells[1].selected && !cells[0].selected && !cells[1].clicked, "The game marks the chosen tile selected; a click lasts a frame");
		frame([Enter]);
		check(cells[1].clicked, "Enter activates the focused tile");
		check(cells[2].texture == null, "A tile without its picture yet");
		var picture = helix.render2d.Texture2D.fromRgba(new CountingGraphics(), 2, 2, haxe.io.Bytes.alloc(16));
		cells[2].texture = picture;
		check(cells[2].texture == picture && cells[2].caption == "Part 2", "shows it once it comes");
	}

	// The theme changed after the widgets were made: each kind takes its colors, corners and sizes from it at the next update, and its layouts'
	// once arranged again; a layout a game sized itself, and a label's own size and color, are kept; another theme assigned is followed alike.
	static function theming(font:Font2D):Void {
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		camera.setViewport(1000, 1600);
		camera.pixels(1);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new helix.ui.Ui(stage, camera, pointer, input);
		var panel = ui.panel(),
			title = ui.label("Title"),
			plain = ui.label("Plain"),
			play = ui.button("Play"),
			sound = ui.toggle("Sound", true),
			volume = ui.slider("Volume", 0, 10, 5, 1),
			bar = ui.progress(.5),
			fixedBar = ui.progress(.5),
			name = ui.textField("abc"),
			tile = ui.tile(null, "Part", 64),
			levels = ui.list(["One", "Two", "Three"], 3),
			picker = ui.colorPicker(0xff0000ff, true, "tint"),
			same = ui.button("Same"),
			wide = ui.button("Wide"),
			kept = ui.panel();
		title.textSize = 30;
		// Values a game set equal to the theme's: still the game's, kept when the theme changes (no guessing from the value); a game's width
		// leaves the height the theme's.
		same.layout.setSizing(Fit, Fixed(40));
		same.layout.setPadding(20, 0, 20, 0);
		wide.layout.widthSizing = Fixed(120);
		kept.content.gap = 8;
		kept.content.setPadding(10, 10, 10, 10);
		title.color = 0x123456ff;
		volume.valueShown = true;
		fixedBar.layout.setSizing(Grow(1), Fixed(10));
		for (w in [title, plain, play, sound, volume, bar, fixedBar, name, tile, levels, same, wide])
			panel.add(w);
		// The picker in a row, so it keeps its own width (the column would stretch it across).
		var pickerRow = Layout2D.row();
		panel.adopt(picker);
		pickerRow.add(picker.layout);
		panel.content.add(pickerRow);
		panel.layout.setSizing(Fixed(600), Fit);
		var layout = holding(sized(Grow(1), Grow(1)), [panel.layout]);
		var batch = new helix.render2d.Batch2D(new CountingGraphics());
		function frame(?keys:Array<helix.input.Key>):Void {
			input.endFrame();
			if (keys != null)
				for (k in keys) {
					input.keyEvent(k, true);
					input.keyEvent(k, false);
				}
			Layout2D.arrange(layout, 0, 0, 1000, 1600, font);
			batch.begin(camera);
			stage.draw(batch, camera);
			batch.end();
			pointer.update();
			ui.update();
		}
		frame();
		frame([Down]);
		var theme = ui.theme;
		var playFace:Shape2D = @:privateAccess play.face,
			playLabel:Text2D = @:privateAccess play.label,
			panelFace:Shape2D = @:privateAccess panel.rectangle,
			listFace:Shape2D = @:privateAccess levels.face,
			listRow:Shape2D = @:privateAccess levels.rows[0].face,
			listText:Text2D = @:privateAccess levels.rows[0].text,
			track:Shape2D = @:privateAccess volume.track,
			knob:Shape2D = @:privateAccess volume.knob.disc,
			checkMark:Shape2D = @:privateAccess sound.mark,
			barTrack:Shape2D = @:privateAccess bar.track,
			fieldText:Text2D = @:privateAccess name.textNode,
			caret:Shape2D = @:privateAccess name.caret,
			tileEdge:Shape2D = @:privateAccess tile.edge,
			hueKnob:Shape2D = @:privateAccess picker.hueKnob.disc,
			swatch:Shape2D = @:privateAccess picker.swatchColor,
			ring:Shape2D = @:privateAccess ui.ring;
		check(playFace.cornerRadius == 8
			&& listFace.cornerRadius == 0
			&& play.layout.height == 40
			&& levels.layout.height == 3 * 40 + 8,
			"The theme's look to start");
		var wasPadding = panel.content.paddingLeft,
			wasToggle = sound.layout.height,
			wasSized = fixedBar.layout.height,
			wasPicker = picker.layout.width;
		theme.faceColor = 0x102030ff;
		theme.panelColor = 0x405060ff;
		theme.accentColor = 0x00ff00ff;
		theme.focusColor = 0xff00ffff;
		theme.focusWidth = 3;
		theme.cornerRadius = 3;
		theme.listCornerRadius = 12;
		theme.listRowCornerRadius = 5;
		theme.listRowHeight = 30;
		theme.listPadding = 6;
		theme.trackThickness = 10;
		theme.handleSize = 20;
		theme.textSize = 24;
		theme.padding = 14;
		theme.gap = 12;
		theme.widgetHeight = 50;
		theme.colorPickerWidth = 260;
		frame();
		check(playFace.color == 0x102030ff && playFace.cornerRadius == 3 && playLabel.textSize == 24,
			"A button: its face's color and corners, its text's size");
		check(panelFace.color == 0x405060ff && panelFace.cornerRadius == 3, "A panel: its color and corners");
		check(listFace.color == 0x102030ff && listFace.cornerRadius == 12 && listRow.cornerRadius == 5 && listText.textSize == 24,
			"A list: its color, its corners, its rows' corners and text");
		check(track.color == 0x102030ff
			&& track.cornerRadius == 5
			&& @:privateAccess volume.fill.color == 0x00ff00ff
			&& knob.radius == 10,
			"A slider: its track's color and round ends, its fill, its handle's size");
		check(checkMark.color == 0x00ff00ff && checkMark.width == 20 && checkMark.cornerRadius == 3 / 4, "A toggle: its mark's color, size and corners");
		check(barTrack.color == 0x102030ff && barTrack.cornerRadius == 3, "A progress bar: its color and corners");
		check(fieldText.textSize == 24 && caret.height == 28 && caret.color == 0xff00ffff, "A text field: its text's size, the caret's");
		check(tileEdge.color == 0x00ff00ff && tileEdge.cornerRadius == 5 && @:privateAccess tile.label.textSize == 24 * .8, "A tile: its edge, its caption");
		check(hueKnob.radius == 10
			&& swatch.radius == (10 + 1.5) * 2 + theme.gap / 4 && @:privateAccess picker.caption.textSize == 24 * .6,
			"A color picker: its handles, its swatch and caption");
		check(ring.visible && ring.color == 0xff00ffff && ring.outline == 3, "The focus ring: its color and width");
		check(@:privateAccess title.node.textSize == 30
			&& @:privateAccess title.node.color == 0x123456ff
			&& @:privateAccess plain.node.textSize == 24
			&& @:privateAccess plain.node.color == theme.textColor,
			"A label: its own size and color kept, the theme's otherwise");
		frame();
		check(play.layout.height == 50 && name.layout.height == 50 && volume.layout.height == 50 && sound.layout.height == 50 && wasToggle == 40,
			"Arranged again: the widgets' heights");
		check(levels.layout.height == 3 * 30 + 6 * 2 && listRow.height == 30, "A list's rows' height and its padding");
		check(panel.content.paddingLeft == 14 && wasPadding == 10 && play.layout.paddingLeft == 28 && name.layout.paddingLeft == 14,
			"Padding: a panel's, a button's, a field's");
		check(panel.content.gap == 12 && @:privateAccess sound.row.gap == 12, "Gaps never set follow the theme");
		check(same.layout.height == 40 && same.layout.paddingLeft == 20 && kept.content.gap == 8 && kept.content.paddingLeft == 10,
			"Sizing, padding and a gap the game set, equal to the theme's then, are kept");
		check(wide.layout.widthSizing.match(Fixed(120))
			&& wide.layout.height == 50, "A width the game set is kept, the height still the theme's");
		check(@:privateAccess volume.trackLayout.height == 10 && @:privateAccess volume.fill.height == 10, "A slider's track and fill as thick");
		check(bar.layout.height == 24 * .75 && fixedBar.layout.height == 10 && wasSized == 10, "A progress bar's height; one a game sized keeps its own");
		check(wasPicker == 200 && picker.layout.width == 260 && @:privateAccess picker.hueLayout.height == (10 + 1.5) * 2,
			"A color picker: its width, its bars' rows");
		check(picker.textField.layout.height == 24 + 7
			&& picker.formatButton.layout.height == 24 + 7
			&& picker.textField.layout.paddingLeft == 7,
			"Its field's and button's height, from the text's, the field's padding its own");
		check(Type.enumEq(picker.textField.layout.widthSizing, Fixed(@:privateAccess picker.fieldWidth))
			&& Type.enumEq(picker.textField.layout.heightSizing, Fixed(24 + 7)),
			"Its field's sizing the picker's, not the theme's (a field grows, as tall as a widget)");
		frame();
		check(@:privateAccess picker.squareLayout.height == 260, "Its square as tall as its new width");
		// Another theme assigned: followed alike; null is the defaults.
		var other = new helix.ui.Theme();
		other.cornerRadius = 0;
		other.listRowHeight = 20;
		ui.theme = other;
		frame();
		frame();
		check(playFace.cornerRadius == 0 && play.layout.height == 40 && levels.layout.height == 3 * 20 + 8, "Another theme: followed");
		ui.theme = null;
		frame();
		check(ui.theme != null && playFace.cornerRadius == 8, "Null: a new theme, the defaults");
	}

	// A layout laid out direction's way (a stack when not given), sized width x height.
	static function sized(width:Sizing, height:Sizing, ?direction:Layout2DDirection):Layout2D {
		var made = new Layout2D(direction != null ? direction : Stack);
		made.setSizing(width, height);
		return made;
	}

	static function fixed(w:Float, h:Float):Layout2D
		return sized(Fixed(w), Fixed(h));

	// Adds children to parent in order; returns parent.
	static function holding(parent:Layout2D, children:Array<Layout2D>):Layout2D {
		for (c in children)
			parent.add(c);
		return parent;
	}

	static function layout(font:Font2D):Void {
		// A row: fixed children, a gap between, padding around; it fits them.
		var a = fixed(50, 20), b = fixed(50, 30), c = fixed(50, 20);
		var row = holding(Layout2D.row(), [a, b, c]);
		row.setPadding(5, 5, 5, 5);
		row.gap = 10;
		Layout2D.arrange(row, 0, 0, 1000, 1000, font);
		check(row.width == 180 && row.height == 40 && a.x == 5 && b.x == 65 && c.x == 125 && a.y == 5, "A row fits its children, gaps and padding");
		// Growing children share what's left by weight; a share of the parent; the main axis centered when none grows.
		var fix = fixed(100, 10),
			one = sized(Grow(1), Fixed(10)),
			two = sized(Grow(2), Fixed(10));
		var grow = holding(sized(Fixed(400), Fixed(10), Row), [fix, one, two]);
		Layout2D.arrange(grow, 0, 0, 1000, 1000, font);
		check(near(one.width, 100) && near(two.width, 200) && near(two.x, 200), "Growing children share the room left by weight");
		var half = sized(Percent(.5), Fixed(10)),
			centred = holding(sized(Fixed(400), Fixed(10), Row), [half]);
		centred.setAlign(Center, Start);
		Layout2D.arrange(centred, 0, 0, 1000, 1000, font);
		check(half.width == 200 && half.x == 100, "A share of the parent, centred when nothing grows");
		// A column stretching its children across.
		var wide = sized(Fit, Fixed(10)),
			column = holding(sized(Fixed(300), Fit, Column), [wide]);
		column.setAlign(Start, Stretch);
		Layout2D.arrange(column, 0, 0, 1000, 1000, font);
		check(wide.width == 300, "Stretch fills across a column");
		// A stack: anchored to a corner and the middle, moved by offsets.
		var corner = fixed(40, 20), middle = fixed(40, 20);
		corner.setAnchor(End, End, -10, -10);
		middle.setAnchor(Center, Center);
		var screen = holding(sized(Grow(1), Grow(1)), [corner, middle]);
		Layout2D.arrange(screen, 0, 0, 800, 600, font);
		check(corner.x == 750 && corner.y == 570 && middle.x == 380 && middle.y == 290, "Anchored to a corner and the middle");
		check(corner.anchorX == End && corner.anchorOffsetY == -10 && screen.gap == 0 && column.crossAlign == Stretch, "A layout answers what it was set to");
		// Nodes placed by their pivots, sprites and rectangles sized; a text fitted to its measure.
		var panel = Shape2D.rectangle(1, 1),
			dot = Shape2D.circle(5),
			label = new Text2D("PLAY", 20, -1, Center);
		var panelLayout = Layout2D.of(panel),
			dotLayout = Layout2D.of(dot),
			labelLayout = Layout2D.of(label);
		panelLayout.setSizing(Fit, Fixed(30));
		var nodes = holding(sized(Fixed(200), Fit, Column), [panelLayout, dotLayout, labelLayout]);
		nodes.setAlign(Start, Stretch);
		nodes.gap = 4;
		Layout2D.arrange(nodes, 10, 10, 1000, 1000, font);
		check(panel.x == 10 && panel.y == 10 && panel.width == 200 && panel.height == 30, "A rectangle at its corner, sized");
		check(dot.x == 110 && dot.y == 49 && dotLayout.height == 10, "A circle at its center (stretched across: the column's middle)");
		check(labelLayout.height == 20 && label.x == 110 && label.y == 58, "A centred text at its middle, as tall as its size");
		var fitted = holding(Layout2D.row(), [Layout2D.of(new Text2D("PLAY", 20))]);
		Layout2D.arrange(fitted, 0, 0, 1000, 1000, font);
		check(near(fitted.width, font.measure("PLAY", 20)), "A text fits its measure");
	}

	// The widgets used by keys, the pointer and a pad's absence: focus order, the ring, activation, the held-key guard, back, a toggle, a
	// slider by keys and by a drag, a list by keys, the wheel and clicks, a disabled button.
	static function widgets(font:Font2D):Void {
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		camera.setViewport(800, 600);
		camera.pixels(1);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new helix.ui.Ui(stage, camera, pointer, input);
		var panel = ui.panel(),
			play = ui.button("Play"),
			sound = ui.toggle("Sound", true),
			volume = ui.slider("Volume", 0, 10, 5, 1),
			levels = ui.list([for (i in 0...20) 'Level ${i + 1}'], 4),
			off = ui.button("Locked");
		off.enabled = false;
		for (w in [play, sound, volume, levels, off])
			panel.content.add(w.layout);
		panel.layout.setSizing(Fixed(400), Fit);
		panel.layout.setAnchor(Center, Center);
		var layout = holding(sized(Grow(1), Grow(1)), [panel.layout]);
		var batch = new helix.render2d.Batch2D(new CountingGraphics());
		function frame(?keys:Array<helix.input.Key>, ?x:Float, ?y:Float, ?down:Bool, wheel = 0.):Void {
			input.endFrame();
			if (keys != null)
				for (k in keys) {
					input.keyEvent(k, true);
					input.keyEvent(k, false);
				}
			if (x != null)
				input.pointerEvent(x, y, down == true);
			if (wheel != 0)
				input.wheelEvent(0, wheel);
			Layout2D.arrange(layout, 0, 0, 800, 600, font);
			batch.begin(camera);
			stage.draw(batch, camera);
			batch.end();
			pointer.update();
			ui.update();
		}
		frame();
		check(ui.focused == null && !ui.capturingKeys, "Nothing focused to start");
		frame([Down]);
		check(ui.focused == play && ui.capturingKeys && ui.focusedName == "Play", "Down: the first button, its name published");
		frame([Down]);
		frame([Enter]);
		check(ui.focused == sound && sound.changed && !sound.on, "Enter switches the toggle");
		frame([Down]);
		frame([Right]);
		check(ui.focused == volume && volume.value == 6 && volume.changed, "Right steps the slider, focus kept");
		frame([Left, Left]);
		check(volume.value == 5, "Left steps back (two presses in a frame are one: frame edges)");
		frame([Down]);
		frame([Down]);
		frame([Down]);
		check(ui.focused == levels && levels.selectedIndex == 1, "Up and Down choose in a focused list");
		frame([Tab]);
		check(ui.focused == play, "Tab leaves the list; the disabled button is skipped, focus wraps");
		frame([Enter]);
		check(play.clicked, "Enter activates the focused button");
		// The pointer: hovering hides the ring and hands back the keys; a click on a button.
		var bx = play.layout.x + 20, by = play.layout.y + 10;
		frame(bx, by, false);
		check(!ui.capturingKeys, "The pointer moving hands back the keys");
		frame(bx, by, true);
		frame(bx, by, false);
		check(play.clicked, "A click on the button");
		var ox = off.layout.x + 10, oy = off.layout.y + 10;
		frame(ox, oy, true);
		frame(ox, oy, false);
		check(!off.clicked, "A disabled button isn't clicked");
		// A drag along the slider's track to its end.
		var sx = volume.layout.x + 5,
			sy = volume.layout.y + volume.layout.height / 2;
		frame(sx, sy, true);
		frame(volume.layout.x + volume.layout.width + 50, sy, true);
		check(volume.value == 10, "Dragged to the end of the track: the most");
		frame(sx, sy, false);
		// The list: the wheel scrolls it; a click chooses the row under the pointer, again activates it.
		var lx = levels.layout.x + 30, ly = levels.layout.y + 10;
		frame(lx, ly, false, -2);
		frame(lx, ly, true);
		frame(lx, ly, false);
		check(levels.selectedIndex == 2 && levels.changed, "Scrolled two rows by the wheel, the top row now the third");
		frame(lx, ly, true);
		frame(lx, ly, false);
		check(levels.activated, "Clicked again: activated");
		// A new screen: Enter held across it does nothing until let go; Escape is back.
		input.keyEvent(Enter, true);
		ui.reset();
		ui.focused = play;
		frame();
		input.keyEvent(Enter, false);
		input.keyEvent(Enter, true);
		frame();
		check(!play.clicked, "A key held into a new screen does nothing");
		input.keyEvent(Enter, false);
		frame();
		frame([Enter]);
		check(play.clicked, "Pressed afresh, it does");
		frame([Escape]);
		check(ui.backPressed, "Escape is back");
		// Used by name, as a test or an autopilot does: at the next update, when shown and usable.
		check(ui.press("Play") && !play.clicked, "Pressed by name; it takes at the next update");
		frame();
		check(play.clicked && ui.focused == play, "Clicked by name, focus with it");
		check(!ui.press("Locked") && !ui.press("Nothing"), "A disabled widget, or none of that name, isn't pressed");
	}

	// A text field: focused by a click, then typed in (spaces typed, not activating), Backspace, Enter, its limit; the keys the UI's meanwhile.
	static function typing(font:Font2D):Void {
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		camera.setViewport(800, 600);
		camera.pixels(1);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new helix.ui.Ui(stage, camera, pointer, input),
			name = ui.textField("", "your name", 8);
		var layout = holding(sized(Fixed(300), Fit, Column), [name.layout]);
		var batch = new helix.render2d.Batch2D(new CountingGraphics());
		function frame(?typed:String, ?key:helix.input.Key, ?x:Float, ?y:Float, ?down:Bool):Void {
			input.endFrame();
			if (typed != null)
				input.textEvent(typed);
			if (key != null) {
				input.keyEvent(key, true);
				input.keyEvent(key, false);
			}
			if (x != null)
				input.pointerEvent(x, y, down == true);
			Layout2D.arrange(layout, 0, 0, 800, 600, font);
			batch.begin(camera);
			stage.draw(batch, camera);
			batch.end();
			pointer.update();
			ui.update();
		}
		frame();
		frame(20, 10, true);
		frame(20, 10, false);
		check(ui.focused == name && ui.capturingKeys, "A click focuses the field; the UI has the keys though the pointer gave focus");
		check(input.textEntry, "Typed text is asked for while the field has focus");
		frame("ab c");
		check(name.text == "ab c" && name.changed, "Typed, a space among it");
		frame(" ", Space);
		check(name.text == "ab c " && !name.submitted, "Space types, not activates");
		frame(Backspace);
		frame("defghijk");
		check(name.text == "ab cdefg", "Backspace takes one off; typing stops at the limit: " + name.text);
		frame(Enter);
		check(name.submitted, "Enter submits");
		ui.reset();
		check(!input.textEntry, "A new screen lets typed text go");
	}

	// HSV to RGBA and back at the edges: the primaries and secondaries at their sixths, black, white and greys, every 8-bit color of a sweep
	// back as it went in, and hex read in its forms and refused in others.
	static function hsv():Void {
		var C = helix.ui.ColorPicker;
		check(C.fromHsv(0, 1, 1) == 0xff0000ff && C.fromHsv(1, 1, 1) == 0xff0000ff, "Hue 0 and 1: red");
		check(C.fromHsv(1 / 6, 1, 1) == 0xffff00ff
			&& C.fromHsv(2 / 6, 1, 1) == 0x00ff00ff
			&& C.fromHsv(3 / 6, 1, 1) == 0x00ffffff
			&& C.fromHsv(4 / 6, 1, 1) == 0x0000ffff
			&& C.fromHsv(5 / 6, 1, 1) == 0xff00ffff,
			"The sixths: yellow, green, cyan, blue, magenta");
		check(C.fromHsv(.3, 0, 1) == 0xffffffff && C.fromHsv(.3, .7, 0) == 0x000000ff && C.fromHsv(.3, 0, .5, 0x80) == 0x80808080,
			"White, black and a grey whatever the hue; alpha as given");
		check(C.fromHsv(-1, 2, 2, 300) == 0xff0000ff && C.fromHsv(0, 1, 1, -5) == 0xff000000, "Out of range clamped");
		// Round trips: every 8-bit color of a sweep comes back from its HSV as it went in.
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		var ui = new helix.ui.Ui(stage, camera, new helix.scene.Pointer(input), input), picker = ui.colorPicker(0x000000ff),
			opaque = ui.colorPicker(0x123456ff, false), wrong = 0;
		var r = 0;
		while (r < 256) {
			var g = 0;
			while (g < 256) {
				var b = 0;
				while (b < 256) {
					var c = (r << 24) | (g << 16) | (b << 8) | ((r + g * 3 + b) & 255);
					picker.color = c;
					if (picker.color != c || C.fromHsv(picker.hue, picker.saturation, picker.brightness, c & 255) != c)
						wrong++;
					b += b == 0 || b == 254 ? 1 : 17;
				}
				g += g == 0 || g == 254 ? 1 : 17;
			}
			r += r == 0 || r == 254 ? 1 : 17;
		}
		check(wrong == 0, 'Every color of the sweep back as it went in ($wrong not)');
		// The hue kept through grey and black, the saturation through black.
		picker.color = 0x3366ccff;
		var hue = picker.hue;
		picker.color = 0x808080ff;
		check(near(picker.hue, hue) && picker.saturation == 0 && picker.color == 0x808080ff, "A grey keeps the hue");
		picker.color = 0x3366ccff;
		var saturation = picker.saturation;
		picker.color = 0x000000ff;
		check(near(picker.hue, hue) && near(picker.saturation, saturation) && picker.brightness == 0, "Black keeps the hue and saturation");
		picker.brightness = 0xcc / 255;
		check(picker.color == 0x3366ccff, "Brightened again: the same color");
		picker.hue = 1;
		picker.saturation = 1;
		picker.brightness = 1;
		picker.color = 0xff0000ff;
		check(picker.hue == 1, "Red assigned at hue 1 stays at 1 (the top of the bar), not 0");
		check(opaque.color == 0x123456ff, "An opaque picker");
		opaque.color = 0x12345600;
		check(opaque.color == 0x123456ff, "Without alpha, alpha is 0xff whatever is assigned");
		// Hex.
		check(C.parseHex("ff8800cc") == 0xff8800cc && C.parseHex("#FF8800") == 0xff8800ff && C.parseHex(" #aBcDeF12 ") == 0xabcdef12,
			"Hex: RRGGBBAA, RRGGBB as opaque, #, either case, spaces around");
		check(C.parseHex("ff880") == null && C.parseHex("ff8800c") == null && C.parseHex("gg8800") == null && C.parseHex("") == null
			&& C.parseHex("##ff8800") == null && C.parseHex("ff8800ccdd") == null,
			"Hex: wrong lengths and digits refused");
		check(C.formatHex(0xff8800cc, true) == "ff8800cc" && C.formatHex(0x0a0b0cff, false) == "0a0b0c", "Hex written lowercase");
		// Decimal channels.
		check(C.parseRgba("255 136 0 204") == 0xff8800cc
			&& C.parseRgba("255,136,0") == 0xff8800ff
			&& C.parseRgba(" 1 , 2,3 ,  4 ") == 0x01020304
			&& C.parseRgba("0 0 0 0") == 0
			&& C.parseRgba("007 08 9") == 0x070809ff,
			"RGBA: four or three channels apart by spaces or a comma, spaces around");
		check(C.parseRgba("256 0 0") == null && C.parseRgba("1 2") == null && C.parseRgba("1 2 3 4 5") == null && C.parseRgba("1,,2,3") == null
			&& C.parseRgba(",1 2 3") == null && C.parseRgba("1 2 3,") == null && C.parseRgba("1 2 3a") == null && C.parseRgba("1 2 -3") == null
			&& C.parseRgba("0001 2 3") == null && C.parseRgba("") == null && C.parseRgba("1.5 2 3") == null,
			"RGBA: out of range, too few or many channels, doubled or loose commas, other characters refused");
		check(C.formatRgba(0xff8800cc, true) == "255 136 0 204"
			&& C.formatRgba(0x0a0b0cff, false) == "10 11 12", "RGBA written apart by spaces");
	}

	// A color picker in a panel: as wide as the panel's column, its square edge to edge and as tall, the strip and the field's row under it;
	// dragged in its square, along its bars, past their ends and through black (the hue kept); its parts stepped through by Enter and nudged
	// by the arrows, then let go so the arrows move focus again; hex typed in its field, refused text marked and changing nothing, the field
	// showing the color once left; the format cycled by its button (clicked, pressed by name, activated) and decimal channels typed; disabled.
	static function colors(font:Font2D):Void {
		var input = new helix.input.InputState(),
			stage = new helix.render2d.Stage2D(),
			camera = new helix.render2d.Camera2D();
		camera.setViewport(800, 900);
		camera.pixels(1);
		var pointer = new helix.scene.Pointer(input);
		pointer.addStage2D(stage, camera);
		var ui = new helix.ui.Ui(stage, camera, pointer, input);
		var panel = ui.panel(),
			above = ui.button("Above"),
			picker = ui.colorPicker(0xff0000ff, true, "tint"),
			below = ui.button("Below");
		for (w in [above, picker, below])
			panel.add(w);
		panel.layout.setSizing(Fixed(500), Fit);
		var layout = holding(sized(Grow(1), Grow(1)), [panel.layout]);
		var batch = new helix.render2d.Batch2D(new CountingGraphics());
		function frame(?keys:Array<helix.input.Key>, ?x:Float, ?y:Float, ?down:Bool, ?typed:String):Void {
			input.endFrame();
			if (keys != null)
				for (k in keys) {
					input.keyEvent(k, true);
					input.keyEvent(k, false);
				}
			if (typed != null)
				input.textEvent(typed);
			if (x != null)
				input.pointerEvent(x, y, down == true);
			Layout2D.arrange(layout, 0, 0, 800, 900, font);
			batch.begin(camera);
			stage.draw(batch, camera);
			batch.end();
			pointer.update();
			ui.update();
		}
		function click(b:Layout2D):Void {
			frame(b.x + b.width / 2, b.y + b.height / 2, true);
			frame(b.x + b.width / 2, b.y + b.height / 2, false);
		}
		frame();
		frame();
		var field = picker.textField,
			button = picker.formatButton,
			theme = ui.theme;
		check(field.name == "tint-text" && button.name == "tint-format" && field.text == "ff0000ff" && field.hint == "RRGGBBAA" && picker.format == Hex,
			"The field and the button named after the picker, the field showing its color as hex");
		// The layout: the square edge to edge across the 480 units the panel's column gives it, as tall; the swatch and the bars in a padded
		// strip under it, the hue's row and the alpha's beside the swatch's middle; the field and the button centered under them.
		var side = picker.layout.width,
			pad = theme.padding,
			square = @:privateAccess picker.squareLayout,
			swatch = @:privateAccess picker.swatchLayout,
			hueRow = @:privateAccess picker.hueLayout,
			alphaRow = @:privateAccess picker.alphaLayout;
		check(side == 480
			&& square.x == picker.layout.x
			&& square.y == picker.layout.y
			&& square.width == side
			&& square.height == side,
			"The square edge to edge across the picker's width, as tall: " + side);
		check(swatch.x == picker.layout.x + pad && swatch.y == square.y + side + pad && swatch.width == swatch.height,
			"The swatch at the strip's padded start");
		check(hueRow.x == swatch.x + swatch.width + pad
			&& near(hueRow.x + hueRow.width, picker.layout.x + side - pad)
			&& alphaRow.x == hueRow.x
			&& alphaRow.width == hueRow.width
			&& alphaRow.y > hueRow.y,
			"The bars from beside the swatch to the strip's padded end, the alpha's under the hue's");
		check(near((hueRow.y + alphaRow.y + alphaRow.height) / 2, swatch.y + swatch.height / 2), "The bars beside the swatch's middle");
		check(near((field.layout.x + button.layout.x + button.layout.width) / 2, picker.layout.x + side / 2)
			&& field.layout.y == button.layout.y
			&& field.layout.height == button.layout.height
			&& field.layout.y >= swatch.y + swatch.height + pad,
			"The field and the button centered under the strip, as tall as each other");
		check(picker.layout.y + picker.layout.height == field.layout.y + field.layout.height + 2 + theme.textSize * .6 + pad,
			"The picker ends under the field's caption and the padding");
		// The square: saturation across, brightness up it.
		var sx = square.x, sy = square.y;
		frame(sx + side * .5, sy + side * .25, true);
		check(ui.focused == picker && near(picker.saturation, .5) && near(picker.brightness, .75) && picker.changed,
			"Pressed in the square: saturation across, brightness up it, focus with it");
		check(picker.color == helix.ui.ColorPicker.fromHsv(0, .5, .75), "The color from them");
		frame(sx + side * 2, sy + side * 2, true);
		check(picker.saturation == 1 && picker.brightness == 0 && picker.color == 0x000000ff, "Dragged past the corner: clamped, black");
		frame(sx + side * 2, sy + side * 2, false);
		// The hue bar, left to right, between its round ends' centers (half its thickness in from its row's ends); dragged through black keeps
		// it.
		var thickness = theme.trackThickness;
		function along(row:Layout2D, f:Float):Float
			return row.x + thickness / 2 + f * (row.width - thickness);
		var hy = hueRow.y + hueRow.height / 2;
		frame(along(hueRow, .5), hy, true);
		frame(along(hueRow, 2 / 3), hy, true);
		check(near(picker.hue, 2 / 3) && !picker.changed && picker.color == 0x000000ff, "The hue moved through black: the color still black");
		frame(along(hueRow, 2 / 3), sy - 100, true);
		check(near(picker.hue, 2 / 3), "Dragged off the bar: still the hue, along it");
		frame(hueRow.x - 50, sy + side * 3, true);
		check(picker.hue == 0, "Past the bar's left end: hue 0");
		frame(hueRow.x - 50, sy + side * 3, false);
		frame(along(hueRow, 1), hueRow.y + 1, true);
		frame(along(hueRow, 1), hueRow.y + 1, false);
		check(picker.hue == 1, "At the right end's center, the top of its row: hue 1");
		frame(sx + side, sy, true);
		check(picker.color == 0xff0000ff, "Back to the square's top right: the full hue, red");
		frame(sx + side, sy, false);
		// The alpha bar under it: clear at its left, opaque at its right.
		frame(along(alphaRow, .5), alphaRow.y + alphaRow.height / 2, true);
		frame(along(alphaRow, .5), alphaRow.y + alphaRow.height / 2, false);
		check(picker.color == 0xff000080, "Half way along the alpha bar: alpha 0x80");
		frame([Up]);
		check(picker.color & 255 == Math.round(.55 * 255), "Up: the part the pointer chose, alpha up a twentieth");
		frame(swatch.x + swatch.width / 2, swatch.y + swatch.height / 2, true);
		frame(swatch.x + swatch.width / 2, swatch.y + swatch.height / 2 - 40, true);
		frame(swatch.x + swatch.width / 2, swatch.y + swatch.height / 2 - 40, false);
		check(picker.color & 255 == Math.round(.55 * 255) && ui.focused == picker, "Dragged from the swatch: nothing changes, focus kept");
		// Keys: Enter steps through the parts (from the alpha bar to none, then the square), the arrows nudge the one stepped to.
		frame([Enter]);
		frame([Enter]);
		frame([Left]);
		check(near(picker.saturation, .95) && ui.focused == picker, "Enter twice, then Left: saturation down a twentieth, focus kept");
		frame([Down]);
		check(near(picker.brightness, .95) && ui.focused == picker, "Down: brightness down a twentieth, focus kept");
		frame([Enter]);
		frame([Left]);
		check(near(picker.hue, 1 - 1 / 20), "Enter again, then Left: the hue down a twentieth");
		frame([Up]);
		check(picker.hue == 1, "Up: up again");
		frame([Enter]);
		frame([Down]);
		check(picker.color & 255 == 0x80, "Enter again, then Down: alpha down a twentieth");
		frame([Enter]);
		frame([Down]);
		check(ui.focused == field, "Enter once more lets the arrows go: Down moves focus on, to the field under the bars");
		frame([Up]);
		check(ui.focused == picker, "Up: back to the picker");
		// Typing: hex as typed, refused text marked and changing nothing, the color's own hex once the field is left.
		var was = picker.color;
		click(field.layout);
		check(ui.focused == field && ui.capturingKeys, "A click focuses the field");
		for (i in 0...9)
			frame([Backspace]);
		check(field.text == "" && field.invalid && picker.color == was | 0xff,
			"Emptied: marked invalid; the color the last it named, its first six digits (opaque) on the way");
		was = picker.color;
		frame(null, null, null, null, "#33");
		frame();
		check(field.invalid && picker.color == was, "Part of a color: marked invalid, the color unchanged");
		frame(null, null, null, null, "66cc");
		frame();
		check(!field.invalid && picker.color == 0x3366ccff && field.text == "#3366cc", "RRGGBB with #: taken as opaque, the text left as typed");
		frame(null, null, null, null, "4");
		frame(null, null, null, null, "0");
		frame();
		check(picker.color == 0x3366cc40, "RRGGBBAA: alpha too");
		frame([Backspace]);
		frame(null, null, null, null, "x");
		frame();
		check(field.invalid && picker.color == 0x3366cc40, "A wrong digit: marked, the color kept");
		frame([Tab]);
		frame();
		check(ui.focused == button && field.text == "3366cc40" && !field.invalid, "Left for the button after it: the field shows the color again");
		// The format: the button cycles it, the field showing the color in it at once; decimal channels typed.
		click(button.layout);
		check(picker.format == Rgba && field.text == "51 102 204 64" && field.hint == "r g b a" && ui.focused == button,
			"Clicked: decimal channels, shown at once");
		check(@:privateAccess picker.caption.text == "RGBA", "Its caption names it");
		click(field.layout);
		for (i in 0...13)
			frame([Backspace]);
		frame(null, null, null, null, "10, 20, 30");
		frame();
		check(!field.invalid && picker.color == 0x0a141eff, "Three channels apart by commas: taken as opaque");
		frame(null, null, null, null, " 300");
		frame();
		check(field.invalid && picker.color == 0x0a141eff, "A channel past 255: marked, the color kept");
		frame([Tab]);
		frame();
		check(field.text == "10 20 30 255" && !field.invalid, "Left: the color in decimal again");
		frame([Enter]);
		check(picker.format == Hex && field.text == "0a141eff" && @:privateAccess picker.caption.text == "HEX", "Enter on the focused button: hex again");
		check(ui.press("tint-format"), "Pressed by name");
		frame();
		check(picker.format == Rgba, "Pressed: decimal");
		picker.format = Hex;
		frame();
		check(field.text == "0a141eff", "Assigned: hex");
		// Disabled: not dragged, its field and button disabled with it.
		picker.enabled = false;
		frame(sx + 1, sy + 1, true);
		frame(sx + 1, sy + 1, false);
		click(button.layout);
		check(picker.color == 0x0a141eff && !field.enabled && !button.enabled && picker.format == Hex,
			"Disabled: not dragged, the field and the button with it");
		ui.remove(picker);
		check(ui.find("tint-text") == null && ui.find("tint-format") == null, "Removed with its field and its button");
		// Without alpha: no alpha bar, a smaller swatch beside the hue bar, three channels; in a row, its own width.
		var opaque = ui.colorPicker(0x112233ff, false, "plain"),
			row = Layout2D.row();
		panel.adopt(opaque);
		row.add(opaque.layout);
		panel.content.add(row);
		frame();
		frame();
		var plainSwatch = @:privateAccess opaque.swatchLayout,
			plainHue = @:privateAccess opaque.hueLayout;
		check(opaque.layout.width == theme.colorPickerWidth && @:privateAccess opaque.squareLayout.height == opaque.layout.width,
			"In a row: its own width, the square as tall");
		check(@:privateAccess opaque.alphaLayout == null && plainSwatch.height < swatch.height && near(plainHue.y + plainHue.height / 2,
			plainSwatch.y + plainSwatch.height / 2),
			"No alpha bar; a smaller swatch, the hue bar beside its middle");
		opaque.format = Rgba;
		frame();
		check(opaque.textField.text == "17 34 51" && opaque.textField.hint == "r g b" && @:privateAccess opaque.caption.text == "RGB",
			"Without alpha: three channels, RGB");
	}
}
