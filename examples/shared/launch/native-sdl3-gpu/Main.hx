import helix.profiles.NativeSdl3GpuProfile;

class Main {
	public static function main():Void
		NativeSdl3GpuProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"),
			services -> new DevKeys(services, new App(services)));
}
