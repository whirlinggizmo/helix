import helix.profiles.BrowserWebGL2Profile;

class Main {
	public static function main():Void {
		var host = new BrowserWebGL2Profile("helix-" + haxe.macro.Compiler.getDefine("example") + "-cache-v1", "assets/");
		host.run(new App(host));
	}
}
