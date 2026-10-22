package helix.render2d;

/** TrueType fonts from files, baked into distance fields and baked again when a file changes during development (FontCache2D). The program's
	one, a static class: each member forwards to instance, written by helix.macro.Facade from FontCache2D's public members with their doc
	comments. */
@:build(helix.macro.Facade.build(helix.render2d.FontCache2D, ["reloaded", "shutdown"]))
class Fonts2D {
	/** The fonts forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):FontCache2D;
}
