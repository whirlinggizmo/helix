import helix.adapters.fetch.fetchapi.FetchApiAdapter;
import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.storage.indexeddb.IndexedDbStorageAdapter;

class ServiceEnvironment {
	public var fetcher = new FetchApiAdapter();
	public var remoteStreams = true;
	public var base:String;
	public var storage:IndexedDbStorageAdapter;
	public var packaged:IndexedDbStorageAdapter;
	public var audio:WebAudioAdapter;

	public function new() {
		var params = new js.html.URLSearchParams(js.Browser.window.location.search);
		base = js.Browser.window.location.origin;
		storage = new IndexedDbStorageAdapter(params.get("db"));
		packaged = new IndexedDbStorageAdapter(params.get("db") + "-unused");
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
