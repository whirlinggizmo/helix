import helix.profiles.NativeSdl3GLProfile;

class Main {
	public static function main():Void
		NativeSdl3GLProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"),
			services -> new DevKeys(services, new App(services)));
}
