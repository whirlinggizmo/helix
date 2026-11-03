package helix.raylib;

/** Represents raylib's `Transform`: a translation, a rotation and a scale, as a bone's pose holds them. */
@:structInit
class Transform {
	/** Gets or sets the translation. */
	public var translation:Vector3;

	/** Gets or sets the rotation, a quaternion. */
	public var rotation:Quaternion;

	/** Gets or sets the scale on each axis. */
	public var scale:Vector3;

	/** Creates a Transform, each part omitted zero, as raylib's struct starts.

		@param translation  The translation.
		@param rotation  The rotation, a quaternion.
		@param scale  The scale on each axis. */
	public function new(?translation:Vector3, ?rotation:Quaternion, ?scale:Vector3) {
		this.translation = translation == null ? new Vector3() : translation;
		this.rotation = rotation == null ? new Quaternion() : rotation;
		this.scale = scale == null ? new Vector3() : scale;
	}
}
