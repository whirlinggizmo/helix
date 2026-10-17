package helix.render3d;

/** Environment maps from equirectangular images, prepared a little each frame (EnvironmentCache). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from EnvironmentCache's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.render3d.EnvironmentCache, ["poll", "reloaded", "shutdown"]))
class Environments {
	/** The environments forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):EnvironmentCache;
}
