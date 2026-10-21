package helix.app;

import helix.host.WindowOptions;

/** What an App starts with, given to its constructor (`super(options)`, or `new Game(options)` from Main); the defaults when none is
	given. Read once, as the app starts: a change after is too late. */
class AppOptions {
	/** The defaults: product "Game" by "DefaultCompany", the assets beside the program, no manifest, a window of 4 samples a pixel, and
		the development extras on in a debug build (-debug) and off otherwise. */
	public function new() {}

	/** The program's own name: with company, its identity (helix.host.Identity), which names what HeliX keeps for it (its cache
		directory natively, its cache database in the browser, its screenshots' directory). One safe file name; cleaned as Identity cleans it. */
	public var product:String = "Game";

	/** The company, the other half of the identity. */
	public var company:String = "DefaultCompany";

	/** Where the assets are: in the browser the URL the asset paths are fetched under ("assets/", beside the page, by default), natively
		a directory relative to the program's ("assets", beside it, by default). Null for the platform's default. */
	public var assets:Null<String> = null;

	/** A manifest among the assets (tools/gen_manifest.py; "manifest.json" for the examples), read in the browser so a returning page
		re-fetches only what changed; null (the default) fetches each file as it's asked for. Natively a manifest comes from
		HELIX_ASSET_MANIFEST instead, with HELIX_ASSET_HOST. */
	public var manifest:Null<String> = null;

	/** The window as it opens: the multisampling samples a pixel. */
	public var window:WindowOptions = new WindowOptions();

	/** The development keys around every frame: F9 saves a screenshot of the frame (a download in a browser, a file in the user's
		pictures natively), logged where it went. On in a debug build (-debug), off otherwise, unless set. A game chooses its own keys for
		what it ships. */
	public var devKeys:Bool = #if debug true #else false #end;

	/** Whether the page is told the program's state, for the tools driving it: in a browser, window.helixBusy says after each frame
		whether the services are still loading (Host.busy), and false once the program has quit, so a tool captures the page once it has
		settled (tools/pages_shots.cjs); natively nothing. On in a debug build (-debug), off otherwise, unless set. */
	public var pageState:Bool = #if debug true #else false #end;
}
