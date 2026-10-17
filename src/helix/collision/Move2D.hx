package helix.collision;

/** Where a move-and-slide ended (Collide2D.moveAndSlide): the box's new place, and which of its sides met a solid on the way, so a game knows
	it stands on the ground (bottom), hit a wall (left, right) or its head (top). One is kept and filled again. */
class Move2D {
	/** The box's left edge after the move. */
	public var x = 0.;

	/** The box's top edge after the move. */
	public var y = 0.;

	/** Whether its left side met a solid. */
	public var left = false;

	/** Whether its right side met a solid. */
	public var right = false;

	/** Whether its top met a solid. */
	public var top = false;

	/** Whether its bottom met a solid: it stands on something. */
	public var bottom = false;

	/** Nothing moved yet. */
	public function new() {}
}
