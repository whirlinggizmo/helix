package helix.services.input;

/** Defines a device `Actions` reads its bindings from: `Keyboard`, `Mouse`, `Gamepads` and `Tilt` each read their own kind of binding.

	A game passes its devices to `Actions` and never calls these itself. */
interface IActionDevice {
	/** Returns whether a binding is one of this device's kind. */
	@:noCompletion
	function reads(binding:Binding):Bool;

	/** Returns how far a binding is worked now, 0 to 1: a key or button held is 1, a stick or tilt its distance past its dead zone. */
	@:noCompletion
	function getValue(binding:Binding):Float;

	/** Returns whether a binding was held before this frame. */
	@:noCompletion
	function wasDown(binding:Binding):Bool;

	/** Returns whether a binding went down this frame. */
	@:noCompletion
	function isPressed(binding:Binding):Bool;

	/** Returns whether a binding went up this frame. */
	@:noCompletion
	function isReleased(binding:Binding):Bool;
}
