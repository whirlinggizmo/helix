import helix.profiles.WebGL2Profile;

class Main {
	public static function main():Void
		WebGL2Profile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "../assets/",
			// The examples' assets carry manifests (tools/example.py), so a returning page re-fetches only what changed.
			"manifest.json", () -> new PageState(new DevKeys(new App())));
}
