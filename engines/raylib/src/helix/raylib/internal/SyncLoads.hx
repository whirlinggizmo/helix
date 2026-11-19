package helix.raylib.internal;

#if !macro
/** Answers raylib's synchronous loads (`LoadTexture`, `LoadImage`, `LoadSound` and the rest) the one way: a file in memory, ensured
	(`EnsureAssetAsync`) or brought in by an async load this run, is built at once. Natively one that isn't is brought in during the call,
	the load waiting for its async form. In a page it can't be, the browser reading its cache and decoding only asynchronously: the load
	logs why and returns raylib's empty result, as raylib's load of a missing file does. */
@:noCompletion
class SyncLoads {
	/** Returns a synchronous load's result.

		@param path  The file, normalized.
		@param ready  Whether the file is in memory as the build needs it.
		@param build  Builds the result from what is in memory.
		@param async  The load's async form, natively waited for when the file isn't ready.
		@param empty  raylib's empty result, for a file that can't be loaded.
		@return  The result, or the empty one. */
	public static function load<T>(path:String, ready:Bool, build:Void->T, async:(T->Void, String->Void)->Void, empty:Void->T):T {
		if (ready)
			return build();
		#if js
		Runtime.log(4, 'FILEIO: [$path] Failed to load: not ensured. See EnsureAssetsAsync');
		return empty();
		#else
		return Runtime.answered(answer -> async(answer, error -> {
			Runtime.log(4, error);
			answer(empty());
		}));
		#end
	}
}
#end
