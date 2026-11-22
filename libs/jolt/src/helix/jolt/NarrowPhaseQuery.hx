package helix.jolt;

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
	function new() {}

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
		throw "not built yet";
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
		throw "not built yet";
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
		throw "not built yet";
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
		throw "not built yet";
	}
}
