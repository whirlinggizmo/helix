import helix.profiles.NativeSokolGLProfile;

class Main {
	public static function main():Void
		NativeSokolGLProfile.run(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"),
			services -> new DevKeys(services, new App(services)));
}
