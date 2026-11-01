package trial;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Logs helix-ray's draw calls for grading, one line each, and each frame's end: added to helix.ray.Raylib at compile time by
	`--macro trial.Recorder.install()`, so the game and the library are left as they are. */
class Recorder {
	#if macro
	public static function install():Void {
		haxe.macro.Compiler.addGlobalMetadata("helix.ray.Raylib", "@:build(trial.Recorder.build())", false, true, false);
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			var name = field.name;
			if (!(StringTools.startsWith(name, "Draw") || name == "EndDrawing" || name == "BeginMode2D" || name == "EndMode2D"
				|| name == "BeginScissorMode"))
				continue;
			switch field.kind {
				case FFun(f) if (f.expr != null):
					var args = [for (a in f.args) macro trial.Recorder.value($i{a.name})];
					var body = f.expr;
					f.expr = macro {
						trial.Recorder.log($v{name}, [$a{args}]);
						$body;
					};
				case _:
			}
		}
		return fields;
	}
	#else
	static var frame = 0;

	public static function log(name:String, args:Array<String>):Void {
		var line = "REC " + frame + " " + name + " " + args.join(" ");
		#if js
		js.Browser.console.log(line);
		#else
		Sys.println(line);
		#end
		if (name == "EndDrawing")
			frame++;
	}

	public static function value(v:Dynamic):String {
		if (v == null)
			return "null";
		if (Std.isOfType(v, Float) || Std.isOfType(v, Int) || Std.isOfType(v, Bool))
			return Std.string(v);
		if (Std.isOfType(v, String))
			return haxe.Json.stringify(v);
		if (Std.isOfType(v, helix.ray.Vector2))
			return "(" + v.x + "," + v.y + ")";
		if (Std.isOfType(v, helix.ray.Rectangle))
			return "[" + v.x + "," + v.y + "," + v.width + "," + v.height + "]";
		if (Std.isOfType(v, helix.ray.Color))
			return "#" + v.r + "," + v.g + "," + v.b + "," + v.a;
		if (Std.isOfType(v, helix.ray.Camera2D))
			return "cam(" + v.offset.x + "," + v.offset.y + "," + v.target.x + "," + v.target.y + "," + v.rotation + "," + v.zoom + ")";
		return "?";
	}
	#end
}
