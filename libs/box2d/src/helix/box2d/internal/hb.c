/* Written by tools/gen_box2d.py: a call of numbers alone for each function of Box2D's that helix-box2d has (hb_io.h says how
   its structs, arrays and strings cross), and a trampoline for each callback, calling Haxe. */
#include "hb.h"
#include "hb_io.h"

#include <box2d/box2d.h>
#include <box2d/collision.h>
#include <box2d/math_functions.h>

/* The world being stepped, for a callback Box2D calls without a context (friction, restitution). */
static int32_t hb_stepping;

static void hb_rd_b2AABB(hb_buffer *b, b2AABB *v);
static void hb_wr_b2AABB(hb_buffer *b, const b2AABB *v);
static void hb_rd_b2BodyDef(hb_buffer *b, b2BodyDef *v);
static void hb_wr_b2BodyDef(hb_buffer *b, const b2BodyDef *v);
static void hb_rd_b2BodyEvents(hb_buffer *b, b2BodyEvents *v);
static void hb_wr_b2BodyEvents(hb_buffer *b, const b2BodyEvents *v);
static void hb_rd_b2BodyId(hb_buffer *b, b2BodyId *v);
static void hb_wr_b2BodyId(hb_buffer *b, const b2BodyId *v);
static void hb_rd_b2BodyMoveEvent(hb_buffer *b, b2BodyMoveEvent *v);
static void hb_wr_b2BodyMoveEvent(hb_buffer *b, const b2BodyMoveEvent *v);
static void hb_rd_b2Capacity(hb_buffer *b, b2Capacity *v);
static void hb_wr_b2Capacity(hb_buffer *b, const b2Capacity *v);
static void hb_rd_b2Capsule(hb_buffer *b, b2Capsule *v);
static void hb_wr_b2Capsule(hb_buffer *b, const b2Capsule *v);
static void hb_rd_b2CastOutput(hb_buffer *b, b2CastOutput *v);
static void hb_wr_b2CastOutput(hb_buffer *b, const b2CastOutput *v);
static void hb_rd_b2ChainDef(hb_buffer *b, b2ChainDef *v);
static void hb_wr_b2ChainDef(hb_buffer *b, const b2ChainDef *v);
static void hb_rd_b2ChainId(hb_buffer *b, b2ChainId *v);
static void hb_wr_b2ChainId(hb_buffer *b, const b2ChainId *v);
static void hb_rd_b2ChainSegment(hb_buffer *b, b2ChainSegment *v);
static void hb_wr_b2ChainSegment(hb_buffer *b, const b2ChainSegment *v);
static void hb_rd_b2Circle(hb_buffer *b, b2Circle *v);
static void hb_wr_b2Circle(hb_buffer *b, const b2Circle *v);
static void hb_rd_b2CollisionPlane(hb_buffer *b, b2CollisionPlane *v);
static void hb_wr_b2CollisionPlane(hb_buffer *b, const b2CollisionPlane *v);
static void hb_rd_b2ContactBeginTouchEvent(hb_buffer *b, b2ContactBeginTouchEvent *v);
static void hb_wr_b2ContactBeginTouchEvent(hb_buffer *b, const b2ContactBeginTouchEvent *v);
static void hb_rd_b2ContactData(hb_buffer *b, b2ContactData *v);
static void hb_wr_b2ContactData(hb_buffer *b, const b2ContactData *v);
static void hb_rd_b2ContactEndTouchEvent(hb_buffer *b, b2ContactEndTouchEvent *v);
static void hb_wr_b2ContactEndTouchEvent(hb_buffer *b, const b2ContactEndTouchEvent *v);
static void hb_rd_b2ContactEvents(hb_buffer *b, b2ContactEvents *v);
static void hb_wr_b2ContactEvents(hb_buffer *b, const b2ContactEvents *v);
static void hb_rd_b2ContactHitEvent(hb_buffer *b, b2ContactHitEvent *v);
static void hb_wr_b2ContactHitEvent(hb_buffer *b, const b2ContactHitEvent *v);
static void hb_rd_b2ContactId(hb_buffer *b, b2ContactId *v);
static void hb_wr_b2ContactId(hb_buffer *b, const b2ContactId *v);
static void hb_rd_b2CosSin(hb_buffer *b, b2CosSin *v);
static void hb_wr_b2CosSin(hb_buffer *b, const b2CosSin *v);
static void hb_rd_b2Counters(hb_buffer *b, b2Counters *v);
static void hb_wr_b2Counters(hb_buffer *b, const b2Counters *v);
static void hb_rd_b2DebugDraw(hb_buffer *b, b2DebugDraw *v);
static void hb_wr_b2DebugDraw(hb_buffer *b, const b2DebugDraw *v);
static void hb_rd_b2DistanceInput(hb_buffer *b, b2DistanceInput *v);
static void hb_wr_b2DistanceInput(hb_buffer *b, const b2DistanceInput *v);
static void hb_rd_b2DistanceJointDef(hb_buffer *b, b2DistanceJointDef *v);
static void hb_wr_b2DistanceJointDef(hb_buffer *b, const b2DistanceJointDef *v);
static void hb_rd_b2DistanceOutput(hb_buffer *b, b2DistanceOutput *v);
static void hb_wr_b2DistanceOutput(hb_buffer *b, const b2DistanceOutput *v);
static void hb_rd_b2ExplosionDef(hb_buffer *b, b2ExplosionDef *v);
static void hb_wr_b2ExplosionDef(hb_buffer *b, const b2ExplosionDef *v);
static void hb_rd_b2Filter(hb_buffer *b, b2Filter *v);
static void hb_wr_b2Filter(hb_buffer *b, const b2Filter *v);
static void hb_rd_b2FilterJointDef(hb_buffer *b, b2FilterJointDef *v);
static void hb_wr_b2FilterJointDef(hb_buffer *b, const b2FilterJointDef *v);
static void hb_rd_b2Hull(hb_buffer *b, b2Hull *v);
static void hb_wr_b2Hull(hb_buffer *b, const b2Hull *v);
static void hb_rd_b2JointDef(hb_buffer *b, b2JointDef *v);
static void hb_wr_b2JointDef(hb_buffer *b, const b2JointDef *v);
static void hb_rd_b2JointEvent(hb_buffer *b, b2JointEvent *v);
static void hb_wr_b2JointEvent(hb_buffer *b, const b2JointEvent *v);
static void hb_rd_b2JointEvents(hb_buffer *b, b2JointEvents *v);
static void hb_wr_b2JointEvents(hb_buffer *b, const b2JointEvents *v);
static void hb_rd_b2JointId(hb_buffer *b, b2JointId *v);
static void hb_wr_b2JointId(hb_buffer *b, const b2JointId *v);
static void hb_rd_b2LocalManifold(hb_buffer *b, b2LocalManifold *v);
static void hb_wr_b2LocalManifold(hb_buffer *b, const b2LocalManifold *v);
static void hb_rd_b2LocalManifoldPoint(hb_buffer *b, b2LocalManifoldPoint *v);
static void hb_wr_b2LocalManifoldPoint(hb_buffer *b, const b2LocalManifoldPoint *v);
static void hb_rd_b2Manifold(hb_buffer *b, b2Manifold *v);
static void hb_wr_b2Manifold(hb_buffer *b, const b2Manifold *v);
static void hb_rd_b2ManifoldPoint(hb_buffer *b, b2ManifoldPoint *v);
static void hb_wr_b2ManifoldPoint(hb_buffer *b, const b2ManifoldPoint *v);
static void hb_rd_b2MassData(hb_buffer *b, b2MassData *v);
static void hb_wr_b2MassData(hb_buffer *b, const b2MassData *v);
static void hb_rd_b2Mat22(hb_buffer *b, b2Mat22 *v);
static void hb_wr_b2Mat22(hb_buffer *b, const b2Mat22 *v);
static void hb_rd_b2MotionLocks(hb_buffer *b, b2MotionLocks *v);
static void hb_wr_b2MotionLocks(hb_buffer *b, const b2MotionLocks *v);
static void hb_rd_b2MotorJointDef(hb_buffer *b, b2MotorJointDef *v);
static void hb_wr_b2MotorJointDef(hb_buffer *b, const b2MotorJointDef *v);
static void hb_rd_b2Plane(hb_buffer *b, b2Plane *v);
static void hb_wr_b2Plane(hb_buffer *b, const b2Plane *v);
static void hb_rd_b2PlaneResult(hb_buffer *b, b2PlaneResult *v);
static void hb_wr_b2PlaneResult(hb_buffer *b, const b2PlaneResult *v);
static void hb_rd_b2PlaneSolverResult(hb_buffer *b, b2PlaneSolverResult *v);
static void hb_wr_b2PlaneSolverResult(hb_buffer *b, const b2PlaneSolverResult *v);
static void hb_rd_b2Polygon(hb_buffer *b, b2Polygon *v);
static void hb_wr_b2Polygon(hb_buffer *b, const b2Polygon *v);
static void hb_rd_b2PrismaticJointDef(hb_buffer *b, b2PrismaticJointDef *v);
static void hb_wr_b2PrismaticJointDef(hb_buffer *b, const b2PrismaticJointDef *v);
static void hb_rd_b2Profile(hb_buffer *b, b2Profile *v);
static void hb_wr_b2Profile(hb_buffer *b, const b2Profile *v);
static void hb_rd_b2QueryFilter(hb_buffer *b, b2QueryFilter *v);
static void hb_wr_b2QueryFilter(hb_buffer *b, const b2QueryFilter *v);
static void hb_rd_b2RayCastInput(hb_buffer *b, b2RayCastInput *v);
static void hb_wr_b2RayCastInput(hb_buffer *b, const b2RayCastInput *v);
static void hb_rd_b2RayResult(hb_buffer *b, b2RayResult *v);
static void hb_wr_b2RayResult(hb_buffer *b, const b2RayResult *v);
static void hb_rd_b2RevoluteJointDef(hb_buffer *b, b2RevoluteJointDef *v);
static void hb_wr_b2RevoluteJointDef(hb_buffer *b, const b2RevoluteJointDef *v);
static void hb_rd_b2Rot(hb_buffer *b, b2Rot *v);
static void hb_wr_b2Rot(hb_buffer *b, const b2Rot *v);
static void hb_rd_b2Segment(hb_buffer *b, b2Segment *v);
static void hb_wr_b2Segment(hb_buffer *b, const b2Segment *v);
static void hb_rd_b2SegmentDistanceResult(hb_buffer *b, b2SegmentDistanceResult *v);
static void hb_wr_b2SegmentDistanceResult(hb_buffer *b, const b2SegmentDistanceResult *v);
static void hb_rd_b2SensorBeginTouchEvent(hb_buffer *b, b2SensorBeginTouchEvent *v);
static void hb_wr_b2SensorBeginTouchEvent(hb_buffer *b, const b2SensorBeginTouchEvent *v);
static void hb_rd_b2SensorEndTouchEvent(hb_buffer *b, b2SensorEndTouchEvent *v);
static void hb_wr_b2SensorEndTouchEvent(hb_buffer *b, const b2SensorEndTouchEvent *v);
static void hb_rd_b2SensorEvents(hb_buffer *b, b2SensorEvents *v);
static void hb_wr_b2SensorEvents(hb_buffer *b, const b2SensorEvents *v);
static void hb_rd_b2ShapeCastInput(hb_buffer *b, b2ShapeCastInput *v);
static void hb_wr_b2ShapeCastInput(hb_buffer *b, const b2ShapeCastInput *v);
static void hb_rd_b2ShapeCastPairInput(hb_buffer *b, b2ShapeCastPairInput *v);
static void hb_wr_b2ShapeCastPairInput(hb_buffer *b, const b2ShapeCastPairInput *v);
static void hb_rd_b2ShapeDef(hb_buffer *b, b2ShapeDef *v);
static void hb_wr_b2ShapeDef(hb_buffer *b, const b2ShapeDef *v);
static void hb_rd_b2ShapeId(hb_buffer *b, b2ShapeId *v);
static void hb_wr_b2ShapeId(hb_buffer *b, const b2ShapeId *v);
static void hb_rd_b2ShapeProxy(hb_buffer *b, b2ShapeProxy *v);
static void hb_wr_b2ShapeProxy(hb_buffer *b, const b2ShapeProxy *v);
static void hb_rd_b2Simplex(hb_buffer *b, b2Simplex *v);
static void hb_wr_b2Simplex(hb_buffer *b, const b2Simplex *v);
static void hb_rd_b2SimplexCache(hb_buffer *b, b2SimplexCache *v);
static void hb_wr_b2SimplexCache(hb_buffer *b, const b2SimplexCache *v);
static void hb_rd_b2SimplexVertex(hb_buffer *b, b2SimplexVertex *v);
static void hb_wr_b2SimplexVertex(hb_buffer *b, const b2SimplexVertex *v);
static void hb_rd_b2SurfaceMaterial(hb_buffer *b, b2SurfaceMaterial *v);
static void hb_wr_b2SurfaceMaterial(hb_buffer *b, const b2SurfaceMaterial *v);
static void hb_rd_b2Sweep(hb_buffer *b, b2Sweep *v);
static void hb_wr_b2Sweep(hb_buffer *b, const b2Sweep *v);
static void hb_rd_b2TOIInput(hb_buffer *b, b2TOIInput *v);
static void hb_wr_b2TOIInput(hb_buffer *b, const b2TOIInput *v);
static void hb_rd_b2TOIOutput(hb_buffer *b, b2TOIOutput *v);
static void hb_wr_b2TOIOutput(hb_buffer *b, const b2TOIOutput *v);
static void hb_rd_b2Transform(hb_buffer *b, b2Transform *v);
static void hb_wr_b2Transform(hb_buffer *b, const b2Transform *v);
static void hb_rd_b2TreeStats(hb_buffer *b, b2TreeStats *v);
static void hb_wr_b2TreeStats(hb_buffer *b, const b2TreeStats *v);
static void hb_rd_b2Version(hb_buffer *b, b2Version *v);
static void hb_wr_b2Version(hb_buffer *b, const b2Version *v);
static void hb_rd_b2WeldJointDef(hb_buffer *b, b2WeldJointDef *v);
static void hb_wr_b2WeldJointDef(hb_buffer *b, const b2WeldJointDef *v);
static void hb_rd_b2WheelJointDef(hb_buffer *b, b2WheelJointDef *v);
static void hb_wr_b2WheelJointDef(hb_buffer *b, const b2WheelJointDef *v);
static void hb_rd_b2WorldDef(hb_buffer *b, b2WorldDef *v);
static void hb_wr_b2WorldDef(hb_buffer *b, const b2WorldDef *v);
static void hb_rd_b2WorldId(hb_buffer *b, b2WorldId *v);
static void hb_wr_b2WorldId(hb_buffer *b, const b2WorldId *v);

#ifdef __EMSCRIPTEN__
float hb_cb_b2CastResultCallbackFcn(int32_t, int32_t, int32_t, int32_t, float, float, float, float, float) HB_IMPORT(hb_cb_b2CastResultCallbackFcn);
#else
static float (*hb_cb_b2CastResultCallbackFcn)(int32_t, int32_t, int32_t, int32_t, float, float, float, float, float);
HB_API void hb_set_hb_cb_b2CastResultCallbackFcn(void *f) { hb_cb_b2CastResultCallbackFcn = (float (*)(int32_t, int32_t, int32_t, int32_t, float, float, float, float, float))f; }
#endif
static float hb_tr_b2CastResultCallbackFcn(b2ShapeId shapeId, b2Pos point, b2Vec2 normal, float fraction, void * context) {
	float result = hb_cb_b2CastResultCallbackFcn((int32_t)(intptr_t)context, shapeId.index1, shapeId.world0, shapeId.generation, point.x, point.y, normal.x, normal.y, fraction);
	return result;
}

#ifdef __EMSCRIPTEN__
int32_t hb_cb_b2CustomFilterCallbackFcn(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t) HB_IMPORT(hb_cb_b2CustomFilterCallbackFcn);
#else
static int32_t (*hb_cb_b2CustomFilterCallbackFcn)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2CustomFilterCallbackFcn(void *f) { hb_cb_b2CustomFilterCallbackFcn = (int32_t (*)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t))f; }
#endif
static bool hb_tr_b2CustomFilterCallbackFcn(b2ShapeId shapeIdA, b2ShapeId shapeIdB, void * context) {
	int32_t result = hb_cb_b2CustomFilterCallbackFcn((int32_t)(intptr_t)context, shapeIdA.index1, shapeIdA.world0, shapeIdA.generation, shapeIdB.index1, shapeIdB.world0, shapeIdB.generation);
	return result != 0;
}

#ifdef __EMSCRIPTEN__
float hb_cb_b2FrictionCallbackFcn(int32_t, float, int32_t, int32_t, float, int32_t, int32_t) HB_IMPORT(hb_cb_b2FrictionCallbackFcn);
#else
static float (*hb_cb_b2FrictionCallbackFcn)(int32_t, float, int32_t, int32_t, float, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2FrictionCallbackFcn(void *f) { hb_cb_b2FrictionCallbackFcn = (float (*)(int32_t, float, int32_t, int32_t, float, int32_t, int32_t))f; }
#endif
static float hb_tr_b2FrictionCallbackFcn(float frictionA, uint64_t userMaterialIdA, float frictionB, uint64_t userMaterialIdB) {
	float result = hb_cb_b2FrictionCallbackFcn(hb_stepping, frictionA, (int32_t)(uint32_t)userMaterialIdA, (int32_t)(uint32_t)(userMaterialIdA >> 32), frictionB, (int32_t)(uint32_t)userMaterialIdB, (int32_t)(uint32_t)(userMaterialIdB >> 32));
	return result;
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2LogCallbackFcn(int32_t) HB_IMPORT(hb_cb_b2LogCallbackFcn);
#else
static void (*hb_cb_b2LogCallbackFcn)(int32_t);
HB_API void hb_set_hb_cb_b2LogCallbackFcn(void *f) { hb_cb_b2LogCallbackFcn = (void (*)(int32_t))f; }
#endif
static void hb_tr_b2LogCallbackFcn(const char * message) {
	hb_begin(&hb_back);
	hb_ws(&hb_back, message);
	hb_cb_b2LogCallbackFcn(hb_stepping);
}

#ifdef __EMSCRIPTEN__
int32_t hb_cb_b2OverlapResultCallbackFcn(int32_t, int32_t, int32_t, int32_t) HB_IMPORT(hb_cb_b2OverlapResultCallbackFcn);
#else
static int32_t (*hb_cb_b2OverlapResultCallbackFcn)(int32_t, int32_t, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2OverlapResultCallbackFcn(void *f) { hb_cb_b2OverlapResultCallbackFcn = (int32_t (*)(int32_t, int32_t, int32_t, int32_t))f; }
#endif
static bool hb_tr_b2OverlapResultCallbackFcn(b2ShapeId shapeId, void * context) {
	int32_t result = hb_cb_b2OverlapResultCallbackFcn((int32_t)(intptr_t)context, shapeId.index1, shapeId.world0, shapeId.generation);
	return result != 0;
}

#ifdef __EMSCRIPTEN__
int32_t hb_cb_b2PlaneResultCallbackFcn(int32_t, int32_t, int32_t, int32_t) HB_IMPORT(hb_cb_b2PlaneResultCallbackFcn);
#else
static int32_t (*hb_cb_b2PlaneResultCallbackFcn)(int32_t, int32_t, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2PlaneResultCallbackFcn(void *f) { hb_cb_b2PlaneResultCallbackFcn = (int32_t (*)(int32_t, int32_t, int32_t, int32_t))f; }
#endif
static bool hb_tr_b2PlaneResultCallbackFcn(b2ShapeId shapeId, const b2PlaneResult * plane, void * context) {
	hb_begin(&hb_back);
	hb_wr_b2PlaneResult(&hb_back, plane);
	int32_t result = hb_cb_b2PlaneResultCallbackFcn((int32_t)(intptr_t)context, shapeId.index1, shapeId.world0, shapeId.generation);
	return result != 0;
}

#ifdef __EMSCRIPTEN__
int32_t hb_cb_b2PreContinuousCallbackFcn(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, float, float, float, float) HB_IMPORT(hb_cb_b2PreContinuousCallbackFcn);
#else
static int32_t (*hb_cb_b2PreContinuousCallbackFcn)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, float, float, float, float);
HB_API void hb_set_hb_cb_b2PreContinuousCallbackFcn(void *f) { hb_cb_b2PreContinuousCallbackFcn = (int32_t (*)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, float, float, float, float))f; }
#endif
static bool hb_tr_b2PreContinuousCallbackFcn(b2ShapeId shapeIdA, b2ShapeId shapeIdB, b2Pos point, b2Vec2 normal, void * context) {
	int32_t result = hb_cb_b2PreContinuousCallbackFcn((int32_t)(intptr_t)context, shapeIdA.index1, shapeIdA.world0, shapeIdA.generation, shapeIdB.index1, shapeIdB.world0, shapeIdB.generation, point.x, point.y, normal.x, normal.y);
	return result != 0;
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2PreSolveCallbackFcn(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t) HB_IMPORT(hb_cb_b2PreSolveCallbackFcn);
#else
static void (*hb_cb_b2PreSolveCallbackFcn)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2PreSolveCallbackFcn(void *f) { hb_cb_b2PreSolveCallbackFcn = (void (*)(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t))f; }
#endif
static void hb_tr_b2PreSolveCallbackFcn(b2ShapeId shapeIdA, b2ShapeId shapeIdB, b2Manifold * manifold, void * context) {
	hb_begin(&hb_back);
	hb_wr_b2Manifold(&hb_back, manifold);
	hb_cb_b2PreSolveCallbackFcn((int32_t)(intptr_t)context, shapeIdA.index1, shapeIdA.world0, shapeIdA.generation, shapeIdB.index1, shapeIdB.world0, shapeIdB.generation);
	hb_begin(&hb_back);
	hb_rd_b2Manifold(&hb_back, manifold);
}

#ifdef __EMSCRIPTEN__
float hb_cb_b2RestitutionCallbackFcn(int32_t, float, int32_t, int32_t, float, int32_t, int32_t) HB_IMPORT(hb_cb_b2RestitutionCallbackFcn);
#else
static float (*hb_cb_b2RestitutionCallbackFcn)(int32_t, float, int32_t, int32_t, float, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2RestitutionCallbackFcn(void *f) { hb_cb_b2RestitutionCallbackFcn = (float (*)(int32_t, float, int32_t, int32_t, float, int32_t, int32_t))f; }
#endif
static float hb_tr_b2RestitutionCallbackFcn(float restitutionA, uint64_t userMaterialIdA, float restitutionB, uint64_t userMaterialIdB) {
	float result = hb_cb_b2RestitutionCallbackFcn(hb_stepping, restitutionA, (int32_t)(uint32_t)userMaterialIdA, (int32_t)(uint32_t)(userMaterialIdA >> 32), restitutionB, (int32_t)(uint32_t)userMaterialIdB, (int32_t)(uint32_t)(userMaterialIdB >> 32));
	return result;
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawPolygonFcn(int32_t, float, float, float, float, int32_t, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawPolygonFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawPolygonFcn)(int32_t, float, float, float, float, int32_t, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawPolygonFcn(void *f) { hb_cb_b2DebugDraw_DrawPolygonFcn = (void (*)(int32_t, float, float, float, float, int32_t, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawPolygonFcn(b2WorldTransform transform, const b2Vec2 * vertices, int vertexCount, b2HexColor color, void * context) {
	hb_begin(&hb_back);
	for (int k = 0; k < vertexCount; k++) {
		hb_wf(&hb_back, vertices[k].x);
		hb_wf(&hb_back, vertices[k].y);
	}
	hb_cb_b2DebugDraw_DrawPolygonFcn((int32_t)(intptr_t)context, transform.p.x, transform.p.y, transform.q.c, transform.q.s, vertexCount, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawSolidPolygonFcn(int32_t, float, float, float, float, int32_t, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawSolidPolygonFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawSolidPolygonFcn)(int32_t, float, float, float, float, int32_t, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawSolidPolygonFcn(void *f) { hb_cb_b2DebugDraw_DrawSolidPolygonFcn = (void (*)(int32_t, float, float, float, float, int32_t, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawSolidPolygonFcn(b2WorldTransform transform, const b2Vec2 * vertices, int vertexCount, float radius, b2HexColor color, void * context) {
	hb_begin(&hb_back);
	for (int k = 0; k < vertexCount; k++) {
		hb_wf(&hb_back, vertices[k].x);
		hb_wf(&hb_back, vertices[k].y);
	}
	hb_cb_b2DebugDraw_DrawSolidPolygonFcn((int32_t)(intptr_t)context, transform.p.x, transform.p.y, transform.q.c, transform.q.s, vertexCount, radius, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawCircleFcn(int32_t, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawCircleFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawCircleFcn)(int32_t, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawCircleFcn(void *f) { hb_cb_b2DebugDraw_DrawCircleFcn = (void (*)(int32_t, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawCircleFcn(b2Pos center, float radius, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawCircleFcn((int32_t)(intptr_t)context, center.x, center.y, radius, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawSolidCircleFcn(int32_t, float, float, float, float, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawSolidCircleFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawSolidCircleFcn)(int32_t, float, float, float, float, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawSolidCircleFcn(void *f) { hb_cb_b2DebugDraw_DrawSolidCircleFcn = (void (*)(int32_t, float, float, float, float, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawSolidCircleFcn(b2WorldTransform transform, b2Vec2 center, float radius, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawSolidCircleFcn((int32_t)(intptr_t)context, transform.p.x, transform.p.y, transform.q.c, transform.q.s, center.x, center.y, radius, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawSolidCapsuleFcn(int32_t, float, float, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawSolidCapsuleFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawSolidCapsuleFcn)(int32_t, float, float, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawSolidCapsuleFcn(void *f) { hb_cb_b2DebugDraw_DrawSolidCapsuleFcn = (void (*)(int32_t, float, float, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawSolidCapsuleFcn(b2Pos p1, b2Pos p2, float radius, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawSolidCapsuleFcn((int32_t)(intptr_t)context, p1.x, p1.y, p2.x, p2.y, radius, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawLineFcn(int32_t, float, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawLineFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawLineFcn)(int32_t, float, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawLineFcn(void *f) { hb_cb_b2DebugDraw_DrawLineFcn = (void (*)(int32_t, float, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawLineFcn(b2Pos p1, b2Pos p2, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawLineFcn((int32_t)(intptr_t)context, p1.x, p1.y, p2.x, p2.y, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawTransformFcn(int32_t, float, float, float, float) HB_IMPORT(hb_cb_b2DebugDraw_DrawTransformFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawTransformFcn)(int32_t, float, float, float, float);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawTransformFcn(void *f) { hb_cb_b2DebugDraw_DrawTransformFcn = (void (*)(int32_t, float, float, float, float))f; }
#endif
static void hb_tr_b2DebugDraw_DrawTransformFcn(b2WorldTransform transform, void * context) {
	hb_cb_b2DebugDraw_DrawTransformFcn((int32_t)(intptr_t)context, transform.p.x, transform.p.y, transform.q.c, transform.q.s);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawPointFcn(int32_t, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawPointFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawPointFcn)(int32_t, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawPointFcn(void *f) { hb_cb_b2DebugDraw_DrawPointFcn = (void (*)(int32_t, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawPointFcn(b2Pos p, float size, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawPointFcn((int32_t)(intptr_t)context, p.x, p.y, size, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawStringFcn(int32_t, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawStringFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawStringFcn)(int32_t, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawStringFcn(void *f) { hb_cb_b2DebugDraw_DrawStringFcn = (void (*)(int32_t, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawStringFcn(b2Pos p, const char * s, b2HexColor color, void * context) {
	hb_begin(&hb_back);
	hb_ws(&hb_back, s);
	hb_cb_b2DebugDraw_DrawStringFcn((int32_t)(intptr_t)context, p.x, p.y, color);
}

#ifdef __EMSCRIPTEN__
void hb_cb_b2DebugDraw_DrawBoundsFcn(int32_t, float, float, float, float, int32_t) HB_IMPORT(hb_cb_b2DebugDraw_DrawBoundsFcn);
#else
static void (*hb_cb_b2DebugDraw_DrawBoundsFcn)(int32_t, float, float, float, float, int32_t);
HB_API void hb_set_hb_cb_b2DebugDraw_DrawBoundsFcn(void *f) { hb_cb_b2DebugDraw_DrawBoundsFcn = (void (*)(int32_t, float, float, float, float, int32_t))f; }
#endif
static void hb_tr_b2DebugDraw_DrawBoundsFcn(b2AABB aabb, b2HexColor color, void * context) {
	hb_cb_b2DebugDraw_DrawBoundsFcn((int32_t)(intptr_t)context, aabb.lowerBound.x, aabb.lowerBound.y, aabb.upperBound.x, aabb.upperBound.y, color);
}

static void hb_rd_b2AABB(hb_buffer *b, b2AABB *v) {
	v->lowerBound.x = hb_rf(b);
	v->lowerBound.y = hb_rf(b);
	v->upperBound.x = hb_rf(b);
	v->upperBound.y = hb_rf(b);
}

static void hb_wr_b2AABB(hb_buffer *b, const b2AABB *v) {
	hb_wf(b, v->lowerBound.x);
	hb_wf(b, v->lowerBound.y);
	hb_wf(b, v->upperBound.x);
	hb_wf(b, v->upperBound.y);
}

static void hb_rd_b2BodyDef(hb_buffer *b, b2BodyDef *v) {
	*v = b2DefaultBodyDef();
	v->type = (b2BodyType)hb_ri(b);
	v->position.x = hb_rf(b);
	v->position.y = hb_rf(b);
	hb_rd_b2Rot(b, &v->rotation);
	v->linearVelocity.x = hb_rf(b);
	v->linearVelocity.y = hb_rf(b);
	v->angularVelocity = hb_rf(b);
	v->linearDamping = hb_rf(b);
	v->angularDamping = hb_rf(b);
	v->gravityScale = hb_rf(b);
	v->sleepThreshold = hb_rf(b);
	v->safetyFactor = hb_rf(b);
	v->name = hb_rs(b, 20);
	hb_ri(b);
	v->userData = NULL;
	hb_rd_b2MotionLocks(b, &v->motionLocks);
	v->enableSleep = hb_ri(b) != 0;
	v->isAwake = hb_ri(b) != 0;
	v->isBullet = hb_ri(b) != 0;
	v->isEnabled = hb_ri(b) != 0;
	v->allowFastRotation = hb_ri(b) != 0;
	v->enableContactRecycling = hb_ri(b) != 0;
}

static void hb_wr_b2BodyDef(hb_buffer *b, const b2BodyDef *v) {
	hb_wi(b, (int32_t)v->type);
	hb_wf(b, v->position.x);
	hb_wf(b, v->position.y);
	hb_wr_b2Rot(b, &v->rotation);
	hb_wf(b, v->linearVelocity.x);
	hb_wf(b, v->linearVelocity.y);
	hb_wf(b, v->angularVelocity);
	hb_wf(b, v->linearDamping);
	hb_wf(b, v->angularDamping);
	hb_wf(b, v->gravityScale);
	hb_wf(b, v->sleepThreshold);
	hb_wf(b, v->safetyFactor);
	hb_ws(b, v->name);
	hb_wi(b, 0);
	hb_wr_b2MotionLocks(b, &v->motionLocks);
	hb_wi(b, v->enableSleep ? 1 : 0);
	hb_wi(b, v->isAwake ? 1 : 0);
	hb_wi(b, v->isBullet ? 1 : 0);
	hb_wi(b, v->isEnabled ? 1 : 0);
	hb_wi(b, v->allowFastRotation ? 1 : 0);
	hb_wi(b, v->enableContactRecycling ? 1 : 0);
}

static void hb_rd_b2BodyEvents(hb_buffer *b, b2BodyEvents *v) {
	{
		int32_t count = hb_ri(b);
		b2BodyMoveEvent *a = (b2BodyMoveEvent *)hb_scratch(24, (size_t)(count > 0 ? count : 1) * sizeof(b2BodyMoveEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2BodyMoveEvent(b, &a[k]);
		}
		v->moveEvents = a;
	}
	v->moveCount = (int)hb_ri(b);
}

static void hb_wr_b2BodyEvents(hb_buffer *b, const b2BodyEvents *v) {
	hb_wi(b, v->moveCount);
	for (int32_t k = 0; k < v->moveCount; k++) {
		hb_wr_b2BodyMoveEvent(b, &v->moveEvents[k]);
	}
	hb_wi(b, (int32_t)v->moveCount);
}

static void hb_rd_b2BodyId(hb_buffer *b, b2BodyId *v) {
	v->index1 = (int32_t)hb_ri(b);
	v->world0 = (uint16_t)hb_ri(b);
	v->generation = (uint16_t)hb_ri(b);
}

static void hb_wr_b2BodyId(hb_buffer *b, const b2BodyId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->world0);
	hb_wi(b, (int32_t)v->generation);
}

static void hb_rd_b2BodyMoveEvent(hb_buffer *b, b2BodyMoveEvent *v) {
	hb_ri(b);
	v->userData = NULL;
	hb_rd_b2Transform(b, &v->transform);
	hb_rd_b2BodyId(b, &v->bodyId);
	v->fellAsleep = hb_ri(b) != 0;
}

static void hb_wr_b2BodyMoveEvent(hb_buffer *b, const b2BodyMoveEvent *v) {
	hb_wi(b, 0);
	hb_wr_b2Transform(b, &v->transform);
	hb_wr_b2BodyId(b, &v->bodyId);
	hb_wi(b, v->fellAsleep ? 1 : 0);
}

static void hb_rd_b2Capacity(hb_buffer *b, b2Capacity *v) {
	v->staticShapeCount = (int)hb_ri(b);
	v->dynamicShapeCount = (int)hb_ri(b);
	v->staticBodyCount = (int)hb_ri(b);
	v->dynamicBodyCount = (int)hb_ri(b);
	v->contactCount = (int)hb_ri(b);
	v->arenaByteCount = (int)hb_ri(b);
}

static void hb_wr_b2Capacity(hb_buffer *b, const b2Capacity *v) {
	hb_wi(b, (int32_t)v->staticShapeCount);
	hb_wi(b, (int32_t)v->dynamicShapeCount);
	hb_wi(b, (int32_t)v->staticBodyCount);
	hb_wi(b, (int32_t)v->dynamicBodyCount);
	hb_wi(b, (int32_t)v->contactCount);
	hb_wi(b, (int32_t)v->arenaByteCount);
}

static void hb_rd_b2Capsule(hb_buffer *b, b2Capsule *v) {
	v->center1.x = hb_rf(b);
	v->center1.y = hb_rf(b);
	v->center2.x = hb_rf(b);
	v->center2.y = hb_rf(b);
	v->radius = hb_rf(b);
}

static void hb_wr_b2Capsule(hb_buffer *b, const b2Capsule *v) {
	hb_wf(b, v->center1.x);
	hb_wf(b, v->center1.y);
	hb_wf(b, v->center2.x);
	hb_wf(b, v->center2.y);
	hb_wf(b, v->radius);
}

static void hb_rd_b2CastOutput(hb_buffer *b, b2CastOutput *v) {
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->fraction = hb_rf(b);
	v->iterations = (int)hb_ri(b);
	v->hit = hb_ri(b) != 0;
}

static void hb_wr_b2CastOutput(hb_buffer *b, const b2CastOutput *v) {
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wf(b, v->fraction);
	hb_wi(b, (int32_t)v->iterations);
	hb_wi(b, v->hit ? 1 : 0);
}

static void hb_rd_b2ChainDef(hb_buffer *b, b2ChainDef *v) {
	*v = b2DefaultChainDef();
	hb_ri(b);
	v->userData = NULL;
	{
		int32_t count = hb_ri(b);
		b2Vec2 *a = (b2Vec2 *)hb_scratch(24, (size_t)(count > 0 ? count : 1) * sizeof(b2Vec2));
		for (int32_t k = 0; k < count; k++) {
			a[k].x = hb_rf(b);
			a[k].y = hb_rf(b);
		}
		v->points = a;
	}
	v->pointCount = (int)hb_ri(b);
	v->ghost1.x = hb_rf(b);
	v->ghost1.y = hb_rf(b);
	v->ghost2.x = hb_rf(b);
	v->ghost2.y = hb_rf(b);
	{
		int32_t count = hb_ri(b);
		b2SurfaceMaterial *a = (b2SurfaceMaterial *)hb_scratch(25, (size_t)(count > 0 ? count : 1) * sizeof(b2SurfaceMaterial));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2SurfaceMaterial(b, &a[k]);
		}
		v->materials = a;
	}
	v->materialCount = (int)hb_ri(b);
	hb_rd_b2Filter(b, &v->filter);
	v->isLoop = hb_ri(b) != 0;
	v->enableSensorEvents = hb_ri(b) != 0;
}

static void hb_wr_b2ChainDef(hb_buffer *b, const b2ChainDef *v) {
	hb_wi(b, 0);
	hb_wi(b, v->pointCount);
	for (int32_t k = 0; k < v->pointCount; k++) {
		hb_wf(b, v->points[k].x);
		hb_wf(b, v->points[k].y);
	}
	hb_wi(b, (int32_t)v->pointCount);
	hb_wf(b, v->ghost1.x);
	hb_wf(b, v->ghost1.y);
	hb_wf(b, v->ghost2.x);
	hb_wf(b, v->ghost2.y);
	hb_wi(b, v->materialCount);
	for (int32_t k = 0; k < v->materialCount; k++) {
		hb_wr_b2SurfaceMaterial(b, &v->materials[k]);
	}
	hb_wi(b, (int32_t)v->materialCount);
	hb_wr_b2Filter(b, &v->filter);
	hb_wi(b, v->isLoop ? 1 : 0);
	hb_wi(b, v->enableSensorEvents ? 1 : 0);
}

static void hb_rd_b2ChainId(hb_buffer *b, b2ChainId *v) {
	v->index1 = (int32_t)hb_ri(b);
	v->world0 = (uint16_t)hb_ri(b);
	v->generation = (uint16_t)hb_ri(b);
}

static void hb_wr_b2ChainId(hb_buffer *b, const b2ChainId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->world0);
	hb_wi(b, (int32_t)v->generation);
}

static void hb_rd_b2ChainSegment(hb_buffer *b, b2ChainSegment *v) {
	v->ghost1.x = hb_rf(b);
	v->ghost1.y = hb_rf(b);
	hb_rd_b2Segment(b, &v->segment);
	v->ghost2.x = hb_rf(b);
	v->ghost2.y = hb_rf(b);
	v->chainId = (int)hb_ri(b);
}

static void hb_wr_b2ChainSegment(hb_buffer *b, const b2ChainSegment *v) {
	hb_wf(b, v->ghost1.x);
	hb_wf(b, v->ghost1.y);
	hb_wr_b2Segment(b, &v->segment);
	hb_wf(b, v->ghost2.x);
	hb_wf(b, v->ghost2.y);
	hb_wi(b, (int32_t)v->chainId);
}

static void hb_rd_b2Circle(hb_buffer *b, b2Circle *v) {
	v->center.x = hb_rf(b);
	v->center.y = hb_rf(b);
	v->radius = hb_rf(b);
}

static void hb_wr_b2Circle(hb_buffer *b, const b2Circle *v) {
	hb_wf(b, v->center.x);
	hb_wf(b, v->center.y);
	hb_wf(b, v->radius);
}

static void hb_rd_b2CollisionPlane(hb_buffer *b, b2CollisionPlane *v) {
	hb_rd_b2Plane(b, &v->plane);
	v->pushLimit = hb_rf(b);
	v->push = hb_rf(b);
	v->clipVelocity = hb_ri(b) != 0;
}

static void hb_wr_b2CollisionPlane(hb_buffer *b, const b2CollisionPlane *v) {
	hb_wr_b2Plane(b, &v->plane);
	hb_wf(b, v->pushLimit);
	hb_wf(b, v->push);
	hb_wi(b, v->clipVelocity ? 1 : 0);
}

static void hb_rd_b2ContactBeginTouchEvent(hb_buffer *b, b2ContactBeginTouchEvent *v) {
	hb_rd_b2ShapeId(b, &v->shapeIdA);
	hb_rd_b2ShapeId(b, &v->shapeIdB);
	hb_rd_b2ContactId(b, &v->contactId);
}

static void hb_wr_b2ContactBeginTouchEvent(hb_buffer *b, const b2ContactBeginTouchEvent *v) {
	hb_wr_b2ShapeId(b, &v->shapeIdA);
	hb_wr_b2ShapeId(b, &v->shapeIdB);
	hb_wr_b2ContactId(b, &v->contactId);
}

static void hb_rd_b2ContactData(hb_buffer *b, b2ContactData *v) {
	hb_rd_b2ContactId(b, &v->contactId);
	hb_rd_b2ShapeId(b, &v->shapeIdA);
	hb_rd_b2ShapeId(b, &v->shapeIdB);
	hb_rd_b2Manifold(b, &v->manifold);
}

static void hb_wr_b2ContactData(hb_buffer *b, const b2ContactData *v) {
	hb_wr_b2ContactId(b, &v->contactId);
	hb_wr_b2ShapeId(b, &v->shapeIdA);
	hb_wr_b2ShapeId(b, &v->shapeIdB);
	hb_wr_b2Manifold(b, &v->manifold);
}

static void hb_rd_b2ContactEndTouchEvent(hb_buffer *b, b2ContactEndTouchEvent *v) {
	hb_rd_b2ShapeId(b, &v->shapeIdA);
	hb_rd_b2ShapeId(b, &v->shapeIdB);
	hb_rd_b2ContactId(b, &v->contactId);
}

static void hb_wr_b2ContactEndTouchEvent(hb_buffer *b, const b2ContactEndTouchEvent *v) {
	hb_wr_b2ShapeId(b, &v->shapeIdA);
	hb_wr_b2ShapeId(b, &v->shapeIdB);
	hb_wr_b2ContactId(b, &v->contactId);
}

static void hb_rd_b2ContactEvents(hb_buffer *b, b2ContactEvents *v) {
	{
		int32_t count = hb_ri(b);
		b2ContactBeginTouchEvent *a = (b2ContactBeginTouchEvent *)hb_scratch(24, (size_t)(count > 0 ? count : 1) * sizeof(b2ContactBeginTouchEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2ContactBeginTouchEvent(b, &a[k]);
		}
		v->beginEvents = a;
	}
	{
		int32_t count = hb_ri(b);
		b2ContactEndTouchEvent *a = (b2ContactEndTouchEvent *)hb_scratch(25, (size_t)(count > 0 ? count : 1) * sizeof(b2ContactEndTouchEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2ContactEndTouchEvent(b, &a[k]);
		}
		v->endEvents = a;
	}
	{
		int32_t count = hb_ri(b);
		b2ContactHitEvent *a = (b2ContactHitEvent *)hb_scratch(26, (size_t)(count > 0 ? count : 1) * sizeof(b2ContactHitEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2ContactHitEvent(b, &a[k]);
		}
		v->hitEvents = a;
	}
	v->beginCount = (int)hb_ri(b);
	v->endCount = (int)hb_ri(b);
	v->hitCount = (int)hb_ri(b);
}

static void hb_wr_b2ContactEvents(hb_buffer *b, const b2ContactEvents *v) {
	hb_wi(b, v->beginCount);
	for (int32_t k = 0; k < v->beginCount; k++) {
		hb_wr_b2ContactBeginTouchEvent(b, &v->beginEvents[k]);
	}
	hb_wi(b, v->endCount);
	for (int32_t k = 0; k < v->endCount; k++) {
		hb_wr_b2ContactEndTouchEvent(b, &v->endEvents[k]);
	}
	hb_wi(b, v->hitCount);
	for (int32_t k = 0; k < v->hitCount; k++) {
		hb_wr_b2ContactHitEvent(b, &v->hitEvents[k]);
	}
	hb_wi(b, (int32_t)v->beginCount);
	hb_wi(b, (int32_t)v->endCount);
	hb_wi(b, (int32_t)v->hitCount);
}

static void hb_rd_b2ContactHitEvent(hb_buffer *b, b2ContactHitEvent *v) {
	hb_rd_b2ShapeId(b, &v->shapeIdA);
	hb_rd_b2ShapeId(b, &v->shapeIdB);
	hb_rd_b2ContactId(b, &v->contactId);
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->approachSpeed = hb_rf(b);
}

static void hb_wr_b2ContactHitEvent(hb_buffer *b, const b2ContactHitEvent *v) {
	hb_wr_b2ShapeId(b, &v->shapeIdA);
	hb_wr_b2ShapeId(b, &v->shapeIdB);
	hb_wr_b2ContactId(b, &v->contactId);
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->approachSpeed);
}

static void hb_rd_b2ContactId(hb_buffer *b, b2ContactId *v) {
	v->index1 = (int32_t)hb_ri(b);
	v->world0 = (uint16_t)hb_ri(b);
	v->padding = (int16_t)hb_ri(b);
	v->generation = (uint32_t)hb_ri(b);
}

static void hb_wr_b2ContactId(hb_buffer *b, const b2ContactId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->world0);
	hb_wi(b, (int32_t)v->padding);
	hb_wi(b, (int32_t)v->generation);
}

static void hb_rd_b2CosSin(hb_buffer *b, b2CosSin *v) {
	v->cosine = hb_rf(b);
	v->sine = hb_rf(b);
}

static void hb_wr_b2CosSin(hb_buffer *b, const b2CosSin *v) {
	hb_wf(b, v->cosine);
	hb_wf(b, v->sine);
}

static void hb_rd_b2Counters(hb_buffer *b, b2Counters *v) {
	v->byteCount = (size_t)hb_ri(b);
	v->bodyCount = (int)hb_ri(b);
	v->shapeCount = (int)hb_ri(b);
	v->contactCount = (int)hb_ri(b);
	v->jointCount = (int)hb_ri(b);
	v->islandCount = (int)hb_ri(b);
	v->stackUsed = (int)hb_ri(b);
	v->staticTreeHeight = (int)hb_ri(b);
	v->treeHeight = (int)hb_ri(b);
	v->taskCount = (int)hb_ri(b);
	for (int k = 0; k < 24; k++) {
		v->colorCounts[k] = (int)hb_ri(b);
	}
	v->awakeContactCount = (int)hb_ri(b);
	v->recycledContactCount = (int)hb_ri(b);
}

static void hb_wr_b2Counters(hb_buffer *b, const b2Counters *v) {
	hb_wi(b, (int32_t)v->byteCount);
	hb_wi(b, (int32_t)v->bodyCount);
	hb_wi(b, (int32_t)v->shapeCount);
	hb_wi(b, (int32_t)v->contactCount);
	hb_wi(b, (int32_t)v->jointCount);
	hb_wi(b, (int32_t)v->islandCount);
	hb_wi(b, (int32_t)v->stackUsed);
	hb_wi(b, (int32_t)v->staticTreeHeight);
	hb_wi(b, (int32_t)v->treeHeight);
	hb_wi(b, (int32_t)v->taskCount);
	for (int k = 0; k < 24; k++) {
		hb_wi(b, (int32_t)v->colorCounts[k]);
	}
	hb_wi(b, (int32_t)v->awakeContactCount);
	hb_wi(b, (int32_t)v->recycledContactCount);
}

static void hb_rd_b2DebugDraw(hb_buffer *b, b2DebugDraw *v) {
	*v = b2DefaultDebugDraw();
	if (hb_ri(b))
		v->DrawPolygonFcn = hb_tr_b2DebugDraw_DrawPolygonFcn;
	if (hb_ri(b))
		v->DrawSolidPolygonFcn = hb_tr_b2DebugDraw_DrawSolidPolygonFcn;
	if (hb_ri(b))
		v->DrawCircleFcn = hb_tr_b2DebugDraw_DrawCircleFcn;
	if (hb_ri(b))
		v->DrawSolidCircleFcn = hb_tr_b2DebugDraw_DrawSolidCircleFcn;
	if (hb_ri(b))
		v->DrawSolidCapsuleFcn = hb_tr_b2DebugDraw_DrawSolidCapsuleFcn;
	if (hb_ri(b))
		v->DrawLineFcn = hb_tr_b2DebugDraw_DrawLineFcn;
	if (hb_ri(b))
		v->DrawTransformFcn = hb_tr_b2DebugDraw_DrawTransformFcn;
	if (hb_ri(b))
		v->DrawPointFcn = hb_tr_b2DebugDraw_DrawPointFcn;
	if (hb_ri(b))
		v->DrawStringFcn = hb_tr_b2DebugDraw_DrawStringFcn;
	if (hb_ri(b))
		v->DrawBoundsFcn = hb_tr_b2DebugDraw_DrawBoundsFcn;
	hb_rd_b2AABB(b, &v->drawingBounds);
	v->forceScale = hb_rf(b);
	v->jointScale = hb_rf(b);
	v->drawContacts = hb_ri(b) != 0;
	v->drawAnchorA = hb_ri(b) != 0;
	v->drawShapes = hb_ri(b) != 0;
	v->drawChainNormals = hb_ri(b) != 0;
	v->drawJoints = hb_ri(b) != 0;
	v->drawJointExtras = hb_ri(b) != 0;
	v->drawBounds = hb_ri(b) != 0;
	v->drawMass = hb_ri(b) != 0;
	v->drawBodyNames = hb_ri(b) != 0;
	v->drawGraphColors = hb_ri(b) != 0;
	v->drawContactFeatures = hb_ri(b) != 0;
	v->drawContactNormals = hb_ri(b) != 0;
	v->drawContactForces = hb_ri(b) != 0;
	v->drawFrictionForces = hb_ri(b) != 0;
	v->drawIslands = hb_ri(b) != 0;
	hb_ri(b);
	v->context = NULL;
}

static void hb_wr_b2DebugDraw(hb_buffer *b, const b2DebugDraw *v) {
	hb_wi(b, v->DrawPolygonFcn != NULL);
	hb_wi(b, v->DrawSolidPolygonFcn != NULL);
	hb_wi(b, v->DrawCircleFcn != NULL);
	hb_wi(b, v->DrawSolidCircleFcn != NULL);
	hb_wi(b, v->DrawSolidCapsuleFcn != NULL);
	hb_wi(b, v->DrawLineFcn != NULL);
	hb_wi(b, v->DrawTransformFcn != NULL);
	hb_wi(b, v->DrawPointFcn != NULL);
	hb_wi(b, v->DrawStringFcn != NULL);
	hb_wi(b, v->DrawBoundsFcn != NULL);
	hb_wr_b2AABB(b, &v->drawingBounds);
	hb_wf(b, v->forceScale);
	hb_wf(b, v->jointScale);
	hb_wi(b, v->drawContacts ? 1 : 0);
	hb_wi(b, v->drawAnchorA ? 1 : 0);
	hb_wi(b, v->drawShapes ? 1 : 0);
	hb_wi(b, v->drawChainNormals ? 1 : 0);
	hb_wi(b, v->drawJoints ? 1 : 0);
	hb_wi(b, v->drawJointExtras ? 1 : 0);
	hb_wi(b, v->drawBounds ? 1 : 0);
	hb_wi(b, v->drawMass ? 1 : 0);
	hb_wi(b, v->drawBodyNames ? 1 : 0);
	hb_wi(b, v->drawGraphColors ? 1 : 0);
	hb_wi(b, v->drawContactFeatures ? 1 : 0);
	hb_wi(b, v->drawContactNormals ? 1 : 0);
	hb_wi(b, v->drawContactForces ? 1 : 0);
	hb_wi(b, v->drawFrictionForces ? 1 : 0);
	hb_wi(b, v->drawIslands ? 1 : 0);
	hb_wi(b, 0);
}

static void hb_rd_b2DistanceInput(hb_buffer *b, b2DistanceInput *v) {
	hb_rd_b2ShapeProxy(b, &v->proxyA);
	hb_rd_b2ShapeProxy(b, &v->proxyB);
	hb_rd_b2Transform(b, &v->transform);
	v->useRadii = hb_ri(b) != 0;
}

static void hb_wr_b2DistanceInput(hb_buffer *b, const b2DistanceInput *v) {
	hb_wr_b2ShapeProxy(b, &v->proxyA);
	hb_wr_b2ShapeProxy(b, &v->proxyB);
	hb_wr_b2Transform(b, &v->transform);
	hb_wi(b, v->useRadii ? 1 : 0);
}

static void hb_rd_b2DistanceJointDef(hb_buffer *b, b2DistanceJointDef *v) {
	*v = b2DefaultDistanceJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->length = hb_rf(b);
	v->enableSpring = hb_ri(b) != 0;
	v->lowerSpringForce = hb_rf(b);
	v->upperSpringForce = hb_rf(b);
	v->hertz = hb_rf(b);
	v->dampingRatio = hb_rf(b);
	v->enableLimit = hb_ri(b) != 0;
	v->minLength = hb_rf(b);
	v->maxLength = hb_rf(b);
	v->enableMotor = hb_ri(b) != 0;
	v->maxMotorForce = hb_rf(b);
	v->motorSpeed = hb_rf(b);
}

static void hb_wr_b2DistanceJointDef(hb_buffer *b, const b2DistanceJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wf(b, v->length);
	hb_wi(b, v->enableSpring ? 1 : 0);
	hb_wf(b, v->lowerSpringForce);
	hb_wf(b, v->upperSpringForce);
	hb_wf(b, v->hertz);
	hb_wf(b, v->dampingRatio);
	hb_wi(b, v->enableLimit ? 1 : 0);
	hb_wf(b, v->minLength);
	hb_wf(b, v->maxLength);
	hb_wi(b, v->enableMotor ? 1 : 0);
	hb_wf(b, v->maxMotorForce);
	hb_wf(b, v->motorSpeed);
}

static void hb_rd_b2DistanceOutput(hb_buffer *b, b2DistanceOutput *v) {
	v->pointA.x = hb_rf(b);
	v->pointA.y = hb_rf(b);
	v->pointB.x = hb_rf(b);
	v->pointB.y = hb_rf(b);
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->distance = hb_rf(b);
	v->iterations = (int)hb_ri(b);
	v->simplexCount = (int)hb_ri(b);
}

static void hb_wr_b2DistanceOutput(hb_buffer *b, const b2DistanceOutput *v) {
	hb_wf(b, v->pointA.x);
	hb_wf(b, v->pointA.y);
	hb_wf(b, v->pointB.x);
	hb_wf(b, v->pointB.y);
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->distance);
	hb_wi(b, (int32_t)v->iterations);
	hb_wi(b, (int32_t)v->simplexCount);
}

static void hb_rd_b2ExplosionDef(hb_buffer *b, b2ExplosionDef *v) {
	*v = b2DefaultExplosionDef();
	v->maskBits = hb_rl(b);
	v->position.x = hb_rf(b);
	v->position.y = hb_rf(b);
	v->radius = hb_rf(b);
	v->falloff = hb_rf(b);
	v->impulsePerLength = hb_rf(b);
}

static void hb_wr_b2ExplosionDef(hb_buffer *b, const b2ExplosionDef *v) {
	hb_wl(b, v->maskBits);
	hb_wf(b, v->position.x);
	hb_wf(b, v->position.y);
	hb_wf(b, v->radius);
	hb_wf(b, v->falloff);
	hb_wf(b, v->impulsePerLength);
}

static void hb_rd_b2Filter(hb_buffer *b, b2Filter *v) {
	*v = b2DefaultFilter();
	v->categoryBits = hb_rl(b);
	v->maskBits = hb_rl(b);
	v->groupIndex = (int)hb_ri(b);
}

static void hb_wr_b2Filter(hb_buffer *b, const b2Filter *v) {
	hb_wl(b, v->categoryBits);
	hb_wl(b, v->maskBits);
	hb_wi(b, (int32_t)v->groupIndex);
}

static void hb_rd_b2FilterJointDef(hb_buffer *b, b2FilterJointDef *v) {
	*v = b2DefaultFilterJointDef();
	hb_rd_b2JointDef(b, &v->base);
}

static void hb_wr_b2FilterJointDef(hb_buffer *b, const b2FilterJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
}

static void hb_rd_b2Hull(hb_buffer *b, b2Hull *v) {
	for (int k = 0; k < 8; k++) {
		v->points[k].x = hb_rf(b);
		v->points[k].y = hb_rf(b);
	}
	v->count = (int)hb_ri(b);
}

static void hb_wr_b2Hull(hb_buffer *b, const b2Hull *v) {
	for (int k = 0; k < 8; k++) {
		hb_wf(b, v->points[k].x);
		hb_wf(b, v->points[k].y);
	}
	hb_wi(b, (int32_t)v->count);
}

static void hb_rd_b2JointDef(hb_buffer *b, b2JointDef *v) {
	hb_ri(b);
	v->userData = NULL;
	hb_rd_b2BodyId(b, &v->bodyIdA);
	hb_rd_b2BodyId(b, &v->bodyIdB);
	hb_rd_b2Transform(b, &v->localFrameA);
	hb_rd_b2Transform(b, &v->localFrameB);
	v->forceThreshold = hb_rf(b);
	v->torqueThreshold = hb_rf(b);
	v->constraintHertz = hb_rf(b);
	v->constraintDampingRatio = hb_rf(b);
	v->drawScale = hb_rf(b);
	v->collideConnected = hb_ri(b) != 0;
}

static void hb_wr_b2JointDef(hb_buffer *b, const b2JointDef *v) {
	hb_wi(b, 0);
	hb_wr_b2BodyId(b, &v->bodyIdA);
	hb_wr_b2BodyId(b, &v->bodyIdB);
	hb_wr_b2Transform(b, &v->localFrameA);
	hb_wr_b2Transform(b, &v->localFrameB);
	hb_wf(b, v->forceThreshold);
	hb_wf(b, v->torqueThreshold);
	hb_wf(b, v->constraintHertz);
	hb_wf(b, v->constraintDampingRatio);
	hb_wf(b, v->drawScale);
	hb_wi(b, v->collideConnected ? 1 : 0);
}

static void hb_rd_b2JointEvent(hb_buffer *b, b2JointEvent *v) {
	hb_rd_b2JointId(b, &v->jointId);
	hb_ri(b);
	v->userData = NULL;
}

static void hb_wr_b2JointEvent(hb_buffer *b, const b2JointEvent *v) {
	hb_wr_b2JointId(b, &v->jointId);
	hb_wi(b, 0);
}

static void hb_rd_b2JointEvents(hb_buffer *b, b2JointEvents *v) {
	{
		int32_t count = hb_ri(b);
		b2JointEvent *a = (b2JointEvent *)hb_scratch(24, (size_t)(count > 0 ? count : 1) * sizeof(b2JointEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2JointEvent(b, &a[k]);
		}
		v->jointEvents = a;
	}
	v->count = (int)hb_ri(b);
}

static void hb_wr_b2JointEvents(hb_buffer *b, const b2JointEvents *v) {
	hb_wi(b, v->count);
	for (int32_t k = 0; k < v->count; k++) {
		hb_wr_b2JointEvent(b, &v->jointEvents[k]);
	}
	hb_wi(b, (int32_t)v->count);
}

static void hb_rd_b2JointId(hb_buffer *b, b2JointId *v) {
	v->index1 = (int32_t)hb_ri(b);
	v->world0 = (uint16_t)hb_ri(b);
	v->generation = (uint16_t)hb_ri(b);
}

static void hb_wr_b2JointId(hb_buffer *b, const b2JointId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->world0);
	hb_wi(b, (int32_t)v->generation);
}

static void hb_rd_b2LocalManifold(hb_buffer *b, b2LocalManifold *v) {
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	for (int k = 0; k < 2; k++) {
		hb_rd_b2LocalManifoldPoint(b, &v->points[k]);
	}
	v->pointCount = (int)hb_ri(b);
}

static void hb_wr_b2LocalManifold(hb_buffer *b, const b2LocalManifold *v) {
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	for (int k = 0; k < 2; k++) {
		hb_wr_b2LocalManifoldPoint(b, &v->points[k]);
	}
	hb_wi(b, (int32_t)v->pointCount);
}

static void hb_rd_b2LocalManifoldPoint(hb_buffer *b, b2LocalManifoldPoint *v) {
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->separation = hb_rf(b);
	v->id = (uint16_t)hb_ri(b);
}

static void hb_wr_b2LocalManifoldPoint(hb_buffer *b, const b2LocalManifoldPoint *v) {
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wf(b, v->separation);
	hb_wi(b, (int32_t)v->id);
}

static void hb_rd_b2Manifold(hb_buffer *b, b2Manifold *v) {
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->rollingImpulse = hb_rf(b);
	for (int k = 0; k < 2; k++) {
		hb_rd_b2ManifoldPoint(b, &v->points[k]);
	}
	v->pointCount = (int)hb_ri(b);
}

static void hb_wr_b2Manifold(hb_buffer *b, const b2Manifold *v) {
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->rollingImpulse);
	for (int k = 0; k < 2; k++) {
		hb_wr_b2ManifoldPoint(b, &v->points[k]);
	}
	hb_wi(b, (int32_t)v->pointCount);
}

static void hb_rd_b2ManifoldPoint(hb_buffer *b, b2ManifoldPoint *v) {
	v->anchorA.x = hb_rf(b);
	v->anchorA.y = hb_rf(b);
	v->anchorB.x = hb_rf(b);
	v->anchorB.y = hb_rf(b);
	v->separation = hb_rf(b);
	v->normalImpulse = hb_rf(b);
	v->tangentImpulse = hb_rf(b);
	v->totalNormalImpulse = hb_rf(b);
	v->normalVelocity = hb_rf(b);
	v->baseSeparation = hb_rf(b);
	v->id = (uint16_t)hb_ri(b);
	v->persisted = hb_ri(b) != 0;
}

static void hb_wr_b2ManifoldPoint(hb_buffer *b, const b2ManifoldPoint *v) {
	hb_wf(b, v->anchorA.x);
	hb_wf(b, v->anchorA.y);
	hb_wf(b, v->anchorB.x);
	hb_wf(b, v->anchorB.y);
	hb_wf(b, v->separation);
	hb_wf(b, v->normalImpulse);
	hb_wf(b, v->tangentImpulse);
	hb_wf(b, v->totalNormalImpulse);
	hb_wf(b, v->normalVelocity);
	hb_wf(b, v->baseSeparation);
	hb_wi(b, (int32_t)v->id);
	hb_wi(b, v->persisted ? 1 : 0);
}

static void hb_rd_b2MassData(hb_buffer *b, b2MassData *v) {
	v->mass = hb_rf(b);
	v->center.x = hb_rf(b);
	v->center.y = hb_rf(b);
	v->rotationalInertia = hb_rf(b);
}

static void hb_wr_b2MassData(hb_buffer *b, const b2MassData *v) {
	hb_wf(b, v->mass);
	hb_wf(b, v->center.x);
	hb_wf(b, v->center.y);
	hb_wf(b, v->rotationalInertia);
}

static void hb_rd_b2Mat22(hb_buffer *b, b2Mat22 *v) {
	v->cx.x = hb_rf(b);
	v->cx.y = hb_rf(b);
	v->cy.x = hb_rf(b);
	v->cy.y = hb_rf(b);
}

static void hb_wr_b2Mat22(hb_buffer *b, const b2Mat22 *v) {
	hb_wf(b, v->cx.x);
	hb_wf(b, v->cx.y);
	hb_wf(b, v->cy.x);
	hb_wf(b, v->cy.y);
}

static void hb_rd_b2MotionLocks(hb_buffer *b, b2MotionLocks *v) {
	v->linearX = hb_ri(b) != 0;
	v->linearY = hb_ri(b) != 0;
	v->angularZ = hb_ri(b) != 0;
}

static void hb_wr_b2MotionLocks(hb_buffer *b, const b2MotionLocks *v) {
	hb_wi(b, v->linearX ? 1 : 0);
	hb_wi(b, v->linearY ? 1 : 0);
	hb_wi(b, v->angularZ ? 1 : 0);
}

static void hb_rd_b2MotorJointDef(hb_buffer *b, b2MotorJointDef *v) {
	*v = b2DefaultMotorJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->linearVelocity.x = hb_rf(b);
	v->linearVelocity.y = hb_rf(b);
	v->maxVelocityForce = hb_rf(b);
	v->angularVelocity = hb_rf(b);
	v->maxVelocityTorque = hb_rf(b);
	v->linearHertz = hb_rf(b);
	v->linearDampingRatio = hb_rf(b);
	v->maxSpringForce = hb_rf(b);
	v->angularHertz = hb_rf(b);
	v->angularDampingRatio = hb_rf(b);
	v->maxSpringTorque = hb_rf(b);
}

static void hb_wr_b2MotorJointDef(hb_buffer *b, const b2MotorJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wf(b, v->linearVelocity.x);
	hb_wf(b, v->linearVelocity.y);
	hb_wf(b, v->maxVelocityForce);
	hb_wf(b, v->angularVelocity);
	hb_wf(b, v->maxVelocityTorque);
	hb_wf(b, v->linearHertz);
	hb_wf(b, v->linearDampingRatio);
	hb_wf(b, v->maxSpringForce);
	hb_wf(b, v->angularHertz);
	hb_wf(b, v->angularDampingRatio);
	hb_wf(b, v->maxSpringTorque);
}

static void hb_rd_b2Plane(hb_buffer *b, b2Plane *v) {
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->offset = hb_rf(b);
}

static void hb_wr_b2Plane(hb_buffer *b, const b2Plane *v) {
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->offset);
}

static void hb_rd_b2PlaneResult(hb_buffer *b, b2PlaneResult *v) {
	hb_rd_b2Plane(b, &v->plane);
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->hit = hb_ri(b) != 0;
}

static void hb_wr_b2PlaneResult(hb_buffer *b, const b2PlaneResult *v) {
	hb_wr_b2Plane(b, &v->plane);
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wi(b, v->hit ? 1 : 0);
}

static void hb_rd_b2PlaneSolverResult(hb_buffer *b, b2PlaneSolverResult *v) {
	v->delta.x = hb_rf(b);
	v->delta.y = hb_rf(b);
	v->iterationCount = (int)hb_ri(b);
}

static void hb_wr_b2PlaneSolverResult(hb_buffer *b, const b2PlaneSolverResult *v) {
	hb_wf(b, v->delta.x);
	hb_wf(b, v->delta.y);
	hb_wi(b, (int32_t)v->iterationCount);
}

static void hb_rd_b2Polygon(hb_buffer *b, b2Polygon *v) {
	for (int k = 0; k < 8; k++) {
		v->vertices[k].x = hb_rf(b);
		v->vertices[k].y = hb_rf(b);
	}
	for (int k = 0; k < 8; k++) {
		v->normals[k].x = hb_rf(b);
		v->normals[k].y = hb_rf(b);
	}
	v->centroid.x = hb_rf(b);
	v->centroid.y = hb_rf(b);
	v->radius = hb_rf(b);
	v->count = (int)hb_ri(b);
}

static void hb_wr_b2Polygon(hb_buffer *b, const b2Polygon *v) {
	for (int k = 0; k < 8; k++) {
		hb_wf(b, v->vertices[k].x);
		hb_wf(b, v->vertices[k].y);
	}
	for (int k = 0; k < 8; k++) {
		hb_wf(b, v->normals[k].x);
		hb_wf(b, v->normals[k].y);
	}
	hb_wf(b, v->centroid.x);
	hb_wf(b, v->centroid.y);
	hb_wf(b, v->radius);
	hb_wi(b, (int32_t)v->count);
}

static void hb_rd_b2PrismaticJointDef(hb_buffer *b, b2PrismaticJointDef *v) {
	*v = b2DefaultPrismaticJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->enableSpring = hb_ri(b) != 0;
	v->hertz = hb_rf(b);
	v->dampingRatio = hb_rf(b);
	v->targetTranslation = hb_rf(b);
	v->enableLimit = hb_ri(b) != 0;
	v->lowerTranslation = hb_rf(b);
	v->upperTranslation = hb_rf(b);
	v->enableMotor = hb_ri(b) != 0;
	v->maxMotorForce = hb_rf(b);
	v->motorSpeed = hb_rf(b);
}

static void hb_wr_b2PrismaticJointDef(hb_buffer *b, const b2PrismaticJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wi(b, v->enableSpring ? 1 : 0);
	hb_wf(b, v->hertz);
	hb_wf(b, v->dampingRatio);
	hb_wf(b, v->targetTranslation);
	hb_wi(b, v->enableLimit ? 1 : 0);
	hb_wf(b, v->lowerTranslation);
	hb_wf(b, v->upperTranslation);
	hb_wi(b, v->enableMotor ? 1 : 0);
	hb_wf(b, v->maxMotorForce);
	hb_wf(b, v->motorSpeed);
}

static void hb_rd_b2Profile(hb_buffer *b, b2Profile *v) {
	v->step = hb_rf(b);
	v->pairs = hb_rf(b);
	v->collide = hb_rf(b);
	v->solve = hb_rf(b);
	v->solverSetup = hb_rf(b);
	v->constraints = hb_rf(b);
	v->prepareConstraints = hb_rf(b);
	v->integrateVelocities = hb_rf(b);
	v->warmStart = hb_rf(b);
	v->solveImpulses = hb_rf(b);
	v->integratePositions = hb_rf(b);
	v->relaxImpulses = hb_rf(b);
	v->restitution = hb_rf(b);
	v->storeImpulses = hb_rf(b);
	v->splitIslands = hb_rf(b);
	v->transforms = hb_rf(b);
	v->sensorHits = hb_rf(b);
	v->jointEvents = hb_rf(b);
	v->hitEvents = hb_rf(b);
	v->refit = hb_rf(b);
	v->bullets = hb_rf(b);
	v->sleepIslands = hb_rf(b);
	v->sensors = hb_rf(b);
}

static void hb_wr_b2Profile(hb_buffer *b, const b2Profile *v) {
	hb_wf(b, v->step);
	hb_wf(b, v->pairs);
	hb_wf(b, v->collide);
	hb_wf(b, v->solve);
	hb_wf(b, v->solverSetup);
	hb_wf(b, v->constraints);
	hb_wf(b, v->prepareConstraints);
	hb_wf(b, v->integrateVelocities);
	hb_wf(b, v->warmStart);
	hb_wf(b, v->solveImpulses);
	hb_wf(b, v->integratePositions);
	hb_wf(b, v->relaxImpulses);
	hb_wf(b, v->restitution);
	hb_wf(b, v->storeImpulses);
	hb_wf(b, v->splitIslands);
	hb_wf(b, v->transforms);
	hb_wf(b, v->sensorHits);
	hb_wf(b, v->jointEvents);
	hb_wf(b, v->hitEvents);
	hb_wf(b, v->refit);
	hb_wf(b, v->bullets);
	hb_wf(b, v->sleepIslands);
	hb_wf(b, v->sensors);
}

static void hb_rd_b2QueryFilter(hb_buffer *b, b2QueryFilter *v) {
	*v = b2DefaultQueryFilter();
	v->categoryBits = hb_rl(b);
	v->maskBits = hb_rl(b);
}

static void hb_wr_b2QueryFilter(hb_buffer *b, const b2QueryFilter *v) {
	hb_wl(b, v->categoryBits);
	hb_wl(b, v->maskBits);
}

static void hb_rd_b2RayCastInput(hb_buffer *b, b2RayCastInput *v) {
	v->origin.x = hb_rf(b);
	v->origin.y = hb_rf(b);
	v->translation.x = hb_rf(b);
	v->translation.y = hb_rf(b);
	v->maxFraction = hb_rf(b);
}

static void hb_wr_b2RayCastInput(hb_buffer *b, const b2RayCastInput *v) {
	hb_wf(b, v->origin.x);
	hb_wf(b, v->origin.y);
	hb_wf(b, v->translation.x);
	hb_wf(b, v->translation.y);
	hb_wf(b, v->maxFraction);
}

static void hb_rd_b2RayResult(hb_buffer *b, b2RayResult *v) {
	hb_rd_b2ShapeId(b, &v->shapeId);
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->fraction = hb_rf(b);
	v->nodeVisits = (int)hb_ri(b);
	v->leafVisits = (int)hb_ri(b);
	v->hit = hb_ri(b) != 0;
}

static void hb_wr_b2RayResult(hb_buffer *b, const b2RayResult *v) {
	hb_wr_b2ShapeId(b, &v->shapeId);
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->fraction);
	hb_wi(b, (int32_t)v->nodeVisits);
	hb_wi(b, (int32_t)v->leafVisits);
	hb_wi(b, v->hit ? 1 : 0);
}

static void hb_rd_b2RevoluteJointDef(hb_buffer *b, b2RevoluteJointDef *v) {
	*v = b2DefaultRevoluteJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->targetAngle = hb_rf(b);
	v->enableSpring = hb_ri(b) != 0;
	v->hertz = hb_rf(b);
	v->dampingRatio = hb_rf(b);
	v->enableLimit = hb_ri(b) != 0;
	v->lowerAngle = hb_rf(b);
	v->upperAngle = hb_rf(b);
	v->enableMotor = hb_ri(b) != 0;
	v->maxMotorTorque = hb_rf(b);
	v->motorSpeed = hb_rf(b);
}

static void hb_wr_b2RevoluteJointDef(hb_buffer *b, const b2RevoluteJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wf(b, v->targetAngle);
	hb_wi(b, v->enableSpring ? 1 : 0);
	hb_wf(b, v->hertz);
	hb_wf(b, v->dampingRatio);
	hb_wi(b, v->enableLimit ? 1 : 0);
	hb_wf(b, v->lowerAngle);
	hb_wf(b, v->upperAngle);
	hb_wi(b, v->enableMotor ? 1 : 0);
	hb_wf(b, v->maxMotorTorque);
	hb_wf(b, v->motorSpeed);
}

static void hb_rd_b2Rot(hb_buffer *b, b2Rot *v) {
	v->c = hb_rf(b);
	v->s = hb_rf(b);
}

static void hb_wr_b2Rot(hb_buffer *b, const b2Rot *v) {
	hb_wf(b, v->c);
	hb_wf(b, v->s);
}

static void hb_rd_b2Segment(hb_buffer *b, b2Segment *v) {
	v->point1.x = hb_rf(b);
	v->point1.y = hb_rf(b);
	v->point2.x = hb_rf(b);
	v->point2.y = hb_rf(b);
}

static void hb_wr_b2Segment(hb_buffer *b, const b2Segment *v) {
	hb_wf(b, v->point1.x);
	hb_wf(b, v->point1.y);
	hb_wf(b, v->point2.x);
	hb_wf(b, v->point2.y);
}

static void hb_rd_b2SegmentDistanceResult(hb_buffer *b, b2SegmentDistanceResult *v) {
	v->closest1.x = hb_rf(b);
	v->closest1.y = hb_rf(b);
	v->closest2.x = hb_rf(b);
	v->closest2.y = hb_rf(b);
	v->fraction1 = hb_rf(b);
	v->fraction2 = hb_rf(b);
	v->distanceSquared = hb_rf(b);
}

static void hb_wr_b2SegmentDistanceResult(hb_buffer *b, const b2SegmentDistanceResult *v) {
	hb_wf(b, v->closest1.x);
	hb_wf(b, v->closest1.y);
	hb_wf(b, v->closest2.x);
	hb_wf(b, v->closest2.y);
	hb_wf(b, v->fraction1);
	hb_wf(b, v->fraction2);
	hb_wf(b, v->distanceSquared);
}

static void hb_rd_b2SensorBeginTouchEvent(hb_buffer *b, b2SensorBeginTouchEvent *v) {
	hb_rd_b2ShapeId(b, &v->sensorShapeId);
	hb_rd_b2ShapeId(b, &v->visitorShapeId);
}

static void hb_wr_b2SensorBeginTouchEvent(hb_buffer *b, const b2SensorBeginTouchEvent *v) {
	hb_wr_b2ShapeId(b, &v->sensorShapeId);
	hb_wr_b2ShapeId(b, &v->visitorShapeId);
}

static void hb_rd_b2SensorEndTouchEvent(hb_buffer *b, b2SensorEndTouchEvent *v) {
	hb_rd_b2ShapeId(b, &v->sensorShapeId);
	hb_rd_b2ShapeId(b, &v->visitorShapeId);
}

static void hb_wr_b2SensorEndTouchEvent(hb_buffer *b, const b2SensorEndTouchEvent *v) {
	hb_wr_b2ShapeId(b, &v->sensorShapeId);
	hb_wr_b2ShapeId(b, &v->visitorShapeId);
}

static void hb_rd_b2SensorEvents(hb_buffer *b, b2SensorEvents *v) {
	{
		int32_t count = hb_ri(b);
		b2SensorBeginTouchEvent *a = (b2SensorBeginTouchEvent *)hb_scratch(24, (size_t)(count > 0 ? count : 1) * sizeof(b2SensorBeginTouchEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2SensorBeginTouchEvent(b, &a[k]);
		}
		v->beginEvents = a;
	}
	{
		int32_t count = hb_ri(b);
		b2SensorEndTouchEvent *a = (b2SensorEndTouchEvent *)hb_scratch(25, (size_t)(count > 0 ? count : 1) * sizeof(b2SensorEndTouchEvent));
		for (int32_t k = 0; k < count; k++) {
			hb_rd_b2SensorEndTouchEvent(b, &a[k]);
		}
		v->endEvents = a;
	}
	v->beginCount = (int)hb_ri(b);
	v->endCount = (int)hb_ri(b);
}

static void hb_wr_b2SensorEvents(hb_buffer *b, const b2SensorEvents *v) {
	hb_wi(b, v->beginCount);
	for (int32_t k = 0; k < v->beginCount; k++) {
		hb_wr_b2SensorBeginTouchEvent(b, &v->beginEvents[k]);
	}
	hb_wi(b, v->endCount);
	for (int32_t k = 0; k < v->endCount; k++) {
		hb_wr_b2SensorEndTouchEvent(b, &v->endEvents[k]);
	}
	hb_wi(b, (int32_t)v->beginCount);
	hb_wi(b, (int32_t)v->endCount);
}

static void hb_rd_b2ShapeCastInput(hb_buffer *b, b2ShapeCastInput *v) {
	hb_rd_b2ShapeProxy(b, &v->proxy);
	v->translation.x = hb_rf(b);
	v->translation.y = hb_rf(b);
	v->maxFraction = hb_rf(b);
	v->canEncroach = hb_ri(b) != 0;
}

static void hb_wr_b2ShapeCastInput(hb_buffer *b, const b2ShapeCastInput *v) {
	hb_wr_b2ShapeProxy(b, &v->proxy);
	hb_wf(b, v->translation.x);
	hb_wf(b, v->translation.y);
	hb_wf(b, v->maxFraction);
	hb_wi(b, v->canEncroach ? 1 : 0);
}

static void hb_rd_b2ShapeCastPairInput(hb_buffer *b, b2ShapeCastPairInput *v) {
	hb_rd_b2ShapeProxy(b, &v->proxyA);
	hb_rd_b2ShapeProxy(b, &v->proxyB);
	hb_rd_b2Transform(b, &v->transform);
	v->translationB.x = hb_rf(b);
	v->translationB.y = hb_rf(b);
	v->maxFraction = hb_rf(b);
	v->canEncroach = hb_ri(b) != 0;
}

static void hb_wr_b2ShapeCastPairInput(hb_buffer *b, const b2ShapeCastPairInput *v) {
	hb_wr_b2ShapeProxy(b, &v->proxyA);
	hb_wr_b2ShapeProxy(b, &v->proxyB);
	hb_wr_b2Transform(b, &v->transform);
	hb_wf(b, v->translationB.x);
	hb_wf(b, v->translationB.y);
	hb_wf(b, v->maxFraction);
	hb_wi(b, v->canEncroach ? 1 : 0);
}

static void hb_rd_b2ShapeDef(hb_buffer *b, b2ShapeDef *v) {
	*v = b2DefaultShapeDef();
	hb_ri(b);
	v->userData = NULL;
	hb_rd_b2SurfaceMaterial(b, &v->material);
	v->density = hb_rf(b);
	hb_rd_b2Filter(b, &v->filter);
	v->enableCustomFiltering = hb_ri(b) != 0;
	v->isSensor = hb_ri(b) != 0;
	v->enableSensorEvents = hb_ri(b) != 0;
	v->enableContactEvents = hb_ri(b) != 0;
	v->enableHitEvents = hb_ri(b) != 0;
	v->enablePreSolveEvents = hb_ri(b) != 0;
	v->invokeContactCreation = hb_ri(b) != 0;
	v->updateBodyMass = hb_ri(b) != 0;
}

static void hb_wr_b2ShapeDef(hb_buffer *b, const b2ShapeDef *v) {
	hb_wi(b, 0);
	hb_wr_b2SurfaceMaterial(b, &v->material);
	hb_wf(b, v->density);
	hb_wr_b2Filter(b, &v->filter);
	hb_wi(b, v->enableCustomFiltering ? 1 : 0);
	hb_wi(b, v->isSensor ? 1 : 0);
	hb_wi(b, v->enableSensorEvents ? 1 : 0);
	hb_wi(b, v->enableContactEvents ? 1 : 0);
	hb_wi(b, v->enableHitEvents ? 1 : 0);
	hb_wi(b, v->enablePreSolveEvents ? 1 : 0);
	hb_wi(b, v->invokeContactCreation ? 1 : 0);
	hb_wi(b, v->updateBodyMass ? 1 : 0);
}

static void hb_rd_b2ShapeId(hb_buffer *b, b2ShapeId *v) {
	v->index1 = (int32_t)hb_ri(b);
	v->world0 = (uint16_t)hb_ri(b);
	v->generation = (uint16_t)hb_ri(b);
}

static void hb_wr_b2ShapeId(hb_buffer *b, const b2ShapeId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->world0);
	hb_wi(b, (int32_t)v->generation);
}

static void hb_rd_b2ShapeProxy(hb_buffer *b, b2ShapeProxy *v) {
	for (int k = 0; k < 8; k++) {
		v->points[k].x = hb_rf(b);
		v->points[k].y = hb_rf(b);
	}
	v->count = (int)hb_ri(b);
	v->radius = hb_rf(b);
}

static void hb_wr_b2ShapeProxy(hb_buffer *b, const b2ShapeProxy *v) {
	for (int k = 0; k < 8; k++) {
		hb_wf(b, v->points[k].x);
		hb_wf(b, v->points[k].y);
	}
	hb_wi(b, (int32_t)v->count);
	hb_wf(b, v->radius);
}

static void hb_rd_b2Simplex(hb_buffer *b, b2Simplex *v) {
	hb_rd_b2SimplexVertex(b, &v->v1);
	hb_rd_b2SimplexVertex(b, &v->v2);
	hb_rd_b2SimplexVertex(b, &v->v3);
	v->count = (int)hb_ri(b);
}

static void hb_wr_b2Simplex(hb_buffer *b, const b2Simplex *v) {
	hb_wr_b2SimplexVertex(b, &v->v1);
	hb_wr_b2SimplexVertex(b, &v->v2);
	hb_wr_b2SimplexVertex(b, &v->v3);
	hb_wi(b, (int32_t)v->count);
}

static void hb_rd_b2SimplexCache(hb_buffer *b, b2SimplexCache *v) {
	v->count = (uint16_t)hb_ri(b);
	for (int k = 0; k < 3; k++) {
		v->indexA[k] = (uint8_t)hb_ri(b);
	}
	for (int k = 0; k < 3; k++) {
		v->indexB[k] = (uint8_t)hb_ri(b);
	}
}

static void hb_wr_b2SimplexCache(hb_buffer *b, const b2SimplexCache *v) {
	hb_wi(b, (int32_t)v->count);
	for (int k = 0; k < 3; k++) {
		hb_wi(b, (int32_t)v->indexA[k]);
	}
	for (int k = 0; k < 3; k++) {
		hb_wi(b, (int32_t)v->indexB[k]);
	}
}

static void hb_rd_b2SimplexVertex(hb_buffer *b, b2SimplexVertex *v) {
	v->wA.x = hb_rf(b);
	v->wA.y = hb_rf(b);
	v->wB.x = hb_rf(b);
	v->wB.y = hb_rf(b);
	v->w.x = hb_rf(b);
	v->w.y = hb_rf(b);
	v->a = hb_rf(b);
	v->indexA = (int)hb_ri(b);
	v->indexB = (int)hb_ri(b);
}

static void hb_wr_b2SimplexVertex(hb_buffer *b, const b2SimplexVertex *v) {
	hb_wf(b, v->wA.x);
	hb_wf(b, v->wA.y);
	hb_wf(b, v->wB.x);
	hb_wf(b, v->wB.y);
	hb_wf(b, v->w.x);
	hb_wf(b, v->w.y);
	hb_wf(b, v->a);
	hb_wi(b, (int32_t)v->indexA);
	hb_wi(b, (int32_t)v->indexB);
}

static void hb_rd_b2SurfaceMaterial(hb_buffer *b, b2SurfaceMaterial *v) {
	*v = b2DefaultSurfaceMaterial();
	v->friction = hb_rf(b);
	v->restitution = hb_rf(b);
	v->rollingResistance = hb_rf(b);
	v->tangentSpeed = hb_rf(b);
	v->userMaterialId = hb_rl(b);
	v->customColor = (uint32_t)hb_ri(b);
}

static void hb_wr_b2SurfaceMaterial(hb_buffer *b, const b2SurfaceMaterial *v) {
	hb_wf(b, v->friction);
	hb_wf(b, v->restitution);
	hb_wf(b, v->rollingResistance);
	hb_wf(b, v->tangentSpeed);
	hb_wl(b, v->userMaterialId);
	hb_wi(b, (int32_t)v->customColor);
}

static void hb_rd_b2Sweep(hb_buffer *b, b2Sweep *v) {
	v->localCenter.x = hb_rf(b);
	v->localCenter.y = hb_rf(b);
	v->c1.x = hb_rf(b);
	v->c1.y = hb_rf(b);
	v->c2.x = hb_rf(b);
	v->c2.y = hb_rf(b);
	hb_rd_b2Rot(b, &v->q1);
	hb_rd_b2Rot(b, &v->q2);
}

static void hb_wr_b2Sweep(hb_buffer *b, const b2Sweep *v) {
	hb_wf(b, v->localCenter.x);
	hb_wf(b, v->localCenter.y);
	hb_wf(b, v->c1.x);
	hb_wf(b, v->c1.y);
	hb_wf(b, v->c2.x);
	hb_wf(b, v->c2.y);
	hb_wr_b2Rot(b, &v->q1);
	hb_wr_b2Rot(b, &v->q2);
}

static void hb_rd_b2TOIInput(hb_buffer *b, b2TOIInput *v) {
	hb_rd_b2ShapeProxy(b, &v->proxyA);
	hb_rd_b2ShapeProxy(b, &v->proxyB);
	hb_rd_b2Sweep(b, &v->sweepA);
	hb_rd_b2Sweep(b, &v->sweepB);
	v->maxFraction = hb_rf(b);
}

static void hb_wr_b2TOIInput(hb_buffer *b, const b2TOIInput *v) {
	hb_wr_b2ShapeProxy(b, &v->proxyA);
	hb_wr_b2ShapeProxy(b, &v->proxyB);
	hb_wr_b2Sweep(b, &v->sweepA);
	hb_wr_b2Sweep(b, &v->sweepB);
	hb_wf(b, v->maxFraction);
}

static void hb_rd_b2TOIOutput(hb_buffer *b, b2TOIOutput *v) {
	v->state = (b2TOIState)hb_ri(b);
	v->point.x = hb_rf(b);
	v->point.y = hb_rf(b);
	v->normal.x = hb_rf(b);
	v->normal.y = hb_rf(b);
	v->fraction = hb_rf(b);
}

static void hb_wr_b2TOIOutput(hb_buffer *b, const b2TOIOutput *v) {
	hb_wi(b, (int32_t)v->state);
	hb_wf(b, v->point.x);
	hb_wf(b, v->point.y);
	hb_wf(b, v->normal.x);
	hb_wf(b, v->normal.y);
	hb_wf(b, v->fraction);
}

static void hb_rd_b2Transform(hb_buffer *b, b2Transform *v) {
	v->p.x = hb_rf(b);
	v->p.y = hb_rf(b);
	hb_rd_b2Rot(b, &v->q);
}

static void hb_wr_b2Transform(hb_buffer *b, const b2Transform *v) {
	hb_wf(b, v->p.x);
	hb_wf(b, v->p.y);
	hb_wr_b2Rot(b, &v->q);
}

static void hb_rd_b2TreeStats(hb_buffer *b, b2TreeStats *v) {
	v->nodeVisits = (int)hb_ri(b);
	v->leafVisits = (int)hb_ri(b);
}

static void hb_wr_b2TreeStats(hb_buffer *b, const b2TreeStats *v) {
	hb_wi(b, (int32_t)v->nodeVisits);
	hb_wi(b, (int32_t)v->leafVisits);
}

static void hb_rd_b2Version(hb_buffer *b, b2Version *v) {
	v->major = (int)hb_ri(b);
	v->minor = (int)hb_ri(b);
	v->revision = (int)hb_ri(b);
}

static void hb_wr_b2Version(hb_buffer *b, const b2Version *v) {
	hb_wi(b, (int32_t)v->major);
	hb_wi(b, (int32_t)v->minor);
	hb_wi(b, (int32_t)v->revision);
}

static void hb_rd_b2WeldJointDef(hb_buffer *b, b2WeldJointDef *v) {
	*v = b2DefaultWeldJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->linearHertz = hb_rf(b);
	v->angularHertz = hb_rf(b);
	v->linearDampingRatio = hb_rf(b);
	v->angularDampingRatio = hb_rf(b);
}

static void hb_wr_b2WeldJointDef(hb_buffer *b, const b2WeldJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wf(b, v->linearHertz);
	hb_wf(b, v->angularHertz);
	hb_wf(b, v->linearDampingRatio);
	hb_wf(b, v->angularDampingRatio);
}

static void hb_rd_b2WheelJointDef(hb_buffer *b, b2WheelJointDef *v) {
	*v = b2DefaultWheelJointDef();
	hb_rd_b2JointDef(b, &v->base);
	v->enableSpring = hb_ri(b) != 0;
	v->hertz = hb_rf(b);
	v->dampingRatio = hb_rf(b);
	v->enableLimit = hb_ri(b) != 0;
	v->lowerTranslation = hb_rf(b);
	v->upperTranslation = hb_rf(b);
	v->enableMotor = hb_ri(b) != 0;
	v->maxMotorTorque = hb_rf(b);
	v->motorSpeed = hb_rf(b);
}

static void hb_wr_b2WheelJointDef(hb_buffer *b, const b2WheelJointDef *v) {
	hb_wr_b2JointDef(b, &v->base);
	hb_wi(b, v->enableSpring ? 1 : 0);
	hb_wf(b, v->hertz);
	hb_wf(b, v->dampingRatio);
	hb_wi(b, v->enableLimit ? 1 : 0);
	hb_wf(b, v->lowerTranslation);
	hb_wf(b, v->upperTranslation);
	hb_wi(b, v->enableMotor ? 1 : 0);
	hb_wf(b, v->maxMotorTorque);
	hb_wf(b, v->motorSpeed);
}

static void hb_rd_b2WorldDef(hb_buffer *b, b2WorldDef *v) {
	*v = b2DefaultWorldDef();
	v->gravity.x = hb_rf(b);
	v->gravity.y = hb_rf(b);
	v->restitutionThreshold = hb_rf(b);
	v->restitutionIterations = (int)hb_ri(b);
	v->enableRestitutionPropagation = hb_ri(b) != 0;
	v->hitEventThreshold = hb_rf(b);
	v->contactHertz = hb_rf(b);
	v->contactDampingRatio = hb_rf(b);
	v->contactSpeed = hb_rf(b);
	v->maximumLinearSpeed = hb_rf(b);
	if (hb_ri(b))
		v->frictionCallback = hb_tr_b2FrictionCallbackFcn;
	if (hb_ri(b))
		v->restitutionCallback = hb_tr_b2RestitutionCallbackFcn;
	v->enableSleep = hb_ri(b) != 0;
	v->enableContinuous = hb_ri(b) != 0;
	v->workerCount = (int)hb_ri(b);
	hb_ri(b);
	v->userData = NULL;
	hb_rd_b2Capacity(b, &v->capacity);
#ifdef __EMSCRIPTEN__
	v->workerCount = 1;
#endif
}

static void hb_wr_b2WorldDef(hb_buffer *b, const b2WorldDef *v) {
	hb_wf(b, v->gravity.x);
	hb_wf(b, v->gravity.y);
	hb_wf(b, v->restitutionThreshold);
	hb_wi(b, (int32_t)v->restitutionIterations);
	hb_wi(b, v->enableRestitutionPropagation ? 1 : 0);
	hb_wf(b, v->hitEventThreshold);
	hb_wf(b, v->contactHertz);
	hb_wf(b, v->contactDampingRatio);
	hb_wf(b, v->contactSpeed);
	hb_wf(b, v->maximumLinearSpeed);
	hb_wi(b, v->frictionCallback != NULL);
	hb_wi(b, v->restitutionCallback != NULL);
	hb_wi(b, v->enableSleep ? 1 : 0);
	hb_wi(b, v->enableContinuous ? 1 : 0);
	hb_wi(b, (int32_t)v->workerCount);
	hb_wi(b, 0);
	hb_wr_b2Capacity(b, &v->capacity);
}

static void hb_rd_b2WorldId(hb_buffer *b, b2WorldId *v) {
	v->index1 = (uint16_t)hb_ri(b);
	v->generation = (uint16_t)hb_ri(b);
}

static void hb_wr_b2WorldId(hb_buffer *b, const b2WorldId *v) {
	hb_wi(b, (int32_t)v->index1);
	hb_wi(b, (int32_t)v->generation);
}

HB_API int32_t hb_b2GetByteCount(void) {
	size_t result = b2GetByteCount();
	return result;
}

HB_API void hb_b2SetLogCallback(int32_t logFcn) {
	b2SetLogCallback(logFcn ? hb_tr_b2LogCallbackFcn : NULL);
}

HB_API void hb_b2GetVersion(void) {
	b2Version result = b2GetVersion();
	hb_begin(&hb_call);
	hb_wr_b2Version(&hb_call, &result);
}

HB_API int32_t hb_b2IsDoublePrecision(void) {
	bool result = b2IsDoublePrecision();
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsAVX2Available(void) {
	bool result = b2IsAVX2Available();
	return result ? 1 : 0;
}

HB_API void hb_b2GetTicks(void) {
	uint64_t result = b2GetTicks();
	hb_begin(&hb_call);
	hb_wl(&hb_call, result);
}

HB_API float hb_b2GetMilliseconds(int32_t ticks_low, int32_t ticks_high) {
	float result = b2GetMilliseconds(((uint64_t)(uint32_t)ticks_high << 32) | (uint32_t)ticks_low);
	return result;
}

HB_API float hb_b2GetMillisecondsAndReset(void) {
	uint64_t ticks_v = 0;
	float result = b2GetMillisecondsAndReset(&ticks_v);
	hb_begin(&hb_call);
	hb_wl(&hb_call, ticks_v);
	return result;
}

HB_API int32_t hb_b2Hash(int32_t hash, int32_t count) {
	hb_begin(&hb_call);
	const uint8_t *data_v = hb_rbytes(&hb_call, count, 1);
	uint32_t result = b2Hash((uint32_t)hash, data_v, (int)count);
	return result;
}

HB_API int32_t hb_b2IsValidFloat(float a) {
	bool result = b2IsValidFloat(a);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidVec2(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	bool result = b2IsValidVec2(v_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidRot(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	bool result = b2IsValidRot(q_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidTransform(float t_p_x, float t_p_y, float t_q_c, float t_q_s) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	bool result = b2IsValidTransform(t_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidAABB(float aabb_lowerBound_x, float aabb_lowerBound_y, float aabb_upperBound_x, float aabb_upperBound_y) {
	b2AABB aabb_v;
	aabb_v.lowerBound.x = aabb_lowerBound_x;
	aabb_v.lowerBound.y = aabb_lowerBound_y;
	aabb_v.upperBound.x = aabb_upperBound_x;
	aabb_v.upperBound.y = aabb_upperBound_y;
	bool result = b2IsValidAABB(aabb_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidPlane(float a_normal_x, float a_normal_y, float a_offset) {
	b2Plane a_v;
	a_v.normal.x = a_normal_x;
	a_v.normal.y = a_normal_y;
	a_v.offset = a_offset;
	bool result = b2IsValidPlane(a_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidPos(float p_x, float p_y) {
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	bool result = b2IsValidPos(p_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2IsValidWorldTransform(float t_p_x, float t_p_y, float t_q_c, float t_q_s) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	bool result = b2IsValidWorldTransform(t_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2MinInt(int32_t a, int32_t b) {
	int result = b2MinInt((int)a, (int)b);
	return result;
}

HB_API int32_t hb_b2MaxInt(int32_t a, int32_t b) {
	int result = b2MaxInt((int)a, (int)b);
	return result;
}

HB_API int32_t hb_b2AbsInt(int32_t a) {
	int result = b2AbsInt((int)a);
	return result;
}

HB_API int32_t hb_b2ClampInt(int32_t a, int32_t lower, int32_t upper) {
	int result = b2ClampInt((int)a, (int)lower, (int)upper);
	return result;
}

HB_API int32_t hb_b2CeilingInt(int32_t numerator, int32_t denominator) {
	int result = b2CeilingInt((int)numerator, (int)denominator);
	return result;
}

HB_API float hb_b2MinFloat(float a, float b) {
	float result = b2MinFloat(a, b);
	return result;
}

HB_API float hb_b2MaxFloat(float a, float b) {
	float result = b2MaxFloat(a, b);
	return result;
}

HB_API float hb_b2AbsFloat(float a) {
	float result = b2AbsFloat(a);
	return result;
}

HB_API float hb_b2ClampFloat(float a, float lower, float upper) {
	float result = b2ClampFloat(a, lower, upper);
	return result;
}

HB_API float hb_b2Atan2(float y, float x) {
	float result = b2Atan2(y, x);
	return result;
}

HB_API void hb_b2ComputeCosSin(float radians) {
	b2CosSin result = b2ComputeCosSin(radians);
	hb_begin(&hb_call);
	hb_wr_b2CosSin(&hb_call, &result);
}

HB_API float hb_b2Dot(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	float result = b2Dot(a_v, b_v);
	return result;
}

HB_API float hb_b2Cross(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	float result = b2Cross(a_v, b_v);
	return result;
}

HB_API void hb_b2CrossVS(float v_x, float v_y, float s) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2CrossVS(v_v, s);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2CrossSV(float s, float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2CrossSV(s, v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2LeftPerp(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2LeftPerp(v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2RightPerp(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2RightPerp(v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Add(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Add(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Sub(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Sub(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Neg(float a_x, float a_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 result = b2Neg(a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Lerp(float a_x, float a_y, float b_x, float b_y, float t) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Lerp(a_v, b_v, t);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Mul(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Mul(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MulSV(float s, float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2MulSV(s, v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MulAdd(float a_x, float a_y, float s, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2MulAdd(a_v, s, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MulSub(float a_x, float a_y, float s, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2MulSub(a_v, s, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Abs(float a_x, float a_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 result = b2Abs(a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Min(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Min(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Max(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Max(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Clamp(float v_x, float v_y, float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Clamp(v_v, a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API float hb_b2Length(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	float result = b2Length(v_v);
	return result;
}

HB_API float hb_b2Distance(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	float result = b2Distance(a_v, b_v);
	return result;
}

HB_API void hb_b2Normalize(float a_x, float a_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 result = b2Normalize(a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API int32_t hb_b2IsNormalized(float a_x, float a_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	bool result = b2IsNormalized(a_v);
	return result ? 1 : 0;
}

HB_API void hb_b2GetLengthAndNormalize(float a_x, float a_y) {
	float length_v = 0;
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 result = b2GetLengthAndNormalize(&length_v, a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
	hb_wf(&hb_call, length_v);
}

HB_API void hb_b2NormalizeRot(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Rot result = b2NormalizeRot(q_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2IntegrateRotation(float q1_c, float q1_s, float deltaAngle) {
	b2Rot q1_v;
	q1_v.c = q1_c;
	q1_v.s = q1_s;
	b2Rot result = b2IntegrateRotation(q1_v, deltaAngle);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API float hb_b2LengthSquared(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	float result = b2LengthSquared(v_v);
	return result;
}

HB_API float hb_b2DistanceSquared(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	float result = b2DistanceSquared(a_v, b_v);
	return result;
}

HB_API void hb_b2MakeRot(float radians) {
	b2Rot result = b2MakeRot(radians);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2MakeRotFromUnitVector(float unitVector_x, float unitVector_y) {
	b2Vec2 unitVector_v;
	unitVector_v.x = unitVector_x;
	unitVector_v.y = unitVector_y;
	b2Rot result = b2MakeRotFromUnitVector(unitVector_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2ComputeRotationBetweenUnitVectors(float v1_x, float v1_y, float v2_x, float v2_y) {
	b2Vec2 v1_v;
	v1_v.x = v1_x;
	v1_v.y = v1_y;
	b2Vec2 v2_v;
	v2_v.x = v2_x;
	v2_v.y = v2_y;
	b2Rot result = b2ComputeRotationBetweenUnitVectors(v1_v, v2_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API int32_t hb_b2IsNormalizedRot(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	bool result = b2IsNormalizedRot(q_v);
	return result ? 1 : 0;
}

HB_API void hb_b2InvertRot(float a_c, float a_s) {
	b2Rot a_v;
	a_v.c = a_c;
	a_v.s = a_s;
	b2Rot result = b2InvertRot(a_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2NLerp(float q1_c, float q1_s, float q2_c, float q2_s, float t) {
	b2Rot q1_v;
	q1_v.c = q1_c;
	q1_v.s = q1_s;
	b2Rot q2_v;
	q2_v.c = q2_c;
	q2_v.s = q2_s;
	b2Rot result = b2NLerp(q1_v, q2_v, t);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API float hb_b2ComputeAngularVelocity(float q1_c, float q1_s, float q2_c, float q2_s, float inv_h) {
	b2Rot q1_v;
	q1_v.c = q1_c;
	q1_v.s = q1_s;
	b2Rot q2_v;
	q2_v.c = q2_c;
	q2_v.s = q2_s;
	float result = b2ComputeAngularVelocity(q1_v, q2_v, inv_h);
	return result;
}

HB_API float hb_b2Rot_GetAngle(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	float result = b2Rot_GetAngle(q_v);
	return result;
}

HB_API void hb_b2Rot_GetXAxis(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Vec2 result = b2Rot_GetXAxis(q_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Rot_GetYAxis(float q_c, float q_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Vec2 result = b2Rot_GetYAxis(q_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MulRot(float q_c, float q_s, float r_c, float r_s) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Rot r_v;
	r_v.c = r_c;
	r_v.s = r_s;
	b2Rot result = b2MulRot(q_v, r_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2InvMulRot(float a_c, float a_s, float b_c, float b_s) {
	b2Rot a_v;
	a_v.c = a_c;
	a_v.s = a_s;
	b2Rot b_v;
	b_v.c = b_c;
	b_v.s = b_s;
	b2Rot result = b2InvMulRot(a_v, b_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API float hb_b2RelativeAngle(float a_c, float a_s, float b_c, float b_s) {
	b2Rot a_v;
	a_v.c = a_c;
	a_v.s = a_s;
	b2Rot b_v;
	b_v.c = b_c;
	b_v.s = b_s;
	float result = b2RelativeAngle(a_v, b_v);
	return result;
}

HB_API float hb_b2UnwindAngle(float radians) {
	float result = b2UnwindAngle(radians);
	return result;
}

HB_API void hb_b2RotateVector(float q_c, float q_s, float v_x, float v_y) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2RotateVector(q_v, v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2InvRotateVector(float q_c, float q_s, float v_x, float v_y) {
	b2Rot q_v;
	q_v.c = q_c;
	q_v.s = q_s;
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2InvRotateVector(q_v, v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2TransformPoint(float t_p_x, float t_p_y, float t_q_c, float t_q_s, float p_x, float p_y) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 result = b2TransformPoint(t_v, p_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2InvTransformPoint(float t_p_x, float t_p_y, float t_q_c, float t_q_s, float p_x, float p_y) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 result = b2InvTransformPoint(t_v, p_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MulTransforms(float A_p_x, float A_p_y, float A_q_c, float A_q_s, float B_p_x, float B_p_y, float B_q_c, float B_q_s) {
	b2Transform A_v;
	A_v.p.x = A_p_x;
	A_v.p.y = A_p_y;
	A_v.q.c = A_q_c;
	A_v.q.s = A_q_s;
	b2Transform B_v;
	B_v.p.x = B_p_x;
	B_v.p.y = B_p_y;
	B_v.q.c = B_q_c;
	B_v.q.s = B_q_s;
	b2Transform result = b2MulTransforms(A_v, B_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2InvMulTransforms(float A_p_x, float A_p_y, float A_q_c, float A_q_s, float B_p_x, float B_p_y, float B_q_c, float B_q_s) {
	b2Transform A_v;
	A_v.p.x = A_p_x;
	A_v.p.y = A_p_y;
	A_v.q.c = A_q_c;
	A_v.q.s = A_q_s;
	b2Transform B_v;
	B_v.p.x = B_p_x;
	B_v.p.y = B_p_y;
	B_v.q.c = B_q_c;
	B_v.q.s = B_q_s;
	b2Transform result = b2InvMulTransforms(A_v, B_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2ToPos(float v_x, float v_y) {
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2ToPos(v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2ToVec2(float p_x, float p_y) {
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 result = b2ToVec2(p_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API float hb_b2RoundDownFloat(float x) {
	float result = b2RoundDownFloat(x);
	return result;
}

HB_API float hb_b2RoundUpFloat(float x) {
	float result = b2RoundUpFloat(x);
	return result;
}

HB_API void hb_b2SubPos(float a_x, float a_y, float b_x, float b_y) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2SubPos(a_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2OffsetPos(float p_x, float p_y, float d_x, float d_y) {
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 d_v;
	d_v.x = d_x;
	d_v.y = d_y;
	b2Vec2 result = b2OffsetPos(p_v, d_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2LerpPos(float a_x, float a_y, float b_x, float b_y, float t) {
	b2Vec2 a_v;
	a_v.x = a_x;
	a_v.y = a_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2LerpPos(a_v, b_v, t);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2TransformWorldPoint(float t_p_x, float t_p_y, float t_q_c, float t_q_s, float p_x, float p_y) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 result = b2TransformWorldPoint(t_v, p_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2InvTransformWorldPoint(float t_p_x, float t_p_y, float t_q_c, float t_q_s, float p_x, float p_y) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Vec2 p_v;
	p_v.x = p_x;
	p_v.y = p_y;
	b2Vec2 result = b2InvTransformWorldPoint(t_v, p_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2InvMulWorldTransforms(float A_p_x, float A_p_y, float A_q_c, float A_q_s, float B_p_x, float B_p_y, float B_q_c, float B_q_s) {
	b2Transform A_v;
	A_v.p.x = A_p_x;
	A_v.p.y = A_p_y;
	A_v.q.c = A_q_c;
	A_v.q.s = A_q_s;
	b2Transform B_v;
	B_v.p.x = B_p_x;
	B_v.p.y = B_p_y;
	B_v.q.c = B_q_c;
	B_v.q.s = B_q_s;
	b2Transform result = b2InvMulWorldTransforms(A_v, B_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2MulWorldTransforms(float A_p_x, float A_p_y, float A_q_c, float A_q_s, float B_p_x, float B_p_y, float B_q_c, float B_q_s) {
	b2Transform A_v;
	A_v.p.x = A_p_x;
	A_v.p.y = A_p_y;
	A_v.q.c = A_q_c;
	A_v.q.s = A_q_s;
	b2Transform B_v;
	B_v.p.x = B_p_x;
	B_v.p.y = B_p_y;
	B_v.q.c = B_q_c;
	B_v.q.s = B_q_s;
	b2Transform result = b2MulWorldTransforms(A_v, B_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2ToRelativeTransform(float t_p_x, float t_p_y, float t_q_c, float t_q_s, float base_x, float base_y) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Vec2 base_v;
	base_v.x = base_x;
	base_v.y = base_y;
	b2Transform result = b2ToRelativeTransform(t_v, base_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2MakeWorldTransform(float t_p_x, float t_p_y, float t_q_c, float t_q_s) {
	b2Transform t_v;
	t_v.p.x = t_p_x;
	t_v.p.y = t_p_y;
	t_v.q.c = t_q_c;
	t_v.q.s = t_q_s;
	b2Transform result = b2MakeWorldTransform(t_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2MulMV(float A_cx_x, float A_cx_y, float A_cy_x, float A_cy_y, float v_x, float v_y) {
	b2Mat22 A_v;
	A_v.cx.x = A_cx_x;
	A_v.cx.y = A_cx_y;
	A_v.cy.x = A_cy_x;
	A_v.cy.y = A_cy_y;
	b2Vec2 v_v;
	v_v.x = v_x;
	v_v.y = v_y;
	b2Vec2 result = b2MulMV(A_v, v_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2GetInverse22(float A_cx_x, float A_cx_y, float A_cy_x, float A_cy_y) {
	b2Mat22 A_v;
	A_v.cx.x = A_cx_x;
	A_v.cx.y = A_cx_y;
	A_v.cy.x = A_cy_x;
	A_v.cy.y = A_cy_y;
	b2Mat22 result = b2GetInverse22(A_v);
	hb_begin(&hb_call);
	hb_wr_b2Mat22(&hb_call, &result);
}

HB_API void hb_b2Solve22(float A_cx_x, float A_cx_y, float A_cy_x, float A_cy_y, float b_x, float b_y) {
	b2Mat22 A_v;
	A_v.cx.x = A_cx_x;
	A_v.cx.y = A_cx_y;
	A_v.cy.x = A_cy_x;
	A_v.cy.y = A_cy_y;
	b2Vec2 b_v;
	b_v.x = b_x;
	b_v.y = b_y;
	b2Vec2 result = b2Solve22(A_v, b_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API int32_t hb_b2AABB_Contains(float a_lowerBound_x, float a_lowerBound_y, float a_upperBound_x, float a_upperBound_y, float b_lowerBound_x, float b_lowerBound_y, float b_upperBound_x, float b_upperBound_y) {
	b2AABB a_v;
	a_v.lowerBound.x = a_lowerBound_x;
	a_v.lowerBound.y = a_lowerBound_y;
	a_v.upperBound.x = a_upperBound_x;
	a_v.upperBound.y = a_upperBound_y;
	b2AABB b_v;
	b_v.lowerBound.x = b_lowerBound_x;
	b_v.lowerBound.y = b_lowerBound_y;
	b_v.upperBound.x = b_upperBound_x;
	b_v.upperBound.y = b_upperBound_y;
	bool result = b2AABB_Contains(a_v, b_v);
	return result ? 1 : 0;
}

HB_API void hb_b2AABB_Center(float a_lowerBound_x, float a_lowerBound_y, float a_upperBound_x, float a_upperBound_y) {
	b2AABB a_v;
	a_v.lowerBound.x = a_lowerBound_x;
	a_v.lowerBound.y = a_lowerBound_y;
	a_v.upperBound.x = a_upperBound_x;
	a_v.upperBound.y = a_upperBound_y;
	b2Vec2 result = b2AABB_Center(a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2AABB_Extents(float a_lowerBound_x, float a_lowerBound_y, float a_upperBound_x, float a_upperBound_y) {
	b2AABB a_v;
	a_v.lowerBound.x = a_lowerBound_x;
	a_v.lowerBound.y = a_lowerBound_y;
	a_v.upperBound.x = a_upperBound_x;
	a_v.upperBound.y = a_upperBound_y;
	b2Vec2 result = b2AABB_Extents(a_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2AABB_Union(float a_lowerBound_x, float a_lowerBound_y, float a_upperBound_x, float a_upperBound_y, float b_lowerBound_x, float b_lowerBound_y, float b_upperBound_x, float b_upperBound_y) {
	b2AABB a_v;
	a_v.lowerBound.x = a_lowerBound_x;
	a_v.lowerBound.y = a_lowerBound_y;
	a_v.upperBound.x = a_upperBound_x;
	a_v.upperBound.y = a_upperBound_y;
	b2AABB b_v;
	b_v.lowerBound.x = b_lowerBound_x;
	b_v.lowerBound.y = b_lowerBound_y;
	b_v.upperBound.x = b_upperBound_x;
	b_v.upperBound.y = b_upperBound_y;
	b2AABB result = b2AABB_Union(a_v, b_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API int32_t hb_b2AABB_Overlaps(float a_lowerBound_x, float a_lowerBound_y, float a_upperBound_x, float a_upperBound_y, float b_lowerBound_x, float b_lowerBound_y, float b_upperBound_x, float b_upperBound_y) {
	b2AABB a_v;
	a_v.lowerBound.x = a_lowerBound_x;
	a_v.lowerBound.y = a_lowerBound_y;
	a_v.upperBound.x = a_upperBound_x;
	a_v.upperBound.y = a_upperBound_y;
	b2AABB b_v;
	b_v.lowerBound.x = b_lowerBound_x;
	b_v.lowerBound.y = b_lowerBound_y;
	b_v.upperBound.x = b_upperBound_x;
	b_v.upperBound.y = b_upperBound_y;
	bool result = b2AABB_Overlaps(a_v, b_v);
	return result ? 1 : 0;
}

HB_API void hb_b2MakeAABB(int32_t count, float radius) {
	hb_begin(&hb_call);
	b2Vec2 *points_v = (b2Vec2 *)hb_scratch(0, (size_t)(count > 0 ? count : 1) * sizeof(b2Vec2));
	for (int32_t k = 0; k < count; k++) {
		points_v[k].x = hb_rf(&hb_call);
		points_v[k].y = hb_rf(&hb_call);
	}
	b2AABB result = b2MakeAABB(points_v, (int)count, radius);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API float hb_b2PlaneSeparation(float plane_normal_x, float plane_normal_y, float plane_offset, float point_x, float point_y) {
	b2Plane plane_v;
	plane_v.normal.x = plane_normal_x;
	plane_v.normal.y = plane_normal_y;
	plane_v.offset = plane_offset;
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	float result = b2PlaneSeparation(plane_v, point_v);
	return result;
}

HB_API float hb_b2SpringDamper(float hertz, float dampingRatio, float position, float velocity, float timeStep) {
	float result = b2SpringDamper(hertz, dampingRatio, position, velocity, timeStep);
	return result;
}

HB_API void hb_b2SetLengthUnitsPerMeter(float lengthUnits) {
	b2SetLengthUnitsPerMeter(lengthUnits);
}

HB_API float hb_b2GetLengthUnitsPerMeter(void) {
	float result = b2GetLengthUnitsPerMeter();
	return result;
}

HB_API int32_t hb_b2IsValidRay(void) {
	hb_begin(&hb_call);
	b2RayCastInput input_v;
	hb_rd_b2RayCastInput(&hb_call, &input_v);
	bool result = b2IsValidRay(&input_v);
	return result ? 1 : 0;
}

HB_API void hb_b2MakePolygon(float radius) {
	hb_begin(&hb_call);
	b2Hull hull_v;
	hb_rd_b2Hull(&hb_call, &hull_v);
	b2Polygon result = b2MakePolygon(&hull_v, radius);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeOffsetPolygon(float position_x, float position_y, float rotation_c, float rotation_s) {
	hb_begin(&hb_call);
	b2Hull hull_v;
	hb_rd_b2Hull(&hb_call, &hull_v);
	b2Vec2 position_v;
	position_v.x = position_x;
	position_v.y = position_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2Polygon result = b2MakeOffsetPolygon(&hull_v, position_v, rotation_v);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeOffsetRoundedPolygon(float position_x, float position_y, float rotation_c, float rotation_s, float radius) {
	hb_begin(&hb_call);
	b2Hull hull_v;
	hb_rd_b2Hull(&hb_call, &hull_v);
	b2Vec2 position_v;
	position_v.x = position_x;
	position_v.y = position_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2Polygon result = b2MakeOffsetRoundedPolygon(&hull_v, position_v, rotation_v, radius);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeSquare(float halfWidth) {
	b2Polygon result = b2MakeSquare(halfWidth);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeBox(float halfWidth, float halfHeight) {
	b2Polygon result = b2MakeBox(halfWidth, halfHeight);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeRoundedBox(float halfWidth, float halfHeight, float radius) {
	b2Polygon result = b2MakeRoundedBox(halfWidth, halfHeight, radius);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeOffsetBox(float halfWidth, float halfHeight, float center_x, float center_y, float rotation_c, float rotation_s) {
	b2Vec2 center_v;
	center_v.x = center_x;
	center_v.y = center_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2Polygon result = b2MakeOffsetBox(halfWidth, halfHeight, center_v, rotation_v);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2MakeOffsetRoundedBox(float halfWidth, float halfHeight, float center_x, float center_y, float rotation_c, float rotation_s, float radius) {
	b2Vec2 center_v;
	center_v.x = center_x;
	center_v.y = center_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2Polygon result = b2MakeOffsetRoundedBox(halfWidth, halfHeight, center_v, rotation_v, radius);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2TransformPolygon(float transform_p_x, float transform_p_y, float transform_q_c, float transform_q_s) {
	hb_begin(&hb_call);
	b2Transform transform_v;
	transform_v.p.x = transform_p_x;
	transform_v.p.y = transform_p_y;
	transform_v.q.c = transform_q_c;
	transform_v.q.s = transform_q_s;
	b2Polygon polygon_v;
	hb_rd_b2Polygon(&hb_call, &polygon_v);
	b2Polygon result = b2TransformPolygon(transform_v, &polygon_v);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2ComputeCircleMass(float density) {
	hb_begin(&hb_call);
	b2Circle shape_v;
	hb_rd_b2Circle(&hb_call, &shape_v);
	b2MassData result = b2ComputeCircleMass(&shape_v, density);
	hb_begin(&hb_call);
	hb_wr_b2MassData(&hb_call, &result);
}

HB_API void hb_b2ComputeCapsuleMass(float density) {
	hb_begin(&hb_call);
	b2Capsule shape_v;
	hb_rd_b2Capsule(&hb_call, &shape_v);
	b2MassData result = b2ComputeCapsuleMass(&shape_v, density);
	hb_begin(&hb_call);
	hb_wr_b2MassData(&hb_call, &result);
}

HB_API void hb_b2ComputePolygonMass(float density) {
	hb_begin(&hb_call);
	b2Polygon shape_v;
	hb_rd_b2Polygon(&hb_call, &shape_v);
	b2MassData result = b2ComputePolygonMass(&shape_v, density);
	hb_begin(&hb_call);
	hb_wr_b2MassData(&hb_call, &result);
}

HB_API void hb_b2ComputeCircleBounds(float transform_p_x, float transform_p_y, float transform_q_c, float transform_q_s) {
	hb_begin(&hb_call);
	b2Circle shape_v;
	hb_rd_b2Circle(&hb_call, &shape_v);
	b2Transform transform_v;
	transform_v.p.x = transform_p_x;
	transform_v.p.y = transform_p_y;
	transform_v.q.c = transform_q_c;
	transform_v.q.s = transform_q_s;
	b2AABB result = b2ComputeCircleBounds(&shape_v, transform_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API void hb_b2ComputeCapsuleBounds(float transform_p_x, float transform_p_y, float transform_q_c, float transform_q_s) {
	hb_begin(&hb_call);
	b2Capsule shape_v;
	hb_rd_b2Capsule(&hb_call, &shape_v);
	b2Transform transform_v;
	transform_v.p.x = transform_p_x;
	transform_v.p.y = transform_p_y;
	transform_v.q.c = transform_q_c;
	transform_v.q.s = transform_q_s;
	b2AABB result = b2ComputeCapsuleBounds(&shape_v, transform_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API void hb_b2ComputePolygonBounds(float transform_p_x, float transform_p_y, float transform_q_c, float transform_q_s) {
	hb_begin(&hb_call);
	b2Polygon shape_v;
	hb_rd_b2Polygon(&hb_call, &shape_v);
	b2Transform transform_v;
	transform_v.p.x = transform_p_x;
	transform_v.p.y = transform_p_y;
	transform_v.q.c = transform_q_c;
	transform_v.q.s = transform_q_s;
	b2AABB result = b2ComputePolygonBounds(&shape_v, transform_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API void hb_b2ComputeSegmentBounds(float transform_p_x, float transform_p_y, float transform_q_c, float transform_q_s) {
	hb_begin(&hb_call);
	b2Segment shape_v;
	hb_rd_b2Segment(&hb_call, &shape_v);
	b2Transform transform_v;
	transform_v.p.x = transform_p_x;
	transform_v.p.y = transform_p_y;
	transform_v.q.c = transform_q_c;
	transform_v.q.s = transform_q_s;
	b2AABB result = b2ComputeSegmentBounds(&shape_v, transform_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API int32_t hb_b2PointInCircle(float point_x, float point_y) {
	hb_begin(&hb_call);
	b2Circle shape_v;
	hb_rd_b2Circle(&hb_call, &shape_v);
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	bool result = b2PointInCircle(&shape_v, point_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2PointInCapsule(float point_x, float point_y) {
	hb_begin(&hb_call);
	b2Capsule shape_v;
	hb_rd_b2Capsule(&hb_call, &shape_v);
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	bool result = b2PointInCapsule(&shape_v, point_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2PointInPolygon(float point_x, float point_y) {
	hb_begin(&hb_call);
	b2Polygon shape_v;
	hb_rd_b2Polygon(&hb_call, &shape_v);
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	bool result = b2PointInPolygon(&shape_v, point_v);
	return result ? 1 : 0;
}

HB_API void hb_b2CastRayCircle(void) {
	hb_begin(&hb_call);
	b2Circle shape_v;
	hb_rd_b2Circle(&hb_call, &shape_v);
	b2RayCastInput input_v;
	hb_rd_b2RayCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastRayCircle(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastRayCapsule(void) {
	hb_begin(&hb_call);
	b2Capsule shape_v;
	hb_rd_b2Capsule(&hb_call, &shape_v);
	b2RayCastInput input_v;
	hb_rd_b2RayCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastRayCapsule(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastRaySegment(int32_t oneSided) {
	hb_begin(&hb_call);
	b2Segment shape_v;
	hb_rd_b2Segment(&hb_call, &shape_v);
	b2RayCastInput input_v;
	hb_rd_b2RayCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastRaySegment(&shape_v, &input_v, oneSided != 0);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastRayPolygon(void) {
	hb_begin(&hb_call);
	b2Polygon shape_v;
	hb_rd_b2Polygon(&hb_call, &shape_v);
	b2RayCastInput input_v;
	hb_rd_b2RayCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastRayPolygon(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastShapeCircle(void) {
	hb_begin(&hb_call);
	b2Circle shape_v;
	hb_rd_b2Circle(&hb_call, &shape_v);
	b2ShapeCastInput input_v;
	hb_rd_b2ShapeCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastShapeCircle(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastShapeCapsule(void) {
	hb_begin(&hb_call);
	b2Capsule shape_v;
	hb_rd_b2Capsule(&hb_call, &shape_v);
	b2ShapeCastInput input_v;
	hb_rd_b2ShapeCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastShapeCapsule(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastShapeSegment(void) {
	hb_begin(&hb_call);
	b2Segment shape_v;
	hb_rd_b2Segment(&hb_call, &shape_v);
	b2ShapeCastInput input_v;
	hb_rd_b2ShapeCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastShapeSegment(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2CastShapePolygon(void) {
	hb_begin(&hb_call);
	b2Polygon shape_v;
	hb_rd_b2Polygon(&hb_call, &shape_v);
	b2ShapeCastInput input_v;
	hb_rd_b2ShapeCastInput(&hb_call, &input_v);
	b2CastOutput result = b2CastShapePolygon(&shape_v, &input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2ComputeHull(int32_t count) {
	hb_begin(&hb_call);
	b2Vec2 *points_v = (b2Vec2 *)hb_scratch(0, (size_t)(count > 0 ? count : 1) * sizeof(b2Vec2));
	for (int32_t k = 0; k < count; k++) {
		points_v[k].x = hb_rf(&hb_call);
		points_v[k].y = hb_rf(&hb_call);
	}
	b2Hull result = b2ComputeHull(points_v, (int)count);
	hb_begin(&hb_call);
	hb_wr_b2Hull(&hb_call, &result);
}

HB_API int32_t hb_b2ValidateHull(void) {
	hb_begin(&hb_call);
	b2Hull hull_v;
	hb_rd_b2Hull(&hb_call, &hull_v);
	bool result = b2ValidateHull(&hull_v);
	return result ? 1 : 0;
}

HB_API void hb_b2ComputeSegmentDistance(float p1_x, float p1_y, float q1_x, float q1_y, float p2_x, float p2_y, float q2_x, float q2_y) {
	b2Vec2 p1_v;
	p1_v.x = p1_x;
	p1_v.y = p1_y;
	b2Vec2 q1_v;
	q1_v.x = q1_x;
	q1_v.y = q1_y;
	b2Vec2 p2_v;
	p2_v.x = p2_x;
	p2_v.y = p2_y;
	b2Vec2 q2_v;
	q2_v.x = q2_x;
	q2_v.y = q2_y;
	b2SegmentDistanceResult result = b2ComputeSegmentDistance(p1_v, q1_v, p2_v, q2_v);
	hb_begin(&hb_call);
	hb_wr_b2SegmentDistanceResult(&hb_call, &result);
}

HB_API void hb_b2ComputeShapeDistance(int32_t simplexCapacity) {
	hb_begin(&hb_call);
	b2DistanceInput input_v;
	hb_rd_b2DistanceInput(&hb_call, &input_v);
	b2SimplexCache cache_v;
	hb_rd_b2SimplexCache(&hb_call, &cache_v);
	b2Simplex *simplexes_v = (b2Simplex *)hb_scratch(2, (size_t)(simplexCapacity > 0 ? simplexCapacity : 1) * sizeof(b2Simplex));
	b2DistanceOutput result = b2ComputeShapeDistance(&input_v, &cache_v, simplexes_v, (int)simplexCapacity);
	hb_begin(&hb_call);
	hb_wr_b2DistanceOutput(&hb_call, &result);
	hb_wr_b2SimplexCache(&hb_call, &cache_v);
	{
		int32_t filled = (result.simplexCount < simplexCapacity ? result.simplexCount : simplexCapacity);
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2Simplex(&hb_call, &simplexes_v[k]);
		}
	}
}

HB_API void hb_b2CastShape(void) {
	hb_begin(&hb_call);
	b2ShapeCastPairInput input_v;
	hb_rd_b2ShapeCastPairInput(&hb_call, &input_v);
	b2CastOutput result = b2CastShape(&input_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2MakeProxy(int32_t count, float radius) {
	hb_begin(&hb_call);
	b2Vec2 *points_v = (b2Vec2 *)hb_scratch(0, (size_t)(count > 0 ? count : 1) * sizeof(b2Vec2));
	for (int32_t k = 0; k < count; k++) {
		points_v[k].x = hb_rf(&hb_call);
		points_v[k].y = hb_rf(&hb_call);
	}
	b2ShapeProxy result = b2MakeProxy(points_v, (int)count, radius);
	hb_begin(&hb_call);
	hb_wr_b2ShapeProxy(&hb_call, &result);
}

HB_API void hb_b2MakeOffsetProxy(int32_t count, float radius, float position_x, float position_y, float rotation_c, float rotation_s) {
	hb_begin(&hb_call);
	b2Vec2 *points_v = (b2Vec2 *)hb_scratch(0, (size_t)(count > 0 ? count : 1) * sizeof(b2Vec2));
	for (int32_t k = 0; k < count; k++) {
		points_v[k].x = hb_rf(&hb_call);
		points_v[k].y = hb_rf(&hb_call);
	}
	b2Vec2 position_v;
	position_v.x = position_x;
	position_v.y = position_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2ShapeProxy result = b2MakeOffsetProxy(points_v, (int)count, radius, position_v, rotation_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeProxy(&hb_call, &result);
}

HB_API void hb_b2GetSweepTransform(float time) {
	hb_begin(&hb_call);
	b2Sweep sweep_v;
	hb_rd_b2Sweep(&hb_call, &sweep_v);
	b2Transform result = b2GetSweepTransform(&sweep_v, time);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2ComputeTimeOfImpact(void) {
	hb_begin(&hb_call);
	b2TOIInput input_v;
	hb_rd_b2TOIInput(&hb_call, &input_v);
	b2TOIOutput result = b2ComputeTimeOfImpact(&input_v);
	hb_begin(&hb_call);
	hb_wr_b2TOIOutput(&hb_call, &result);
}

HB_API void hb_b2CollideCircles(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Circle circleA_v;
	hb_rd_b2Circle(&hb_call, &circleA_v);
	b2Circle circleB_v;
	hb_rd_b2Circle(&hb_call, &circleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideCircles(&circleA_v, &circleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideCapsuleAndCircle(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Capsule capsuleA_v;
	hb_rd_b2Capsule(&hb_call, &capsuleA_v);
	b2Circle circleB_v;
	hb_rd_b2Circle(&hb_call, &circleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideCapsuleAndCircle(&capsuleA_v, &circleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideSegmentAndCircle(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Segment segmentA_v;
	hb_rd_b2Segment(&hb_call, &segmentA_v);
	b2Circle circleB_v;
	hb_rd_b2Circle(&hb_call, &circleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideSegmentAndCircle(&segmentA_v, &circleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollidePolygonAndCircle(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Polygon polygonA_v;
	hb_rd_b2Polygon(&hb_call, &polygonA_v);
	b2Circle circleB_v;
	hb_rd_b2Circle(&hb_call, &circleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollidePolygonAndCircle(&polygonA_v, &circleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideCapsules(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Capsule capsuleA_v;
	hb_rd_b2Capsule(&hb_call, &capsuleA_v);
	b2Capsule capsuleB_v;
	hb_rd_b2Capsule(&hb_call, &capsuleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideCapsules(&capsuleA_v, &capsuleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideSegmentAndCapsule(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Segment segmentA_v;
	hb_rd_b2Segment(&hb_call, &segmentA_v);
	b2Capsule capsuleB_v;
	hb_rd_b2Capsule(&hb_call, &capsuleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideSegmentAndCapsule(&segmentA_v, &capsuleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollidePolygonAndCapsule(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Polygon polygonA_v;
	hb_rd_b2Polygon(&hb_call, &polygonA_v);
	b2Capsule capsuleB_v;
	hb_rd_b2Capsule(&hb_call, &capsuleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollidePolygonAndCapsule(&polygonA_v, &capsuleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollidePolygons(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Polygon polygonA_v;
	hb_rd_b2Polygon(&hb_call, &polygonA_v);
	b2Polygon polygonB_v;
	hb_rd_b2Polygon(&hb_call, &polygonB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollidePolygons(&polygonA_v, &polygonB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideSegmentAndPolygon(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2Segment segmentA_v;
	hb_rd_b2Segment(&hb_call, &segmentA_v);
	b2Polygon polygonB_v;
	hb_rd_b2Polygon(&hb_call, &polygonB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideSegmentAndPolygon(&segmentA_v, &polygonB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideChainSegmentAndCircle(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2ChainSegment segmentA_v;
	hb_rd_b2ChainSegment(&hb_call, &segmentA_v);
	b2Circle circleB_v;
	hb_rd_b2Circle(&hb_call, &circleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2LocalManifold result = b2CollideChainSegmentAndCircle(&segmentA_v, &circleB_v, xf_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
}

HB_API void hb_b2CollideChainSegmentAndCapsule(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2ChainSegment segmentA_v;
	hb_rd_b2ChainSegment(&hb_call, &segmentA_v);
	b2Capsule capsuleB_v;
	hb_rd_b2Capsule(&hb_call, &capsuleB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2SimplexCache cache_v;
	hb_rd_b2SimplexCache(&hb_call, &cache_v);
	b2LocalManifold result = b2CollideChainSegmentAndCapsule(&segmentA_v, &capsuleB_v, xf_v, &cache_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
	hb_wr_b2SimplexCache(&hb_call, &cache_v);
}

HB_API void hb_b2CollideChainSegmentAndPolygon(float xf_p_x, float xf_p_y, float xf_q_c, float xf_q_s) {
	hb_begin(&hb_call);
	b2ChainSegment segmentA_v;
	hb_rd_b2ChainSegment(&hb_call, &segmentA_v);
	b2Polygon polygonB_v;
	hb_rd_b2Polygon(&hb_call, &polygonB_v);
	b2Transform xf_v;
	xf_v.p.x = xf_p_x;
	xf_v.p.y = xf_p_y;
	xf_v.q.c = xf_q_c;
	xf_v.q.s = xf_q_s;
	b2SimplexCache cache_v;
	hb_rd_b2SimplexCache(&hb_call, &cache_v);
	b2LocalManifold result = b2CollideChainSegmentAndPolygon(&segmentA_v, &polygonB_v, xf_v, &cache_v);
	hb_begin(&hb_call);
	hb_wr_b2LocalManifold(&hb_call, &result);
	hb_wr_b2SimplexCache(&hb_call, &cache_v);
}

HB_API void hb_b2SolvePlanes(float targetDelta_x, float targetDelta_y, int32_t count) {
	hb_begin(&hb_call);
	b2Vec2 targetDelta_v;
	targetDelta_v.x = targetDelta_x;
	targetDelta_v.y = targetDelta_y;
	b2CollisionPlane *planes_v = (b2CollisionPlane *)hb_scratch(1, (size_t)(count > 0 ? count : 1) * sizeof(b2CollisionPlane));
	for (int32_t k = 0; k < count; k++) {
		hb_rd_b2CollisionPlane(&hb_call, &planes_v[k]);
	}
	b2PlaneSolverResult result = b2SolvePlanes(targetDelta_v, planes_v, (int)count);
	hb_begin(&hb_call);
	hb_wr_b2PlaneSolverResult(&hb_call, &result);
	for (int32_t k = 0; k < count; k++) {
		hb_wr_b2CollisionPlane(&hb_call, &planes_v[k]);
	}
}

HB_API void hb_b2ClipVector(float vector_x, float vector_y, int32_t count) {
	hb_begin(&hb_call);
	b2Vec2 vector_v;
	vector_v.x = vector_x;
	vector_v.y = vector_y;
	b2CollisionPlane *planes_v = (b2CollisionPlane *)hb_scratch(1, (size_t)(count > 0 ? count : 1) * sizeof(b2CollisionPlane));
	for (int32_t k = 0; k < count; k++) {
		hb_rd_b2CollisionPlane(&hb_call, &planes_v[k]);
	}
	b2Vec2 result = b2ClipVector(vector_v, planes_v, (int)count);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2DefaultWorldDef(void) {
	b2WorldDef result = b2DefaultWorldDef();
	hb_begin(&hb_call);
	hb_wr_b2WorldDef(&hb_call, &result);
}

HB_API void hb_b2DefaultBodyDef(void) {
	b2BodyDef result = b2DefaultBodyDef();
	hb_begin(&hb_call);
	hb_wr_b2BodyDef(&hb_call, &result);
}

HB_API void hb_b2DefaultFilter(void) {
	b2Filter result = b2DefaultFilter();
	hb_begin(&hb_call);
	hb_wr_b2Filter(&hb_call, &result);
}

HB_API void hb_b2DefaultQueryFilter(void) {
	b2QueryFilter result = b2DefaultQueryFilter();
	hb_begin(&hb_call);
	hb_wr_b2QueryFilter(&hb_call, &result);
}

HB_API void hb_b2DefaultSurfaceMaterial(void) {
	b2SurfaceMaterial result = b2DefaultSurfaceMaterial();
	hb_begin(&hb_call);
	hb_wr_b2SurfaceMaterial(&hb_call, &result);
}

HB_API void hb_b2DefaultShapeDef(void) {
	b2ShapeDef result = b2DefaultShapeDef();
	hb_begin(&hb_call);
	hb_wr_b2ShapeDef(&hb_call, &result);
}

HB_API void hb_b2DefaultChainDef(void) {
	b2ChainDef result = b2DefaultChainDef();
	hb_begin(&hb_call);
	hb_wr_b2ChainDef(&hb_call, &result);
}

HB_API void hb_b2DefaultDistanceJointDef(void) {
	b2DistanceJointDef result = b2DefaultDistanceJointDef();
	hb_begin(&hb_call);
	hb_wr_b2DistanceJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultFilterJointDef(void) {
	b2FilterJointDef result = b2DefaultFilterJointDef();
	hb_begin(&hb_call);
	hb_wr_b2FilterJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultMotorJointDef(void) {
	b2MotorJointDef result = b2DefaultMotorJointDef();
	hb_begin(&hb_call);
	hb_wr_b2MotorJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultPrismaticJointDef(void) {
	b2PrismaticJointDef result = b2DefaultPrismaticJointDef();
	hb_begin(&hb_call);
	hb_wr_b2PrismaticJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultRevoluteJointDef(void) {
	b2RevoluteJointDef result = b2DefaultRevoluteJointDef();
	hb_begin(&hb_call);
	hb_wr_b2RevoluteJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultWeldJointDef(void) {
	b2WeldJointDef result = b2DefaultWeldJointDef();
	hb_begin(&hb_call);
	hb_wr_b2WeldJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultWheelJointDef(void) {
	b2WheelJointDef result = b2DefaultWheelJointDef();
	hb_begin(&hb_call);
	hb_wr_b2WheelJointDef(&hb_call, &result);
}

HB_API void hb_b2DefaultExplosionDef(void) {
	b2ExplosionDef result = b2DefaultExplosionDef();
	hb_begin(&hb_call);
	hb_wr_b2ExplosionDef(&hb_call, &result);
}

HB_API int32_t hb_b2GetGraphColor(int32_t index) {
	b2HexColor result = b2GetGraphColor((int)index);
	return result;
}

HB_API void hb_b2DefaultDebugDraw(void) {
	b2DebugDraw result = b2DefaultDebugDraw();
	hb_begin(&hb_call);
	hb_wr_b2DebugDraw(&hb_call, &result);
}

HB_API void hb_b2CreateWorld(void) {
	hb_begin(&hb_call);
	b2WorldDef def_v;
	hb_rd_b2WorldDef(&hb_call, &def_v);
	b2WorldId result = b2CreateWorld(&def_v);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API void hb_b2DestroyWorld(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2DestroyWorld(worldId_v);
}

HB_API int32_t hb_b2World_IsValid(int32_t id_index1, int32_t id_generation) {
	b2WorldId id_v;
	id_v.index1 = id_index1;
	id_v.generation = id_generation;
	bool result = b2World_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API void hb_b2World_Step(int32_t worldId_index1, int32_t worldId_generation, float timeStep, int32_t subStepCount) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	hb_stepping = worldId_v.index1;
	b2World_Step(worldId_v, timeStep, (int)subStepCount);
	hb_stepping = 0;
}

HB_API void hb_b2World_Draw(int32_t worldId_index1, int32_t worldId_generation, int32_t slot) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2DebugDraw draw_v;
	hb_rd_b2DebugDraw(&hb_call, &draw_v);
	draw_v.context = (void *)(intptr_t)slot;
	b2World_Draw(worldId_v, &draw_v);
}

HB_API void hb_b2World_GetBounds(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2AABB result = b2World_GetBounds(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API void hb_b2World_GetBodyEvents(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2BodyEvents result = b2World_GetBodyEvents(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2BodyEvents(&hb_call, &result);
}

HB_API void hb_b2World_GetSensorEvents(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2SensorEvents result = b2World_GetSensorEvents(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2SensorEvents(&hb_call, &result);
}

HB_API void hb_b2World_GetContactEvents(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2ContactEvents result = b2World_GetContactEvents(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2ContactEvents(&hb_call, &result);
}

HB_API void hb_b2World_GetJointEvents(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2JointEvents result = b2World_GetJointEvents(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2JointEvents(&hb_call, &result);
}

HB_API void hb_b2World_OverlapAABB(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, float aabb_lowerBound_x, float aabb_lowerBound_y, float aabb_upperBound_x, float aabb_upperBound_y, int32_t fcn, int32_t context) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2AABB aabb_v;
	aabb_v.lowerBound.x = aabb_lowerBound_x;
	aabb_v.lowerBound.y = aabb_lowerBound_y;
	aabb_v.upperBound.x = aabb_upperBound_x;
	aabb_v.upperBound.y = aabb_upperBound_y;
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2TreeStats result = b2World_OverlapAABB(worldId_v, origin_v, aabb_v, filter_v, fcn ? hb_tr_b2OverlapResultCallbackFcn : NULL, (void *)(intptr_t)context);
	hb_begin(&hb_call);
	hb_wr_b2TreeStats(&hb_call, &result);
}

HB_API void hb_b2World_OverlapShape(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, int32_t fcn, int32_t context) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2ShapeProxy proxy_v;
	hb_rd_b2ShapeProxy(&hb_call, &proxy_v);
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2TreeStats result = b2World_OverlapShape(worldId_v, origin_v, &proxy_v, filter_v, fcn ? hb_tr_b2OverlapResultCallbackFcn : NULL, (void *)(intptr_t)context);
	hb_begin(&hb_call);
	hb_wr_b2TreeStats(&hb_call, &result);
}

HB_API void hb_b2World_CastRay(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, float translation_x, float translation_y, int32_t fcn, int32_t context) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2Vec2 translation_v;
	translation_v.x = translation_x;
	translation_v.y = translation_y;
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2TreeStats result = b2World_CastRay(worldId_v, origin_v, translation_v, filter_v, fcn ? hb_tr_b2CastResultCallbackFcn : NULL, (void *)(intptr_t)context);
	hb_begin(&hb_call);
	hb_wr_b2TreeStats(&hb_call, &result);
}

HB_API void hb_b2World_CastRayClosest(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, float translation_x, float translation_y) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2Vec2 translation_v;
	translation_v.x = translation_x;
	translation_v.y = translation_y;
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2RayResult result = b2World_CastRayClosest(worldId_v, origin_v, translation_v, filter_v);
	hb_begin(&hb_call);
	hb_wr_b2RayResult(&hb_call, &result);
}

HB_API void hb_b2World_CastShape(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, float translation_x, float translation_y, int32_t fcn, int32_t context) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2ShapeProxy proxy_v;
	hb_rd_b2ShapeProxy(&hb_call, &proxy_v);
	b2Vec2 translation_v;
	translation_v.x = translation_x;
	translation_v.y = translation_y;
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2TreeStats result = b2World_CastShape(worldId_v, origin_v, &proxy_v, translation_v, filter_v, fcn ? hb_tr_b2CastResultCallbackFcn : NULL, (void *)(intptr_t)context);
	hb_begin(&hb_call);
	hb_wr_b2TreeStats(&hb_call, &result);
}

HB_API float hb_b2World_CastMover(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, float translation_x, float translation_y) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2Capsule mover_v;
	hb_rd_b2Capsule(&hb_call, &mover_v);
	b2Vec2 translation_v;
	translation_v.x = translation_x;
	translation_v.y = translation_y;
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	float result = b2World_CastMover(worldId_v, origin_v, &mover_v, translation_v, filter_v);
	return result;
}

HB_API void hb_b2World_CollideMover(int32_t worldId_index1, int32_t worldId_generation, float origin_x, float origin_y, int32_t fcn, int32_t context) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2Capsule mover_v;
	hb_rd_b2Capsule(&hb_call, &mover_v);
	b2QueryFilter filter_v;
	hb_rd_b2QueryFilter(&hb_call, &filter_v);
	b2World_CollideMover(worldId_v, origin_v, &mover_v, filter_v, fcn ? hb_tr_b2PlaneResultCallbackFcn : NULL, (void *)(intptr_t)context);
}

HB_API void hb_b2World_EnableSleeping(int32_t worldId_index1, int32_t worldId_generation, int32_t flag) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_EnableSleeping(worldId_v, flag != 0);
}

HB_API int32_t hb_b2World_IsSleepingEnabled(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	bool result = b2World_IsSleepingEnabled(worldId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2World_EnableContinuous(int32_t worldId_index1, int32_t worldId_generation, int32_t flag) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_EnableContinuous(worldId_v, flag != 0);
}

HB_API int32_t hb_b2World_IsContinuousEnabled(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	bool result = b2World_IsContinuousEnabled(worldId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2World_SetRestitutionThreshold(int32_t worldId_index1, int32_t worldId_generation, float value) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetRestitutionThreshold(worldId_v, value);
}

HB_API float hb_b2World_GetRestitutionThreshold(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	float result = b2World_GetRestitutionThreshold(worldId_v);
	return result;
}

HB_API void hb_b2World_SetRestitutionIterations(int32_t worldId_index1, int32_t worldId_generation, int32_t iterations) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetRestitutionIterations(worldId_v, (int)iterations);
}

HB_API int32_t hb_b2World_GetRestitutionIterations(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	int result = b2World_GetRestitutionIterations(worldId_v);
	return result;
}

HB_API void hb_b2World_EnableRestitutionPropagation(int32_t worldId_index1, int32_t worldId_generation, int32_t flag) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_EnableRestitutionPropagation(worldId_v, flag != 0);
}

HB_API int32_t hb_b2World_IsRestitutionPropagationEnabled(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	bool result = b2World_IsRestitutionPropagationEnabled(worldId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2World_SetHitEventThreshold(int32_t worldId_index1, int32_t worldId_generation, float value) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetHitEventThreshold(worldId_v, value);
}

HB_API float hb_b2World_GetHitEventThreshold(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	float result = b2World_GetHitEventThreshold(worldId_v);
	return result;
}

HB_API void hb_b2World_SetCustomFilterCallback(int32_t worldId_index1, int32_t worldId_generation, int32_t fcn, int32_t context) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetCustomFilterCallback(worldId_v, fcn ? hb_tr_b2CustomFilterCallbackFcn : NULL, (void *)(intptr_t)context);
}

HB_API void hb_b2World_SetPreSolveCallback(int32_t worldId_index1, int32_t worldId_generation, int32_t preSolveFcn, int32_t preContinuousFcn, int32_t context) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetPreSolveCallback(worldId_v, preSolveFcn ? hb_tr_b2PreSolveCallbackFcn : NULL, preContinuousFcn ? hb_tr_b2PreContinuousCallbackFcn : NULL, (void *)(intptr_t)context);
}

HB_API void hb_b2World_SetGravity(int32_t worldId_index1, int32_t worldId_generation, float gravity_x, float gravity_y) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 gravity_v;
	gravity_v.x = gravity_x;
	gravity_v.y = gravity_y;
	b2World_SetGravity(worldId_v, gravity_v);
}

HB_API void hb_b2World_GetGravity(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Vec2 result = b2World_GetGravity(worldId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2World_Explode(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2ExplosionDef explosionDef_v;
	hb_rd_b2ExplosionDef(&hb_call, &explosionDef_v);
	b2World_Explode(worldId_v, &explosionDef_v);
}

HB_API void hb_b2World_SetContactTuning(int32_t worldId_index1, int32_t worldId_generation, float hertz, float dampingRatio, float pushSpeed) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetContactTuning(worldId_v, hertz, dampingRatio, pushSpeed);
}

HB_API void hb_b2World_GetContactTuning(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	float hertz_v = 0;
	float dampingRatio_v = 0;
	float pushSpeed_v = 0;
	b2World_GetContactTuning(worldId_v, &hertz_v, &dampingRatio_v, &pushSpeed_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, hertz_v);
	hb_wf(&hb_call, dampingRatio_v);
	hb_wf(&hb_call, pushSpeed_v);
}

HB_API void hb_b2World_SetContactRecycleDistance(int32_t worldId_index1, int32_t worldId_generation, float recycleDistance) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetContactRecycleDistance(worldId_v, recycleDistance);
}

HB_API float hb_b2World_GetContactRecycleDistance(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	float result = b2World_GetContactRecycleDistance(worldId_v);
	return result;
}

HB_API void hb_b2World_SetMaxLinearSpeed(int32_t worldId_index1, int32_t worldId_generation, float maximumLinearSpeed) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetMaxLinearSpeed(worldId_v, maximumLinearSpeed);
}

HB_API float hb_b2World_GetMaxLinearSpeed(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	float result = b2World_GetMaxLinearSpeed(worldId_v);
	return result;
}

HB_API void hb_b2World_EnableWarmStarting(int32_t worldId_index1, int32_t worldId_generation, int32_t flag) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_EnableWarmStarting(worldId_v, flag != 0);
}

HB_API int32_t hb_b2World_IsWarmStartingEnabled(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	bool result = b2World_IsWarmStartingEnabled(worldId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2World_EnableSSE2Fallback(int32_t worldId_index1, int32_t worldId_generation, int32_t flag) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_EnableSSE2Fallback(worldId_v, flag != 0);
}

HB_API int32_t hb_b2World_GetAwakeBodyCount(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	int result = b2World_GetAwakeBodyCount(worldId_v);
	return result;
}

HB_API void hb_b2World_GetProfile(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Profile result = b2World_GetProfile(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2Profile(&hb_call, &result);
}

HB_API void hb_b2World_GetCounters(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Counters result = b2World_GetCounters(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2Counters(&hb_call, &result);
}

HB_API void hb_b2World_GetMaxCapacity(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2Capacity result = b2World_GetMaxCapacity(worldId_v);
	hb_begin(&hb_call);
	hb_wr_b2Capacity(&hb_call, &result);
}

HB_API void hb_b2World_SetFrictionCallback(int32_t worldId_index1, int32_t worldId_generation, int32_t callback) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetFrictionCallback(worldId_v, callback ? hb_tr_b2FrictionCallbackFcn : NULL);
}

HB_API void hb_b2World_SetRestitutionCallback(int32_t worldId_index1, int32_t worldId_generation, int32_t callback) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_SetRestitutionCallback(worldId_v, callback ? hb_tr_b2RestitutionCallbackFcn : NULL);
}

HB_API void hb_b2World_SetWorkerCount(int32_t worldId_index1, int32_t worldId_generation, int32_t count) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
#ifdef __EMSCRIPTEN__
	count = 1;
#endif
	b2World_SetWorkerCount(worldId_v, (int)count);
}

HB_API int32_t hb_b2World_GetWorkerCount(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	int result = b2World_GetWorkerCount(worldId_v);
	return result;
}

HB_API void hb_b2World_RebuildStaticTree(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2World_RebuildStaticTree(worldId_v);
}

HB_API void hb_b2World_GetStateHash(int32_t worldId_index1, int32_t worldId_generation) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	uint64_t result = b2World_GetStateHash(worldId_v);
	hb_begin(&hb_call);
	hb_wl(&hb_call, result);
}

HB_API int32_t hb_b2World_GetSnapshot(int32_t worldId_index1, int32_t worldId_generation, int32_t image_given, int32_t capacity) {
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	uint8_t *image_v = image_given ? (uint8_t *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1)) : NULL;
	int result = b2World_GetSnapshot(worldId_v, image_v, (int)capacity);
	hb_begin(&hb_call);
	if (image_v != NULL)
		hb_wbytes(&hb_call, image_v, result < capacity ? result : capacity);
	return result;
}

HB_API int32_t hb_b2World_RestoreFromSnapshot(int32_t worldId_index1, int32_t worldId_generation, int32_t size) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	const uint8_t *image_v = hb_rbytes(&hb_call, size, 1);
	bool result = b2World_RestoreFromSnapshot(worldId_v, image_v, (int)size);
	return result ? 1 : 0;
}

HB_API void hb_b2CreateWorldFromSnapshot(int32_t size, int32_t workerCount) {
	hb_begin(&hb_call);
	const uint8_t *image_v = hb_rbytes(&hb_call, size, 0);
#ifdef __EMSCRIPTEN__
	workerCount = 1;
#endif
	b2WorldId result = b2CreateWorldFromSnapshot(image_v, (int)size, (int)workerCount);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API void hb_b2CreateBody(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2BodyDef def_v;
	hb_rd_b2BodyDef(&hb_call, &def_v);
	b2BodyId result = b2CreateBody(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2BodyId(&hb_call, &result);
}

HB_API void hb_b2DestroyBody(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2DestroyBody(bodyId_v);
}

HB_API int32_t hb_b2Body_IsValid(int32_t id_index1, int32_t id_world0, int32_t id_generation) {
	b2BodyId id_v;
	id_v.index1 = id_index1;
	id_v.world0 = id_world0;
	id_v.generation = id_generation;
	bool result = b2Body_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2Body_GetType(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2BodyType result = b2Body_GetType(bodyId_v);
	return result;
}

HB_API void hb_b2Body_SetType(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t type) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetType(bodyId_v, (b2BodyType)type);
}

HB_API void hb_b2Body_SetName(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	const char *name_v = hb_rs(&hb_call, 1);
	b2Body_SetName(bodyId_v, name_v);
}

HB_API void hb_b2Body_GetName(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	const char * result = b2Body_GetName(bodyId_v);
	hb_begin(&hb_call);
	hb_ws(&hb_call, result);
}

HB_API void hb_b2Body_GetPosition(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 result = b2Body_GetPosition(bodyId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetRotation(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Rot result = b2Body_GetRotation(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2Rot(&hb_call, &result);
}

HB_API void hb_b2Body_GetTransform(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Transform result = b2Body_GetTransform(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2Body_SetTransform(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float position_x, float position_y, float rotation_c, float rotation_s) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 position_v;
	position_v.x = position_x;
	position_v.y = position_y;
	b2Rot rotation_v;
	rotation_v.c = rotation_c;
	rotation_v.s = rotation_s;
	b2Body_SetTransform(bodyId_v, position_v, rotation_v);
}

HB_API void hb_b2Body_GetLocalPoint(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float worldPoint_x, float worldPoint_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 worldPoint_v;
	worldPoint_v.x = worldPoint_x;
	worldPoint_v.y = worldPoint_y;
	b2Vec2 result = b2Body_GetLocalPoint(bodyId_v, worldPoint_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetWorldPoint(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float localPoint_x, float localPoint_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 localPoint_v;
	localPoint_v.x = localPoint_x;
	localPoint_v.y = localPoint_y;
	b2Vec2 result = b2Body_GetWorldPoint(bodyId_v, localPoint_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetLocalVector(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float worldVector_x, float worldVector_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 worldVector_v;
	worldVector_v.x = worldVector_x;
	worldVector_v.y = worldVector_y;
	b2Vec2 result = b2Body_GetLocalVector(bodyId_v, worldVector_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetWorldVector(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float localVector_x, float localVector_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 localVector_v;
	localVector_v.x = localVector_x;
	localVector_v.y = localVector_y;
	b2Vec2 result = b2Body_GetWorldVector(bodyId_v, localVector_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetLinearVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 result = b2Body_GetLinearVelocity(bodyId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API float hb_b2Body_GetAngularVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetAngularVelocity(bodyId_v);
	return result;
}

HB_API void hb_b2Body_SetLinearVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float linearVelocity_x, float linearVelocity_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 linearVelocity_v;
	linearVelocity_v.x = linearVelocity_x;
	linearVelocity_v.y = linearVelocity_y;
	b2Body_SetLinearVelocity(bodyId_v, linearVelocity_v);
}

HB_API void hb_b2Body_SetAngularVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float angularVelocity) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetAngularVelocity(bodyId_v, angularVelocity);
}

HB_API void hb_b2Body_SetTargetTransform(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float target_p_x, float target_p_y, float target_q_c, float target_q_s, float timeStep, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Transform target_v;
	target_v.p.x = target_p_x;
	target_v.p.y = target_p_y;
	target_v.q.c = target_q_c;
	target_v.q.s = target_q_s;
	b2Body_SetTargetTransform(bodyId_v, target_v, timeStep, wake != 0);
}

HB_API void hb_b2Body_GetLocalPointVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float localPoint_x, float localPoint_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 localPoint_v;
	localPoint_v.x = localPoint_x;
	localPoint_v.y = localPoint_y;
	b2Vec2 result = b2Body_GetLocalPointVelocity(bodyId_v, localPoint_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetWorldPointVelocity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float worldPoint_x, float worldPoint_y) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 worldPoint_v;
	worldPoint_v.x = worldPoint_x;
	worldPoint_v.y = worldPoint_y;
	b2Vec2 result = b2Body_GetWorldPointVelocity(bodyId_v, worldPoint_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_ApplyForce(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float force_x, float force_y, float point_x, float point_y, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 force_v;
	force_v.x = force_x;
	force_v.y = force_y;
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	b2Body_ApplyForce(bodyId_v, force_v, point_v, wake != 0);
}

HB_API void hb_b2Body_ApplyForceToCenter(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float force_x, float force_y, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 force_v;
	force_v.x = force_x;
	force_v.y = force_y;
	b2Body_ApplyForceToCenter(bodyId_v, force_v, wake != 0);
}

HB_API void hb_b2Body_ApplyTorque(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float torque, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_ApplyTorque(bodyId_v, torque, wake != 0);
}

HB_API void hb_b2Body_ClearForces(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_ClearForces(bodyId_v);
}

HB_API void hb_b2Body_ApplyLinearImpulse(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float impulse_x, float impulse_y, float point_x, float point_y, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 impulse_v;
	impulse_v.x = impulse_x;
	impulse_v.y = impulse_y;
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	b2Body_ApplyLinearImpulse(bodyId_v, impulse_v, point_v, wake != 0);
}

HB_API void hb_b2Body_ApplyLinearImpulseToCenter(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float impulse_x, float impulse_y, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 impulse_v;
	impulse_v.x = impulse_x;
	impulse_v.y = impulse_y;
	b2Body_ApplyLinearImpulseToCenter(bodyId_v, impulse_v, wake != 0);
}

HB_API void hb_b2Body_ApplyAngularImpulse(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float impulse, int32_t wake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_ApplyAngularImpulse(bodyId_v, impulse, wake != 0);
}

HB_API float hb_b2Body_GetMass(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetMass(bodyId_v);
	return result;
}

HB_API float hb_b2Body_GetRotationalInertia(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetRotationalInertia(bodyId_v);
	return result;
}

HB_API void hb_b2Body_GetLocalCenter(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 result = b2Body_GetLocalCenter(bodyId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_GetWorldCenter(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Vec2 result = b2Body_GetWorldCenter(bodyId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Body_SetMassData(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float massData_mass, float massData_center_x, float massData_center_y, float massData_rotationalInertia) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2MassData massData_v;
	massData_v.mass = massData_mass;
	massData_v.center.x = massData_center_x;
	massData_v.center.y = massData_center_y;
	massData_v.rotationalInertia = massData_rotationalInertia;
	b2Body_SetMassData(bodyId_v, massData_v);
}

HB_API void hb_b2Body_GetMassData(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2MassData result = b2Body_GetMassData(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2MassData(&hb_call, &result);
}

HB_API void hb_b2Body_UpdateMassFromShapes(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_UpdateMassFromShapes(bodyId_v);
}

HB_API void hb_b2Body_SetLinearDamping(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float linearDamping) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetLinearDamping(bodyId_v, linearDamping);
}

HB_API float hb_b2Body_GetLinearDamping(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetLinearDamping(bodyId_v);
	return result;
}

HB_API void hb_b2Body_SetAngularDamping(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float angularDamping) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetAngularDamping(bodyId_v, angularDamping);
}

HB_API float hb_b2Body_GetAngularDamping(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetAngularDamping(bodyId_v);
	return result;
}

HB_API void hb_b2Body_SetGravityScale(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float gravityScale) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetGravityScale(bodyId_v, gravityScale);
}

HB_API float hb_b2Body_GetGravityScale(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetGravityScale(bodyId_v);
	return result;
}

HB_API int32_t hb_b2Body_IsAwake(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	bool result = b2Body_IsAwake(bodyId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Body_SetAwake(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t awake) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetAwake(bodyId_v, awake != 0);
}

HB_API void hb_b2Body_WakeTouching(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_WakeTouching(bodyId_v);
}

HB_API void hb_b2Body_EnableSleeping(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t enableSleep) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_EnableSleeping(bodyId_v, enableSleep != 0);
}

HB_API int32_t hb_b2Body_IsSleepingEnabled(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	bool result = b2Body_IsSleepingEnabled(bodyId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Body_SetSleepThreshold(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float sleepThreshold) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetSleepThreshold(bodyId_v, sleepThreshold);
}

HB_API float hb_b2Body_GetSleepThreshold(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetSleepThreshold(bodyId_v);
	return result;
}

HB_API void hb_b2Body_SetSafetyFactor(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, float safetyFactor) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetSafetyFactor(bodyId_v, safetyFactor);
}

HB_API float hb_b2Body_GetSafetyFactor(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetSafetyFactor(bodyId_v);
	return result;
}

HB_API int32_t hb_b2Body_IsEnabled(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	bool result = b2Body_IsEnabled(bodyId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Body_Disable(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_Disable(bodyId_v);
}

HB_API void hb_b2Body_Enable(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_Enable(bodyId_v);
}

HB_API void hb_b2Body_SetMotionLocks(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t locks_linearX, int32_t locks_linearY, int32_t locks_angularZ) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2MotionLocks locks_v;
	locks_v.linearX = locks_linearX;
	locks_v.linearY = locks_linearY;
	locks_v.angularZ = locks_angularZ;
	b2Body_SetMotionLocks(bodyId_v, locks_v);
}

HB_API void hb_b2Body_GetMotionLocks(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2MotionLocks result = b2Body_GetMotionLocks(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2MotionLocks(&hb_call, &result);
}

HB_API void hb_b2Body_SetBullet(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t flag) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_SetBullet(bodyId_v, flag != 0);
}

HB_API int32_t hb_b2Body_IsBullet(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	bool result = b2Body_IsBullet(bodyId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Body_EnableContactRecycling(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t flag) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_EnableContactRecycling(bodyId_v, flag != 0);
}

HB_API int32_t hb_b2Body_IsContactRecyclingEnabled(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	bool result = b2Body_IsContactRecyclingEnabled(bodyId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Body_EnableContactEvents(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t flag) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_EnableContactEvents(bodyId_v, flag != 0);
}

HB_API void hb_b2Body_EnableHitEvents(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t flag) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2Body_EnableHitEvents(bodyId_v, flag != 0);
}

HB_API void hb_b2Body_GetWorld(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2WorldId result = b2Body_GetWorld(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API int32_t hb_b2Body_GetShapeCount(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	int result = b2Body_GetShapeCount(bodyId_v);
	return result;
}

HB_API int32_t hb_b2Body_GetShapes(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t capacity) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeId *shapeArray_v = (b2ShapeId *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2ShapeId));
	int result = b2Body_GetShapes(bodyId_v, shapeArray_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2ShapeId(&hb_call, &shapeArray_v[k]);
		}
	}
	return result;
}

HB_API int32_t hb_b2Body_GetJointCount(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	int result = b2Body_GetJointCount(bodyId_v);
	return result;
}

HB_API int32_t hb_b2Body_GetJoints(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t capacity) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2JointId *jointArray_v = (b2JointId *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2JointId));
	int result = b2Body_GetJoints(bodyId_v, jointArray_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2JointId(&hb_call, &jointArray_v[k]);
		}
	}
	return result;
}

HB_API int32_t hb_b2Body_GetContactCapacity(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	int result = b2Body_GetContactCapacity(bodyId_v);
	return result;
}

HB_API int32_t hb_b2Body_GetContactData(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation, int32_t capacity) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ContactData *contactData_v = (b2ContactData *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2ContactData));
	int result = b2Body_GetContactData(bodyId_v, contactData_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2ContactData(&hb_call, &contactData_v[k]);
		}
	}
	return result;
}

HB_API void hb_b2Body_ComputeBounds(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2AABB result = b2Body_ComputeBounds(bodyId_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API float hb_b2Body_GetMinExtent(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetMinExtent(bodyId_v);
	return result;
}

HB_API float hb_b2Body_GetMaxExtent(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetMaxExtent(bodyId_v);
	return result;
}

HB_API float hb_b2Body_GetMaxExtentFromOrigin(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	float result = b2Body_GetMaxExtentFromOrigin(bodyId_v);
	return result;
}

HB_API void hb_b2CreateCircleShape(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeDef def_v;
	hb_rd_b2ShapeDef(&hb_call, &def_v);
	b2Circle circle_v;
	hb_rd_b2Circle(&hb_call, &circle_v);
	b2ShapeId result = b2CreateCircleShape(bodyId_v, &def_v, &circle_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeId(&hb_call, &result);
}

HB_API void hb_b2CreateSegmentShape(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeDef def_v;
	hb_rd_b2ShapeDef(&hb_call, &def_v);
	b2Segment segment_v;
	hb_rd_b2Segment(&hb_call, &segment_v);
	b2ShapeId result = b2CreateSegmentShape(bodyId_v, &def_v, &segment_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeId(&hb_call, &result);
}

HB_API void hb_b2CreateChainSegmentShape(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeDef def_v;
	hb_rd_b2ShapeDef(&hb_call, &def_v);
	b2ChainSegment chainSegment_v;
	hb_rd_b2ChainSegment(&hb_call, &chainSegment_v);
	b2ShapeId result = b2CreateChainSegmentShape(bodyId_v, &def_v, &chainSegment_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeId(&hb_call, &result);
}

HB_API void hb_b2CreateCapsuleShape(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeDef def_v;
	hb_rd_b2ShapeDef(&hb_call, &def_v);
	b2Capsule capsule_v;
	hb_rd_b2Capsule(&hb_call, &capsule_v);
	b2ShapeId result = b2CreateCapsuleShape(bodyId_v, &def_v, &capsule_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeId(&hb_call, &result);
}

HB_API void hb_b2CreatePolygonShape(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ShapeDef def_v;
	hb_rd_b2ShapeDef(&hb_call, &def_v);
	b2Polygon polygon_v;
	hb_rd_b2Polygon(&hb_call, &polygon_v);
	b2ShapeId result = b2CreatePolygonShape(bodyId_v, &def_v, &polygon_v);
	hb_begin(&hb_call);
	hb_wr_b2ShapeId(&hb_call, &result);
}

HB_API void hb_b2DestroyShape(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t updateBodyMass) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2DestroyShape(shapeId_v, updateBodyMass != 0);
}

HB_API int32_t hb_b2Shape_IsValid(int32_t id_index1, int32_t id_world0, int32_t id_generation) {
	b2ShapeId id_v;
	id_v.index1 = id_index1;
	id_v.world0 = id_world0;
	id_v.generation = id_generation;
	bool result = b2Shape_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2Shape_GetType(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ShapeType result = b2Shape_GetType(shapeId_v);
	return result;
}

HB_API void hb_b2Shape_GetBody(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2BodyId result = b2Shape_GetBody(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2BodyId(&hb_call, &result);
}

HB_API void hb_b2Shape_GetWorld(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2WorldId result = b2Shape_GetWorld(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API int32_t hb_b2Shape_IsSensor(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	bool result = b2Shape_IsSensor(shapeId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Shape_SetDensity(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float density, int32_t updateBodyMass) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_SetDensity(shapeId_v, density, updateBodyMass != 0);
}

HB_API float hb_b2Shape_GetDensity(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	float result = b2Shape_GetDensity(shapeId_v);
	return result;
}

HB_API void hb_b2Shape_SetFriction(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float friction) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_SetFriction(shapeId_v, friction);
}

HB_API float hb_b2Shape_GetFriction(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	float result = b2Shape_GetFriction(shapeId_v);
	return result;
}

HB_API void hb_b2Shape_SetRestitution(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float restitution) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_SetRestitution(shapeId_v, restitution);
}

HB_API float hb_b2Shape_GetRestitution(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	float result = b2Shape_GetRestitution(shapeId_v);
	return result;
}

HB_API void hb_b2Shape_SetUserMaterial(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t material_low, int32_t material_high) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_SetUserMaterial(shapeId_v, ((uint64_t)(uint32_t)material_high << 32) | (uint32_t)material_low);
}

HB_API void hb_b2Shape_GetUserMaterial(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	uint64_t result = b2Shape_GetUserMaterial(shapeId_v);
	hb_begin(&hb_call);
	hb_wl(&hb_call, result);
}

HB_API void hb_b2Shape_SetSurfaceMaterial(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2SurfaceMaterial surfaceMaterial_v;
	hb_rd_b2SurfaceMaterial(&hb_call, &surfaceMaterial_v);
	b2Shape_SetSurfaceMaterial(shapeId_v, &surfaceMaterial_v);
}

HB_API void hb_b2Shape_GetSurfaceMaterial(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2SurfaceMaterial result = b2Shape_GetSurfaceMaterial(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2SurfaceMaterial(&hb_call, &result);
}

HB_API void hb_b2Shape_GetFilter(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Filter result = b2Shape_GetFilter(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2Filter(&hb_call, &result);
}

HB_API void hb_b2Shape_SetFilter(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Filter filter_v;
	hb_rd_b2Filter(&hb_call, &filter_v);
	b2Shape_SetFilter(shapeId_v, filter_v);
}

HB_API void hb_b2Shape_EnableSensorEvents(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t flag) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_EnableSensorEvents(shapeId_v, flag != 0);
}

HB_API int32_t hb_b2Shape_AreSensorEventsEnabled(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	bool result = b2Shape_AreSensorEventsEnabled(shapeId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Shape_EnableContactEvents(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t flag) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_EnableContactEvents(shapeId_v, flag != 0);
}

HB_API int32_t hb_b2Shape_AreContactEventsEnabled(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	bool result = b2Shape_AreContactEventsEnabled(shapeId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Shape_EnablePreSolveEvents(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t flag) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_EnablePreSolveEvents(shapeId_v, flag != 0);
}

HB_API int32_t hb_b2Shape_ArePreSolveEventsEnabled(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	bool result = b2Shape_ArePreSolveEventsEnabled(shapeId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Shape_EnableHitEvents(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t flag) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Shape_EnableHitEvents(shapeId_v, flag != 0);
}

HB_API int32_t hb_b2Shape_AreHitEventsEnabled(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	bool result = b2Shape_AreHitEventsEnabled(shapeId_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2Shape_TestPoint(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float point_x, float point_y) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Vec2 point_v;
	point_v.x = point_x;
	point_v.y = point_y;
	bool result = b2Shape_TestPoint(shapeId_v, point_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Shape_CastRay(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float origin_x, float origin_y, float translation_x, float translation_y) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Vec2 origin_v;
	origin_v.x = origin_x;
	origin_v.y = origin_y;
	b2Vec2 translation_v;
	translation_v.x = translation_x;
	translation_v.y = translation_y;
	b2CastOutput result = b2Shape_CastRay(shapeId_v, origin_v, translation_v);
	hb_begin(&hb_call);
	hb_wr_b2CastOutput(&hb_call, &result);
}

HB_API void hb_b2Shape_GetCircle(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Circle result = b2Shape_GetCircle(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2Circle(&hb_call, &result);
}

HB_API void hb_b2Shape_GetSegment(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Segment result = b2Shape_GetSegment(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2Segment(&hb_call, &result);
}

HB_API void hb_b2Shape_GetChainSegment(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ChainSegment result = b2Shape_GetChainSegment(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2ChainSegment(&hb_call, &result);
}

HB_API void hb_b2Shape_GetCapsule(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Capsule result = b2Shape_GetCapsule(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2Capsule(&hb_call, &result);
}

HB_API void hb_b2Shape_GetPolygon(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Polygon result = b2Shape_GetPolygon(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2Polygon(&hb_call, &result);
}

HB_API void hb_b2Shape_SetCircle(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Circle circle_v;
	hb_rd_b2Circle(&hb_call, &circle_v);
	b2Shape_SetCircle(shapeId_v, &circle_v);
}

HB_API void hb_b2Shape_SetCapsule(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Capsule capsule_v;
	hb_rd_b2Capsule(&hb_call, &capsule_v);
	b2Shape_SetCapsule(shapeId_v, &capsule_v);
}

HB_API void hb_b2Shape_SetSegment(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Segment segment_v;
	hb_rd_b2Segment(&hb_call, &segment_v);
	b2Shape_SetSegment(shapeId_v, &segment_v);
}

HB_API void hb_b2Shape_SetPolygon(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Polygon polygon_v;
	hb_rd_b2Polygon(&hb_call, &polygon_v);
	b2Shape_SetPolygon(shapeId_v, &polygon_v);
}

HB_API void hb_b2Shape_SetChainSegment(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	hb_begin(&hb_call);
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ChainSegment chainSegment_v;
	hb_rd_b2ChainSegment(&hb_call, &chainSegment_v);
	b2Shape_SetChainSegment(shapeId_v, &chainSegment_v);
}

HB_API void hb_b2Shape_GetParentChain(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ChainId result = b2Shape_GetParentChain(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2ChainId(&hb_call, &result);
}

HB_API int32_t hb_b2Shape_GetContactCapacity(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	int result = b2Shape_GetContactCapacity(shapeId_v);
	return result;
}

HB_API int32_t hb_b2Shape_GetContactData(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t capacity) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ContactData *contactData_v = (b2ContactData *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2ContactData));
	int result = b2Shape_GetContactData(shapeId_v, contactData_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2ContactData(&hb_call, &contactData_v[k]);
		}
	}
	return result;
}

HB_API int32_t hb_b2Shape_GetSensorCapacity(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	int result = b2Shape_GetSensorCapacity(shapeId_v);
	return result;
}

HB_API int32_t hb_b2Shape_GetSensorData(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, int32_t capacity) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2ShapeId *visitorIds_v = (b2ShapeId *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2ShapeId));
	int result = b2Shape_GetSensorData(shapeId_v, visitorIds_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2ShapeId(&hb_call, &visitorIds_v[k]);
		}
	}
	return result;
}

HB_API void hb_b2Shape_GetBounds(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2AABB result = b2Shape_GetBounds(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2AABB(&hb_call, &result);
}

HB_API void hb_b2Shape_ComputeMassData(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2MassData result = b2Shape_ComputeMassData(shapeId_v);
	hb_begin(&hb_call);
	hb_wr_b2MassData(&hb_call, &result);
}

HB_API void hb_b2Shape_GetClosestPoint(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float target_x, float target_y) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Vec2 target_v;
	target_v.x = target_x;
	target_v.y = target_y;
	b2Vec2 result = b2Shape_GetClosestPoint(shapeId_v, target_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2Shape_ApplyWind(int32_t shapeId_index1, int32_t shapeId_world0, int32_t shapeId_generation, float wind_x, float wind_y, float drag, float lift, int32_t wake) {
	b2ShapeId shapeId_v;
	shapeId_v.index1 = shapeId_index1;
	shapeId_v.world0 = shapeId_world0;
	shapeId_v.generation = shapeId_generation;
	b2Vec2 wind_v;
	wind_v.x = wind_x;
	wind_v.y = wind_y;
	b2Shape_ApplyWind(shapeId_v, wind_v, drag, lift, wake != 0);
}

HB_API void hb_b2CreateChain(int32_t bodyId_index1, int32_t bodyId_world0, int32_t bodyId_generation) {
	hb_begin(&hb_call);
	b2BodyId bodyId_v;
	bodyId_v.index1 = bodyId_index1;
	bodyId_v.world0 = bodyId_world0;
	bodyId_v.generation = bodyId_generation;
	b2ChainDef def_v;
	hb_rd_b2ChainDef(&hb_call, &def_v);
	b2ChainId result = b2CreateChain(bodyId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2ChainId(&hb_call, &result);
}

HB_API void hb_b2DestroyChain(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation) {
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2DestroyChain(chainId_v);
}

HB_API void hb_b2Chain_GetWorld(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation) {
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2WorldId result = b2Chain_GetWorld(chainId_v);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API int32_t hb_b2Chain_GetSegmentCount(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation) {
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	int result = b2Chain_GetSegmentCount(chainId_v);
	return result;
}

HB_API int32_t hb_b2Chain_GetSegments(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation, int32_t capacity) {
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2ShapeId *segmentArray_v = (b2ShapeId *)hb_scratch(1, (size_t)(capacity > 0 ? capacity : 1) * sizeof(b2ShapeId));
	int result = b2Chain_GetSegments(chainId_v, segmentArray_v, (int)capacity);
	hb_begin(&hb_call);
	{
		int32_t filled = result;
		hb_wi(&hb_call, filled);
		for (int32_t k = 0; k < filled; k++) {
			hb_wr_b2ShapeId(&hb_call, &segmentArray_v[k]);
		}
	}
	return result;
}

HB_API void hb_b2Chain_SetAllSurfaceMaterials(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation) {
	hb_begin(&hb_call);
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2SurfaceMaterial material_v;
	hb_rd_b2SurfaceMaterial(&hb_call, &material_v);
	b2Chain_SetAllSurfaceMaterials(chainId_v, &material_v);
}

HB_API void hb_b2Chain_SetSurfaceMaterial(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation, int32_t segmentIndex) {
	hb_begin(&hb_call);
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2SurfaceMaterial material_v;
	hb_rd_b2SurfaceMaterial(&hb_call, &material_v);
	b2Chain_SetSurfaceMaterial(chainId_v, &material_v, (int)segmentIndex);
}

HB_API void hb_b2Chain_GetSurfaceMaterial(int32_t chainId_index1, int32_t chainId_world0, int32_t chainId_generation, int32_t segmentIndex) {
	b2ChainId chainId_v;
	chainId_v.index1 = chainId_index1;
	chainId_v.world0 = chainId_world0;
	chainId_v.generation = chainId_generation;
	b2SurfaceMaterial result = b2Chain_GetSurfaceMaterial(chainId_v, (int)segmentIndex);
	hb_begin(&hb_call);
	hb_wr_b2SurfaceMaterial(&hb_call, &result);
}

HB_API int32_t hb_b2Chain_IsValid(int32_t id_index1, int32_t id_world0, int32_t id_generation) {
	b2ChainId id_v;
	id_v.index1 = id_index1;
	id_v.world0 = id_world0;
	id_v.generation = id_generation;
	bool result = b2Chain_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API void hb_b2DestroyJoint(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DestroyJoint(jointId_v);
}

HB_API int32_t hb_b2Joint_IsValid(int32_t id_index1, int32_t id_world0, int32_t id_generation) {
	b2JointId id_v;
	id_v.index1 = id_index1;
	id_v.world0 = id_world0;
	id_v.generation = id_generation;
	bool result = b2Joint_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API int32_t hb_b2Joint_GetType(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2JointType result = b2Joint_GetType(jointId_v);
	return result;
}

HB_API void hb_b2Joint_GetBodyA(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2BodyId result = b2Joint_GetBodyA(jointId_v);
	hb_begin(&hb_call);
	hb_wr_b2BodyId(&hb_call, &result);
}

HB_API void hb_b2Joint_GetBodyB(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2BodyId result = b2Joint_GetBodyB(jointId_v);
	hb_begin(&hb_call);
	hb_wr_b2BodyId(&hb_call, &result);
}

HB_API void hb_b2Joint_GetWorld(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WorldId result = b2Joint_GetWorld(jointId_v);
	hb_begin(&hb_call);
	hb_wr_b2WorldId(&hb_call, &result);
}

HB_API void hb_b2Joint_SetLocalFrameA(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float localFrame_p_x, float localFrame_p_y, float localFrame_q_c, float localFrame_q_s) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Transform localFrame_v;
	localFrame_v.p.x = localFrame_p_x;
	localFrame_v.p.y = localFrame_p_y;
	localFrame_v.q.c = localFrame_q_c;
	localFrame_v.q.s = localFrame_q_s;
	b2Joint_SetLocalFrameA(jointId_v, localFrame_v);
}

HB_API void hb_b2Joint_GetLocalFrameA(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Transform result = b2Joint_GetLocalFrameA(jointId_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2Joint_SetLocalFrameB(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float localFrame_p_x, float localFrame_p_y, float localFrame_q_c, float localFrame_q_s) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Transform localFrame_v;
	localFrame_v.p.x = localFrame_p_x;
	localFrame_v.p.y = localFrame_p_y;
	localFrame_v.q.c = localFrame_q_c;
	localFrame_v.q.s = localFrame_q_s;
	b2Joint_SetLocalFrameB(jointId_v, localFrame_v);
}

HB_API void hb_b2Joint_GetLocalFrameB(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Transform result = b2Joint_GetLocalFrameB(jointId_v);
	hb_begin(&hb_call);
	hb_wr_b2Transform(&hb_call, &result);
}

HB_API void hb_b2Joint_SetCollideConnected(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t shouldCollide) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Joint_SetCollideConnected(jointId_v, shouldCollide != 0);
}

HB_API int32_t hb_b2Joint_GetCollideConnected(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2Joint_GetCollideConnected(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Joint_WakeBodies(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Joint_WakeBodies(jointId_v);
}

HB_API void hb_b2Joint_GetConstraintForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Vec2 result = b2Joint_GetConstraintForce(jointId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API float hb_b2Joint_GetConstraintTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2Joint_GetConstraintTorque(jointId_v);
	return result;
}

HB_API float hb_b2Joint_GetLinearSeparation(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2Joint_GetLinearSeparation(jointId_v);
	return result;
}

HB_API float hb_b2Joint_GetAngularSeparation(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2Joint_GetAngularSeparation(jointId_v);
	return result;
}

HB_API void hb_b2Joint_SetConstraintTuning(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Joint_SetConstraintTuning(jointId_v, hertz, dampingRatio);
}

HB_API void hb_b2Joint_GetConstraintTuning(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float hertz_v = 0;
	float dampingRatio_v = 0;
	b2Joint_GetConstraintTuning(jointId_v, &hertz_v, &dampingRatio_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, hertz_v);
	hb_wf(&hb_call, dampingRatio_v);
}

HB_API void hb_b2Joint_SetForceThreshold(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float threshold) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Joint_SetForceThreshold(jointId_v, threshold);
}

HB_API float hb_b2Joint_GetForceThreshold(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2Joint_GetForceThreshold(jointId_v);
	return result;
}

HB_API void hb_b2Joint_SetTorqueThreshold(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float threshold) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Joint_SetTorqueThreshold(jointId_v, threshold);
}

HB_API float hb_b2Joint_GetTorqueThreshold(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2Joint_GetTorqueThreshold(jointId_v);
	return result;
}

HB_API void hb_b2CreateDistanceJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2DistanceJointDef def_v;
	hb_rd_b2DistanceJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateDistanceJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2DistanceJoint_SetRestLength(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float length) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetRestLength(jointId_v, length);
}

HB_API float hb_b2DistanceJoint_GetRestLength(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetRestLength(jointId_v);
	return result;
}

HB_API void hb_b2DistanceJoint_EnableSpring(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableSpring) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_EnableSpring(jointId_v, enableSpring != 0);
}

HB_API int32_t hb_b2DistanceJoint_IsSpringEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2DistanceJoint_IsSpringEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2DistanceJoint_SetSpringForceRange(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float lowerForce, float upperForce) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetSpringForceRange(jointId_v, lowerForce, upperForce);
}

HB_API void hb_b2DistanceJoint_GetSpringForceRange(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float lowerForce_v = 0;
	float upperForce_v = 0;
	b2DistanceJoint_GetSpringForceRange(jointId_v, &lowerForce_v, &upperForce_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, lowerForce_v);
	hb_wf(&hb_call, upperForce_v);
}

HB_API void hb_b2DistanceJoint_SetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetSpringHertz(jointId_v, hertz);
}

HB_API void hb_b2DistanceJoint_SetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetSpringDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2DistanceJoint_GetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetSpringHertz(jointId_v);
	return result;
}

HB_API float hb_b2DistanceJoint_GetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetSpringDampingRatio(jointId_v);
	return result;
}

HB_API float hb_b2DistanceJoint_GetSpringForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetSpringForce(jointId_v);
	return result;
}

HB_API void hb_b2DistanceJoint_EnableLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableLimit) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_EnableLimit(jointId_v, enableLimit != 0);
}

HB_API int32_t hb_b2DistanceJoint_IsLimitEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2DistanceJoint_IsLimitEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2DistanceJoint_SetLimits(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float minLength, float maxLength) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetLimits(jointId_v, minLength, maxLength);
}

HB_API float hb_b2DistanceJoint_GetLowerLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetLowerLimit(jointId_v);
	return result;
}

HB_API float hb_b2DistanceJoint_GetUpperLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetUpperLimit(jointId_v);
	return result;
}

HB_API float hb_b2DistanceJoint_GetCurrentLength(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetCurrentLength(jointId_v);
	return result;
}

HB_API void hb_b2DistanceJoint_EnableMotor(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableMotor) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_EnableMotor(jointId_v, enableMotor != 0);
}

HB_API int32_t hb_b2DistanceJoint_IsMotorEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2DistanceJoint_IsMotorEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2DistanceJoint_SetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float motorSpeed) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetTargetMotorSpeed(jointId_v, motorSpeed);
}

HB_API float hb_b2DistanceJoint_GetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetTargetMotorSpeed(jointId_v);
	return result;
}

HB_API void hb_b2DistanceJoint_SetMaxMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float force) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2DistanceJoint_SetMaxMotorForce(jointId_v, force);
}

HB_API float hb_b2DistanceJoint_GetMaxMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetMaxMotorForce(jointId_v);
	return result;
}

HB_API float hb_b2DistanceJoint_GetCurrentMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2DistanceJoint_GetCurrentMotorForce(jointId_v);
	return result;
}

HB_API void hb_b2CreateFilterJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2FilterJointDef def_v;
	hb_rd_b2FilterJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateFilterJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2CreateMotorJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2MotorJointDef def_v;
	hb_rd_b2MotorJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateMotorJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2MotorJoint_SetLinearVelocity(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float velocity_x, float velocity_y) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Vec2 velocity_v;
	velocity_v.x = velocity_x;
	velocity_v.y = velocity_y;
	b2MotorJoint_SetLinearVelocity(jointId_v, velocity_v);
}

HB_API void hb_b2MotorJoint_GetLinearVelocity(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2Vec2 result = b2MotorJoint_GetLinearVelocity(jointId_v);
	hb_begin(&hb_call);
	hb_wf(&hb_call, result.x);
	hb_wf(&hb_call, result.y);
}

HB_API void hb_b2MotorJoint_SetAngularVelocity(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float velocity) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetAngularVelocity(jointId_v, velocity);
}

HB_API float hb_b2MotorJoint_GetAngularVelocity(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetAngularVelocity(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetMaxVelocityForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float maxForce) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetMaxVelocityForce(jointId_v, maxForce);
}

HB_API float hb_b2MotorJoint_GetMaxVelocityForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetMaxVelocityForce(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetMaxVelocityTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float maxTorque) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetMaxVelocityTorque(jointId_v, maxTorque);
}

HB_API float hb_b2MotorJoint_GetMaxVelocityTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetMaxVelocityTorque(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetLinearHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetLinearHertz(jointId_v, hertz);
}

HB_API float hb_b2MotorJoint_GetLinearHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetLinearHertz(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetLinearDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float damping) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetLinearDampingRatio(jointId_v, damping);
}

HB_API float hb_b2MotorJoint_GetLinearDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetLinearDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetAngularHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetAngularHertz(jointId_v, hertz);
}

HB_API float hb_b2MotorJoint_GetAngularHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetAngularHertz(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetAngularDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float damping) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetAngularDampingRatio(jointId_v, damping);
}

HB_API float hb_b2MotorJoint_GetAngularDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetAngularDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetMaxSpringForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float maxForce) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetMaxSpringForce(jointId_v, maxForce);
}

HB_API float hb_b2MotorJoint_GetMaxSpringForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetMaxSpringForce(jointId_v);
	return result;
}

HB_API void hb_b2MotorJoint_SetMaxSpringTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float maxTorque) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2MotorJoint_SetMaxSpringTorque(jointId_v, maxTorque);
}

HB_API float hb_b2MotorJoint_GetMaxSpringTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2MotorJoint_GetMaxSpringTorque(jointId_v);
	return result;
}

HB_API void hb_b2CreatePrismaticJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2PrismaticJointDef def_v;
	hb_rd_b2PrismaticJointDef(&hb_call, &def_v);
	b2JointId result = b2CreatePrismaticJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2PrismaticJoint_EnableSpring(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableSpring) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_EnableSpring(jointId_v, enableSpring != 0);
}

HB_API int32_t hb_b2PrismaticJoint_IsSpringEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2PrismaticJoint_IsSpringEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2PrismaticJoint_SetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetSpringHertz(jointId_v, hertz);
}

HB_API float hb_b2PrismaticJoint_GetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetSpringHertz(jointId_v);
	return result;
}

HB_API void hb_b2PrismaticJoint_SetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetSpringDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2PrismaticJoint_GetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetSpringDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2PrismaticJoint_SetTargetTranslation(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float translation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetTargetTranslation(jointId_v, translation);
}

HB_API float hb_b2PrismaticJoint_GetTargetTranslation(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetTargetTranslation(jointId_v);
	return result;
}

HB_API void hb_b2PrismaticJoint_EnableLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableLimit) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_EnableLimit(jointId_v, enableLimit != 0);
}

HB_API int32_t hb_b2PrismaticJoint_IsLimitEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2PrismaticJoint_IsLimitEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API float hb_b2PrismaticJoint_GetLowerLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetLowerLimit(jointId_v);
	return result;
}

HB_API float hb_b2PrismaticJoint_GetUpperLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetUpperLimit(jointId_v);
	return result;
}

HB_API void hb_b2PrismaticJoint_SetLimits(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float lower, float upper) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetLimits(jointId_v, lower, upper);
}

HB_API void hb_b2PrismaticJoint_EnableMotor(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableMotor) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_EnableMotor(jointId_v, enableMotor != 0);
}

HB_API int32_t hb_b2PrismaticJoint_IsMotorEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2PrismaticJoint_IsMotorEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2PrismaticJoint_SetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float motorSpeed) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetTargetMotorSpeed(jointId_v, motorSpeed);
}

HB_API float hb_b2PrismaticJoint_GetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetTargetMotorSpeed(jointId_v);
	return result;
}

HB_API void hb_b2PrismaticJoint_SetMaxMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float force) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2PrismaticJoint_SetMaxMotorForce(jointId_v, force);
}

HB_API float hb_b2PrismaticJoint_GetMaxMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetMaxMotorForce(jointId_v);
	return result;
}

HB_API float hb_b2PrismaticJoint_GetCurrentTranslation(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetCurrentTranslation(jointId_v);
	return result;
}

HB_API float hb_b2PrismaticJoint_GetCurrentSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetCurrentSpeed(jointId_v);
	return result;
}

HB_API float hb_b2PrismaticJoint_GetCurrentMotorForce(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2PrismaticJoint_GetCurrentMotorForce(jointId_v);
	return result;
}

HB_API void hb_b2CreateRevoluteJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2RevoluteJointDef def_v;
	hb_rd_b2RevoluteJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateRevoluteJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2RevoluteJoint_EnableSpring(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableSpring) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_EnableSpring(jointId_v, enableSpring != 0);
}

HB_API int32_t hb_b2RevoluteJoint_IsSpringEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2RevoluteJoint_IsSpringEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2RevoluteJoint_SetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetSpringHertz(jointId_v, hertz);
}

HB_API float hb_b2RevoluteJoint_GetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetSpringHertz(jointId_v);
	return result;
}

HB_API void hb_b2RevoluteJoint_SetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetSpringDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2RevoluteJoint_GetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetSpringDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2RevoluteJoint_SetTargetAngle(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float angle) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetTargetAngle(jointId_v, angle);
}

HB_API float hb_b2RevoluteJoint_GetTargetAngle(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetTargetAngle(jointId_v);
	return result;
}

HB_API void hb_b2RevoluteJoint_EnableLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableLimit) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_EnableLimit(jointId_v, enableLimit != 0);
}

HB_API int32_t hb_b2RevoluteJoint_IsLimitEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2RevoluteJoint_IsLimitEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API float hb_b2RevoluteJoint_GetLowerLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetLowerLimit(jointId_v);
	return result;
}

HB_API float hb_b2RevoluteJoint_GetUpperLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetUpperLimit(jointId_v);
	return result;
}

HB_API void hb_b2RevoluteJoint_SetLimits(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float lower, float upper) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetLimits(jointId_v, lower, upper);
}

HB_API void hb_b2RevoluteJoint_EnableMotor(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableMotor) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_EnableMotor(jointId_v, enableMotor != 0);
}

HB_API int32_t hb_b2RevoluteJoint_IsMotorEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2RevoluteJoint_IsMotorEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2RevoluteJoint_SetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float motorSpeed) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetTargetMotorSpeed(jointId_v, motorSpeed);
}

HB_API float hb_b2RevoluteJoint_GetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetTargetMotorSpeed(jointId_v);
	return result;
}

HB_API void hb_b2RevoluteJoint_SetMaxMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float torque) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2RevoluteJoint_SetMaxMotorTorque(jointId_v, torque);
}

HB_API float hb_b2RevoluteJoint_GetMaxMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetMaxMotorTorque(jointId_v);
	return result;
}

HB_API float hb_b2RevoluteJoint_GetCurrentAngle(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetCurrentAngle(jointId_v);
	return result;
}

HB_API float hb_b2RevoluteJoint_GetCurrentSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetCurrentSpeed(jointId_v);
	return result;
}

HB_API float hb_b2RevoluteJoint_GetCurrentMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2RevoluteJoint_GetCurrentMotorTorque(jointId_v);
	return result;
}

HB_API void hb_b2CreateWeldJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2WeldJointDef def_v;
	hb_rd_b2WeldJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateWeldJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2WeldJoint_SetLinearHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WeldJoint_SetLinearHertz(jointId_v, hertz);
}

HB_API float hb_b2WeldJoint_GetLinearHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WeldJoint_GetLinearHertz(jointId_v);
	return result;
}

HB_API void hb_b2WeldJoint_SetLinearDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WeldJoint_SetLinearDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2WeldJoint_GetLinearDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WeldJoint_GetLinearDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2WeldJoint_SetAngularHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WeldJoint_SetAngularHertz(jointId_v, hertz);
}

HB_API float hb_b2WeldJoint_GetAngularHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WeldJoint_GetAngularHertz(jointId_v);
	return result;
}

HB_API void hb_b2WeldJoint_SetAngularDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WeldJoint_SetAngularDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2WeldJoint_GetAngularDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WeldJoint_GetAngularDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2CreateWheelJoint(int32_t worldId_index1, int32_t worldId_generation) {
	hb_begin(&hb_call);
	b2WorldId worldId_v;
	worldId_v.index1 = worldId_index1;
	worldId_v.generation = worldId_generation;
	b2WheelJointDef def_v;
	hb_rd_b2WheelJointDef(&hb_call, &def_v);
	b2JointId result = b2CreateWheelJoint(worldId_v, &def_v);
	hb_begin(&hb_call);
	hb_wr_b2JointId(&hb_call, &result);
}

HB_API void hb_b2WheelJoint_EnableSpring(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableSpring) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_EnableSpring(jointId_v, enableSpring != 0);
}

HB_API int32_t hb_b2WheelJoint_IsSpringEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2WheelJoint_IsSpringEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2WheelJoint_SetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float hertz) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_SetSpringHertz(jointId_v, hertz);
}

HB_API float hb_b2WheelJoint_GetSpringHertz(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetSpringHertz(jointId_v);
	return result;
}

HB_API void hb_b2WheelJoint_SetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float dampingRatio) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_SetSpringDampingRatio(jointId_v, dampingRatio);
}

HB_API float hb_b2WheelJoint_GetSpringDampingRatio(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetSpringDampingRatio(jointId_v);
	return result;
}

HB_API void hb_b2WheelJoint_EnableLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableLimit) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_EnableLimit(jointId_v, enableLimit != 0);
}

HB_API int32_t hb_b2WheelJoint_IsLimitEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2WheelJoint_IsLimitEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API float hb_b2WheelJoint_GetLowerLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetLowerLimit(jointId_v);
	return result;
}

HB_API float hb_b2WheelJoint_GetUpperLimit(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetUpperLimit(jointId_v);
	return result;
}

HB_API void hb_b2WheelJoint_SetLimits(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float lower, float upper) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_SetLimits(jointId_v, lower, upper);
}

HB_API void hb_b2WheelJoint_EnableMotor(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, int32_t enableMotor) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_EnableMotor(jointId_v, enableMotor != 0);
}

HB_API int32_t hb_b2WheelJoint_IsMotorEnabled(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	bool result = b2WheelJoint_IsMotorEnabled(jointId_v);
	return result ? 1 : 0;
}

HB_API void hb_b2WheelJoint_SetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float motorSpeed) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_SetTargetMotorSpeed(jointId_v, motorSpeed);
}

HB_API float hb_b2WheelJoint_GetTargetMotorSpeed(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetTargetMotorSpeed(jointId_v);
	return result;
}

HB_API void hb_b2WheelJoint_SetMaxMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation, float torque) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	b2WheelJoint_SetMaxMotorTorque(jointId_v, torque);
}

HB_API float hb_b2WheelJoint_GetMaxMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetMaxMotorTorque(jointId_v);
	return result;
}

HB_API float hb_b2WheelJoint_GetCurrentMotorTorque(int32_t jointId_index1, int32_t jointId_world0, int32_t jointId_generation) {
	b2JointId jointId_v;
	jointId_v.index1 = jointId_index1;
	jointId_v.world0 = jointId_world0;
	jointId_v.generation = jointId_generation;
	float result = b2WheelJoint_GetCurrentMotorTorque(jointId_v);
	return result;
}

HB_API int32_t hb_b2Contact_IsValid(int32_t id_index1, int32_t id_world0, int32_t id_padding, int32_t id_generation) {
	b2ContactId id_v;
	id_v.index1 = id_index1;
	id_v.world0 = id_world0;
	id_v.padding = id_padding;
	id_v.generation = id_generation;
	bool result = b2Contact_IsValid(id_v);
	return result ? 1 : 0;
}

HB_API void hb_b2Contact_GetData(int32_t contactId_index1, int32_t contactId_world0, int32_t contactId_padding, int32_t contactId_generation) {
	b2ContactId contactId_v;
	contactId_v.index1 = contactId_index1;
	contactId_v.world0 = contactId_world0;
	contactId_v.padding = contactId_padding;
	contactId_v.generation = contactId_generation;
	b2ContactData result = b2Contact_GetData(contactId_v);
	hb_begin(&hb_call);
	hb_wr_b2ContactData(&hb_call, &result);
}
