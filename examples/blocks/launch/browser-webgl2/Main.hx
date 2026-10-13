import helix.profiles.BrowserWebGL2Profile;

class Main {
	public static function main():Void
		App.start(new BrowserWebGL2Profile(new helix.host.Identity("blocks", "HeliX"), "assets/"));
}
