package helix.collision;

/** An arcade body: a box moved by its velocity and gravity over a grid of solid tiles, sliding along what it meets (Collide2D.moveAndSlide),
	its velocity stopped against it, and what it touches kept: the ground under it, a wall either side, a ceiling. A platformer's player or
	enemy, a top-down character with no gravity. step runs it: in a Ticker's fixed step (helix.time), so it moves the same at any frame
	rate. Bodies don't push each other; Collide2D's overlaps meet them. */
class Body2D {
	var move = new Move2D();

	/** A width x height box with its top-left at x, y (world units), still, with no gravity. */
	public function new(x:Float, y:Float, width:Float, height:Float) {
		this.x = previousX = x;
		this.y = previousY = y;
		this.width = width;
		this.height = height;
	}

	/** Its left edge, in world units. */
	public var x:Float;

	/** Its top edge, in world units. */
	public var y:Float;

	/** Its left edge before its last step, in world units: drawn between the two (getDrawnX). */
	public var previousX(default, null):Float;

	/** Its top edge before its last step, in world units. */
	public var previousY(default, null):Float;

	/** Its left edge as drawn fraction of the way from before its last step to now (a Ticker's fraction): where a frame between ticks
		draws it, and where a camera following it looks. */
	public function getDrawnX(fraction:Float):Float
		return previousX + (x - previousX) * fraction;

	/** Its top edge as drawn fraction of the way from before its last step to now. */
	public function getDrawnY(fraction:Float):Float
		return previousY + (y - previousY) * fraction;

	/** Its width, in world units. */
	public var width:Float;

	/** Its height, in world units. */
	public var height:Float;

	/** Its center across, in world units. */
	public var centerX(get, never):Float;

	function get_centerX():Float
		return x + width / 2;

	/** Its center down, in world units. */
	public var centerY(get, never):Float;

	function get_centerY():Float
		return y + height / 2;

	/** Its bottom edge, where it stands, in world units. */
	public var bottom(get, never):Float;

	function get_bottom():Float
		return y + height;

	/** Its speed across, world units a second, + right. */
	public var velocityX = 0.;

	/** Its speed down, world units a second, + down. */
	public var velocityY = 0.;

	/** Its acceleration down, world units a second each second (0, the start: none, top-down). */
	public var gravity = 0.;

	/** The fastest it falls, world units a second, at least 0. */
	public var maxFallSpeed(default, set) = Math.POSITIVE_INFINITY;

	function set_maxFallSpeed(value:Float):Float
		return maxFallSpeed = value > 0 ? value : 0.;

	/** Whether it stood on a solid at its last step. */
	public var grounded(default, null) = false;

	/** Whether a solid stopped its left side at its last step. */
	public var blockedLeft(default, null) = false;

	/** Whether a solid stopped its right side at its last step. */
	public var blockedRight(default, null) = false;

	/** Whether a solid stopped its top at its last step: it hit its head. */
	public var blockedAbove(default, null) = false;

	/** Seconds since it was last grounded, 0 while it is: a jump a moment after walking off a ledge (coyote time) asks whether this is
		short. */
	public var airTime(default, null) = 0.;

	/** Puts its top-left at x, y at once (a respawn: drawn there, not moved there), still, touching nothing until its next step. */
	public function place(x:Float, y:Float):Void {
		this.x = previousX = x;
		this.y = previousY = y;
		velocityX = velocityY = 0;
		grounded = blockedLeft = blockedRight = blockedAbove = false;
		airTime = 0;
	}

	/** Runs it dt seconds over a grid of tiles of tileSize, each solid or not by solid(column, row): gravity speeds its fall (held to
		maxFallSpeed), it moves by its velocity, across then down, sliding along what it meets, and a side that meets a solid stops its
		velocity that way. A body standing still on the ground stays grounded: gravity presses it down each step. */
	public function step(dt:Float, tileSize:Float, solid:(Int, Int) -> Bool):Void {
		if (!(dt > 0))
			return;
		previousX = x;
		previousY = y;
		velocityY = Math.min(velocityY + gravity * dt, maxFallSpeed);
		Collide2D.moveAndSlide(x, y, width, height, velocityX * dt, velocityY * dt, tileSize, solid, move);
		x = move.x;
		y = move.y;
		blockedLeft = move.left;
		blockedRight = move.right;
		blockedAbove = move.top;
		grounded = move.bottom;
		if (move.left && velocityX < 0 || move.right && velocityX > 0)
			velocityX = 0;
		if (move.bottom && velocityY > 0 || move.top && velocityY < 0)
			velocityY = 0;
		airTime = grounded ? 0 : airTime + dt;
	}
}
