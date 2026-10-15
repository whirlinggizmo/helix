import Render2DTests.CountingGraphics;
import helix.render2d.Font2D;
import helix.render2d.Node2D;
import helix.render2d.Text2D;
import helix.ui.Box;

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
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function fixed(w:Float, h:Float):Box
		return Box.stack().setSize(Fixed(w), Fixed(h));

	static function layout(font:Font2D):Void {
		// A row: fixed children, a gap between, padding around; it fits them.
		var a = fixed(50, 20), b = fixed(50, 30), c = fixed(50, 20);
		var row = Box.row().setPadding(5, 5, 5, 5).setGap(10).add(a).add(b).add(c);
		Box.arrange(row, 0, 0, 1000, 1000, font);
		check(row.getWidth() == 180 && row.getHeight() == 40 && a.getX() == 5 && b.getX() == 65 && c.getX() == 125 && a.getY() == 5,
			"A row fits its children, gaps and padding");
		// Growing children share what's left by weight; a share of the parent; the main axis centered when none grows.
		var fix = fixed(100, 10),
			one = Box.stack().setSize(Grow(1), Fixed(10)),
			two = Box.stack().setSize(Grow(2), Fixed(10));
		var grow = Box.row().setSize(Fixed(400), Fixed(10)).add(fix).add(one).add(two);
		Box.arrange(grow, 0, 0, 1000, 1000, font);
		check(near(one.getWidth(), 100) && near(two.getWidth(), 200) && near(two.getX(), 200), "Growing children share the room left by weight");
		var half = Box.stack().setSize(Percent(.5), Fixed(10)),
			centred = Box.row().setSize(Fixed(400), Fixed(10)).setAlign(Center, Start).add(half);
		Box.arrange(centred, 0, 0, 1000, 1000, font);
		check(half.getWidth() == 200 && half.getX() == 100, "A share of the parent, centred when nothing grows");
		// A column stretching its children across.
		var wide = Box.stack().setSize(Fit, Fixed(10)),
			column = Box.column().setSize(Fixed(300), Fit).setAlign(Start, Stretch).add(wide);
		Box.arrange(column, 0, 0, 1000, 1000, font);
		check(wide.getWidth() == 300, "Stretch fills across a column");
		// A stack: anchored to a corner and the middle, moved by offsets.
		var corner = fixed(40, 20).setAnchor(End, End, -10, -10),
			middle = fixed(40, 20).setAnchor(Center, Center);
		var screen = Box.stack().setSize(Grow(1), Grow(1)).add(corner).add(middle);
		Box.arrange(screen, 0, 0, 800, 600, font);
		check(corner.getX() == 750 && corner.getY() == 570 && middle.getX() == 380 && middle.getY() == 290, "Anchored to a corner and the middle");
		// Nodes placed by their pivots, sprites and rectangles sized; a text fitted to its measure.
		var panel = Node2D.rectangle(1, 1),
			dot = Node2D.circle(5),
			label = Node2D.text("PLAY", 20, -1, Center);
		var nodes = Box.column().setSize(Fixed(200), Fit).setAlign(Start, Stretch).setGap(4);
		var panelBox = Box.of(panel).setSize(Fit, Fixed(30)),
			dotBox = Box.of(dot),
			labelBox = Box.of(label);
		nodes.add(panelBox).add(dotBox).add(labelBox);
		Box.arrange(nodes, 10, 10, 1000, 1000, font);
		check(panel.getX() == 10 && panel.getY() == 10 && panel.getWidth() == 200 && panel.getHeight() == 30, "A rectangle at its corner, sized");
		check(dot.getX() == 110 && dot.getY() == 49 && dotBox.getHeight() == 10, "A circle at its center (stretched across: the column's middle)");
		check(labelBox.getHeight() == 20 && label.getX() == 110 && label.getY() == 58, "A centred text at its middle, as tall as its size");
		var fitted = Box.row().add(Box.of(Node2D.text("PLAY", 20)));
		Box.arrange(fitted, 0, 0, 1000, 1000, font);
		check(near(fitted.getWidth(), Text2D.measure(font, "PLAY", 20)), "A text fits its measure");
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
		off.setEnabled(false);
		for (w in [play, sound, volume, levels, off])
			panel.getContent().add(w.getBox());
		var layout = Box.stack().setSize(Grow(1), Grow(1)).add(panel.getBox().setSize(Fixed(400), Fit).setAnchor(Center, Center));
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
		check(ui.getFocused() == null && !ui.isCapturingKeys(), "Nothing focused to start");
		frame([Down]);
		check(ui.getFocused() == play && ui.isCapturingKeys() && ui.getFocusedName() == "Play", "Down: the first button, its name published");
		frame([Down]);
		frame([Enter]);
		check(ui.getFocused() == sound && sound.isChanged() && !sound.isOn(), "Enter switches the toggle");
		frame([Down]);
		frame([Right]);
		check(ui.getFocused() == volume && volume.getValue() == 6 && volume.isChanged(), "Right steps the slider, focus kept");
		frame([Left, Left]);
		check(volume.getValue() == 5, "Left steps back (two presses in a frame are one: frame edges)");
		frame([Down]);
		frame([Down]);
		frame([Down]);
		check(ui.getFocused() == levels && levels.getSelectedIndex() == 1, "Up and Down choose in a focused list");
		frame([Tab]);
		check(ui.getFocused() == play, "Tab leaves the list; the disabled button is skipped, focus wraps");
		frame([Enter]);
		check(play.isClicked(), "Enter activates the focused button");
		// The pointer: hovering hides the ring and hands back the keys; a click on a button.
		var bx = play.getBox().getX() + 20, by = play.getBox().getY() + 10;
		frame(bx, by, false);
		check(!ui.isCapturingKeys(), "The pointer moving hands back the keys");
		frame(bx, by, true);
		frame(bx, by, false);
		check(play.isClicked(), "A click on the button");
		var ox = off.getBox().getX() + 10, oy = off.getBox().getY() + 10;
		frame(ox, oy, true);
		frame(ox, oy, false);
		check(!off.isClicked(), "A disabled button isn't clicked");
		// A drag along the slider's track to its end.
		var sx = volume.getBox().getX() + 5,
			sy = volume.getBox().getY() + volume.getBox().getHeight() / 2;
		frame(sx, sy, true);
		frame(volume.getBox().getX() + volume.getBox().getWidth() + 50, sy, true);
		check(volume.getValue() == 10, "Dragged to the end of the track: the most");
		frame(sx, sy, false);
		// The list: the wheel scrolls it; a click chooses the row under the pointer, again activates it.
		var lx = levels.getBox().getX() + 30, ly = levels.getBox().getY() + 10;
		frame(lx, ly, false, -2);
		frame(lx, ly, true);
		frame(lx, ly, false);
		check(levels.getSelectedIndex() == 2 && levels.isChanged(), "Scrolled two rows by the wheel, the top row now the third");
		frame(lx, ly, true);
		frame(lx, ly, false);
		check(levels.isActivated(), "Clicked again: activated");
		// A new screen: Enter held across it does nothing until let go; Escape is back.
		input.keyEvent(Enter, true);
		ui.reset();
		ui.setFocused(play);
		frame();
		input.keyEvent(Enter, false);
		input.keyEvent(Enter, true);
		frame();
		check(!play.isClicked(), "A key held into a new screen does nothing");
		input.keyEvent(Enter, false);
		frame();
		frame([Enter]);
		check(play.isClicked(), "Pressed afresh, it does");
		frame([Escape]);
		check(ui.isBackPressed(), "Escape is back");
		// Used by name, as a test or an autopilot does: at the next update, when shown and usable.
		check(ui.press("Play") && !play.isClicked(), "Pressed by name; it takes at the next update");
		frame();
		check(play.isClicked() && ui.getFocused() == play, "Clicked by name, focus with it");
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
		var layout = Box.column().setSize(Fixed(300), Fit).add(name.getBox());
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
		check(ui.getFocused() == name && ui.isCapturingKeys(), "A click focuses the field; the UI has the keys though the pointer gave focus");
		frame("ab c");
		check(name.getText() == "ab c" && name.isChanged(), "Typed, a space among it");
		frame(" ", Space);
		check(name.getText() == "ab c " && !name.isSubmitted(), "Space types, not activates");
		frame(Backspace);
		frame("defghijk");
		check(name.getText() == "ab cdefg", "Backspace takes one off; typing stops at the limit: " + name.getText());
		frame(Enter);
		check(name.isSubmitted(), "Enter submits");
	}
}
