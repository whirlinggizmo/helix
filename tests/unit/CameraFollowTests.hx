import helix.render2d.Camera2D;
import helix.render2d.CameraFollow2D;

/** A 2D camera following a target (helix.render2d.CameraFollow2D): the dead zone, catching up the same at any frame rate, the world's bounds
	(and a world smaller than the view), snapping, and the shake: thrown within its distance by the trauma's square, settling, the same for
	the same seed. */
class CameraFollowTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, e = 1e-6):Bool
		return Math.abs(a - b) < e;

	static function main():Void {
		var camera = new Camera2D();
		camera.setViewport(100, 80);

		// The dead zone: free inside, the view pulled along by its edge outside.
		var follow = new CameraFollow2D();
		follow.smoothing = 0;
		check(follow.setDeadZone(10, 6) && !follow.setDeadZone(-1, 0), "A dead zone, none below 0");
		follow.update(4, -2, 1 / 60, camera);
		check(follow.x == 0 && follow.y == 0, "Inside the dead zone the view stays");
		follow.update(8, -7, 1 / 60, camera);
		check(follow.x == 3 && follow.y == -4, "Leaving it, the view follows its edge");

		// Catching up the same at any frame rate.
		var once = new CameraFollow2D(), twice = new CameraFollow2D();
		once.update(100, 0, .1, camera);
		twice.update(100, 0, .05, camera);
		twice.update(100, 0, .05, camera);
		check(near(once.x, twice.x) && once.x > 0 && once.x < 100, "Catching up smoothly, the same over two half steps as one");

		// Bounds: the view stops at the world's edges, and centers a world smaller than it.
		check(follow.setBounds(0, 0, 300, 200) && !follow.setBounds(0, 0, 0, 10), "Bounds, none empty");
		follow.update(-500, 500, 1 / 60, camera);
		check(follow.x == 50 && follow.y == 160, "The view stops at the world's edges");
		camera.zoom = .25;
		follow.update(0, 0, 1 / 60, camera);
		check(follow.x == 150 && follow.y == 100, "A world smaller than the view is centered");
		camera.zoom = 1;
		follow.clearBounds();
		follow.snap(1000, 1000);
		follow.update(1000, 1000, 1 / 60, camera);
		check(follow.x == 1000 && follow.y == 1000, "Snapped, and free without bounds");

		// The shake: within its distance by the trauma's square, settling, the same for a seed.
		var a = new CameraFollow2D(0, 0, 7), b = new CameraFollow2D(0, 0, 7);
		a.shake(.5);
		b.shake(.5);
		a.shake(0);
		check(a.trauma == .5, "Trauma adds up, nothing for 0");
		var thrown = false, within = true, same = true;
		for (_ in 0...20) {
			a.update(0, 0, 1 / 60, camera);
			b.update(0, 0, 1 / 60, camera);
			thrown = thrown || a.shakeX != 0;
			within = within && Math.abs(a.shakeX) <= .25 * a.shakeDistance * 80 && Math.abs(a.shakeY) <= .25 * a.shakeDistance * 80;
			same = same && a.shakeX == b.shakeX && a.shakeY == b.shakeY;
		}
		check(thrown && within && same, "Thrown within the distance (a share of the 80 units seen) times the trauma's square, the same for one seed");
		a.apply(camera);
		check(camera.x == a.x + a.shakeX && camera.y == a.y + a.shakeY, "apply places the camera, shaken");
		a.update(0, 0, 1, camera);
		check(a.trauma == 0 && a.shakeX == 0 && a.shakeY == 0 && a.x == 0, "It settles, and the follow never takes the shake");
		a.shake(5);
		check(a.trauma == 1, "Trauma is held to 1");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
