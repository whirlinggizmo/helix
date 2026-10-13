import helix.adapters.fetch.haxehttp.HaxeHttpFetchAdapter;
import helix.adapters.audio.sokol.SokolAudioAdapter;
import helix.adapters.storage.filesystem.FileStorageAdapter;

class ServiceEnvironment {
	public var fetcher = new HaxeHttpFetchAdapter();
	public var remoteStreams = false;
	public var base:String;
	public var storage:FileStorageAdapter;
	public var packaged:FileStorageAdapter;
	public var audio:SokolAudioAdapter;

	public function new() {
		var args = Sys.args();
		base = args[0];
		storage = new FileStorageAdapter(args[1]);
		packaged = new FileStorageAdapter(args[1] + "-unused", true);
		audio = new SokolAudioAdapter();
	}

	public function start(poll:Void->Void, done:Void->Bool, result:Void->Dynamic):Void {
		var started = haxe.Timer.stamp();
		try {
			while (!done()) {
				poll();
				if (haxe.Timer.stamp() - started > 30)
					throw "Service test timeout";
				Sys.sleep(.005);
			}
			Sys.println(haxe.Json.stringify(result()));
		} catch (error:Dynamic) {
			Sys.println(haxe.Json.stringify({passed: false, error: Std.string(error), stack: haxe.CallStack.toString(haxe.CallStack.exceptionStack())}));
			Sys.exit(1);
		}
	}
}
