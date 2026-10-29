import helix.math.Bounds2D;
import helix.math.Bounds3D;

/** Checks Bounds2D and Bounds3D with the library alone: made empty, grown by points and by other bounds, their sizes and centers,
	what they contain and overlap (faces included, an empty one never), set, copied and cleared. */
class BoundsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var b = new Bounds2D();
		check(b.isEmpty && b.width == 0 && b.height == 0 && Math.isNaN(b.centerX) && Math.isNaN(b.centerY), "2D made empty: no size, no center");
		check(!b.contains(0, 0), "2D: an empty one contains nothing");
		b.expand(2, 3);
		check(!b.isEmpty && b.minX == 2 && b.maxX == 2 && b.width == 0, "2D: a first point makes it that point");
		b.expand(-1, 7);
		check(b.minX == -1 && b.maxY == 7 && b.width == 3 && b.height == 4 && b.centerX == .5 && b.centerY == 5, "2D: grown by a second");
		check(b.contains(0, 4) && b.contains(-1, 7) && !b.contains(3, 4), "2D: holds its inside and edges, not what's past them");
		var other = new Bounds2D().set(1, 6, 9, 9);
		check(b.intersects(other) && !b.intersects(new Bounds2D()) && !new Bounds2D().intersects(b), "2D: overlaps another; never an empty one");
		check(b.intersects(new Bounds2D().set(2, 7, 3, 8)) && !b.intersects(new Bounds2D().set(2.5, 7.5, 3, 8)), "2D: touching counts");
		check(b.union(other) == b && b.maxX == 9 && b.union(new Bounds2D()).maxX == 9, "2D: a union grows to hold both; an empty one changes nothing");
		var copy = new Bounds2D().copyFrom(b);
		check(copy.minX == -1 && copy.maxX == 9 && copy.minY == 3 && copy.maxY == 9, "2D: copied");
		check(copy.makeEmpty() == copy && copy.isEmpty && !b.isEmpty, "2D: made empty, the original unchanged");

		var c = new Bounds3D();
		check(c.isEmpty && c.depth == 0 && Math.isNaN(c.centerZ), "3D made empty: no size, no center");
		c.expand(1, 2, 3);
		check(!c.isEmpty && c.minZ == 3 && c.maxZ == 3 && c.depth == 0, "3D: a first point makes it that point");
		c.expand(-1, 0, 7);
		check(c.width == 2 && c.height == 2 && c.depth == 4 && c.centerX == 0 && c.centerY == 1 && c.centerZ == 5, "3D: grown by a second");
		check(c.contains(0, 1, 5) && c.contains(1, 2, 7) && !c.contains(0, 1, 8), "3D: holds its inside and faces, not what's past them");
		var far = new Bounds3D().set(0, 0, 8, 1, 1, 9);
		check(!c.intersects(far) && c.intersects(new Bounds3D().set(0, 0, 7, 1, 1, 9)) && !c.intersects(new Bounds3D()),
			"3D: overlaps by every axis; faces count; never an empty one");
		check(c.union(far) == c && c.maxZ == 9 && c.minX == -1 && c.union(new Bounds3D()).maxZ == 9,
			"3D: a union grows to hold both; an empty one changes nothing");
		var copy3 = new Bounds3D().copyFrom(c);
		check(copy3.minZ == 3 && copy3.maxZ == 9 && copy3.makeEmpty().isEmpty && !c.isEmpty, "3D: copied, made empty, the original unchanged");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
