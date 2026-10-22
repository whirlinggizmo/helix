package helix.host;

/** The app's design fitted to the window (Presentation): its units, what's visible of them, and a 2D camera to show them (None, logical
	pixels, until the app sets a mode). The runner refits it to the window before every frame. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from Presentation's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.host.Presentation))
class Screen {
	/** The presentation forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):Presentation;
}
