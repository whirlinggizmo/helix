package helix.jolt;

/** Represents the outcome of `ShapeSettings.Create`: the shape, or why it couldn't be built. */
class ShapeResult {
	var shape:Null<Shape>;
	var error:String;

	@:allow(helix.jolt) function new(handle:Int, error:String) {
		shape = Shape.of(handle);
		this.error = error;
	}

	/** Returns whether the shape was built.

		@return  True when `Get` returns the shape. */
	public function IsValid():Bool {
		return shape != null;
	}

	/** Returns whether the shape couldn't be built.

		@return  True when `GetError` says why. */
	public function HasError():Bool {
		return shape == null;
	}

	/** Returns why the shape couldn't be built.

		@return  The reason, or an empty string when the shape was built. */
	public function GetError():String {
		return error;
	}

	/** Returns the shape.

		@return  The shape, or null when it couldn't be built. */
	public function Get():Null<Shape> {
		return shape;
	}
}
