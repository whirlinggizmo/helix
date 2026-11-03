package helix.ray;

/** Represents raylib's `Camera2D`: what it looks at, where that shows on the screen, its rotation and its zoom. */
@:structInit
class Camera2D {
	/** Gets or sets where the target shows, in the screen's pixels. */
	public var offset:Vector2;

	/** Gets or sets the point in the world it looks at. */
	public var target:Vector2;

	/** Gets or sets its rotation, in degrees. */
	public var rotation:Float;

	/** Gets or sets its zoom, 1 for none. */
	public var zoom:Float;

	/** Creates a 2D camera.

		@param offset  Where the target shows.
		@param target  The point it looks at.
		@param rotation  Its rotation, in degrees.
		@param zoom  Its zoom. */
	public function new(?offset:Vector2, ?target:Vector2, rotation:Float = 0, zoom:Float = 1) {
		this.offset = offset == null ? new Vector2() : offset;
		this.target = target == null ? new Vector2() : target;
		this.rotation = rotation;
		this.zoom = zoom;
	}
}
