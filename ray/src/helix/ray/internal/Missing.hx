package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Refuses, as the program builds, a call to a raylib function helix-ray doesn't have yet, saying so: the name is raylib's, so the
	program remembered it right. */
class Missing {
	/** Returns nothing: reports the call as an error where it is.

		@param name  The raylib function.
		@param header  The header it is from.
		@return  Never returns. */
	public static function refuse(name:String, header:String):Expr {
		return Context.error('$name is raylib\'s ($header), but helix-ray doesn\'t have it yet', Context.currentPos());
	}
}
#end
