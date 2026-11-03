import helix.math.Bounds3D;
import helix.geometry.Frustum3D;
import helix.math.Matrix3D;

/** Checks Frustum3D with the library alone: made holding everything; its planes from a perspective and an orthographic view-projection,
	pinned to Gribb and Hartmann's planes computed apart from Haxe; copied and filled into the one given; points, spheres and boxes
	inside, outside and straddling each kind, on a plane, past near and far, and an empty box; and a box outside near a corner, counted
	in as its doc comment allows. */
class Frustum3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance * Math.max(1, Math.abs(b));

	static function box(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Bounds3D
		return new Bounds3D().set(minX, minY, minZ, maxX, maxY, maxZ);

	// A camera at (2, 3, 8) looking at (0, 1, 0), +y up: its view, then a projection of 16 / 9, near 0.1 and far 1000.
	static function viewProjection(orthographic:Bool):Matrix3D {
		var view = Matrix3D.fromLookAt(2, 3, 8, 0, 1, 0, 0, 1, 0);
		var aspect = 16 / 9;
		var projection = orthographic ? Matrix3D.fromOrthographic(-6 * aspect, 6 * aspect, -6, 6, .1, 1000) : Matrix3D.fromPerspective(.9, aspect, .1, 1000);
		return Matrix3D.compose(view, projection);
	}

	static function main():Void {
		var everything = new Frustum3D();
		check(everything.contains(0, 0, 0)
			&& everything.contains(1e30, -1e30, 5)
			&& everything.intersectsSphere(-1e20, 0, 0, 0)
			&& everything.intersectsBounds(box(1e10, 1e10, 1e10, 1e10 + 1, 1e10 + 1, 1e10 + 1)),
			"made: holds everything");
		check(!everything.intersectsBounds(new Bounds3D()), "made: an empty box is still never inside");

		// Pinned: each plane the last row plus or minus another, normalized, in Python with numpy, apart from Haxe.
		var perspective = Frustum3D.fromMatrix(viewProjection(false));
		var planes = [
			  0.5824369146810011, -0.15356009878926333,  -0.7982396485246195,  5.6817236552027435,  -0.8895571122595278, -0.15356009878926333,
			-0.43024114178948714,   5.6817236552027435, -0.15399749426721182,  0.7725549300277239,  -0.6159899770688473,   2.9182500150020303,
			-0.05104722490110784,  -0.9775996491960435, -0.20418889960443137,   4.668404594225797, -0.23570226039551584, -0.23570226039551584,
			 -0.9428090415820634,    8.620983634634086,  0.23570226039551584, 0.23570226039551584,   0.9428090415820634,    991.2790163653458
		];
		check([for (i in 0...24) near(perspective.planes[i], planes[i], 1e-9)].indexOf(false) < 0,
			"a perspective view's planes: left, right, bottom, top, near and far, pinned");
		for (plane in 0...6) {
			var p = perspective.planes;
			check(near(Math.sqrt(p[plane * 4] * p[plane * 4] + p[plane * 4 + 1] * p[plane * 4 + 1] + p[plane * 4 + 2] * p[plane * 4 + 2]), 1),
				'plane $plane of length 1');
		}
		var orthographic = Frustum3D.fromMatrix(viewProjection(true));
		var flat = [
			0.9701425001453319,
			0.0,
			-0.24253562503633297,
			10.666666666666666,
			-0.9701425001453319,
			0.0,
			0.24253562503633297,
			10.666666666666666,
			-0.057166195047502935,
			0.97182531580755,
			-0.22866478019001174,
			5.028174684192449,
			0.057166195047502935,
			-0.97182531580755,
			0.22866478019001174,
			6.971825315807549,
			-0.23570226039551587,
			-0.23570226039551587,
			-0.9428090415820635,
			8.620983634634069,
			0.23570226039551587,
			0.23570226039551587,
			0.9428090415820635,
			991.2790163653659
		];
		check([for (i in 0...24) near(orthographic.planes[i], flat[i], 1e-9)].indexOf(false) < 0, "an orthographic view's planes: pinned");
		var given = new Frustum3D();
		check(Frustum3D.fromMatrix(viewProjection(false), given) == given
			&& given.planes.join(",") == perspective.planes.join(","), "into the one given");
		var copied = new Frustum3D();
		check(copied.copyFrom(orthographic) == copied
			&& copied.planes.join(",") == orthographic.planes.join(",")
			&& copied.planes != orthographic.planes,
			"copied, returning itself");

		// Points: what it looks at, behind it, beside it, on its near plane, past its far plane.
		for (f in [perspective, orthographic]) {
			var kind = f == perspective ? "perspective" : "orthographic";
			check(f.contains(0, 1, 0) && f.contains(-1, .5, -3), '$kind: points it looks at, inside');
			check(!f.contains(2.5, 3.5, 9.5) && !f.contains(4, 5, 16), '$kind: points behind it, outside');
			check(!f.contains(200, 1, 0) && !f.contains(0, -150, 0), '$kind: points beside and below it, outside');
			check(!f.contains(-200, -200, -1000), '$kind: a point past its far plane, outside');
			// Its near plane 0.1 from the camera along its view: a hair beyond it, inside; a hair nearer, outside.
			var d = Math.sqrt(4 + 4 + 64);
			function along(distance:Float):Bool
				return f.contains(2 - distance * 2 / d, 3 - distance * 2 / d, 8 - distance * 8 / d);
			check(along(.1 + 1e-9) && !along(.1 - 1e-9), '$kind: just past its near plane, inside; just short of it, outside');
		}

		// Spheres: inside, outside, straddling a plane, holding the camera.
		var f = perspective;
		check(f.intersectsSphere(0, 1, 0, .5) && f.intersectsSphere(0, 1, 0, 1e4), "a sphere inside, and one holding all of it");
		check(!f.intersectsSphere(200, 1, 0, 50), "a sphere to the right, outside");
		var leftDistance = f.planes[0] * -200 + f.planes[1] * 1 + f.planes[2] * 0 + f.planes[3];
		check(leftDistance < 0
			&& f.intersectsSphere(-200, 1, 0, -leftDistance + .01)
			&& !f.intersectsSphere(-200, 1, 0, -leftDistance - .01),
			"a sphere straddling the left plane, in; just short of it, out");
		check(f.intersectsSphere(2, 3, 8, .2) && !f.intersectsSphere(2.5, 3.5, 9.5, .5), "one holding the camera's near plane, in; behind, out");
		check(f.contains(0, 1, 0) == f.intersectsSphere(0, 1, 0, 0)
			&& !f.intersectsSphere(200, 1, 0, 0), "a sphere of radius 0 is a point");

		// Boxes: inside, outside, straddling, holding all of it, empty.
		check(f.intersectsBounds(box(-1, 0, -1, 1, 2, 1)), "a box inside");
		check(!f.intersectsBounds(box(150, -5, -5, 160, 5, 5))
			&& !f.intersectsBounds(box(2, 3, 12, 4, 5, 14)), "boxes beside and behind, outside");
		check(f.intersectsBounds(box(-1, 0, 7.9, 3, 4, 9)), "a box straddling the near plane, holding the camera");
		check(f.intersectsBounds(box(-100, 0, 0, 0, 1, 1)), "a box straddling the left plane");
		check(f.intersectsBounds(box(-1e4, -1e4, -1e4, 1e4, 1e4, 1e4)), "a box holding all of it");
		check(f.intersectsBounds(box(0, 1, 0, 0, 1, 0))
			&& !f.intersectsBounds(box(200, 1, 0, 200, 1, 0)), "a box of one point is that point");
		check(!f.intersectsBounds(new Bounds3D()) && !f.intersectsBounds(box(1, 1, 1, 0, 2, 2)), "an empty box, never inside");
		check(!orthographic.intersectsBounds(box(150, -5, -5, 160, 5, 5)) && orthographic.intersectsBounds(box(-1, 0, -1, 1, 2, 1)),
			"the orthographic one alike");
		// Outside near a corner, past the left and the top planes but neither alone: counted in, erring toward in view.
		// (Found and checked outside in Python, sampled at 41 points along each axis.)
		var corner = box(-55.8, 14.8, -34.4, -51.8, 18.8, -30.4);
		var inside = false;
		for (i in 0...11)
			for (j in 0...11)
				for (k in 0...11)
					inside = inside || f.contains(-55.8 + .4 * i, 14.8 + .4 * j, -34.4 + .4 * k);
		check(!inside && f.intersectsBounds(corner), "a box outside near a corner may be counted in");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
