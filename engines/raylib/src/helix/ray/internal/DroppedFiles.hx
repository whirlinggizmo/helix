package helix.ray.internal;

/** Reads the files dropped on the window into memory, for `IsFileDropped` and `LoadDroppedFiles`, which read the paths through it.

	A program naming either links this class, and its start sets `Runtime.dropping`, so every drop from the first frame on is read, as
	raylib's are; a program naming neither never links the reading, nor the assets and caches the dropped files are kept in, and its drops
	are ignored. */
@:noCompletion
class DroppedFiles {
	static function __init__():Void {
		Runtime.dropping = drop;
	}

	/** Returns the paths of the files last dropped, once each was read; empty when none were or after `UnloadDroppedFiles`.

		@return  The paths, `Runtime.dropped` itself. */
	public static function paths():Array<String> {
		return Runtime.dropped;
	}

	// Reads the files of a drop into memory in place of the last drop's, then lists their paths, as raylib's do.
	static function drop(count:Int):Void {
		Runtime.loading();
		var paths:Array<Null<String>> = [for (_ in 0...count) null], left = count;
		function answered():Void {
			if (--left > 0)
				return;
			for (path in Runtime.held)
				Runtime.memory.remove(path);
			Runtime.held = [for (path in paths) if (path != null) path];
			Runtime.dropped = Runtime.held.copy();
		}
		for (i in 0...count)
			Runtime.window.readDroppedFile(i, 1 << 30, (name, bytes) -> {
				paths[i] = Runtime.memory.addDropped(name, bytes);
				answered();
			}, error -> {
				Runtime.log(4, 'FILEIO: Failed to read a dropped file: $error');
				answered();
			});
	}
}
