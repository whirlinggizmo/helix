package helix.platform.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Helps a library's macros say what a build can't have.

	Each refuses a call to a function the library declares but doesn't have: `unimplemented` one it will have, `unsupported` one it won't,
	by design. The library writes the function as a macro whose body returns it: the message is reported where the program calls it,
	every such call in one build, and the call keeps the function's result type, so nothing after it is typed wrong because of it.
	helix-ray declares raylib's functions it doesn't have so (`tools/gen_raylib.py`).

	```haxe
	public static macro function LoadImage(fileName:ExprOf<String>):ExprOf<Image>
		return helix.platform.macros.Build.unimplemented("LoadImage: Not implemented", macro (null : helix.ray.Image));
	``` */
class Build {
	/** Refuses a call to a function the library doesn't have yet: reports a message at the call being typed and returns what the call
		becomes.

		@param message  The message, naming the function and saying it isn't there yet.
		@param result  The expression the call becomes, typed as the function's result, with its types' full paths, as it is typed in
			the program's scope; nothing runs, as the build stops.
		@return  The result. */
	public static function unimplemented(message:String, result:Expr):Expr {
		Context.reportError(message, Context.currentPos());
		return result;
	}

	/** Refuses a call to a function the library won't have, by design: reports a message at the call being typed and returns what the
		call becomes.

		@param message  The message, naming the function, why it isn't there, and what to use instead.
		@param result  The expression the call becomes, as `unimplemented` takes it.
		@return  The result. */
	public static function unsupported(message:String, result:Expr):Expr {
		Context.reportError(message, Context.currentPos());
		return result;
	}
}
#end
