package helix.platform.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Helps a library's macros say what a build can't have.

	`unimplemented` refuses a call to a function the library declares but doesn't have. The library writes the function as a macro
	whose body returns it: the message is reported where the program calls it, every such call in one build, and the call keeps the
	function's result type, so nothing after it is typed wrong because of it. helix-ray declares raylib's functions it doesn't have so
	(`tools/gen_raylib.py`).

	```haxe
	public static macro function LoadImage(fileName:ExprOf<String>):ExprOf<Image>
		return helix.platform.macros.Build.unimplemented("LoadImage: Not implemented", macro (null : helix.ray.Image));
	``` */
class Build {
	/** Reports a message at the call being typed and returns what the call becomes.

		@param message  The message, naming the function: what to use instead, or that the library doesn't have it yet.
		@param result  The expression the call becomes, typed as the function's result, with its types' full paths, as it is typed in
			the program's scope; nothing runs, as the build stops.
		@return  The result. */
	public static function unimplemented(message:String, result:Expr):Expr {
		Context.reportError(message, Context.currentPos());
		return result;
	}
}
#end
