package helix.adapters.http.fetchapi;

import haxe.io.Bytes;
import helix.assets.IHttp;

/** IHttp in a browser over fetch(): the body read as it arrives, abort through an AbortController. */
class FetchApiHttpAdapter implements IHttp {
	var controllers:Array<js.html.AbortController> = [];

	/** No transfers yet. */
	public function new() {}

	public function get(url:String, noCache:Bool, head:(Int, Map<String, String>) -> Void, body:Bytes->Void, end:Null<String>->Void):Void->Void {
		var controller = new js.html.AbortController(), stopped = false;
		controllers.push(controller);
		function finish(error:Null<String>):Void
			if (!stopped) {
				stopped = true;
				controllers.remove(controller);
				end(error);
			}
		js.Browser.window.fetch(url, {signal: controller.signal, cache: noCache ? js.html.RequestCache.NO_STORE : js.html.RequestCache.DEFAULT})
			.then(response -> {
				if (stopped)
					return null;
				var headers:Map<String, String> = [];
				response.headers.forEach((value, name, _) -> headers[name.toLowerCase()] = value);
				head(response.status, headers);
				var reader:Dynamic = (cast response : Dynamic).body == null ? null : (cast response : Dynamic).body.getReader();
				if (reader == null) {
					finish(null);
					return null;
				}
				var read:Void->Void = null;
				read = () -> reader.read().then(part -> {
					if (stopped)
						return null;
					if (part.done)
						finish(null);
					else {
						var chunk:js.lib.Uint8Array = cast part.value;
						body(Bytes.ofData(chunk.buffer.slice(chunk.byteOffset, chunk.byteOffset + chunk.byteLength)));
						read();
					}
					return null;
				}, error -> {
					finish(Std.string(error));
					return null;
				});
				read();
				return null;
			}, error -> {
				finish(Std.string(error));
				return null;
			});
		return () -> if (!stopped) {
			stopped = true;
			controllers.remove(controller);
			controller.abort();
		};
	}

	/** Nothing to deliver: the page's callbacks already run on the host thread. */
	public function poll():Void {}

	public function shutdown():Void {
		for (controller in controllers.copy())
			controller.abort();
		controllers = [];
	}
}
