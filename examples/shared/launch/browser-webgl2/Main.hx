import helix.profiles.BrowserWebGL2Profile;

class Main {
	public static function main():Void
		BrowserWebGL2Profile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "assets/", services -> new App(services));
}
