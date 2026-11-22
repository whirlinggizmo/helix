// helix-jolt's C ABI over Jolt Physics (hj.h): bodies, and many bodies at once.
#include "hj_internal.h"

#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Body/BodyLock.h>

using namespace JPH;
using namespace hj;

namespace {

BodyInterface *bodies_of(int32_t world) {
	World *w = world_of(world);
	return w == nullptr ? nullptr : &w->system.GetBodyInterfaceNoLock();
}

BodyID id_of(int32_t body) { return BodyID(uint32(body)); }

EActivation activation_of(int32_t activation) { return activation == 0 ? EActivation::Activate : EActivation::DontActivate; }

} // namespace

extern "C" {

// The settings in BodyCreationSettings.hx's order. io_f: position 0-2, rotation 3-6, linear velocity 7-9, angular velocity 10-12,
// friction 13, restitution 14, linear damping 15, angular damping 16, max linear velocity 17, max angular velocity 18, gravity factor 19,
// mass 20, inertia 21-36 by columns. io_i: user data 0, object layer 1, motion type 2, allowed DOFs 3, allow dynamic or kinematic 4,
// is sensor 5, motion quality 6, allow sleeping 7, override mass properties 8.
int32_t hj_body_create(int32_t world, int32_t shape, int32_t add, int32_t activation) {
	BodyInterface *bodies = bodies_of(world);
	Shape *s = shape_of(shape);
	if (bodies == nullptr || s == nullptr)
		return -1;
	BodyCreationSettings settings(s, RVec3(io_f[0], io_f[1], io_f[2]), Quat(io_f[3], io_f[4], io_f[5], io_f[6]), EMotionType(io_i[2]),
								  ObjectLayer(io_i[1]));
	settings.mLinearVelocity = Vec3(io_f[7], io_f[8], io_f[9]);
	settings.mAngularVelocity = Vec3(io_f[10], io_f[11], io_f[12]);
	settings.mFriction = io_f[13];
	settings.mRestitution = io_f[14];
	settings.mLinearDamping = io_f[15];
	settings.mAngularDamping = io_f[16];
	settings.mMaxLinearVelocity = io_f[17];
	settings.mMaxAngularVelocity = io_f[18];
	settings.mGravityFactor = io_f[19];
	settings.mMassPropertiesOverride.mMass = io_f[20];
	settings.mMassPropertiesOverride.mInertia = read_mat44(io_f + 21);
	settings.mUserData = uint64(uint32(io_i[0]));
	settings.mAllowedDOFs = EAllowedDOFs(io_i[3]);
	settings.mAllowDynamicOrKinematic = io_i[4] != 0;
	settings.mIsSensor = io_i[5] != 0;
	settings.mMotionQuality = EMotionQuality(io_i[6]);
	settings.mAllowSleeping = io_i[7] != 0;
	settings.mOverrideMassProperties = EOverrideMassProperties(io_i[8]);
	Body *body = bodies->CreateBody(settings);
	if (body == nullptr)
		return -1;
	collectable(shape);
	if (add != 0)
		bodies->AddBody(body->GetID(), activation_of(activation));
	return int32_t(body->GetID().GetIndexAndSequenceNumber());
}

void hj_body_destroy(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world)) {
		if (bodies->IsAdded(id_of(body)))
			bodies->RemoveBody(id_of(body));
		bodies->DestroyBody(id_of(body));
		sweep();
	}
}

void hj_body_add(int32_t world, int32_t body, int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->AddBody(id_of(body), activation_of(activation));
}

void hj_body_remove(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->RemoveBody(id_of(body));
}

int32_t hj_body_is_added(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies != nullptr && bodies->IsAdded(id_of(body)) ? 1 : 0;
}

int32_t hj_body_get_shape(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? -1 : handle_of(bodies->GetShape(id_of(body)).GetPtr());
}

void hj_body_set_shape(int32_t world, int32_t body, int32_t shape, int32_t update_mass, int32_t activation) {
	BodyInterface *bodies = bodies_of(world);
	Shape *s = shape_of(shape);
	if (bodies == nullptr || s == nullptr)
		return;
	collectable(shape);
	bodies->SetShape(id_of(body), s, update_mass != 0, activation_of(activation));
	sweep();
}

void hj_body_set_object_layer(int32_t world, int32_t body, int32_t layer) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetObjectLayer(id_of(body), ObjectLayer(layer));
}

int32_t hj_body_get_object_layer(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0 : int32_t(bodies->GetObjectLayer(id_of(body)));
}

void hj_body_set_position_and_rotation(int32_t world, int32_t body, float x, float y, float z, float qx, float qy, float qz, float qw,
									   int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetPositionAndRotation(id_of(body), RVec3(x, y, z), Quat(qx, qy, qz, qw), activation_of(activation));
}

void hj_body_set_position(int32_t world, int32_t body, float x, float y, float z, int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetPosition(id_of(body), RVec3(x, y, z), activation_of(activation));
}

void hj_body_set_rotation(int32_t world, int32_t body, float qx, float qy, float qz, float qw, int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetRotation(id_of(body), Quat(qx, qy, qz, qw), activation_of(activation));
}

void hj_body_get_position_and_rotation(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return;
	RVec3 position;
	Quat rotation;
	bodies->GetPositionAndRotation(id_of(body), position, rotation);
	write_vec3(io_f, position);
	write_quat(io_f + 3, rotation);
}

void hj_body_get_world_transform(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world))
		write_mat44(io_f, bodies->GetWorldTransform(id_of(body)));
}

void hj_body_get_center_of_mass_transform(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world))
		write_mat44(io_f, bodies->GetCenterOfMassTransform(id_of(body)));
}

void hj_body_move_kinematic(int32_t world, int32_t body, float x, float y, float z, float qx, float qy, float qz, float qw, float delta_time) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->MoveKinematic(id_of(body), RVec3(x, y, z), Quat(qx, qy, qz, qw), delta_time);
}

void hj_body_set_linear_velocity(int32_t world, int32_t body, float x, float y, float z) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetLinearVelocity(id_of(body), Vec3(x, y, z));
}

void hj_body_add_linear_velocity(int32_t world, int32_t body, float x, float y, float z) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->AddLinearVelocity(id_of(body), Vec3(x, y, z));
}

void hj_body_set_angular_velocity(int32_t world, int32_t body, float x, float y, float z) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetAngularVelocity(id_of(body), Vec3(x, y, z));
}

void hj_body_get_velocities(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return;
	Vec3 linear, angular;
	bodies->GetLinearAndAngularVelocity(id_of(body), linear, angular);
	write_vec3(io_f, linear);
	write_vec3(io_f + 3, angular);
}

void hj_body_get_point_velocity(int32_t world, int32_t body, float x, float y, float z) {
	if (BodyInterface *bodies = bodies_of(world))
		write_vec3(io_f, bodies->GetPointVelocity(id_of(body), RVec3(x, y, z)));
}

void hj_body_add_force(int32_t world, int32_t body, float x, float y, float z, int32_t at_point, float px, float py, float pz,
					   int32_t activation) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return;
	if (at_point != 0)
		bodies->AddForce(id_of(body), Vec3(x, y, z), RVec3(px, py, pz), activation_of(activation));
	else
		bodies->AddForce(id_of(body), Vec3(x, y, z), activation_of(activation));
}

void hj_body_add_torque(int32_t world, int32_t body, float x, float y, float z, int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->AddTorque(id_of(body), Vec3(x, y, z), activation_of(activation));
}

void hj_body_add_impulse(int32_t world, int32_t body, float x, float y, float z, int32_t at_point, float px, float py, float pz) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return;
	if (at_point != 0)
		bodies->AddImpulse(id_of(body), Vec3(x, y, z), RVec3(px, py, pz));
	else
		bodies->AddImpulse(id_of(body), Vec3(x, y, z));
}

void hj_body_add_angular_impulse(int32_t world, int32_t body, float x, float y, float z) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->AddAngularImpulse(id_of(body), Vec3(x, y, z));
}

void hj_body_activate(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->ActivateBody(id_of(body));
}

void hj_body_deactivate(int32_t world, int32_t body) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->DeactivateBody(id_of(body));
}

int32_t hj_body_is_active(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies != nullptr && bodies->IsActive(id_of(body)) ? 1 : 0;
}

void hj_body_set_motion_type(int32_t world, int32_t body, int32_t motion_type, int32_t activation) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetMotionType(id_of(body), EMotionType(motion_type), activation_of(activation));
}

int32_t hj_body_get_motion_type(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0 : int32_t(bodies->GetMotionType(id_of(body)));
}

void hj_body_set_motion_quality(int32_t world, int32_t body, int32_t motion_quality) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetMotionQuality(id_of(body), EMotionQuality(motion_quality));
}

void hj_body_set_restitution(int32_t world, int32_t body, float restitution) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetRestitution(id_of(body), restitution);
}

float hj_body_get_restitution(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0.0f : bodies->GetRestitution(id_of(body));
}

void hj_body_set_friction(int32_t world, int32_t body, float friction) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetFriction(id_of(body), friction);
}

float hj_body_get_friction(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0.0f : bodies->GetFriction(id_of(body));
}

void hj_body_set_gravity_factor(int32_t world, int32_t body, float factor) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetGravityFactor(id_of(body), factor);
}

float hj_body_get_gravity_factor(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0.0f : bodies->GetGravityFactor(id_of(body));
}

void hj_body_set_is_sensor(int32_t world, int32_t body, int32_t is_sensor) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetIsSensor(id_of(body), is_sensor != 0);
}

int32_t hj_body_is_sensor(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies != nullptr && bodies->IsSensor(id_of(body)) ? 1 : 0;
}

void hj_body_set_user_data(int32_t world, int32_t body, int32_t user_data) {
	if (BodyInterface *bodies = bodies_of(world))
		bodies->SetUserData(id_of(body), uint64(uint32(user_data)));
}

int32_t hj_body_get_user_data(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	return bodies == nullptr ? 0 : int32_t(uint32(bodies->GetUserData(id_of(body))));
}

void hj_body_get_world_space_bounds(int32_t world, int32_t body) {
	World *w = world_of(world);
	if (w == nullptr)
		return;
	BodyLockRead lock(w->system.GetBodyLockInterfaceNoLock(), id_of(body));
	if (!lock.Succeeded())
		return;
	const AABox &bounds = lock.GetBody().GetWorldSpaceBounds();
	write_vec3(io_f, bounds.mMin);
	write_vec3(io_f + 3, bounds.mMax);
}

int32_t hj_body_get_transformed_shape(int32_t world, int32_t body) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return -1;
	TransformedShape transformed = bodies->GetTransformedShape(id_of(body));
	write_vec3(io_f, transformed.mShapePositionCOM);
	write_quat(io_f + 3, transformed.mShapeRotation);
	write_vec3(io_f + 7, transformed.GetShapeScale());
	return handle_of(transformed.mShape.GetPtr());
}

void hj_body_get_world_space_surface_normal(int32_t world, int32_t body, int32_t sub_shape_id, float x, float y, float z) {
	World *w = world_of(world);
	if (w == nullptr)
		return;
	BodyLockRead lock(w->system.GetBodyLockInterfaceNoLock(), id_of(body));
	if (!lock.Succeeded())
		return;
	SubShapeID id;
	id.SetValue(uint32(sub_shape_id));
	write_vec3(io_f, lock.GetBody().GetWorldSpaceSurfaceNormal(id, RVec3(x, y, z)));
}

// Many bodies at once.

int32_t hj_bodies_get_positions_and_rotations(int32_t world, int32_t count) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return 0;
	uint8 *area = bulk_at(size_t(count) * 4 + size_t(count) * 28);
	const int32_t *ids = reinterpret_cast<const int32_t *>(area);
	float *out = reinterpret_cast<float *>(area + size_t(count) * 4);
	for (int32_t i = 0; i < count; i++) {
		RVec3 position;
		Quat rotation;
		bodies->GetPositionAndRotation(id_of(ids[i]), position, rotation);
		write_vec3(out + i * 7, position);
		write_quat(out + i * 7 + 3, rotation);
	}
	return count;
}

int32_t hj_bodies_get_world_transforms(int32_t world, int32_t count) {
	BodyInterface *bodies = bodies_of(world);
	if (bodies == nullptr)
		return 0;
	uint8 *area = bulk_at(size_t(count) * 4 + size_t(count) * 64);
	const int32_t *ids = reinterpret_cast<const int32_t *>(area);
	float *out = reinterpret_cast<float *>(area + size_t(count) * 4);
	for (int32_t i = 0; i < count; i++)
		write_mat44(out + i * 16, bodies->GetWorldTransform(id_of(ids[i])));
	return count;
}

} // extern "C"
