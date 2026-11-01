import helix.math.Bounds2D;
import helix.math.Bounds3D;

/** Checks Bounds2D and Bounds3D with the library alone: made empty, grown by points and by other bounds, their sizes and centers,
	what they contain and overlap (faces included, an empty one never), the spheres a 3D box touches, set, copied and cleared. */
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
		var joined = b.union(other);
		check(joined != b && b.maxX == 2 && joined.minX == -1 && joined.maxX == 9 && joined.minY == 3 && joined.maxY == 9,
			"2D: a union holds both, into a new box, the box unchanged");
		check(b.union(other, b) == b && b.maxX == 9 && b.union(new Bounds2D(), b).maxX == 9 && new Bounds2D().union(b).minX == -1,
			"2D: a union into the box itself; an empty one adds nothing");
		var into2 = new Bounds2D().set(0, 0, 1, 1);
		check(new Bounds2D().set(5, 5, 6, 6).union(into2, into2) == into2
			&& into2.minX == 0
			&& into2.maxX == 6, "2D: a union into the other box");
		var overlap = new Bounds2D().set(0, 0, 4, 4).intersection(new Bounds2D().set(2, 1, 6, 3));
		check(overlap.minX == 2 && overlap.minY == 1 && overlap.maxX == 4 && overlap.maxY == 3, "2D: the overlap of two");
		var edge = new Bounds2D().set(0, 0, 4, 4).intersection(new Bounds2D().set(4, 1, 6, 3));
		check(!edge.isEmpty && edge.width == 0 && edge.height == 2, "2D: touching edges overlap with no width");
		var into = new Bounds2D().set(0, 0, 4, 4);
		check(into.intersection(new Bounds2D().set(5, 5, 6, 6), into) == into && into.isEmpty, "2D: apart, empty; into itself");
		var argument = new Bounds2D().set(2, 1, 6, 3);
		check(new Bounds2D().set(0, 0, 4, 4).intersection(argument, argument) == argument && argument.minX == 2 && argument.maxX == 4,
			"2D: an overlap into the other box");
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
		var joined3 = c.union(far);
		check(joined3 != c && c.maxZ == 7 && joined3.maxZ == 9 && joined3.minX == -1, "3D: a union holds both, into a new box, the box unchanged");
		check(c.union(far, c) == c && c.maxZ == 9 && c.minX == -1 && c.union(new Bounds3D(), c).maxZ == 9,
			"3D: a union into the box itself; an empty one adds nothing");
		var into3 = new Bounds3D().set(0, 0, 0, 1, 1, 1);
		check(far.union(into3, into3) == into3 && into3.minZ == 0 && into3.maxZ == 9, "3D: a union into the other box");
		var copy3 = new Bounds3D().copyFrom(c);
		check(copy3.minZ == 3 && copy3.maxZ == 9 && copy3.makeEmpty().isEmpty && !c.isEmpty, "3D: copied, made empty, the original unchanged");
		var crate = new Bounds3D().set(-1, -1, -1, 1, 2, 1);
		check(crate.intersectsSphere(0, 0, 0, .1)
			&& crate.intersectsSphere(2, 3, 0, Math.sqrt(2))
			&& !crate.intersectsSphere(2, 3, 0, 1.41)
			&& crate.intersectsSphere(1.5, 0, 0, .5)
			&& !crate.intersectsSphere(1.5, 0, 0, .49),
			"3D: a sphere inside, touching a corner and a face, and just apart");
		check(!new Bounds3D().intersectsSphere(0, 0, 0, 100), "3D: an empty box meets no sphere");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
