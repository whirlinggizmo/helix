import helix.raylib.*;

/** Checks the structs' `copy`: a copy is separate from what it copies, a struct holding others copies them too, and a copy into an
	out fills that one and makes none; and `Color` as a value, copied when assigned. */
class StructTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var v = new Vector3(1, 2, 3), c = v.copy();
		c.x = 9;
		check(v.x == 1 && c.x == 9 && c.y == 2 && c.z == 3, "a copy is separate");

		var camera = new Camera3D(new Vector3(0, 2, 5), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 60, 0);
		var copied = camera.copy();
		copied.position.y = 7;
		check(camera.position.y == 2 && copied.fovy == 60 && copied.up.y == 1, "a camera's vectors are copied too");

		var out = new Camera3D(), target = out.target;
		check(camera.copy(out) == out && out.target == target && out.position.z == 5 && out.fovy == 60, "a copy into out fills it and makes none");

		var m = new Matrix(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16), n = m.copy();
		check(n != m && n.m0 == 1 && n.m4 == 2 && n.m12 == 4 && n.m1 == 5 && n.m15 == 16, "a matrix's sixteen values, in raylib's order");

		var red = new Color(230, 41, 55, 255), faded = red;
		faded.a = 128;
		check(red.a == 255 && faded.a == 128 && faded.r == 230, "a color is a value: assigned, then changed alone");
		var map = new MaterialMap(null, Raylib.RED);
		map.color.a = 9;
		check(Raylib.RED.a == 255 && map.color.a == 9 && map.color.r == 230, "a field's color changed in place, the constant untouched");
		var unset = new MaterialMap().color;
		check(unset.r == 0 && unset.a == 0, "a map's color left out is transparent black, as raylib's zeroed maps");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
