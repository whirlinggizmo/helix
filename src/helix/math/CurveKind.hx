package helix.math;

/** How a curve passes its points. */
enum CurveKind {
	/** Through each, smoothly (Catmull-Rom). */
	Through;

	/** By cubic Bézier control points. */
	Bezier;

	/** Straight between them. */
	Polyline;
}
