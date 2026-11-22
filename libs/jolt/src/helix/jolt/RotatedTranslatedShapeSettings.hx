package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents what a moved and turned shape is built from: another shape, away from its body's origin. */
class RotatedTranslatedShapeSettings extends ShapeSettings {
	/** Gets or sets where the shape is, from the body's origin, in meters. */
	public var mPosition:Vec3;

	/** Gets or sets how the shape is turned. */
	public var mRotation:Quat;

	/** Creates the settings.

		@param inPosition  Where the shape is, from the body's origin, in meters.
		@param inRotation  How the shape is turned.
		@param inShape  The shape. */
	public function new(inPosition:Vec3, inRotation:Quat, inShape:Shape) {
		super();
		mPosition = inPosition;
		mRotation = inRotation;
		shape = inShape;
	}

	var shape:Shape;

	override function make():Int {
		return Hj.shapeRotatedTranslated(shape.handle, mPosition.x, mPosition.y, mPosition.z, mRotation.x, mRotation.y, mRotation.z, mRotation.w, mUserData);
	}
}
