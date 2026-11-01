import haxe.io.Bytes;
import helix.platform.IFileSystem;

// The harness's files, read and listed from the working directory, each answer at the next poll.
class DiskFiles implements IFileSystem {
	final waiting:Array<Void->Void> = [];

	public function new() {}

	public var root(get, never):String;

	function get_root():String
		return "";

	public var canWrite(get, never):Bool;

	function get_canWrite():Bool
		return false;

	static function load(path:String):Null<Bytes> {
		#if js
		var fs:Dynamic = js.Syntax.code("require('fs')");
		if (!fs.existsSync(path))
			return null;
		var b:Dynamic = fs.readFileSync(path);
		var out = Bytes.alloc(b.length);
		for (i in 0...b.length)
			out.set(i, b[i]);
		return out;
		#else
		return sys.FileSystem.exists(path) ? sys.io.File.getBytes(path) : null;
		#end
	}

	public function read(path:String, maxBytes:Int, loaded:Bytes->Void, missing:Void->Void, failed:String->Void):Void->Void {
		waiting.push(() -> {
			var b = load(path);
			b == null ? missing() : loaded(b);
		});
		return () -> {};
	}

	public function write(path:String, bytes:Bytes, written:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFile(path:String, deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function deleteFiles(deleted:Void->Void, failed:String->Void):Void
		waiting.push(() -> failed("read only"));

	public function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> {
			var b = load(path);
			b == null ? missing() : found(b.length, 0);
		});

	// A directory's names, a subdirectory's with "/" after it, sorted; null when there is no directory.
	static function names(directory:String):Null<Array<String>> {
		var path = directory == "" ? "." : directory;
		#if js
		var fs:Dynamic = js.Syntax.code("require('fs')");
		if (!fs.existsSync(path) || !fs.statSync(path).isDirectory())
			return null;
		var entries:Array<Dynamic> = fs.readdirSync(path, {withFileTypes: true});
		var out = [for (e in entries) e.isDirectory() ? e.name + "/" : e.name];
		#else
		if (!sys.FileSystem.exists(path) || !sys.FileSystem.isDirectory(path))
			return null;
		var out = [
			for (n in sys.FileSystem.readDirectory(path))
				sys.FileSystem.isDirectory(path + "/" + n) ? n + "/" : n
		];
		#end
		out.sort(Reflect.compare);
		return out;
	}

	public function list(directory:String, listed:Array<String>->Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> {
			var found = names(directory);
			found == null ? missing() : listed(found);
		});

	public function locate(path:String, located:(location:String, release:Void->Void) -> Void, missing:Void->Void, failed:String->Void):Void
		waiting.push(() -> missing());

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}

// Images that decode to one white pixel: the harness draws nothing.
class WhiteDecoder implements helix.platform.IImageDecoder {
	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var p = Bytes.alloc(4);
		p.fill(0, 4, 255);
		decoded(p, 1, 1);
	}

	public function poll():Void {}

	public function dispose():Void {}
}
