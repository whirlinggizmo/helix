import helix.platform.IEvents;
import helix.platform.IFileSystem;
import helix.platform.IGraphics;
import helix.platform.IHttp;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.ManifestCache;
import helix.services.assets.ServerSource;

/** Shows shipped files patched from a server: a server source with a `ManifestCache`, given the shipped files, listed before them, so a
	shipped file the server's manifests list at the same hash is read in place and only what changed is downloaded. The manifests are
	written as it builds (its hxml's `AssetManifests.write`). It loads two files, each time as a new run would: with nothing kept (the
	cache cleared first), with the same manifests, and natively after the server is updated, with each connection lost before an answer
	(the copies kept answer), and after the server's manifest drops b.txt: its copy is deleted as that manifest arrives, so with the
	connection lost again the shipped b.txt answers.

	Natively the server is `LocalServer`, which the program starts on this machine and uses as it would a CDN; in a page there are no
	shipped files, the server that serves the page serves `cdn/` too, and it can't be updated while the page runs.

	The screen is grey until that happens, then green. The window, its events and the loop are the platform's, written out by hand, as a
	program does them until the layer above the services does. The `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits it after that frame. */
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
	// The run's assets, polled each frame.
	static var assets:Null<Assets> = null;
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
		var frames = system.getOption("quit_after_frame");
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
		// The example keeps its files beside its page, a directory up from the program.
		var example = haxe.io.Path.join([system.getProgramDirectory(), ".."]);
		cdn = new LocalServer(haxe.io.Path.join([example, "web/cdn"]));
		httpClient = new helix.platform.adapters.http.haxehttp.HaxeHttpAdapter();
		downloads = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: system.getCacheDirectory()});
		shipped = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: haxe.io.Path.join([example, "shipped"]), readOnly: true});
		polled.push(shipped);
		#end
		polled.push(httpClient);
		polled.push(downloads);
		var first = assets = makeAssets();
		first.clearCache(() -> {
			first.dispose();
			var both = ["a.txt", "b.txt"];
			load("nothing kept", both, () -> load("same manifests", both, () -> {
				#if js
				color = DONE;
				#else
				cdn.directory = haxe.io.Path.join([system.getProgramDirectory(), "../web/cdn-updated"]);
				load("server updated", both, () -> {
					cdn.losing = true;
					load("connection lost", both, () -> {
						cdn.losing = false;
						cdn.directory = haxe.io.Path.join([system.getProgramDirectory(), "../web/cdn-dropped"]);
						// a.txt alone, so b.txt's copy goes only because the new manifest dropped it: with no connection, the shipped one answers.
						load("a name dropped", ["a.txt"], () -> {
							cdn.losing = true;
							load("dropped, connection lost", ["b.txt"], () -> color = DONE);
						});
					});
				});
				#end
			}));
		});
	}

	/** Makes the assets as a run would: the server first, its copies checked by its manifests, and natively the shipped files after it,
		which the cache is given too, so a shipped file the manifests list at the same hash is read in place. */
	static function makeAssets():Assets {
		#if js
		return new Assets([
			new ServerSource(system.getProgramDirectory() + "cdn/", httpClient, new ManifestCache(downloads))
		]);
		#else
		return new Assets([
			new ServerSource(cdn.url, httpClient, new ManifestCache(downloads, {shipped: [shipped]})),
			new FileSystemSource(shipped)
		]);
		#end
	}

	/** Loads files with new assets, one after another, says what each held and what was downloaded, then goes on. */
	static function load(run:String, names:Array<String>, next:Void->Void):Void {
		var assets = Main.assets = makeAssets();
		#if !js
		var before = cdn.served.length;
		#end
		var held = [];
		function from(i:Int)
			if (i < names.length)
				assets.load(names[i], bytes -> {
					held.push('${names[i]} "${bytes.toString()}"');
					from(i + 1);
				});
			else {
				#if js
				trace('$run: ${held.join(", ")}');
				#else
				var downloaded = cdn.served.slice(before).filter(path -> path.indexOf("manifest") < 0);
				trace('$run: ${held.join(", ")}, downloaded: ${downloaded.length == 0 ? "nothing" : downloaded.join(", ")}');
				#end
				assets.dispose();
				next();
			}
		from(0);
	}

	/** Runs one frame: polls what answers later, then clears the screen to its color; false once the program should stop. */
	static function tick():Bool {
		for (pollable in polled)
			pollable.poll();
		if (assets != null)
			assets.poll();
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
