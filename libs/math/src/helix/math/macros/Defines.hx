package helix.math.macros;

#if macro
import haxe.macro.Compiler;
#end

/** Registers helix-math's defines, so `haxe --help-user-defines` and an editor's hxml completion show them, and the API reference lists
	them. Run by the library's `extraParams.hxml`. */
@:noCompletion
class Defines {
	#if macro
	/** helix-math's defines, each with its documentation. */
	public static final ALL:Array<haxe.macro.Compiler.DefineDescription> = [
		{
			define: "helix-math-standard-trig",
			doc: "Makes Trig's functions the standard library's (Math.sin and the others), and with them the cosines and sines helix-math's rotations take. Faster in a browser. A result's last bit may then differ between targets, so a simulation no longer plays alike on each. Off by default."
		}
	];

	/** Registers the defines. */
	public static function register():Void {
		for (define in ALL)
			Compiler.registerCustomDefine(define, "helix-math");
	}

	/** Prints the defines as JSON, for the API reference (`tools/gen_apidoc.py`). */
	public static function describe():Void
		Sys.println(haxe.Json.stringify(ALL));
	#end
}
