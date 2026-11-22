package helix.jolt;

/** Specifies a shape's kind. */
enum abstract EShapeSubType(Int) {
	/** `SphereShape`. */
	var EShapeSubType_Sphere = 0;

	/** `BoxShape`. */
	var EShapeSubType_Box = 1;

	/** `CapsuleShape`. */
	var EShapeSubType_Capsule = 2;

	/** A shape made by `TaperedCapsuleShapeSettings`. */
	var EShapeSubType_TaperedCapsule = 3;

	/** `CylinderShape`. */
	var EShapeSubType_Cylinder = 4;

	/** A tapered cylinder, which this module doesn't make. */
	var EShapeSubType_TaperedCylinder = 5;

	/** A shape made by `ConvexHullShapeSettings`. */
	var EShapeSubType_ConvexHull = 6;

	/** A shape made by `StaticCompoundShapeSettings`. */
	var EShapeSubType_StaticCompound = 7;

	/** A mutable compound, which this module doesn't make. */
	var EShapeSubType_MutableCompound = 8;

	/** A shape made by `RotatedTranslatedShapeSettings`. */
	var EShapeSubType_RotatedTranslated = 9;

	/** `ScaledShape`. */
	var EShapeSubType_Scaled = 10;

	/** `OffsetCenterOfMassShape`. */
	var EShapeSubType_OffsetCenterOfMass = 11;

	/** A shape made by `MeshShapeSettings`. */
	var EShapeSubType_Mesh = 12;

	/** A shape made by `HeightFieldShapeSettings`. */
	var EShapeSubType_HeightField = 13;

	/** `PlaneShape`. */
	var EShapeSubType_Plane = 14;

	/** `EmptyShape`. */
	var EShapeSubType_Empty = 15;
}
