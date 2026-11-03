import helix.raylib.Camera3D;
import helix.raylib.Raylib.*;
import helix.raylib.Vector3;
import helix.raylib.modules.RCore;

// helix-raylib's rcamera moves in the world's plane (raylib 6.2's CameraMoveForward and CameraMoveRight) and UpdateCameraPro over a grid of
// cameras: each number's bits, one line per case, as ref.c prints raylib 6.2's for the same cases. Each camera's first line is its scale
// line: what its differences are measured against, and whether it's degenerate.
@:access(helix.raylib.modules.RCore)
class CameraBits62 {
	static function bits(x:Float):String {
		var i = haxe.io.FPHelper.doubleToI64(x);
		return StringTools.hex(i.high, 8) + StringTools.hex(i.low, 8);
	}

	static function put(label:String, values:Array<Float>)
		Parity.line(label + ' ' + [for (v in values) bits(v)].join(' '));

	static function cam(c:Camera3D):Array<Float>
		return [
			c.position.x,
			c.position.y,
			c.position.z,
			c.target.x,
			c.target.y,
			c.target.z,
			c.up.x,
			c.up.y,
			c.up.z
		];

	static function v(a:Array<Float>):Vector3
		return new Vector3(a[0], a[1], a[2]);

	public static final positions = [[0., 2., 4.], [10., -3., 7.5], [0., 0., 0.], [-1e3, 50., 2e2]];
	public static final ups = [
		[0., 1., 0.],
		[0., 0., 1.],
		[.3, .9, -.1],
		[0., 0., 0.],
		[0., -2., 0.],
		[1., 0., 0.]
	];
	public static final fovys = [[45., 0.], [60., 0.], [0., 0.], [179., 0.], [1e-4, 0.], [10., 1.], [0., 1.]];

	static function targets(p:Array<Float>):Array<Array<Float>>
		return [
			[0., 0., 0.],
			[0., 2., 0.],
			p.copy(),
			[p[0], p[1] - 5, p[2]],
			[1 / 3, 2 / 7, -5.]
		];

	// What the camera's differences are measured against: the scene's size, at least 1.
	static function scale(p:Array<Float>, t:Array<Float>):Float {
		var s = 1.;
		for (x in p.concat(t))
			s = Math.max(s, Math.abs(x));
		return s;
	}

	// A camera without a view: its target at its position, no up, up along the view, or a field of view of 0, 179 or 1e-4 degrees.
	static function degenerate(p:Array<Float>, t:Array<Float>, u:Array<Float>, f:Array<Float>):Bool {
		var v = [t[0] - p[0], t[1] - p[1], t[2] - p[2]];
		var c = [v[1] * u[2] - v[2] * u[1], v[2] * u[0] - v[0] * u[2], v[0] * u[1] - v[1] * u[0]];
		inline function zero(a:Array<Float>)
			return a[0] == 0 && a[1] == 0 && a[2] == 0;
		return zero(v) || zero(u) || zero(c) || f[0] == 0 || f[0] == 179 || f[0] == 1e-4;
	}

	static function make(p:Array<Float>, t:Array<Float>, u:Array<Float>, f:Array<Float>):Camera3D
		return new Camera3D(v(p), v(t), v(u), f[0], Std.int(f[1]));

	static function main() {
		var n = 0;
		for (p in positions)
			for (t in targets(p))
				for (u in ups)
					for (f in fovys) {
						var id = 'c$n';
						n++;
						Parity.line('$id scale ${scale(p, t)} ${degenerate(p, t, u, f) ? "degenerate" : "regular"}');
						if (f[0] != 60)
							continue;
						// The moves, each from the camera as made.
						function op(label:String, change:Camera3D->Void) {
							var c = make(p, t, u, f);
							change(c);
							put('$id.$label', cam(c));
						}
						for (plane in [false, true]) {
							op('forward.$plane', c -> RCore.cameraMoveForward(c, 1.5, plane));
							op('right.$plane', c -> RCore.cameraMoveRight(c, -.7, plane));
						}
						op('pro', c -> UpdateCameraPro(c, new Vector3(1.5, -.75, .2), new Vector3(-33, 12, 4), .5));
						op('pro50', c -> {
							for (i in 0...50)
								UpdateCameraPro(c, new Vector3(.1, .05, .01), new Vector3(1.3, -.7, .2), .01);
						});
						op('prolock', c -> {
							UpdateCameraPro(c, new Vector3(0, 0, 0), new Vector3(0, -200, 0), 0);
							UpdateCameraPro(c, new Vector3(0, 0, 0), new Vector3(10, 400, 15), 0);
						});
					}
		Parity.save();
	}
}
