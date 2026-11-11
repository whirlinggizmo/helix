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
			doc: "Warns where the program's own code reaches the page (localStorage, the page's fullscreen) for what Raylib answers on every target, naming the call. Off by default."
		},
		{
			define: "helix-raylib-portable-sys",
			doc: "Natively, refuses what a page can't answer, as a build for the page does: Haxe's file calls (sys.io.File, sys.FileSystem), sys.io.Process and the Sys calls a page has no answer for, each refusal naming the raylib call to use. So a program that builds natively builds for the page. Off by default, when a native program has Haxe's own."
		},
		{
			define: "helix-raylib-frame-stats",
			doc: "For timing a program without changing it: with the frame_stats option (--frame_stats=120,1200 natively, ?frame_stats=120,1200 in a page), records frames 121 to 1200, prints the stats as frame_stats and a JSON object, and closes the window. In a page the object is also window.helixResult. Off by default."
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
