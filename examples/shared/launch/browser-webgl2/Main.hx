import helix.profiles.BrowserWebGL2Profile;

class Main {
	public static function main():Void {
		var host = new BrowserWebGL2Profile(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "assets/");
		host.run(new App(host));
	}
}
