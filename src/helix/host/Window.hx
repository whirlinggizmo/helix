package helix.host;

/** The window the app draws in (the page, on the web): its drawing surface's size, pixel ratio and focus too, and what may be asked of it (a
	size, a position, fullscreen). The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from IWindow's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.host.IWindow))
class Window {
	/** The window forwarded to: the host's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):IWindow;
}
