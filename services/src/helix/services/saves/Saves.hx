package helix.services.saves;

import haxe.exceptions.NotImplementedException;
import helix.platform.IFileSystem;
import helix.platform.IPollable;

/** Provides small values a game keeps between runs, by key, in one file.

	`load` reads the file once; after it the values are read and set at once, in memory. A change is kept at the next `poll`: everything
	set in a frame is written as one file, one write at a time, so a program that ends between frames loses at most that frame's changes.

	A write never blocks and finishes in the file system's `poll`, so a program that ends keeps polling until it's done. Natively, at
	`CloseRequested` the program flushes and leaves its loop when the flush answers; in a page, which ends without a last frame, it
	flushes in `IWindow.onClose`, where a write started may not finish.

	```haxe
	saves.load(() -> {
		x = saves.getFloat("x", 0);
		y = saves.getFloat("y", 0);
	});
	saves.setFloat("x", x);

	// natively, ending: the loop runs on until running is false
	case CloseRequested: saves.flush(() -> running = false, error -> running = false);
	// in a page
	window.onClose = () -> saves.flush();
	``` */
class Saves implements IPollable {
	/** Creates the saves over a file system, holding nothing until `load`.

		@param fileSystem  Where the file is kept: natively a `NativeFileSystemAdapter` over `ISystem.getDataDirectory`, in a page a
			`BrowserFileSystemAdapter` with its own name, apart from `Assets`' cache, which `Assets.clearCache` empties.
		@param name  Optional. The file's path in it; "saves.json" by default. */
	public function new(fileSystem:IFileSystem, name = "saves.json") {
		throw new NotImplementedException();
	}

	/** Reads the file. A file that isn't there yet loads as no values.

		@param loaded  Called once the values can be read.
		@param failed  Optional. Receives why the file can't be read or isn't saves; left out, it's logged. */
	public function load(loaded:Void->Void, ?failed:String->Void):Void {
		throw new NotImplementedException();
	}

	/** Gets a value indicating whether `load` has finished, so the values can be read and set. */
	public var loaded(default, null):Bool = false;

	/** Returns whether a key has a value.

		@param key  The key.
		@return  True when one was set or loaded, and not removed. */
	public function has(key:String):Bool {
		throw new NotImplementedException();
	}

	/** Returns a key's value as a string.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a string.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getString(key:String, fallback:String):String {
		throw new NotImplementedException();
	}

	/** Returns a key's value as a whole number.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a whole number.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getInt(key:String, fallback:Int):Int {
		throw new NotImplementedException();
	}

	/** Returns a key's value as a number.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a number.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getFloat(key:String, fallback:Float):Float {
		throw new NotImplementedException();
	}

	/** Returns a key's value as true or false.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't true or false.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getBool(key:String, fallback:Bool):Bool {
		throw new NotImplementedException();
	}

	/** Sets a key to a string, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setString(key:String, value:String):Void {
		throw new NotImplementedException();
	}

	/** Sets a key to a whole number, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setInt(key:String, value:Int):Void {
		throw new NotImplementedException();
	}

	/** Sets a key to a number, kept at the next `poll`.

		@param key  The key.
		@param value  The value, finite.
		@throws String  Before `load` has finished, or for a value that isn't finite. */
	public function setFloat(key:String, value:Float):Void {
		throw new NotImplementedException();
	}

	/** Sets a key to true or false, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setBool(key:String, value:Bool):Void {
		throw new NotImplementedException();
	}

	/** Removes a key's value, kept at the next `poll`; does nothing for a key with none.

		@param key  The key.
		@throws String  Before `load` has finished. */
	public function remove(key:String):Void {
		throw new NotImplementedException();
	}

	/** Removes every value, kept at the next `poll`: a reset. The file system holds nothing else of the saves', so nothing else there
		changes.

		@throws String  Before `load` has finished. */
	public function clearValues():Void {
		throw new NotImplementedException();
	}

	/** Gets a value indicating whether a change isn't kept yet: set since the last write, or being written. */
	public var pending(get, never):Bool;

	function get_pending():Bool {
		throw new NotImplementedException();
	}

	/** Starts writing what's set now, without waiting for the next `poll`; never blocks.

		Before `load` nothing is pending. A write started still finishes when the saves or their file system are disposed straight
		after, as in a page's `IWindow.onClose`, but then nothing is called.
		@param written  Optional. Called once it's kept; at once, at the next `IFileSystem.poll`, when nothing was pending.
		@param failed  Optional. Receives why it can't be written; left out, it's logged. */
	public function flush(?written:Void->Void, ?failed:String->Void):Void {
		throw new NotImplementedException();
	}

	/** Starts writing what was set since the last write, unless a write is still going; call once a frame. */
	public function poll():Void {
		throw new NotImplementedException();
	}

	/** Lets go of the values; a write in flight still finishes. */
	public function dispose():Void {
		throw new NotImplementedException();
	}
}
