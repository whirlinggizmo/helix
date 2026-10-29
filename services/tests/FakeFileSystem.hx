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
		later(() -> if (failWrites) failed("write failed") else {
			files.set(path, copy);
			written();
		});
	}

	public function remove(path:String, removed:Void->Void, failed:String->Void):Void
		later(() -> {
			files.remove(path);
			removed();
		});

	public function clearFiles(cleared:Void->Void, failed:String->Void):Void
		later(() -> {
			files.clear();
			cleared();
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
