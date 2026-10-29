package helix.platform.adapters.http.fetchapi;

import haxe.io.Bytes;
import helix.platform.IHttp;

/** Provides `IHttp` in a page over `fetch`: the body read as it arrives, aborted through an `AbortController`.

	Conditional headers (`If-None-Match`, `If-Modified-Since`) to another origin would need a CORS preflight the server may refuse, so there
	they are left out and the browser revalidates its own copy instead (cache `no-cache`), answering 200. */
class FetchApiHttpAdapter implements IHttp {
	var controllers:Array<js.html.AbortController> = [];

	/** Creates the adapter. */
	public function new() {}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
			done:Void->Void, failed:String->Void):Void->Void {
		var controller = new js.html.AbortController(),
			stopped = false,
			sent = new js.html.Headers(),
			cache = noCache ? js.html.RequestCache.NO_STORE : js.html.RequestCache.DEFAULT,
			foreign = new js.html.URL(url, js.Browser.location.href).origin != js.Browser.location.origin;
		for (name => value in headers) {
			var lower = name.toLowerCase();
			if (foreign && (lower == "if-none-match" || lower == "if-modified-since")) {
				if (!noCache)
					cache = js.html.RequestCache.NO_CACHE;
			} else
				sent.set(name, value);
		}
		controllers.push(controller);
		function stop():Bool {
			if (stopped)
				return false;
			stopped = true;
			controllers.remove(controller);
			return true;
		}
		function fail(error:Dynamic):Dynamic {
			if (stop())
				failed(Std.string(error));
			return null;
		}
		js.Browser.window.fetch(url, {signal: controller.signal, cache: cache, headers: sent}).then(response -> {
			if (stopped)
				return null;
			var received:Map<String, String> = [];
			response.headers.forEach((value, name, _) -> received[name.toLowerCase()] = value);
			head(response.status, received);
			var reader:Dynamic = (cast response : Dynamic).body == null ? null : (cast response : Dynamic).body.getReader();
			if (reader == null) {
				if (stop())
					done();
				return null;
			}
			var read:Void->Void = null;
			read = () -> reader.read().then(part -> {
				if (stopped)
					return null;
				if (part.done) {
					if (stop())
						done();
				} else {
					var chunk:js.lib.Uint8Array = cast part.value;
					body(Bytes.ofData(chunk.buffer.slice(chunk.byteOffset, chunk.byteOffset + chunk.byteLength)));
					read();
				}
				return null;
			}, fail);
			read();
			return null;
		}, fail);
		return () -> if (stop()) controller.abort();
	}

	/** Does nothing: the page's callbacks already run on the main thread. */
	public function poll():Void {}

	public function dispose():Void {
		for (controller in controllers.copy())
			controller.abort();
		controllers = [];
	}
}
