package helix.raylib;

/** Represents raylib's `Camera3D`, which is also its `Camera`: where it is, what it looks at, and its lens. */
@:structInit
class Camera3D {
	/** Gets or sets where it is. */
	public var position:Vector3;

	/** Gets or sets the point it looks at. */
	public var target:Vector3;

	/** Gets or sets its up direction. */
	public var up:Vector3;

	/** Gets or sets the field of view, top to bottom, in degrees; in orthographic, the height seen. */
	public var fovy:Float;

	/** Gets or sets `CAMERA_PERSPECTIVE` or `CAMERA_ORTHOGRAPHIC`. */
	public var projection:Int;

	/** Creates a Camera3D.

		@param position  Gets or sets where it is.
		@param target  Gets or sets the point it looks at.
		@param up  Gets or sets its up direction.
		@param fovy  Gets or sets the field of view, top to bottom, in degrees; in orthographic, the height seen.
		@param projection  Gets or sets `CAMERA_PERSPECTIVE` or `CAMERA_ORTHOGRAPHIC`. */
	public function new(?position:Vector3, ?target:Vector3, ?up:Vector3, fovy:Float = 45, projection:Int = 0) {
		this.position = position == null ? new Vector3() : position;
		this.target = target == null ? new Vector3() : target;
		this.up = up == null ? new Vector3() : up;
		this.fovy = fovy;
		this.projection = projection;
	}
}
