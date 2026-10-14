import helix.adapters.http.haxehttp.HaxeHttpAdapter;
import helix.adapters.audiodecoder.libsndfile.LibsndfileAudioDecoderAdapter;
import helix.adapters.audiodecoder.libsndfile.LibsndfilePcmFiles;
import helix.adapters.audio.sokol.SokolAudioAdapter;
import helix.adapters.store.filesystem.FileSystemStoreAdapter;

class ServiceEnvironment {
	public var fetcher = new HaxeHttpAdapter();
	public var remoteStreams = false;
	public var base:String;
	public var storage:FileSystemStoreAdapter;
	public var packaged:FileSystemStoreAdapter;
	public var audio:SokolAudioAdapter;
	public var decoder = new LibsndfileAudioDecoderAdapter();

	public function new() {
		var args = Sys.args();
		base = args[0];
		storage = new FileSystemStoreAdapter(args[1]);
		packaged = new FileSystemStoreAdapter(args[1] + "-unused");
		audio = new SokolAudioAdapter(new LibsndfilePcmFiles());
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
