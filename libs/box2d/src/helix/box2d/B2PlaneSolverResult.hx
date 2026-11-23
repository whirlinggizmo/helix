package helix.box2d;

/** What `b2SolvePlanes` returns. */
class B2PlaneSolverResult {
	/** The final translation, relative to the position the collision planes were found at. */
	public var delta:B2Vec2;

	/** The number of iterations the plane solver used. Diagnostic. */
	public var iterationCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2PlaneSolverResult(this);
	}
}
