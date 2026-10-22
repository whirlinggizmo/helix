import helix.graphics.Color;
import helix.host.Presentation;
import helix.render2d.Camera2D;
import helix.render2d.Drawing2D;

/** Draws a Game into a Drawing2D in cell units, cleared and drawn again each update; the app shows it through the well's camera. Its text is never smaller than READABLE of the presentation's units, so the labels stay
	readable where cells are small (a phone on its side). */
class Renderer {
	public static final colors = [
		0xff3fd0e0,
		0xfff0d040,
		0xffa050e0,
		0xff50d060,
		0xffe04848,
		0xff4870e8,
		0xfff09030
	];

	/** The least text size, in the presentation's units. */
	static inline var READABLE = 15;

	/** What it draws into, in cells: the app puts it under the world a View2D shows. */
	public var drawing(default, null) = new Drawing2D();

	// The least text size in cells, this frame.
	var least = 0.;

	public function new() {}

	static function shade(color:Int, amount:Float):Int {
		inline function channel(shift:Int):Int {
			var v = (color >>> shift) & 255;
			return Std.int(amount >= 0 ? v + (255 - v) * amount : v * (1 + amount)) << shift;
		}
		return channel(16) | channel(8) | channel(0) | Color.withAlpha(0, Color.getAlpha(color));
	}

	// A text size in cells, at least the readable one.
	inline function size(cells:Float):Float
		return Math.max(cells, least);

	function block(x:Float, y:Float, size:Float, color:Int):Void {
		var edge = size * .14;
		drawing.rect(x, y, size, size, shade(color, -.45));
		drawing.rect(x, y, size - edge, size - edge, shade(color, .35));
		drawing.rect(x + edge, y + edge, size - 2 * edge, size - 2 * edge, color);
	}

	/** A piece centered in a box, at a given cell size. */
	function preview(kind:Int, box:Array<Float>, size:Float):Void {
		var c = Pieces.cells[kind][0], minX = 9, maxX = 0, minY = 9, maxY = 0;
		for (i in 0...4) {
			minX = Std.int(Math.min(minX, c[i * 2]));
			maxX = Std.int(Math.max(maxX, c[i * 2]));
			minY = Std.int(Math.min(minY, c[i * 2 + 1]));
			maxY = Std.int(Math.max(maxY, c[i * 2 + 1]));
		}
		var x = box[0] + (box[2] - (maxX - minX + 1) * size) / 2,
			y = box[1] + (box[3] - (maxY - minY + 1) * size) / 2;
		for (i in 0...4)
			block(x + (c[i * 2] - minX) * size, y + (c[i * 2 + 1] - minY) * size, size, colors[kind]);
	}

	function panel(box:Array<Float>, label:String):Void {
		drawing.roundedRect(box[0], box[1], box[2], box[3], .3, 0xff141b2b);
		drawing.drawText(label, box[0] + box[2] / 2, box[1] + .2, size(.45), 0xff8090a8, Center);
	}

	function button(box:Array<Float>, label:String, size:Float):Void {
		drawing.roundedRect(box[0], box[1], box[2], box[3], .3, 0xff22304a);
		drawing.drawText(label, box[0] + box[2] / 2, box[1] + (box[3] - size) / 2, size, 0xffe0e8f4, Center);
	}

	/** Draws game laid out by layout, seen through camera, its text sized by presentation's units: the drawing cleared and drawn again. */
	public function render(game:Game, layout:Layout, camera:Camera2D, presentation:Presentation, tick:Int):Void {
		least = READABLE * presentation.scaleX / camera.zoom;
		drawing.clear();
		var fx = layout.fieldX,
			fy = layout.fieldY,
			visible = Game.H - Game.HIDDEN;
		drawing.rect(fx - .15, fy - .15, Game.W + .3, visible + .3, 0xff2a3550);
		drawing.rect(fx, fy, Game.W, visible, 0xff05070d);
		for (x in 1...Game.W)
			drawing.rect(fx + x - .01, fy, .02, visible, 0xff111827);
		for (y in 1...visible)
			drawing.rect(fx, fy + y - .01, Game.W, .02, 0xff111827);
		for (y in Game.HIDDEN...Game.H) {
			var flash = game.clearing.indexOf(y) >= 0;
			for (x in 0...Game.W) {
				var v = game.cell(x, y);
				if (v > 0)
					block(fx + x, fy + y - Game.HIDDEN, 1, flash && game.clearTimer % 6 < 3 ? 0xffffffff : colors[v - 1]);
			}
		}
		if (game.piece >= 0) {
			var c = Pieces.cells[game.piece][game.rotation],
				ghost = game.ghostY();
			for (i in 0...4) {
				var y = ghost + c[i * 2 + 1] - Game.HIDDEN;
				if (y >= 0)
					drawing.frame(fx + game.px + c[i * 2] + .06, fy + y + .06, .88, .88, .08, Color.withAlpha(colors[game.piece], 0x90));
			}
			for (i in 0...4) {
				var y = game.py + c[i * 2 + 1] - Game.HIDDEN;
				if (y >= 0)
					block(fx + game.px + c[i * 2], fy + y, 1, colors[game.piece]);
			}
		}
		panel(layout.holdBox, "HOLD");
		if (game.held >= 0)
			preview(game.held, [
				layout.holdBox[0],
				layout.holdBox[1] + .5,
				layout.holdBox[2],
				layout.holdBox[3] - .5
			], layout.portrait ? 0.6 : .8);
		panel(layout.nextBox, "NEXT");
		var count = layout.portrait ? 1 : 3,
			slot = (layout.nextBox[3] - .5) / count;
		for (i in 0...count)
			if (i < game.queue.length)
				preview(game.queue[i], [layout.nextBox[0], layout.nextBox[1] + .5 + i * slot, layout.nextBox[2], slot],
					i == 0 ? (layout.portrait ? 0.6 : .8) : .6);
		var sx = layout.scoreX, sy = layout.scoreY;
		drawing.drawText(Std.string(game.score), sx, sy, 1, 0xfff0f4fa, Center);
		drawing.drawText("LEVEL " + game.level, sx, sy + 1.3, size(.4), 0xff8090a8, Center);
		drawing.drawText("LINES " + game.lines, sx, sy + 1.3 + Math.max(.6, size(.4) * 1.25), size(.4), 0xff8090a8, Center);
		if (game.state == "playing")
			button(layout.pauseBox, "II", .7);
		if (game.state != "playing") {
			drawing.rect(fx, fy, Game.W, visible, 0xd005070d);
			var cy = fy + visible * .3;
			var title = switch game.state {
				case "paused": "PAUSED";
				case "over": "GAME OVER";
				default: "BLOCKS";
			};
			drawing.drawText(title, fx + Game.W / 2, cy, 1.2, 0xfff0f4fa, Center);
			if (game.best > 0)
				drawing.drawText("BEST " + game.best, fx + Game.W / 2, cy + 2, size(.5), 0xff8090a8, Center);
			if (tick % 60 < 40)
				drawing.drawTextWrapped(game.state == "paused" ? "TAP OR ENTER TO RESUME" : "TAP OR ENTER TO PLAY", fx
					+ Game.W / 2, cy
					+ 3.5, size(.4),
					Game.W
					- .5, 0xffe0e8f4, Center);
			if (game.state == "title") {
				var help = [
					"TAP: TURN   DRAG: MOVE",
					"FLICK DOWN: DROP  UP: HOLD",
					"KEYS: ARROWS Z X SPACE C"
				];
				// Wrapped to the well, stacked by the lines' heights.
				var y = cy + 6;
				for (line in help)
					y += Math.max(.8, drawing.drawTextWrapped(line, fx + Game.W / 2, y, size(.35), Game.W - .5, 0xff8090a8, Center));
			}
		}
	}
}
