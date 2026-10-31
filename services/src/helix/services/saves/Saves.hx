package helix.services.saves;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.IFileSystem;
import helix.platform.IPollable;

/** Provides small values a game keeps between runs, by key, in one file.

	`load` reads the file once. After that, values are read and set in memory, without waiting. A change is written at the next `poll`:
	everything set in a frame as one file, one write at a time. A value set, or deleted, before the read has finished is held and made
	once it has, so it wins over what the file kept: a program can save as it starts, before it has asked for anything back.

	Set a value when it changes, not as the program ends. A page's end gives a write no time to finish, so what is set there is lost. A
	native program leaving its loop flushes first, and leaves when the flush answers.

	```haxe
	saves.load(() -> {
		x = saves.getFloat("x", 0);
		y = saves.getFloat("y", 0);
	});
	// as the position changes
	saves.setFloat("x", x);
	saves.setFloat("y", y);

	// natively, ending: the loop runs on until running is false
	case CloseRequested: saves.flush(() -> running = false, error -> running = false);
	``` */
class Saves implements IPollable {
	/** The largest saves file read. It is far more than small values need, so a larger file doesn't hold saves. */
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
	// The loads asked for while the first is in flight, answered together.
	var loads:Array<Flush> = [];
	// What was set or deleted before the read finished, made after it, in order.
	var held:Array<Void->Void> = [];

	/** Creates the saves over a file system, holding nothing until `load`.

		@param fileSystem  The file system the file is kept in. Make it over `ISystem.getDataDirectory`: a `NativeFileSystemAdapter`
			natively, and a `BrowserFileSystemAdapter` in a page.
		@param name  Optional. The file's path in the file system. Defaults to "saves.json". */
	public function new(fileSystem:IFileSystem, name = "saves.json") {
		this.fileSystem = fileSystem;
		this.name = name;
	}

	/** Reads the file. A file that doesn't exist yet loads as no values.

		Calling it again answers too: with the first load's outcome while that is in flight, and at the next `poll` once it has finished.

		@param loaded  Called once the values can be read.
		@param failed  Optional. Receives why the file can't be read or doesn't hold saves. When omitted, the failure is logged. */
	public function load(loaded:Void->Void, ?failed:String->Void):Void {
		var asked = new Flush(loaded, failed);
		if (this.loaded) {
			answered.push(asked);
			return;
		}
		loads.push(asked);
		if (loading)
			return;
		loading = true;
		function finish(failure:Null<String>) {
			loading = false;
			var asked = loads;
			loads = [];
			if (disposed)
				return;
			this.loaded = failure == null;
			if (this.loaded && held.length > 0) {
				for (make in held)
					make();
				held = [];
				change();
			}
			for (load in asked)
				if (failure == null)
					load.written();
				else
					fail(load.failed, failure);
		}
		fileSystem.read(name, MAX_BYTES, bytes -> {
			var parsed:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
			if (parsed == null || Type.typeof(parsed) != TObject)
				finish('$name isn\'t saves');
			else {
				values = parsed;
				finish(null);
			}
		}, () -> finish(null), message -> finish(message));
	}

	/** Gets a value indicating whether `load` has finished, so values can be read and set. */
	public var loaded(default, null):Bool = false;

	/** Returns whether a key has a value.

		@param key  The key.
		@return  True when a value was set or loaded, and not deleted since. */
	public function hasKey(key:String):Bool {
		return values.exists(key);
	}

	/** Returns a key's value as a string.

		@param key  The key.
		@param fallback  The value to return when the key has no value, or one that isn't a string.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getString(key:String, fallback:String):String {
		var value = read(key);
		return value != null && Std.isOfType(value, String) ? value : fallback;
	}

	/** Returns a key's value as a whole number.

		@param key  The key.
		@param fallback  The value to return when the key has no value, or one that isn't a whole number in Int's range.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getInt(key:String, fallback:Int):Int {
		var value = number(read(key));
		return value != null && Math.ffloor(value) == value && value >= -2147483648. && value <= 2147483647.?Std.int(value)
		:fallback;
	}

	/** Returns a key's value as a number.

		@param key  The key.
		@param fallback  The value to return when the key has no value, or one that isn't a finite number.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getFloat(key:String, fallback:Float):Float {
		var value = number(read(key));
		return value != null ? value : fallback;
	}

	/** Returns a key's value as true or false.

		@param key  The key.
		@param fallback  The value to return when the key has no value, or one that isn't true or false.
		@return  The value, or the fallback.
		@throws String  Before `load` has finished. */
	public function getBool(key:String, fallback:Bool):Bool {
		var value = read(key);
		return value != null && Std.isOfType(value, Bool) ? value : fallback;
	}

	/** Sets a key to a string, kept at the next `poll`.

		@param key  The key.
		@param value  The value. */
	public function setString(key:String, value:String):Void {
		write(key, value);
	}

	/** Sets a key to a whole number, kept at the next `poll`.

		@param key  The key.
		@param value  The value. */
	public function setInt(key:String, value:Int):Void {
		write(key, value);
	}

	/** Sets a key to a number, kept at the next `poll`.

		@param key  The key.
		@param value  The value. Must be finite.
		@throws String  When the value isn't finite. */
	public function setFloat(key:String, value:Float):Void {
		if (!Math.isFinite(value))
			throw '$key can\'t be saved as $value: a value is finite';
		write(key, value);
	}

	/** Sets a key to true or false, kept at the next `poll`.

		@param key  The key.
		@param value  The value. */
	public function setBool(key:String, value:Bool):Void {
		write(key, value);
	}

	/** Deletes a key and its value, kept at the next `poll`. Does nothing for a key with no value.

		@param key  The key. */
	public function deleteKey(key:String):Void {
		if (!loaded) {
			held.push(() -> values.remove(key));
			return;
		}
		if (values.remove(key))
			change();
	}

	/** Deletes every key, kept at the next `poll`, resetting the saves.

		Only the saves file changes. Nothing else in the file system belongs to the saves. */
	public function deleteKeys():Void {
		if (!loaded) {
			held.push(() -> values = {});
			return;
		}
		values = {};
		change();
	}

	/** Gets a value indicating whether a change isn't kept yet, because it was set since the last write or is being written. */
	public var pending(get, never):Bool;

	function get_pending():Bool {
		return changed || writing;
	}

	/** Starts writing the current values without waiting for the next `poll`. Never blocks.

		Before `load`, nothing is pending. A write that has started still finishes when the saves or their file system are disposed
		straight after, but then nothing is called.

		@param written  Optional. Called once the values are kept, or at the next `poll` when nothing was pending.
		@param failed  Optional. Receives why the values can't be written. When omitted, the failure is logged. */
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

	/** Starts writing what was set since the last write, unless a write is still in flight.

		Call it once a frame. After a failed write, it waits for another change before trying again. */
	public function poll():Void {
		var due = answered;
		answered = [];
		for (flush in due)
			if (flush.written != null)
				flush.written();
		if (changed && !writing && !lastFailed)
			start();
	}

	/** Releases the values. A write in flight still finishes.

		Call it before disposing the file system it was given. */
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
		if (!loaded) {
			held.push(() -> values.set(key, value));
			return;
		}
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

/** Represents a flush's callbacks. */
private class Flush {
	/** Gets the function called once the write is kept. */
	public final written:Null<Void->Void>;

	/** Gets the function that receives why the write failed. */
	public final failed:Null<String->Void>;

	/** Creates a flush's callbacks. */
	public function new(written:Null<Void->Void>, failed:Null<String->Void>) {
		this.written = written;
		this.failed = failed;
	}
}
