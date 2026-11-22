// helix-jolt's C ABI over Jolt Physics (hj.h): worlds, shapes and bodies.
#include "hj_internal.h"

#include <Jolt/Core/Factory.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/Shape/CapsuleShape.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <Jolt/Physics/Collision/Shape/CylinderShape.h>
#include <Jolt/Physics/Collision/Shape/EmptyShape.h>
#include <Jolt/Physics/Collision/Shape/HeightFieldShape.h>
#include <Jolt/Physics/Collision/Shape/MeshShape.h>
#include <Jolt/Physics/Collision/Shape/OffsetCenterOfMassShape.h>
#include <Jolt/Physics/Collision/Shape/PlaneShape.h>
#include <Jolt/Physics/Collision/Shape/RotatedTranslatedShape.h>
#include <Jolt/Physics/Collision/Shape/ScaledShape.h>
#include <Jolt/Physics/Collision/Shape/SphereShape.h>
#include <Jolt/Physics/Collision/Shape/StaticCompoundShape.h>
#include <Jolt/Physics/Collision/Shape/TaperedCapsuleShape.h>
#include <Jolt/RegisterTypes.h>

#include <cstring>
#include <string>

using namespace JPH;

namespace hj {

float io_f[64];
int32_t io_i[64];
Array<uint8> bulk;
std::unordered_map<int32_t, World *> worlds;
std::unordered_map<int32_t, ShapeEntry> shapes;
std::unordered_map<const Shape *, int32_t> shape_handles;
int32_t next_world = 0;
int32_t next_shape = 0;
std::string shape_error;

uint8 *bulk_at(size_t bytes) {
	if (bulk.size() < bytes)
		bulk.resize(bytes);
	return bulk.data();
}

World *world_of(int32_t handle) {
	auto found = worlds.find(handle);
	return found == worlds.end() ? nullptr : found->second;
}

Shape *shape_of(int32_t handle) {
	auto found = shapes.find(handle);
	return found == shapes.end() ? nullptr : found->second.ref.GetPtr();
}

int32_t handle_of(const Shape *shape) {
	auto found = shape_handles.find(shape);
	return found == shape_handles.end() ? -1 : found->second;
}

int32_t add_shape(Shape *shape) {
	if (shape == nullptr)
		return -1;
	int32_t existing = handle_of(shape);
	if (existing >= 0)
		return existing;
	int32_t handle = next_shape++;
	shapes[handle] = ShapeEntry{Ref<Shape>(shape), false};
	shape_handles[shape] = handle;
	return handle;
}

void collectable(int32_t handle) {
	auto found = shapes.find(handle);
	if (found != shapes.end())
		found->second.collectable = true;
}

// Frees each shape held by the table alone that has been held by something else since it was made, until none is left, as freeing a
// compound lets go of its parts.
void sweep() {
	bool freed = true;
	while (freed) {
		freed = false;
		for (auto it = shapes.begin(); it != shapes.end();) {
			if (it->second.collectable && it->second.ref->GetRefCount() == 1) {
				shape_handles.erase(it->second.ref.GetPtr());
				it = shapes.erase(it);
				freed = true;
			} else
				++it;
		}
	}
}

int32_t result_shape(const ShapeSettings::ShapeResult &result) {
	if (result.HasError()) {
		shape_error = result.GetError().c_str();
		return -1;
	}
	shape_error.clear();
	return add_shape(const_cast<Shape *>(result.Get().GetPtr()));
}

void write_vec3(float *out, Vec3Arg v) {
	out[0] = v.GetX();
	out[1] = v.GetY();
	out[2] = v.GetZ();
}

void write_quat(float *out, QuatArg q) {
	out[0] = q.GetX();
	out[1] = q.GetY();
	out[2] = q.GetZ();
	out[3] = q.GetW();
}

void write_mat44(float *out, Mat44Arg m) {
	for (int c = 0; c < 4; c++) {
		Vec4 column = m.GetColumn4(c);
		for (int r = 0; r < 4; r++)
			out[c * 4 + r] = column[r];
	}
}

Mat44 read_mat44(const float *in) {
	return Mat44(Vec4(in[0], in[1], in[2], in[3]), Vec4(in[4], in[5], in[6], in[7]), Vec4(in[8], in[9], in[10], in[11]),
				 Vec4(in[12], in[13], in[14], in[15]));
}

int32_t shape_type(EShapeType type) {
	switch (type) {
	case EShapeType::Convex: return 0;
	case EShapeType::Compound: return 1;
	case EShapeType::Decorated: return 2;
	case EShapeType::Mesh: return 3;
	case EShapeType::HeightField: return 4;
	case EShapeType::Plane: return 5;
	default: return 6;
	}
}

int32_t shape_sub_type(EShapeSubType type) {
	switch (type) {
	case EShapeSubType::Sphere: return 0;
	case EShapeSubType::Box: return 1;
	case EShapeSubType::Capsule: return 2;
	case EShapeSubType::TaperedCapsule: return 3;
	case EShapeSubType::Cylinder: return 4;
	case EShapeSubType::TaperedCylinder: return 5;
	case EShapeSubType::ConvexHull: return 6;
	case EShapeSubType::StaticCompound: return 7;
	case EShapeSubType::MutableCompound: return 8;
	case EShapeSubType::RotatedTranslated: return 9;
	case EShapeSubType::Scaled: return 10;
	case EShapeSubType::OffsetCenterOfMass: return 11;
	case EShapeSubType::Mesh: return 12;
	case EShapeSubType::HeightField: return 13;
	case EShapeSubType::Plane: return 14;
	default: return 15;
	}
}

} // namespace hj

using namespace hj;

extern "C" {

float *hj_io_f(void) { return io_f; }

int32_t *hj_io_i(void) { return io_i; }

void *hj_bulk(int32_t bytes) { return bulk_at(bytes > 0 ? size_t(bytes) : 0); }

void hj_init(void) {
	static bool done = false;
	if (done)
		return;
	done = true;
	RegisterDefaultAllocator();
	Factory::sInstance = new Factory();
	RegisterTypes();
}

// Worlds.

int32_t hj_world_create(int32_t max_bodies, int32_t max_body_pairs, int32_t max_contacts, int32_t num_object_layers,
						int32_t num_broad_phase_layers) {
	hj_init();
	const int32_t *tables = reinterpret_cast<const int32_t *>(bulk_at(size_t(num_object_layers + num_object_layers * num_object_layers) * 4));
	World *world = new World(uint(num_object_layers), uint(num_broad_phase_layers));
	for (int32_t layer = 0; layer < num_object_layers; layer++)
		world->broad_phase_layers.MapObjectToBroadPhaseLayer(ObjectLayer(layer), BroadPhaseLayer(uint8(tables[layer])));
	for (int32_t a = 0; a < num_object_layers; a++)
		for (int32_t b = 0; b < num_object_layers; b++)
			if (tables[num_object_layers + a * num_object_layers + b] != 0)
				world->object_pairs.EnableCollision(ObjectLayer(a), ObjectLayer(b));
	world->object_vs_broad_phase = new ObjectVsBroadPhaseLayerFilterTable(world->broad_phase_layers, uint(num_broad_phase_layers),
																			world->object_pairs, uint(num_object_layers));
	world->system.Init(uint(max_bodies), 0, uint(max_body_pairs), uint(max_contacts), world->broad_phase_layers, *world->object_vs_broad_phase,
					   world->object_pairs);
	world->system.SetContactListener(&world->contacts);
	int32_t handle = next_world++;
	worlds[handle] = world;
	return handle;
}

void hj_world_destroy(int32_t handle) {
	World *world = world_of(handle);
	if (world == nullptr)
		return;
	worlds.erase(handle);
	for (auto &entry : world->constraints)
		if (entry.second.added)
			world->system.RemoveConstraint(entry.second.ref);
	world->constraints.clear();
	BodyIDVector bodies;
	world->system.GetBodies(bodies);
	BodyInterface &interface = world->system.GetBodyInterfaceNoLock();
	for (BodyID id : bodies) {
		if (interface.IsAdded(id))
			interface.RemoveBody(id);
		interface.DestroyBody(id);
	}
	delete world;
	sweep();
	if (worlds.empty()) {
		shape_handles.clear();
		shapes.clear();
	}
}

void hj_world_step(int32_t handle, float delta_time, int32_t collision_steps) {
	World *world = world_of(handle);
	if (world == nullptr)
		return;
	world->contacts.begin_step();
	world->system.Update(delta_time, collision_steps, &world->temp, &world->jobs);
}

void hj_world_set_gravity(int32_t handle, float x, float y, float z) {
	if (World *world = world_of(handle))
		world->system.SetGravity(Vec3(x, y, z));
}

void hj_world_get_gravity(int32_t handle) {
	if (World *world = world_of(handle))
		write_vec3(io_f, world->system.GetGravity());
}

// PhysicsSettings in PhysicsSettings.hx's order: floats baumgarte, speculative contact distance, penetration slop, linear cast threshold,
// min velocity for restitution, time before sleep, point velocity sleep threshold; ints velocity steps, position steps, allow sleeping,
// check active edges.
void hj_world_get_settings(int32_t handle) {
	World *world = world_of(handle);
	if (world == nullptr)
		return;
	const PhysicsSettings &s = world->system.GetPhysicsSettings();
	float values[] = {s.mBaumgarte, s.mSpeculativeContactDistance, s.mPenetrationSlop, s.mLinearCastThreshold, s.mMinVelocityForRestitution,
					  s.mTimeBeforeSleep, s.mPointVelocitySleepThreshold};
	memcpy(io_f, values, sizeof(values));
	io_i[0] = int32_t(s.mNumVelocitySteps);
	io_i[1] = int32_t(s.mNumPositionSteps);
	io_i[2] = s.mAllowSleeping ? 1 : 0;
	io_i[3] = s.mCheckActiveEdges ? 1 : 0;
}

void hj_world_set_settings(int32_t handle) {
	World *world = world_of(handle);
	if (world == nullptr)
		return;
	PhysicsSettings s = world->system.GetPhysicsSettings();
	s.mBaumgarte = io_f[0];
	s.mSpeculativeContactDistance = io_f[1];
	s.mPenetrationSlop = io_f[2];
	s.mLinearCastThreshold = io_f[3];
	s.mMinVelocityForRestitution = io_f[4];
	s.mTimeBeforeSleep = io_f[5];
	s.mPointVelocitySleepThreshold = io_f[6];
	s.mNumVelocitySteps = uint(io_i[0]);
	s.mNumPositionSteps = uint(io_i[1]);
	s.mAllowSleeping = io_i[2] != 0;
	s.mCheckActiveEdges = io_i[3] != 0;
	world->system.SetPhysicsSettings(s);
}

int32_t hj_world_num_bodies(int32_t handle) {
	World *world = world_of(handle);
	return world == nullptr ? 0 : int32_t(world->system.GetNumBodies());
}

int32_t hj_world_num_active_bodies(int32_t handle) {
	World *world = world_of(handle);
	return world == nullptr ? 0 : int32_t(world->system.GetNumActiveBodies(EBodyType::RigidBody));
}

int32_t hj_world_max_bodies(int32_t handle) {
	World *world = world_of(handle);
	return world == nullptr ? 0 : int32_t(world->system.GetMaxBodies());
}

int32_t hj_world_get_bodies(int32_t handle, int32_t active) {
	World *world = world_of(handle);
	if (world == nullptr)
		return 0;
	BodyIDVector ids;
	if (active != 0)
		world->system.GetActiveBodies(EBodyType::RigidBody, ids);
	else
		world->system.GetBodies(ids);
	int32_t *out = reinterpret_cast<int32_t *>(bulk_at(ids.size() * 4));
	for (size_t i = 0; i < ids.size(); i++)
		out[i] = int32_t(ids[i].GetIndexAndSequenceNumber());
	return int32_t(ids.size());
}

void hj_world_get_bounds(int32_t handle) {
	if (World *world = world_of(handle)) {
		AABox bounds = world->system.GetBounds();
		write_vec3(io_f, bounds.mMin);
		write_vec3(io_f + 3, bounds.mMax);
	}
}

void hj_world_optimize_broad_phase(int32_t handle) {
	if (World *world = world_of(handle))
		world->system.OptimizeBroadPhase();
}

int32_t hj_world_were_in_contact(int32_t handle, int32_t body1, int32_t body2) {
	World *world = world_of(handle);
	return world != nullptr && world->system.WereBodiesInContact(BodyID(uint32(body1)), BodyID(uint32(body2))) ? 1 : 0;
}

// Shapes made directly.

int32_t hj_shape_box(float half_x, float half_y, float half_z, float convex_radius) {
	hj_init();
	return add_shape(new BoxShape(Vec3(half_x, half_y, half_z), convex_radius));
}

int32_t hj_shape_sphere(float radius) {
	hj_init();
	return add_shape(new SphereShape(radius));
}

int32_t hj_shape_capsule(float half_height, float radius) {
	hj_init();
	return add_shape(new CapsuleShape(half_height, radius));
}

int32_t hj_shape_cylinder(float half_height, float radius, float convex_radius) {
	hj_init();
	return add_shape(new CylinderShape(half_height, radius, convex_radius));
}

int32_t hj_shape_scaled(int32_t shape, float x, float y, float z) {
	Shape *inner = shape_of(shape);
	if (inner == nullptr)
		return -1;
	collectable(shape);
	return add_shape(new ScaledShape(inner, Vec3(x, y, z)));
}

int32_t hj_shape_offset_center_of_mass(int32_t shape, float x, float y, float z) {
	Shape *inner = shape_of(shape);
	if (inner == nullptr)
		return -1;
	collectable(shape);
	return add_shape(new OffsetCenterOfMassShape(inner, Vec3(x, y, z)));
}

int32_t hj_shape_plane(float normal_x, float normal_y, float normal_z, float constant, float half_extent) {
	hj_init();
	return add_shape(new PlaneShape(Plane(Vec3(normal_x, normal_y, normal_z), constant), nullptr, half_extent));
}

int32_t hj_shape_empty(float x, float y, float z) {
	hj_init();
	return add_shape(new EmptyShape(Vec3(x, y, z)));
}

// Shapes made from settings.

int32_t hj_shape_tapered_capsule(float half_height, float top_radius, float bottom_radius, float density, int32_t user_data) {
	hj_init();
	TaperedCapsuleShapeSettings settings(half_height, top_radius, bottom_radius);
	settings.mDensity = density;
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_convex_hull(int32_t num_points, float max_convex_radius, float hull_tolerance, float density, int32_t user_data) {
	hj_init();
	const float *in = reinterpret_cast<const float *>(bulk_at(size_t(num_points) * 12));
	Array<Vec3> points;
	points.reserve(size_t(num_points));
	for (int32_t i = 0; i < num_points; i++)
		points.push_back(Vec3(in[i * 3], in[i * 3 + 1], in[i * 3 + 2]));
	ConvexHullShapeSettings settings(points, max_convex_radius);
	settings.mHullTolerance = hull_tolerance;
	settings.mDensity = density;
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_mesh(int32_t num_vertices, int32_t num_triangles, int32_t max_triangles_per_leaf, int32_t user_data) {
	hj_init();
	const uint8 *in = bulk_at(size_t(num_vertices) * 12 + size_t(num_triangles) * 12);
	const float *v = reinterpret_cast<const float *>(in);
	const int32_t *t = reinterpret_cast<const int32_t *>(in + size_t(num_vertices) * 12);
	VertexList vertices;
	vertices.reserve(size_t(num_vertices));
	for (int32_t i = 0; i < num_vertices; i++)
		vertices.push_back(Float3(v[i * 3], v[i * 3 + 1], v[i * 3 + 2]));
	IndexedTriangleList triangles;
	triangles.reserve(size_t(num_triangles));
	for (int32_t i = 0; i < num_triangles; i++)
		triangles.push_back(IndexedTriangle(uint32(t[i * 3]), uint32(t[i * 3 + 1]), uint32(t[i * 3 + 2])));
	MeshShapeSettings settings(std::move(vertices), std::move(triangles));
	settings.mMaxTrianglesPerLeaf = uint(max_triangles_per_leaf);
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_height_field(int32_t sample_count, int32_t block_size, int32_t bits_per_sample, int32_t user_data) {
	hj_init();
	const float *samples = reinterpret_cast<const float *>(bulk_at(size_t(sample_count) * size_t(sample_count) * 4));
	HeightFieldShapeSettings settings(samples, Vec3(io_f[0], io_f[1], io_f[2]), Vec3(io_f[3], io_f[4], io_f[5]), uint32(sample_count));
	settings.mBlockSize = uint32(block_size);
	settings.mBitsPerSample = uint32(bits_per_sample);
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_static_compound(int32_t num_parts, int32_t user_data) {
	hj_init();
	const uint8 *in = bulk_at(size_t(num_parts) * 36);
	const float *f = reinterpret_cast<const float *>(in);
	const int32_t *ints = reinterpret_cast<const int32_t *>(in + size_t(num_parts) * 28);
	StaticCompoundShapeSettings settings;
	for (int32_t i = 0; i < num_parts; i++) {
		Shape *part = shape_of(ints[i * 2]);
		if (part == nullptr) {
			shape_error = "a part of the compound is not a shape";
			return -1;
		}
		collectable(ints[i * 2]);
		const float *p = f + i * 7;
		settings.AddShape(Vec3(p[0], p[1], p[2]), Quat(p[3], p[4], p[5], p[6]), part, uint32(ints[i * 2 + 1]));
	}
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_rotated_translated(int32_t shape, float x, float y, float z, float qx, float qy, float qz, float qw, int32_t user_data) {
	Shape *inner = shape_of(shape);
	if (inner == nullptr) {
		shape_error = "the shape moved is not a shape";
		return -1;
	}
	collectable(shape);
	RotatedTranslatedShapeSettings settings(Vec3(x, y, z), Quat(qx, qy, qz, qw), inner);
	settings.mUserData = uint64(uint32(user_data));
	return result_shape(settings.Create());
}

int32_t hj_shape_error(void) {
	uint8 *out = bulk_at(shape_error.size());
	memcpy(out, shape_error.data(), shape_error.size());
	return int32_t(shape_error.size());
}

// A shape's count, type and values.

int32_t hj_shape_get_ref_count(int32_t shape) {
	Shape *s = shape_of(shape);
	return s == nullptr ? 0 : int32_t(s->GetRefCount()) - 1;
}

void hj_shape_add_ref(int32_t shape) {
	if (Shape *s = shape_of(shape))
		s->AddRef();
}

void hj_shape_release(int32_t shape) {
	Shape *s = shape_of(shape);
	if (s == nullptr)
		return;
	if (s->GetRefCount() > 1)
		s->Release();
	collectable(shape);
	sweep();
}

int32_t hj_shape_get_type(int32_t shape) {
	Shape *s = shape_of(shape);
	return s == nullptr ? 6 : shape_type(s->GetType());
}

int32_t hj_shape_get_sub_type(int32_t shape) {
	Shape *s = shape_of(shape);
	return s == nullptr ? 15 : shape_sub_type(s->GetSubType());
}

int32_t hj_shape_must_be_static(int32_t shape) {
	Shape *s = shape_of(shape);
	return s != nullptr && s->MustBeStatic() ? 1 : 0;
}

void hj_shape_get_local_bounds(int32_t shape) {
	if (Shape *s = shape_of(shape)) {
		AABox bounds = s->GetLocalBounds();
		write_vec3(io_f, bounds.mMin);
		write_vec3(io_f + 3, bounds.mMax);
	}
}

void hj_shape_get_center_of_mass(int32_t shape) {
	if (Shape *s = shape_of(shape))
		write_vec3(io_f, s->GetCenterOfMass());
}

float hj_shape_get_volume(int32_t shape) {
	Shape *s = shape_of(shape);
	return s == nullptr ? 0.0f : s->GetVolume();
}

void hj_shape_get_mass_properties(int32_t shape) {
	if (Shape *s = shape_of(shape)) {
		MassProperties properties = s->GetMassProperties();
		io_f[0] = properties.mMass;
		write_mat44(io_f + 1, properties.mInertia);
	}
}

int32_t hj_shape_get_user_data(int32_t shape) {
	Shape *s = shape_of(shape);
	return s == nullptr ? 0 : int32_t(uint32(s->GetUserData()));
}

void hj_shape_set_user_data(int32_t shape, int32_t user_data) {
	if (Shape *s = shape_of(shape))
		s->SetUserData(uint64(uint32(user_data)));
}

float hj_shape_get_density(int32_t shape) {
	Shape *s = shape_of(shape);
	return s != nullptr && s->GetType() == EShapeType::Convex ? static_cast<ConvexShape *>(s)->GetDensity() : 0.0f;
}

void hj_shape_set_density(int32_t shape, float density) {
	Shape *s = shape_of(shape);
	if (s != nullptr && s->GetType() == EShapeType::Convex)
		static_cast<ConvexShape *>(s)->SetDensity(density);
}

void hj_shape_get_dimensions(int32_t shape) {
	Shape *s = shape_of(shape);
	if (s == nullptr)
		return;
	switch (s->GetSubType()) {
	case EShapeSubType::Box: write_vec3(io_f, static_cast<BoxShape *>(s)->GetHalfExtent()); break;
	case EShapeSubType::Sphere: io_f[0] = static_cast<SphereShape *>(s)->GetRadius(); break;
	case EShapeSubType::Capsule:
		io_f[0] = static_cast<CapsuleShape *>(s)->GetRadius();
		io_f[1] = static_cast<CapsuleShape *>(s)->GetHalfHeightOfCylinder();
		break;
	case EShapeSubType::Cylinder:
		io_f[0] = static_cast<CylinderShape *>(s)->GetRadius();
		io_f[1] = static_cast<CylinderShape *>(s)->GetHalfHeight();
		break;
	case EShapeSubType::Scaled: write_vec3(io_f, static_cast<ScaledShape *>(s)->GetScale()); break;
	default: break;
	}
}

void hj_shape_get_world_surface_normal(int32_t shape, int32_t sub_shape_id) {
	Shape *s = shape_of(shape);
	if (s == nullptr)
		return;
	TransformedShape transformed(RVec3(io_f[0], io_f[1], io_f[2]), Quat(io_f[3], io_f[4], io_f[5], io_f[6]), s, BodyID());
	transformed.SetShapeScale(Vec3(io_f[7], io_f[8], io_f[9]));
	SubShapeID id;
	id.SetValue(uint32(sub_shape_id));
	write_vec3(io_f, transformed.GetWorldSpaceSurfaceNormal(id, RVec3(io_f[10], io_f[11], io_f[12])));
}

} // extern "C"
