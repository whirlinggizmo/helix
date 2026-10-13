import helix.profiles.NativeSokolGLProfile;

class Main {
	public static function main():Void {
		var host = new NativeSokolGLProfile(new helix.host.Identity(haxe.macro.Compiler.getDefine("example"), "HeliX"));
		host.run(new App(host));
	}
}
