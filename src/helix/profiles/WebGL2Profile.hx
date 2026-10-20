package helix.profiles;

import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.export.download.DownloadExportAdapter;
import helix.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter;
import helix.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.adapters.graphics.webgl2.WebGL2GraphicsAdapter;
import helix.adapters.testharness.dom.DomTestHarnessAdapter;
import helix.adapters.host.dom.DomHostAdapter;
import helix.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter;
import helix.adapters.inputsource.dom.DomInputSourceAdapter;
import helix.adapters.store.indexeddb.IndexedDbStoreAdapter;
import helix.app.IApp;
import helix.host.Runner;

/** The browser on WebGL2 (the `webgl2` backend): the page's host and canvas, Web Audio, fetch, IndexedDB and the page's image decoder. */
class WebGL2Profile {
	/** Runs the app makeApp builds once its services are bound, on the page's canvas, for identity: assets fetched from assetBase and cached in IndexedDB
		as "<company>/<product>", following the manifest tree from assetManifest under it when given ("manifest.json"; tools/gen_manifest.py), the canvas made as options ask (the defaults when not given). The tick option keeps the drawing buffer between
		frames, for checks that read it. */
	public static function run(identity:helix.host.Identity, assetBase:String, assetManifest:Null<String>, makeApp:Void->IApp,
			?options:helix.host.WindowOptions):Void {
		if (options == null)
			options = new helix.host.WindowOptions();
		var host = new DomHostAdapter(),
			cacheName = identity.company + "/" + identity.product;
		var runner = new Runner(host, () -> {
			var graphics = new WebGL2GraphicsAdapter(host.canvas, host.getOption("tick") != null, options.msaaSamples);
			return {
				graphics: graphics,
				input: new DomInputSourceAdapter(host.canvas),
				audio: new WebAudioAdapter(),
				audioDecoder: new WebAudioDecoderAdapter(),
				images: new CanvasImageDecoderAdapter(),
				http: new FetchApiHttpAdapter(),
				storage: new IndexedDbStoreAdapter(cacheName),
				packaged: new IndexedDbStoreAdapter(cacheName + "-packaged"),
				base: assetBase,
				manifest: assetManifest,
				harness: new DomTestHarnessAdapter(),
				export: new DownloadExportAdapter(),
				name: identity.product
			};
		});
		#if hotreload new helix.adapters.host.dom.AssetWatcher(assetBase, path -> runner.assetChanged(path)); #end
		runner.run(makeApp);
	}
}
