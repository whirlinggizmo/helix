import helix.profiles.NativeSokolGLProfile;

class Main {
	public static function main():Void {
		var host = new NativeSokolGLProfile();
		host.run(new App(host));
	}
}
