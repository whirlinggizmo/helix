import helix.profiles.SokolGLProfile;

class Main {
	public static function main():Void
		SokolGLProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "../assets", () -> new DevKeys(new App()));
}
