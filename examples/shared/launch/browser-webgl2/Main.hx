import helix.profiles.BrowserWebGL2Profile;

class Main {
	public static function main():Void
		BrowserWebGL2Profile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "../assets/",
			// The examples' assets carry manifests (tools/example.py), so a returning page re-fetches only what changed.
			"manifest.json", services -> new PageState(services, new DevKeys(services, new App(services))));
}
