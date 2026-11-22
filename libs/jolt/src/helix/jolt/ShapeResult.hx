package helix.jolt;

/** Represents the outcome of `ShapeSettings.Create`: the shape, or why it couldn't be built. */
class ShapeResult {
	function new() {}

	/** Returns whether the shape was built.

		@return  True when `Get` returns the shape. */
	public function IsValid():Bool {
		throw "not built yet";
	}

	/** Returns whether the shape couldn't be built.

		@return  True when `GetError` says why. */
	public function HasError():Bool {
		throw "not built yet";
	}

	/** Returns why the shape couldn't be built.

		@return  The reason, or an empty string when the shape was built. */
	public function GetError():String {
		throw "not built yet";
	}

	/** Returns the shape.

		@return  The shape, or null when it couldn't be built. */
	public function Get():Null<Shape> {
		throw "not built yet";
	}
}
