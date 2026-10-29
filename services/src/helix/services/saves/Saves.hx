package helix.services.saves;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Bytes;
import helix.log.Log;
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
	/** The largest saves file read: far more than small values need, so a file this large isn't saves. */
	static inline final MAX_BYTES = 1 << 20;

	final fileSystem:IFileSystem;
	final name:String;
	var values:DynamicAccess<Dynamic> = {};
	var loading = false;
	// Set since the last write started; a write is in flight; the last write failed, so poll waits for a change before trying again.
	var changed = false;
	var writing = false;
	var lastFailed = false;
	var disposed = false;
	// Flushes waiting for the write in flight, and for the next one.
	var current:Array<Flush> = [];
	var waiting:Array<Flush> = [];
	// Flushes with nothing pending, answered at the next poll.
	var answered:Array<Flush> = [];

	/** Creates the saves over a file system, holding nothing until `load`.

		@param fileSystem  Where the file is kept: natively a `NativeFileSystemAdapter` over `ISystem.getDataDirectory`, in a page a
			`BrowserFileSystemAdapter` with its own name, apart from `Assets`' cache, which `Assets.clearCache` empties.
		@param name  Optional. The file's path in it; "saves.json" by default. */
	public function new(fileSystem:IFileSystem, name = "saves.json") {
		this.fileSystem = fileSystem;
		this.name = name;
	}

	/** Reads the file. A file that isn't there yet loads as no values.

		@param loaded  Called once the values can be read.
		@param failed  Optional. Receives why the file can't be read or isn't saves; left out, it's logged. */
	public function load(loaded:Void->Void, ?failed:String->Void):Void {
		if (loading || this.loaded)
			return;
		loading = true;
		fileSystem.read(name, MAX_BYTES, bytes -> {
			loading = false;
			if (disposed)
				return;
			var parsed:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
			if (parsed == null || Type.typeof(parsed) != TObject) {
				fail(failed, '$name isn\'t saves');
				return;
			}
			values = parsed;
			this.loaded = true;
			loaded();
		}, () -> {
			loading = false;
			if (disposed)
				return;
			this.loaded = true;
			loaded();
		}, message -> {
			loading = false;
			if (!disposed)
				fail(failed, message);
		});
	}

	/** Gets a value indicating whether `load` has finished, so the values can be read and set. */
	public var loaded(default, null):Bool = false;

	/** Returns whether a key has a value.

		@param key  The key.
		@return  True when one was set or loaded, and not removed. */
	public function has(key:String):Bool {
		return values.exists(key);
	}

	/** Returns a key's value as a string.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a string.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getString(key:String, fallback:String):String {
		var value = read(key);
		return value != null && Std.isOfType(value, String) ? value : fallback;
	}

	/** Returns a key's value as a whole number.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a whole number.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getInt(key:String, fallback:Int):Int {
		var value = number(read(key));
		return value != null && Math.ffloor(value) == value && value >= -2147483648. && value <= 2147483647.?Std.int(value)
		:fallback;
	}

	/** Returns a key's value as a number.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't a number.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getFloat(key:String, fallback:Float):Float {
		var value = number(read(key));
		return value != null ? value : fallback;
	}

	/** Returns a key's value as true or false.

		@param key  The key.
		@param fallback  What to return when it has none, or one that isn't true or false.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getBool(key:String, fallback:Bool):Bool {
		var value = read(key);
		return value != null && Std.isOfType(value, Bool) ? value : fallback;
	}

	/** Sets a key to a string, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setString(key:String, value:String):Void {
		write(key, value);
	}

	/** Sets a key to a whole number, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setInt(key:String, value:Int):Void {
		write(key, value);
	}

	/** Sets a key to a number, kept at the next `poll`.

		@param key  The key.
		@param value  The value, finite.
		@throws String  Before `load` has finished, or for a value that isn't finite. */
	public function setFloat(key:String, value:Float):Void {
		if (!Math.isFinite(value))
			throw '$key can\'t be saved as $value: a value is finite';
		write(key, value);
	}

	/** Sets a key to true or false, kept at the next `poll`.

		@param key  The key.
		@param value  The value.
		@throws String  Before `load` has finished. */
	public function setBool(key:String, value:Bool):Void {
		write(key, value);
	}

	/** Removes a key's value, kept at the next `poll`; does nothing for a key with none.

		@param key  The key.
		@throws String  Before `load` has finished. */
	public function remove(key:String):Void {
		ready();
		if (values.remove(key))
			change();
	}

	/** Removes every value, kept at the next `poll`: a reset. The file system holds nothing else of the saves', so nothing else there
		changes.

		@throws String  Before `load` has finished. */
	public function clearValues():Void {
		ready();
		values = {};
		change();
	}

	/** Gets a value indicating whether a change isn't kept yet: set since the last write, or being written. */
	public var pending(get, never):Bool;

	function get_pending():Bool {
		return changed || writing;
	}

	/** Starts writing what's set now, without waiting for the next `poll`; never blocks.

		Before `load` nothing is pending. A write started still finishes when the saves or their file system are disposed straight
		after, as in a page's `IWindow.onClose`, but then nothing is called.
		@param written  Optional. Called once it's kept; at the next `poll` when nothing was pending.
		@param failed  Optional. Receives why it can't be written; left out, it's logged. */
	public function flush(?written:Void->Void, ?failed:String->Void):Void {
		var flush = new Flush(written, failed);
		if (!changed && !writing) {
			answered.push(flush);
			return;
		}
		if (!changed) {
			current.push(flush);
			return;
		}
		waiting.push(flush);
		lastFailed = false;
		if (!writing)
			start();
	}

	/** Starts writing what was set since the last write, unless a write is still going; call once a frame. */
	public function poll():Void {
		var due = answered;
		answered = [];
		for (flush in due)
			if (flush.written != null)
				flush.written();
		if (changed && !writing && !lastFailed)
			start();
	}

	/** Lets go of the values, before the file system it was given is disposed; a write in flight still finishes. */
	public function dispose():Void {
		disposed = true;
		values = {};
		loaded = false;
		current = [];
		waiting = [];
		answered = [];
	}

	function ready():Void {
		if (!loaded)
			throw 'the saves are read and set after load';
	}

	function read(key:String):Dynamic {
		ready();
		return values.get(key);
	}

	// A value as a finite number, or null for anything else: a string, true and false aren't numbers on any target.
	static function number(value:Dynamic):Null<Float> {
		if (value == null || Std.isOfType(value, String) || Std.isOfType(value, Bool) || !Std.isOfType(value, Float))
			return null;
		var number:Float = value;
		return Math.isFinite(number) ? number : null;
	}

	function write(key:String, value:Dynamic):Void {
		ready();
		values.set(key, value);
		change();
	}

	function change():Void {
		changed = true;
		lastFailed = false;
	}

	// Writes the values as they are now; the flushes waiting are answered by this write.
	function start():Void {
		changed = false;
		writing = true;
		current = waiting;
		waiting = [];
		fileSystem.write(name, Bytes.ofString(Json.stringify(values)), () -> {
			writing = false;
			if (disposed)
				return;
			var done = current;
			current = [];
			for (flush in done)
				if (flush.written != null)
					flush.written();
			// A flush asked for while this write was in flight wants what was set since: written now, not at the next poll.
			if (waiting.length > 0)
				start();
		}, message -> {
			writing = false;
			if (disposed)
				return;
			changed = true;
			lastFailed = true;
			var done = current;
			current = [];
			if (done.length == 0)
				Log.warn('$name can\'t be written: $message', "saves");
			for (flush in done)
				fail(flush.failed, '$name can\'t be written: $message');
			if (waiting.length > 0)
				start();
		});
	}

	static function fail(failed:Null<String->Void>, message:String):Void {
		if (failed != null)
			failed(message);
		else
			Log.warn(message, "saves");
	}
}

/** A flush's answers. */
private class Flush {
	/** Gets what's called once the write is kept. */
	public final written:Null<Void->Void>;

	/** Gets what receives why it can't be written. */
	public final failed:Null<String->Void>;

	/** Creates a flush's answers. */
	public function new(written:Null<Void->Void>, failed:Null<String->Void>) {
		this.written = written;
		this.failed = failed;
	}
}
