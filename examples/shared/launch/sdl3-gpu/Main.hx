import helix.profiles.Sdl3GpuProfile;

class Main {
	public static function main():Void
		Sdl3GpuProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"), "../assets", () -> new DevKeys(new App()));
}
