// helix-jolt's C ABI over Jolt Physics (hj.h): queries against the bodies, and what helix-jolt's Haxe asks of the module itself.
#include "hj_internal.h"

#include <Jolt/Physics/Body/BodyFilter.h>
#include <Jolt/Physics/Body/BodyLock.h>
#include <Jolt/Physics/Collision/CastResult.h>
#include <Jolt/Physics/Collision/CollidePointResult.h>
#include <Jolt/Physics/Collision/CollideShape.h>
#include <Jolt/Physics/Collision/CollisionCollectorImpl.h>
#include <Jolt/Physics/Collision/NarrowPhaseQuery.h>
#include <Jolt/Physics/Collision/RayCast.h>
#include <Jolt/Physics/Collision/ShapeCast.h>

#ifdef __EMSCRIPTEN__
#include <malloc.h>
#endif

using namespace JPH;
using namespace hj;

namespace {

// The filters a query reads from hj_io_i: broad phase kind and value, object layer kind and value, body kind and count (0 none, 1 the
// default for an object layer or one body, 2 a specified layer or a list of bodies, read from the bulk buffer's first ints).
struct Filters {
	BroadPhaseLayerFilter all_broad_phase;
	ObjectLayerFilter all_layers;
	BodyFilter all_bodies;
	ShapeFilter all_parts;
	DefaultBroadPhaseLayerFilter *default_broad_phase = nullptr;
	SpecifiedBroadPhaseLayerFilter *specified_broad_phase = nullptr;
	DefaultObjectLayerFilter *default_layer = nullptr;
	SpecifiedObjectLayerFilter *specified_layer = nullptr;
	IgnoreSingleBodyFilter *ignore_one = nullptr;
	IgnoreMultipleBodiesFilter *ignore_many = nullptr;

	explicit Filters(World *world) {
		if (io_i[0] == 1)
			default_broad_phase = new DefaultBroadPhaseLayerFilter(*world->object_vs_broad_phase, ObjectLayer(io_i[1]));
		else if (io_i[0] == 2)
			specified_broad_phase = new SpecifiedBroadPhaseLayerFilter(BroadPhaseLayer(uint8(io_i[1])));
		if (io_i[2] == 1)
			default_layer = new DefaultObjectLayerFilter(world->object_pairs, ObjectLayer(io_i[3]));
		else if (io_i[2] == 2)
			specified_layer = new SpecifiedObjectLayerFilter(ObjectLayer(io_i[3]));
		if (io_i[4] == 1)
			ignore_one = new IgnoreSingleBodyFilter(BodyID(uint32(io_i[5])));
		else if (io_i[4] == 2) {
			ignore_many = new IgnoreMultipleBodiesFilter();
			const int32_t *ids = reinterpret_cast<const int32_t *>(bulk_at(size_t(io_i[5]) * 4));
			for (int32_t i = 0; i < io_i[5]; i++)
				ignore_many->IgnoreBody(BodyID(uint32(ids[i])));
		}
	}

	~Filters() {
		delete default_broad_phase;
		delete specified_broad_phase;
		delete default_layer;
		delete specified_layer;
		delete ignore_one;
		delete ignore_many;
	}

	const BroadPhaseLayerFilter &broad_phase() const {
		return default_broad_phase != nullptr ? *default_broad_phase : specified_broad_phase != nullptr ? *specified_broad_phase : all_broad_phase;
	}

	const ObjectLayerFilter &layers() const {
		return default_layer != nullptr ? *default_layer : specified_layer != nullptr ? static_cast<const ObjectLayerFilter &>(*specified_layer)
																					  : all_layers;
	}

	const BodyFilter &bodies() const {
		return ignore_one != nullptr ? *ignore_one : ignore_many != nullptr ? static_cast<const BodyFilter &>(*ignore_many) : all_bodies;
	}
};

// Runs a query into the collector its kind names (0 all, 1 closest, 2 any) and returns its hits in found order.
template <class CollectorType, class Run>
Array<typename CollectorType::ResultType> collect(int32_t kind, Run run) {
	Array<typename CollectorType::ResultType> hits;
	if (kind == 1) {
		ClosestHitCollisionCollector<CollectorType> collector;
		run(collector);
		if (collector.HadHit())
			hits.push_back(collector.mHit);
	} else if (kind == 2) {
		AnyHitCollisionCollector<CollectorType> collector;
		run(collector);
		if (collector.HadHit())
			hits.push_back(collector.mHit);
	} else {
		AllHitCollisionCollector<CollectorType> collector;
		run(collector);
		hits = collector.mHits;
	}
	return hits;
}

// A collide shape result as CollideShapeResult.hx reads it: 13 numbers.
void write_collide(uint8 *out, const CollideShapeResult &hit) {
	float *f = reinterpret_cast<float *>(out);
	int32_t *i = reinterpret_cast<int32_t *>(out);
	write_vec3(f, hit.mContactPointOn1);
	write_vec3(f + 3, hit.mContactPointOn2);
	write_vec3(f + 6, hit.mPenetrationAxis);
	f[9] = hit.mPenetrationDepth;
	i[10] = int32_t(hit.mSubShapeID1.GetValue());
	i[11] = int32_t(hit.mSubShapeID2.GetValue());
	i[12] = int32_t(hit.mBodyID2.GetIndexAndSequenceNumber());
}

} // namespace

extern "C" {

int32_t hj_query_cast_ray(int32_t world, float ox, float oy, float oz, float dx, float dy, float dz, int32_t back_face_triangles,
						  int32_t back_face_convex, int32_t treat_convex_as_solid, int32_t collector) {
	World *w = world_of(world);
	if (w == nullptr)
		return 0;
	Filters filters(w);
	RRayCast ray(RVec3(ox, oy, oz), Vec3(dx, dy, dz));
	RayCastSettings settings;
	settings.mBackFaceModeTriangles = EBackFaceMode(back_face_triangles);
	settings.mBackFaceModeConvex = EBackFaceMode(back_face_convex);
	settings.mTreatConvexAsSolid = treat_convex_as_solid != 0;
	auto hits = collect<CastRayCollector>(collector, [&](CastRayCollector &c) {
		w->system.GetNarrowPhaseQueryNoLock().CastRay(ray, settings, c, filters.broad_phase(), filters.layers(), filters.bodies(), filters.all_parts);
	});
	int32_t *out = reinterpret_cast<int32_t *>(bulk_at(hits.size() * 12));
	for (size_t n = 0; n < hits.size(); n++) {
		out[n * 3] = int32_t(hits[n].mBodyID.GetIndexAndSequenceNumber());
		out[n * 3 + 1] = int32_t(hits[n].mSubShapeID2.GetValue());
		reinterpret_cast<float *>(out)[n * 3 + 2] = hits[n].mFraction;
	}
	return int32_t(hits.size());
}

int32_t hj_query_collide_point(int32_t world, float x, float y, float z, int32_t collector) {
	World *w = world_of(world);
	if (w == nullptr)
		return 0;
	Filters filters(w);
	auto hits = collect<CollidePointCollector>(collector, [&](CollidePointCollector &c) {
		w->system.GetNarrowPhaseQueryNoLock().CollidePoint(RVec3(x, y, z), c, filters.broad_phase(), filters.layers(), filters.bodies(),
														   filters.all_parts);
	});
	int32_t *out = reinterpret_cast<int32_t *>(bulk_at(hits.size() * 8));
	for (size_t n = 0; n < hits.size(); n++) {
		out[n * 2] = int32_t(hits[n].mBodyID.GetIndexAndSequenceNumber());
		out[n * 2 + 1] = int32_t(hits[n].mSubShapeID2.GetValue());
	}
	return int32_t(hits.size());
}

// hj_io_f: scale 0-2, center of mass transform 3-18 by columns, base offset 22-24.
int32_t hj_query_collide_shape(int32_t world, int32_t shape, float max_separation_distance, int32_t back_face_mode, int32_t collector) {
	World *w = world_of(world);
	Shape *s = shape_of(shape);
	if (w == nullptr || s == nullptr)
		return 0;
	Filters filters(w);
	CollideShapeSettings settings;
	settings.mMaxSeparationDistance = max_separation_distance;
	settings.mBackFaceMode = EBackFaceMode(back_face_mode);
	Vec3 scale(io_f[0], io_f[1], io_f[2]);
	RMat44 transform = read_mat44(io_f + 3);
	RVec3 base(io_f[22], io_f[23], io_f[24]);
	auto hits = collect<CollideShapeCollector>(collector, [&](CollideShapeCollector &c) {
		w->system.GetNarrowPhaseQueryNoLock().CollideShape(s, scale, transform, settings, base, c, filters.broad_phase(), filters.layers(),
														   filters.bodies(), filters.all_parts);
	});
	uint8 *out = bulk_at(hits.size() * 52);
	for (size_t n = 0; n < hits.size(); n++)
		write_collide(out + n * 52, hits[n]);
	return int32_t(hits.size());
}

// hj_io_f: scale 0-2, center of mass start 3-18 by columns, direction 19-21, base offset 22-24.
int32_t hj_query_cast_shape(int32_t world, int32_t shape, int32_t back_face_triangles, int32_t back_face_convex, int32_t return_deepest_point,
							int32_t collector) {
	World *w = world_of(world);
	Shape *s = shape_of(shape);
	if (w == nullptr || s == nullptr)
		return 0;
	Filters filters(w);
	ShapeCastSettings settings;
	settings.mBackFaceModeTriangles = EBackFaceMode(back_face_triangles);
	settings.mBackFaceModeConvex = EBackFaceMode(back_face_convex);
	settings.mReturnDeepestPoint = return_deepest_point != 0;
	RShapeCast cast(s, Vec3(io_f[0], io_f[1], io_f[2]), read_mat44(io_f + 3), Vec3(io_f[19], io_f[20], io_f[21]));
	RVec3 base(io_f[22], io_f[23], io_f[24]);
	auto hits = collect<CastShapeCollector>(collector, [&](CastShapeCollector &c) {
		w->system.GetNarrowPhaseQueryNoLock().CastShape(cast, settings, base, c, filters.broad_phase(), filters.layers(), filters.bodies(),
														filters.all_parts);
	});
	uint8 *out = bulk_at(hits.size() * 60);
	for (size_t n = 0; n < hits.size(); n++) {
		write_collide(out + n * 60, hits[n]);
		reinterpret_cast<float *>(out + n * 60)[13] = hits[n].mFraction;
		reinterpret_cast<int32_t *>(out + n * 60)[14] = hits[n].mIsBackFaceHit ? 1 : 0;
	}
	return int32_t(hits.size());
}

int32_t hj_body_exists(int32_t world, int32_t body) {
	World *w = world_of(world);
	if (w == nullptr)
		return 0;
	BodyLockRead lock(w->system.GetBodyLockInterfaceNoLock(), BodyID(uint32(body)));
	return lock.Succeeded() ? 1 : 0;
}

// hj_io_f in: center of mass 0-2, rotation 3-6, scale 7-9. Out: the shape's world transform 0-15 by columns, its world bounds 16-21.
void hj_shape_get_transformed_world(int32_t shape) {
	Shape *s = shape_of(shape);
	if (s == nullptr)
		return;
	TransformedShape transformed(RVec3(io_f[0], io_f[1], io_f[2]), Quat(io_f[3], io_f[4], io_f[5], io_f[6]), s, BodyID());
	transformed.SetShapeScale(Vec3(io_f[7], io_f[8], io_f[9]));
	AABox bounds = transformed.GetWorldSpaceBounds();
	write_mat44(io_f, transformed.GetWorldTransform());
	write_vec3(io_f + 16, bounds.mMin);
	write_vec3(io_f + 19, bounds.mMax);
}

int32_t hj_total_memory(void) {
#ifdef __EMSCRIPTEN__
	return int32_t(__builtin_wasm_memory_size(0) * 65536);
#else
	return 0;
#endif
}

int32_t hj_free_memory(void) {
#ifdef __EMSCRIPTEN__
	struct mallinfo info = mallinfo();
	return int32_t(__builtin_wasm_memory_size(0) * 65536) - int32_t(info.uordblks);
#else
	return 0;
#endif
}

} // extern "C"
