package helix.raylib.extras;

import helix.raylib.*;

/** Represents a particle's color at a point of its life. */
@:structInit class EmitterColorKey {
	/** Gets or sets when, 0 at birth to 1 at death. */
	public var at:Float;

	/** Gets or sets the color then. */
	public var color:Color;
}
