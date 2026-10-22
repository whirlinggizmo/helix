package helix.adapter.host.dom;

#if hotreload
/** Development only (hotreload-hx): the dev server says which served files changed; those under the asset base are passed to changed, by
	their asset path, to load again in place. */
class AssetWatcher {
	var reloader:hotreload.Reloader;

	/** Watches for the files under base (a URL, relative to the page) changing. */
	public function new(base:String, changed:String->Void) {
		var prefix = new js.html.URL(base, js.Browser.location.href).pathname;
		reloader = new hotreload.Reloader();
		reloader.assetsChanged = urls -> for (url in urls)
			if (StringTools.startsWith(url, prefix))
				changed(url.substr(prefix.length));
	}
}
#end
