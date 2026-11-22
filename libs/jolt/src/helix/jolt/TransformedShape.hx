package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a body's shape where the body is, returned by `BodyInterface.GetTransformedShape`, for asking about a query's hit. Read
	as the body was when returned. */
class TransformedShape {
	/** Gets the body. */
	public var mBodyID(default, null):BodyID;

	/** Gets the shape. */
	public var mShape(default, null):Shape;

	/** Creates an empty transformed shape, to fill with `BodyInterface.GetTransformedShape`. */
	public function new() {
		mBodyID = new BodyID();
		centerOfMass = new Vec3();
		rotation = Quat.sIdentity();
		scale = new Vec3(1, 1, 1);
	}

	/** Returns the transform of the shape.

		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(?out:RMat44):RMat44 {
		write();
		Hj.shapeGetTransformedWorld(mShape.handle);
		return Io.mat44(0, out);
	}

	/** Returns the shape's bounds in the world.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetWorldSpaceBounds(?out:AABox):AABox {
		write();
		Hj.shapeGetTransformedWorld(mShape.handle);
		return Io.box(16, out);
	}

	/** Returns the normal of the shape's surface at a point a query hit.

		@param inSubShapeID  The part of the shape hit, from the query's result.
		@param inPosition  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The normal, of length 1. */
	public function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3 {
		write();
		Io.setF(10, inPosition.x);
		Io.setF(11, inPosition.y);
		Io.setF(12, inPosition.z);
		Hj.shapeGetWorldSurfaceNormal(mShape.handle, inSubShapeID.GetValue());
		return Io.vec3(0, out);
	}

	var centerOfMass:Vec3;
	var rotation:Quat;
	var scale:Vec3;

	/** Reads the body's shape and where it is from the shared areas, as hj_body_get_transformed_shape writes them. */
	@:allow(helix.jolt) function read(inBodyID:BodyID, inShape:Shape):Void {
		mBodyID = inBodyID;
		mShape = inShape;
		Io.vec3(0, centerOfMass);
		Io.quat(3, rotation);
		Io.vec3(7, scale);
	}

	function write():Void {
		Io.setF(0, centerOfMass.x);
		Io.setF(1, centerOfMass.y);
		Io.setF(2, centerOfMass.z);
		Io.setF(3, rotation.x);
		Io.setF(4, rotation.y);
		Io.setF(5, rotation.z);
		Io.setF(6, rotation.w);
		Io.setF(7, scale.x);
		Io.setF(8, scale.y);
		Io.setF(9, scale.z);
	}
}
