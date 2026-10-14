package helix.profiles;

import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.audio.webaudio.WebAudioDecoder;
import helix.adapters.fetch.fetchapi.FetchApiAdapter;
import helix.adapters.graphics.webgl2.WebGL2GraphicsAdapter;
import helix.adapters.harness.dom.DomTestHarness;
import helix.adapters.host.dom.DomHostAdapter;
import helix.adapters.images.canvas.CanvasImagesAdapter;
import helix.adapters.input.dom.DomInputAdapter;
import helix.adapters.storage.indexeddb.IndexedDbStorageAdapter;
import helix.app.IApp;
import helix.host.Runner;
import helix.host.Services;

/** The browser on WebGL2: the page's host and canvas, Web Audio, fetch, IndexedDB and the page's image decoder. */
class BrowserWebGL2Profile {
	/** Runs the app makeApp builds over its services, on the page's canvas, for identity: assets fetched from assetBase and cached in IndexedDB
		as "<company>/<product>". The tick option keeps the drawing buffer between frames, for checks that read it. */
	public static function run(identity:helix.host.Identity, assetBase:String, makeApp:Services->IApp):Void {
		var host = new DomHostAdapter(),
			cacheName = identity.getCompany() + "/" + identity.getProduct();
		var runner = new Runner(host, () -> {
			var graphics = new WebGL2GraphicsAdapter(host.getCanvas(), host.getOption("tick") != null), audio = new WebAudioAdapter();
			return {
				graphics: graphics,
				input: new DomInputAdapter(host.getCanvas()),
				audio: new WebAudioAdapter(),
				audioDecoder: new WebAudioDecoder(),
				images: new CanvasImagesAdapter(),
				http: new FetchApiAdapter(),
				storage: new IndexedDbStorageAdapter(cacheName),
				packaged: new IndexedDbStorageAdapter(cacheName + "-packaged"),
				base: assetBase,
				harness: new DomTestHarness()
			};
		});
		#if hotreload new helix.adapters.host.dom.AssetWatcher(assetBase, runner.assetChanged); #end
		runner.run(makeApp(runner.services));
	}
}
