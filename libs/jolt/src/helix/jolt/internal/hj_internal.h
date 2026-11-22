// What helix-jolt's C++ files share: the world, the tables of handles and the shared areas.
#ifndef HJ_INTERNAL_H
#define HJ_INTERNAL_H

#include "hj.h"

#include <Jolt/Jolt.h>

#include <Jolt/Core/JobSystemSingleThreaded.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Physics/Collision/BroadPhase/BroadPhaseLayerInterfaceTable.h>
#include <Jolt/Physics/Collision/BroadPhase/ObjectVsBroadPhaseLayerFilterTable.h>
#include <Jolt/Physics/Collision/ContactListener.h>
#include <Jolt/Physics/Collision/ObjectLayerPairFilterTable.h>
#include <Jolt/Physics/Constraints/TwoBodyConstraint.h>
#include <Jolt/Physics/PhysicsSystem.h>

#include <unordered_map>

namespace hj {

// A contact of a step, as ContactEvent.hx reads it.
struct ContactRecord {
	int32_t type, body1, body2, sub_shape1, sub_shape2;
	float normal[3], point[3], depth;
};

// Records a step's contacts, when the program has set a queue, in the order Jolt reports them.
class ContactQueue : public JPH::ContactListener {
public:
	bool enabled = false;
	bool record_persisted = false;
	int32_t max_events = 0;
	int32_t dropped = 0;
	JPH::Array<ContactRecord> events;
	JPH::BodyInterface *bodies = nullptr;

	void begin_step();
	void OnContactAdded(const JPH::Body &inBody1, const JPH::Body &inBody2, const JPH::ContactManifold &inManifold,
						JPH::ContactSettings &ioSettings) override;
	void OnContactPersisted(const JPH::Body &inBody1, const JPH::Body &inBody2, const JPH::ContactManifold &inManifold,
							JPH::ContactSettings &ioSettings) override;
	void OnContactRemoved(const JPH::SubShapeIDPair &inSubShapePair) override;

private:
	void record(int32_t type, const JPH::Body &inBody1, const JPH::Body &inBody2, const JPH::ContactManifold &inManifold);
};

// A constraint a world holds, with whether the system has it added.
struct ConstraintEntry {
	JPH::Ref<JPH::TwoBodyConstraint> ref;
	bool added;
};

struct World {
	JPH::BroadPhaseLayerInterfaceTable broad_phase_layers;
	JPH::ObjectLayerPairFilterTable object_pairs;
	JPH::ObjectVsBroadPhaseLayerFilterTable *object_vs_broad_phase = nullptr;
	JPH::PhysicsSystem system;
	JPH::TempAllocatorImpl temp{8 * 1024 * 1024};
	JPH::JobSystemSingleThreaded jobs{JPH::cMaxPhysicsJobs};
	ContactQueue contacts;
	std::unordered_map<int32_t, ConstraintEntry> constraints;
	int32_t next_constraint = 0;

	World(JPH::uint num_object_layers, JPH::uint num_broad_phase_layers)
		: broad_phase_layers(num_object_layers, num_broad_phase_layers), object_pairs(num_object_layers) {}
	~World() { delete object_vs_broad_phase; }
};

// A shape the tables hold. A shape is freed once the table holds it alone and something else (a body, another shape, the program)
// has held it since it was made.
struct ShapeEntry {
	JPH::Ref<JPH::Shape> ref;
	bool collectable;
};

extern float io_f[64];
extern int32_t io_i[64];
extern std::unordered_map<int32_t, ShapeEntry> shapes;

JPH::uint8 *bulk_at(size_t bytes);
World *world_of(int32_t handle);
JPH::Shape *shape_of(int32_t handle);
int32_t handle_of(const JPH::Shape *shape);
void collectable(int32_t handle);
void sweep();
void write_vec3(float *out, JPH::Vec3Arg v);
void write_quat(float *out, JPH::QuatArg q);
void write_mat44(float *out, JPH::Mat44Arg m);
JPH::Mat44 read_mat44(const float *in);

} // namespace hj

#endif
