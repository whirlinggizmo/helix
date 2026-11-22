package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Provides the queries against the bodies as they are after the last step: rays, points, overlapping shapes and swept shapes.
	Returned by `PhysicsSystem.GetNarrowPhaseQuery`.

	```haxe
	var ray = new RRayCast(origin, direction.MulFloat(100));
	var collector = new CastRayClosestHitCollisionCollector();
	query.CastRay(ray, settings, collector);
	if (collector.HadHit())
		var point = ray.GetPointOnRay(collector.mHit.mFraction);
	```

	A sensor is skipped by every query. Each query adds its hits to the collector, which is emptied with `Reset` before reuse. */
class NarrowPhaseQuery {
	var world:Int;

	@:allow(helix.jolt) function new(world:Int) {
		this.world = world;
	}

	/** Writes a query's filters into hj_io_i, and a list of bodies into the bulk buffer. */
	function filters(broadPhase:Null<BroadPhaseLayerFilter>, layers:Null<ObjectLayerFilter>, bodies:Null<BodyFilter>):Void {
		Io.setI(0, broadPhase == null ? 0 : broadPhase.kind);
		Io.setI(1, broadPhase == null ? 0 : broadPhase.value);
		Io.setI(2, layers == null ? 0 : layers.kind);
		Io.setI(3, layers == null ? 0 : layers.value);
		Io.setI(4, bodies == null ? 0 : bodies.kind);
		if (bodies != null && bodies.kind == 2) {
			var ids = (cast bodies : IgnoreMultipleBodiesFilter).ids;
			Io.setI(5, ids.length);
			var base = Io.bulk(ids.length * 4);
			for (n in 0...ids.length)
				Io.setBulkI(base, n, ids[n]);
		} else
			Io.setI(5, bodies == null ? 0 : bodies.value);
	}

	/** Writes a shape's scale, transform and base offset into hj_io_f, as the shape queries read them. */
	static function shape(scale:Vec3, transform:RMat44, baseOffset:RVec3):Void {
		Io.setF(0, scale.x);
		Io.setF(1, scale.y);
		Io.setF(2, scale.z);
		Io.setMat44(3, transform);
		Io.setF(22, baseOffset.x);
		Io.setF(23, baseOffset.y);
		Io.setF(24, baseOffset.z);
	}

	/** Casts a ray, collecting the bodies it hits.

		The ray reaches as far as its direction is long.

		@param inRay  The ray.
		@param inRayCastSettings  How faces and solids are treated.
		@param ioCollector  Receives the hits.
		@param inBroadPhaseLayerFilter  Optional. The broad phase layers tested; all when omitted.
		@param inObjectLayerFilter  Optional. The object layers tested; all when omitted.
		@param inBodyFilter  Optional. The bodies tested; all when omitted.
		@param inShapeFilter  Optional. The parts of shapes tested; all when omitted. */
	public function CastRay(inRay:RRayCast, inRayCastSettings:RayCastSettings, ioCollector:CastRayCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter,
			?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void {
		filters(inBroadPhaseLayerFilter, inObjectLayerFilter, inBodyFilter);
		var o = inRay.mOrigin, d = inRay.mDirection;
		var count = Hj.queryCastRay(world, o.x, o.y, o.z, d.x, d.y, d.z, cast inRayCastSettings.mBackFaceModeTriangles,
			cast inRayCastSettings.mBackFaceModeConvex, inRayCastSettings.mTreatConvexAsSolid ? 1 : 0, ioCollector.kind());
		ioCollector.take(Io.bulk(count * 12), count);
	}

	/** Finds the bodies a point is inside.

		@param inPoint  The point, in meters.
		@param ioCollector  Receives the bodies.
		@param inBroadPhaseLayerFilter  Optional. The broad phase layers tested; all when omitted.
		@param inObjectLayerFilter  Optional. The object layers tested; all when omitted.
		@param inBodyFilter  Optional. The bodies tested; all when omitted.
		@param inShapeFilter  Optional. The parts of shapes tested; all when omitted. */
	public function CollidePoint(inPoint:RVec3, ioCollector:CollidePointCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter,
			?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void {
		filters(inBroadPhaseLayerFilter, inObjectLayerFilter, inBodyFilter);
		var count = Hj.queryCollidePoint(world, inPoint.x, inPoint.y, inPoint.z, ioCollector.kind());
		ioCollector.take(Io.bulk(count * 8), count);
	}

	/** Finds the bodies a shape overlaps.

		@param inShape  The shape.
		@param inShapeScale  The shape's scale.
		@param inCenterOfMassTransform  The transform of the shape's center of mass.
		@param inCollideShapeSettings  How the overlap is tested.
		@param inBaseOffset  A point subtracted from every position to keep the numbers small: the shape's position, or (0, 0, 0).
		@param ioCollector  Receives the bodies.
		@param inBroadPhaseLayerFilter  Optional. The broad phase layers tested; all when omitted.
		@param inObjectLayerFilter  Optional. The object layers tested; all when omitted.
		@param inBodyFilter  Optional. The bodies tested; all when omitted.
		@param inShapeFilter  Optional. The parts of shapes tested; all when omitted. */
	public function CollideShape(inShape:Shape, inShapeScale:Vec3, inCenterOfMassTransform:RMat44, inCollideShapeSettings:CollideShapeSettings,
			inBaseOffset:RVec3, ioCollector:CollideShapeCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter,
			?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void {
		filters(inBroadPhaseLayerFilter, inObjectLayerFilter, inBodyFilter);
		shape(inShapeScale, inCenterOfMassTransform, inBaseOffset);
		var count = Hj.queryCollideShape(world, inShape.handle, inCollideShapeSettings.mMaxSeparationDistance, cast inCollideShapeSettings.mBackFaceMode,
			ioCollector.kind());
		ioCollector.take(Io.bulk(count * 52), count);
	}

	/** Sweeps a shape along a line, collecting the bodies it hits.

		@param inShapeCast  The shape and its sweep.
		@param inShapeCastSettings  How faces are treated.
		@param inBaseOffset  A point subtracted from every position to keep the numbers small: the cast's start, or (0, 0, 0).
		@param ioCollector  Receives the hits.
		@param inBroadPhaseLayerFilter  Optional. The broad phase layers tested; all when omitted.
		@param inObjectLayerFilter  Optional. The object layers tested; all when omitted.
		@param inBodyFilter  Optional. The bodies tested; all when omitted.
		@param inShapeFilter  Optional. The parts of shapes tested; all when omitted. */
	public function CastShape(inShapeCast:RShapeCast, inShapeCastSettings:ShapeCastSettings, inBaseOffset:RVec3, ioCollector:CastShapeCollector,
			?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void {
		filters(inBroadPhaseLayerFilter, inObjectLayerFilter, inBodyFilter);
		shape(inShapeCast.mScale, inShapeCast.mCenterOfMassStart, inBaseOffset);
		Io.setF(19, inShapeCast.mDirection.x);
		Io.setF(20, inShapeCast.mDirection.y);
		Io.setF(21, inShapeCast.mDirection.z);
		var count = Hj.queryCastShape(world, inShapeCast.mShape.handle, cast inShapeCastSettings.mBackFaceModeTriangles,
			cast inShapeCastSettings.mBackFaceModeConvex, inShapeCastSettings.mReturnDeepestPoint ? 1 : 0, ioCollector.kind());
		ioCollector.take(Io.bulk(count * 60), count);
	}
}
