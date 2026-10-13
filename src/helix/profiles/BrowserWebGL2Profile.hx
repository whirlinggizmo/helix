package helix.profiles;

import helix.adapters.host.dom.DomHostAdapter;
import helix.adapters.graphics.webgl2.WebGL2GraphicsAdapter;
import helix.adapters.input.dom.DomInputAdapter;
import helix.adapters.audio.webaudio.WebAudioAdapter;
import helix.adapters.fetch.fetchapi.FetchApiAdapter;
import helix.adapters.storage.indexeddb.IndexedDbStorageAdapter;

/** This sample profile chooses providers. Reusable host code owns their lifecycle. */
class BrowserWebGL2Profile extends DomHostAdapter {
	/** A browser host on the page's canvas: assets fetched from assetBase and cached in IndexedDB under cacheName; cacheGraphics and shareShader pick WebGL2 variants. */
	public function new(cacheName:String = "helix-cache-v1", assetBase:String = "assets/", cacheGraphics:Bool = false, shareShader:Bool = false) {
		super((canvas, preserve) -> {
			var graphics = new WebGL2GraphicsAdapter(canvas, preserve, cacheGraphics, shareShader),
				input = new DomInputAdapter(canvas),
				audio = new WebAudioAdapter();
			return {
				graphics: graphics,
				input: input,
				audio: audio,
				fetch: new FetchApiAdapter(),
				storage: new IndexedDbStorageAdapter(cacheName),
				packaged: new IndexedDbStorageAdapter(cacheName + "-packaged"),
				base: assetBase,
				pollInput: input.poll,
				endInputFrame: input.endFrame,
				focusInput: active -> {
					input.setActive(active);
					if (!active)
						input.clear();
				},
				unlockAudio: audio.unlock,
				suspendAudio: audio.suspend,
				shutdownInput: () -> {},
				info: () -> {
					var gl = graphics.getContext(),
						ext = gl.getExtension("WEBGL_debug_renderer_info"),
						value = audio.info();
					value.backend = "raw-webgl2";
					value.cacheGraphics = cacheGraphics;
					value.shareShader = shareShader;
					value.renderer = gl.getParameter(ext == null ? js.html.webgl.WebGL2RenderingContext.RENDERER : untyped ext.UNMASKED_RENDERER_WEBGL);
					return value;
				}
			};
		});
	}
}
