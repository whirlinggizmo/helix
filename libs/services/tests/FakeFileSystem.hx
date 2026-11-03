import haxe.io.Bytes;
import helix.platform.IFileSystem;

/** Stands in for a file system in the services' tests: files in memory, each operation answered at the next `poll`, and failures the
	test turns on. */
class FakeFileSystem implements IFileSystem {
	/** Gets the files, by path. */
	public final files = new Map<String, Bytes>();

	/** Gets or sets whether reads fail. */
	public var failReads = false;

	/** Gets or sets whether writes fail. */
	public var failWrites = false;

	/** Gets when each file was last written, by path: the fake's clock, `time`, at its write. */
	public final modified = new Map<String, Float>();

	/** Gets or sets the fake's clock, in seconds, given to each file written. */
	public var time = 0.;

	/** Gets or sets which paths' writes fail, when it returns true; null for none. */
	public var failWrite:Null<String->Bool> = null;

	/** Gets the writes and deletes as they landed, in order: "write <path>", "delete <path>". */
	public final ops:Array<String> = [];

	/** Gets how many writes were made. */
	public var writes(default, null) = 0;

	/** Gets the locations located and not yet released. */
	public var held(default, null) = 0;

	final queued:Array<Void->Void> = [];

	/** Creates one with no files. */
	public function new() {}

	/** Gets "fake". */
	public var root(get, never):String;

	function get_root():String
		return "fake";

	/** Gets true. */
	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return true;

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		var aborted = false;
		later(() -> if (!aborted) {
			var bytes = files.get(path);
			if (failReads)
				failed("read failed");
			else if (bytes == null)
				missing();
			else if (bytes.length > maxBytes)
				failed("too large");
			else
				loaded(bytes);
		});
		return () -> aborted = true;
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void {
		var copy = Bytes.alloc(bytes.length);
		copy.blit(0, bytes, 0, bytes.length);
		writes++;
		later(() -> if (failWrites || failWrite != null && failWrite(path)) failed("write failed") else {
			ops.push('write $path');
			files.set(path, copy);
			modified.set(path, time);
			written();
		});
	}

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		later(() -> {
			ops.push('delete $path');
			files.remove(path);
			modified.remove(path);
			deleted();
		});

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		later(() -> {
			files.clear();
			modified.clear();
			deleted();
		});

	public function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:Void->Void, failed:String->Void):Void
		later(() -> if (failReads) failed("read failed") else if (files.exists(path)) found(files.get(path).length,
			modified.exists(path) ? modified.get(path) : 0) else missing());

	public function list(directory:String, listed:Array<String>->Void, missing:Void->Void, failed:String->Void):Void
		later(() -> {
			if (failReads) {
				failed("read failed");
				return;
			}
			var prefix = directory == "" ? "" : directory + "/", names = [];
			for (path in files.keys())
				if (StringTools.startsWith(path, prefix)) {
					var rest = path.substr(prefix.length),
						slash = rest.indexOf("/");
					var name = slash < 0 ? rest : rest.substr(0, slash + 1);
					if (names.indexOf(name) < 0)
						names.push(name);
				}
			names.sort(Reflect.compare);
			names.length == 0
			&& directory != "" ? missing() : listed(names);
		});

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		later(() -> if (files.exists(path)) {
			held++;
			var released = false;
			located('fake:$path', () -> if (!released) {
				released = true;
				held--;
			});
		} else missing());

	/** Gets a value indicating whether an operation waits for the next poll. */
	public var busy(get, never):Bool;

	function get_busy():Bool
		return queued.length > 0;

	public function poll():Void {
		var due = queued.splice(0, queued.length);
		for (f in due)
			f();
	}

	public function dispose():Void {}

	function later(f:Void->Void):Void
		queued.push(f);
}
