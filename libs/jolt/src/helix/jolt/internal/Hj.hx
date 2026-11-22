package helix.jolt.internal;

/** Provides helix-jolt's C ABI (hj.h): natively compiled with the program by hxcpp, in a page the calls of the loaded jolt.wasm, which
	`Jolt.loadAsync` puts in the global `helixJolt`. The shared areas' addresses are `Io`'s. */
#if cpp
@:include("hj.h")
@:buildXml("<set name='HELIX_JOLT' value='${haxelib:helix-jolt}' unless='HELIX_JOLT'/>
<include name='${HELIX_JOLT}/vendor/jolt/files.xml'/>
<files id='haxe'><compilerflag value='-I${HELIX_JOLT}/src/helix/jolt/internal'/></files>
<target id='haxe'><files id='helix-jolt'/></target>")
#else
@:native("helixJolt")
#end
@:noCompletion
extern class Hj {
	@:native("hj_init") static function init():Void;
	@:native("hj_world_create") static function worldCreate(maxBodies:Int, maxBodyPairs:Int, maxContacts:Int, numObjectLayers:Int, numBroadPhaseLayers:Int):Int;
	@:native("hj_world_destroy") static function worldDestroy(world:Int):Void;
	@:native("hj_world_step") static function worldStep(world:Int, deltaTime:Float, collisionSteps:Int):Void;
	@:native("hj_world_set_gravity") static function worldSetGravity(world:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_world_get_gravity") static function worldGetGravity(world:Int):Void;
	@:native("hj_world_get_settings") static function worldGetSettings(world:Int):Void;
	@:native("hj_world_set_settings") static function worldSetSettings(world:Int):Void;
	@:native("hj_world_num_bodies") static function worldNumBodies(world:Int):Int;
	@:native("hj_world_num_active_bodies") static function worldNumActiveBodies(world:Int):Int;
	@:native("hj_world_max_bodies") static function worldMaxBodies(world:Int):Int;
	@:native("hj_world_get_bodies") static function worldGetBodies(world:Int, active:Int):Int;
	@:native("hj_world_get_bounds") static function worldGetBounds(world:Int):Void;
	@:native("hj_world_optimize_broad_phase") static function worldOptimizeBroadPhase(world:Int):Void;
	@:native("hj_world_were_in_contact") static function worldWereInContact(world:Int, body1:Int, body2:Int):Int;
	@:native("hj_shape_box") static function shapeBox(halfX:Float, halfY:Float, halfZ:Float, convexRadius:Float):Int;
	@:native("hj_shape_sphere") static function shapeSphere(radius:Float):Int;
	@:native("hj_shape_capsule") static function shapeCapsule(halfHeight:Float, radius:Float):Int;
	@:native("hj_shape_cylinder") static function shapeCylinder(halfHeight:Float, radius:Float, convexRadius:Float):Int;
	@:native("hj_shape_scaled") static function shapeScaled(shape:Int, x:Float, y:Float, z:Float):Int;
	@:native("hj_shape_offset_center_of_mass") static function shapeOffsetCenterOfMass(shape:Int, x:Float, y:Float, z:Float):Int;
	@:native("hj_shape_plane") static function shapePlane(normalX:Float, normalY:Float, normalZ:Float, constant:Float, halfExtent:Float):Int;
	@:native("hj_shape_empty") static function shapeEmpty(x:Float, y:Float, z:Float):Int;
	@:native("hj_shape_tapered_capsule") static function shapeTaperedCapsule(halfHeight:Float, topRadius:Float, bottomRadius:Float, density:Float,
		userData:Int):Int;
	@:native("hj_shape_convex_hull") static function shapeConvexHull(numPoints:Int, maxConvexRadius:Float, hullTolerance:Float, density:Float,
		userData:Int):Int;
	@:native("hj_shape_mesh") static function shapeMesh(numVertices:Int, numTriangles:Int, maxTrianglesPerLeaf:Int, userData:Int):Int;
	@:native("hj_shape_height_field") static function shapeHeightField(sampleCount:Int, blockSize:Int, bitsPerSample:Int, userData:Int):Int;
	@:native("hj_shape_static_compound") static function shapeStaticCompound(numParts:Int, userData:Int):Int;
	@:native("hj_shape_rotated_translated") static function shapeRotatedTranslated(shape:Int, x:Float, y:Float, z:Float, qx:Float, qy:Float, qz:Float,
		qw:Float, userData:Int):Int;
	@:native("hj_shape_error") static function shapeError():Int;
	@:native("hj_shape_get_ref_count") static function shapeGetRefCount(shape:Int):Int;
	@:native("hj_shape_add_ref") static function shapeAddRef(shape:Int):Void;
	@:native("hj_shape_release") static function shapeRelease(shape:Int):Void;
	@:native("hj_shape_get_type") static function shapeGetType(shape:Int):Int;
	@:native("hj_shape_get_sub_type") static function shapeGetSubType(shape:Int):Int;
	@:native("hj_shape_must_be_static") static function shapeMustBeStatic(shape:Int):Int;
	@:native("hj_shape_get_local_bounds") static function shapeGetLocalBounds(shape:Int):Void;
	@:native("hj_shape_get_center_of_mass") static function shapeGetCenterOfMass(shape:Int):Void;
	@:native("hj_shape_get_volume") static function shapeGetVolume(shape:Int):Float;
	@:native("hj_shape_get_mass_properties") static function shapeGetMassProperties(shape:Int):Void;
	@:native("hj_shape_get_user_data") static function shapeGetUserData(shape:Int):Int;
	@:native("hj_shape_set_user_data") static function shapeSetUserData(shape:Int, userData:Int):Void;
	@:native("hj_shape_get_density") static function shapeGetDensity(shape:Int):Float;
	@:native("hj_shape_set_density") static function shapeSetDensity(shape:Int, density:Float):Void;
	@:native("hj_shape_get_dimensions") static function shapeGetDimensions(shape:Int):Void;
	@:native("hj_shape_get_world_surface_normal") static function shapeGetWorldSurfaceNormal(shape:Int, subShapeId:Int):Void;
	@:native("hj_body_create") static function bodyCreate(world:Int, shape:Int, add:Int, activation:Int):Int;
	@:native("hj_body_destroy") static function bodyDestroy(world:Int, body:Int):Void;
	@:native("hj_body_add") static function bodyAdd(world:Int, body:Int, activation:Int):Void;
	@:native("hj_body_remove") static function bodyRemove(world:Int, body:Int):Void;
	@:native("hj_body_is_added") static function bodyIsAdded(world:Int, body:Int):Int;
	@:native("hj_body_get_shape") static function bodyGetShape(world:Int, body:Int):Int;
	@:native("hj_body_set_shape") static function bodySetShape(world:Int, body:Int, shape:Int, updateMass:Int, activation:Int):Void;
	@:native("hj_body_set_object_layer") static function bodySetObjectLayer(world:Int, body:Int, layer:Int):Void;
	@:native("hj_body_get_object_layer") static function bodyGetObjectLayer(world:Int, body:Int):Int;
	@:native("hj_body_set_position_and_rotation") static function bodySetPositionAndRotation(world:Int, body:Int, x:Float, y:Float, z:Float, qx:Float,
		qy:Float, qz:Float, qw:Float, activation:Int):Void;
	@:native("hj_body_set_position") static function bodySetPosition(world:Int, body:Int, x:Float, y:Float, z:Float, activation:Int):Void;
	@:native("hj_body_set_rotation") static function bodySetRotation(world:Int, body:Int, qx:Float, qy:Float, qz:Float, qw:Float, activation:Int):Void;
	@:native("hj_body_get_position_and_rotation") static function bodyGetPositionAndRotation(world:Int, body:Int):Void;
	@:native("hj_body_get_world_transform") static function bodyGetWorldTransform(world:Int, body:Int):Void;
	@:native("hj_body_get_center_of_mass_transform") static function bodyGetCenterOfMassTransform(world:Int, body:Int):Void;
	@:native("hj_body_move_kinematic") static function bodyMoveKinematic(world:Int, body:Int, x:Float, y:Float, z:Float, qx:Float, qy:Float, qz:Float,
		qw:Float, deltaTime:Float):Void;
	@:native("hj_body_set_linear_velocity") static function bodySetLinearVelocity(world:Int, body:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_body_add_linear_velocity") static function bodyAddLinearVelocity(world:Int, body:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_body_set_angular_velocity") static function bodySetAngularVelocity(world:Int, body:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_body_get_velocities") static function bodyGetVelocities(world:Int, body:Int):Void;
	@:native("hj_body_get_point_velocity") static function bodyGetPointVelocity(world:Int, body:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_body_add_force") static function bodyAddForce(world:Int, body:Int, x:Float, y:Float, z:Float, atPoint:Int, px:Float, py:Float, pz:Float,
		activation:Int):Void;
	@:native("hj_body_add_torque") static function bodyAddTorque(world:Int, body:Int, x:Float, y:Float, z:Float, activation:Int):Void;
	@:native("hj_body_add_impulse") static function bodyAddImpulse(world:Int, body:Int, x:Float, y:Float, z:Float, atPoint:Int, px:Float, py:Float,
		pz:Float):Void;
	@:native("hj_body_add_angular_impulse") static function bodyAddAngularImpulse(world:Int, body:Int, x:Float, y:Float, z:Float):Void;
	@:native("hj_body_activate") static function bodyActivate(world:Int, body:Int):Void;
	@:native("hj_body_deactivate") static function bodyDeactivate(world:Int, body:Int):Void;
	@:native("hj_body_is_active") static function bodyIsActive(world:Int, body:Int):Int;
	@:native("hj_body_set_motion_type") static function bodySetMotionType(world:Int, body:Int, motionType:Int, activation:Int):Void;
	@:native("hj_body_get_motion_type") static function bodyGetMotionType(world:Int, body:Int):Int;
	@:native("hj_body_set_motion_quality") static function bodySetMotionQuality(world:Int, body:Int, motionQuality:Int):Void;
	@:native("hj_body_set_restitution") static function bodySetRestitution(world:Int, body:Int, restitution:Float):Void;
	@:native("hj_body_get_restitution") static function bodyGetRestitution(world:Int, body:Int):Float;
	@:native("hj_body_set_friction") static function bodySetFriction(world:Int, body:Int, friction:Float):Void;
	@:native("hj_body_get_friction") static function bodyGetFriction(world:Int, body:Int):Float;
	@:native("hj_body_set_gravity_factor") static function bodySetGravityFactor(world:Int, body:Int, factor:Float):Void;
	@:native("hj_body_get_gravity_factor") static function bodyGetGravityFactor(world:Int, body:Int):Float;
	@:native("hj_body_set_is_sensor") static function bodySetIsSensor(world:Int, body:Int, isSensor:Int):Void;
	@:native("hj_body_is_sensor") static function bodyIsSensor(world:Int, body:Int):Int;
	@:native("hj_body_set_user_data") static function bodySetUserData(world:Int, body:Int, userData:Int):Void;
	@:native("hj_body_get_user_data") static function bodyGetUserData(world:Int, body:Int):Int;
	@:native("hj_body_get_world_space_bounds") static function bodyGetWorldSpaceBounds(world:Int, body:Int):Void;
	@:native("hj_body_get_transformed_shape") static function bodyGetTransformedShape(world:Int, body:Int):Int;
	@:native("hj_body_get_world_space_surface_normal") static function bodyGetWorldSpaceSurfaceNormal(world:Int, body:Int, subShapeId:Int, x:Float, y:Float,
		z:Float):Void;
	@:native("hj_world_set_contact_queue") static function worldSetContactQueue(world:Int, maxEvents:Int, recordPersisted:Int):Void;
	@:native("hj_world_get_contacts") static function worldGetContacts(world:Int):Int;
	@:native("hj_world_get_dropped_contacts") static function worldGetDroppedContacts(world:Int):Int;
	@:native("hj_bodies_get_positions_and_rotations") static function bodiesGetPositionsAndRotations(world:Int, count:Int):Int;
	@:native("hj_bodies_get_world_transforms") static function bodiesGetWorldTransforms(world:Int, count:Int):Int;
	@:native("hj_query_cast_ray") static function queryCastRay(world:Int, ox:Float, oy:Float, oz:Float, dx:Float, dy:Float, dz:Float, backFaceTriangles:Int,
		backFaceConvex:Int, treatConvexAsSolid:Int, collector:Int):Int;
	@:native("hj_query_collide_point") static function queryCollidePoint(world:Int, x:Float, y:Float, z:Float, collector:Int):Int;
	@:native("hj_query_collide_shape") static function queryCollideShape(world:Int, shape:Int, maxSeparationDistance:Float, backFaceMode:Int,
		collector:Int):Int;
	@:native("hj_query_cast_shape") static function queryCastShape(world:Int, shape:Int, backFaceTriangles:Int, backFaceConvex:Int, returnDeepestPoint:Int,
		collector:Int):Int;
	@:native("hj_body_exists") static function bodyExists(world:Int, body:Int):Int;
	@:native("hj_shape_get_transformed_world") static function shapeGetTransformedWorld(shape:Int):Void;
	@:native("hj_total_memory") static function totalMemory():Int;
	@:native("hj_free_memory") static function freeMemory():Int;
	@:native("hj_constraint_create") static function constraintCreate(world:Int, kind:Int, body1:Int, body2:Int):Int;
	@:native("hj_constraint_add") static function constraintAdd(world:Int, constraint:Int):Void;
	@:native("hj_constraint_remove") static function constraintRemove(world:Int, constraint:Int):Void;
	@:native("hj_constraint_get_ref_count") static function constraintGetRefCount(world:Int, constraint:Int):Int;
	@:native("hj_constraint_add_ref") static function constraintAddRef(world:Int, constraint:Int):Void;
	@:native("hj_constraint_release") static function constraintRelease(world:Int, constraint:Int):Void;
	@:native("hj_constraint_get_sub_type") static function constraintGetSubType(world:Int, constraint:Int):Int;
	@:native("hj_constraint_set_enabled") static function constraintSetEnabled(world:Int, constraint:Int, enabled:Int):Void;
	@:native("hj_constraint_get_enabled") static function constraintGetEnabled(world:Int, constraint:Int):Int;
	@:native("hj_constraint_set_user_data") static function constraintSetUserData(world:Int, constraint:Int, userData:Int):Void;
	@:native("hj_constraint_get_user_data") static function constraintGetUserData(world:Int, constraint:Int):Int;
	@:native("hj_constraint_get_body") static function constraintGetBody(world:Int, constraint:Int, second:Int):Int;
	@:native("hj_constraint_get_float") static function constraintGetFloat(world:Int, constraint:Int, what:Int):Float;
	@:native("hj_constraint_set_float") static function constraintSetFloat(world:Int, constraint:Int, what:Int, value:Float):Void;
	@:native("hj_constraint_set_range") static function constraintSetRange(world:Int, constraint:Int, min:Float, max:Float):Void;
	@:native("hj_constraint_set_motor_state") static function constraintSetMotorState(world:Int, constraint:Int, axis:Int, state:Int):Void;
	@:native("hj_constraint_get_motor_state") static function constraintGetMotorState(world:Int, constraint:Int, axis:Int):Int;
	@:native("hj_constraint_get_motor") static function constraintGetMotor(world:Int, constraint:Int, axis:Int):Void;
	@:native("hj_constraint_set_motor") static function constraintSetMotor(world:Int, constraint:Int, axis:Int):Void;
	@:native("hj_constraint_six_dof_set_limits") static function constraintSixDofSetLimits(world:Int, constraint:Int, translation:Int):Void;
	@:native("hj_constraint_six_dof_set_target") static function constraintSixDofSetTarget(world:Int, constraint:Int, which:Int):Void;
}
