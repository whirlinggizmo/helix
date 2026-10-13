import helix.profiles.BrowserWebGL2Profile;

/** Target composition only; game/workload code receives the same IHost contract. */
class Main {
	public static function main():Void
		App.start(new BrowserWebGL2Profile("hybrid-asteroids-cache-v1", "assets/", true, true));
}
