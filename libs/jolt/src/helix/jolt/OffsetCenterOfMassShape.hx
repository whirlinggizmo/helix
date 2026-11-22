package helix.jolt;

/** Represents another shape with its center of mass moved: a car's, low, so it doesn't roll. */
class OffsetCenterOfMassShape extends Shape {
	/** Creates the shape, holding the shape it changes.

		@param inShape  The shape.
		@param inOffset  How far the center of mass moves, in meters. */
	public function new(inShape:Shape, inOffset:Vec3) {
		super();
		throw "not built yet";
	}
}
