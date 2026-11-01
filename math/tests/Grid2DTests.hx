import helix.math.DistanceField2D;
import helix.math.RectPacker2D;

/** Checks DistanceField2D and RectPacker2D with the library alone: a distance field against measured distances, and rectangles packed
	apart, inside the area, tallest first. */
class Grid2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// A 7 by 5 grid, zeros at (1, 1) and (5, 3): each cell's squared distance to the nearer.
		var grid = [for (_ in 0...35) 1e20];
		grid[1 * 7 + 1] = 0;
		grid[3 * 7 + 5] = 0;
		DistanceField2D.transform(grid, 7, 5);
		var right = true;
		for (y in 0...5)
			for (x in 0...7) {
				var a = (x - 1) * (x - 1) + (y - 1) * (y - 1),
					b = (x - 5) * (x - 5) + (y - 3) * (y - 3);
				right = right && grid[y * 7 + x] == (a < b ? a : b);
			}
		check(right, "a distance field: each cell's squared distance to the nearest zero");

		var sizes = [10, 30, 20, 10, 20, 20, 5, 5, 0, 4],
			places = RectPacker2D.pack(40, 40, sizes);
		var placed = true;
		for (i in 0...4) {
			var x = places[i * 3],
				y = places[i * 3 + 1],
				w = sizes[i * 2],
				h = sizes[i * 2 + 1];
			placed = placed && places[i * 3 + 2] == 1 && x >= 0 && y >= 0 && x + w <= 40 && y + h <= 40;
			for (j in 0...i) {
				var ox = places[j * 3], oy = places[j * 3 + 1];
				placed = placed && (x + w <= ox || ox + sizes[j * 2] <= x || y + h <= oy || oy + sizes[j * 2 + 1] <= y);
			}
		}
		check(placed, "packed: every rectangle inside the area, none overlapping");
		check(places[0] == 0 && places[1] == 0 && places[12] == 0 && places[13] == 0 && places[14] == 1, "the tallest at the corner; an empty one at 0, 0");
		var full = RectPacker2D.pack(10, 10, [10, 10, 1, 1]);
		check(full[2] == 1 && full[5] == 0, "one too many doesn't fit, and says so");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
