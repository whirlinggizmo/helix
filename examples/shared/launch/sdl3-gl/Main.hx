import helix.profiles.Sdl3GLProfile;

class Main {
	public static function main():Void
		Sdl3GLProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "../assets", () -> new DevKeys(new App()));
}
