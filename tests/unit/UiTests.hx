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
}
