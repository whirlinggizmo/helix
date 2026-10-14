import helix.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter;
import helix.adapters.store.indexeddb.IndexedDbStoreAdapter;

class ServiceEnvironment {
	public var fetcher = new FetchApiHttpAdapter();
	public var remoteStreams = true;
	public var base:String;
	public var storage:IndexedDbStoreAdapter;
	public var packaged:IndexedDbStoreAdapter;
	public var audio:WebAudioAdapter;
	public var decoder = new WebAudioDecoderAdapter();

	public function new() {
		var params = new js.html.URLSearchParams(js.Browser.window.location.search);
		base = js.Browser.window.location.origin;
		storage = new IndexedDbStoreAdapter(params.get("db"));
		packaged = new IndexedDbStoreAdapter(params.get("db") + "-unused");
		audio = new WebAudioAdapter();
		audio.unlock();
	}

	public function start(poll:Void->Void, done:Void->Bool, result:Void->Dynamic):Void {
		var started = haxe.Timer.stamp(), timer = 0;
		timer = js.Browser.window.setInterval(() -> {
			try {
				poll();
				if (done()) {
					js.Browser.window.clearInterval(timer);
					js.Syntax.code("window.serviceResult={0}", result());
				} else if (haxe.Timer.stamp() - started > 30)
					throw "Service test timeout";
			} catch (error:Dynamic) {
				js.Browser.window.clearInterval(timer);
				js.Syntax.code("window.serviceResult={0}",
					{passed: false, error: Std.string(error), stack: haxe.CallStack.toString(haxe.CallStack.exceptionStack())});
			}
		}, 5);
	}
}
