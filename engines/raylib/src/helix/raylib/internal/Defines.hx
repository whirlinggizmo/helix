package helix.raylib.internal;

#if macro
import haxe.macro.Compiler;
#end

/** Registers helix-raylib's defines, so `haxe --help-user-defines` and an editor's hxml completion show them, and the API reference lists
	them. Run by the library's `extraParams.hxml`. */
@:noCompletion
class Defines {
	#if macro
	/** helix-raylib's defines, each with its documentation. */
	public static final ALL:Array<haxe.macro.Compiler.DefineDescription> = [
		{
			define: "helix-raylib-native-root",
			doc: "Where a native program finds its files, relative to its own directory. Defaults to ../web.",
			params: ["directory"]
		},
		{
			define: "helix-raylib-host-warnings",
			doc: "Warns where the program's own code reaches the page (localStorage, the page's fullscreen) for what helix.raylib.extras or Raylib answers on every target, naming the call. Off by default."
		},
		{
			define: "helix-raylib-custom-frame-control",
			doc: "raylib's SUPPORT_CUSTOM_FRAME_CONTROL: EndDrawing only draws, and the program calls SwapScreenBuffer, WaitTime and PollInputEvents itself."
		}
	];

	/** Registers the defines. */
	public static function register():Void {
		for (define in ALL)
			Compiler.registerCustomDefine(define, "helix-raylib");
	}

	/** Prints the defines as JSON, for the API reference (`tools/gen_apidoc.py`). */
	public static function describe():Void
		Sys.println(haxe.Json.stringify(ALL));
	#end
}
