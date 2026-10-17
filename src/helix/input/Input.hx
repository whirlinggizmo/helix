package helix.input;

/** Keyboard, mouse, touch and gamepads, as this frame and tick see them. The program's one, a static class: each
	member forwards to instance, written by helix.macro.Facade from IInput's public members with their doc comments. */
@:build(helix.macro.Facade.build(helix.input.IInput))
class Input {
	/** The input forwarded to: the runner's router's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot public static var instance(default, null):IInput;
}
