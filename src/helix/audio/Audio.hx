package helix.audio;

/** Sounds: clips and streams loaded through the assets, decoded and played (AudioResources). The audio output under it (IAudio) is the
	adapter's. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from AudioResources' public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.audio.AudioResources, ["poll", "reloaded", "shutdown"]))
class Audio {
	/** The sounds forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):AudioResources;
}
