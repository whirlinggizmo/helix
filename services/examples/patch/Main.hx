import helix.platform.IEvents;
import helix.platform.IFileSystem;
import helix.platform.IGraphics;
import helix.platform.IHttp;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.services.assets.Assets;

/** Shows shipped files patched from a server: a `Manifest` source listed before the files the program ships, so a shipped file the server's
	manifests list at the same hash is read in place and only what changed is downloaded. The manifests are written as it builds (its
	hxml's `AssetManifests.write`). It loads two files three times, each time as a new run would: with nothing kept (the cache cleared
	first), with the same manifests, and natively once more after the server is updated.

	Natively the server is `LocalServer`, which the program starts on this machine and uses as it would a CDN; in a page there are no
	shipped files, the server that serves the page serves `cdn/` too, and it can't be updated while the page runs.

	The screen is grey until that happens, then green. The window, its events and the loop are the platform's, written out by hand, as a
	program does them until the layer above the services does. The `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page)
	stops it after that many frames. */
class Main {
	static inline final WAITING = 0xff1a1d26;
	static inline final DONE = 0xff2a9d4a;

	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static final polled:Array<IPollable> = [];
	static var color = WAITING;
	static var framesLeft = -1;
	static var httpClient:IHttp;
	static var downloads:IFileSystem;
	#if !js
	static var shipped:IFileSystem;
	static var cdn:LocalServer;
	#end

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		#end
		window.title = "helix-services: patch";
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		polled.push(events);
		setup();
		#if js
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else dispose();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		while (tick()) {}
		dispose();
		#end
	}

	/** Makes the platform's HTTP client and file systems, and loads the files a run at a time. */
	static function setup():Void {
		#if js
		httpClient = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		downloads = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		#else
		cdn = new LocalServer("web/cdn");
		httpClient = new helix.platform.adapters.http.haxehttp.HaxeHttpAdapter();
		downloads = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: system.getCacheDirectory()});
		shipped = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: "shipped", readOnly: true});
		polled.push(shipped);
		#end
		polled.push(httpClient);
		polled.push(downloads);
		var first = makeAssets();
		first.clearCache(() -> {
			first.dispose();
			load("nothing kept", () -> load("same manifests", () -> {
				#if js
				color = DONE;
				#else
				cdn.directory = "web/cdn-updated";
				load("server updated", () -> color = DONE);
				#end
			}));
		});
	}

	/** Makes the assets as a run would: the server first, in Manifest mode, and natively the shipped files after it. */
	static function makeAssets():Assets {
		#if js
		return new Assets({sources: [HttpServer("cdn/", Manifest)], httpClient: httpClient, cacheFileSystem: downloads});
		#else
		return new Assets({sources: [HttpServer(cdn.url, Manifest), FileSystem(shipped)], httpClient: httpClient, cacheFileSystem: downloads});
		#end
	}

	/** Loads a.txt and b.txt with new assets, says what each held and what was downloaded, then goes on. */
	static function load(run:String, next:Void->Void):Void {
		var assets = makeAssets();
		#if !js
		var before = cdn.served.length;
		#end
		assets.load("a.txt", a -> assets.load("b.txt", b -> {
			#if js
			trace('$run: a.txt "${a.toString()}", b.txt "${b.toString()}"');
			#else
			var downloaded = cdn.served.slice(before).filter(path -> path.indexOf("manifest") < 0);
			trace('$run: a.txt "${a.toString()}", b.txt "${b.toString()}", downloaded: ${downloaded.length == 0 ? "nothing" : downloaded.join(", ")}');
			#end
			assets.dispose();
			next();
		}));
	}

	/** Runs one frame: polls what answers later, then clears the screen to its color; false once the program should stop. */
	static function tick():Bool {
		for (pollable in polled)
			pollable.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, color);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		downloads.dispose();
		httpClient.dispose();
		#if !js
		shipped.dispose();
		cdn.close();
		#end
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
