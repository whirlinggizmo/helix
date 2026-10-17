package helix.render2d;

/** Textures from image files, shared by path and reloading in place when a file changes during development (TextureCache). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from TextureCache's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.render2d.TextureCache, ["reloaded", "shutdown"]))
class Textures {
	/** The textures forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):TextureCache;
}
