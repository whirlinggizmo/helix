import helix.profiles.NativeSokolGLProfile;

/** Target composition only; game/workload code receives the same IHost contract. */
class Main {
	public static function main():Void
		App.start(new NativeSokolGLProfile());
}
