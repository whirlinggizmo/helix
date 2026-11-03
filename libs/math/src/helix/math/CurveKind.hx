package helix.math;

/** Specifies how a `Curve` passes its points. */
enum CurveKind {
	/** Through each point, smoothly: a centripetal Catmull-Rom spline. */
	Through;

	/** Near its control points: cubic Bézier pieces. */
	Bezier;

	/** Straight from point to point. */
	Polyline;
}
