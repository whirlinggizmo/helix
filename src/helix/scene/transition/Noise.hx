package helix.scene.transition;

import helix.render2d.Drawing2D;

/** The screen covered square by square in a scattered order, then uncovered the same way in another: a dissolve in blocks. */
class Noise extends Transition {
	/** Squares of cell stage units (24 unless given, at least 2) over seconds (half a second unless given) in color (black unless given,
		0xAARRGGBB). */
	public function new(seconds = .5, cell = 24., color = 0xff000000) {
		super(seconds);
		this.cell = cell > 2 ? cell : 2;
		this.color = color;
	}

	/** Each square's size, the stage's units. */
	public var cell(default, null):Float;

	/** Its color. */
	public var color(default, null):Int;

	override public function draw(cover:Drawing2D, x:Float, y:Float, width:Float, height:Float, progress:Float):Void {
		var columns = Math.ceil(width / cell), rows = Math.ceil(height / cell);
		var coming = progress < .5,
			amount = coming ? progress * 2 : (progress - .5) * 2;
		for (row in 0...rows) {
			// A row's neighboring squares drawn as one: a run from where it starts to where it stops.
			var start = -1;
			for (column in 0...columns + 1) {
				var drawn = false;
				if (column < columns) {
					// Each square's turn, from its place (the same every run): one order in, another out.
					var turn = order(column, row, coming ? 0x1e3779b9 : 0x7f4a7c15);
					drawn = coming ? (turn < amount) : (turn >= amount);
				}
				if (drawn && start < 0)
					start = column;
				else if (!drawn && start >= 0) {
					cover.rect(x + start * cell, y + row * cell, (column - start) * cell, cell, color);
					start = -1;
				}
			}
		}
	}

	// A square's turn, 0 to 1, scattered by its column, row and salt; every product under 2^53, so JS's doubles and native 32-bit
	// integers keep the same low bits and both targets scatter alike.
	static function order(column:Int, row:Int, salt:Int):Float {
		var h = ((column & 0xffff) * 0x3c6ef3) ^ ((row & 0xffff) * 0x1b8735) ^ salt;
		h = (h ^ (h >>> 15)) & 0x3fffff;
		h = (h * 0x2c1b3c) ^ ((h * 0x2c1b3c) >>> 13);
		h = (h & 0x3fffff) * 0x297a2d;
		h ^= h >>> 16;
		return (h & 0xffffff) / 0x1000000;
	}
}
