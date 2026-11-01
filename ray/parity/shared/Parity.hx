import helix.ray.*;
import helix.ray.internal.Frame;
import helix.ray.internal.Runtime;

/** The Haxe side of a value suite (ray/parity/README.md): what helix-ray gives, a line at a time, each led by its case's name, as
	shared/parity.h prints raylib's; `save` writes them to the file the command line names. tools/ray_parity.py compares the two. */
@:access(helix.ray.internal.Frame)
class Parity {
	static final out = new StringBuf();

	/** Whether a drawn vertex's z is printed: 2D vertices carry rlgl's batch depth in raylib, draw order in helix-ray. */
	public static var depth = true;

	public static function V2(x:Float, y:Float):Vector2
		return new Vector2(x, y);

	public static function V3(x:Float, y:Float, z:Float):Vector3
		return new Vector3(x, y, z);

	public static function R(x:Float, y:Float, w:Float, h:Float):Rectangle
		return new Rectangle(x, y, w, h);

	/** A line of output. */
	public static function line(s:String):Void
		out.add(s + "\n");

	/** helix-ray drawing into a frame of its own, on graphics that keep nothing, for `shape` to read back. */
	public static function open():Void {
		Raylib.SetTraceLogLevel(Raylib.LOG_NONE);
		var g = new StubGraphics();
		Runtime.graphics = g;
		Runtime.frame = new Frame(g);
	}

	/** What was drawn since the last shape, as parity.h's shape prints rlgl's batch: the batch flushed into the frame's pass, and the
		pass's immediate vertices read back; the frame is drawn after. */
	public static function shape(name:String):Void {
		var f = Runtime.frame, lines = [];
		f.flush();
		for (d in f.pass.draws) {
			if (d.buffers != null)
				continue;
			for (i in d.first...d.first + d.count) {
				var at = i * 48;
				var v = [for (k in 0...8) if (depth || k != 2) Std.string(f.data.getFloat(at + k * 4))];
				var c = [for (k in 8...12) Std.string(Math.round(f.data.getFloat(at + k * 4) * 255))];
				lines.push('$name ${d.lines ? "L" : "T"} ' + v.concat(c).join(" "));
			}
		}
		line('$name drawn ${lines.length}');
		for (l in lines)
			line(l);
		f.draw(64, 64, true);
	}

	static function floats(name:String, label:String, v:Null<Array<Float>>, n:Int):Void
		line('$name $label ${v == null ? -1 : n}' + (v == null ? "" : [for (i in 0...n) " " + v[i]].join("")));

	/** A mesh's counts, then its vertices, texture coordinates, normals, tangents and indices (-1 for one it hasn't). */
	public static function mesh(name:String, m:Mesh):Void {
		line('$name mesh ${m.vertexCount} ${m.triangleCount}');
		floats(name, "vertices", m.vertices, m.vertexCount * 3);
		floats(name, "texcoords", m.texcoords, m.vertexCount * 2);
		floats(name, "normals", m.normals, m.vertexCount * 3);
		floats(name, "tangents", m.tangents, m.vertexCount * 4);
		line('$name indices ${m.indices == null ? -1 : m.triangleCount * 3}'
			+ (m.indices == null ? "" : [for (i in 0...m.triangleCount * 3) " " + m.indices[i]].join("")));
	}

	public static function hit(name:String, c:RayCollision):Void
		line('$name hit ${c.hit ? 1 : 0} ${c.distance} ${c.point.x} ${c.point.y} ${c.point.z} ${c.normal.x} ${c.normal.y} ${c.normal.z}');

	public static function flag(name:String, b:Bool):Void
		line('$name flag ${b ? 1 : 0}');

	public static function num(name:String, x:Float):Void
		line('$name num $x');

	public static function vec2(name:String, v:Vector2):Void
		line('$name vec2 ${v.x} ${v.y}');

	public static function rect(name:String, r:Rectangle):Void
		line('$name rect ${r.x} ${r.y} ${r.width} ${r.height}');

	public static function color(name:String, c:Color):Void
		line('$name color ${c.r} ${c.g} ${c.b} ${c.a}');

	/** An image's size, format and mipmaps, then its first level's bytes in hex, 48 to a line, as parity.h's image prints them. */
	public static function image(name:String, m:Image):Void {
		var size = m.data == null ? 0 : Raylib.GetPixelDataSize(m.width, m.height, m.format);
		line('$name image ${m.width} ${m.height} ${m.format} ${m.mipmaps} $size');
		var i = 0;
		while (i < size) {
			var hex = new StringBuf();
			for (k in i...(i + 48 < size ? i + 48 : size))
				hex.add(StringTools.hex(m.data.get(k), 2).toLowerCase());
			line('$name data #$hex');
			i += 48;
		}
	}

	public static function box(name:String, b:BoundingBox):Void
		line('$name box ${b.min.x} ${b.min.y} ${b.min.z} ${b.max.x} ${b.max.y} ${b.max.z}');

	/** Writes the lines to the file the command line names. */
	public static function save():Void {
		#if js
		js.Syntax.code("require('fs').writeFileSync(process.argv[2], {0})", out.toString());
		#else
		sys.io.File.saveContent(Sys.args()[0], out.toString());
		#end
	}
}
