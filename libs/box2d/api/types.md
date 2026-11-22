# helix.box2d

[Back to the library](README.md)

## B2AABB

*class* in [`libs/box2d/src/helix/box2d/B2AABB.hx`](../src/helix/box2d/B2AABB.hx), `import helix.box2d.B2AABB;`

An axis-aligned bounding box, in world units (meters by default).

```haxe
function new(?lowerBound:B2Vec2, ?upperBound:B2Vec2)
var lowerBound:B2Vec2
var upperBound:B2Vec2
```

- `new`: Creates one, as C's initializer lists its fields.
  - `lowerBound`: Optional. The lower corner. A zero vector when omitted.
  - `upperBound`: Optional. The upper corner. A zero vector when omitted.
- `lowerBound`: The corner with the smallest x and y.
- `upperBound`: The corner with the largest x and y.

## B2BodyDef

*class* in [`libs/box2d/src/helix/box2d/B2BodyDef.hx`](../src/helix/box2d/B2BodyDef.hx), `import helix.box2d.B2BodyDef;`

Everything needed to create a body with `b2CreateBody`. The definition can be reused for more bodies. Shapes are added to a body after it's created.

```haxe
function new()
var type:B2BodyType
var position:B2Pos
var rotation:B2Rot
var linearVelocity:B2Vec2
var angularVelocity:Float
var linearDamping:Float
var angularDamping:Float
var gravityScale:Float
var sleepThreshold:Float
var safetyFactor:Float
var name:String
var userData:Dynamic
var motionLocks:B2MotionLocks
var enableSleep:Bool
var isAwake:Bool
var isBullet:Bool
var isEnabled:Bool
var allowFastRotation:Bool
var enableContactRecycling:Bool
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultBodyDef()` returns. The structs it holds are made with it.
- `type`: How the body moves: static, kinematic or dynamic. Defaults to `b2_staticBody`.
- `position`: The body's starting position in the world, in length units. Create the body here, since creating it at the origin and moving it afterward nearly doubles the cost. Defaults to the origin.
- `rotation`: The body's starting rotation. Make one from an angle with `b2MakeRot`. Defaults to no rotation.
- `linearVelocity`: The starting velocity of the body's origin, in meters per second. Defaults to zero.
- `angularVelocity`: The starting angular velocity, in radians per second. Defaults to 0.
- `linearDamping`: Slows the body's linear velocity over time. 0 or more. A large value makes the effect depend on the time step, and any damping makes objects move as if floating. Defaults to 0.
- `angularDamping`: Slows the body's angular velocity over time. 0 or more. A large value makes the effect depend on the time step. Defaults to 0.
- `gravityScale`: Scales the gravity applied to this body. Non-dimensional. Defaults to 1.
- `sleepThreshold`: The speed below which the body may fall asleep, in meters per second. Defaults to 0.05 meters per second.
- `safetyFactor`: How far the body may move in one step, as a fraction of the distance that risks tunneling, before it gets continuous collision. Non-dimensional, recommended 0.01 to 0.5. Defaults to 0.5, for high performance with low tunneling risk.
- `name`: An optional name for debugging, up to `B2_NAME_LENGTH` characters. Defaults to null.
- `userData`: Any Haxe value the program keeps with the body, returned as set. Defaults to null.
- `motionLocks`: The movement the body is locked out of. A locked direction may be solved more softly. Defaults to nothing locked.
- `enableSleep`: Whether the body may fall asleep. Set it to false for a body that must never sleep. Defaults to true.
- `isAwake`: Whether the body starts awake. Defaults to true.
- `isBullet`: Whether this dynamic body is a fast object that gets continuous collision against dynamic and kinematic bodies, but not against other bullets. Use it sparingly, as it doesn't guarantee a hit when both bodies are fast. Defaults to false.
- `isEnabled`: Whether the body is enabled. A disabled body doesn't move or collide. Defaults to true.
- `allowFastRotation`: Whether the body may exceed the rotation speed limit. Use it only for round objects such as wheels. Defaults to false.
- `enableContactRecycling`: Whether the body's contacts are recycled between steps. Recycling improves performance but may cause ghost collisions, so turn it off for characters. Defaults to true.

## B2BodyEvents

*class* in [`libs/box2d/src/helix/box2d/B2BodyEvents.hx`](../src/helix/box2d/B2BodyEvents.hx), `import helix.box2d.B2BodyEvents;`

The body events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies makes them invalid.

```haxe
function new()
var moveEvents:Array<B2BodyMoveEvent>
var moveCount:Int
```

- `new`: Creates one, its fields zero.
- `moveEvents`: The move events, from index 0 up to `moveCount`. The array may be longer when it is reused.
- `moveCount`: The number of move events.

## B2BodyId

*class* in [`libs/box2d/src/helix/box2d/B2BodyId.hx`](../src/helix/box2d/B2BodyId.hx), `import helix.box2d.B2BodyId;`

References a body. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var world0:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the object plus one. Opaque to a program.
- `world0`: Box2D's index of the world the object belongs to. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2BodyMoveEvent

*class* in [`libs/box2d/src/helix/box2d/B2BodyMoveEvent.hx`](../src/helix/box2d/B2BodyMoveEvent.hx), `import helix.box2d.B2BodyMoveEvent;`

Reports a body that moved in the simulation, with its new transform. It is not reported for a body the program moved. It is an efficient way to update the program's own objects, as only the bodies that moved are listed. With sleeping disabled, every dynamic and kinematic body is reported each step.

```haxe
function new()
var userData:Dynamic
var transform:B2WorldTransform
var bodyId:B2BodyId
var fellAsleep:Bool
```

- `new`: Creates one, its fields zero.
- `userData`: The `userData` of the body, returned as set.
- `transform`: The new transform of the body, in the world.
- `bodyId`: The id of the body that moved.
- `fellAsleep`: Whether the body fell asleep in this step. A body that didn't can be treated as awake.

## B2BodyType

*abstract* in [`libs/box2d/src/helix/box2d/B2BodyType.hx`](../src/helix/box2d/B2BodyType.hx), `import helix.box2d.B2BodyType;`

The body simulation type.

- `B2BodyType.b2_staticBody`: Zero mass, zero velocity, may be manually moved.
- `B2BodyType.b2_kinematicBody`: Zero mass, velocity set by user, moved by solver.
- `B2BodyType.b2_dynamicBody`: Positive mass, velocity determined by forces, moved by solver.
- `B2BodyType.b2_bodyTypeCount`: Number of body types.

## B2Capacity

*class* in [`libs/box2d/src/helix/box2d/B2Capacity.hx`](../src/helix/box2d/B2Capacity.hx), `import helix.box2d.B2Capacity;`

Expected counts that let a world reserve memory when it is created and avoid allocating while it runs. Every field defaults to 0, which reserves nothing.

```haxe
function new()
var staticShapeCount:Int
var dynamicShapeCount:Int
var staticBodyCount:Int
var dynamicBodyCount:Int
var contactCount:Int
var arenaByteCount:Int
```

- `new`: Creates one, its fields zero.
- `staticShapeCount`: The expected number of static shapes.
- `dynamicShapeCount`: The expected number of dynamic and kinematic shapes.
- `staticBodyCount`: The expected number of static bodies.
- `dynamicBodyCount`: The expected number of dynamic and kinematic bodies.
- `contactCount`: The expected number of contacts.
- `arenaByteCount`: The bytes to reserve for temporary allocations.

## B2Capsule

*class* in [`libs/box2d/src/helix/box2d/B2Capsule.hx`](../src/helix/box2d/B2Capsule.hx), `import helix.box2d.B2Capsule;`

A solid capsule can be viewed as two semicircles connected by a rectangle.

```haxe
function new(?center1:B2Vec2, ?center2:B2Vec2, ?radius:Float = 0.)
var center1:B2Vec2
var center2:B2Vec2
var radius:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `center1`: Optional. Local center of the first semicircle.
  - `center2`: Optional. Local center of the second semicircle.
  - `radius`: Optional. The radius of the semicircles.
- `center1`: Local center of the first semicircle.
- `center2`: Local center of the second semicircle.
- `radius`: The radius of the semicircles.

## B2CastOutput

*class* in [`libs/box2d/src/helix/box2d/B2CastOutput.hx`](../src/helix/box2d/B2CastOutput.hx), `import helix.box2d.B2CastOutput;`

The output of a low level ray cast or shape cast. Box2D fills it.

```haxe
function new()
var normal:B2Vec2
var point:B2Vec2
var fraction:Float
var iterations:Int
var hit:Bool
```

- `new`: Creates one, its fields zero.
- `normal`: The surface normal at the hit point.
- `point`: The surface hit point.
- `fraction`: The fraction of the input translation at collision.
- `iterations`: The number of iterations used.
- `hit`: Did the cast hit?

## B2CastResultCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2CastResultCallbackFcn.hx`](../src/helix/box2d/B2CastResultCallbackFcn.hx), `import helix.box2d.B2CastResultCallbackFcn;`

A callback for ray and shape casts. Box2D calls it for each shape the cast finds. The return value controls how the cast goes on: -1 ignores this shape and continues, 0 terminates the cast, the fraction clips the ray to that point (use it to find the closest hit), and 1 continues without clipping. A shape cast that starts overlapping a shape reports a fraction of 0 and a zero normal.

- `shapeId`: The shape hit by the cast.
- `point`: The point where the cast first meets the shape, in world coordinates.
- `normal`: The unit normal of the shape at that point. Zero for a shape cast that starts overlapping.
- `fraction`: How far along the cast the hit is, from 0 to 1. Zero for a shape cast that starts overlapping.
- `context`: The value the program provided to the cast call, returned as it was.
- returns: -1 to ignore the shape, 0 to stop, the fraction to clip the ray, or 1 to continue.

An alias of `(shapeId:B2ShapeId, point:B2Pos, normal:B2Vec2, fraction:Float, context:Dynamic) -> Float`.

## B2ChainDef

*class* in [`libs/box2d/src/helix/box2d/B2ChainDef.hx`](../src/helix/box2d/B2ChainDef.hx), `import helix.box2d.B2ChainDef;`

Everything needed to create a chain of line segments with `b2CreateChain`. A chain is one-sided, with no mass, so use it on static bodies. It has a counter-clockwise winding, where the normal points right of the segment direction. It collides on one side, its front, which is to the right looking from each point to the next: points listed from right to left make ground whose top is up. It's either a loop or open, and an open chain needs a ghost point at each end, as `b2CreateChain` refuses an open chain whose ghost points are left at their defaults. The distance between two points must exceed `B2_LINEAR_SLOP`, and the chain must not intersect itself. Use chains only when you understand these limits.

```haxe
function new()
var userData:Dynamic
var points:Array<B2Vec2>
var pointCount:Int
var ghost1:B2Vec2
var ghost2:B2Vec2
var materials:Array<B2SurfaceMaterial>
var materialCount:Int
var filter:B2Filter
var isLoop:Bool
var enableSensorEvents:Bool
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultChainDef()` returns. The structs it holds are made with it.
- `userData`: Any Haxe value the program keeps with the chain, returned as set. Defaults to null.
- `points`: The chain's points, read from index 0 up to `pointCount`. Each consecutive pair is a segment, and for a loop the last and first point are a segment too. Box2D copies them. Defaults to none.
- `pointCount`: The number of points to use. At least 2 for an open chain and at least 3 for a loop. Defaults to 0.
- `ghost1`: The leading ghost point of an open chain. Its distance from the first point must exceed `B2_LINEAR_SLOP`. Ignored for a loop. Defaults to a point at infinity, which is not valid until it's set.
- `ghost2`: The trailing ghost point of an open chain. Its distance from the last point must exceed `B2_LINEAR_SLOP`. Ignored for a loop. Defaults to a point at infinity, which is not valid until it's set.
- `materials`: One material for the whole chain, or one for each segment, read from index 0 up to `materialCount`. Box2D copies them. Defaults to one material with a friction of 0.6.
- `materialCount`: The number of materials to use. Must be 1 or the segment count, which is `pointCount` for a loop and one less for an open chain. Defaults to 1.
- `filter`: Which shapes the chain collides with, and which queries find it. Defaults to category 1, colliding with all categories, in group 0.
- `isLoop`: Whether the chain is closed by joining the last point to the first. Defaults to false.
- `enableSensorEvents`: Whether sensors detect the chain. Defaults to false.

## B2ChainId

*class* in [`libs/box2d/src/helix/box2d/B2ChainId.hx`](../src/helix/box2d/B2ChainId.hx), `import helix.box2d.B2ChainId;`

References a chain shape. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var world0:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the object plus one. Opaque to a program.
- `world0`: Box2D's index of the world the object belongs to. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2ChainSegment

*class* in [`libs/box2d/src/helix/box2d/B2ChainSegment.hx`](../src/helix/box2d/B2ChainSegment.hx), `import helix.box2d.B2ChainSegment;`

A line segment of a chain, with one-sided collision. It has a ghost vertex at each end.

```haxe
function new()
var ghost1:B2Vec2
var segment:B2Segment
var ghost2:B2Vec2
var chainId:Int
```

- `new`: Creates one, its fields zero.
- `ghost1`: The ghost vertex before the segment.
- `segment`: The line segment.
- `ghost2`: The ghost vertex after the segment.
- `chainId`: Box2D's index of the chain that owns the segment. Opaque to a program.

## B2Circle

*class* in [`libs/box2d/src/helix/box2d/B2Circle.hx`](../src/helix/box2d/B2Circle.hx), `import helix.box2d.B2Circle;`

A solid circle.

```haxe
function new(?center:B2Vec2, ?radius:Float = 0.)
var center:B2Vec2
var radius:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `center`: Optional. The local center.
  - `radius`: Optional. The radius.
- `center`: The local center.
- `radius`: The radius.

## B2ContactBeginTouchEvent

*class* in [`libs/box2d/src/helix/box2d/B2ContactBeginTouchEvent.hx`](../src/helix/box2d/B2ContactBeginTouchEvent.hx), `import helix.box2d.B2ContactBeginTouchEvent;`

Reports that two shapes began touching.

```haxe
function new()
var shapeIdA:B2ShapeId
var shapeIdB:B2ShapeId
var contactId:B2ContactId
```

- `new`: Creates one, its fields zero.
- `shapeIdA`: The id of the first shape.
- `shapeIdB`: The id of the second shape.
- `contactId`: The id of the contact. It is transient, as Box2D may destroy the contact when the world is modified or stepped. Check it with `b2Contact_IsValid` before use.

## B2ContactData

*class* in [`libs/box2d/src/helix/box2d/B2ContactData.hx`](../src/helix/box2d/B2ContactData.hx), `import helix.box2d.B2ContactData;`

The data of a contact between two shapes. By convention the manifold normal points from shape A to shape B. Box2D fills it, as `b2Shape_GetContactData` and `b2Body_GetContactData` return it.

```haxe
function new()
var contactId:B2ContactId
var shapeIdA:B2ShapeId
var shapeIdB:B2ShapeId
var manifold:B2Manifold
```

- `new`: Creates one, its fields zero.
- `contactId`: The id of the contact. The program may keep it to follow a contact across steps, but it can become orphaned, so check it with `b2Contact_IsValid` before use.
- `shapeIdA`: The id of the first shape.
- `shapeIdB`: The id of the second shape.
- `manifold`: A copy of the contact's manifold.

## B2ContactEndTouchEvent

*class* in [`libs/box2d/src/helix/box2d/B2ContactEndTouchEvent.hx`](../src/helix/box2d/B2ContactEndTouchEvent.hx), `import helix.box2d.B2ContactEndTouchEvent;`

Reports that two shapes stopped touching. It is also reported when something destroys a contact made before the last step, such as setting a body's transform, destroying a body or shape, or changing a filter or a body type.

```haxe
function new()
var shapeIdA:B2ShapeId
var shapeIdB:B2ShapeId
var contactId:B2ContactId
```

- `new`: Creates one, its fields zero.
- `shapeIdA`: The id of the first shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`.
- `shapeIdB`: The id of the second shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`.
- `contactId`: The id of the contact. The contact may have been destroyed, so check it with `b2Contact_IsValid`.

## B2ContactEvents

*class* in [`libs/box2d/src/helix/box2d/B2ContactEvents.hx`](../src/helix/box2d/B2ContactEvents.hx), `import helix.box2d.B2ContactEvents;`

The contact events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies or shapes can make them invalid.

```haxe
function new()
var beginEvents:Array<B2ContactBeginTouchEvent>
var endEvents:Array<B2ContactEndTouchEvent>
var hitEvents:Array<B2ContactHitEvent>
var beginCount:Int
var endCount:Int
var hitCount:Int
```

- `new`: Creates one, its fields zero.
- `beginEvents`: The begin touch events, from index 0 up to `beginCount`. The array may be longer when it is reused.
- `endEvents`: The end touch events, from index 0 up to `endCount`. The array may be longer when it is reused.
- `hitEvents`: The hit events, from index 0 up to `hitCount`. The array may be longer when it is reused.
- `beginCount`: The number of begin touch events.
- `endCount`: The number of end touch events.
- `hitCount`: The number of hit events.

## B2ContactHitEvent

*class* in [`libs/box2d/src/helix/box2d/B2ContactHitEvent.hx`](../src/helix/box2d/B2ContactHitEvent.hx), `import helix.box2d.B2ContactHitEvent;`

Reports two shapes that collided faster than the world's hit event threshold. It may be reported for a speculative contact that has a confirmed impulse.

```haxe
function new()
var shapeIdA:B2ShapeId
var shapeIdB:B2ShapeId
var contactId:B2ContactId
var point:B2Pos
var normal:B2Vec2
var approachSpeed:Float
```

- `new`: Creates one, its fields zero.
- `shapeIdA`: The id of the first shape.
- `shapeIdB`: The id of the second shape.
- `contactId`: The id of the contact. The contact may have been destroyed, so check it with `b2Contact_IsValid`.
- `point`: The point where the shapes hit, midway between the two surfaces. It may be a speculative point where the shapes weren't touching at the start of the step. It is rebuilt after the step, so when both bodies move it may trail the impact by up to one step of motion.
- `normal`: The unit normal, pointing from shape A to shape B.
- `approachSpeed`: The speed at which the shapes approach, always positive, usually in meters per second.

## B2ContactId

*class* in [`libs/box2d/src/helix/box2d/B2ContactId.hx`](../src/helix/box2d/B2ContactId.hx), `import helix.box2d.B2ContactId;`

References a contact. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var world0:Int
var padding:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the object plus one. Opaque to a program.
- `world0`: Box2D's index of the world the object belongs to. Opaque to a program.
- `padding`: Box2D's padding field. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2CosSin

*class* in [`libs/box2d/src/helix/box2d/B2CosSin.hx`](../src/helix/box2d/B2CosSin.hx), `import helix.box2d.B2CosSin;`

A cosine and sine pair. Box2D computes it with its own implementation, designed to return the same result on every platform.

```haxe
function new(?cosine:Float = 0., ?sine:Float = 0.)
var cosine:Float
var sine:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `cosine`: Optional. The cosine. Zero when omitted.
  - `sine`: Optional. The sine. Zero when omitted.
- `cosine`: The cosine.
- `sine`: The sine.

## B2Counters

*class* in [`libs/box2d/src/helix/box2d/B2Counters.hx`](../src/helix/box2d/B2Counters.hx), `import helix.box2d.B2Counters;`

Counts that describe the size of a simulation. `b2World_GetCounters` returns one that Box2D fills.

```haxe
function new()
var byteCount:Int
var bodyCount:Int
var shapeCount:Int
var contactCount:Int
var jointCount:Int
var islandCount:Int
var stackUsed:Int
var staticTreeHeight:Int
var treeHeight:Int
var taskCount:Int
var colorCounts:Array<Int>
var awakeContactCount:Int
var recycledContactCount:Int
```

- `new`: Creates one, its fields zero.
- `byteCount`: Bytes of memory Box2D has allocated.
- `bodyCount`: The number of bodies.
- `shapeCount`: The number of shapes.
- `contactCount`: The number of contacts.
- `jointCount`: The number of joints.
- `islandCount`: The number of simulation islands.
- `stackUsed`: Bytes of Box2D's stack allocator in use.
- `staticTreeHeight`: The height of the static bodies' broad-phase tree.
- `treeHeight`: The height of the moving bodies' broad-phase trees, the tallest of them.
- `taskCount`: The number of tasks Box2D ran in the last step.
- `colorCounts`: The number of constraints in each of the 24 graph colors, the solver's groups of constraints that can be solved together. An array of 24 integers.
- `awakeContactCount`: Number of contacts touched by the collide pass (graph contacts + awake-set non-touching).
- `recycledContactCount`: Number of contacts recycled in the most recent step.

## B2CustomFilterCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2CustomFilterCallbackFcn.hx`](../src/helix/box2d/B2CustomFilterCallbackFcn.hx), `import helix.box2d.B2CustomFilterCallbackFcn;`

A callback that decides whether two shapes collide. Box2D calls it when two shapes' bounding boxes begin to overlap and one of them has custom filtering enabled in its `B2ShapeDef`. It may also be called for awake dynamic bodies and sensors. Natively it can be called from a worker thread, so it must not modify the world.

- `shapeIdA`: The first shape.
- `shapeIdB`: The second shape.
- `context`: The value the program provided with the callback, returned as it was.
- returns: False to disable the collision between the shapes, true to allow it.

An alias of `(shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, context:Dynamic) -> Bool`.

## B2DebugDraw

*class* in [`libs/box2d/src/helix/box2d/B2DebugDraw.hx`](../src/helix/box2d/B2DebugDraw.hx), `import helix.box2d.B2DebugDraw;`

The functions and options `b2World_Draw` uses to draw a world. The program sets the functions it wants and Box2D calls them with world coordinates, so a program shifts into its own camera frame inside them. Make one with `b2DefaultDebugDraw`, whose functions do nothing, so a program may set only some of them.

```haxe
function new()
var DrawPolygonFcn:(transform:B2WorldTransform, vertices:Array<B2Vec2>, vertexCount:Int, color:B2HexColor, context:Dynamic) -> Void
var DrawSolidPolygonFcn:(transform:B2WorldTransform, vertices:Array<B2Vec2>, vertexCount:Int, radius:Float, color:B2HexColor, context:Dynamic) -> Void
var DrawCircleFcn:(center:B2Pos, radius:Float, color:B2HexColor, context:Dynamic) -> Void
var DrawSolidCircleFcn:(transform:B2WorldTransform, center:B2Vec2, radius:Float, color:B2HexColor, context:Dynamic) -> Void
var DrawSolidCapsuleFcn:(p1:B2Pos, p2:B2Pos, radius:Float, color:B2HexColor, context:Dynamic) -> Void
var DrawLineFcn:(p1:B2Pos, p2:B2Pos, color:B2HexColor, context:Dynamic) -> Void
var DrawTransformFcn:(transform:B2WorldTransform, context:Dynamic) -> Void
var DrawPointFcn:(p:B2Pos, size:Float, color:B2HexColor, context:Dynamic) -> Void
var DrawStringFcn:(p:B2Pos, s:String, color:B2HexColor, context:Dynamic) -> Void
var DrawBoundsFcn:(aabb:B2AABB, color:B2HexColor, context:Dynamic) -> Void
var drawingBounds:B2AABB
var forceScale:Float
var jointScale:Float
var drawContacts:Bool
var drawAnchorA:Bool
var drawShapes:Bool
var drawChainNormals:Bool
var drawJoints:Bool
var drawJointExtras:Bool
var drawBounds:Bool
var drawMass:Bool
var drawBodyNames:Bool
var drawGraphColors:Bool
var drawContactFeatures:Bool
var drawContactNormals:Bool
var drawContactForces:Bool
var drawFrictionForces:Bool
var drawIslands:Bool
var context:Dynamic
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultDebugDraw()` returns. The structs it holds are made with it.
- `DrawPolygonFcn`: Draws the outline of a closed polygon. Box2D calls it when drawing weld joints, once for the box of each joint frame. `transform` is the joint frame in the world, `vertices` are in that frame in counter-clockwise order from index 0 up to `vertexCount`, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawSolidPolygonFcn`: Draws a filled polygon. Box2D calls it for each polygon shape when `drawShapes` is true. `transform` is the body's transform in the world, `vertices` are in the body's frame in counter-clockwise order from index 0 up to `vertexCount`, `radius` rounds its corners (0 for none), and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawCircleFcn`: Draws the outline of a circle. Box2D calls it when drawing revolute joints. `center` is the circle's center in the world, `radius` its radius, and `color` the color to draw with. `context` is the debug draw object's `context`.
- `DrawSolidCircleFcn`: Draws a filled circle. Box2D calls it for each circle shape when `drawShapes` is true. `transform` is the body's transform in the world, `center` is the circle's center in the body's frame, `radius` its radius, and `color` the color to draw with. `context` is the debug draw object's `context`.
- `DrawSolidCapsuleFcn`: Draws a filled capsule. Box2D calls it for each capsule shape when `drawShapes` is true. `p1` and `p2` are the centers of the two semicircles in the world, `radius` is their radius, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawLineFcn`: Draws a line segment. Box2D calls it for segment and chain segment shapes when `drawShapes` is true, and for joints, chain normals, the movement of the center of mass and force arrows when their options are on. `p1` and `p2` are the end points in the world, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawTransformFcn`: Draws the axes of a transform, with a length of the program's choosing. Box2D calls it for the center of mass of each dynamic body when `drawMass` is true. `transform` is the center of mass and rotation in the world. `context` is the debug draw object's `context`.
- `DrawPointFcn`: Draws a point. Box2D calls it for the ends of chain segments, joint anchors and contact points when their options are on. `p` is the point in the world, `size` is its size, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawStringFcn`: Draws text. Box2D calls it for body names, masses, contact features and forces, and joint forces when their options are on. `p` is the text's position in the world, `s` is the text, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `DrawBoundsFcn`: Draws a bounding box. Box2D calls it for each shape's box when `drawBounds` is true, and for each island's box when `drawIslands` is true. `aabb` is the box in the world, and `color` is the color to draw with. `context` is the debug draw object's `context`.
- `drawingBounds`: The part of the world to draw. Shapes outside it are skipped, and an empty box draws nothing. Defaults to the whole world.
- `forceScale`: The scale of the arrows drawn for forces. Defaults to 1.
- `jointScale`: The scale of everything drawn for joints. Defaults to 1.
- `drawContacts`: Whether contact points are drawn. Defaults to false.
- `drawAnchorA`: Whether contact points are drawn at anchor A rather than anchor B. Defaults to false.
- `drawShapes`: Whether shapes are drawn. Defaults to true.
- `drawChainNormals`: Whether the normals of chain shape segments are drawn. Defaults to false.
- `drawJoints`: Whether joints are drawn. Defaults to false.
- `drawJointExtras`: Whether extra information is drawn for joints, such as limits and forces. Defaults to false.
- `drawBounds`: Whether the bounding boxes of shapes are drawn. Defaults to false.
- `drawMass`: Whether the mass and center of mass of dynamic bodies are drawn. Defaults to false.
- `drawBodyNames`: Whether body names are drawn. Defaults to false.
- `drawGraphColors`: Whether contacts and joints are colored by the solver's constraint graph color. Defaults to false.
- `drawContactFeatures`: Whether the feature ids of contact points are drawn. Defaults to false.
- `drawContactNormals`: Whether contact normals are drawn. Defaults to false.
- `drawContactForces`: Whether the normal forces of contacts are drawn. Defaults to false.
- `drawFrictionForces`: Whether the friction forces of contacts are drawn. Defaults to false.
- `drawIslands`: Whether simulation islands are drawn as bounding boxes. Defaults to false.
- `context`: Any Haxe value the program keeps with the debug draw object, passed to each drawing function as `context` and returned as set. Defaults to null.

## B2DistanceInput

*class* in [`libs/box2d/src/helix/box2d/B2DistanceInput.hx`](../src/helix/box2d/B2DistanceInput.hx), `import helix.box2d.B2DistanceInput;`

The input of `b2ComputeShapeDistance`.

```haxe
function new()
var proxyA:B2ShapeProxy
var proxyB:B2ShapeProxy
var transform:B2Transform
var useRadii:Bool
```

- `new`: Creates one, its fields zero.
- `proxyA`: The proxy for shape A.
- `proxyB`: The proxy for shape B.
- `transform`: The pose of shape B in the frame of shape A.
- `useRadii`: Whether the radii of the proxies count in the distance.

## B2DistanceJointDef

*class* in [`libs/box2d/src/helix/box2d/B2DistanceJointDef.hx`](../src/helix/box2d/B2DistanceJointDef.hx), `import helix.box2d.B2DistanceJointDef;`

Keeps a point on body A and a point on body B at a distance, like a segment. Useful for ropes and springs.

```haxe
function new()
var base:B2JointDef
var length:Float
var enableSpring:Bool
var lowerSpringForce:Float
var upperSpringForce:Float
var hertz:Float
var dampingRatio:Float
var enableLimit:Bool
var minLength:Float
var maxLength:Float
var enableMotor:Bool
var maxMotorForce:Float
var motorSpeed:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultDistanceJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `length`: The rest length of the joint, in length units. Clamped to a stable minimum. Defaults to 1.
- `enableSpring`: Whether the joint acts as a spring. When false the joint is rigid, and its limit and motor are ignored. Defaults to false.
- `lowerSpringForce`: The most tension the spring can sustain, as a force. Defaults to the most negative float.
- `upperSpringForce`: The most compression the spring can sustain, as a force. Defaults to the largest float.
- `hertz`: The spring stiffness, in cycles per second. Defaults to 0.
- `dampingRatio`: The spring damping ratio, non-dimensional. Defaults to 0.
- `enableLimit`: Whether the joint keeps its length between `minLength` and `maxLength`. Defaults to false.
- `minLength`: The shortest length for the limit, in length units. Clamped to a stable minimum. Defaults to 0.
- `maxLength`: The longest length for the limit, in length units. At least `minLength`. Defaults to `B2_HUGE`.
- `enableMotor`: Whether the joint motor is on. Defaults to false.
- `maxMotorForce`: The most force the motor applies, usually in newtons. Defaults to 0.
- `motorSpeed`: The speed the motor aims for, usually in meters per second. Defaults to 0.

## B2DistanceOutput

*class* in [`libs/box2d/src/helix/box2d/B2DistanceOutput.hx`](../src/helix/box2d/B2DistanceOutput.hx), `import helix.box2d.B2DistanceOutput;`

The output of `b2ComputeShapeDistance`. Box2D fills it.

```haxe
function new()
var pointA:B2Vec2
var pointB:B2Vec2
var normal:B2Vec2
var distance:Float
var iterations:Int
var simplexCount:Int
```

- `new`: Creates one, its fields zero.
- `pointA`: Closest point on shapeA, in shape A's frame.
- `pointB`: Closest point on shapeB, in shape A's frame.
- `normal`: A to B normal in shape A's frame. Invalid if distance is zero.
- `distance`: The final distance, zero if overlapped.
- `iterations`: Number of GJK iterations used.
- `simplexCount`: The number of simplexes stored in the simplex array.

## B2ExplosionDef

*class* in [`libs/box2d/src/helix/box2d/B2ExplosionDef.hx`](../src/helix/box2d/B2ExplosionDef.hx), `import helix.box2d.B2ExplosionDef;`

Configures an explosion for `b2World_Explode`. The explosion considers each shape's geometry when it computes the impulse, and applies to circles, capsules and polygons.

```haxe
function new()
var maskBits:haxe.Int64
var position:B2Pos
var radius:Float
var falloff:Float
var impulsePerLength:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultExplosionDef()` returns. The structs it holds are made with it.
- `maskBits`: The categories of shape the explosion affects. Defaults to all bits.
- `position`: The center of the explosion, in the world. Defaults to the origin.
- `radius`: The radius of the explosion, in length units. Defaults to 0.
- `falloff`: The distance beyond the radius over which the impulse falls to zero, in length units. Defaults to 0.
- `impulsePerLength`: The impulse applied for each unit of the shape's perimeter that faces the explosion. Negative for an implosion. Defaults to 0.

## B2Filter

*class* in [`libs/box2d/src/helix/box2d/B2Filter.hx`](../src/helix/box2d/B2Filter.hx), `import helix.box2d.B2Filter;`

Decides which shapes collide. It applies to shape against shape and to shapes found by a query such as `b2World_CastRay`.

```haxe
function new()
var categoryBits:haxe.Int64
var maskBits:haxe.Int64
var groupIndex:Int
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultFilter()` returns. The structs it holds are made with it.
- `categoryBits`: The categories the shape belongs to, usually one bit for each kind of object in the program, such as static, dynamic or player. Defaults to 1.
- `maskBits`: The categories the shape collides with. A player might collide with static objects and other players only. Defaults to all bits.
- `groupIndex`: A group of shapes that never collide (negative) or always collide (positive), whatever the mask bits say. 0 has no effect. A ragdoll whose shapes share one unique negative index does not collide with itself. Defaults to 0.

## B2FilterJointDef

*class* in [`libs/box2d/src/helix/box2d/B2FilterJointDef.hx`](../src/helix/box2d/B2FilterJointDef.hx), `import helix.box2d.B2FilterJointDef;`

Stops two specific bodies from colliding with each other.

```haxe
function new()
var base:B2JointDef
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultFilterJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.

## B2FrictionCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2FrictionCallbackFcn.hx`](../src/helix/box2d/B2FrictionCallbackFcn.hx), `import helix.box2d.B2FrictionCallbackFcn;`

A callback that mixes the friction of two touching shapes into one coefficient. Box2D calls it for each contact when it is set on the world, instead of its own mixing. It has no context value because Box2D may call it from a worker thread. It must not modify Box2D's state or the program's.

- `frictionA`: The friction coefficient of the first shape.
- `userMaterialIdA`: The user material id of the first shape's material.
- `frictionB`: The friction coefficient of the second shape.
- `userMaterialIdB`: The user material id of the second shape's material.
- returns: The mixed friction coefficient the contact uses.

An alias of `(frictionA:Float, userMaterialIdA:haxe.Int64, frictionB:Float, userMaterialIdB:haxe.Int64) -> Float`.

## B2HexColor

*abstract* in [`libs/box2d/src/helix/box2d/B2HexColor.hx`](../src/helix/box2d/B2HexColor.hx), `import helix.box2d.B2HexColor;`

These colors are used for debug draw and mostly match the named SVG colors.

- `B2HexColor.b2_colorAliceBlue`: The SVG color alice blue, 0xF0F8FF.
- `B2HexColor.b2_colorAntiqueWhite`: The SVG color antique white, 0xFAEBD7.
- `B2HexColor.b2_colorAqua`: The SVG color aqua, 0x00FFFF.
- `B2HexColor.b2_colorAquamarine`: The SVG color aquamarine, 0x7FFFD4.
- `B2HexColor.b2_colorAzure`: The SVG color azure, 0xF0FFFF.
- `B2HexColor.b2_colorBeige`: The SVG color beige, 0xF5F5DC.
- `B2HexColor.b2_colorBisque`: The SVG color bisque, 0xFFE4C4.
- `B2HexColor.b2_colorBlack`: The SVG color black, 0x000000.
- `B2HexColor.b2_colorBlanchedAlmond`: The SVG color blanched almond, 0xFFEBCD.
- `B2HexColor.b2_colorBlue`: The SVG color blue, 0x0000FF.
- `B2HexColor.b2_colorBlueViolet`: The SVG color blue violet, 0x8A2BE2.
- `B2HexColor.b2_colorBrown`: The SVG color brown, 0xA52A2A.
- `B2HexColor.b2_colorBurlywood`: The SVG color burlywood, 0xDEB887.
- `B2HexColor.b2_colorCadetBlue`: The SVG color cadet blue, 0x5F9EA0.
- `B2HexColor.b2_colorChartreuse`: The SVG color chartreuse, 0x7FFF00.
- `B2HexColor.b2_colorChocolate`: The SVG color chocolate, 0xD2691E.
- `B2HexColor.b2_colorCoral`: The SVG color coral, 0xFF7F50.
- `B2HexColor.b2_colorCornflowerBlue`: The SVG color cornflower blue, 0x6495ED.
- `B2HexColor.b2_colorCornsilk`: The SVG color cornsilk, 0xFFF8DC.
- `B2HexColor.b2_colorCrimson`: The SVG color crimson, 0xDC143C.
- `B2HexColor.b2_colorCyan`: The SVG color cyan, 0x00FFFF.
- `B2HexColor.b2_colorDarkBlue`: The SVG color dark blue, 0x00008B.
- `B2HexColor.b2_colorDarkCyan`: The SVG color dark cyan, 0x008B8B.
- `B2HexColor.b2_colorDarkGoldenRod`: The SVG color dark golden rod, 0xB8860B.
- `B2HexColor.b2_colorDarkGray`: The SVG color dark gray, 0xA9A9A9.
- `B2HexColor.b2_colorDarkGreen`: The SVG color dark green, 0x006400.
- `B2HexColor.b2_colorDarkKhaki`: The SVG color dark khaki, 0xBDB76B.
- `B2HexColor.b2_colorDarkMagenta`: The SVG color dark magenta, 0x8B008B.
- `B2HexColor.b2_colorDarkOliveGreen`: The SVG color dark olive green, 0x556B2F.
- `B2HexColor.b2_colorDarkOrange`: The SVG color dark orange, 0xFF8C00.
- `B2HexColor.b2_colorDarkOrchid`: The SVG color dark orchid, 0x9932CC.
- `B2HexColor.b2_colorDarkRed`: The SVG color dark red, 0x8B0000.
- `B2HexColor.b2_colorDarkSalmon`: The SVG color dark salmon, 0xE9967A.
- `B2HexColor.b2_colorDarkSeaGreen`: The SVG color dark sea green, 0x8FBC8F.
- `B2HexColor.b2_colorDarkSlateBlue`: The SVG color dark slate blue, 0x483D8B.
- `B2HexColor.b2_colorDarkSlateGray`: The SVG color dark slate gray, 0x2F4F4F.
- `B2HexColor.b2_colorDarkTurquoise`: The SVG color dark turquoise, 0x00CED1.
- `B2HexColor.b2_colorDarkViolet`: The SVG color dark violet, 0x9400D3.
- `B2HexColor.b2_colorDeepPink`: The SVG color deep pink, 0xFF1493.
- `B2HexColor.b2_colorDeepSkyBlue`: The SVG color deep sky blue, 0x00BFFF.
- `B2HexColor.b2_colorDimGray`: The SVG color dim gray, 0x696969.
- `B2HexColor.b2_colorDodgerBlue`: The SVG color dodger blue, 0x1E90FF.
- `B2HexColor.b2_colorFireBrick`: The SVG color fire brick, 0xB22222.
- `B2HexColor.b2_colorFloralWhite`: The SVG color floral white, 0xFFFAF0.
- `B2HexColor.b2_colorForestGreen`: The SVG color forest green, 0x228B22.
- `B2HexColor.b2_colorFuchsia`: The SVG color fuchsia, 0xFF00FF.
- `B2HexColor.b2_colorGainsboro`: The SVG color gainsboro, 0xDCDCDC.
- `B2HexColor.b2_colorGhostWhite`: The SVG color ghost white, 0xF8F8FF.
- `B2HexColor.b2_colorGold`: The SVG color gold, 0xFFD700.
- `B2HexColor.b2_colorGoldenRod`: The SVG color golden rod, 0xDAA520.
- `B2HexColor.b2_colorGray`: The SVG color gray, 0x808080.
- `B2HexColor.b2_colorGreen`: The SVG color green, 0x008000.
- `B2HexColor.b2_colorGreenYellow`: The SVG color green yellow, 0xADFF2F.
- `B2HexColor.b2_colorHoneyDew`: The SVG color honey dew, 0xF0FFF0.
- `B2HexColor.b2_colorHotPink`: The SVG color hot pink, 0xFF69B4.
- `B2HexColor.b2_colorIndianRed`: The SVG color indian red, 0xCD5C5C.
- `B2HexColor.b2_colorIndigo`: The SVG color indigo, 0x4B0082.
- `B2HexColor.b2_colorIvory`: The SVG color ivory, 0xFFFFF0.
- `B2HexColor.b2_colorKhaki`: The SVG color khaki, 0xF0E68C.
- `B2HexColor.b2_colorLavender`: The SVG color lavender, 0xE6E6FA.
- `B2HexColor.b2_colorLavenderBlush`: The SVG color lavender blush, 0xFFF0F5.
- `B2HexColor.b2_colorLawnGreen`: The SVG color lawn green, 0x7CFC00.
- `B2HexColor.b2_colorLemonChiffon`: The SVG color lemon chiffon, 0xFFFACD.
- `B2HexColor.b2_colorLightBlue`: The SVG color light blue, 0xADD8E6.
- `B2HexColor.b2_colorLightCoral`: The SVG color light coral, 0xF08080.
- `B2HexColor.b2_colorLightCyan`: The SVG color light cyan, 0xE0FFFF.
- `B2HexColor.b2_colorLightGoldenRodYellow`: The SVG color light golden rod yellow, 0xFAFAD2.
- `B2HexColor.b2_colorLightGray`: The SVG color light gray, 0xD3D3D3.
- `B2HexColor.b2_colorLightGreen`: The SVG color light green, 0x90EE90.
- `B2HexColor.b2_colorLightPink`: The SVG color light pink, 0xFFB6C1.
- `B2HexColor.b2_colorLightSalmon`: The SVG color light salmon, 0xFFA07A.
- `B2HexColor.b2_colorLightSeaGreen`: The SVG color light sea green, 0x20B2AA.
- `B2HexColor.b2_colorLightSkyBlue`: The SVG color light sky blue, 0x87CEFA.
- `B2HexColor.b2_colorLightSlateGray`: The SVG color light slate gray, 0x778899.
- `B2HexColor.b2_colorLightSteelBlue`: The SVG color light steel blue, 0xB0C4DE.
- `B2HexColor.b2_colorLightYellow`: The SVG color light yellow, 0xFFFFE0.
- `B2HexColor.b2_colorLime`: The SVG color lime, 0x00FF00.
- `B2HexColor.b2_colorLimeGreen`: The SVG color lime green, 0x32CD32.
- `B2HexColor.b2_colorLinen`: The SVG color linen, 0xFAF0E6.
- `B2HexColor.b2_colorMagenta`: The SVG color magenta, 0xFF00FF.
- `B2HexColor.b2_colorMaroon`: The SVG color maroon, 0x800000.
- `B2HexColor.b2_colorMediumAquaMarine`: The SVG color medium aqua marine, 0x66CDAA.
- `B2HexColor.b2_colorMediumBlue`: The SVG color medium blue, 0x0000CD.
- `B2HexColor.b2_colorMediumOrchid`: The SVG color medium orchid, 0xBA55D3.
- `B2HexColor.b2_colorMediumPurple`: The SVG color medium purple, 0x9370DB.
- `B2HexColor.b2_colorMediumSeaGreen`: The SVG color medium sea green, 0x3CB371.
- `B2HexColor.b2_colorMediumSlateBlue`: The SVG color medium slate blue, 0x7B68EE.
- `B2HexColor.b2_colorMediumSpringGreen`: The SVG color medium spring green, 0x00FA9A.
- `B2HexColor.b2_colorMediumTurquoise`: The SVG color medium turquoise, 0x48D1CC.
- `B2HexColor.b2_colorMediumVioletRed`: The SVG color medium violet red, 0xC71585.
- `B2HexColor.b2_colorMidnightBlue`: The SVG color midnight blue, 0x191970.
- `B2HexColor.b2_colorMintCream`: The SVG color mint cream, 0xF5FFFA.
- `B2HexColor.b2_colorMistyRose`: The SVG color misty rose, 0xFFE4E1.
- `B2HexColor.b2_colorMoccasin`: The SVG color moccasin, 0xFFE4B5.
- `B2HexColor.b2_colorNavajoWhite`: The SVG color navajo white, 0xFFDEAD.
- `B2HexColor.b2_colorNavy`: The SVG color navy, 0x000080.
- `B2HexColor.b2_colorOldLace`: The SVG color old lace, 0xFDF5E6.
- `B2HexColor.b2_colorOlive`: The SVG color olive, 0x808000.
- `B2HexColor.b2_colorOliveDrab`: The SVG color olive drab, 0x6B8E23.
- `B2HexColor.b2_colorOrange`: The SVG color orange, 0xFFA500.
- `B2HexColor.b2_colorOrangeRed`: The SVG color orange red, 0xFF4500.
- `B2HexColor.b2_colorOrchid`: The SVG color orchid, 0xDA70D6.
- `B2HexColor.b2_colorPaleGoldenRod`: The SVG color pale golden rod, 0xEEE8AA.
- `B2HexColor.b2_colorPaleGreen`: The SVG color pale green, 0x98FB98.
- `B2HexColor.b2_colorPaleTurquoise`: The SVG color pale turquoise, 0xAFEEEE.
- `B2HexColor.b2_colorPaleVioletRed`: The SVG color pale violet red, 0xDB7093.
- `B2HexColor.b2_colorPapayaWhip`: The SVG color papaya whip, 0xFFEFD5.
- `B2HexColor.b2_colorPeachPuff`: The SVG color peach puff, 0xFFDAB9.
- `B2HexColor.b2_colorPeru`: The SVG color peru, 0xCD853F.
- `B2HexColor.b2_colorPink`: The SVG color pink, 0xFFC0CB.
- `B2HexColor.b2_colorPlum`: The SVG color plum, 0xDDA0DD.
- `B2HexColor.b2_colorPowderBlue`: The SVG color powder blue, 0xB0E0E6.
- `B2HexColor.b2_colorPurple`: The SVG color purple, 0x800080.
- `B2HexColor.b2_colorRebeccaPurple`: The SVG color rebecca purple, 0x663399.
- `B2HexColor.b2_colorRed`: The SVG color red, 0xFF0000.
- `B2HexColor.b2_colorRosyBrown`: The SVG color rosy brown, 0xBC8F8F.
- `B2HexColor.b2_colorRoyalBlue`: The SVG color royal blue, 0x4169E1.
- `B2HexColor.b2_colorSaddleBrown`: The SVG color saddle brown, 0x8B4513.
- `B2HexColor.b2_colorSalmon`: The SVG color salmon, 0xFA8072.
- `B2HexColor.b2_colorSandyBrown`: The SVG color sandy brown, 0xF4A460.
- `B2HexColor.b2_colorSeaGreen`: The SVG color sea green, 0x2E8B57.
- `B2HexColor.b2_colorSeaShell`: The SVG color sea shell, 0xFFF5EE.
- `B2HexColor.b2_colorSienna`: The SVG color sienna, 0xA0522D.
- `B2HexColor.b2_colorSilver`: The SVG color silver, 0xC0C0C0.
- `B2HexColor.b2_colorSkyBlue`: The SVG color sky blue, 0x87CEEB.
- `B2HexColor.b2_colorSlateBlue`: The SVG color slate blue, 0x6A5ACD.
- `B2HexColor.b2_colorSlateGray`: The SVG color slate gray, 0x708090.
- `B2HexColor.b2_colorSnow`: The SVG color snow, 0xFFFAFA.
- `B2HexColor.b2_colorSpringGreen`: The SVG color spring green, 0x00FF7F.
- `B2HexColor.b2_colorSteelBlue`: The SVG color steel blue, 0x4682B4.
- `B2HexColor.b2_colorTan`: The SVG color tan, 0xD2B48C.
- `B2HexColor.b2_colorTeal`: The SVG color teal, 0x008080.
- `B2HexColor.b2_colorThistle`: The SVG color thistle, 0xD8BFD8.
- `B2HexColor.b2_colorTomato`: The SVG color tomato, 0xFF6347.
- `B2HexColor.b2_colorTurquoise`: The SVG color turquoise, 0x40E0D0.
- `B2HexColor.b2_colorViolet`: The SVG color violet, 0xEE82EE.
- `B2HexColor.b2_colorWheat`: The SVG color wheat, 0xF5DEB3.
- `B2HexColor.b2_colorWhite`: The SVG color white, 0xFFFFFF.
- `B2HexColor.b2_colorWhiteSmoke`: The SVG color white smoke, 0xF5F5F5.
- `B2HexColor.b2_colorYellow`: The SVG color yellow, 0xFFFF00.
- `B2HexColor.b2_colorYellowGreen`: The SVG color yellow green, 0x9ACD32.
- `B2HexColor.b2_colorBox2DRed`: The Box2D logo color red, 0xDC3132.
- `B2HexColor.b2_colorBox2DBlue`: The Box2D logo color blue, 0x30AEBF.
- `B2HexColor.b2_colorBox2DGreen`: The Box2D logo color green, 0x8CC924.
- `B2HexColor.b2_colorBox2DYellow`: The Box2D logo color yellow, 0xFFEE8C.

## B2Hull

*class* in [`libs/box2d/src/helix/box2d/B2Hull.hx`](../src/helix/box2d/B2Hull.hx), `import helix.box2d.B2Hull;`

A convex hull of points, made by `b2ComputeHull`.

```haxe
function new()
var points:Array<B2Vec2>
var count:Int
```

- `new`: Creates one, its fields zero.
- `points`: The points of the hull, from index 0 up to `count`.
- `count`: The number of points.

## B2JointDef

*class* in [`libs/box2d/src/helix/box2d/B2JointDef.hx`](../src/helix/box2d/B2JointDef.hx), `import helix.box2d.B2JointDef;`

The settings every joint type shares, held in the `base` field of each joint definition. The local frames are measured from each body's origin and not its center of mass, since the center of mass may not be known yet and changes when shapes are added or removed.

```haxe
function new()
var userData:Dynamic
var bodyIdA:B2BodyId
var bodyIdB:B2BodyId
var localFrameA:B2Transform
var localFrameB:B2Transform
var forceThreshold:Float
var torqueThreshold:Float
var constraintHertz:Float
var constraintDampingRatio:Float
var drawScale:Float
var collideConnected:Bool
```

- `new`: Creates one holding the base values that every joint's default definition starts from, as `b2DefaultDistanceJointDef()` and the other default functions set in their `base`.
- `userData`: Any Haxe value the program keeps with the joint, returned as set. Defaults to null.
- `bodyIdA`: The first attached body. Defaults to the null id, which must be replaced.
- `bodyIdB`: The second attached body. Defaults to the null id, which must be replaced.
- `localFrameA`: The joint's frame in the first body, measured from the body's origin. Defaults to the body's origin with no rotation.
- `localFrameB`: The joint's frame in the second body, measured from the body's origin. Defaults to the body's origin with no rotation.
- `forceThreshold`: The force above which an awake joint reports a joint event, in newtons. Defaults to the largest float, so none is reported.
- `torqueThreshold`: The torque above which an awake joint reports a joint event, in newton-meters. Defaults to the largest float, so none is reported.
- `constraintHertz`: The stiffness of the joint's constraint, in cycles per second. An advanced setting. Defaults to 60.
- `constraintDampingRatio`: The damping ratio of the joint's constraint, non-dimensional. An advanced setting. Defaults to 2.
- `drawScale`: The scale of the joint when debug drawn. Defaults to the world's length units per meter.
- `collideConnected`: Whether the two attached bodies collide with each other. Defaults to false.

## B2JointEvent

*class* in [`libs/box2d/src/helix/box2d/B2JointEvent.hx`](../src/helix/box2d/B2JointEvent.hx), `import helix.box2d.B2JointEvent;`

Reports an awake joint whose force or torque exceeds its threshold. The force and torque themselves are not reported.

```haxe
function new()
var jointId:B2JointId
var userData:Dynamic
```

- `new`: Creates one, its fields zero.
- `jointId`: The id of the joint.
- `userData`: The `userData` of the joint, returned as set.

## B2JointEvents

*class* in [`libs/box2d/src/helix/box2d/B2JointEvents.hx`](../src/helix/box2d/B2JointEvents.hx), `import helix.box2d.B2JointEvents;`

The joint events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying joints makes them invalid.

```haxe
function new()
var jointEvents:Array<B2JointEvent>
var count:Int
```

- `new`: Creates one, its fields zero.
- `jointEvents`: The joint events, from index 0 up to `count`. The array may be longer when it is reused.
- `count`: The number of joint events.

## B2JointId

*class* in [`libs/box2d/src/helix/box2d/B2JointId.hx`](../src/helix/box2d/B2JointId.hx), `import helix.box2d.B2JointId;`

References a joint. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var world0:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the object plus one. Opaque to a program.
- `world0`: Box2D's index of the world the object belongs to. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2JointType

*abstract* in [`libs/box2d/src/helix/box2d/B2JointType.hx`](../src/helix/box2d/B2JointType.hx), `import helix.box2d.B2JointType;`

Joint type enumeration.

- `B2JointType.b2_distanceJoint`: Constrain the distance between two points.
- `B2JointType.b2_filterJoint`: Filter collision between two bodies.
- `B2JointType.b2_motorJoint`: Fully control the movement of a body.
- `B2JointType.b2_moverJoint`: Control the movement of the dynamic character mover.
- `B2JointType.b2_pogoJoint`: Ground interaction for the dynamic character mover.
- `B2JointType.b2_prismaticJoint`: Slide along an axis.
- `B2JointType.b2_revoluteJoint`: Rotate around a pivot.
- `B2JointType.b2_weldJoint`: Bring two bodies together with some flex.
- `B2JointType.b2_wheelJoint`: Wheel spins with shock absorber.

## B2LocalManifold

*class* in [`libs/box2d/src/helix/box2d/B2LocalManifold.hx`](../src/helix/box2d/B2LocalManifold.hx), `import helix.box2d.B2LocalManifold;`

Describes the contact points between two shapes in local coordinates, the frame of shape A. Box2D fills it.

```haxe
function new()
var normal:B2Vec2
var points:Array<B2LocalManifoldPoint>
var pointCount:Int
```

- `new`: Creates one, its fields zero.
- `normal`: The unit normal in frame A, pointing from shape A to shape B.
- `points`: The manifold points, from index 0 up to `pointCount`. A manifold in 2D has at most two.
- `pointCount`: The number of manifold points: 0, 1 or 2.

## B2LocalManifoldPoint

*class* in [`libs/box2d/src/helix/box2d/B2LocalManifoldPoint.hx`](../src/helix/box2d/B2LocalManifoldPoint.hx), `import helix.box2d.B2LocalManifoldPoint;`

One contact point of a local manifold, in the frame of shape A. Box2D fills it.

```haxe
function new()
var point:B2Vec2
var separation:Float
var id:Int
```

- `new`: Creates one, its fields zero.
- `point`: The contact point in frame A.
- `separation`: The separation of the contact point, in length units. Negative when the shapes penetrate.
- `id`: Identifies the contact point between the two shapes.

## B2LogCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2LogCallbackFcn.hx`](../src/helix/box2d/B2LogCallbackFcn.hx), `import helix.box2d.B2LogCallbackFcn;`

A callback that receives Box2D's log messages. Box2D calls it when it logs a warning, such as when it rejects invalid input.

- `message`: The text of the message.

An alias of `(message:String) -> Void`.

## B2Manifold

*class* in [`libs/box2d/src/helix/box2d/B2Manifold.hx`](../src/helix/box2d/B2Manifold.hx), `import helix.box2d.B2Manifold;`

Describes the contact points between two colliding shapes. Box2D uses speculative collision, so some points may be separated. Box2D fills it.

```haxe
function new()
var normal:B2Vec2
var rollingImpulse:Float
var points:Array<B2ManifoldPoint>
var pointCount:Int
```

- `new`: Creates one, its fields zero.
- `normal`: The unit normal in the world, pointing from shape A to shape B.
- `rollingImpulse`: The angular impulse applied for rolling resistance, in newton-meter-seconds.
- `points`: The manifold points, from index 0 up to `pointCount`. A manifold in 2D has at most two.
- `pointCount`: The number of manifold points: 0, 1 or 2.

## B2ManifoldPoint

*class* in [`libs/box2d/src/helix/box2d/B2ManifoldPoint.hx`](../src/helix/box2d/B2ManifoldPoint.hx), `import helix.box2d.B2ManifoldPoint;`

One contact point of a manifold. Box2D fills it.

```haxe
function new()
var anchorA:B2Vec2
var anchorB:B2Vec2
var separation:Float
var normalImpulse:Float
var tangentImpulse:Float
var totalNormalImpulse:Float
var normalVelocity:Float
var baseSeparation:Float
var id:Int
var persisted:Bool
```

- `new`: Creates one, its fields zero.
- `anchorA`: The contact point relative to body A's center of mass, in world orientation. Add it to `b2Body_GetWorldCenter` of body A to get the world point.
- `anchorB`: The contact point relative to body B's center of mass, in world orientation.
- `separation`: The separation of the contact point, in length units. Negative when the shapes penetrate.
- `normalImpulse`: The impulse along the manifold normal.
- `tangentImpulse`: The friction impulse.
- `totalNormalImpulse`: The whole normal impulse applied across sub-steps and restitution. A positive value marks a speculative point that was involved in the step.
- `normalVelocity`: The relative velocity along the normal before the solve. Negative when the shapes approach. It is reliable only when hit events are enabled.
- `baseSeparation`: The separation Box2D keeps to recycle the contact, in length units.
- `id`: Identifies the contact point between the two shapes.
- `persisted`: Whether the contact point existed in the previous step.

## B2MassData

*class* in [`libs/box2d/src/helix/box2d/B2MassData.hx`](../src/helix/box2d/B2MassData.hx), `import helix.box2d.B2MassData;`

This holds the mass data computed for a shape.

```haxe
function new(?mass:Float = 0., ?center:B2Vec2, ?rotationalInertia:Float = 0.)
var mass:Float
var center:B2Vec2
var rotationalInertia:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `mass`: Optional. The mass of the shape, usually in kilograms.
  - `center`: Optional. The position of the shape's centroid relative to the shape's origin.
  - `rotationalInertia`: Optional. The rotational inertia of the shape about the shape center.
- `mass`: The mass of the shape, usually in kilograms.
- `center`: The position of the shape's centroid relative to the shape's origin.
- `rotationalInertia`: The rotational inertia of the shape about the shape center.

## B2Mat22

*class* in [`libs/box2d/src/helix/box2d/B2Mat22.hx`](../src/helix/box2d/B2Mat22.hx), `import helix.box2d.B2Mat22;`

A 2-by-2 matrix stored as two column vectors.

```haxe
function new(?cx:B2Vec2, ?cy:B2Vec2)
var cx:B2Vec2
var cy:B2Vec2
```

- `new`: Creates one, as C's initializer lists its fields.
  - `cx`: Optional. The first column. A zero vector when omitted.
  - `cy`: Optional. The second column. A zero vector when omitted.
- `cx`: The first column.
- `cy`: The second column.

## B2MotionLocks

*class* in [`libs/box2d/src/helix/box2d/B2MotionLocks.hx`](../src/helix/box2d/B2MotionLocks.hx), `import helix.box2d.B2MotionLocks;`

Motion locks to restrict the body movement.

```haxe
function new(?linearX:Bool = false, ?linearY:Bool = false, ?angularZ:Bool = false)
var linearX:Bool
var linearY:Bool
var angularZ:Bool
```

- `new`: Creates one, as C's initializer lists its fields.
  - `linearX`: Optional. Prevent translation along the x-axis.
  - `linearY`: Optional. Prevent translation along the y-axis.
  - `angularZ`: Optional. Prevent rotation around the z-axis.
- `linearX`: Prevent translation along the x-axis.
- `linearY`: Prevent translation along the y-axis.
- `angularZ`: Prevent rotation around the z-axis.

## B2MotorJointDef

*class* in [`libs/box2d/src/helix/box2d/B2MotorJointDef.hx`](../src/helix/box2d/B2MotorJointDef.hx), `import helix.box2d.B2MotorJointDef;`

Controls the relative velocity, and optionally the relative transform, of two bodies. With a velocity of zero it acts like top-down friction.

```haxe
function new()
var base:B2JointDef
var linearVelocity:B2Vec2
var maxVelocityForce:Float
var angularVelocity:Float
var maxVelocityTorque:Float
var linearHertz:Float
var linearDampingRatio:Float
var maxSpringForce:Float
var angularHertz:Float
var angularDampingRatio:Float
var maxSpringTorque:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultMotorJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `linearVelocity`: The linear velocity to aim for, in meters per second. Defaults to zero.
- `maxVelocityForce`: The most force the motor applies to reach the linear velocity, in newtons. Defaults to 0.
- `angularVelocity`: The angular velocity to aim for, in radians per second. Defaults to 0.
- `maxVelocityTorque`: The most torque the motor applies to reach the angular velocity, in newton-meters. Defaults to 0.
- `linearHertz`: The stiffness of the linear spring that holds the relative position, in cycles per second. Defaults to 0.
- `linearDampingRatio`: The damping ratio of the linear spring, non-dimensional. Defaults to 0.
- `maxSpringForce`: The most force the linear spring applies, in newtons. Defaults to 0.
- `angularHertz`: The stiffness of the angular spring that holds the relative angle, in cycles per second. Defaults to 0.
- `angularDampingRatio`: The damping ratio of the angular spring, non-dimensional. Defaults to 0.
- `maxSpringTorque`: The most torque the angular spring applies, in newton-meters. Defaults to 0.

## B2OverlapResultCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2OverlapResultCallbackFcn.hx`](../src/helix/box2d/B2OverlapResultCallbackFcn.hx), `import helix.box2d.B2OverlapResultCallbackFcn;`

A callback for overlap queries. Box2D calls it for each shape the query finds.

- `shapeId`: The shape found.
- `context`: The value the program provided to the query call, returned as it was.
- returns: True to continue the query, false to stop it.

An alias of `(shapeId:B2ShapeId, context:Dynamic) -> Bool`.

## B2Plane

*class* in [`libs/box2d/src/helix/box2d/B2Plane.hx`](../src/helix/box2d/B2Plane.hx), `import helix.box2d.B2Plane;`

A plane in 2D, the set of points where `dot(normal, point) - offset` is zero. That value is a point's signed separation from the plane.

```haxe
function new(?normal:B2Vec2, ?offset:Float = 0.)
var normal:B2Vec2
var offset:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `normal`: Optional. The unit normal. A zero vector when omitted.
  - `offset`: Optional. The offset. Zero when omitted.
- `normal`: The unit normal of the plane.
- `offset`: The plane's offset from the origin along the normal, in length units.

## B2Polygon

*class* in [`libs/box2d/src/helix/box2d/B2Polygon.hx`](../src/helix/box2d/B2Polygon.hx), `import helix.box2d.B2Polygon;`

A solid convex polygon with at most `B2_MAX_POLYGON_VERTICES` vertices, optionally rounded by a radius.

```haxe
function new()
var vertices:Array<B2Vec2>
var normals:Array<B2Vec2>
var centroid:B2Vec2
var radius:Float
var count:Int
```

- `new`: Creates one, its fields zero.
- `vertices`: The vertices, from index 0 up to `count`.
- `normals`: The outward unit normals of the sides, from index 0 up to `count`. Side `i` runs from vertex `i` to the next.
- `centroid`: The centroid of the polygon.
- `radius`: The radius that rounds the corners, in length units. 0 for sharp corners.
- `count`: The number of vertices.

## B2Pos

*typedef* in [`libs/box2d/src/helix/box2d/B2Pos.hx`](../src/helix/box2d/B2Pos.hx), `import helix.box2d.B2Pos;`

Box2D's `b2Pos`: a `B2Vec2` in Box2D's single precision build.

An alias of [`B2Vec2`](types.md#b2vec2).

## B2PreContinuousCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2PreContinuousCallbackFcn.hx`](../src/helix/box2d/B2PreContinuousCallbackFcn.hx), `import helix.box2d.B2PreContinuousCallbackFcn;`

A callback that can skip a continuous collision event. Box2D calls it when a time of impact event is computed for a shape that has pre-solve events enabled, on an awake dynamic body. It is not called for sensors. Natively it can be called from a worker thread, so it must not modify the world. Only a point and normal are provided because the contact's manifold may not exist yet or may be stale.

- `shapeIdA`: The first shape.
- `shapeIdB`: The second shape.
- `point`: The point of the event, in world coordinates.
- `normal`: The unit normal of the event.
- `context`: The value the program provided with the callback, returned as it was.
- returns: False to skip the time of impact event, true to keep it.

An alias of `(shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, point:B2Pos, normal:B2Vec2, context:Dynamic) -> Bool`.

## B2PreSolveCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2PreSolveCallbackFcn.hx`](../src/helix/box2d/B2PreSolveCallbackFcn.hx), `import helix.box2d.B2PreSolveCallbackFcn;`

A callback that inspects a contact manifold before it goes to the solver. Box2D calls it after a contact's manifold is updated, for a shape that has pre-solve events enabled, on an awake dynamic body. It is not called for sensors. Natively it can be called from a worker thread, so it must not modify the world. It may change the manifold, such as its normal, and setting the manifold's `pointCount` to 0 disables the collision. The manifold's impulses are not reliable here.

- `shapeIdA`: The first shape.
- `shapeIdB`: The second shape.
- `manifold`: The contact manifold, which the callback may modify.
- `context`: The value the program provided with the callback, returned as it was.

An alias of `(shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, manifold:B2Manifold, context:Dynamic) -> Void`.

## B2PrismaticJointDef

*class* in [`libs/box2d/src/helix/box2d/B2PrismaticJointDef.hx`](../src/helix/box2d/B2PrismaticJointDef.hx), `import helix.box2d.B2PrismaticJointDef;`

Lets body B slide along the x-axis of the local frame in body A, with no rotation relative to it.

```haxe
function new()
var base:B2JointDef
var enableSpring:Bool
var hertz:Float
var dampingRatio:Float
var targetTranslation:Float
var enableLimit:Bool
var lowerTranslation:Float
var upperTranslation:Float
var enableMotor:Bool
var maxMotorForce:Float
var motorSpeed:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultPrismaticJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `enableSpring`: Whether a linear spring acts along the joint axis. Defaults to false.
- `hertz`: The spring stiffness, in cycles per second. Defaults to 0.
- `dampingRatio`: The spring damping ratio, non-dimensional. Defaults to 0.
- `targetTranslation`: The translation the spring aims for, in length units. Defaults to 0.
- `enableLimit`: Whether the translation is limited. Defaults to false.
- `lowerTranslation`: The lowest translation the limit allows, in length units. Defaults to 0.
- `upperTranslation`: The highest translation the limit allows, in length units. Defaults to 0.
- `enableMotor`: Whether the joint motor is on. Defaults to false.
- `maxMotorForce`: The most force the motor applies, typically in newtons. Defaults to 0.
- `motorSpeed`: The speed the motor aims for, typically in meters per second. Defaults to 0.

## B2Profile

*class* in [`libs/box2d/src/helix/box2d/B2Profile.hx`](../src/helix/box2d/B2Profile.hx), `import helix.box2d.B2Profile;`

The time each part of the last world step used, in milliseconds. `b2World_GetProfile` returns one that Box2D fills.

```haxe
function new()
var step:Float
var pairs:Float
var collide:Float
var solve:Float
var solverSetup:Float
var constraints:Float
var prepareConstraints:Float
var integrateVelocities:Float
var warmStart:Float
var solveImpulses:Float
var integratePositions:Float
var relaxImpulses:Float
var restitution:Float
var storeImpulses:Float
var splitIslands:Float
var transforms:Float
var sensorHits:Float
var jointEvents:Float
var hitEvents:Float
var refit:Float
var bullets:Float
var sleepIslands:Float
var sensors:Float
```

- `new`: Creates one, its fields zero.
- `step`: Milliseconds spent: the whole step.
- `pairs`: Milliseconds spent: updating the broad-phase pairs, which finds new contacts.
- `collide`: Milliseconds spent: updating contacts, the narrow phase.
- `solve`: Milliseconds spent: the solver stage, all of the constraint solving and integration.
- `solverSetup`: Milliseconds spent: preparing the solver's data for the step.
- `constraints`: Milliseconds spent: solving the constraints, in all its stages.
- `prepareConstraints`: Milliseconds spent: preparing the contact and joint constraints.
- `integrateVelocities`: Milliseconds spent: integrating velocities from forces and gravity.
- `warmStart`: Milliseconds spent: warm starting the constraints with the last step's impulses.
- `solveImpulses`: Milliseconds spent: solving the constraints' impulses.
- `integratePositions`: Milliseconds spent: integrating positions from velocities.
- `relaxImpulses`: Milliseconds spent: relaxing the constraints' impulses.
- `restitution`: Milliseconds spent: applying restitution.
- `storeImpulses`: Milliseconds spent: storing impulses to warm start the next step.
- `splitIslands`: Milliseconds spent: splitting islands that are no longer connected.
- `transforms`: Milliseconds spent: updating the transforms and broad-phase boxes of bodies that moved.
- `sensorHits`: Milliseconds spent: finding sensor overlaps for moving shapes.
- `jointEvents`: Milliseconds spent: reporting joint events.
- `hitEvents`: Milliseconds spent: reporting contact hit events.
- `refit`: Milliseconds spent: refitting the broad-phase trees.
- `bullets`: Milliseconds spent: continuous collision for bullet bodies.
- `sleepIslands`: Milliseconds spent: putting islands to sleep.
- `sensors`: Milliseconds spent: updating sensor events.

## B2QueryFilter

*class* in [`libs/box2d/src/helix/box2d/B2QueryFilter.hx`](../src/helix/box2d/B2QueryFilter.hx), `import helix.box2d.B2QueryFilter;`

Decides which shapes a query finds, such as a ray cast. A projectile's ray might find players and the static environment but not debris.

```haxe
function new()
var categoryBits:haxe.Int64
var maskBits:haxe.Int64
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultQueryFilter()` returns. The structs it holds are made with it.
- `categoryBits`: The categories of the query, usually one bit. Defaults to 1.
- `maskBits`: The shape categories the query finds. Defaults to all bits.

## B2RayCastInput

*class* in [`libs/box2d/src/helix/box2d/B2RayCastInput.hx`](../src/helix/box2d/B2RayCastInput.hx), `import helix.box2d.B2RayCastInput;`

Low level ray cast input data.

```haxe
function new(?origin:B2Vec2, ?translation:B2Vec2, ?maxFraction:Float = 0.)
var origin:B2Vec2
var translation:B2Vec2
var maxFraction:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `origin`: Optional. Start point of the ray cast.
  - `translation`: Optional. Translation of the ray cast.
  - `maxFraction`: Optional. The maximum fraction of the translation to consider, typically 1.
- `origin`: Start point of the ray cast.
- `translation`: Translation of the ray cast.
- `maxFraction`: The maximum fraction of the translation to consider, typically 1.

## B2RayResult

*class* in [`libs/box2d/src/helix/box2d/B2RayResult.hx`](../src/helix/box2d/B2RayResult.hx), `import helix.box2d.B2RayResult;`

The result of `b2World_CastRayClosest`. Box2D fills it. If the ray starts overlapping a shape, the fraction and normal are zero and the point is an arbitrary point in the overlap.

```haxe
function new()
var shapeId:B2ShapeId
var point:B2Pos
var normal:B2Vec2
var fraction:Float
var nodeVisits:Int
var leafVisits:Int
var hit:Bool
```

- `new`: Creates one, its fields zero.
- `shapeId`: The shape hit.
- `point`: The point of contact, on the surface of the hit shape.
- `normal`: The unit normal vector at the point of contact.
- `fraction`: The fraction of the input ray.
- `nodeVisits`: The number of BVH nodes visited. Diagnostic.
- `leafVisits`: The number of BVH leaves visited. Diagnostic.
- `hit`: Did the ray hit? If false, all other data is invalid.

## B2RestitutionCallbackFcn

*typedef* in [`libs/box2d/src/helix/box2d/B2RestitutionCallbackFcn.hx`](../src/helix/box2d/B2RestitutionCallbackFcn.hx), `import helix.box2d.B2RestitutionCallbackFcn;`

A callback that mixes the restitution of two touching shapes into one coefficient. Box2D calls it for each contact when it is set on the world, instead of its own mixing. It has no context value because Box2D may call it from a worker thread. It must not modify Box2D's state or the program's.

- `restitutionA`: The restitution of the first shape.
- `userMaterialIdA`: The user material id of the first shape's material.
- `restitutionB`: The restitution of the second shape.
- `userMaterialIdB`: The user material id of the second shape's material.
- returns: The mixed restitution the contact uses.

An alias of `(restitutionA:Float, userMaterialIdA:haxe.Int64, restitutionB:Float, userMaterialIdB:haxe.Int64) -> Float`.

## B2RevoluteJointDef

*class* in [`libs/box2d/src/helix/box2d/B2RevoluteJointDef.hx`](../src/helix/box2d/B2RevoluteJointDef.hx), `import helix.box2d.B2RevoluteJointDef;`

Fixes a point on body B to a point on body A, so the bodies rotate about it like a hinge.

```haxe
function new()
var base:B2JointDef
var targetAngle:Float
var enableSpring:Bool
var hertz:Float
var dampingRatio:Float
var enableLimit:Bool
var lowerAngle:Float
var upperAngle:Float
var enableMotor:Bool
var maxMotorTorque:Float
var motorSpeed:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultRevoluteJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `targetAngle`: The angle the spring aims for, in radians. Defaults to 0.
- `enableSpring`: Whether a rotational spring acts on the hinge. Defaults to false.
- `hertz`: The spring stiffness, in cycles per second. Defaults to 0.
- `dampingRatio`: The spring damping ratio, non-dimensional. Defaults to 0.
- `enableLimit`: Whether the angle is limited. Defaults to false.
- `lowerAngle`: The lowest angle the limit allows, in radians. At least -0.99 times pi. Defaults to 0.
- `upperAngle`: The highest angle the limit allows, in radians. At most 0.99 times pi. Defaults to 0.
- `enableMotor`: Whether the joint motor is on. Defaults to false.
- `maxMotorTorque`: The most torque the motor applies, typically in newton-meters. Defaults to 0.
- `motorSpeed`: The speed the motor aims for, in radians per second: body B's angular velocity relative to body A's. Positive turns body B counterclockwise relative to body A. Defaults to 0.

## B2Rot

*class* in [`libs/box2d/src/helix/box2d/B2Rot.hx`](../src/helix/box2d/B2Rot.hx), `import helix.box2d.B2Rot;`

A 2D rotation stored as its cosine and sine, like a unit complex number. Make one from an angle with `b2MakeRot`.

```haxe
function new(?c:Float = 1., ?s:Float = 0.)
var c:Float
var s:Float
```

- `new`: Creates one, as C's initializer lists its fields.
  - `c`: Optional. The cosine; 1 when omitted.
  - `s`: Optional. The sine; 0 when omitted. Both omitted, the rotation turns nothing.
- `c`: The cosine of the angle.
- `s`: The sine of the angle.

## B2Segment

*class* in [`libs/box2d/src/helix/box2d/B2Segment.hx`](../src/helix/box2d/B2Segment.hx), `import helix.box2d.B2Segment;`

A line segment with two-sided collision.

```haxe
function new(?point1:B2Vec2, ?point2:B2Vec2)
var point1:B2Vec2
var point2:B2Vec2
```

- `new`: Creates one, as C's initializer lists its fields.
  - `point1`: Optional. The first point.
  - `point2`: Optional. The second point.
- `point1`: The first point.
- `point2`: The second point.

## B2SegmentDistanceResult

*class* in [`libs/box2d/src/helix/box2d/B2SegmentDistanceResult.hx`](../src/helix/box2d/B2SegmentDistanceResult.hx), `import helix.box2d.B2SegmentDistanceResult;`

The result of computing the distance between two line segments. Box2D fills it.

```haxe
function new()
var closest1:B2Vec2
var closest2:B2Vec2
var fraction1:Float
var fraction2:Float
var distanceSquared:Float
```

- `new`: Creates one, its fields zero.
- `closest1`: The closest point on the first segment.
- `closest2`: The closest point on the second segment.
- `fraction1`: The barycentric coordinate on the first segment.
- `fraction2`: The barycentric coordinate on the second segment.
- `distanceSquared`: The squared distance between the closest points.

## B2SensorBeginTouchEvent

*class* in [`libs/box2d/src/helix/box2d/B2SensorBeginTouchEvent.hx`](../src/helix/box2d/B2SensorBeginTouchEvent.hx), `import helix.box2d.B2SensorBeginTouchEvent;`

Reports that a shape began overlapping a sensor shape.

```haxe
function new()
var sensorShapeId:B2ShapeId
var visitorShapeId:B2ShapeId
```

- `new`: Creates one, its fields zero.
- `sensorShapeId`: The id of the sensor shape.
- `visitorShapeId`: The id of the shape that began overlapping the sensor shape.

## B2SensorEndTouchEvent

*class* in [`libs/box2d/src/helix/box2d/B2SensorEndTouchEvent.hx`](../src/helix/box2d/B2SensorEndTouchEvent.hx), `import helix.box2d.B2SensorEndTouchEvent;`

Reports that a shape stopped overlapping a sensor shape. It is also reported when something other than movement ends the overlap: setting a body's transform, destroying a body or shape, or changing a filter. It is reported too when the sensor is destroyed, so check the ids with `b2Shape_IsValid`.

```haxe
function new()
var sensorShapeId:B2ShapeId
var visitorShapeId:B2ShapeId
```

- `new`: Creates one, its fields zero.
- `sensorShapeId`: The id of the sensor shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`.
- `visitorShapeId`: The id of the shape that stopped overlapping the sensor shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`.

## B2SensorEvents

*class* in [`libs/box2d/src/helix/box2d/B2SensorEvents.hx`](../src/helix/box2d/B2SensorEvents.hx), `import helix.box2d.B2SensorEvents;`

The sensor events of the last step, buffered in the world. Box2D fills it. Read the events right after the step, as the next step replaces them, and destroying bodies or shapes can make them invalid.

```haxe
function new()
var beginEvents:Array<B2SensorBeginTouchEvent>
var endEvents:Array<B2SensorEndTouchEvent>
var beginCount:Int
var endCount:Int
```

- `new`: Creates one, its fields zero.
- `beginEvents`: The sensor begin touch events, from index 0 up to `beginCount`. The array may be longer when it is reused.
- `endEvents`: The sensor end touch events, from index 0 up to `endCount`. The array may be longer when it is reused.
- `beginCount`: The number of sensor begin touch events.
- `endCount`: The number of sensor end touch events.

## B2ShapeCastInput

*class* in [`libs/box2d/src/helix/box2d/B2ShapeCastInput.hx`](../src/helix/box2d/B2ShapeCastInput.hx), `import helix.box2d.B2ShapeCastInput;`

The input of a shape cast against one shape, in a general form.

```haxe
function new()
var proxy:B2ShapeProxy
var translation:B2Vec2
var maxFraction:Float
var canEncroach:Bool
```

- `new`: Creates one, its fields zero.
- `proxy`: The shape to cast.
- `translation`: The translation of the cast.
- `maxFraction`: The largest fraction of the translation to consider, typically 1.
- `canEncroach`: Whether a shape with a radius may move slightly closer when it already touches.

## B2ShapeCastPairInput

*class* in [`libs/box2d/src/helix/box2d/B2ShapeCastPairInput.hx`](../src/helix/box2d/B2ShapeCastPairInput.hx), `import helix.box2d.B2ShapeCastPairInput;`

The input of `b2CastShape`, which casts one shape against another.

```haxe
function new()
var proxyA:B2ShapeProxy
var proxyB:B2ShapeProxy
var transform:B2Transform
var translationB:B2Vec2
var maxFraction:Float
var canEncroach:Bool
```

- `new`: Creates one, its fields zero.
- `proxyA`: The proxy for shape A.
- `proxyB`: The proxy for shape B.
- `transform`: The pose of shape B in the frame of shape A.
- `translationB`: The translation of shape B, in the frame of shape A.
- `maxFraction`: The largest fraction of the translation to consider, typically 1.
- `canEncroach`: Whether shapes with a radius may move slightly closer when they already touch.

## B2ShapeDef

*class* in [`libs/box2d/src/helix/box2d/B2ShapeDef.hx`](../src/helix/box2d/B2ShapeDef.hx), `import helix.box2d.B2ShapeDef;`

Everything needed to create a shape on a body, such as with `b2CreateCircleShape`. The definition can be reused for more shapes.

```haxe
function new()
var userData:Dynamic
var material:B2SurfaceMaterial
var density:Float
var filter:B2Filter
var enableCustomFiltering:Bool
var isSensor:Bool
var enableSensorEvents:Bool
var enableContactEvents:Bool
var enableHitEvents:Bool
var enablePreSolveEvents:Bool
var invokeContactCreation:Bool
var updateBodyMass:Bool
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultShapeDef()` returns. The structs it holds are made with it.
- `userData`: Any Haxe value the program keeps with the shape, returned as set. Defaults to null.
- `material`: The surface material of the shape. Defaults to a friction of 0.6 and zero for the rest.
- `density`: The density of the shape's interior, usually in kilograms per square meter. Defaults to 1.
- `filter`: Which shapes this shape collides with, and which queries find it. Defaults to category 1, colliding with all categories, in group 0.
- `enableCustomFiltering`: Whether the world's custom filter callback is asked about contacts of this shape. One of the two shapes involved needs it. See `b2World_SetCustomFilterCallback`. Defaults to false.
- `isSensor`: Whether the shape is a sensor. A sensor reports overlaps and never causes a collision response. A fast sensor may miss overlaps, so use a ray or shape cast for those. A sensor with density still adds to the body's mass. Defaults to false.
  _Note that a sensor reports events only when `enableSensorEvents` is true on it and on the shape it overlaps._
- `enableSensorEvents`: Whether sensor events are reported for this shape, whether it is a sensor or not. Both shapes involved need it. Defaults to false, even for sensors.
- `enableContactEvents`: Whether begin and end touch events are reported for this shape. Only applies to kinematic and dynamic bodies, and is ignored for sensors. One of the two shapes involved needs it. Defaults to false.
- `enableHitEvents`: Whether hit events are reported for this shape. Only applies to kinematic and dynamic bodies, and is ignored for sensors. One of the two shapes involved needs it. Defaults to false.
- `enablePreSolveEvents`: Whether the world's pre-solve callback is called for contacts of this shape. Only applies to dynamic bodies, and is ignored for sensors. It is expensive. Defaults to false.
- `invokeContactCreation`: Whether the new shape looks for collisions at the next step. Setting it to false speeds up creating many static shapes. Ignored for dynamic and kinematic shapes, which always look. Defaults to true.
- `updateBodyMass`: Whether the body's mass is recomputed when the shape is created. When false, call `b2Body_UpdateMassFromShapes` or `b2Body_SetMassData` before stepping the world. Defaults to true.

## B2ShapeId

*class* in [`libs/box2d/src/helix/box2d/B2ShapeId.hx`](../src/helix/box2d/B2ShapeId.hx), `import helix.box2d.B2ShapeId;`

References a shape. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var world0:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the object plus one. Opaque to a program.
- `world0`: Box2D's index of the world the object belongs to. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2ShapeProxy

*class* in [`libs/box2d/src/helix/box2d/B2ShapeProxy.hx`](../src/helix/box2d/B2ShapeProxy.hx), `import helix.box2d.B2ShapeProxy;`

A convex cloud of points, with a radius, that stands for a shape in the distance, cast and time of impact functions.

```haxe
function new()
var points:Array<B2Vec2>
var count:Int
var radius:Float
```

- `new`: Creates one, its fields zero.
- `points`: The points, from index 0 up to `count`.
- `count`: The number of points. Must be greater than 0.
- `radius`: The radius around the points, in length units. May be 0.

## B2ShapeType

*abstract* in [`libs/box2d/src/helix/box2d/B2ShapeType.hx`](../src/helix/box2d/B2ShapeType.hx), `import helix.box2d.B2ShapeType;`

Shape type.

- `B2ShapeType.b2_circleShape`: A circle with an offset.
- `B2ShapeType.b2_capsuleShape`: A capsule is an extruded circle.
- `B2ShapeType.b2_segmentShape`: A line segment.
- `B2ShapeType.b2_polygonShape`: A convex polygon.
- `B2ShapeType.b2_chainSegmentShape`: A line segment owned by a chain shape.
- `B2ShapeType.b2_shapeTypeCount`: The number of shape types.

## B2Simplex

*class* in [`libs/box2d/src/helix/box2d/B2Simplex.hx`](../src/helix/box2d/B2Simplex.hx), `import helix.box2d.B2Simplex;`

A simplex from the GJK distance algorithm, for debugging. Box2D fills it when `b2ComputeShapeDistance` is provided an array of them.

```haxe
function new()
var v1:B2SimplexVertex
var v2:B2SimplexVertex
var v3:B2SimplexVertex
var count:Int
```

- `new`: Creates one, its fields zero.
- `v1`: The first vertex.
- `v2`: The second vertex. Valid when `count` is at least 2.
- `v3`: The third vertex. Valid when `count` is 3.
- `count`: The number of valid vertices, 1 to 3.

## B2SimplexCache

*class* in [`libs/box2d/src/helix/box2d/B2SimplexCache.hx`](../src/helix/box2d/B2SimplexCache.hx), `import helix.box2d.B2SimplexCache;`

Warm starts `b2ComputeShapeDistance` with the simplex of an earlier call on the same shapes. Start with `b2_emptySimplexCache`.

```haxe
function new()
var count:Int
var indexA:Array<Int>
var indexB:Array<Int>
```

- `new`: Creates one, its fields zero.
- `count`: The number of stored simplex points.
- `indexA`: The cached indices of the simplex points on shape A, from index 0 up to `count`.
- `indexB`: The cached indices of the simplex points on shape B, from index 0 up to `count`.

## B2SimplexVertex

*class* in [`libs/box2d/src/helix/box2d/B2SimplexVertex.hx`](../src/helix/box2d/B2SimplexVertex.hx), `import helix.box2d.B2SimplexVertex;`

A vertex of the simplex of the GJK distance algorithm, for debugging. Box2D fills it.

```haxe
function new()
var wA:B2Vec2
var wB:B2Vec2
var w:B2Vec2
var a:Float
var indexA:Int
var indexB:Int
```

- `new`: Creates one, its fields zero.
- `wA`: The support point in proxy A.
- `wB`: The support point in proxy B.
- `w`: The difference `wB - wA`.
- `a`: The barycentric coordinate of the closest point.
- `indexA`: The index of `wA` in proxy A's points.
- `indexB`: The index of `wB` in proxy B's points.

## B2SurfaceMaterial

*class* in [`libs/box2d/src/helix/box2d/B2SurfaceMaterial.hx`](../src/helix/box2d/B2SurfaceMaterial.hx), `import helix.box2d.B2SurfaceMaterial;`

The surface properties of a shape, which is the 2D boundary. A chain can have one for each segment.

```haxe
function new()
var friction:Float
var restitution:Float
var rollingResistance:Float
var tangentSpeed:Float
var userMaterialId:haxe.Int64
var customColor:Int
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultSurfaceMaterial()` returns. The structs it holds are made with it.
- `friction`: The Coulomb (dry) friction coefficient, usually 0 to 1. Defaults to 0.6.
- `restitution`: The coefficient of restitution (bounce), usually 0 to 1. Defaults to 0.
- `rollingResistance`: The rolling resistance, usually 0 to 1. Defaults to 0.
- `tangentSpeed`: The speed of the surface along its tangent, in meters per second, as on a conveyor belt. Defaults to 0.
- `userMaterialId`: A number the program chooses to identify the material. It is passed to the friction and restitution callbacks and returned with query results, and Box2D doesn't use it otherwise. Defaults to 0.
- `customColor`: The color to debug draw the shape with, as 0xRRGGBB. Defaults to 0, which draws the usual color.

## B2Sweep

*class* in [`libs/box2d/src/helix/box2d/B2Sweep.hx`](../src/helix/box2d/B2Sweep.hx), `import helix.box2d.B2Sweep;`

Describes the motion of a body or shape for a time of impact computation. The body moves linearly from its starting to its ending center of mass and rotation.

```haxe
function new()
var localCenter:B2Vec2
var c1:B2Vec2
var c2:B2Vec2
var q1:B2Rot
var q2:B2Rot
```

- `new`: Creates one, its fields zero.
- `localCenter`: The center of mass in the body's frame.
- `c1`: The center of mass in the world at the start.
- `c2`: The center of mass in the world at the end.
- `q1`: The rotation in the world at the start.
- `q2`: The rotation in the world at the end.

## B2TOIInput

*class* in [`libs/box2d/src/helix/box2d/B2TOIInput.hx`](../src/helix/box2d/B2TOIInput.hx), `import helix.box2d.B2TOIInput;`

The input of `b2ComputeTimeOfImpact`.

```haxe
function new()
var proxyA:B2ShapeProxy
var proxyB:B2ShapeProxy
var sweepA:B2Sweep
var sweepB:B2Sweep
var maxFraction:Float
```

- `new`: Creates one, its fields zero.
- `proxyA`: The proxy for shape A.
- `proxyB`: The proxy for shape B.
- `sweepA`: The movement of shape A.
- `sweepB`: The movement of shape B.
- `maxFraction`: The end of the sweep interval, which runs from 0 to this fraction.

## B2TOIOutput

*class* in [`libs/box2d/src/helix/box2d/B2TOIOutput.hx`](../src/helix/box2d/B2TOIOutput.hx), `import helix.box2d.B2TOIOutput;`

The output of a time of impact computation. Box2D fills it.

```haxe
function new()
var state:B2TOIState
var point:B2Vec2
var normal:B2Vec2
var fraction:Float
```

- `new`: Creates one, its fields zero.
- `state`: The type of result.
- `point`: The hit point.
- `normal`: The hit normal.
- `fraction`: The sweep time of the collision.

## B2TOIState

*abstract* in [`libs/box2d/src/helix/box2d/B2TOIState.hx`](../src/helix/box2d/B2TOIState.hx), `import helix.box2d.B2TOIState;`

The result of a time of impact computation, `B2TOIOutput.state`.

- `B2TOIState.b2_toiStateUnknown`: The computation didn't finish or hasn't run.
- `B2TOIState.b2_toiStateFailed`: The root finder failed, and the fraction is the last time known to be safe.
- `B2TOIState.b2_toiStateOverlapped`: The shapes already overlap at the start of the sweep, and the fraction is 0.
- `B2TOIState.b2_toiStateHit`: The shapes come within the target separation, and the fraction is when.
- `B2TOIState.b2_toiStateSeparated`: The shapes stay separated for the whole sweep, and the fraction is the sweep's end.

## B2Transform

*class* in [`libs/box2d/src/helix/box2d/B2Transform.hx`](../src/helix/box2d/B2Transform.hx), `import helix.box2d.B2Transform;`

A 2D rigid transform, a rotation and a translation.

```haxe
function new(?p:B2Vec2, ?q:B2Rot)
var p:B2Vec2
var q:B2Rot
```

- `new`: Creates one, as C's initializer lists its fields.
  - `p`: Optional. The translation. A zero vector when omitted.
  - `q`: Optional. The rotation. When omitted, the rotation that turns nothing (`b2Rot_identity`).
- `p`: The translation, in length units.
- `q`: The rotation.

## B2TreeStats

*class* in [`libs/box2d/src/helix/box2d/B2TreeStats.hx`](../src/helix/box2d/B2TreeStats.hx), `import helix.box2d.B2TreeStats;`

Performance results of a dynamic tree query. Box2D fills it.

```haxe
function new()
var nodeVisits:Int
var leafVisits:Int
```

- `new`: Creates one, its fields zero.
- `nodeVisits`: Number of internal nodes visited during the query.
- `leafVisits`: Number of leaf nodes visited during the query.

## B2Vec2

*abstract* in [`libs/box2d/src/helix/box2d/B2Vec2.hx`](../src/helix/box2d/B2Vec2.hx), `import helix.box2d.B2Vec2;`

Represents Box2D's `b2Vec2`: a point, a direction, a velocity or a size. Wraps helix-math's `Vector2`, whose fields and methods it also has, and is passed as a `Vector2` without a copy.

Box2D reads each component as a 32-bit float, so a value set here is rounded to the nearest 32-bit float as Box2D reads it.

_Note that a `B2Vec2` is assigned by reference, where C copies a `b2Vec2`. A function returning one accepts an optional `out` that receives the result, and makes a new `B2Vec2` when `out` is omitted._

## B2Version

*class* in [`libs/box2d/src/helix/box2d/B2Version.hx`](../src/helix/box2d/B2Version.hx), `import helix.box2d.B2Version;`

Version numbering scheme.

```haxe
function new(?major:Int = 0, ?minor:Int = 0, ?revision:Int = 0)
var major:Int
var minor:Int
var revision:Int
```

- `new`: Creates one, as C's initializer lists its fields.
  - `major`: Optional. Significant changes.
  - `minor`: Optional. Incremental changes.
  - `revision`: Optional. Bug fixes.
- `major`: Significant changes.
- `minor`: Incremental changes.
- `revision`: Bug fixes.

## B2WeldJointDef

*class* in [`libs/box2d/src/helix/box2d/B2WeldJointDef.hx`](../src/helix/box2d/B2WeldJointDef.hx), `import helix.box2d.B2WeldJointDef;`

Connects two bodies together rigidly, or with some flex when the stiffness is set.

```haxe
function new()
var base:B2JointDef
var linearHertz:Float
var angularHertz:Float
var linearDampingRatio:Float
var angularDampingRatio:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultWeldJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `linearHertz`: The linear stiffness, in cycles per second. 0 is the maximum stiffness. Defaults to 0.
- `angularHertz`: The angular stiffness, in cycles per second. 0 is the maximum stiffness. Defaults to 0.
- `linearDampingRatio`: The linear damping ratio, non-dimensional. 1 is critical damping. Defaults to 0.
- `angularDampingRatio`: The angular damping ratio, non-dimensional. 1 is critical damping. Defaults to 0.

## B2WheelJointDef

*class* in [`libs/box2d/src/helix/box2d/B2WheelJointDef.hx`](../src/helix/box2d/B2WheelJointDef.hx), `import helix.box2d.B2WheelJointDef;`

Makes body B a wheel that rotates freely and slides along the x-axis of the local frame in body A, usually with a spring for the suspension.

```haxe
function new()
var base:B2JointDef
var enableSpring:Bool
var hertz:Float
var dampingRatio:Float
var enableLimit:Bool
var lowerTranslation:Float
var upperTranslation:Float
var enableMotor:Bool
var maxMotorTorque:Float
var motorSpeed:Float
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultWheelJointDef()` returns. The structs it holds are made with it.
- `base`: Base joint definition. Its bodies, frames and thresholds are set here.
- `enableSpring`: Whether a linear spring acts along the local axis. Defaults to true.
- `hertz`: The spring stiffness, in cycles per second. Defaults to 1.
- `dampingRatio`: The spring damping ratio, non-dimensional. Defaults to 0.7.
- `enableLimit`: Whether the translation along the axis is limited. Defaults to false.
- `lowerTranslation`: The lowest translation the limit allows, in length units. Defaults to 0.
- `upperTranslation`: The highest translation the limit allows, in length units. Defaults to 0.
- `enableMotor`: Whether the rotational motor is on. Defaults to false.
- `maxMotorTorque`: The most torque the motor applies, typically in newton-meters. Defaults to 0.
- `motorSpeed`: The speed the motor aims for, in radians per second: body B's angular velocity relative to body A's. Positive turns body B counterclockwise relative to body A, so a wheel rolling toward +x on level ground needs a negative speed. Defaults to 0.

## B2WorldCastOutput

*typedef* in [`libs/box2d/src/helix/box2d/B2WorldCastOutput.hx`](../src/helix/box2d/B2WorldCastOutput.hx), `import helix.box2d.B2WorldCastOutput;`

Box2D's `b2WorldCastOutput`: a `B2CastOutput` in Box2D's single precision build.

An alias of [`B2CastOutput`](types.md#b2castoutput).

## B2WorldDef

*class* in [`libs/box2d/src/helix/box2d/B2WorldDef.hx`](../src/helix/box2d/B2WorldDef.hx), `import helix.box2d.B2WorldDef;`

Everything needed to create a world with `b2CreateWorld`.

```haxe
function new()
var gravity:B2Vec2
var restitutionThreshold:Float
var restitutionIterations:Int
var enableRestitutionPropagation:Bool
var hitEventThreshold:Float
var contactHertz:Float
var contactDampingRatio:Float
var contactSpeed:Float
var maximumLinearSpeed:Float
var frictionCallback:B2FrictionCallbackFcn
var restitutionCallback:B2RestitutionCallbackFcn
var enableSleep:Bool
var enableContinuous:Bool
var workerCount:Int
var userData:Dynamic
var capacity:B2Capacity
```

- `new`: Creates one holding Box2D's defaults, as `b2DefaultWorldDef()` returns. The structs it holds are made with it.
- `gravity`: The gravity, in meters per second squared. Box2D has no up direction. Defaults to (0, -10).
- `restitutionThreshold`: The approach speed, in meters per second, above which collisions bounce. Defaults to 1 meter per second.
- `restitutionIterations`: The number of iterations of the restitution solver. More iterations can mean less box spinning. Defaults to 2.
- `enableRestitutionPropagation`: Whether the restitution solver propagates through whole contact chains. Experimental and expensive. Defaults to false.
- `hitEventThreshold`: The approach speed, in meters per second, above which a hit event is reported. Defaults to 1 meter per second.
- `contactHertz`: The contact stiffness, in cycles per second. Raising it recovers from overlap faster but may add jitter. Defaults to 30.
- `contactDampingRatio`: The contact damping ratio, non-dimensional. Lowering it recovers from overlap faster, with a more energetic result. Defaults to 10.
- `contactSpeed`: The most speed, in meters per second, at which overlap is resolved. It caps the recovery speed only, which the hertz and damping ratio also set. Defaults to 3 meters per second.
- `maximumLinearSpeed`: The most speed a body may have, in meters per second. Defaults to 400 meters per second.
- `frictionCallback`: An optional function that mixes the friction of two touching shapes. Defaults to null, which mixes as the square root of the two coefficients multiplied.
- `restitutionCallback`: An optional function that mixes the restitution of two touching shapes. Defaults to null, which mixes as the larger of the two coefficients.
- `enableSleep`: Whether bodies may fall asleep, which improves performance. Defaults to true.
- `enableContinuous`: Whether continuous collision is used to stop fast bodies from tunneling. Defaults to true.
- `workerCount`: The number of workers for multithreading. Natively, a count above 1 runs Box2D's own threads, and 0 or 1 runs one thread. The count is limited to Box2D's maximum number of workers. Defaults to 0.
  _Note that in a page the module runs one worker, whatever the count._
- `userData`: Any Haxe value the program keeps with the world, returned as set. Defaults to null.
- `capacity`: Expected counts that let Box2D reserve memory when the world is created. Defaults to zero for all of them, reserving nothing.

## B2WorldId

*class* in [`libs/box2d/src/helix/box2d/B2WorldId.hx`](../src/helix/box2d/B2WorldId.hx), `import helix.box2d.B2WorldId;`

References a world. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it.

```haxe
function new()
var index1:Int
var generation:Int
```

- `new`: Creates one, its fields zero.
- `index1`: Box2D's index of the world plus one. Opaque to a program.
- `generation`: Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program.

## B2WorldTransform

*typedef* in [`libs/box2d/src/helix/box2d/B2WorldTransform.hx`](../src/helix/box2d/B2WorldTransform.hx), `import helix.box2d.B2WorldTransform;`

Box2D's `b2WorldTransform`: a `B2Transform` in Box2D's single precision build.

An alias of [`B2Transform`](types.md#b2transform).

## Box2D

*class* in [`libs/box2d/src/helix/box2d/Box2D.hx`](../src/helix/box2d/Box2D.hx), `import helix.box2d.Box2D;`

Provides Box2D 3.2: loading the module, Box2D's functions under their C names, and its constants.

A program loads the module once, then calls Box2D as C does:

```haxe
import helix.box2d.*;
import helix.box2d.Box2D.*;

Box2D.loadAsync(() -> {
var worldDef = b2DefaultWorldDef();
worldDef.gravity = new B2Vec2(0, -10);
var worldId = b2CreateWorld(worldDef);

var bodyDef = b2DefaultBodyDef();
bodyDef.type = b2_dynamicBody;
bodyDef.position = new B2Vec2(0, 4);
var bodyId = b2CreateBody(worldId, bodyDef);
b2CreatePolygonShape(bodyId, b2DefaultShapeDef(), b2MakeBox(1, 1));

for (i in 0...90)
b2World_Step(worldId, 1 / 60, 4);
});
```

Natively, Box2D is compiled into the program, and `loadAsync` calls `loaded` before returning. In a page, `loadAsync` fetches the module (`box2d.wasm`) and calls `loaded` once the module runs.

The build of Box2D the module holds is single precision and cross-platform deterministic: the same steps from the same state produce the same bits natively and in a page.

Box2D's types are Haxe types named as Box2D names them with a capital first letter (`b2BodyDef` is `B2BodyDef`), as Haxe requires; functions, fields, enum values and constants keep Box2D's names. A struct Box2D passes by value is a Haxe object, which the garbage collector frees; a function returning one accepts an optional `out` that receives the result. What Box2D holds (a world, a body, a shape, a joint, a chain) is reached by its id and lives in the module until it is destroyed.

A def from its `b2Default` function, or from its constructor, holds Box2D's defaults, with the structs it holds already made (`def.base.localFrameA.p`, `shapeDef.material.friction`), so their fields are set directly. An `out` is filled in place, and an array a call fills reuses the elements it holds and grows as needed, so a step's reads allocate nothing when each is passed the same one.

A callback is a Haxe function. The ids, vectors and structs it receives are reused from one call to the next, so it copies one it keeps. Natively, a callback Box2D calls during a step (a filter, pre-solve, friction or restitution) may run on one of Box2D's threads when the world has more than one worker.

```haxe
static function loadAsync(loaded:() -> Void, ?failed:String -> Void, ?wasmUrl:String):Void
static inline var B2_AABB_MARGIN_FRACTION:Float
static inline var B2_CONTACT_RECYCLE_COS_ANGLE:Float
static var B2_CONTACT_RECYCLE_DISTANCE(get, never):Float
static var B2_DEFAULT_CATEGORY_BITS(get, never):haxe.Int64
static var B2_DEFAULT_MASK_BITS(get, never):haxe.Int64
static inline var B2_GRAPH_COLOR_COUNT:Int
static inline var B2_HASH_INIT:Int
static var B2_HUGE(get, never):Float
static var B2_LINEAR_SLOP(get, never):Float
static var B2_MAX_AABB_MARGIN(get, never):Float
static inline var B2_MAX_POLYGON_VERTICES:Int
static inline var B2_MAX_RESTITUTION_ITERATIONS:Int
static inline var B2_MAX_ROTATION:Float
static inline var B2_MAX_TASKS:Int
static inline var B2_MAX_WORKERS:Int
static inline var B2_MAX_WORLDS:Int
static inline var B2_NAME_LENGTH:Int
static inline var B2_NULL_INDEX:Int
static inline var B2_PI:Float
static var B2_SPECULATIVE_DISTANCE(get, never):Float
static inline var B2_TIME_TO_SLEEP:Float
static inline var B2_VERSION_MAJOR:Int
static inline var B2_VERSION_MINOR:Int
static inline var B2_VERSION_REVISION:Int
static function B2_IS_NULL(id:{index1:Int}):Bool
static function B2_IS_NON_NULL(id:{index1:Int}):Bool
static function B2_ID_EQUALS(id1:{world0:Int, index1:Int, generation:Int}, id2:{world0:Int, index1:Int, generation:Int}):Bool
static var b2Mat22_zero(get, never):B2Mat22
static var b2Pos_zero(get, never):B2Pos
static var b2Rot_identity(get, never):B2Rot
static var b2Transform_identity(get, never):B2Transform
static var b2Vec2_zero(get, never):B2Vec2
static var b2WorldTransform_identity(get, never):B2WorldTransform
static var b2_emptySimplexCache(get, never):B2SimplexCache
static var b2_lengthUnitsPerMeter(get, never):Float
static var b2_nullWorldId(get, never):B2WorldId
static var b2_nullBodyId(get, never):B2BodyId
static var b2_nullShapeId(get, never):B2ShapeId
static var b2_nullChainId(get, never):B2ChainId
static var b2_nullJointId(get, never):B2JointId
static var b2_nullContactId(get, never):B2ContactId
static inline var b2_staticBody:B2BodyType
static inline var b2_kinematicBody:B2BodyType
static inline var b2_dynamicBody:B2BodyType
static inline var b2_bodyTypeCount:B2BodyType
static inline var b2_colorAliceBlue:B2HexColor
static inline var b2_colorAntiqueWhite:B2HexColor
static inline var b2_colorAqua:B2HexColor
static inline var b2_colorAquamarine:B2HexColor
static inline var b2_colorAzure:B2HexColor
static inline var b2_colorBeige:B2HexColor
static inline var b2_colorBisque:B2HexColor
static inline var b2_colorBlack:B2HexColor
static inline var b2_colorBlanchedAlmond:B2HexColor
static inline var b2_colorBlue:B2HexColor
static inline var b2_colorBlueViolet:B2HexColor
static inline var b2_colorBrown:B2HexColor
static inline var b2_colorBurlywood:B2HexColor
static inline var b2_colorCadetBlue:B2HexColor
static inline var b2_colorChartreuse:B2HexColor
static inline var b2_colorChocolate:B2HexColor
static inline var b2_colorCoral:B2HexColor
static inline var b2_colorCornflowerBlue:B2HexColor
static inline var b2_colorCornsilk:B2HexColor
static inline var b2_colorCrimson:B2HexColor
static inline var b2_colorCyan:B2HexColor
static inline var b2_colorDarkBlue:B2HexColor
static inline var b2_colorDarkCyan:B2HexColor
static inline var b2_colorDarkGoldenRod:B2HexColor
static inline var b2_colorDarkGray:B2HexColor
static inline var b2_colorDarkGreen:B2HexColor
static inline var b2_colorDarkKhaki:B2HexColor
static inline var b2_colorDarkMagenta:B2HexColor
static inline var b2_colorDarkOliveGreen:B2HexColor
static inline var b2_colorDarkOrange:B2HexColor
static inline var b2_colorDarkOrchid:B2HexColor
static inline var b2_colorDarkRed:B2HexColor
static inline var b2_colorDarkSalmon:B2HexColor
static inline var b2_colorDarkSeaGreen:B2HexColor
static inline var b2_colorDarkSlateBlue:B2HexColor
static inline var b2_colorDarkSlateGray:B2HexColor
static inline var b2_colorDarkTurquoise:B2HexColor
static inline var b2_colorDarkViolet:B2HexColor
static inline var b2_colorDeepPink:B2HexColor
static inline var b2_colorDeepSkyBlue:B2HexColor
static inline var b2_colorDimGray:B2HexColor
static inline var b2_colorDodgerBlue:B2HexColor
static inline var b2_colorFireBrick:B2HexColor
static inline var b2_colorFloralWhite:B2HexColor
static inline var b2_colorForestGreen:B2HexColor
static inline var b2_colorFuchsia:B2HexColor
static inline var b2_colorGainsboro:B2HexColor
static inline var b2_colorGhostWhite:B2HexColor
static inline var b2_colorGold:B2HexColor
static inline var b2_colorGoldenRod:B2HexColor
static inline var b2_colorGray:B2HexColor
static inline var b2_colorGreen:B2HexColor
static inline var b2_colorGreenYellow:B2HexColor
static inline var b2_colorHoneyDew:B2HexColor
static inline var b2_colorHotPink:B2HexColor
static inline var b2_colorIndianRed:B2HexColor
static inline var b2_colorIndigo:B2HexColor
static inline var b2_colorIvory:B2HexColor
static inline var b2_colorKhaki:B2HexColor
static inline var b2_colorLavender:B2HexColor
static inline var b2_colorLavenderBlush:B2HexColor
static inline var b2_colorLawnGreen:B2HexColor
static inline var b2_colorLemonChiffon:B2HexColor
static inline var b2_colorLightBlue:B2HexColor
static inline var b2_colorLightCoral:B2HexColor
static inline var b2_colorLightCyan:B2HexColor
static inline var b2_colorLightGoldenRodYellow:B2HexColor
static inline var b2_colorLightGray:B2HexColor
static inline var b2_colorLightGreen:B2HexColor
static inline var b2_colorLightPink:B2HexColor
static inline var b2_colorLightSalmon:B2HexColor
static inline var b2_colorLightSeaGreen:B2HexColor
static inline var b2_colorLightSkyBlue:B2HexColor
static inline var b2_colorLightSlateGray:B2HexColor
static inline var b2_colorLightSteelBlue:B2HexColor
static inline var b2_colorLightYellow:B2HexColor
static inline var b2_colorLime:B2HexColor
static inline var b2_colorLimeGreen:B2HexColor
static inline var b2_colorLinen:B2HexColor
static inline var b2_colorMagenta:B2HexColor
static inline var b2_colorMaroon:B2HexColor
static inline var b2_colorMediumAquaMarine:B2HexColor
static inline var b2_colorMediumBlue:B2HexColor
static inline var b2_colorMediumOrchid:B2HexColor
static inline var b2_colorMediumPurple:B2HexColor
static inline var b2_colorMediumSeaGreen:B2HexColor
static inline var b2_colorMediumSlateBlue:B2HexColor
static inline var b2_colorMediumSpringGreen:B2HexColor
static inline var b2_colorMediumTurquoise:B2HexColor
static inline var b2_colorMediumVioletRed:B2HexColor
static inline var b2_colorMidnightBlue:B2HexColor
static inline var b2_colorMintCream:B2HexColor
static inline var b2_colorMistyRose:B2HexColor
static inline var b2_colorMoccasin:B2HexColor
static inline var b2_colorNavajoWhite:B2HexColor
static inline var b2_colorNavy:B2HexColor
static inline var b2_colorOldLace:B2HexColor
static inline var b2_colorOlive:B2HexColor
static inline var b2_colorOliveDrab:B2HexColor
static inline var b2_colorOrange:B2HexColor
static inline var b2_colorOrangeRed:B2HexColor
static inline var b2_colorOrchid:B2HexColor
static inline var b2_colorPaleGoldenRod:B2HexColor
static inline var b2_colorPaleGreen:B2HexColor
static inline var b2_colorPaleTurquoise:B2HexColor
static inline var b2_colorPaleVioletRed:B2HexColor
static inline var b2_colorPapayaWhip:B2HexColor
static inline var b2_colorPeachPuff:B2HexColor
static inline var b2_colorPeru:B2HexColor
static inline var b2_colorPink:B2HexColor
static inline var b2_colorPlum:B2HexColor
static inline var b2_colorPowderBlue:B2HexColor
static inline var b2_colorPurple:B2HexColor
static inline var b2_colorRebeccaPurple:B2HexColor
static inline var b2_colorRed:B2HexColor
static inline var b2_colorRosyBrown:B2HexColor
static inline var b2_colorRoyalBlue:B2HexColor
static inline var b2_colorSaddleBrown:B2HexColor
static inline var b2_colorSalmon:B2HexColor
static inline var b2_colorSandyBrown:B2HexColor
static inline var b2_colorSeaGreen:B2HexColor
static inline var b2_colorSeaShell:B2HexColor
static inline var b2_colorSienna:B2HexColor
static inline var b2_colorSilver:B2HexColor
static inline var b2_colorSkyBlue:B2HexColor
static inline var b2_colorSlateBlue:B2HexColor
static inline var b2_colorSlateGray:B2HexColor
static inline var b2_colorSnow:B2HexColor
static inline var b2_colorSpringGreen:B2HexColor
static inline var b2_colorSteelBlue:B2HexColor
static inline var b2_colorTan:B2HexColor
static inline var b2_colorTeal:B2HexColor
static inline var b2_colorThistle:B2HexColor
static inline var b2_colorTomato:B2HexColor
static inline var b2_colorTurquoise:B2HexColor
static inline var b2_colorViolet:B2HexColor
static inline var b2_colorWheat:B2HexColor
static inline var b2_colorWhite:B2HexColor
static inline var b2_colorWhiteSmoke:B2HexColor
static inline var b2_colorYellow:B2HexColor
static inline var b2_colorYellowGreen:B2HexColor
static inline var b2_colorBox2DRed:B2HexColor
static inline var b2_colorBox2DBlue:B2HexColor
static inline var b2_colorBox2DGreen:B2HexColor
static inline var b2_colorBox2DYellow:B2HexColor
static inline var b2_distanceJoint:B2JointType
static inline var b2_filterJoint:B2JointType
static inline var b2_motorJoint:B2JointType
static inline var b2_moverJoint:B2JointType
static inline var b2_pogoJoint:B2JointType
static inline var b2_prismaticJoint:B2JointType
static inline var b2_revoluteJoint:B2JointType
static inline var b2_weldJoint:B2JointType
static inline var b2_wheelJoint:B2JointType
static inline var b2_circleShape:B2ShapeType
static inline var b2_capsuleShape:B2ShapeType
static inline var b2_segmentShape:B2ShapeType
static inline var b2_polygonShape:B2ShapeType
static inline var b2_chainSegmentShape:B2ShapeType
static inline var b2_shapeTypeCount:B2ShapeType
static inline var b2_toiStateUnknown:B2TOIState
static inline var b2_toiStateFailed:B2TOIState
static inline var b2_toiStateOverlapped:B2TOIState
static inline var b2_toiStateHit:B2TOIState
static inline var b2_toiStateSeparated:B2TOIState
static function b2GetByteCount():Int
static function b2SetLogCallback(logFcn:B2LogCallbackFcn):Void
static function b2GetVersion(?out:B2Version):B2Version
static function b2IsDoublePrecision():Bool
static function b2IsAVX2Available():Bool
static function b2GetTicks():haxe.Int64
static function b2GetMilliseconds(ticks:haxe.Int64):Float
static function b2GetMillisecondsAndReset(ticks:Array<haxe.Int64>):Float
static function b2Hash(hash:Int, data:haxe.io.Bytes, count:Int):Int
static function b2IsValidFloat(a:Float):Bool
static function b2IsValidVec2(v:B2Vec2):Bool
static function b2IsValidRot(q:B2Rot):Bool
static function b2IsValidTransform(t:B2Transform):Bool
static function b2IsValidAABB(aabb:B2AABB):Bool
static function b2IsValidPlane(a:B2Plane):Bool
static function b2IsValidPos(p:B2Pos):Bool
static function b2IsValidWorldTransform(t:B2WorldTransform):Bool
static function b2MinInt(a:Int, b:Int):Int
static function b2MaxInt(a:Int, b:Int):Int
static function b2AbsInt(a:Int):Int
static function b2ClampInt(a:Int, lower:Int, upper:Int):Int
static function b2CeilingInt(numerator:Int, denominator:Int):Int
static function b2MinFloat(a:Float, b:Float):Float
static function b2MaxFloat(a:Float, b:Float):Float
static function b2AbsFloat(a:Float):Float
static function b2ClampFloat(a:Float, lower:Float, upper:Float):Float
static function b2Atan2(y:Float, x:Float):Float
static function b2ComputeCosSin(radians:Float, ?out:B2CosSin):B2CosSin
static function b2Dot(a:B2Vec2, b:B2Vec2):Float
static function b2Cross(a:B2Vec2, b:B2Vec2):Float
static function b2CrossVS(v:B2Vec2, s:Float, ?out:B2Vec2):B2Vec2
static function b2CrossSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2LeftPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2RightPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Add(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Sub(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Neg(a:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Lerp(a:B2Vec2, b:B2Vec2, t:Float, ?out:B2Vec2):B2Vec2
static function b2Mul(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2MulSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2MulAdd(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2MulSub(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Abs(a:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Min(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Max(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Clamp(v:B2Vec2, a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Length(v:B2Vec2):Float
static function b2Distance(a:B2Vec2, b:B2Vec2):Float
static function b2Normalize(a:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2IsNormalized(a:B2Vec2):Bool
static function b2GetLengthAndNormalize(length:Array<Float>, a:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2NormalizeRot(q:B2Rot, ?out:B2Rot):B2Rot
static function b2IntegrateRotation(q1:B2Rot, deltaAngle:Float, ?out:B2Rot):B2Rot
static function b2LengthSquared(v:B2Vec2):Float
static function b2DistanceSquared(a:B2Vec2, b:B2Vec2):Float
static function b2MakeRot(radians:Float, ?out:B2Rot):B2Rot
static function b2MakeRotFromUnitVector(unitVector:B2Vec2, ?out:B2Rot):B2Rot
static function b2ComputeRotationBetweenUnitVectors(v1:B2Vec2, v2:B2Vec2, ?out:B2Rot):B2Rot
static function b2IsNormalizedRot(q:B2Rot):Bool
static function b2InvertRot(a:B2Rot, ?out:B2Rot):B2Rot
static function b2NLerp(q1:B2Rot, q2:B2Rot, t:Float, ?out:B2Rot):B2Rot
static function b2ComputeAngularVelocity(q1:B2Rot, q2:B2Rot, inv_h:Float):Float
static function b2Rot_GetAngle(q:B2Rot):Float
static function b2Rot_GetXAxis(q:B2Rot, ?out:B2Vec2):B2Vec2
static function b2Rot_GetYAxis(q:B2Rot, ?out:B2Vec2):B2Vec2
static function b2MulRot(q:B2Rot, r:B2Rot, ?out:B2Rot):B2Rot
static function b2InvMulRot(a:B2Rot, b:B2Rot, ?out:B2Rot):B2Rot
static function b2RelativeAngle(a:B2Rot, b:B2Rot):Float
static function b2UnwindAngle(radians:Float):Float
static function b2RotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2InvRotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2TransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2InvTransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2MulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform
static function b2InvMulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform
static function b2ToPos(v:B2Vec2, ?out:B2Pos):B2Pos
static function b2ToVec2(p:B2Pos, ?out:B2Vec2):B2Vec2
static function b2RoundDownFloat(x:Float):Float
static function b2RoundUpFloat(x:Float):Float
static function b2SubPos(a:B2Pos, b:B2Pos, ?out:B2Vec2):B2Vec2
static function b2OffsetPos(p:B2Pos, d:B2Vec2, ?out:B2Pos):B2Pos
static function b2LerpPos(a:B2Pos, b:B2Pos, t:Float, ?out:B2Pos):B2Pos
static function b2TransformWorldPoint(t:B2WorldTransform, p:B2Vec2, ?out:B2Pos):B2Pos
static function b2InvTransformWorldPoint(t:B2WorldTransform, p:B2Pos, ?out:B2Vec2):B2Vec2
static function b2InvMulWorldTransforms(A:B2WorldTransform, B:B2WorldTransform, ?out:B2Transform):B2Transform
static function b2MulWorldTransforms(A:B2WorldTransform, B:B2Transform, ?out:B2WorldTransform):B2WorldTransform
static function b2ToRelativeTransform(t:B2WorldTransform, base:B2Pos, ?out:B2Transform):B2Transform
static function b2MakeWorldTransform(t:B2Transform, ?out:B2WorldTransform):B2WorldTransform
static function b2MulMV(A:B2Mat22, v:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2GetInverse22(A:B2Mat22, ?out:B2Mat22):B2Mat22
static function b2Solve22(A:B2Mat22, b:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2AABB_Contains(a:B2AABB, b:B2AABB):Bool
static function b2AABB_Center(a:B2AABB, ?out:B2Vec2):B2Vec2
static function b2AABB_Extents(a:B2AABB, ?out:B2Vec2):B2Vec2
static function b2AABB_Union(a:B2AABB, b:B2AABB, ?out:B2AABB):B2AABB
static function b2AABB_Overlaps(a:B2AABB, b:B2AABB):Bool
static function b2MakeAABB(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2AABB):B2AABB
static function b2PlaneSeparation(plane:B2Plane, point:B2Vec2):Float
static function b2SpringDamper(hertz:Float, dampingRatio:Float, position:Float, velocity:Float, timeStep:Float):Float
static function b2SetLengthUnitsPerMeter(lengthUnits:Float):Void
static function b2GetLengthUnitsPerMeter():Float
static function b2IsValidRay(input:B2RayCastInput):Bool
static function b2MakePolygon(hull:B2Hull, radius:Float, ?out:B2Polygon):B2Polygon
static function b2MakeOffsetPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon
static function b2MakeOffsetRoundedPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon
static function b2MakeSquare(halfWidth:Float, ?out:B2Polygon):B2Polygon
static function b2MakeBox(halfWidth:Float, halfHeight:Float, ?out:B2Polygon):B2Polygon
static function b2MakeRoundedBox(halfWidth:Float, halfHeight:Float, radius:Float, ?out:B2Polygon):B2Polygon
static function b2MakeOffsetBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon
static function b2MakeOffsetRoundedBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon
static function b2TransformPolygon(transform:B2Transform, polygon:B2Polygon, ?out:B2Polygon):B2Polygon
static function b2ComputeCircleMass(shape:B2Circle, density:Float, ?out:B2MassData):B2MassData
static function b2ComputeCapsuleMass(shape:B2Capsule, density:Float, ?out:B2MassData):B2MassData
static function b2ComputePolygonMass(shape:B2Polygon, density:Float, ?out:B2MassData):B2MassData
static function b2ComputeCircleBounds(shape:B2Circle, transform:B2WorldTransform, ?out:B2AABB):B2AABB
static function b2ComputeCapsuleBounds(shape:B2Capsule, transform:B2WorldTransform, ?out:B2AABB):B2AABB
static function b2ComputePolygonBounds(shape:B2Polygon, transform:B2WorldTransform, ?out:B2AABB):B2AABB
static function b2ComputeSegmentBounds(shape:B2Segment, transform:B2WorldTransform, ?out:B2AABB):B2AABB
static function b2PointInCircle(shape:B2Circle, point:B2Vec2):Bool
static function b2PointInCapsule(shape:B2Capsule, point:B2Vec2):Bool
static function b2PointInPolygon(shape:B2Polygon, point:B2Vec2):Bool
static function b2CastRayCircle(shape:B2Circle, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastRayCapsule(shape:B2Capsule, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastRaySegment(shape:B2Segment, input:B2RayCastInput, oneSided:Bool, ?out:B2CastOutput):B2CastOutput
static function b2CastRayPolygon(shape:B2Polygon, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastShapeCircle(shape:B2Circle, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastShapeCapsule(shape:B2Capsule, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastShapeSegment(shape:B2Segment, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput
static function b2CastShapePolygon(shape:B2Polygon, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput
static function b2ComputeHull(points:Array<B2Vec2>, count:Int, ?out:B2Hull):B2Hull
static function b2ValidateHull(hull:B2Hull):Bool
static function b2ComputeSegmentDistance(p1:B2Vec2, q1:B2Vec2, p2:B2Vec2, q2:B2Vec2, ?out:B2SegmentDistanceResult):B2SegmentDistanceResult
static function b2ComputeShapeDistance(input:B2DistanceInput, cache:B2SimplexCache, ?simplexes:Array<B2Simplex>, ?simplexCapacity:Int = 0, ?out:B2DistanceOutput):B2DistanceOutput
static function b2CastShape(input:B2ShapeCastPairInput, ?out:B2CastOutput):B2CastOutput
static function b2MakeProxy(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2ShapeProxy):B2ShapeProxy
static function b2MakeOffsetProxy(points:Array<B2Vec2>, count:Int, radius:Float, position:B2Vec2, rotation:B2Rot, ?out:B2ShapeProxy):B2ShapeProxy
static function b2GetSweepTransform(sweep:B2Sweep, time:Float, ?out:B2Transform):B2Transform
static function b2ComputeTimeOfImpact(input:B2TOIInput, ?out:B2TOIOutput):B2TOIOutput
static function b2CollideCircles(circleA:B2Circle, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideCapsuleAndCircle(capsuleA:B2Capsule, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideSegmentAndCircle(segmentA:B2Segment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollidePolygonAndCircle(polygonA:B2Polygon, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideCapsules(capsuleA:B2Capsule, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideSegmentAndCapsule(segmentA:B2Segment, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollidePolygonAndCapsule(polygonA:B2Polygon, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollidePolygons(polygonA:B2Polygon, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideSegmentAndPolygon(segmentA:B2Segment, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideChainSegmentAndCircle(segmentA:B2ChainSegment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideChainSegmentAndCapsule(segmentA:B2ChainSegment, capsuleB:B2Capsule, xf:B2Transform, cache:B2SimplexCache, ?out:B2LocalManifold):B2LocalManifold
static function b2CollideChainSegmentAndPolygon(segmentA:B2ChainSegment, polygonB:B2Polygon, xf:B2Transform, cache:B2SimplexCache, ?out:B2LocalManifold):B2LocalManifold
static function b2DefaultWorldDef(?out:B2WorldDef):B2WorldDef
static function b2DefaultBodyDef(?out:B2BodyDef):B2BodyDef
static function b2DefaultFilter(?out:B2Filter):B2Filter
static function b2DefaultQueryFilter(?out:B2QueryFilter):B2QueryFilter
static function b2DefaultSurfaceMaterial(?out:B2SurfaceMaterial):B2SurfaceMaterial
static function b2DefaultShapeDef(?out:B2ShapeDef):B2ShapeDef
static function b2DefaultChainDef(?out:B2ChainDef):B2ChainDef
static function b2DefaultDistanceJointDef(?out:B2DistanceJointDef):B2DistanceJointDef
static function b2DefaultFilterJointDef(?out:B2FilterJointDef):B2FilterJointDef
static function b2DefaultMotorJointDef(?out:B2MotorJointDef):B2MotorJointDef
static function b2DefaultPrismaticJointDef(?out:B2PrismaticJointDef):B2PrismaticJointDef
static function b2DefaultRevoluteJointDef(?out:B2RevoluteJointDef):B2RevoluteJointDef
static function b2DefaultWeldJointDef(?out:B2WeldJointDef):B2WeldJointDef
static function b2DefaultWheelJointDef(?out:B2WheelJointDef):B2WheelJointDef
static function b2DefaultExplosionDef(?out:B2ExplosionDef):B2ExplosionDef
static function b2GetGraphColor(index:Int):B2HexColor
static function b2DefaultDebugDraw(?out:B2DebugDraw):B2DebugDraw
static function b2CreateWorld(def:B2WorldDef, ?out:B2WorldId):B2WorldId
static function b2DestroyWorld(worldId:B2WorldId):Void
static function b2World_IsValid(id:B2WorldId):Bool
static function b2World_Step(worldId:B2WorldId, timeStep:Float, subStepCount:Int):Void
static function b2World_Draw(worldId:B2WorldId, draw:B2DebugDraw):Void
static function b2World_GetBounds(worldId:B2WorldId, ?out:B2AABB):B2AABB
static function b2World_GetBodyEvents(worldId:B2WorldId, ?out:B2BodyEvents):B2BodyEvents
static function b2World_GetSensorEvents(worldId:B2WorldId, ?out:B2SensorEvents):B2SensorEvents
static function b2World_GetContactEvents(worldId:B2WorldId, ?out:B2ContactEvents):B2ContactEvents
static function b2World_GetJointEvents(worldId:B2WorldId, ?out:B2JointEvents):B2JointEvents
static function b2World_OverlapAABB(worldId:B2WorldId, origin:B2Pos, aabb:B2AABB, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats
static function b2World_OverlapShape(worldId:B2WorldId, origin:B2Pos, proxy:B2ShapeProxy, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats
static function b2World_CastRay(worldId:B2WorldId, origin:B2Pos, translation:B2Vec2, filter:B2QueryFilter, fcn:B2CastResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats
static function b2World_CastRayClosest(worldId:B2WorldId, origin:B2Pos, translation:B2Vec2, filter:B2QueryFilter, ?out:B2RayResult):B2RayResult
static function b2World_CastShape(worldId:B2WorldId, origin:B2Pos, proxy:B2ShapeProxy, translation:B2Vec2, filter:B2QueryFilter, fcn:B2CastResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats
static function b2World_EnableSleeping(worldId:B2WorldId, flag:Bool):Void
static function b2World_IsSleepingEnabled(worldId:B2WorldId):Bool
static function b2World_EnableContinuous(worldId:B2WorldId, flag:Bool):Void
static function b2World_IsContinuousEnabled(worldId:B2WorldId):Bool
static function b2World_SetRestitutionThreshold(worldId:B2WorldId, value:Float):Void
static function b2World_GetRestitutionThreshold(worldId:B2WorldId):Float
static function b2World_SetRestitutionIterations(worldId:B2WorldId, iterations:Int):Void
static function b2World_GetRestitutionIterations(worldId:B2WorldId):Int
static function b2World_EnableRestitutionPropagation(worldId:B2WorldId, flag:Bool):Void
static function b2World_IsRestitutionPropagationEnabled(worldId:B2WorldId):Bool
static function b2World_SetHitEventThreshold(worldId:B2WorldId, value:Float):Void
static function b2World_GetHitEventThreshold(worldId:B2WorldId):Float
static function b2World_SetCustomFilterCallback(worldId:B2WorldId, fcn:B2CustomFilterCallbackFcn, context:Dynamic):Void
static function b2World_SetPreSolveCallback(worldId:B2WorldId, preSolveFcn:B2PreSolveCallbackFcn, preContinuousFcn:B2PreContinuousCallbackFcn, context:Dynamic):Void
static function b2World_SetGravity(worldId:B2WorldId, gravity:B2Vec2):Void
static function b2World_GetGravity(worldId:B2WorldId, ?out:B2Vec2):B2Vec2
static function b2World_Explode(worldId:B2WorldId, explosionDef:B2ExplosionDef):Void
static function b2World_SetContactTuning(worldId:B2WorldId, hertz:Float, dampingRatio:Float, pushSpeed:Float):Void
static function b2World_GetContactTuning(worldId:B2WorldId, hertz:Array<Float>, dampingRatio:Array<Float>, pushSpeed:Array<Float>):Void
static function b2World_SetContactRecycleDistance(worldId:B2WorldId, recycleDistance:Float):Void
static function b2World_GetContactRecycleDistance(worldId:B2WorldId):Float
static function b2World_SetMaxLinearSpeed(worldId:B2WorldId, maximumLinearSpeed:Float):Void
static function b2World_GetMaxLinearSpeed(worldId:B2WorldId):Float
static function b2World_EnableWarmStarting(worldId:B2WorldId, flag:Bool):Void
static function b2World_IsWarmStartingEnabled(worldId:B2WorldId):Bool
static function b2World_EnableSSE2Fallback(worldId:B2WorldId, flag:Bool):Void
static function b2World_GetAwakeBodyCount(worldId:B2WorldId):Int
static function b2World_GetProfile(worldId:B2WorldId, ?out:B2Profile):B2Profile
static function b2World_GetCounters(worldId:B2WorldId, ?out:B2Counters):B2Counters
static function b2World_GetMaxCapacity(worldId:B2WorldId, ?out:B2Capacity):B2Capacity
static function b2World_SetUserData(worldId:B2WorldId, userData:Dynamic):Void
static function b2World_GetUserData(worldId:B2WorldId):Dynamic
static function b2World_SetFrictionCallback(worldId:B2WorldId, callback:B2FrictionCallbackFcn):Void
static function b2World_SetRestitutionCallback(worldId:B2WorldId, callback:B2RestitutionCallbackFcn):Void
static function b2World_SetWorkerCount(worldId:B2WorldId, count:Int):Void
static function b2World_GetWorkerCount(worldId:B2WorldId):Int
static function b2World_RebuildStaticTree(worldId:B2WorldId):Void
static function b2World_GetStateHash(worldId:B2WorldId):haxe.Int64
static function b2World_GetSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, capacity:Int):Int
static function b2World_RestoreFromSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, size:Int):Bool
static function b2CreateWorldFromSnapshot(image:haxe.io.Bytes, size:Int, workerCount:Int, ?out:B2WorldId):B2WorldId
static function b2CreateBody(worldId:B2WorldId, def:B2BodyDef, ?out:B2BodyId):B2BodyId
static function b2DestroyBody(bodyId:B2BodyId):Void
static function b2Body_IsValid(id:B2BodyId):Bool
static function b2Body_GetType(bodyId:B2BodyId):B2BodyType
static function b2Body_SetType(bodyId:B2BodyId, type:B2BodyType):Void
static function b2Body_SetName(bodyId:B2BodyId, name:String):Void
static function b2Body_GetName(bodyId:B2BodyId):String
static function b2Body_SetUserData(bodyId:B2BodyId, userData:Dynamic):Void
static function b2Body_GetUserData(bodyId:B2BodyId):Dynamic
static function b2Body_GetPosition(bodyId:B2BodyId, ?out:B2Pos):B2Pos
static function b2Body_GetRotation(bodyId:B2BodyId, ?out:B2Rot):B2Rot
static function b2Body_GetTransform(bodyId:B2BodyId, ?out:B2WorldTransform):B2WorldTransform
static function b2Body_SetTransform(bodyId:B2BodyId, position:B2Pos, rotation:B2Rot):Void
static function b2Body_GetLocalPoint(bodyId:B2BodyId, worldPoint:B2Pos, ?out:B2Vec2):B2Vec2
static function b2Body_GetWorldPoint(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Pos):B2Pos
static function b2Body_GetLocalVector(bodyId:B2BodyId, worldVector:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Body_GetWorldVector(bodyId:B2BodyId, localVector:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Body_GetLinearVelocity(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2
static function b2Body_GetAngularVelocity(bodyId:B2BodyId):Float
static function b2Body_SetLinearVelocity(bodyId:B2BodyId, linearVelocity:B2Vec2):Void
static function b2Body_SetAngularVelocity(bodyId:B2BodyId, angularVelocity:Float):Void
static function b2Body_SetTargetTransform(bodyId:B2BodyId, target:B2WorldTransform, timeStep:Float, wake:Bool):Void
static function b2Body_GetLocalPointVelocity(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Vec2):B2Vec2
static function b2Body_GetWorldPointVelocity(bodyId:B2BodyId, worldPoint:B2Pos, ?out:B2Vec2):B2Vec2
static function b2Body_ApplyForce(bodyId:B2BodyId, force:B2Vec2, point:B2Pos, wake:Bool):Void
static function b2Body_ApplyForceToCenter(bodyId:B2BodyId, force:B2Vec2, wake:Bool):Void
static function b2Body_ApplyTorque(bodyId:B2BodyId, torque:Float, wake:Bool):Void
static function b2Body_ClearForces(bodyId:B2BodyId):Void
static function b2Body_ApplyLinearImpulse(bodyId:B2BodyId, impulse:B2Vec2, point:B2Pos, wake:Bool):Void
static function b2Body_ApplyLinearImpulseToCenter(bodyId:B2BodyId, impulse:B2Vec2, wake:Bool):Void
static function b2Body_ApplyAngularImpulse(bodyId:B2BodyId, impulse:Float, wake:Bool):Void
static function b2Body_GetMass(bodyId:B2BodyId):Float
static function b2Body_GetRotationalInertia(bodyId:B2BodyId):Float
static function b2Body_GetLocalCenter(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2
static function b2Body_GetWorldCenter(bodyId:B2BodyId, ?out:B2Pos):B2Pos
static function b2Body_SetMassData(bodyId:B2BodyId, massData:B2MassData):Void
static function b2Body_GetMassData(bodyId:B2BodyId, ?out:B2MassData):B2MassData
static function b2Body_UpdateMassFromShapes(bodyId:B2BodyId):Void
static function b2Body_SetLinearDamping(bodyId:B2BodyId, linearDamping:Float):Void
static function b2Body_GetLinearDamping(bodyId:B2BodyId):Float
static function b2Body_SetAngularDamping(bodyId:B2BodyId, angularDamping:Float):Void
static function b2Body_GetAngularDamping(bodyId:B2BodyId):Float
static function b2Body_SetGravityScale(bodyId:B2BodyId, gravityScale:Float):Void
static function b2Body_GetGravityScale(bodyId:B2BodyId):Float
static function b2Body_IsAwake(bodyId:B2BodyId):Bool
static function b2Body_SetAwake(bodyId:B2BodyId, awake:Bool):Void
static function b2Body_WakeTouching(bodyId:B2BodyId):Void
static function b2Body_EnableSleeping(bodyId:B2BodyId, enableSleep:Bool):Void
static function b2Body_IsSleepingEnabled(bodyId:B2BodyId):Bool
static function b2Body_SetSleepThreshold(bodyId:B2BodyId, sleepThreshold:Float):Void
static function b2Body_GetSleepThreshold(bodyId:B2BodyId):Float
static function b2Body_SetSafetyFactor(bodyId:B2BodyId, safetyFactor:Float):Void
static function b2Body_GetSafetyFactor(bodyId:B2BodyId):Float
static function b2Body_IsEnabled(bodyId:B2BodyId):Bool
static function b2Body_Disable(bodyId:B2BodyId):Void
static function b2Body_Enable(bodyId:B2BodyId):Void
static function b2Body_SetMotionLocks(bodyId:B2BodyId, locks:B2MotionLocks):Void
static function b2Body_GetMotionLocks(bodyId:B2BodyId, ?out:B2MotionLocks):B2MotionLocks
static function b2Body_SetBullet(bodyId:B2BodyId, flag:Bool):Void
static function b2Body_IsBullet(bodyId:B2BodyId):Bool
static function b2Body_EnableContactRecycling(bodyId:B2BodyId, flag:Bool):Void
static function b2Body_IsContactRecyclingEnabled(bodyId:B2BodyId):Bool
static function b2Body_EnableContactEvents(bodyId:B2BodyId, flag:Bool):Void
static function b2Body_EnableHitEvents(bodyId:B2BodyId, flag:Bool):Void
static function b2Body_GetWorld(bodyId:B2BodyId, ?out:B2WorldId):B2WorldId
static function b2Body_GetShapeCount(bodyId:B2BodyId):Int
static function b2Body_GetShapes(bodyId:B2BodyId, shapeArray:Array<B2ShapeId>, capacity:Int):Int
static function b2Body_GetJointCount(bodyId:B2BodyId):Int
static function b2Body_GetJoints(bodyId:B2BodyId, jointArray:Array<B2JointId>, capacity:Int):Int
static function b2Body_GetContactCapacity(bodyId:B2BodyId):Int
static function b2Body_GetContactData(bodyId:B2BodyId, contactData:Array<B2ContactData>, capacity:Int):Int
static function b2Body_ComputeBounds(bodyId:B2BodyId, ?out:B2AABB):B2AABB
static function b2Body_GetMinExtent(bodyId:B2BodyId):Float
static function b2Body_GetMaxExtent(bodyId:B2BodyId):Float
static function b2Body_GetMaxExtentFromOrigin(bodyId:B2BodyId):Float
static function b2CreateCircleShape(bodyId:B2BodyId, def:B2ShapeDef, circle:B2Circle, ?out:B2ShapeId):B2ShapeId
static function b2CreateSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, segment:B2Segment, ?out:B2ShapeId):B2ShapeId
static function b2CreateChainSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, chainSegment:B2ChainSegment, ?out:B2ShapeId):B2ShapeId
static function b2CreateCapsuleShape(bodyId:B2BodyId, def:B2ShapeDef, capsule:B2Capsule, ?out:B2ShapeId):B2ShapeId
static function b2CreatePolygonShape(bodyId:B2BodyId, def:B2ShapeDef, polygon:B2Polygon, ?out:B2ShapeId):B2ShapeId
static function b2DestroyShape(shapeId:B2ShapeId, updateBodyMass:Bool):Void
static function b2Shape_IsValid(id:B2ShapeId):Bool
static function b2Shape_GetType(shapeId:B2ShapeId):B2ShapeType
static function b2Shape_GetBody(shapeId:B2ShapeId, ?out:B2BodyId):B2BodyId
static function b2Shape_GetWorld(shapeId:B2ShapeId, ?out:B2WorldId):B2WorldId
static function b2Shape_IsSensor(shapeId:B2ShapeId):Bool
static function b2Shape_SetUserData(shapeId:B2ShapeId, userData:Dynamic):Void
static function b2Shape_GetUserData(shapeId:B2ShapeId):Dynamic
static function b2Shape_SetDensity(shapeId:B2ShapeId, density:Float, updateBodyMass:Bool):Void
static function b2Shape_GetDensity(shapeId:B2ShapeId):Float
static function b2Shape_SetFriction(shapeId:B2ShapeId, friction:Float):Void
static function b2Shape_GetFriction(shapeId:B2ShapeId):Float
static function b2Shape_SetRestitution(shapeId:B2ShapeId, restitution:Float):Void
static function b2Shape_GetRestitution(shapeId:B2ShapeId):Float
static function b2Shape_SetUserMaterial(shapeId:B2ShapeId, material:haxe.Int64):Void
static function b2Shape_GetUserMaterial(shapeId:B2ShapeId):haxe.Int64
static function b2Shape_SetSurfaceMaterial(shapeId:B2ShapeId, surfaceMaterial:B2SurfaceMaterial):Void
static function b2Shape_GetSurfaceMaterial(shapeId:B2ShapeId, ?out:B2SurfaceMaterial):B2SurfaceMaterial
static function b2Shape_GetFilter(shapeId:B2ShapeId, ?out:B2Filter):B2Filter
static function b2Shape_SetFilter(shapeId:B2ShapeId, filter:B2Filter):Void
static function b2Shape_EnableSensorEvents(shapeId:B2ShapeId, flag:Bool):Void
static function b2Shape_AreSensorEventsEnabled(shapeId:B2ShapeId):Bool
static function b2Shape_EnableContactEvents(shapeId:B2ShapeId, flag:Bool):Void
static function b2Shape_AreContactEventsEnabled(shapeId:B2ShapeId):Bool
static function b2Shape_EnablePreSolveEvents(shapeId:B2ShapeId, flag:Bool):Void
static function b2Shape_ArePreSolveEventsEnabled(shapeId:B2ShapeId):Bool
static function b2Shape_EnableHitEvents(shapeId:B2ShapeId, flag:Bool):Void
static function b2Shape_AreHitEventsEnabled(shapeId:B2ShapeId):Bool
static function b2Shape_TestPoint(shapeId:B2ShapeId, point:B2Pos):Bool
static function b2Shape_CastRay(shapeId:B2ShapeId, origin:B2Pos, translation:B2Vec2, ?out:B2WorldCastOutput):B2WorldCastOutput
static function b2Shape_GetCircle(shapeId:B2ShapeId, ?out:B2Circle):B2Circle
static function b2Shape_GetSegment(shapeId:B2ShapeId, ?out:B2Segment):B2Segment
static function b2Shape_GetChainSegment(shapeId:B2ShapeId, ?out:B2ChainSegment):B2ChainSegment
static function b2Shape_GetCapsule(shapeId:B2ShapeId, ?out:B2Capsule):B2Capsule
static function b2Shape_GetPolygon(shapeId:B2ShapeId, ?out:B2Polygon):B2Polygon
static function b2Shape_SetCircle(shapeId:B2ShapeId, circle:B2Circle):Void
static function b2Shape_SetCapsule(shapeId:B2ShapeId, capsule:B2Capsule):Void
static function b2Shape_SetSegment(shapeId:B2ShapeId, segment:B2Segment):Void
static function b2Shape_SetPolygon(shapeId:B2ShapeId, polygon:B2Polygon):Void
static function b2Shape_SetChainSegment(shapeId:B2ShapeId, chainSegment:B2ChainSegment):Void
static function b2Shape_GetParentChain(shapeId:B2ShapeId, ?out:B2ChainId):B2ChainId
static function b2Shape_GetContactCapacity(shapeId:B2ShapeId):Int
static function b2Shape_GetContactData(shapeId:B2ShapeId, contactData:Array<B2ContactData>, capacity:Int):Int
static function b2Shape_GetSensorCapacity(shapeId:B2ShapeId):Int
static function b2Shape_GetSensorData(shapeId:B2ShapeId, visitorIds:Array<B2ShapeId>, capacity:Int):Int
static function b2Shape_GetBounds(shapeId:B2ShapeId, ?out:B2AABB):B2AABB
static function b2Shape_ComputeMassData(shapeId:B2ShapeId, ?out:B2MassData):B2MassData
static function b2Shape_GetClosestPoint(shapeId:B2ShapeId, target:B2Pos, ?out:B2Pos):B2Pos
static function b2Shape_ApplyWind(shapeId:B2ShapeId, wind:B2Vec2, drag:Float, lift:Float, wake:Bool):Void
static function b2CreateChain(bodyId:B2BodyId, def:B2ChainDef, ?out:B2ChainId):B2ChainId
static function b2DestroyChain(chainId:B2ChainId):Void
static function b2Chain_GetWorld(chainId:B2ChainId, ?out:B2WorldId):B2WorldId
static function b2Chain_GetSegmentCount(chainId:B2ChainId):Int
static function b2Chain_GetSegments(chainId:B2ChainId, segmentArray:Array<B2ShapeId>, capacity:Int):Int
static function b2Chain_SetAllSurfaceMaterials(chainId:B2ChainId, material:B2SurfaceMaterial):Void
static function b2Chain_SetSurfaceMaterial(chainId:B2ChainId, material:B2SurfaceMaterial, segmentIndex:Int):Void
static function b2Chain_GetSurfaceMaterial(chainId:B2ChainId, segmentIndex:Int, ?out:B2SurfaceMaterial):B2SurfaceMaterial
static function b2Chain_IsValid(id:B2ChainId):Bool
static function b2DestroyJoint(jointId:B2JointId):Void
static function b2Joint_IsValid(id:B2JointId):Bool
static function b2Joint_GetType(jointId:B2JointId):B2JointType
static function b2Joint_GetBodyA(jointId:B2JointId, ?out:B2BodyId):B2BodyId
static function b2Joint_GetBodyB(jointId:B2JointId, ?out:B2BodyId):B2BodyId
static function b2Joint_GetWorld(jointId:B2JointId, ?out:B2WorldId):B2WorldId
static function b2Joint_SetLocalFrameA(jointId:B2JointId, localFrame:B2Transform):Void
static function b2Joint_GetLocalFrameA(jointId:B2JointId, ?out:B2Transform):B2Transform
static function b2Joint_SetLocalFrameB(jointId:B2JointId, localFrame:B2Transform):Void
static function b2Joint_GetLocalFrameB(jointId:B2JointId, ?out:B2Transform):B2Transform
static function b2Joint_SetCollideConnected(jointId:B2JointId, shouldCollide:Bool):Void
static function b2Joint_GetCollideConnected(jointId:B2JointId):Bool
static function b2Joint_SetUserData(jointId:B2JointId, userData:Dynamic):Void
static function b2Joint_GetUserData(jointId:B2JointId):Dynamic
static function b2Joint_WakeBodies(jointId:B2JointId):Void
static function b2Joint_GetConstraintForce(jointId:B2JointId, ?out:B2Vec2):B2Vec2
static function b2Joint_GetConstraintTorque(jointId:B2JointId):Float
static function b2Joint_GetLinearSeparation(jointId:B2JointId):Float
static function b2Joint_GetAngularSeparation(jointId:B2JointId):Float
static function b2Joint_SetConstraintTuning(jointId:B2JointId, hertz:Float, dampingRatio:Float):Void
static function b2Joint_GetConstraintTuning(jointId:B2JointId, hertz:Array<Float>, dampingRatio:Array<Float>):Void
static function b2Joint_SetForceThreshold(jointId:B2JointId, threshold:Float):Void
static function b2Joint_GetForceThreshold(jointId:B2JointId):Float
static function b2Joint_SetTorqueThreshold(jointId:B2JointId, threshold:Float):Void
static function b2Joint_GetTorqueThreshold(jointId:B2JointId):Float
static function b2CreateDistanceJoint(worldId:B2WorldId, def:B2DistanceJointDef, ?out:B2JointId):B2JointId
static function b2DistanceJoint_SetRestLength(jointId:B2JointId, length:Float):Void
static function b2DistanceJoint_GetRestLength(jointId:B2JointId):Float
static function b2DistanceJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void
static function b2DistanceJoint_IsSpringEnabled(jointId:B2JointId):Bool
static function b2DistanceJoint_SetSpringForceRange(jointId:B2JointId, lowerForce:Float, upperForce:Float):Void
static function b2DistanceJoint_GetSpringForceRange(jointId:B2JointId, lowerForce:Array<Float>, upperForce:Array<Float>):Void
static function b2DistanceJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void
static function b2DistanceJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2DistanceJoint_GetSpringHertz(jointId:B2JointId):Float
static function b2DistanceJoint_GetSpringDampingRatio(jointId:B2JointId):Float
static function b2DistanceJoint_GetSpringForce(jointId:B2JointId):Float
static function b2DistanceJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void
static function b2DistanceJoint_IsLimitEnabled(jointId:B2JointId):Bool
static function b2DistanceJoint_SetLimits(jointId:B2JointId, minLength:Float, maxLength:Float):Void
static function b2DistanceJoint_GetLowerLimit(jointId:B2JointId):Float
static function b2DistanceJoint_GetUpperLimit(jointId:B2JointId):Float
static function b2DistanceJoint_GetCurrentLength(jointId:B2JointId):Float
static function b2DistanceJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void
static function b2DistanceJoint_IsMotorEnabled(jointId:B2JointId):Bool
static function b2DistanceJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void
static function b2DistanceJoint_GetTargetMotorSpeed(jointId:B2JointId):Float
static function b2DistanceJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void
static function b2DistanceJoint_GetMaxMotorForce(jointId:B2JointId):Float
static function b2DistanceJoint_GetCurrentMotorForce(jointId:B2JointId):Float
static function b2CreateFilterJoint(worldId:B2WorldId, def:B2FilterJointDef, ?out:B2JointId):B2JointId
static function b2CreateMotorJoint(worldId:B2WorldId, def:B2MotorJointDef, ?out:B2JointId):B2JointId
static function b2MotorJoint_SetLinearVelocity(jointId:B2JointId, velocity:B2Vec2):Void
static function b2MotorJoint_GetLinearVelocity(jointId:B2JointId, ?out:B2Vec2):B2Vec2
static function b2MotorJoint_SetAngularVelocity(jointId:B2JointId, velocity:Float):Void
static function b2MotorJoint_GetAngularVelocity(jointId:B2JointId):Float
static function b2MotorJoint_SetMaxVelocityForce(jointId:B2JointId, maxForce:Float):Void
static function b2MotorJoint_GetMaxVelocityForce(jointId:B2JointId):Float
static function b2MotorJoint_SetMaxVelocityTorque(jointId:B2JointId, maxTorque:Float):Void
static function b2MotorJoint_GetMaxVelocityTorque(jointId:B2JointId):Float
static function b2MotorJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void
static function b2MotorJoint_GetLinearHertz(jointId:B2JointId):Float
static function b2MotorJoint_SetLinearDampingRatio(jointId:B2JointId, damping:Float):Void
static function b2MotorJoint_GetLinearDampingRatio(jointId:B2JointId):Float
static function b2MotorJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void
static function b2MotorJoint_GetAngularHertz(jointId:B2JointId):Float
static function b2MotorJoint_SetAngularDampingRatio(jointId:B2JointId, damping:Float):Void
static function b2MotorJoint_GetAngularDampingRatio(jointId:B2JointId):Float
static function b2MotorJoint_SetMaxSpringForce(jointId:B2JointId, maxForce:Float):Void
static function b2MotorJoint_GetMaxSpringForce(jointId:B2JointId):Float
static function b2MotorJoint_SetMaxSpringTorque(jointId:B2JointId, maxTorque:Float):Void
static function b2MotorJoint_GetMaxSpringTorque(jointId:B2JointId):Float
static function b2CreatePrismaticJoint(worldId:B2WorldId, def:B2PrismaticJointDef, ?out:B2JointId):B2JointId
static function b2PrismaticJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void
static function b2PrismaticJoint_IsSpringEnabled(jointId:B2JointId):Bool
static function b2PrismaticJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void
static function b2PrismaticJoint_GetSpringHertz(jointId:B2JointId):Float
static function b2PrismaticJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2PrismaticJoint_GetSpringDampingRatio(jointId:B2JointId):Float
static function b2PrismaticJoint_SetTargetTranslation(jointId:B2JointId, translation:Float):Void
static function b2PrismaticJoint_GetTargetTranslation(jointId:B2JointId):Float
static function b2PrismaticJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void
static function b2PrismaticJoint_IsLimitEnabled(jointId:B2JointId):Bool
static function b2PrismaticJoint_GetLowerLimit(jointId:B2JointId):Float
static function b2PrismaticJoint_GetUpperLimit(jointId:B2JointId):Float
static function b2PrismaticJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void
static function b2PrismaticJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void
static function b2PrismaticJoint_IsMotorEnabled(jointId:B2JointId):Bool
static function b2PrismaticJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void
static function b2PrismaticJoint_GetTargetMotorSpeed(jointId:B2JointId):Float
static function b2PrismaticJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void
static function b2PrismaticJoint_GetMaxMotorForce(jointId:B2JointId):Float
static function b2PrismaticJoint_GetCurrentTranslation(jointId:B2JointId):Float
static function b2PrismaticJoint_GetCurrentSpeed(jointId:B2JointId):Float
static function b2PrismaticJoint_GetCurrentMotorForce(jointId:B2JointId):Float
static function b2CreateRevoluteJoint(worldId:B2WorldId, def:B2RevoluteJointDef, ?out:B2JointId):B2JointId
static function b2RevoluteJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void
static function b2RevoluteJoint_IsSpringEnabled(jointId:B2JointId):Bool
static function b2RevoluteJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void
static function b2RevoluteJoint_GetSpringHertz(jointId:B2JointId):Float
static function b2RevoluteJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2RevoluteJoint_GetSpringDampingRatio(jointId:B2JointId):Float
static function b2RevoluteJoint_SetTargetAngle(jointId:B2JointId, angle:Float):Void
static function b2RevoluteJoint_GetTargetAngle(jointId:B2JointId):Float
static function b2RevoluteJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void
static function b2RevoluteJoint_IsLimitEnabled(jointId:B2JointId):Bool
static function b2RevoluteJoint_GetLowerLimit(jointId:B2JointId):Float
static function b2RevoluteJoint_GetUpperLimit(jointId:B2JointId):Float
static function b2RevoluteJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void
static function b2RevoluteJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void
static function b2RevoluteJoint_IsMotorEnabled(jointId:B2JointId):Bool
static function b2RevoluteJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void
static function b2RevoluteJoint_GetTargetMotorSpeed(jointId:B2JointId):Float
static function b2RevoluteJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void
static function b2RevoluteJoint_GetMaxMotorTorque(jointId:B2JointId):Float
static function b2RevoluteJoint_GetCurrentAngle(jointId:B2JointId):Float
static function b2RevoluteJoint_GetCurrentSpeed(jointId:B2JointId):Float
static function b2RevoluteJoint_GetCurrentMotorTorque(jointId:B2JointId):Float
static function b2CreateWeldJoint(worldId:B2WorldId, def:B2WeldJointDef, ?out:B2JointId):B2JointId
static function b2WeldJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void
static function b2WeldJoint_GetLinearHertz(jointId:B2JointId):Float
static function b2WeldJoint_SetLinearDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2WeldJoint_GetLinearDampingRatio(jointId:B2JointId):Float
static function b2WeldJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void
static function b2WeldJoint_GetAngularHertz(jointId:B2JointId):Float
static function b2WeldJoint_SetAngularDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2WeldJoint_GetAngularDampingRatio(jointId:B2JointId):Float
static function b2CreateWheelJoint(worldId:B2WorldId, def:B2WheelJointDef, ?out:B2JointId):B2JointId
static function b2WheelJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void
static function b2WheelJoint_IsSpringEnabled(jointId:B2JointId):Bool
static function b2WheelJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void
static function b2WheelJoint_GetSpringHertz(jointId:B2JointId):Float
static function b2WheelJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void
static function b2WheelJoint_GetSpringDampingRatio(jointId:B2JointId):Float
static function b2WheelJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void
static function b2WheelJoint_IsLimitEnabled(jointId:B2JointId):Bool
static function b2WheelJoint_GetLowerLimit(jointId:B2JointId):Float
static function b2WheelJoint_GetUpperLimit(jointId:B2JointId):Float
static function b2WheelJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void
static function b2WheelJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void
static function b2WheelJoint_IsMotorEnabled(jointId:B2JointId):Bool
static function b2WheelJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void
static function b2WheelJoint_GetTargetMotorSpeed(jointId:B2JointId):Float
static function b2WheelJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void
static function b2WheelJoint_GetMaxMotorTorque(jointId:B2JointId):Float
static function b2WheelJoint_GetCurrentMotorTorque(jointId:B2JointId):Float
static function b2Contact_IsValid(id:B2ContactId):Bool
static function b2Contact_GetData(contactId:B2ContactId, ?out:B2ContactData):B2ContactData
static macro function copyWasm(directory:String):Void
```

- `loadAsync`: Asynchronously loads the module.
  - `loaded`: Called once the module is ready.
  - `failed`: Optional. Receives why the module couldn't be loaded; when omitted, it is thrown.
  - `wasmUrl`: Optional. In a page, the module's URL; defaults to `box2d.wasm`. Ignored natively.

  Calling it again after the module has loaded calls `loaded` again.

  _Note that in a page the module is `box2d.wasm` beside the page unless `wasmUrl` names another. The build copies it there with a line in the build's hxml:_

  ```hxml
  --macro helix.box2d.Box2D.copyWasm("web")
  ```
- `B2_AABB_MARGIN_FRACTION`: For small objects the margin is limited to this fraction times the maximum extent.
- `B2_CONTACT_RECYCLE_COS_ANGLE`: The default contact recycling world angle threshold: 0.98, about 11.5 degrees.
- `B2_CONTACT_RECYCLE_DISTANCE`: The default contact recycling distance: 10 times `B2_LINEAR_SLOP`.
- `B2_DEFAULT_CATEGORY_BITS`: The default category bits of a shape's filter: 1.
- `B2_DEFAULT_MASK_BITS`: The default mask bits of a shape's filter: every bit set.
- `B2_GRAPH_COLOR_COUNT`: The number of graph colors the solver uses.
- `B2_HASH_INIT`: The value `b2Hash` starts from.
- `B2_HUGE`: Used to detect bad values: 100 kilometers in length units.
- `B2_LINEAR_SLOP`: A small length used as a collision and constraint tolerance: 0.005 meters in length units.
- `B2_MAX_AABB_MARGIN`: The maximum margin of a shape's bounding box: 0.05 meters in length units.
- `B2_MAX_POLYGON_VERTICES`: The maximum number of vertices on a convex polygon.
- `B2_MAX_RESTITUTION_ITERATIONS`: The maximum number of restitution iterations.
- `B2_MAX_ROTATION`: The maximum rotation of a body in one step, in radians: a quarter of `B2_PI`.
- `B2_MAX_TASKS`: The maximum number of tasks in a step.
- `B2_MAX_WORKERS`: The maximum number of workers.
- `B2_MAX_WORLDS`: The maximum number of worlds at once.
- `B2_NAME_LENGTH`: The longest body name kept, in characters.
- `B2_NULL_INDEX`: The index that stands for none.
- `B2_PI`: Pi, as Box2D uses it.
- `B2_SPECULATIVE_DISTANCE`: The distance at which contacts are made ahead of touching: 4 times `B2_LINEAR_SLOP`.
- `B2_TIME_TO_SLEEP`: The time a body must be still before it sleeps, in seconds.
- `B2_VERSION_MAJOR`: Box2D's major version.
- `B2_VERSION_MINOR`: Box2D's minor version.
- `B2_VERSION_REVISION`: Box2D's revision.
- `B2_IS_NULL`: Whether an id is null.
  - `id`: A world, body, shape, joint, chain or contact id.
  - returns: Whether it is null.
- `B2_IS_NON_NULL`: Whether an id isn't null.
  - `id`: A world, body, shape, joint, chain or contact id.
  - returns: Whether it isn't null.
- `B2_ID_EQUALS`: Whether two ids of one kind are the same.
  - `id1`: An id.
  - `id2`: Another id of the same kind.
  - returns: Whether they are the same.
- `b2Mat22_zero`: A 2x2 matrix of zeros, new each time it is read.
- `b2Pos_zero`: The position (0, 0), new each time it is read.
- `b2Rot_identity`: The rotation that turns nothing, new each time it is read.
- `b2Transform_identity`: The transform that moves and turns nothing, new each time it is read.
- `b2Vec2_zero`: The vector (0, 0), new each time it is read.
- `b2WorldTransform_identity`: The world transform that moves and turns nothing, new each time it is read.
- `b2_emptySimplexCache`: An empty simplex cache, for a first call of `b2ComputeShapeDistance`, new each time it is read.
- `b2_lengthUnitsPerMeter`: The length units per meter, which `b2SetLengthUnitsPerMeter` sets.
- `b2_nullWorldId`: The null world id, new each time it is read.
- `b2_nullBodyId`: The null body id, new each time it is read.
- `b2_nullShapeId`: The null shape id, new each time it is read.
- `b2_nullChainId`: The null chain id, new each time it is read.
- `b2_nullJointId`: The null joint id, new each time it is read.
- `b2_nullContactId`: The null contact id, new each time it is read.
- `b2_staticBody`: The `B2BodyType` value b2_staticBody: Zero mass, zero velocity, may be manually moved.
- `b2_kinematicBody`: The `B2BodyType` value b2_kinematicBody: Zero mass, velocity set by user, moved by solver.
- `b2_dynamicBody`: The `B2BodyType` value b2_dynamicBody: Positive mass, velocity determined by forces, moved by solver.
- `b2_bodyTypeCount`: The `B2BodyType` value b2_bodyTypeCount: Number of body types.
- `b2_colorAliceBlue`: The `B2HexColor` value b2_colorAliceBlue: The SVG color alice blue, 0xF0F8FF.
- `b2_colorAntiqueWhite`: The `B2HexColor` value b2_colorAntiqueWhite: The SVG color antique white, 0xFAEBD7.
- `b2_colorAqua`: The `B2HexColor` value b2_colorAqua: The SVG color aqua, 0x00FFFF.
- `b2_colorAquamarine`: The `B2HexColor` value b2_colorAquamarine: The SVG color aquamarine, 0x7FFFD4.
- `b2_colorAzure`: The `B2HexColor` value b2_colorAzure: The SVG color azure, 0xF0FFFF.
- `b2_colorBeige`: The `B2HexColor` value b2_colorBeige: The SVG color beige, 0xF5F5DC.
- `b2_colorBisque`: The `B2HexColor` value b2_colorBisque: The SVG color bisque, 0xFFE4C4.
- `b2_colorBlack`: The `B2HexColor` value b2_colorBlack: The SVG color black, 0x000000.
- `b2_colorBlanchedAlmond`: The `B2HexColor` value b2_colorBlanchedAlmond: The SVG color blanched almond, 0xFFEBCD.
- `b2_colorBlue`: The `B2HexColor` value b2_colorBlue: The SVG color blue, 0x0000FF.
- `b2_colorBlueViolet`: The `B2HexColor` value b2_colorBlueViolet: The SVG color blue violet, 0x8A2BE2.
- `b2_colorBrown`: The `B2HexColor` value b2_colorBrown: The SVG color brown, 0xA52A2A.
- `b2_colorBurlywood`: The `B2HexColor` value b2_colorBurlywood: The SVG color burlywood, 0xDEB887.
- `b2_colorCadetBlue`: The `B2HexColor` value b2_colorCadetBlue: The SVG color cadet blue, 0x5F9EA0.
- `b2_colorChartreuse`: The `B2HexColor` value b2_colorChartreuse: The SVG color chartreuse, 0x7FFF00.
- `b2_colorChocolate`: The `B2HexColor` value b2_colorChocolate: The SVG color chocolate, 0xD2691E.
- `b2_colorCoral`: The `B2HexColor` value b2_colorCoral: The SVG color coral, 0xFF7F50.
- `b2_colorCornflowerBlue`: The `B2HexColor` value b2_colorCornflowerBlue: The SVG color cornflower blue, 0x6495ED.
- `b2_colorCornsilk`: The `B2HexColor` value b2_colorCornsilk: The SVG color cornsilk, 0xFFF8DC.
- `b2_colorCrimson`: The `B2HexColor` value b2_colorCrimson: The SVG color crimson, 0xDC143C.
- `b2_colorCyan`: The `B2HexColor` value b2_colorCyan: The SVG color cyan, 0x00FFFF.
- `b2_colorDarkBlue`: The `B2HexColor` value b2_colorDarkBlue: The SVG color dark blue, 0x00008B.
- `b2_colorDarkCyan`: The `B2HexColor` value b2_colorDarkCyan: The SVG color dark cyan, 0x008B8B.
- `b2_colorDarkGoldenRod`: The `B2HexColor` value b2_colorDarkGoldenRod: The SVG color dark golden rod, 0xB8860B.
- `b2_colorDarkGray`: The `B2HexColor` value b2_colorDarkGray: The SVG color dark gray, 0xA9A9A9.
- `b2_colorDarkGreen`: The `B2HexColor` value b2_colorDarkGreen: The SVG color dark green, 0x006400.
- `b2_colorDarkKhaki`: The `B2HexColor` value b2_colorDarkKhaki: The SVG color dark khaki, 0xBDB76B.
- `b2_colorDarkMagenta`: The `B2HexColor` value b2_colorDarkMagenta: The SVG color dark magenta, 0x8B008B.
- `b2_colorDarkOliveGreen`: The `B2HexColor` value b2_colorDarkOliveGreen: The SVG color dark olive green, 0x556B2F.
- `b2_colorDarkOrange`: The `B2HexColor` value b2_colorDarkOrange: The SVG color dark orange, 0xFF8C00.
- `b2_colorDarkOrchid`: The `B2HexColor` value b2_colorDarkOrchid: The SVG color dark orchid, 0x9932CC.
- `b2_colorDarkRed`: The `B2HexColor` value b2_colorDarkRed: The SVG color dark red, 0x8B0000.
- `b2_colorDarkSalmon`: The `B2HexColor` value b2_colorDarkSalmon: The SVG color dark salmon, 0xE9967A.
- `b2_colorDarkSeaGreen`: The `B2HexColor` value b2_colorDarkSeaGreen: The SVG color dark sea green, 0x8FBC8F.
- `b2_colorDarkSlateBlue`: The `B2HexColor` value b2_colorDarkSlateBlue: The SVG color dark slate blue, 0x483D8B.
- `b2_colorDarkSlateGray`: The `B2HexColor` value b2_colorDarkSlateGray: The SVG color dark slate gray, 0x2F4F4F.
- `b2_colorDarkTurquoise`: The `B2HexColor` value b2_colorDarkTurquoise: The SVG color dark turquoise, 0x00CED1.
- `b2_colorDarkViolet`: The `B2HexColor` value b2_colorDarkViolet: The SVG color dark violet, 0x9400D3.
- `b2_colorDeepPink`: The `B2HexColor` value b2_colorDeepPink: The SVG color deep pink, 0xFF1493.
- `b2_colorDeepSkyBlue`: The `B2HexColor` value b2_colorDeepSkyBlue: The SVG color deep sky blue, 0x00BFFF.
- `b2_colorDimGray`: The `B2HexColor` value b2_colorDimGray: The SVG color dim gray, 0x696969.
- `b2_colorDodgerBlue`: The `B2HexColor` value b2_colorDodgerBlue: The SVG color dodger blue, 0x1E90FF.
- `b2_colorFireBrick`: The `B2HexColor` value b2_colorFireBrick: The SVG color fire brick, 0xB22222.
- `b2_colorFloralWhite`: The `B2HexColor` value b2_colorFloralWhite: The SVG color floral white, 0xFFFAF0.
- `b2_colorForestGreen`: The `B2HexColor` value b2_colorForestGreen: The SVG color forest green, 0x228B22.
- `b2_colorFuchsia`: The `B2HexColor` value b2_colorFuchsia: The SVG color fuchsia, 0xFF00FF.
- `b2_colorGainsboro`: The `B2HexColor` value b2_colorGainsboro: The SVG color gainsboro, 0xDCDCDC.
- `b2_colorGhostWhite`: The `B2HexColor` value b2_colorGhostWhite: The SVG color ghost white, 0xF8F8FF.
- `b2_colorGold`: The `B2HexColor` value b2_colorGold: The SVG color gold, 0xFFD700.
- `b2_colorGoldenRod`: The `B2HexColor` value b2_colorGoldenRod: The SVG color golden rod, 0xDAA520.
- `b2_colorGray`: The `B2HexColor` value b2_colorGray: The SVG color gray, 0x808080.
- `b2_colorGreen`: The `B2HexColor` value b2_colorGreen: The SVG color green, 0x008000.
- `b2_colorGreenYellow`: The `B2HexColor` value b2_colorGreenYellow: The SVG color green yellow, 0xADFF2F.
- `b2_colorHoneyDew`: The `B2HexColor` value b2_colorHoneyDew: The SVG color honey dew, 0xF0FFF0.
- `b2_colorHotPink`: The `B2HexColor` value b2_colorHotPink: The SVG color hot pink, 0xFF69B4.
- `b2_colorIndianRed`: The `B2HexColor` value b2_colorIndianRed: The SVG color indian red, 0xCD5C5C.
- `b2_colorIndigo`: The `B2HexColor` value b2_colorIndigo: The SVG color indigo, 0x4B0082.
- `b2_colorIvory`: The `B2HexColor` value b2_colorIvory: The SVG color ivory, 0xFFFFF0.
- `b2_colorKhaki`: The `B2HexColor` value b2_colorKhaki: The SVG color khaki, 0xF0E68C.
- `b2_colorLavender`: The `B2HexColor` value b2_colorLavender: The SVG color lavender, 0xE6E6FA.
- `b2_colorLavenderBlush`: The `B2HexColor` value b2_colorLavenderBlush: The SVG color lavender blush, 0xFFF0F5.
- `b2_colorLawnGreen`: The `B2HexColor` value b2_colorLawnGreen: The SVG color lawn green, 0x7CFC00.
- `b2_colorLemonChiffon`: The `B2HexColor` value b2_colorLemonChiffon: The SVG color lemon chiffon, 0xFFFACD.
- `b2_colorLightBlue`: The `B2HexColor` value b2_colorLightBlue: The SVG color light blue, 0xADD8E6.
- `b2_colorLightCoral`: The `B2HexColor` value b2_colorLightCoral: The SVG color light coral, 0xF08080.
- `b2_colorLightCyan`: The `B2HexColor` value b2_colorLightCyan: The SVG color light cyan, 0xE0FFFF.
- `b2_colorLightGoldenRodYellow`: The `B2HexColor` value b2_colorLightGoldenRodYellow: The SVG color light golden rod yellow, 0xFAFAD2.
- `b2_colorLightGray`: The `B2HexColor` value b2_colorLightGray: The SVG color light gray, 0xD3D3D3.
- `b2_colorLightGreen`: The `B2HexColor` value b2_colorLightGreen: The SVG color light green, 0x90EE90.
- `b2_colorLightPink`: The `B2HexColor` value b2_colorLightPink: The SVG color light pink, 0xFFB6C1.
- `b2_colorLightSalmon`: The `B2HexColor` value b2_colorLightSalmon: The SVG color light salmon, 0xFFA07A.
- `b2_colorLightSeaGreen`: The `B2HexColor` value b2_colorLightSeaGreen: The SVG color light sea green, 0x20B2AA.
- `b2_colorLightSkyBlue`: The `B2HexColor` value b2_colorLightSkyBlue: The SVG color light sky blue, 0x87CEFA.
- `b2_colorLightSlateGray`: The `B2HexColor` value b2_colorLightSlateGray: The SVG color light slate gray, 0x778899.
- `b2_colorLightSteelBlue`: The `B2HexColor` value b2_colorLightSteelBlue: The SVG color light steel blue, 0xB0C4DE.
- `b2_colorLightYellow`: The `B2HexColor` value b2_colorLightYellow: The SVG color light yellow, 0xFFFFE0.
- `b2_colorLime`: The `B2HexColor` value b2_colorLime: The SVG color lime, 0x00FF00.
- `b2_colorLimeGreen`: The `B2HexColor` value b2_colorLimeGreen: The SVG color lime green, 0x32CD32.
- `b2_colorLinen`: The `B2HexColor` value b2_colorLinen: The SVG color linen, 0xFAF0E6.
- `b2_colorMagenta`: The `B2HexColor` value b2_colorMagenta: The SVG color magenta, 0xFF00FF.
- `b2_colorMaroon`: The `B2HexColor` value b2_colorMaroon: The SVG color maroon, 0x800000.
- `b2_colorMediumAquaMarine`: The `B2HexColor` value b2_colorMediumAquaMarine: The SVG color medium aqua marine, 0x66CDAA.
- `b2_colorMediumBlue`: The `B2HexColor` value b2_colorMediumBlue: The SVG color medium blue, 0x0000CD.
- `b2_colorMediumOrchid`: The `B2HexColor` value b2_colorMediumOrchid: The SVG color medium orchid, 0xBA55D3.
- `b2_colorMediumPurple`: The `B2HexColor` value b2_colorMediumPurple: The SVG color medium purple, 0x9370DB.
- `b2_colorMediumSeaGreen`: The `B2HexColor` value b2_colorMediumSeaGreen: The SVG color medium sea green, 0x3CB371.
- `b2_colorMediumSlateBlue`: The `B2HexColor` value b2_colorMediumSlateBlue: The SVG color medium slate blue, 0x7B68EE.
- `b2_colorMediumSpringGreen`: The `B2HexColor` value b2_colorMediumSpringGreen: The SVG color medium spring green, 0x00FA9A.
- `b2_colorMediumTurquoise`: The `B2HexColor` value b2_colorMediumTurquoise: The SVG color medium turquoise, 0x48D1CC.
- `b2_colorMediumVioletRed`: The `B2HexColor` value b2_colorMediumVioletRed: The SVG color medium violet red, 0xC71585.
- `b2_colorMidnightBlue`: The `B2HexColor` value b2_colorMidnightBlue: The SVG color midnight blue, 0x191970.
- `b2_colorMintCream`: The `B2HexColor` value b2_colorMintCream: The SVG color mint cream, 0xF5FFFA.
- `b2_colorMistyRose`: The `B2HexColor` value b2_colorMistyRose: The SVG color misty rose, 0xFFE4E1.
- `b2_colorMoccasin`: The `B2HexColor` value b2_colorMoccasin: The SVG color moccasin, 0xFFE4B5.
- `b2_colorNavajoWhite`: The `B2HexColor` value b2_colorNavajoWhite: The SVG color navajo white, 0xFFDEAD.
- `b2_colorNavy`: The `B2HexColor` value b2_colorNavy: The SVG color navy, 0x000080.
- `b2_colorOldLace`: The `B2HexColor` value b2_colorOldLace: The SVG color old lace, 0xFDF5E6.
- `b2_colorOlive`: The `B2HexColor` value b2_colorOlive: The SVG color olive, 0x808000.
- `b2_colorOliveDrab`: The `B2HexColor` value b2_colorOliveDrab: The SVG color olive drab, 0x6B8E23.
- `b2_colorOrange`: The `B2HexColor` value b2_colorOrange: The SVG color orange, 0xFFA500.
- `b2_colorOrangeRed`: The `B2HexColor` value b2_colorOrangeRed: The SVG color orange red, 0xFF4500.
- `b2_colorOrchid`: The `B2HexColor` value b2_colorOrchid: The SVG color orchid, 0xDA70D6.
- `b2_colorPaleGoldenRod`: The `B2HexColor` value b2_colorPaleGoldenRod: The SVG color pale golden rod, 0xEEE8AA.
- `b2_colorPaleGreen`: The `B2HexColor` value b2_colorPaleGreen: The SVG color pale green, 0x98FB98.
- `b2_colorPaleTurquoise`: The `B2HexColor` value b2_colorPaleTurquoise: The SVG color pale turquoise, 0xAFEEEE.
- `b2_colorPaleVioletRed`: The `B2HexColor` value b2_colorPaleVioletRed: The SVG color pale violet red, 0xDB7093.
- `b2_colorPapayaWhip`: The `B2HexColor` value b2_colorPapayaWhip: The SVG color papaya whip, 0xFFEFD5.
- `b2_colorPeachPuff`: The `B2HexColor` value b2_colorPeachPuff: The SVG color peach puff, 0xFFDAB9.
- `b2_colorPeru`: The `B2HexColor` value b2_colorPeru: The SVG color peru, 0xCD853F.
- `b2_colorPink`: The `B2HexColor` value b2_colorPink: The SVG color pink, 0xFFC0CB.
- `b2_colorPlum`: The `B2HexColor` value b2_colorPlum: The SVG color plum, 0xDDA0DD.
- `b2_colorPowderBlue`: The `B2HexColor` value b2_colorPowderBlue: The SVG color powder blue, 0xB0E0E6.
- `b2_colorPurple`: The `B2HexColor` value b2_colorPurple: The SVG color purple, 0x800080.
- `b2_colorRebeccaPurple`: The `B2HexColor` value b2_colorRebeccaPurple: The SVG color rebecca purple, 0x663399.
- `b2_colorRed`: The `B2HexColor` value b2_colorRed: The SVG color red, 0xFF0000.
- `b2_colorRosyBrown`: The `B2HexColor` value b2_colorRosyBrown: The SVG color rosy brown, 0xBC8F8F.
- `b2_colorRoyalBlue`: The `B2HexColor` value b2_colorRoyalBlue: The SVG color royal blue, 0x4169E1.
- `b2_colorSaddleBrown`: The `B2HexColor` value b2_colorSaddleBrown: The SVG color saddle brown, 0x8B4513.
- `b2_colorSalmon`: The `B2HexColor` value b2_colorSalmon: The SVG color salmon, 0xFA8072.
- `b2_colorSandyBrown`: The `B2HexColor` value b2_colorSandyBrown: The SVG color sandy brown, 0xF4A460.
- `b2_colorSeaGreen`: The `B2HexColor` value b2_colorSeaGreen: The SVG color sea green, 0x2E8B57.
- `b2_colorSeaShell`: The `B2HexColor` value b2_colorSeaShell: The SVG color sea shell, 0xFFF5EE.
- `b2_colorSienna`: The `B2HexColor` value b2_colorSienna: The SVG color sienna, 0xA0522D.
- `b2_colorSilver`: The `B2HexColor` value b2_colorSilver: The SVG color silver, 0xC0C0C0.
- `b2_colorSkyBlue`: The `B2HexColor` value b2_colorSkyBlue: The SVG color sky blue, 0x87CEEB.
- `b2_colorSlateBlue`: The `B2HexColor` value b2_colorSlateBlue: The SVG color slate blue, 0x6A5ACD.
- `b2_colorSlateGray`: The `B2HexColor` value b2_colorSlateGray: The SVG color slate gray, 0x708090.
- `b2_colorSnow`: The `B2HexColor` value b2_colorSnow: The SVG color snow, 0xFFFAFA.
- `b2_colorSpringGreen`: The `B2HexColor` value b2_colorSpringGreen: The SVG color spring green, 0x00FF7F.
- `b2_colorSteelBlue`: The `B2HexColor` value b2_colorSteelBlue: The SVG color steel blue, 0x4682B4.
- `b2_colorTan`: The `B2HexColor` value b2_colorTan: The SVG color tan, 0xD2B48C.
- `b2_colorTeal`: The `B2HexColor` value b2_colorTeal: The SVG color teal, 0x008080.
- `b2_colorThistle`: The `B2HexColor` value b2_colorThistle: The SVG color thistle, 0xD8BFD8.
- `b2_colorTomato`: The `B2HexColor` value b2_colorTomato: The SVG color tomato, 0xFF6347.
- `b2_colorTurquoise`: The `B2HexColor` value b2_colorTurquoise: The SVG color turquoise, 0x40E0D0.
- `b2_colorViolet`: The `B2HexColor` value b2_colorViolet: The SVG color violet, 0xEE82EE.
- `b2_colorWheat`: The `B2HexColor` value b2_colorWheat: The SVG color wheat, 0xF5DEB3.
- `b2_colorWhite`: The `B2HexColor` value b2_colorWhite: The SVG color white, 0xFFFFFF.
- `b2_colorWhiteSmoke`: The `B2HexColor` value b2_colorWhiteSmoke: The SVG color white smoke, 0xF5F5F5.
- `b2_colorYellow`: The `B2HexColor` value b2_colorYellow: The SVG color yellow, 0xFFFF00.
- `b2_colorYellowGreen`: The `B2HexColor` value b2_colorYellowGreen: The SVG color yellow green, 0x9ACD32.
- `b2_colorBox2DRed`: The `B2HexColor` value b2_colorBox2DRed: The Box2D logo color red, 0xDC3132.
- `b2_colorBox2DBlue`: The `B2HexColor` value b2_colorBox2DBlue: The Box2D logo color blue, 0x30AEBF.
- `b2_colorBox2DGreen`: The `B2HexColor` value b2_colorBox2DGreen: The Box2D logo color green, 0x8CC924.
- `b2_colorBox2DYellow`: The `B2HexColor` value b2_colorBox2DYellow: The Box2D logo color yellow, 0xFFEE8C.
- `b2_distanceJoint`: The `B2JointType` value b2_distanceJoint: Constrain the distance between two points.
- `b2_filterJoint`: The `B2JointType` value b2_filterJoint: Filter collision between two bodies.
- `b2_motorJoint`: The `B2JointType` value b2_motorJoint: Fully control the movement of a body.
- `b2_moverJoint`: The `B2JointType` value b2_moverJoint: Control the movement of the dynamic character mover.
- `b2_pogoJoint`: The `B2JointType` value b2_pogoJoint: Ground interaction for the dynamic character mover.
- `b2_prismaticJoint`: The `B2JointType` value b2_prismaticJoint: Slide along an axis.
- `b2_revoluteJoint`: The `B2JointType` value b2_revoluteJoint: Rotate around a pivot.
- `b2_weldJoint`: The `B2JointType` value b2_weldJoint: Bring two bodies together with some flex.
- `b2_wheelJoint`: The `B2JointType` value b2_wheelJoint: Wheel spins with shock absorber.
- `b2_circleShape`: The `B2ShapeType` value b2_circleShape: A circle with an offset.
- `b2_capsuleShape`: The `B2ShapeType` value b2_capsuleShape: A capsule is an extruded circle.
- `b2_segmentShape`: The `B2ShapeType` value b2_segmentShape: A line segment.
- `b2_polygonShape`: The `B2ShapeType` value b2_polygonShape: A convex polygon.
- `b2_chainSegmentShape`: The `B2ShapeType` value b2_chainSegmentShape: A line segment owned by a chain shape.
- `b2_shapeTypeCount`: The `B2ShapeType` value b2_shapeTypeCount: The number of shape types.
- `b2_toiStateUnknown`: The `B2TOIState` value b2_toiStateUnknown: The computation didn't finish or hasn't run.
- `b2_toiStateFailed`: The `B2TOIState` value b2_toiStateFailed: The root finder failed, and the fraction is the last time known to be safe.
- `b2_toiStateOverlapped`: The `B2TOIState` value b2_toiStateOverlapped: The shapes already overlap at the start of the sweep, and the fraction is 0.
- `b2_toiStateHit`: The `B2TOIState` value b2_toiStateHit: The shapes come within the target separation, and the fraction is when.
- `b2_toiStateSeparated`: The `B2TOIState` value b2_toiStateSeparated: The shapes stay separated for the whole sweep, and the fraction is the sweep's end.
- `b2GetByteCount`: Returns the total bytes currently allocated by Box2D.
  - returns: The allocated bytes.
- `b2SetLogCallback`: Replaces the default function that receives Box2D's log messages.
  - `logFcn`: The function that receives each log message. Must not be null.
- `b2GetVersion`: Returns the version of Box2D.
  - `out`: Optional. The `B2Version` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Version`, which is `out` when provided.
- `b2IsDoublePrecision`: Returns whether the library was built with `BOX2D_DOUBLE_PRECISION` (large world mode).
  - returns: True when built with double precision.
- `b2IsAVX2Available`: Returns whether the current CPU has the AVX2 instruction set.
  - returns: True when AVX2 is available.
- `b2GetTicks`: Returns the current system tick count.
  - returns: The tick count.

  The tick unit depends on the platform. Pass the value to `b2GetMilliseconds` to measure elapsed time.
- `b2GetMilliseconds`: Returns the milliseconds that have passed since an earlier tick count.
  - `ticks`: A tick count returned by `b2GetTicks`.
  - returns: The elapsed time, in milliseconds.
- `b2GetMillisecondsAndReset`: Returns the milliseconds that have passed since an earlier tick count, and replaces that count with the current one.
  - `ticks`: A one-element array holding a tick count returned by `b2GetTicks`. The call stores the current tick count at index 0.
  - returns: The elapsed time, in milliseconds.
- `b2Hash`: Returns the djb2 hash of bytes, for determinism testing.
  - `hash`: The starting hash value, `B2_HASH_INIT` for the first buffer.
  - `data`: The bytes to hash, read from index 0.
  - `count`: The number of bytes to hash.
  - returns: The hash, as an unsigned 32-bit value held in an `Int`.

  Hash a series of buffers by passing each result as the next `hash`. Start with `B2_HASH_INIT`.
- `b2IsValidFloat`: Returns whether a number is finite.
  - `a`: The number.
  - returns: False when the number is NaN or infinity.
- `b2IsValidVec2`: Returns whether both components of a vector are finite.
  - `v`: The vector.
  - returns: False when a component is NaN or infinity.
- `b2IsValidRot`: Returns whether a rotation is finite and normalized.
  - `q`: The rotation.
  - returns: False when a component is NaN or infinity, or the rotation is not normalized.
- `b2IsValidTransform`: Returns whether a transform is finite and its rotation is normalized.
  - `t`: The transform.
  - returns: False when a component is NaN or infinity, or the rotation is not normalized.
- `b2IsValidAABB`: Returns whether a bounding box is finite and its upper bound is not below its lower bound.
  - `aabb`: The bounding box.
  - returns: False when a component is NaN or infinity, or the upper bound is below the lower bound in either axis.
- `b2IsValidPlane`: Returns whether a plane is finite and its normal is a unit vector.
  - `a`: The plane.
  - returns: False when the plane's normal is not a unit vector, or a component is NaN or infinity.
- `b2IsValidPos`: Returns whether a world position is finite.
  - `p`: The world position.
  - returns: False when a component is NaN or infinity.
- `b2IsValidWorldTransform`: Returns whether a world transform is finite and its rotation is normalized.
  - `t`: The world transform.
  - returns: False when a component is NaN or infinity, or the rotation is not normalized.
- `b2MinInt`: Returns the smaller of two integers.
  - `a`: The first integer.
  - `b`: The second integer.
  - returns: The smaller integer.
- `b2MaxInt`: Returns the larger of two integers.
  - `a`: The first integer.
  - `b`: The second integer.
  - returns: The larger integer.
- `b2AbsInt`: Returns the absolute value of an integer.
  - `a`: The integer.
  - returns: The absolute value.
- `b2ClampInt`: Returns an integer limited to a range.
  - `a`: The integer.
  - `lower`: The lower bound.
  - `upper`: The upper bound.
  - returns: The integer, or the nearest bound when it lies outside the range.
- `b2CeilingInt`: Returns the integer division of a numerator by a denominator, rounded up.
  - `numerator`: The numerator. Must not be negative.
  - `denominator`: The denominator. Must be greater than zero.
  - returns: The quotient, rounded up.
- `b2MinFloat`: Returns the smaller of two floats.
  - `a`: The first float.
  - `b`: The second float.
  - returns: The smaller float.
- `b2MaxFloat`: Returns the larger of two floats.
  - `a`: The first float.
  - `b`: The second float.
  - returns: The larger float.
- `b2AbsFloat`: Returns the absolute value of a float.
  - `a`: The float.
  - returns: The absolute value.
- `b2ClampFloat`: Returns a float limited to a range.
  - `a`: The float.
  - `lower`: The lower bound.
  - `upper`: The upper bound.
  - returns: The float, or the nearest bound when it lies outside the range.
- `b2Atan2`: Returns an approximate arctangent of `y / x`, in radians within [-pi, pi].
  - `y`: The y coordinate.
  - `x`: The x coordinate.
  - returns: The angle, in radians.

  Box2D computes this itself, so the result is the same on every platform, which `Math.atan2` does not guarantee. The error is up to about 0.0023 degrees. Returns 0 when both arguments are 0.
- `b2ComputeCosSin`: Returns the cosine and sine of an angle, computed so the result is the same on every platform.
  - `radians`: The angle, in radians.
  - `out`: Optional. The `B2CosSin` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2CosSin`, which is `out` when provided.
- `b2Dot`: Returns the dot product of two vectors.
  - `a`: The first vector.
  - `b`: The second vector.
  - returns: The dot product.
- `b2Cross`: Returns the cross product of two vectors, a scalar in 2D.
  - `a`: The first vector.
  - `b`: The second vector.
  - returns: The cross product, `a.x * b.y - a.y * b.x`.
- `b2CrossVS`: Returns the cross product of a vector and a scalar, a vector in 2D.
  - `v`: The vector.
  - `s`: The scalar.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided. It holds `(s * v.y, -s * v.x)`.
- `b2CrossSV`: Returns the cross product of a scalar and a vector, a vector in 2D.
  - `s`: The scalar.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided. It holds `(-s * v.y, s * v.x)`.
- `b2LeftPerp`: Returns the vector rotated 90 degrees counter-clockwise, which is `b2CrossSV(1, v)`.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided. It holds `(-v.y, v.x)`.
- `b2RightPerp`: Returns the vector rotated 90 degrees clockwise, which is `b2CrossVS(v, 1)`.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided. It holds `(v.y, -v.x)`.
- `b2Add`: Returns the sum of two vectors.
  - `a`: The first vector.
  - `b`: The second vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Sub`: Returns the difference `a - b` of two vectors.
  - `a`: The vector to subtract from.
  - `b`: The vector to subtract.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Neg`: Returns the negation of a vector.
  - `a`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Lerp`: Returns the point between two vectors at a fraction of the way from the first to the second.
  - `a`: The vector at `t` of 0.
  - `b`: The vector at `t` of 1.
  - `t`: The fraction, 0 to 1.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Mul`: Returns the component-wise product of two vectors.
  - `a`: The first vector.
  - `b`: The second vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2MulSV`: Returns a vector scaled by a scalar.
  - `s`: The scalar.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2MulAdd`: Returns `a + s * b`.
  - `a`: The vector to add to.
  - `s`: The scalar.
  - `b`: The vector to scale.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2MulSub`: Returns `a - s * b`.
  - `a`: The vector to subtract from.
  - `s`: The scalar.
  - `b`: The vector to scale.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Abs`: Returns the absolute value of each component of a vector.
  - `a`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Min`: Returns the smaller of each component of two vectors.
  - `a`: The first vector.
  - `b`: The second vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Max`: Returns the larger of each component of two vectors.
  - `a`: The first vector.
  - `b`: The second vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Clamp`: Returns a vector with each component limited to the range between the matching components of two vectors.
  - `v`: The vector.
  - `a`: The lower bound vector.
  - `b`: The upper bound vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Length`: Returns the length of a vector.
  - `v`: The vector.
  - returns: The length.
- `b2Distance`: Returns the distance between two points.
  - `a`: The first point.
  - `b`: The second point.
  - returns: The distance.
- `b2Normalize`: Returns a vector scaled to length 1.
  - `a`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.

  Returns the zero vector when the length is too small to scale.
- `b2IsNormalized`: Returns whether a vector has length 1, within a small tolerance.
  - `a`: The vector.
  - returns: True when the vector is normalized.
- `b2GetLengthAndNormalize`: Returns a vector scaled to length 1, and stores the vector's original length.
  - `length`: A one-element array. The call stores the original length at index 0.
  - `a`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.

  Returns the zero vector, with a length of 0, when the length is too small to scale.
- `b2NormalizeRot`: Returns a rotation scaled to unit magnitude.
  - `q`: The rotation.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2IntegrateRotation`: Returns a rotation advanced by an angular displacement.
  - `q1`: The initial rotation.
  - `deltaAngle`: The angular displacement, in radians.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.

  The result is normalized.
- `b2LengthSquared`: Returns the squared length of a vector.
  - `v`: The vector.
  - returns: The squared length.
- `b2DistanceSquared`: Returns the squared distance between two points.
  - `a`: The first point.
  - `b`: The second point.
  - returns: The squared distance.
- `b2MakeRot`: Returns the rotation for an angle.
  - `radians`: The angle, in radians.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2MakeRotFromUnitVector`: Returns the rotation whose x-axis is a unit vector.
  - `unitVector`: The unit vector, which must be normalized.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2ComputeRotationBetweenUnitVectors`: Returns the rotation from one unit vector to another.
  - `v1`: The first unit vector.
  - `v2`: The second unit vector.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2IsNormalizedRot`: Returns whether a rotation has unit magnitude, within a small tolerance.
  - `q`: The rotation.
  - returns: True when the rotation is normalized.
- `b2InvertRot`: Returns the inverse of a rotation.
  - `a`: The rotation.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2NLerp`: Returns the normalized linear interpolation between two rotations.
  - `q1`: The rotation at `t` of 0.
  - `q2`: The rotation at `t` of 1.
  - `t`: The fraction, 0 to 1.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2ComputeAngularVelocity`: Returns the angular velocity that rotates from one rotation to another over a time step.
  - `q1`: The initial rotation.
  - `q2`: The final rotation.
  - `inv_h`: The inverse of the time step, in 1/seconds.
  - returns: The angular velocity, in radians per second.
- `b2Rot_GetAngle`: Returns the angle of a rotation, in radians within [-pi, pi].
  - `q`: The rotation.
  - returns: The angle, in radians.
- `b2Rot_GetXAxis`: Returns the x-axis of a rotation.
  - `q`: The rotation.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2Rot_GetYAxis`: Returns the y-axis of a rotation.
  - `q`: The rotation.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2MulRot`: Returns the product `q * r` of two rotations.
  - `q`: The left rotation.
  - `r`: The right rotation.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.
- `b2InvMulRot`: Returns the product `inv(a) * b` of two rotations.
  - `a`: The rotation to invert.
  - `b`: The rotation to multiply by.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Rot`, which is `out` when provided.

  The result rotates a vector in frame `b` into a vector in frame `a`.
- `b2RelativeAngle`: Returns the angle of one rotation relative to another, in radians.
  - `a`: The reference rotation.
  - `b`: The rotation to measure.
  - returns: The angle of `b` relative to `a`, in radians within [-pi, pi].
- `b2UnwindAngle`: Returns an angle brought into the range [-pi, pi].
  - `radians`: The angle, in radians.
  - returns: The equivalent angle, in radians.

  The angle's magnitude should stay below 10000 radians. Unwind angles regularly.
- `b2RotateVector`: Returns a vector rotated by a rotation.
  - `q`: The rotation.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2InvRotateVector`: Returns a vector rotated by the inverse of a rotation.
  - `q`: The rotation to invert.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2TransformPoint`: Returns a point transformed by a transform, for example from local space to world space.
  - `t`: The transform.
  - `p`: The point.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2InvTransformPoint`: Returns a point transformed by the inverse of a transform, for example from world space to local space.
  - `t`: The transform to invert.
  - `p`: The point.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2MulTransforms`: Returns the product of two transforms.
  - `A`: The outer transform.
  - `B`: The inner transform.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Transform`, which is `out` when provided.

  Applied to a point local to frame `B`, the result converts the point to frame `A`'s space, then into the world. This equals `A.q.Rot(B.q.Rot(v1) + B.p) + A.p`.
- `b2InvMulTransforms`: Returns the transform that converts a point local to frame `B` into a point local to frame `A`.
  - `A`: The transform of frame `A`.
  - `B`: The transform of frame `B`.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Transform`, which is `out` when provided.

  The result is `A.q' * B.q * v1 + A.q' * (B.p - A.p)`.
- `b2ToPos`: Returns a vector as a world position.
  - `v`: The vector.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Pos`, which is `out` when provided.

  Returns a copy of the vector in single precision.
- `b2ToVec2`: Returns a world position as a vector.
  - `p`: The world position.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.

  Returns a copy of the position in single precision.
- `b2RoundDownFloat`: Returns a world coordinate narrowed to a float, rounded toward negative infinity.
  - `x`: The world coordinate.
  - returns: The coordinate, rounded down.

  Use with `b2RoundUpFloat` to build a float box that always contains double precision bounds. In single precision, the value is returned unchanged.
- `b2RoundUpFloat`: Returns a world coordinate narrowed to a float, rounded toward positive infinity.
  - `x`: The world coordinate.
  - returns: The coordinate, rounded up.

  Use with `b2RoundDownFloat` to build a float box that always contains double precision bounds. In single precision, the value is returned unchanged.
- `b2SubPos`: Returns the difference `a - b` of two world positions as a vector.
  - `a`: The position to subtract from.
  - `b`: The position to subtract.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2OffsetPos`: Returns a world position moved by a vector.
  - `p`: The world position.
  - `d`: The offset.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Pos`, which is `out` when provided.
- `b2LerpPos`: Returns the world position between two positions at a fraction of the way from the first to the second.
  - `a`: The position at `t` of 0.
  - `b`: The position at `t` of 1.
  - `t`: The fraction, 0 to 1.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Pos`, which is `out` when provided.
- `b2TransformWorldPoint`: Returns a local point transformed to a world position.
  - `t`: The world transform.
  - `p`: The local point.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Pos`, which is `out` when provided.
- `b2InvTransformWorldPoint`: Returns a world position transformed to a point local to a world transform.
  - `t`: The world transform.
  - `p`: The world position.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2InvMulWorldTransforms`: Returns the transform of frame `B` relative to frame `A`.
  - `A`: The world transform of frame `A`.
  - `B`: The world transform of frame `B`.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Transform`, which is `out` when provided.
- `b2MulWorldTransforms`: Returns a local transform converted into world space by a world transform.
  - `A`: The world transform.
  - `B`: The local transform.
  - `out`: Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2WorldTransform`, which is `out` when provided.
- `b2ToRelativeTransform`: Returns a world transform expressed relative to a base position.
  - `t`: The world transform.
  - `base`: The base world position.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Transform`, which is `out` when provided.
- `b2MakeWorldTransform`: Returns a transform as a world transform.
  - `t`: The transform.
  - `out`: Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2WorldTransform`, which is `out` when provided.

  The conversion loses nothing.
- `b2MulMV`: Returns a 2-by-2 matrix multiplied by a vector.
  - `A`: The matrix.
  - `v`: The vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2GetInverse22`: Returns the inverse of a 2-by-2 matrix.
  - `A`: The matrix.
  - `out`: Optional. The `B2Mat22` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Mat22`, which is `out` when provided.

  Returns the zero matrix when the matrix is singular.
- `b2Solve22`: Returns the solution `x` of `A * x = b`.
  - `A`: The matrix.
  - `b`: The right-hand side column vector.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.

  Cheaper than computing the inverse when solving once. Returns the zero vector when the matrix is singular.
- `b2AABB_Contains`: Returns whether one bounding box fully contains another.
  - `a`: The containing bounding box.
  - `b`: The bounding box to test.
  - returns: True when `a` contains `b`.
- `b2AABB_Center`: Returns the center of a bounding box.
  - `a`: The bounding box.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2AABB_Extents`: Returns the half-widths of a bounding box.
  - `a`: The bounding box.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2Vec2`, which is `out` when provided.
- `b2AABB_Union`: Returns the smallest bounding box that contains two bounding boxes.
  - `a`: The first bounding box.
  - `b`: The second bounding box.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2AABB`, which is `out` when provided.
- `b2AABB_Overlaps`: Returns whether two bounding boxes overlap.
  - `a`: The first bounding box.
  - `b`: The second bounding box.
  - returns: True when the bounding boxes overlap.
- `b2MakeAABB`: Returns the bounding box of circles of one radius centered on points.
  - `points`: The circle centers, read from index 0 up to `count`.
  - `count`: The number of points. Must be greater than zero.
  - `radius`: The radius of every circle.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The `B2AABB`, which is `out` when provided.
- `b2PlaneSeparation`: Returns the signed separation of a point from a plane.
  - `plane`: The plane.
  - `point`: The point.
  - returns: The distance along the plane's normal, positive on the normal's side.
- `b2SpringDamper`: Returns the new velocity of a one-dimensional mass-spring-damper that drives toward a position of zero.
  - `hertz`: The spring frequency, in hertz.
  - `dampingRatio`: The damping ratio, where 1 is critical damping.
  - `position`: The current position.
  - `velocity`: The current velocity.
  - `timeStep`: The time step, in seconds.
  - returns: The new velocity.

  Compute the new position with `position += timeStep * newVelocity`. The solution is stable because it uses implicit integration, and needs no transcendental functions.
- `b2SetLengthUnitsPerMeter`: Sets the length units per meter, for programs whose units are not meters.
  - `lengthUnits`: The length units per meter. Must be finite and greater than zero.

  Box2D tunes its internal tolerances and thresholds for meters, and scales them by this value. Lengths are never scaled otherwise, so every length sent to and returned from Box2D is in the program's units. A good value is the height of the player character, such as 32 for a character 32 pixels high. Gravity, density and forces then need values suited to those units.

  _Note that this must be called once at startup, before any other Box2D call._ The default is 1.
- `b2GetLengthUnitsPerMeter`: Returns the length units per meter.
  - returns: The length units per meter. The default is 1.
- `b2IsValidRay`: Returns whether a ray cast input has finite values and a `maxFraction` from 0 up to `B2_HUGE`.
  - `input`: The ray cast input to check.
  - returns: True when the input is valid, false when it holds a NaN, an infinity or an out of range `maxFraction`.
- `b2MakePolygon`: Makes a convex polygon from a convex hull.
  - `hull`: The hull, computed by `b2ComputeHull`.
  - `radius`: The rounding radius of the polygon, in length units. Zero makes sharp corners.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.

  The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5. Do not fill in the hull's fields by hand.
- `b2MakeOffsetPolygon`: Makes a convex polygon from a convex hull, moved and rotated by an offset.
  - `hull`: The hull, computed by `b2ComputeHull`.
  - `position`: The offset of the polygon, in length units.
  - `rotation`: The rotation of the polygon.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon, with sharp corners.

  The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5.
- `b2MakeOffsetRoundedPolygon`: Makes a rounded convex polygon from a convex hull, moved and rotated by an offset.
  - `hull`: The hull, computed by `b2ComputeHull`.
  - `position`: The offset of the polygon, in length units.
  - `rotation`: The rotation of the polygon.
  - `radius`: The rounding radius of the polygon, in length units.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.

  The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5.
- `b2MakeSquare`: Makes a square polygon centered on the origin, without a convex hull.
  - `halfWidth`: The half-width of the square, in length units.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.
- `b2MakeBox`: Makes a box polygon centered on the origin, without a convex hull.
  - `halfWidth`: The half-width along the x-axis, in length units.
  - `halfHeight`: The half-height along the y-axis, in length units.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.
- `b2MakeRoundedBox`: Makes a box polygon with rounded corners centered on the origin, without a convex hull.
  - `halfWidth`: The half-width along the x-axis, in length units.
  - `halfHeight`: The half-height along the y-axis, in length units.
  - `radius`: The rounding radius, in length units. The rounding extends beyond the half-width and half-height.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.
- `b2MakeOffsetBox`: Makes a box polygon moved and rotated by an offset, without a convex hull.
  - `halfWidth`: The half-width along the box's x-axis, in length units.
  - `halfHeight`: The half-height along the box's y-axis, in length units.
  - `center`: The local center of the box, in length units.
  - `rotation`: The local rotation of the box.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.
- `b2MakeOffsetRoundedBox`: Makes a box polygon with rounded corners, moved and rotated by an offset, without a convex hull.
  - `halfWidth`: The half-width along the box's x-axis, in length units.
  - `halfHeight`: The half-height along the box's y-axis, in length units.
  - `center`: The local center of the box, in length units.
  - `rotation`: The local rotation of the box.
  - `radius`: The rounding radius, in length units. The rounding extends beyond the half-width and half-height.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon.
- `b2TransformPolygon`: Returns a polygon moved by a transform. Useful for moving a shape from one body to another.
  - `transform`: The transform to apply.
  - `polygon`: The polygon to transform.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The transformed polygon.
- `b2ComputeCircleMass`: Computes the mass, center of mass and rotational inertia of a circle.
  - `shape`: The circle.
  - `density`: The density, in kilograms per square meter.
  - `out`: Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The mass data.
- `b2ComputeCapsuleMass`: Computes the mass, center of mass and rotational inertia of a capsule.
  - `shape`: The capsule.
  - `density`: The density, in kilograms per square meter.
  - `out`: Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The mass data.
- `b2ComputePolygonMass`: Computes the mass, center of mass and rotational inertia of a polygon.
  - `shape`: The polygon.
  - `density`: The density, in kilograms per square meter.
  - `out`: Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The mass data.
- `b2ComputeCircleBounds`: Computes the bounding box of a transformed circle.
  - `shape`: The circle, in its local space.
  - `transform`: The world transform of the shape.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The axis-aligned bounding box in world space.
- `b2ComputeCapsuleBounds`: Computes the bounding box of a transformed capsule.
  - `shape`: The capsule, in its local space.
  - `transform`: The world transform of the shape.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The axis-aligned bounding box in world space.
- `b2ComputePolygonBounds`: Computes the bounding box of a transformed polygon.
  - `shape`: The polygon, in its local space.
  - `transform`: The world transform of the shape.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The axis-aligned bounding box in world space.
- `b2ComputeSegmentBounds`: Computes the bounding box of a transformed line segment.
  - `shape`: The line segment, in its local space.
  - `transform`: The world transform of the shape.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The axis-aligned bounding box in world space.
- `b2PointInCircle`: Tests whether a point overlaps a circle, in the shape's local space.
  - `shape`: The circle.
  - `point`: The point, in the shape's local space.
  - returns: True when the point is inside the shape.
- `b2PointInCapsule`: Tests whether a point overlaps a capsule, in the shape's local space.
  - `shape`: The capsule.
  - `point`: The point, in the shape's local space.
  - returns: True when the point is inside the shape.
- `b2PointInPolygon`: Tests whether a point overlaps a convex polygon, in the shape's local space.
  - `shape`: The convex polygon.
  - `point`: The point, in the shape's local space.
  - returns: True when the point is inside the shape.
- `b2CastRayCircle`: Casts a ray against a circle, in the shape's local space.
  - `shape`: The circle.
  - `input`: The ray, in the shape's local space.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the ray misses.
- `b2CastRayCapsule`: Casts a ray against a capsule, in the shape's local space.
  - `shape`: The capsule.
  - `input`: The ray, in the shape's local space.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the ray misses.
- `b2CastRaySegment`: Casts a ray against a line segment, in the segment's local space. The segment may be one-sided.
  - `shape`: The line segment.
  - `input`: The ray, in the segment's local space.
  - `oneSided`: When true, a hit from the left side of the segment counts as a miss.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the ray misses.
- `b2CastRayPolygon`: Casts a ray against a polygon, in the shape's local space.
  - `shape`: The polygon.
  - `input`: The ray, in the shape's local space.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the ray misses.
- `b2CastShapeCircle`: Casts a moving shape against a circle, in the shape's local space.
  - `shape`: The shape that stays in place.
  - `input`: The moving shape, its translation and its `maxFraction`.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the moving shape misses.
- `b2CastShapeCapsule`: Casts a moving shape against a capsule, in the shape's local space.
  - `shape`: The shape that stays in place.
  - `input`: The moving shape, its translation and its `maxFraction`.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the moving shape misses.
- `b2CastShapeSegment`: Casts a moving shape against a line segment, in the shape's local space.
  - `shape`: The shape that stays in place.
  - `input`: The moving shape, its translation and its `maxFraction`.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the moving shape misses.
- `b2CastShapePolygon`: Casts a moving shape against a convex polygon, in the shape's local space.
  - `shape`: The shape that stays in place.
  - `input`: The moving shape, its translation and its `maxFraction`.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output. `hit` is false when the moving shape misses.
- `b2ComputeHull`: Computes the convex hull of a set of points.
  - `points`: The points. Read from index 0 up to `count`.
  - `count`: The number of points. Must be at least 3 and at most `B2_MAX_POLYGON_VERTICES`.
  - `out`: Optional. The `B2Hull` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The hull. Its `count` is 0 when the computation fails.

  Fails when all the points are very close together, when all the points lie on a line, or when `count` is outside that range. Points that are close together are welded and collinear points are removed. Do not modify a hull once it is computed.
- `b2ValidateHull`: Returns whether a hull is valid, meaning convex and without collinear points.
  - `hull`: The hull to check.
  - returns: True when the hull is valid.

  _Note that this check is expensive and is meant for debugging, not for runtime use._
- `b2ComputeSegmentDistance`: Computes the closest points between two line segments, clamping at the end points.
  - `p1`: The first end point of the first segment.
  - `q1`: The second end point of the first segment.
  - `p2`: The first end point of the second segment.
  - `q2`: The second end point of the second segment.
  - `out`: Optional. The `B2SegmentDistanceResult` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The closest point on each segment, the fractions along each segment and the squared distance between the points.
- `b2ComputeShapeDistance`: Computes the closest points between two shapes, each represented as a point cloud.
  - `input`: The two proxies, the transform of proxy B in proxy A's frame and whether the proxy radii count.
  - `cache`: The simplex cache. Updated by the call, so a later call with a nearby transform starts faster. Set its `count` to 0 on the first call.
  - `simplexes`: Optional. Receives the algorithm's simplexes, for debugging, from index 0. Elements it holds are reused, and missing ones are made.
  - `simplexCapacity`: Optional. The most simplexes to store; 0 when omitted.
  - `out`: Optional. The `B2DistanceOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The closest points on each proxy, the distance, and the iteration and simplex counts.
- `b2CastShape`: Casts shape B, moving by a translation, against shape A, which stays in place.
  - `input`: The two proxies, the transform of proxy B in proxy A's frame, the translation of B, `maxFraction` and `canEncroach`.
  - `out`: Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast output, in shape A's frame. `hit` is false when B misses A.

  The hit point and normal are in shape A's frame. Shapes that already touch produce a `fraction` of 0.
- `b2MakeProxy`: Makes a proxy for the overlap, shape cast and distance functions. The points are copied.
  - `points`: The points. Read from index 0 up to `count`.
  - `count`: The number of points. At most `B2_MAX_POLYGON_VERTICES`, and a larger count is clamped to it.
  - `radius`: The radius around the points, in length units.
  - `out`: Optional. The `B2ShapeProxy` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The proxy.
- `b2MakeOffsetProxy`: Makes a proxy for the overlap, shape cast and distance functions, with its points moved and rotated by an offset. The points are copied.
  - `points`: The points. Read from index 0 up to `count`.
  - `count`: The number of points. At most `B2_MAX_POLYGON_VERTICES`, and a larger count is clamped to it.
  - `radius`: The radius around the points, in length units.
  - `position`: The offset of the points, in length units.
  - `rotation`: The rotation of the points.
  - `out`: Optional. The `B2ShapeProxy` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The proxy.
- `b2GetSweepTransform`: Evaluates the transform of a sweep at a time.
  - `sweep`: The sweep, holding the center of mass and rotation at the start and the end.
  - `time`: The time as a fraction from 0 (the start) to 1 (the end).
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The transform of the body's origin at that time.
- `b2ComputeTimeOfImpact`: Computes the upper bound on the time before two moving shapes penetrate.
  - `input`: The two proxies, their sweeps and the interval `maxFraction`.
  - `out`: Optional. The `B2TOIOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The output state and the time fraction.

  Time is a fraction from 0 to `maxFraction`. The computation uses a swept separating axis and can miss intermediate collisions where the shapes pass without penetrating. Call it again when the time interval changes.
- `b2CollideCircles`: Computes the contact manifold between two circles.
  - `circleA`: The first circle. Shape A, in its local space.
  - `circleB`: The second circle. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideCapsuleAndCircle`: Computes the contact manifold between a capsule and a circle.
  - `capsuleA`: The capsule. Shape A, in its local space.
  - `circleB`: The circle. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideSegmentAndCircle`: Computes the contact manifold between a segment and a circle.
  - `segmentA`: The segment. Shape A, in its local space.
  - `circleB`: The circle. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollidePolygonAndCircle`: Computes the contact manifold between a polygon and a circle.
  - `polygonA`: The polygon. Shape A, in its local space.
  - `circleB`: The circle. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideCapsules`: Computes the contact manifold between two capsules.
  - `capsuleA`: The first capsule. Shape A, in its local space.
  - `capsuleB`: The second capsule. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideSegmentAndCapsule`: Computes the contact manifold between a segment and a capsule.
  - `segmentA`: The segment. Shape A, in its local space.
  - `capsuleB`: The capsule. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollidePolygonAndCapsule`: Computes the contact manifold between a polygon and a capsule.
  - `polygonA`: The polygon. Shape A, in its local space.
  - `capsuleB`: The capsule. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollidePolygons`: Computes the contact manifold between two polygons.
  - `polygonA`: The first polygon. Shape A, in its local space.
  - `polygonB`: The second polygon. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideSegmentAndPolygon`: Computes the contact manifold between a segment and a polygon.
  - `segmentA`: The segment. Shape A, in its local space.
  - `polygonB`: The polygon. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideChainSegmentAndCircle`: Computes the contact manifold between a chain segment and a circle.
  - `segmentA`: The chain segment. Shape A, in its local space.
  - `circleB`: The circle. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideChainSegmentAndCapsule`: Computes the contact manifold between a chain segment and a capsule.
  - `segmentA`: The chain segment. Shape A, in its local space.
  - `capsuleB`: The capsule. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `cache`: The simplex cache, updated by the call. Set its `count` to 0 on the first call.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2CollideChainSegmentAndPolygon`: Computes the contact manifold between a chain segment and a polygon, which may be rounded.
  - `segmentA`: The chain segment. Shape A, in its local space.
  - `polygonB`: The polygon. Shape B, in its local space.
  - `xf`: The transform of shape B in shape A's frame.
  - `cache`: The simplex cache, updated by the call. Set its `count` to 0 on the first call.
  - `out`: Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch.
- `b2DefaultWorldDef`: Returns a world definition set to Box2D's defaults.
  - `out`: Optional. The `B2WorldDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The world definition.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultBodyDef`: Returns a body definition set to Box2D's defaults.
  - `out`: Optional. The `B2BodyDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The body definition.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultFilter`: Returns a collision filter set to Box2D's defaults.
  - `out`: Optional. The `B2Filter` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The filter, with `categoryBits` 1, `maskBits` of all ones and `groupIndex` 0.
- `b2DefaultQueryFilter`: Returns a query filter set to Box2D's defaults.
  - `out`: Optional. The `B2QueryFilter` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The query filter, with `categoryBits` 1 and `maskBits` of all ones.
- `b2DefaultSurfaceMaterial`: Returns a surface material set to Box2D's defaults.
  - `out`: Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The surface material.
- `b2DefaultShapeDef`: Returns a shape definition set to Box2D's defaults.
  - `out`: Optional. The `B2ShapeDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The shape definition.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultChainDef`: Returns a chain definition set to Box2D's defaults.
  - `out`: Optional. The `B2ChainDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The chain definition.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultDistanceJointDef`: Returns a distance joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2DistanceJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The distance joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultFilterJointDef`: Returns a filter joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2FilterJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The filter joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultMotorJointDef`: Returns a motor joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2MotorJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The motor joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultPrismaticJointDef`: Returns a prismatic joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2PrismaticJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The prismatic joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultRevoluteJointDef`: Returns a revolute joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2RevoluteJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The revolute joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultWeldJointDef`: Returns a weld joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2WeldJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The weld joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultWheelJointDef`: Returns a wheel joint definition set to Box2D's defaults.
  - `out`: Optional. The `B2WheelJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The wheel joint definition.

  Joint definitions have `B2JointDef` as their `base`, with its own defaults.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2DefaultExplosionDef`: Returns a explosion definition set to Box2D's defaults.
  - `out`: Optional. The `B2ExplosionDef` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The explosion definition.

  Make a definition with this call rather than with zeros, which are not its defaults.
- `b2GetGraphColor`: Returns the debug draw color of a constraint graph color slot.
  - `index`: The color slot, from 0 up to `B2_GRAPH_COLOR_COUNT` minus 1.
  - returns: The color, as a hex value.

  The last slot, `B2_GRAPH_COLOR_COUNT` minus 1, is the overflow color.
- `b2DefaultDebugDraw`: Returns a debug draw interface set to Box2D's defaults, so a program can implement a subset of the drawing callbacks.
  - `out`: Optional. The `B2DebugDraw` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The debug draw interface. Each drawing callback is an empty function, `drawingBounds` covers the whole world, `forceScale` and `jointScale` are 1, and `drawShapes` is true.
- `b2CreateWorld`: Creates a world for rigid body simulation.
  - `def`: The world's definition. Make it with `b2DefaultWorldDef`. The definition is not retained.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new world's id.

  A world contains bodies, shapes and constraints. Up to `B2_MAX_WORLDS` worlds can exist at once. Each world is independent of the others.

  Invalid values in the definition are rejected and logged, and the null world id is returned.
- `b2DestroyWorld`: Destroys a world, with all its bodies, shapes and joints.
  - `worldId`: The world.
- `b2World_IsValid`: Returns whether a world id refers to a world that exists.
  - `id`: The world id to check.
  - returns: True when the world exists.

  Detects an id left over from a world that was destroyed. A null world id is not valid.
- `b2World_Step`: Simulates a world for one time step.
  - `worldId`: The world to simulate.
  - `timeStep`: The time to simulate, in seconds.
  - `subStepCount`: The number of sub-steps in the step. More sub-steps increase accuracy. Usually 4.

  Performs collision detection, integration and constraint solution. Body and contact events for the step are available afterward. The events are replaced by the next step.

  _Note that the time step should be a fixed number, usually 1/60 of a second._
- `b2World_Draw`: Draws the world's shapes and other debug data through a debug draw object.
  - `worldId`: The world.
  - `draw`: The debug draw object, with its callbacks and flags.

  The object's callbacks receive each primitive to draw, and its flags choose which kinds of data are drawn.
- `b2World_GetBounds`: Returns the world bounds, the union of the bounds of all shapes.
  - `worldId`: The world.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The bounds, in world coordinates.
- `b2World_GetBodyEvents`: Returns the body events from the most recent time step.
  - `worldId`: The world.
  - `out`: Optional. The `B2BodyEvents` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The body events.

  The event data is valid until the next step. Copy anything the program keeps after that.
- `b2World_GetSensorEvents`: Returns the sensor events from the most recent time step.
  - `worldId`: The world.
  - `out`: Optional. The `B2SensorEvents` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The sensor events.

  The event data is valid until the next step. Copy anything the program keeps after that.
- `b2World_GetContactEvents`: Returns the contact events from the most recent time step.
  - `worldId`: The world.
  - `out`: Optional. The `B2ContactEvents` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact events.

  The event data is valid until the next step. Copy anything the program keeps after that.
- `b2World_GetJointEvents`: Returns the joint events from the most recent time step.
  - `worldId`: The world.
  - `out`: Optional. The `B2JointEvents` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The joint events.

  The event data is valid until the next step. Copy anything the program keeps after that.
- `b2World_OverlapAABB`: Calls a callback for each shape whose bounds may overlap a box.
  - `worldId`: The world.
  - `origin`: The origin the box is relative to.
  - `aabb`: The box, relative to the origin.
  - `filter`: The filter that chooses which shapes are reported.
  - `fcn`: The callback, called for each shape found. Returning false stops the query.
  - `context`: A value passed to the callback.
  - `out`: Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Counters of the tree traversal.

  Shapes are reported when their bounds overlap the box. The shapes themselves may not overlap it. The box is relative to the origin, which keeps the test precise far from the world origin in large world mode. Near the world origin, provide `b2Pos_zero` and a box in world coordinates.
- `b2World_OverlapShape`: Calls a callback for each shape that overlaps a shape proxy.
  - `worldId`: The world.
  - `origin`: The origin the proxy's points are relative to.
  - `proxy`: The proxy, a convex point cloud with a radius.
  - `filter`: The filter that chooses which shapes are reported.
  - `fcn`: The callback, called for each shape found. Returning false stops the query.
  - `context`: A value passed to the callback.
  - `out`: Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Counters of the tree traversal.

  The proxy points are relative to the origin. Near the world origin, provide `b2Pos_zero` and points in world coordinates.
- `b2World_CastRay`: Casts a ray into the world and calls a callback for each shape in its path.
  - `worldId`: The world to cast the ray against.
  - `origin`: The start point of the ray.
  - `translation`: The vector from the ray's start point to its end point.
  - `filter`: The filter that chooses which shapes the ray can hit.
  - `fcn`: The callback, called for each hit. It returns -1 to ignore the shape, 0 to stop, the hit's fraction to clip the cast to the closest hit, or 1 to continue.
  - `context`: A value passed to the callback.
  - `out`: Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Counters of the tree traversal.

  The callback chooses whether the cast finds the closest hit, any hit or several hits, by the value it returns. The callback may receive shapes in any order. See `b2World_CastRayClosest` for finding the closest hit alone.
- `b2World_CastRayClosest`: Casts a ray into the world and returns the closest hit.
  - `worldId`: The world.
  - `origin`: The start point of the ray.
  - `translation`: The vector from the ray's start point to its end point.
  - `filter`: The filter that chooses which shapes the ray can hit.
  - `out`: Optional. The `B2RayResult` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The hit, with its `hit` field false when the ray hit no shape.

  Ignores shapes that contain the ray's start point. Allows no custom filtering. See `b2World_CastRay` for a callback that chooses what to keep.
- `b2World_CastShape`: Casts a shape proxy through the world and calls a callback for each shape in its path.
  - `worldId`: The world.
  - `origin`: The origin the proxy's points are relative to.
  - `proxy`: The proxy, a convex point cloud with a radius.
  - `translation`: The vector the proxy moves along.
  - `filter`: The filter that chooses which shapes the proxy can hit.
  - `fcn`: The callback, called for each hit. It returns -1 to ignore the shape, 0 to stop, the hit's fraction to clip the cast to the closest hit, or 1 to continue.
  - `context`: A value passed to the callback.
  - `out`: Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Counters of the tree traversal.

  Works as `b2World_CastRay` does, with a shape in place of a point. The proxy points are relative to the origin. The points the callback receives are world positions.
- `b2World_EnableSleeping`: Sets whether bodies in the world can fall asleep.
  - `worldId`: The world.
  - `flag`: True to let bodies sleep.

  A program that doesn't need sleeping gains some performance by disabling it for the whole world. The default is set by `B2WorldDef.enableSleep`.
- `b2World_IsSleepingEnabled`: Returns whether bodies in the world can fall asleep.
  - `worldId`: The world.
  - returns: True when sleeping is enabled.
- `b2World_EnableContinuous`: Sets whether continuous collision between dynamic and static bodies is on.
  - `worldId`: The world.
  - `flag`: True to enable continuous collision.

  Continuous collision keeps fast bodies from passing through static ones. The performance gain from disabling it is small. The default is set by `B2WorldDef.enableContinuous`.
- `b2World_IsContinuousEnabled`: Returns whether continuous collision is on.
  - `worldId`: The world.
  - returns: True when continuous collision is enabled.
- `b2World_SetRestitutionThreshold`: Sets the speed below which a collision doesn't bounce.
  - `worldId`: The world.
  - `value`: The threshold, usually in meters per second.

  A very small value keeps bodies from sleeping. The default is set by `B2WorldDef.restitutionThreshold`.
- `b2World_GetRestitutionThreshold`: Returns the speed below which a collision doesn't bounce.
  - `worldId`: The world.
  - returns: The threshold, usually in meters per second.
- `b2World_SetRestitutionIterations`: Sets the number of iterations of the restitution solver.
  - `worldId`: The world.
  - `iterations`: The iteration count.

  The value is limited by `B2_MAX_RESTITUTION_ITERATIONS`.
- `b2World_GetRestitutionIterations`: Returns the number of iterations of the restitution solver.
  - `worldId`: The world.
  - returns: The iteration count.
- `b2World_EnableRestitutionPropagation`: Sets whether restitution propagates through a stack of bodies.
  - `worldId`: The world.
  - `flag`: True to enable propagation.

  The default is set by `B2WorldDef.enableRestitutionPropagation`.
- `b2World_IsRestitutionPropagationEnabled`: Returns whether restitution propagation is on.
  - `worldId`: The world.
  - returns: True when propagation is enabled.
- `b2World_SetHitEventThreshold`: Sets the collision speed that generates a hit event.
  - `worldId`: The world.
  - `value`: The threshold, usually in meters per second.

  The default is set by `B2WorldDef.hitEventThreshold`. Hit events are listed in `B2ContactEvents`.
- `b2World_GetHitEventThreshold`: Returns the collision speed that generates a hit event.
  - `worldId`: The world.
  - returns: The threshold, usually in meters per second.
- `b2World_SetCustomFilterCallback`: Registers the callback that decides whether two shapes collide.
  - `worldId`: The world.
  - `fcn`: The callback. When null, the callback is removed.
  - `context`: A value passed to the callback.

  Optional. The callback is called when the broad phase finds a pair of shapes that may collide. It adds to the shapes' filters.
- `b2World_SetPreSolveCallback`: Registers the callbacks called before a contact is solved and before continuous collision.
  - `worldId`: The world.
  - `preSolveFcn`: The pre-solve callback. When null, it is removed.
  - `preContinuousFcn`: The pre-continuous callback. When null, it is removed.
  - `context`: A value passed to the callbacks.

  Optional. The pre-solve callback can disable a contact for a step. The callbacks run during the step, so they must not change the world.
- `b2World_SetGravity`: Sets the gravity vector of the world.
  - `worldId`: The world.
  - `gravity`: The gravity, usually in meters per second squared.

  Box2D has no up direction. The program chooses one. The default is set by `B2WorldDef.gravity`.
- `b2World_GetGravity`: Returns the gravity vector of the world.
  - `worldId`: The world.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The gravity, usually in meters per second squared.
- `b2World_Explode`: Applies a radial explosion to the bodies around a point.
  - `worldId`: The world.
  - `explosionDef`: The explosion's position, radius, falloff and strength.
- `b2World_SetContactTuning`: Sets the contact tuning parameters of the world.
  - `worldId`: The world.
  - `hertz`: The contact stiffness, in cycles per second.
  - `dampingRatio`: The contact bounciness, with 1 being critical damping. Non-dimensional.
  - `pushSpeed`: The largest speed at which a contact constraint pushes bodies apart, usually in meters per second.

  _Note that this is an advanced feature._
- `b2World_GetContactTuning`: Reads the contact tuning parameters of the world.
  - `worldId`: The world.
  - `hertz`: Receives the contact stiffness, in cycles per second.
  - `dampingRatio`: Receives the contact damping ratio.
  - `pushSpeed`: Receives the largest push speed, usually in meters per second.

  Each parameter is stored at index 0 of its array.
- `b2World_SetContactRecycleDistance`: Sets the distance within which a contact's points are reused.
  - `worldId`: The world.
  - `recycleDistance`: The distance, usually in meters.

  Zero disables contact point recycling.
- `b2World_GetContactRecycleDistance`: Returns the distance within which a contact's points are reused.
  - `worldId`: The world.
  - returns: The distance, usually in meters.
- `b2World_SetMaxLinearSpeed`: Sets the largest speed a body can have.
  - `worldId`: The world.
  - `maximumLinearSpeed`: The speed, usually in meters per second.
- `b2World_GetMaxLinearSpeed`: Returns the largest speed a body can have.
  - `worldId`: The world.
  - returns: The speed, usually in meters per second.
- `b2World_EnableWarmStarting`: Sets whether constraints are warm started.
  - `worldId`: The world.
  - `flag`: True to enable warm starting.

  Meant for testing. Disabling warm starting greatly reduces stability and gains no performance.
- `b2World_IsWarmStartingEnabled`: Returns whether constraints are warm started.
  - `worldId`: The world.
  - returns: True when warm starting is enabled.
- `b2World_EnableSSE2Fallback`: Sets whether the solver uses SSE2 even where AVX2 is available.
  - `worldId`: The world.
  - `flag`: True to use SSE2.

  Meant for testing.
- `b2World_GetAwakeBodyCount`: Returns the number of awake bodies.
  - `worldId`: The world.
  - returns: The count of awake bodies.
- `b2World_GetProfile`: Returns the timings of the most recent step.
  - `worldId`: The world.
  - `out`: Optional. The `B2Profile` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The profile, with times in milliseconds.
- `b2World_GetCounters`: Returns the world's counters and sizes.
  - `worldId`: The world.
  - `out`: Optional. The `B2Counters` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The counters.
- `b2World_GetMaxCapacity`: Returns the largest sizes the world has reached.
  - `worldId`: The world.
  - `out`: Optional. The `B2Capacity` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The capacities.

  Provide the result in a `B2WorldDef` to avoid allocations and copies while the program runs.
- `b2World_SetUserData`: Sets the value stored in the world.
  - `worldId`: The world.
  - `userData`: Any value.
- `b2World_GetUserData`: Returns the value stored in the world.
  - `worldId`: The world.
  - returns: The value, as it was set.
- `b2World_SetFrictionCallback`: Sets the callback that mixes two shapes' friction.
  - `worldId`: The world.
  - `callback`: The callback. When null, the default mixing returns.

  The callback replaces the default mixing.
- `b2World_SetRestitutionCallback`: Sets the callback that mixes two shapes' restitution.
  - `worldId`: The world.
  - `callback`: The callback. When null, the default mixing returns.

  The callback replaces the default mixing.
- `b2World_SetWorkerCount`: Sets the number of workers a step spreads its work across.
  - `worldId`: The world.
  - `count`: The number of workers.

  The count is clamped to the range [1, `B2_MAX_WORKERS`]. A count above 1 runs Box2D's own threads, and a count of 1 runs the step on the calling thread. The call is refused while the world is locked.

  _Note that in a page the module runs one worker, whatever the count._
- `b2World_GetWorkerCount`: Returns the number of workers a step spreads its work across.
  - `worldId`: The world.
  - returns: The number of workers.

  Returns 0 when the world id is not valid.

  _Note that in a page the module runs one worker, whatever the count._
- `b2World_RebuildStaticTree`: Rebuilds the broad phase tree of static shapes.
  - `worldId`: The world.

  Meant for Box2D's own testing.
- `b2World_GetStateHash`: Returns a hash of the world's simulation state.
  - `worldId`: The world.
  - returns: The hash.

  Use it to detect that two simulations differ, for example in rollback resimulation.
- `b2World_GetSnapshot`: Writes a snapshot of the world's simulation state into a buffer.
  - `worldId`: The world to snapshot.
  - `image`: The buffer to write into.
  - `capacity`: The size of the buffer, in bytes.
  - returns: The number of bytes the snapshot needs. Nothing is written when that exceeds the capacity. 0 when the world is in the middle of a step.

  Call with an image whose capacity is 0 to learn the size needed, then again with a buffer of at least that size. Call between steps. Callbacks and user data are not part of a snapshot.
- `b2World_RestoreFromSnapshot`: Restores a world's simulation state from a snapshot.
  - `worldId`: The world to restore.
  - `image`: A snapshot written by `b2World_GetSnapshot`.
  - `size`: The size of the snapshot, in bytes.
  - returns: True on success. When the image is rejected, for a bad magic number, version or layout, the world is unchanged. When a corrupt image is found after the rebuild starts, false is returned and the world is unusable, so the program must destroy it.

  Ids from this world stay valid for objects that existed when the snapshot was written. Callbacks and the worker count are kept. User data on shapes, bodies and joints is cleared.
- `b2CreateWorldFromSnapshot`: Creates a world from a snapshot.
  - `image`: A snapshot written by `b2World_GetSnapshot`.
  - `size`: The size of the snapshot, in bytes.
  - `workerCount`: The new world's number of workers. 0 runs one worker. In a page the module runs one worker, whatever the count.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new world's id, or `b2_nullWorldId` on failure.

  Mainly useful for replay. The callbacks are the defaults.
- `b2CreateBody`: Creates a rigid body in a world.
  - `worldId`: The world.
  - `def`: The body's definition. Make it with `b2DefaultBodyDef`.
  - `out`: Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new body's id.

  The definition is not retained. A body has no shapes until `b2CreateCircleShape` and the other shape calls add them. Refused and logged during a callback.

  ```haxe
  var bodyDef = Box2D.b2DefaultBodyDef();
  var bodyId = Box2D.b2CreateBody(worldId, bodyDef);
  ```
- `b2DestroyBody`: Destroys a body, with all its shapes and joints.
  - `bodyId`: The body.

  The ids of the body's shapes and joints are not valid afterward.
- `b2Body_IsValid`: Returns whether a body id refers to a body that exists.
  - `id`: The body id to check.
  - returns: True when the body exists.

  Detects an id left over from a body that was destroyed. A null body id is not valid.
- `b2Body_GetType`: Returns the body's type: static, kinematic or dynamic.
  - `bodyId`: The body.
  - returns: The type.
- `b2Body_SetType`: Changes the body's type.
  - `bodyId`: The body.
  - `type`: The new type.

  Expensive. The mass properties are recomputed, whether or not automatic mass is on.
- `b2Body_SetName`: Sets the body's name.
  - `bodyId`: The body.
  - `name`: The name, for debugging.

  A name longer than `B2_NAME_LENGTH` characters is cut. A null name clears it.
- `b2Body_GetName`: Returns the body's name.
  - `bodyId`: The body.
  - returns: The name, empty when none was set.
- `b2Body_SetUserData`: Sets the value stored in the body.
  - `bodyId`: The body.
  - `userData`: Any value.
- `b2Body_GetUserData`: Returns the value stored in the body.
  - `bodyId`: The body.
  - returns: The value, as it was set.
- `b2Body_GetPosition`: Returns the position of the body's origin in the world.
  - `bodyId`: The body.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The position.
- `b2Body_GetRotation`: Returns the body's rotation in the world.
  - `bodyId`: The body.
  - `out`: Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The rotation, a cosine and sine pair.
- `b2Body_GetTransform`: Returns the body's transform in the world.
  - `bodyId`: The body.
  - `out`: Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The transform.
- `b2Body_SetTransform`: Moves the body to a position and rotation in the world.
  - `bodyId`: The body.
  - `position`: The new position of the body's origin.
  - `rotation`: The new rotation.

  The body teleports, which is fairly expensive. Prefer creating the body with its intended transform, in `B2BodyDef.position` and `B2BodyDef.rotation`. Refused and logged while the world is locked, during a step or in a callback.
- `b2Body_GetLocalPoint`: Returns a world point in the body's local space.
  - `bodyId`: The body.
  - `worldPoint`: The point in world coordinates.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The point in the body's local space.
- `b2Body_GetWorldPoint`: Returns a point of the body's local space in the world.
  - `bodyId`: The body.
  - `localPoint`: The point in the body's local space.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The point in world coordinates.
- `b2Body_GetLocalVector`: Returns a world vector in the body's local space.
  - `bodyId`: The body.
  - `worldVector`: The vector in world coordinates.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The vector in the body's local space.
- `b2Body_GetWorldVector`: Returns a vector of the body's local space in the world.
  - `bodyId`: The body.
  - `localVector`: The vector in the body's local space.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The vector in world coordinates.
- `b2Body_GetLinearVelocity`: Returns the linear velocity of the body's center of mass.
  - `bodyId`: The body.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The velocity, usually in meters per second.
- `b2Body_GetAngularVelocity`: Returns the body's angular velocity.
  - `bodyId`: The body.
  - returns: The velocity, in radians per second.
- `b2Body_SetLinearVelocity`: Sets the linear velocity of the body's center of mass.
  - `bodyId`: The body.
  - `linearVelocity`: The velocity, usually in meters per second.
- `b2Body_SetAngularVelocity`: Sets the body's angular velocity.
  - `bodyId`: The body.
  - `angularVelocity`: The velocity, in radians per second.
- `b2Body_SetTargetTransform`: Sets the body's velocity to reach a transform after a time step.
  - `bodyId`: The body.
  - `target`: The transform to reach at the end of the next step.
  - `timeStep`: The time step of the next call to `b2World_Step`, in seconds.
  - `wake`: True to wake the body.

  The result is close to the target but may not be exact. Meant for kinematic bodies. The target is not applied when the needed velocity is below the sleep threshold and the body is asleep.
- `b2Body_GetLocalPointVelocity`: Returns the velocity of a point fixed to the body, in the body's local space.
  - `bodyId`: The body.
  - `localPoint`: The point in the body's local space.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The velocity, usually in meters per second.
- `b2Body_GetWorldPointVelocity`: Returns the velocity of a point fixed to the body, in world coordinates.
  - `bodyId`: The body.
  - `worldPoint`: The point in world coordinates.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The velocity, usually in meters per second.
- `b2Body_ApplyForce`: Applies a force at a point in the world.
  - `bodyId`: The body.
  - `force`: The force in world coordinates, usually in newtons.
  - `point`: The point of application, in world coordinates.
  - `wake`: True to wake the body.

  A force away from the center of mass also produces a torque and changes the angular velocity. The force is ignored when the body is not awake. The force lasts until the next step.
- `b2Body_ApplyForceToCenter`: Applies a force to the body's center of mass.
  - `bodyId`: The body.
  - `force`: The force in world coordinates, usually in newtons.
  - `wake`: True to wake the body.

  The force is ignored when the body is not awake. The force lasts until the next step.
- `b2Body_ApplyTorque`: Applies a torque to the body.
  - `bodyId`: The body.
  - `torque`: The torque about the z axis, out of the screen, usually in newton meters.
  - `wake`: True to wake the body.

  The angular velocity changes and the linear velocity doesn't. The torque is ignored when the body is not awake.
- `b2Body_ClearForces`: Removes the force and torque applied to the body.
  - `bodyId`: The body.

  Forces and torques are cleared after each step. The call is for removing the effect of earlier force calls before the step.
- `b2Body_ApplyLinearImpulse`: Applies an impulse at a point in the world.
  - `bodyId`: The body.
  - `impulse`: The impulse in world coordinates, usually in newton seconds.
  - `point`: The point of application, in world coordinates.
  - `wake`: True to wake the body.

  The velocity changes at once. The angular velocity changes too when the point is away from the center of mass. The impulse is ignored when the body is not awake.

  _Note that an impulse is for one-shot use. A steady push works better as a force with the sub-stepping solver._
- `b2Body_ApplyLinearImpulseToCenter`: Applies an impulse to the body's center of mass.
  - `bodyId`: The body.
  - `impulse`: The impulse in world coordinates, usually in newton seconds.
  - `wake`: True to wake the body.

  The velocity changes at once. The impulse is ignored when the body is not awake.

  _Note that an impulse is for one-shot use. A steady push works better as a force with the sub-stepping solver._
- `b2Body_ApplyAngularImpulse`: Applies an angular impulse to the body.
  - `bodyId`: The body.
  - `impulse`: The angular impulse, usually in kilogram meters squared per second.
  - `wake`: True to wake the body.

  The impulse is ignored when the body is not awake.

  _Note that an impulse is for one-shot use. A steady turn works better as a torque with the sub-stepping solver._
- `b2Body_GetMass`: Returns the body's mass.
  - `bodyId`: The body.
  - returns: The mass, usually in kilograms.
- `b2Body_GetRotationalInertia`: Returns the body's rotational inertia.
  - `bodyId`: The body.
  - returns: The inertia, usually in kilogram meters squared.
- `b2Body_GetLocalCenter`: Returns the body's center of mass in its local space.
  - `bodyId`: The body.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The center of mass.
- `b2Body_GetWorldCenter`: Returns the body's center of mass in the world.
  - `bodyId`: The body.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The center of mass, in world coordinates.
- `b2Body_SetMassData`: Overrides the body's mass properties.
  - `bodyId`: The body.
  - `massData`: The mass, center of mass and rotational inertia.

  Box2D normally computes them from the shapes and their density. Adding or removing a shape, or changing the body's type, discards the override. When motion locks fix rotation, the rotational inertia stays zero and the value provided is ignored.
- `b2Body_GetMassData`: Returns the body's mass data.
  - `bodyId`: The body.
  - `out`: Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The mass, center of mass and rotational inertia.
- `b2Body_UpdateMassFromShapes`: Recomputes the body's mass properties from its shapes.
  - `bodyId`: The body.

  Needed to undo an override from `b2Body_SetMassData`, or when automatic mass computation is off. Call it for a body of any type. Sensor shapes may have mass.
- `b2Body_SetLinearDamping`: Sets the body's linear damping.
  - `bodyId`: The body.
  - `linearDamping`: The damping, non-negative.

  Normally set in `B2BodyDef` before the body is created.
- `b2Body_GetLinearDamping`: Returns the body's linear damping.
  - `bodyId`: The body.
  - returns: The damping.
- `b2Body_SetAngularDamping`: Sets the body's angular damping.
  - `bodyId`: The body.
  - `angularDamping`: The damping, non-negative.

  Normally set in `B2BodyDef` before the body is created.
- `b2Body_GetAngularDamping`: Returns the body's angular damping.
  - `bodyId`: The body.
  - returns: The damping.
- `b2Body_SetGravityScale`: Sets the factor that scales gravity on the body.
  - `bodyId`: The body.
  - `gravityScale`: The factor, 1 for full gravity.

  Normally set in `B2BodyDef.gravityScale` before the body is created.
- `b2Body_GetGravityScale`: Returns the factor that scales gravity on the body.
  - `bodyId`: The body.
  - returns: The factor.
- `b2Body_IsAwake`: Returns whether the body is awake.
  - `bodyId`: The body.
  - returns: True when the body is awake.
- `b2Body_SetAwake`: Wakes the body, or puts it to sleep.
  - `bodyId`: The body.
  - `awake`: True to wake the body, false to put it to sleep.

  Waking a body wakes the whole island of bodies touching it. Putting a body to sleep puts that whole island to sleep, which can be expensive. Refused and logged while the world is locked, during a step or in a callback.
- `b2Body_WakeTouching`: Wakes the bodies touching the body.
  - `bodyId`: The body.

  Works for static bodies.
- `b2Body_EnableSleeping`: Sets whether the body can fall asleep.
  - `bodyId`: The body.
  - `enableSleep`: True to let the body sleep.

  Disabling sleep wakes the body and its island.
- `b2Body_IsSleepingEnabled`: Returns whether the body can fall asleep.
  - `bodyId`: The body.
  - returns: True when sleeping is enabled.
- `b2Body_SetSleepThreshold`: Sets the speed below which the body can fall asleep.
  - `bodyId`: The body.
  - `sleepThreshold`: The threshold, usually in meters per second.
- `b2Body_GetSleepThreshold`: Returns the speed below which the body can fall asleep.
  - `bodyId`: The body.
  - returns: The threshold, usually in meters per second.
- `b2Body_SetSafetyFactor`: Sets the body's continuous collision safety factor.
  - `bodyId`: The body.
  - `safetyFactor`: The factor, non-dimensional.

  A smaller factor is safer and can cause hitching. The recommended range is [0.01, 0.5].
- `b2Body_GetSafetyFactor`: Returns the body's continuous collision safety factor.
  - `bodyId`: The body.
  - returns: The factor, non-dimensional.
- `b2Body_IsEnabled`: Returns whether the body is enabled.
  - `bodyId`: The body.
  - returns: True when the body is enabled.
- `b2Body_Disable`: Removes the body from the simulation.
  - `bodyId`: The body.

  Expensive. The body keeps its shapes and joints, and `b2Body_Enable` adds it back.
- `b2Body_Enable`: Adds a disabled body back to the simulation.
  - `bodyId`: The body.

  Expensive.
- `b2Body_SetMotionLocks`: Sets which motions of the body are locked.
  - `bodyId`: The body.
  - `locks`: The locks.

  The mass properties are recomputed, since a locked rotation sets the rotational inertia to zero.
- `b2Body_GetMotionLocks`: Returns which motions of the body are locked.
  - `bodyId`: The body.
  - `out`: Optional. The `B2MotionLocks` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The locks.
- `b2Body_SetBullet`: Sets whether the body is a bullet.
  - `bodyId`: The body.
  - `flag`: True to make the body a bullet.

  A bullet gets continuous collision against dynamic and kinematic bodies, but not against other bullets. Only dynamic bodies can be bullets.
- `b2Body_IsBullet`: Returns whether the body is a bullet.
  - `bodyId`: The body.
  - returns: True when the body is a bullet.
- `b2Body_EnableContactRecycling`: Sets whether the body's contacts reuse their manifolds when the body moves slightly.
  - `bodyId`: The body.
  - `flag`: True to enable contact recycling.

  Recycling saves work. Disabling it can avoid ghost collisions on characters, at the cost of more work each step. Contacts that exist keep their setting. Contacts created after the call use the new one. The default is set by `B2BodyDef.enableContactRecycling`.
- `b2Body_IsContactRecyclingEnabled`: Returns whether the body's contacts reuse their manifolds.
  - `bodyId`: The body.
  - returns: True when contact recycling is enabled.
- `b2Body_EnableContactEvents`: Sets whether all the body's shapes generate contact events.
  - `bodyId`: The body.
  - `flag`: True to enable contact events.

  Each shape's setting is `B2ShapeDef.enableContactEvents`. _Note that changing this while the world runs can leave begin and end touch events unpaired._
- `b2Body_EnableHitEvents`: Sets whether all the body's shapes generate hit events.
  - `bodyId`: The body.
  - `flag`: True to enable hit events.

  Each shape's setting is `B2ShapeDef.enableHitEvents`.
- `b2Body_GetWorld`: Returns the world that holds the body.
  - `bodyId`: The body.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The world's id.
- `b2Body_GetShapeCount`: Returns the number of shapes on the body.
  - `bodyId`: The body.
  - returns: The count of shapes.
- `b2Body_GetShapes`: Fills an array with the ids of the body's shapes, up to a capacity.
  - `bodyId`: The body.
  - `shapeArray`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of ids stored in the array.

  A capacity of `b2Body_GetShapeCount` holds them all.
- `b2Body_GetJointCount`: Returns the number of joints on the body.
  - `bodyId`: The body.
  - returns: The count of joints.
- `b2Body_GetJoints`: Fills an array with the ids of the body's joints, up to a capacity.
  - `bodyId`: The body.
  - `jointArray`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of ids stored in the array.

  A capacity of `b2Body_GetJointCount` holds them all.
- `b2Body_GetContactCapacity`: Returns the capacity needed to read all the touching contacts of the body.
  - `bodyId`: The body.
  - returns: The capacity.
- `b2Body_GetContactData`: Fills an array with the body's touching contacts, up to a capacity.
  - `bodyId`: The body.
  - `contactData`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of contacts stored in the array.

  Box2D uses speculative collision, so some contact points may be separated.

  _Note that only the elements below the returned count are valid._
- `b2Body_ComputeBounds`: Returns the world bounds of all the body's shapes.
  - `bodyId`: The body.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The bounds, in world coordinates.

  The bounds may not contain the body's origin. When the body has no shapes, the bounds are empty and centered on the origin.
- `b2Body_GetMinExtent`: Returns the smallest distance from any point on the body's shapes to its center of mass.
  - `bodyId`: The body.
  - returns: The distance.
- `b2Body_GetMaxExtent`: Returns the largest distance from any point on the body's shapes to its center of mass.
  - `bodyId`: The body.
  - returns: The distance.
- `b2Body_GetMaxExtentFromOrigin`: Returns an upper bound on the distance from any point on the body's shapes to the body's origin.
  - `bodyId`: The body.
  - returns: The distance, conservative.
- `b2CreateCircleShape`: Creates a circle shape and attaches it to a body.
  - `bodyId`: The body to attach the shape to.
  - `def`: The shape's definition.
  - `circle`: The circle, in the body's local space.
  - `out`: Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new shape's id, or `b2_nullShapeId` when the circle is invalid.

  The shape definition and the circle are copied. Contacts are created at the next step.

  Returns `b2_nullShapeId` when the circle is invalid.
- `b2CreateSegmentShape`: Creates a line segment shape and attaches it to a body.
  - `bodyId`: The body to attach the shape to.
  - `def`: The shape's definition.
  - `segment`: The segment, in the body's local space.
  - `out`: Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new shape's id, or `b2_nullShapeId` when the segment is too short.

  The shape definition and the segment are copied. Contacts are created at the next step.
- `b2CreateChainSegmentShape`: Creates a loose chain segment shape and attaches it to a body.
  - `bodyId`: The body to attach the shape to.
  - `def`: The shape's definition.
  - `chainSegment`: The chain segment, in the body's local space.
  - `out`: Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new shape's id, or `b2_nullShapeId` when the segment is too short.

  The shape definition and the chain segment are copied. Contacts are created at the next step.

  The segment belongs to no chain, so `b2Shape_GetParentChain` returns `b2_nullChainId` for it. Its `chainId` field is ignored.

  A loose chain segment uses more memory than the segments of a chain made by `b2CreateChain`, which is preferred.
- `b2CreateCapsuleShape`: Creates a capsule shape and attaches it to a body.
  - `bodyId`: The body to attach the shape to.
  - `def`: The shape's definition.
  - `capsule`: The capsule, in the body's local space.
  - `out`: Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new shape's id, or `b2_nullShapeId` when the capsule's length is too small.

  The shape definition and the capsule are copied. Contacts are created at the next step.
- `b2CreatePolygonShape`: Creates a convex polygon shape and attaches it to a body.
  - `bodyId`: The body to attach the shape to.
  - `def`: The shape's definition.
  - `polygon`: The polygon, in the body's local space.
  - `out`: Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new shape's id, or `b2_nullShapeId` when the polygon is invalid.

  The shape definition and the polygon are copied. Contacts are created at the next step.

  Returns `b2_nullShapeId` when the polygon is invalid.
- `b2DestroyShape`: Destroys a shape.
  - `shapeId`: The shape.
  - `updateBodyMass`: Whether to update the body's mass data now.

  Destroying several shapes of one body with `updateBodyMass` false, then calling `b2Body_UpdateMassFromShapes` once, costs less than updating the body's mass at each destruction.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_IsValid`: Returns whether a shape id refers to a shape that exists.
  - `id`: The shape id.
  - returns: True when the shape exists.

  Validates up to 64K allocations.
- `b2Shape_GetType`: Returns the type of a shape.
  - `shapeId`: The shape.
  - returns: The shape's type.
- `b2Shape_GetBody`: Returns the id of the body a shape is attached to.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The body's id.
- `b2Shape_GetWorld`: Returns the id of the world that owns a shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The world's id.
- `b2Shape_IsSensor`: Returns whether a shape is a sensor.
  - `shapeId`: The shape.
  - returns: True when the shape is a sensor.

  A shape can't be changed between sensor and solid after creation, since that would break the contract for sensor events.
- `b2Shape_SetUserData`: Sets the user data of a shape.
  - `shapeId`: The shape.
  - `userData`: Any Haxe value, returned as set by `b2Shape_GetUserData`.
- `b2Shape_GetUserData`: Returns the user data of a shape.
  - `shapeId`: The shape.
  - returns: The value set by `b2Shape_SetUserData`, or null when none was set.

  Useful for finding the program's object from a shape id received in an event or a query.
- `b2Shape_SetDensity`: Sets the mass density of a shape, in kg/m^2.
  - `shapeId`: The shape.
  - `density`: The density in kg/m^2, zero or more.
  - `updateBodyMass`: Whether to update the body's mass data now.

  Updating the body's mass data is optional. See `B2ShapeDef` for the density and `b2Body_UpdateMassFromShapes` for updating the mass later.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetDensity`: Returns the mass density of a shape, in kg/m^2.
  - `shapeId`: The shape.
  - returns: The density.
- `b2Shape_SetFriction`: Sets the friction of a shape.
  - `shapeId`: The shape.
  - `friction`: The friction coefficient, zero or more.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetFriction`: Returns the friction of a shape.
  - `shapeId`: The shape.
  - returns: The friction coefficient.
- `b2Shape_SetRestitution`: Sets the restitution (bounciness) of a shape.
  - `shapeId`: The shape.
  - `restitution`: The restitution, normally from 0 to 1.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetRestitution`: Returns the restitution (bounciness) of a shape.
  - `shapeId`: The shape.
  - returns: The restitution.
- `b2Shape_SetUserMaterial`: Sets the user material identifier of a shape.
  - `shapeId`: The shape.
  - `material`: The identifier.

  Box2D passes the identifier through to the program's callbacks and doesn't interpret it.
- `b2Shape_GetUserMaterial`: Returns the user material identifier of a shape.
  - `shapeId`: The shape.
  - returns: The identifier.
- `b2Shape_SetSurfaceMaterial`: Sets the surface material of a shape.
  - `shapeId`: The shape.
  - `surfaceMaterial`: The new surface material.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetSurfaceMaterial`: Returns the surface material of a shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The surface material.
- `b2Shape_GetFilter`: Returns the collision filter of a shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2Filter` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The filter.
- `b2Shape_SetFilter`: Sets the collision filter of a shape.
  - `shapeId`: The shape.
  - `filter`: The new filter.

  Costs almost as much as recreating the shape. Contacts that no longer pass the filter are destroyed at once. New contacts are created at the next step, and the sensor overlaps are updated then too.

  See `B2ShapeDef` for the filter.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_EnableSensorEvents`: Sets whether a shape generates sensor events.
  - `shapeId`: The shape.
  - `flag`: True to generate sensor events.

  See `B2ShapeDef`'s `enableSensorEvents`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_AreSensorEventsEnabled`: Returns whether a shape generates sensor events.
  - `shapeId`: The shape.
  - returns: True when sensor events are enabled.
- `b2Shape_EnableContactEvents`: Sets whether a shape generates contact begin and end events.
  - `shapeId`: The shape.
  - `flag`: True to generate contact events.

  Applies to shapes on kinematic and dynamic bodies, and is ignored for sensors.

  _Note that changing this while contacts exist may lose begin and end events._

  Refused while the world is stepping, such as from a callback.
- `b2Shape_AreContactEventsEnabled`: Returns whether a shape generates contact begin and end events.
  - `shapeId`: The shape.
  - returns: True when contact events are enabled.
- `b2Shape_EnablePreSolveEvents`: Sets whether a shape calls the pre-solve callback.
  - `shapeId`: The shape.
  - `flag`: True to call the pre-solve callback.

  Applies to shapes on dynamic bodies, and is ignored for sensors. Pre-solve calls are expensive and, as the solver is multithreaded, must be handled with care. See `b2PreSolveCallbackFcn`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_ArePreSolveEventsEnabled`: Returns whether a shape calls the pre-solve callback.
  - `shapeId`: The shape.
  - returns: True when pre-solve events are enabled.
- `b2Shape_EnableHitEvents`: Sets whether a shape generates contact hit events.
  - `shapeId`: The shape.
  - `flag`: True to generate hit events.

  Ignored for sensors. A hit is reported when the approach speed exceeds `B2WorldDef`'s `hitEventThreshold`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_AreHitEventsEnabled`: Returns whether a shape generates contact hit events.
  - `shapeId`: The shape.
  - returns: True when hit events are enabled.
- `b2Shape_TestPoint`: Returns whether a world point overlaps a shape.
  - `shapeId`: The shape.
  - `point`: The point, in world space.
  - returns: True when the point is inside the shape.
- `b2Shape_CastRay`: Casts a ray against a single shape.
  - `shapeId`: The shape.
  - `origin`: The ray's start, in world space.
  - `translation`: The ray's displacement, in meters.
  - `out`: Optional. The `B2WorldCastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The cast result.

  The ray starts at the origin and extends by the translation. The output point is a world position.
- `b2Shape_GetCircle`: Returns a copy of the circle of a circle shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2Circle` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The circle, in the body's local space.

  Asserts that the shape is a circle.
- `b2Shape_GetSegment`: Returns a copy of the segment of a segment shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2Segment` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The segment, in the body's local space.

  Asserts that the shape is a segment.
- `b2Shape_GetChainSegment`: Returns a copy of the chain segment of a chain segment shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2ChainSegment` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The chain segment, in the body's local space.

  Chain segment shapes come from chains and from `b2CreateChainSegmentShape`. Asserts that the shape is a chain segment.
- `b2Shape_GetCapsule`: Returns a copy of the capsule of a capsule shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2Capsule` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The capsule, in the body's local space.

  Asserts that the shape is a capsule.
- `b2Shape_GetPolygon`: Returns a copy of the convex polygon of a polygon shape.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The polygon, in the body's local space.

  Asserts that the shape is a polygon.
- `b2Shape_SetCircle`: Changes a shape into a circle, or updates its circle.
  - `shapeId`: The shape.
  - `circle`: The circle, in the body's local space.

  The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_SetCapsule`: Changes a shape into a capsule, or updates its capsule.
  - `shapeId`: The shape.
  - `capsule`: The capsule, in the body's local space.

  The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_SetSegment`: Changes a shape into a segment, or updates its segment.
  - `shapeId`: The shape.
  - `segment`: The segment, in the body's local space.

  The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_SetPolygon`: Changes a shape into a polygon, or updates its polygon.
  - `shapeId`: The shape.
  - `polygon`: The polygon, in the body's local space.

  The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_SetChainSegment`: Changes a shape into a loose chain segment, or updates its chain segment.
  - `shapeId`: The shape.
  - `chainSegment`: The chain segment, in the body's local space.

  The shape then belongs to no chain. Asserts when the shape is a chain segment owned by a chain.

  The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetParentChain`: Returns the chain a chain segment shape belongs to.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2ChainId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The chain's id, or `b2_nullChainId` when the shape isn't a chain segment of a chain.
- `b2Shape_GetContactCapacity`: Returns the capacity needed to retrieve all the touching contacts of a shape.
  - `shapeId`: The shape.
  - returns: The number of contacts on the shape's body, which is at least the number of touching contacts of the shape. Returns 0 for a sensor shape.

  Pass the result as the capacity of `b2Shape_GetContactData`.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetContactData`: Fills an array with the touching contacts of a shape.
  - `shapeId`: The shape.
  - `contactData`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of elements filled.

  The shape is `shapeIdA` or `shapeIdB` in each contact. Box2D collides speculatively, so some contact points may be separated.

  Returns 0 for a sensor shape.

  _Note that only the elements before the returned count are valid._

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetSensorCapacity`: Returns the capacity needed to retrieve all the shapes overlapping a sensor shape.
  - `shapeId`: The sensor shape.
  - returns: The capacity `b2Shape_GetSensorData` needs to return every overlap.

  Returns 0 when the shape isn't a sensor.

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetSensorData`: Fills an array with the shapes that overlapped a sensor shape at the previous step.
  - `shapeId`: The sensor shape.
  - `visitorIds`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of elements filled.

  Returns 0 when the shape isn't a sensor.

  _Note that the overlaps may include destroyed shapes, so confirm each with `b2Shape_IsValid`. Only the elements before the returned count are valid._

  Refused while the world is stepping, such as from a callback.
- `b2Shape_GetBounds`: Returns the current bounding box of a shape, in world space.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The bounding box.
- `b2Shape_ComputeMassData`: Computes the mass data of a shape from its geometry and density.
  - `shapeId`: The shape.
  - `out`: Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The mass data, in the body's local space.
- `b2Shape_GetClosestPoint`: Returns the point on a shape closest to a target point.
  - `shapeId`: The shape.
  - `target`: The target point, in world space.
  - `out`: Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The closest point, in world space.

  The target and the result are world positions.
- `b2Shape_ApplyWind`: Applies a wind force to the body of a shape, using the density of air.
  - `shapeId`: The shape.
  - `wind`: The wind velocity, in world space.
  - `drag`: The drag coefficient, for the force that opposes the relative velocity.
  - `lift`: The lift coefficient, for the force perpendicular to the relative velocity.
  - `wake`: Whether to wake the body when it sleeps.

  The force depends on the shape's area projected along the wind direction and on the shape's velocity relative to the wind. Applies to circle, capsule and polygon shapes on dynamic bodies.
- `b2CreateChain`: Creates a chain shape and attaches it to a body.
  - `bodyId`: The body to attach the chain to.
  - `def`: The chain's definition.
  - `out`: Optional. The `B2ChainId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new chain's id.

  The chain makes one chain segment shape for each segment, with ghost vertices at its ends and at the seam of a loop. See `B2ChainDef` for the points and the materials.

  Refused while the world is stepping, such as from a callback.
- `b2DestroyChain`: Destroys a chain shape and its segment shapes.
  - `chainId`: The chain.

  Refused while the world is stepping, such as from a callback.
- `b2Chain_GetWorld`: Returns the id of the world that owns a chain shape.
  - `chainId`: The chain.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The world's id.
- `b2Chain_GetSegmentCount`: Returns the number of segments of a chain shape.
  - `chainId`: The chain.
  - returns: The segment count.
- `b2Chain_GetSegments`: Fills an array with the segment shape ids of a chain shape.
  - `chainId`: The chain.
  - `segmentArray`: The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
  - `capacity`: The most to store.
  - returns: The number of elements filled.

  Refused while the world is stepping, such as from a callback.
- `b2Chain_SetAllSurfaceMaterials`: Sets the surface material of every segment of a chain shape.
  - `chainId`: The chain.
  - `material`: The surface material.

  Refused while the world is stepping, such as from a callback.
- `b2Chain_SetSurfaceMaterial`: Sets the surface material of one segment of a chain shape.
  - `chainId`: The chain.
  - `material`: The surface material, copied into the segment.
  - `segmentIndex`: The index of the segment, from 0 up to the segment count.

  Refused while the world is stepping, such as from a callback.
- `b2Chain_GetSurfaceMaterial`: Returns the surface material of one segment of a chain shape.
  - `chainId`: The chain.
  - `segmentIndex`: The index of the segment, from 0 up to the segment count.
  - `out`: Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The surface material.
- `b2Chain_IsValid`: Returns whether a chain id refers to a chain shape that exists.
  - `id`: The chain id.
  - returns: True when the chain exists.

  Validates up to 64K allocations.
- `b2DestroyJoint`: Destroys a joint.
  - `jointId`: The joint.

  Refused while the world is stepping, such as from a callback.
- `b2Joint_IsValid`: Returns whether a joint id refers to a joint that exists.
  - `id`: The joint id.
  - returns: True when the joint exists.

  Validates up to 64K allocations.
- `b2Joint_GetType`: Returns the type of a joint.
  - `jointId`: The joint.
  - returns: The joint's type.
- `b2Joint_GetBodyA`: Returns the id of body A of a joint.
  - `jointId`: The joint.
  - `out`: Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Body A's id.
- `b2Joint_GetBodyB`: Returns the id of body B of a joint.
  - `jointId`: The joint.
  - `out`: Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: Body B's id.
- `b2Joint_GetWorld`: Returns the id of the world that owns a joint.
  - `jointId`: The joint.
  - `out`: Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The world's id.
- `b2Joint_SetLocalFrameA`: Sets the frame of a joint on body A.
  - `jointId`: The joint.
  - `localFrame`: The frame, in body A's local space.

  The frame is a position and rotation in body A's local space.
- `b2Joint_GetLocalFrameA`: Returns the frame of a joint on body A.
  - `jointId`: The joint.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The frame, in body A's local space.
- `b2Joint_SetLocalFrameB`: Sets the frame of a joint on body B.
  - `jointId`: The joint.
  - `localFrame`: The frame, in body B's local space.

  The frame is a position and rotation in body B's local space.
- `b2Joint_GetLocalFrameB`: Returns the frame of a joint on body B.
  - `jointId`: The joint.
  - `out`: Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The frame, in body B's local space.
- `b2Joint_SetCollideConnected`: Sets whether the bodies of a joint collide with each other.
  - `jointId`: The joint.
  - `shouldCollide`: True to let the connected bodies collide.

  Refused while the world is stepping, such as from a callback.
- `b2Joint_GetCollideConnected`: Returns whether the bodies of a joint collide with each other.
  - `jointId`: The joint.
  - returns: True when the connected bodies collide.
- `b2Joint_SetUserData`: Sets the user data of a joint.
  - `jointId`: The joint.
  - `userData`: Any Haxe value, returned as set by `b2Joint_GetUserData`.
- `b2Joint_GetUserData`: Returns the user data of a joint.
  - `jointId`: The joint.
  - returns: The value set by `b2Joint_SetUserData`, or null when none was set.
- `b2Joint_WakeBodies`: Wakes the bodies of a joint.
  - `jointId`: The joint.
- `b2Joint_GetConstraintForce`: Returns the constraint force of a joint, in newtons.
  - `jointId`: The joint.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The force.

  The force is the one applied at the last step.
- `b2Joint_GetConstraintTorque`: Returns the constraint torque of a joint, in newton-meters.
  - `jointId`: The joint.
  - returns: The torque.

  The torque is the one applied at the last step.
- `b2Joint_GetLinearSeparation`: Returns the current linear separation error of a joint, in meters.
  - `jointId`: The joint.
  - returns: The linear error.

  Movement the joint allows, such as sliding along a prismatic joint's axis, is not counted as error.
- `b2Joint_GetAngularSeparation`: Returns the current angular separation error of a joint, in radians.
  - `jointId`: The joint.
  - returns: The angular error.

  Movement the joint allows, such as the rotation of a revolute joint, is not counted as error.
- `b2Joint_SetConstraintTuning`: Sets the stiffness and damping of a joint's constraint.
  - `jointId`: The joint.
  - `hertz`: The stiffness, in hertz (cycles per second).
  - `dampingRatio`: The damping ratio, without a unit, where one is critical damping.

  An advanced feature. Both values must be zero or more.
- `b2Joint_GetConstraintTuning`: Reads the stiffness and damping of a joint's constraint.
  - `jointId`: The joint.
  - `hertz`: A one-element array that receives the stiffness at index 0, in hertz.
  - `dampingRatio`: A one-element array that receives the damping ratio at index 0.

  An advanced feature.
- `b2Joint_SetForceThreshold`: Sets the force above which a joint reports a joint event, in newtons.
  - `jointId`: The joint.
  - `threshold`: The force threshold.

  The threshold must be zero or more.
- `b2Joint_GetForceThreshold`: Returns the force above which a joint reports a joint event, in newtons.
  - `jointId`: The joint.
  - returns: The force threshold.
- `b2Joint_SetTorqueThreshold`: Sets the torque above which a joint reports a joint event, in newton-meters.
  - `jointId`: The joint.
  - `threshold`: The torque threshold.

  The threshold must be zero or more.
- `b2Joint_GetTorqueThreshold`: Returns the torque above which a joint reports a joint event, in newton-meters.
  - `jointId`: The joint.
  - returns: The torque threshold.
- `b2CreateDistanceJoint`: Creates a distance joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  The joint keeps a point on body A and a point on body B a set distance apart, and works as a rope or a spring. See `B2DistanceJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2DistanceJoint_SetRestLength`: Sets the distance joint's rest length, in meters.
  - `jointId`: The distance joint.
  - `length`: The new rest length, in meters.

  The length is clamped to between `B2_LINEAR_SLOP` and `B2_HUGE`. The joint's accumulated impulses reset to zero.
- `b2DistanceJoint_GetRestLength`: Returns the distance joint's rest length, in meters.
  - `jointId`: The distance joint.
  - returns: The rest length.
- `b2DistanceJoint_EnableSpring`: Sets whether the distance joint works as a spring.
  - `jointId`: The distance joint.
  - `enableSpring`: True to enable the spring, false to make the joint rigid.

  When disabled, the joint is rigid at its rest length.
- `b2DistanceJoint_IsSpringEnabled`: Returns whether the distance joint works as a spring.
  - `jointId`: The distance joint.
  - returns: True when the spring is enabled.
- `b2DistanceJoint_SetSpringForceRange`: Sets the range of force the distance joint's spring can exert, in newtons.
  - `jointId`: The distance joint.
  - `lowerForce`: The lowest spring force, in newtons.
  - `upperForce`: The highest spring force, in newtons.

  The lower force limits the tension the spring can sustain, and the upper force limits the compression. A lower force above the upper force is swapped with it.
- `b2DistanceJoint_GetSpringForceRange`: Reads the range of force the distance joint's spring can exert, in newtons.
  - `jointId`: The distance joint.
  - `lowerForce`: A one-element array that receives the lowest spring force at index 0.
  - `upperForce`: A one-element array that receives the highest spring force at index 0.
- `b2DistanceJoint_SetSpringHertz`: Sets the distance joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The distance joint.
  - `hertz`: The spring stiffness, in hertz.
- `b2DistanceJoint_SetSpringDampingRatio`: Sets the distance joint's spring damping ratio, which has no unit.
  - `jointId`: The distance joint.
  - `dampingRatio`: The spring damping ratio.

  A ratio of 1 is critical damping.
- `b2DistanceJoint_GetSpringHertz`: Returns the distance joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The distance joint.
  - returns: The spring stiffness, in hertz.
- `b2DistanceJoint_GetSpringDampingRatio`: Returns the distance joint's spring damping ratio, which has no unit.
  - `jointId`: The distance joint.
  - returns: The spring damping ratio.
- `b2DistanceJoint_GetSpringForce`: Returns the force the distance joint's spring applied in the last step, in newtons.
  - `jointId`: The distance joint.
  - returns: The spring force.

  Returns 0 when the spring is disabled.
- `b2DistanceJoint_EnableLimit`: Sets whether the distance joint enforces its minimum and maximum lengths.
  - `jointId`: The distance joint.
  - `enableLimit`: True to enforce the limits.

  _Note that the limits only act while the spring is enabled. A rigid joint stays at its rest length and ignores them._
- `b2DistanceJoint_IsLimitEnabled`: Returns whether the distance joint enforces its minimum and maximum lengths.
  - `jointId`: The distance joint.
  - returns: True when the limits are enabled.
- `b2DistanceJoint_SetLimits`: Sets the distance joint's minimum and maximum lengths, in meters.
  - `jointId`: The distance joint.
  - `minLength`: The minimum length, in meters.
  - `maxLength`: The maximum length, in meters.

  Both lengths are clamped to between `B2_LINEAR_SLOP` and `B2_HUGE`, and a minimum above the maximum is swapped with it.
- `b2DistanceJoint_GetLowerLimit`: Returns the distance joint's minimum length, in meters.
  - `jointId`: The distance joint.
  - returns: The minimum length.
- `b2DistanceJoint_GetUpperLimit`: Returns the distance joint's maximum length, in meters.
  - `jointId`: The distance joint.
  - returns: The maximum length.
- `b2DistanceJoint_GetCurrentLength`: Returns the current distance between the distance joint's two anchor points, in meters.
  - `jointId`: The distance joint.
  - returns: The current length.

  Returns 0 when the world is locked, as during a step.
- `b2DistanceJoint_EnableMotor`: Sets whether the distance joint's motor is enabled.
  - `jointId`: The distance joint.
  - `enableMotor`: True to enable the motor.

  The motor drives the joint's length at its target speed. A change of state resets the motor's accumulated impulse.
- `b2DistanceJoint_IsMotorEnabled`: Returns whether the distance joint's motor is enabled.
  - `jointId`: The distance joint.
  - returns: True when the motor is enabled.
- `b2DistanceJoint_SetTargetMotorSpeed`: Sets the speed the distance joint's motor drives the length at, usually in meters per second.
  - `jointId`: The distance joint.
  - `motorSpeed`: The target speed, usually in meters per second.
- `b2DistanceJoint_GetTargetMotorSpeed`: Returns the speed the distance joint's motor drives the length at, usually in meters per second.
  - `jointId`: The distance joint.
  - returns: The target speed.
- `b2DistanceJoint_SetMaxMotorForce`: Sets the largest force the distance joint's motor can apply, usually in newtons.
  - `jointId`: The distance joint.
  - `force`: The largest motor force, usually in newtons.
- `b2DistanceJoint_GetMaxMotorForce`: Returns the largest force the distance joint's motor can apply, usually in newtons.
  - `jointId`: The distance joint.
  - returns: The largest motor force.
- `b2DistanceJoint_GetCurrentMotorForce`: Returns the force the distance joint's motor applied in the last step, usually in newtons.
  - `jointId`: The distance joint.
  - returns: The motor force.
- `b2CreateFilterJoint`: Creates a filter joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  The joint disables collision between the two bodies and keeps them in the same simulation island. See `B2FilterJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2CreateMotorJoint`: Creates a motor joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  The joint drives the relative velocity or the relative transform of the two bodies. With a velocity of zero it acts like top-down friction. See `B2MotorJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2MotorJoint_SetLinearVelocity`: Sets the relative linear velocity the motor joint drives toward, in meters per second.
  - `jointId`: The motor joint.
  - `velocity`: The desired relative linear velocity, in meters per second.
- `b2MotorJoint_GetLinearVelocity`: Returns the relative linear velocity the motor joint drives toward, in meters per second.
  - `jointId`: The motor joint.
  - `out`: Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The desired relative linear velocity.
- `b2MotorJoint_SetAngularVelocity`: Sets the relative angular velocity the motor joint drives toward, in radians per second.
  - `jointId`: The motor joint.
  - `velocity`: The desired relative angular velocity, in radians per second.
- `b2MotorJoint_GetAngularVelocity`: Returns the relative angular velocity the motor joint drives toward, in radians per second.
  - `jointId`: The motor joint.
  - returns: The desired relative angular velocity.
- `b2MotorJoint_SetMaxVelocityForce`: Sets the largest force the motor joint applies to reach its linear velocity, in newtons.
  - `jointId`: The motor joint.
  - `maxForce`: The largest force, in newtons.
- `b2MotorJoint_GetMaxVelocityForce`: Returns the largest force the motor joint applies to reach its linear velocity, in newtons.
  - `jointId`: The motor joint.
  - returns: The largest force.
- `b2MotorJoint_SetMaxVelocityTorque`: Sets the largest torque the motor joint applies to reach its angular velocity, in newton-meters.
  - `jointId`: The motor joint.
  - `maxTorque`: The largest torque, in newton-meters.
- `b2MotorJoint_GetMaxVelocityTorque`: Returns the largest torque the motor joint applies to reach its angular velocity, in newton-meters.
  - `jointId`: The motor joint.
  - returns: The largest torque.
- `b2MotorJoint_SetLinearHertz`: Sets the stiffness of the motor joint's linear spring, in hertz.
  - `jointId`: The motor joint.
  - `hertz`: The linear spring stiffness, in hertz.

  The linear spring drives the relative position toward the joint frames coinciding.
- `b2MotorJoint_GetLinearHertz`: Returns the stiffness of the motor joint's linear spring, in hertz.
  - `jointId`: The motor joint.
  - returns: The linear spring stiffness, in hertz.
- `b2MotorJoint_SetLinearDampingRatio`: Sets the damping ratio of the motor joint's linear spring, which has no unit.
  - `jointId`: The motor joint.
  - `damping`: The linear spring damping ratio.

  A ratio of 1 is critical damping.
- `b2MotorJoint_GetLinearDampingRatio`: Returns the damping ratio of the motor joint's linear spring, which has no unit.
  - `jointId`: The motor joint.
  - returns: The linear spring damping ratio.
- `b2MotorJoint_SetAngularHertz`: Sets the stiffness of the motor joint's angular spring, in hertz.
  - `jointId`: The motor joint.
  - `hertz`: The angular spring stiffness, in hertz.

  The angular spring drives the relative rotation toward the joint frames aligning.
- `b2MotorJoint_GetAngularHertz`: Returns the stiffness of the motor joint's angular spring, in hertz.
  - `jointId`: The motor joint.
  - returns: The angular spring stiffness, in hertz.
- `b2MotorJoint_SetAngularDampingRatio`: Sets the damping ratio of the motor joint's angular spring, which has no unit.
  - `jointId`: The motor joint.
  - `damping`: The angular spring damping ratio.

  A ratio of 1 is critical damping.
- `b2MotorJoint_GetAngularDampingRatio`: Returns the damping ratio of the motor joint's angular spring, which has no unit.
  - `jointId`: The motor joint.
  - returns: The angular spring damping ratio.
- `b2MotorJoint_SetMaxSpringForce`: Sets the largest force the motor joint's linear spring applies, in newtons.
  - `jointId`: The motor joint.
  - `maxForce`: The largest spring force, in newtons.

  A negative force is clamped to 0.
- `b2MotorJoint_GetMaxSpringForce`: Returns the largest force the motor joint's linear spring applies, in newtons.
  - `jointId`: The motor joint.
  - returns: The largest spring force.
- `b2MotorJoint_SetMaxSpringTorque`: Sets the largest torque the motor joint's angular spring applies, in newton-meters.
  - `jointId`: The motor joint.
  - `maxTorque`: The largest spring torque, in newton-meters.

  A negative torque is clamped to 0.
- `b2MotorJoint_GetMaxSpringTorque`: Returns the largest torque the motor joint's angular spring applies, in newton-meters.
  - `jointId`: The motor joint.
  - returns: The largest spring torque.
- `b2CreatePrismaticJoint`: Creates a prismatic (slider) joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  Body B slides along the x-axis of frame A and can not rotate relative to body A. See `B2PrismaticJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2PrismaticJoint_EnableSpring`: Sets whether the prismatic joint's spring is enabled.
  - `jointId`: The prismatic joint.
  - `enableSpring`: True to enable the spring.

  The spring drives the joint's translation toward its target translation. A change of state resets the spring's accumulated impulse.
- `b2PrismaticJoint_IsSpringEnabled`: Returns whether the prismatic joint's spring is enabled.
  - `jointId`: The prismatic joint.
  - returns: True when the spring is enabled.
- `b2PrismaticJoint_SetSpringHertz`: Sets the prismatic joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The prismatic joint.
  - `hertz`: The spring stiffness, in hertz.

  The stiffness should usually be less than a quarter of the simulation rate. At 60 hertz, that is 15 hertz or less.
- `b2PrismaticJoint_GetSpringHertz`: Returns the prismatic joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The prismatic joint.
  - returns: The spring stiffness, in hertz.
- `b2PrismaticJoint_SetSpringDampingRatio`: Sets the prismatic joint's spring damping ratio, which has no unit.
  - `jointId`: The prismatic joint.
  - `dampingRatio`: The spring damping ratio.

  A ratio of 1 is critical damping.
- `b2PrismaticJoint_GetSpringDampingRatio`: Returns the prismatic joint's spring damping ratio, which has no unit.
  - `jointId`: The prismatic joint.
  - returns: The spring damping ratio.
- `b2PrismaticJoint_SetTargetTranslation`: Sets the translation the prismatic joint's spring drives toward, usually in meters.
  - `jointId`: The prismatic joint.
  - `translation`: The target translation, usually in meters.
- `b2PrismaticJoint_GetTargetTranslation`: Returns the translation the prismatic joint's spring drives toward, usually in meters.
  - `jointId`: The prismatic joint.
  - returns: The target translation.
- `b2PrismaticJoint_EnableLimit`: Sets whether the prismatic joint enforces its translation limits.
  - `jointId`: The prismatic joint.
  - `enableLimit`: True to enforce the limits.

  A change of state resets the limit's accumulated impulses.
- `b2PrismaticJoint_IsLimitEnabled`: Returns whether the prismatic joint enforces its translation limits.
  - `jointId`: The prismatic joint.
  - returns: True when the limits are enabled.
- `b2PrismaticJoint_GetLowerLimit`: Returns the prismatic joint's lower translation limit, in meters.
  - `jointId`: The prismatic joint.
  - returns: The lower limit.
- `b2PrismaticJoint_GetUpperLimit`: Returns the prismatic joint's upper translation limit, in meters.
  - `jointId`: The prismatic joint.
  - returns: The upper limit.
- `b2PrismaticJoint_SetLimits`: Sets the prismatic joint's lower and upper translation limits, in meters.
  - `jointId`: The prismatic joint.
  - `lower`: The lower limit, in meters.
  - `upper`: The upper limit, in meters.

  A lower limit above the upper limit is swapped with it.
- `b2PrismaticJoint_EnableMotor`: Sets whether the prismatic joint's motor is enabled.
  - `jointId`: The prismatic joint.
  - `enableMotor`: True to enable the motor.

  The motor drives the joint along its axis at its target speed. A change of state resets the motor's accumulated impulse.
- `b2PrismaticJoint_IsMotorEnabled`: Returns whether the prismatic joint's motor is enabled.
  - `jointId`: The prismatic joint.
  - returns: True when the motor is enabled.
- `b2PrismaticJoint_SetTargetMotorSpeed`: Sets the speed the prismatic joint's motor drives the joint along its axis at, usually in meters per second.
  - `jointId`: The prismatic joint.
  - `motorSpeed`: The target speed, usually in meters per second.
- `b2PrismaticJoint_GetTargetMotorSpeed`: Returns the speed the prismatic joint's motor drives the joint along its axis at, usually in meters per second.
  - `jointId`: The prismatic joint.
  - returns: The target speed.
- `b2PrismaticJoint_SetMaxMotorForce`: Sets the largest force the prismatic joint's motor can apply, usually in newtons.
  - `jointId`: The prismatic joint.
  - `force`: The largest motor force, usually in newtons.
- `b2PrismaticJoint_GetMaxMotorForce`: Returns the largest force the prismatic joint's motor can apply, usually in newtons.
  - `jointId`: The prismatic joint.
  - returns: The largest motor force.
- `b2PrismaticJoint_GetCurrentTranslation`: Returns the prismatic joint's current translation along its axis, usually in meters.
  - `jointId`: The prismatic joint.
  - returns: The current translation.

  The translation is zero when the origins of the two joint frames coincide in the world.
- `b2PrismaticJoint_GetCurrentSpeed`: Returns the prismatic joint's current translation speed along its axis, usually in meters per second.
  - `jointId`: The prismatic joint.
  - returns: The current speed.
- `b2PrismaticJoint_GetCurrentMotorForce`: Returns the force the prismatic joint's motor applied in the last step, usually in newtons.
  - `jointId`: The prismatic joint.
  - returns: The motor force.
- `b2CreateRevoluteJoint`: Creates a revolute joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  A point on body B is fixed to a point on body A, and the bodies rotate freely relative to each other. See `B2RevoluteJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2RevoluteJoint_EnableSpring`: Sets whether the revolute joint's spring is enabled.
  - `jointId`: The revolute joint.
  - `enableSpring`: True to enable the spring.

  The spring drives the joint's angle toward its target angle. A change of state resets the spring's accumulated impulse.
- `b2RevoluteJoint_IsSpringEnabled`: Returns whether the revolute joint's spring is enabled.
  - `jointId`: The revolute joint.
  - returns: True when the spring is enabled.
- `b2RevoluteJoint_SetSpringHertz`: Sets the revolute joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The revolute joint.
  - `hertz`: The spring stiffness, in hertz.
- `b2RevoluteJoint_GetSpringHertz`: Returns the revolute joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The revolute joint.
  - returns: The spring stiffness, in hertz.
- `b2RevoluteJoint_SetSpringDampingRatio`: Sets the revolute joint's spring damping ratio, which has no unit.
  - `jointId`: The revolute joint.
  - `dampingRatio`: The spring damping ratio.

  A ratio of 1 is critical damping.
- `b2RevoluteJoint_GetSpringDampingRatio`: Returns the revolute joint's spring damping ratio, which has no unit.
  - `jointId`: The revolute joint.
  - returns: The spring damping ratio.
- `b2RevoluteJoint_SetTargetAngle`: Sets the angle the revolute joint's spring drives toward, in radians.
  - `jointId`: The revolute joint.
  - `angle`: The target angle, in radians.
- `b2RevoluteJoint_GetTargetAngle`: Returns the angle the revolute joint's spring drives toward, in radians.
  - `jointId`: The revolute joint.
  - returns: The target angle, in radians.
- `b2RevoluteJoint_EnableLimit`: Sets whether the revolute joint enforces its angle limits.
  - `jointId`: The revolute joint.
  - `enableLimit`: True to enforce the limits.

  A change of state resets the limit's accumulated impulses.
- `b2RevoluteJoint_IsLimitEnabled`: Returns whether the revolute joint enforces its angle limits.
  - `jointId`: The revolute joint.
  - returns: True when the limits are enabled.
- `b2RevoluteJoint_GetLowerLimit`: Returns the revolute joint's lower angle limit, in radians.
  - `jointId`: The revolute joint.
  - returns: The lower limit.
- `b2RevoluteJoint_GetUpperLimit`: Returns the revolute joint's upper angle limit, in radians.
  - `jointId`: The revolute joint.
  - returns: The upper limit.
- `b2RevoluteJoint_SetLimits`: Sets the revolute joint's lower and upper angle limits, in radians.
  - `jointId`: The revolute joint.
  - `lower`: The lower limit, in radians.
  - `upper`: The upper limit, in radians.

  Both limits are clamped to between -0.99 * `B2_PI` and 0.99 * `B2_PI`, and a lower limit above the upper limit is swapped with it.
- `b2RevoluteJoint_EnableMotor`: Sets whether the revolute joint's motor is enabled.
  - `jointId`: The revolute joint.
  - `enableMotor`: True to enable the motor.

  The motor drives the joint angle at its target speed. A change of state resets the motor's accumulated impulse.
- `b2RevoluteJoint_IsMotorEnabled`: Returns whether the revolute joint's motor is enabled.
  - `jointId`: The revolute joint.
  - returns: True when the motor is enabled.
- `b2RevoluteJoint_SetTargetMotorSpeed`: Sets the speed the revolute joint's motor drives the joint angle at, in radians per second.
  - `jointId`: The revolute joint.
  - `motorSpeed`: The target speed, in radians per second. Positive turns body B counterclockwise relative to body A.
- `b2RevoluteJoint_GetTargetMotorSpeed`: Returns the speed the revolute joint's motor drives the joint angle at, in radians per second.
  - `jointId`: The revolute joint.
  - returns: The target speed.
- `b2RevoluteJoint_SetMaxMotorTorque`: Sets the largest torque the revolute joint's motor can apply, usually in newton-meters.
  - `jointId`: The revolute joint.
  - `torque`: The largest motor torque, usually in newton-meters.
- `b2RevoluteJoint_GetMaxMotorTorque`: Returns the largest torque the revolute joint's motor can apply, usually in newton-meters.
  - `jointId`: The revolute joint.
  - returns: The largest motor torque.
- `b2RevoluteJoint_GetCurrentAngle`: Returns the revolute joint's current angle, in radians.
  - `jointId`: The revolute joint.
  - returns: The current angle, in radians.

  The angle is the relative rotation of the two joint frames.
- `b2RevoluteJoint_GetCurrentSpeed`: Returns the revolute joint's current angular speed, in radians per second.
  - `jointId`: The revolute joint.
  - returns: The current speed, in radians per second.
- `b2RevoluteJoint_GetCurrentMotorTorque`: Returns the torque the revolute joint's motor applied in the last step, usually in newton-meters.
  - `jointId`: The revolute joint.
  - returns: The motor torque.
- `b2CreateWeldJoint`: Creates a weld joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  The joint connects the two bodies rigidly, and its springs mimic soft-body simulation. See `B2WeldJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2WeldJoint_SetLinearHertz`: Sets the weld joint's linear stiffness, in hertz.
  - `jointId`: The weld joint.
  - `hertz`: The linear stiffness, in hertz.

  A stiffness of 0 makes the linear constraint rigid.
- `b2WeldJoint_GetLinearHertz`: Returns the weld joint's linear stiffness, in hertz.
  - `jointId`: The weld joint.
  - returns: The linear stiffness, in hertz.
- `b2WeldJoint_SetLinearDampingRatio`: Sets the weld joint's linear damping ratio, which has no unit.
  - `jointId`: The weld joint.
  - `dampingRatio`: The linear damping ratio.
- `b2WeldJoint_GetLinearDampingRatio`: Returns the weld joint's linear damping ratio, which has no unit.
  - `jointId`: The weld joint.
  - returns: The linear damping ratio.
- `b2WeldJoint_SetAngularHertz`: Sets the weld joint's angular stiffness, in hertz.
  - `jointId`: The weld joint.
  - `hertz`: The angular stiffness, in hertz.

  A stiffness of 0 makes the angular constraint rigid.
- `b2WeldJoint_GetAngularHertz`: Returns the weld joint's angular stiffness, in hertz.
  - `jointId`: The weld joint.
  - returns: The angular stiffness, in hertz.
- `b2WeldJoint_SetAngularDampingRatio`: Sets the weld joint's angular damping ratio, which has no unit.
  - `jointId`: The weld joint.
  - `dampingRatio`: The angular damping ratio.
- `b2WeldJoint_GetAngularDampingRatio`: Returns the weld joint's angular damping ratio, which has no unit.
  - `jointId`: The weld joint.
  - returns: The angular damping ratio.
- `b2CreateWheelJoint`: Creates a wheel joint between two bodies and returns its id.
  - `worldId`: The world.
  - `def`: The joint's definition, read during the call.
  - `out`: Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The new joint's id.

  Body B is a wheel that rotates freely and slides along the x-axis of frame A. See `B2WheelJointDef` for the settings.

  Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.
- `b2WheelJoint_EnableSpring`: Sets whether the wheel joint's spring is enabled.
  - `jointId`: The wheel joint.
  - `enableSpring`: True to enable the spring.

  The spring acts along the joint's axis, as a suspension does. A change of state resets the spring's accumulated impulse.
- `b2WheelJoint_IsSpringEnabled`: Returns whether the wheel joint's spring is enabled.
  - `jointId`: The wheel joint.
  - returns: True when the spring is enabled.
- `b2WheelJoint_SetSpringHertz`: Sets the wheel joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The wheel joint.
  - `hertz`: The spring stiffness, in hertz.
- `b2WheelJoint_GetSpringHertz`: Returns the wheel joint's spring stiffness, in hertz (cycles per second).
  - `jointId`: The wheel joint.
  - returns: The spring stiffness, in hertz.
- `b2WheelJoint_SetSpringDampingRatio`: Sets the wheel joint's spring damping ratio, which has no unit.
  - `jointId`: The wheel joint.
  - `dampingRatio`: The spring damping ratio.

  A ratio of 1 is critical damping.
- `b2WheelJoint_GetSpringDampingRatio`: Returns the wheel joint's spring damping ratio, which has no unit.
  - `jointId`: The wheel joint.
  - returns: The spring damping ratio.
- `b2WheelJoint_EnableLimit`: Sets whether the wheel joint enforces its translation limits.
  - `jointId`: The wheel joint.
  - `enableLimit`: True to enforce the limits.

  A change of state resets the limit's accumulated impulses.
- `b2WheelJoint_IsLimitEnabled`: Returns whether the wheel joint enforces its translation limits.
  - `jointId`: The wheel joint.
  - returns: True when the limits are enabled.
- `b2WheelJoint_GetLowerLimit`: Returns the wheel joint's lower translation limit, in meters.
  - `jointId`: The wheel joint.
  - returns: The lower limit.
- `b2WheelJoint_GetUpperLimit`: Returns the wheel joint's upper translation limit, in meters.
  - `jointId`: The wheel joint.
  - returns: The upper limit.
- `b2WheelJoint_SetLimits`: Sets the wheel joint's lower and upper translation limits, in meters.
  - `jointId`: The wheel joint.
  - `lower`: The lower limit, in meters.
  - `upper`: The upper limit, in meters.

  A lower limit above the upper limit is swapped with it.
- `b2WheelJoint_EnableMotor`: Sets whether the wheel joint's motor is enabled.
  - `jointId`: The wheel joint.
  - `enableMotor`: True to enable the motor.

  The motor drives the wheel's rotation at its target speed. A change of state resets the motor's accumulated impulse.
- `b2WheelJoint_IsMotorEnabled`: Returns whether the wheel joint's motor is enabled.
  - `jointId`: The wheel joint.
  - returns: True when the motor is enabled.
- `b2WheelJoint_SetTargetMotorSpeed`: Sets the speed the wheel joint's motor drives the wheel's rotation at, in radians per second.
  - `jointId`: The wheel joint.
  - `motorSpeed`: The target speed, in radians per second. Positive turns body B counterclockwise relative to body A, so a wheel rolling toward +x on level ground needs a negative speed.
- `b2WheelJoint_GetTargetMotorSpeed`: Returns the speed the wheel joint's motor drives the wheel's rotation at, in radians per second.
  - `jointId`: The wheel joint.
  - returns: The target speed.
- `b2WheelJoint_SetMaxMotorTorque`: Sets the largest torque the wheel joint's motor can apply, usually in newton-meters.
  - `jointId`: The wheel joint.
  - `torque`: The largest motor torque, usually in newton-meters.
- `b2WheelJoint_GetMaxMotorTorque`: Returns the largest torque the wheel joint's motor can apply, usually in newton-meters.
  - `jointId`: The wheel joint.
  - returns: The largest motor torque.
- `b2WheelJoint_GetCurrentMotorTorque`: Returns the torque the wheel joint's motor applied in the last step, usually in newton-meters.
  - `jointId`: The wheel joint.
  - returns: The motor torque.
- `b2Contact_IsValid`: Returns whether a contact id refers to a contact that still exists.
  - `id`: The contact id.
  - returns: True when the contact exists.

  A contact id can become orphaned when its contact ends. Check it with this call before using it in other contact calls.
- `b2Contact_GetData`: Returns the data of a contact: its id, its two shapes and its manifold.
  - `contactId`: The contact.
  - `out`: Optional. The `B2ContactData` to fill in place, its objects and arrays reused; a new one when omitted.
  - returns: The contact's data.

  The manifold is a copy of the contact's and may have no points when the shapes are not touching. The contact id must be valid.
- `copyWasm`: Copies `box2d.wasm` into a JavaScript build's output directory, from a line in the build's hxml.
  - `directory`: The directory, relative to the build's working directory.
