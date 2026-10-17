import Render2DTests.CountingGraphics;
import helix.render2d.Font2D;
import helix.render2d.Node2D;
import helix.render2d.Text2D;
import helix.ui.Box;
import helix.ui.Box.BoxDirection;
import helix.ui.Box.Sizing;

/** The UI's layout: rows, columns and stacks, sizes fixed, fitted, growing and shared, padding, gaps, alignment and anchors, and the nodes
	placed by their pivots. */
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
		var grid = Box.column(), cells = [];
		grid.gap = 8;
		for (r in 0...2) {
			var row = Box.row();
			row.gap = 8;
			for (c in 0...3) {
				var tile = ui.tile(null, 'Part ${r * 3 + c}', 64);
				cells.push(tile);
				row.add(tile.box);
			}
			grid.add(row);
		}
		var done = ui.button("Done");
		grid.add(done.box);
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
			Box.arrange(layout, 0, 0, 800, 600, font);
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
		var middle = cells[1].box;
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

	// A box laid out direction's way (a stack when not given), sized width x height.
	static function sized(width:Sizing, height:Sizing, ?direction:BoxDirection):Box {
		var box = new Box(direction != null ? direction : Stack);
		box.setSizing(width, height);
		return box;
	}

	static function fixed(w:Float, h:Float):Box
		return sized(Fixed(w), Fixed(h));

	// Adds children to box in order; returns box.
	static function holding(box:Box, children:Array<Box>):Box {
		for (c in children)
			box.add(c);
		return box;
	}

	static function layout(font:Font2D):Void {
		// A row: fixed children, a gap between, padding around; it fits them.
		var a = fixed(50, 20), b = fixed(50, 30), c = fixed(50, 20);
		var row = holding(Box.row(), [a, b, c]);
		row.setPadding(5, 5, 5, 5);
		row.gap = 10;
		Box.arrange(row, 0, 0, 1000, 1000, font);
		check(row.width == 180 && row.height == 40 && a.x == 5 && b.x == 65 && c.x == 125 && a.y == 5, "A row fits its children, gaps and padding");
		// Growing children share what's left by weight; a share of the parent; the main axis centered when none grows.
		var fix = fixed(100, 10),
			one = sized(Grow(1), Fixed(10)),
			two = sized(Grow(2), Fixed(10));
		var grow = holding(sized(Fixed(400), Fixed(10), Row), [fix, one, two]);
		Box.arrange(grow, 0, 0, 1000, 1000, font);
		check(near(one.width, 100) && near(two.width, 200) && near(two.x, 200), "Growing children share the room left by weight");
		var half = sized(Percent(.5), Fixed(10)),
			centred = holding(sized(Fixed(400), Fixed(10), Row), [half]);
		centred.setAlign(Center, Start);
		Box.arrange(centred, 0, 0, 1000, 1000, font);
		check(half.width == 200 && half.x == 100, "A share of the parent, centred when nothing grows");
		// A column stretching its children across.
		var wide = sized(Fit, Fixed(10)),
			column = holding(sized(Fixed(300), Fit, Column), [wide]);
		column.setAlign(Start, Stretch);
		Box.arrange(column, 0, 0, 1000, 1000, font);
		check(wide.width == 300, "Stretch fills across a column");
		// A stack: anchored to a corner and the middle, moved by offsets.
		var corner = fixed(40, 20), middle = fixed(40, 20);
		corner.setAnchor(End, End, -10, -10);
		middle.setAnchor(Center, Center);
		var screen = holding(sized(Grow(1), Grow(1)), [corner, middle]);
		Box.arrange(screen, 0, 0, 800, 600, font);
		check(corner.x == 750 && corner.y == 570 && middle.x == 380 && middle.y == 290, "Anchored to a corner and the middle");
		check(corner.anchorX == End && corner.anchorOffsetY == -10 && screen.gap == 0 && column.crossAlign == Stretch, "A box answers what it was set to");
		// Nodes placed by their pivots, sprites and rectangles sized; a text fitted to its measure.
		var panel = Node2D.rectangle(1, 1),
			dot = Node2D.circle(5),
			label = Node2D.text("PLAY", 20, -1, Center);
		var panelBox = Box.of(panel),
			dotBox = Box.of(dot),
			labelBox = Box.of(label);
		panelBox.setSizing(Fit, Fixed(30));
		var nodes = holding(sized(Fixed(200), Fit, Column), [panelBox, dotBox, labelBox]);
		nodes.setAlign(Start, Stretch);
		nodes.gap = 4;
		Box.arrange(nodes, 10, 10, 1000, 1000, font);
		check(panel.x == 10 && panel.y == 10 && panel.width == 200 && panel.height == 30, "A rectangle at its corner, sized");
		check(dot.x == 110 && dot.y == 49 && dotBox.height == 10, "A circle at its center (stretched across: the column's middle)");
		check(labelBox.height == 20 && label.x == 110 && label.y == 58, "A centred text at its middle, as tall as its size");
		var fitted = holding(Box.row(), [Box.of(Node2D.text("PLAY", 20))]);
		Box.arrange(fitted, 0, 0, 1000, 1000, font);
		check(near(fitted.width, Text2D.measure(font, "PLAY", 20)), "A text fits its measure");
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
			panel.content.add(w.box);
		panel.box.setSizing(Fixed(400), Fit);
		panel.box.setAnchor(Center, Center);
		var layout = holding(sized(Grow(1), Grow(1)), [panel.box]);
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
			Box.arrange(layout, 0, 0, 800, 600, font);
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
		var bx = play.box.x + 20, by = play.box.y + 10;
		frame(bx, by, false);
		check(!ui.capturingKeys, "The pointer moving hands back the keys");
		frame(bx, by, true);
		frame(bx, by, false);
		check(play.clicked, "A click on the button");
		var ox = off.box.x + 10, oy = off.box.y + 10;
		frame(ox, oy, true);
		frame(ox, oy, false);
		check(!off.clicked, "A disabled button isn't clicked");
		// A drag along the slider's track to its end.
		var sx = volume.box.x + 5, sy = volume.box.y + volume.box.height / 2;
		frame(sx, sy, true);
		frame(volume.box.x + volume.box.width + 50, sy, true);
		check(volume.value == 10, "Dragged to the end of the track: the most");
		frame(sx, sy, false);
		// The list: the wheel scrolls it; a click chooses the row under the pointer, again activates it.
		var lx = levels.box.x + 30, ly = levels.box.y + 10;
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
		var layout = holding(sized(Fixed(300), Fit, Column), [name.box]);
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
			Box.arrange(layout, 0, 0, 800, 600, font);
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
}
