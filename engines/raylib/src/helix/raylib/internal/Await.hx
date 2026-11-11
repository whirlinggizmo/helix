package helix.raylib.internal;

#if js
/** A page's `await`, placed in the function calling it (`Wait`). */
@:noCompletion
class Await {
	/** Waits for a promise's value, in an async function.

		@param promise  The promise, or a value, which is returned as it is.
		@return  The value. */
	public static extern inline function value<T>(promise:T):T {
		return js.Syntax.code("(await {0})", promise);
	}

	/** Waits for a promise's value, in an async function.

		@param promise  The promise.
		@return  Its value. */
	public static extern inline function promised<T>(promise:js.lib.Promise<T>):T {
		return js.Syntax.code("(await {0})", promise);
	}

	/** Waits for a promise that has no value, in an async function.

		@param promise  The promise. */
	public static extern inline function finished(promise:js.lib.Promise<Dynamic>):Void {
		js.Syntax.code("(await {0})", promise);
	}
}
#end
