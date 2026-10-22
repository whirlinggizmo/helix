package helix.render2d;

/** Textures from image files, shared by path and reloading in place when a file changes during development (TextureCache2D). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from TextureCache2D's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.render2d.TextureCache2D, ["reloaded", "shutdown"]))
class Textures2D {
	/** The textures forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):TextureCache2D;
}
