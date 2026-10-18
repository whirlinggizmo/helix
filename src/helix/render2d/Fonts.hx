package helix.render2d;

/** TrueType fonts from files, baked into distance fields and baked again when a file changes during development (FontCache). The program's
	one, a static class: each member forwards to instance, written by helix.macro.Facade from FontCache's public members with their doc
	comments. */
@:build(helix.macro.Facade.build(helix.render2d.FontCache, ["reloaded", "shutdown"]))
class Fonts {
	/** The fonts forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):FontCache;
}
