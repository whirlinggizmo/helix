package helix.raylib.extras;

/** Represents a particle's size at a point of its life. */
@:structInit class EmitterSizeKey {
	/** Gets or sets when, 0 at birth to 1 at death. */
	public var at:Float;

	/** Gets or sets the size then. */
	public var size:Float;
}
