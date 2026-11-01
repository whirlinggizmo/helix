# helix.geometry

[Back to the index](README.md)

## Camera2D

*class* in [`geometry/src/helix/geometry/Camera2D.hx`](../../geometry/src/helix/geometry/Camera2D.hx), `import helix.geometry.Camera2D;`

Represents a view of a 2D world: where it looks and how it is turned (a `Transform2D`), how near it is, and where in the view the point it looks at shows.

It is steered by its transform as any object is: `transform.moveForward`, `rotate`, `lookAt`. Turning it turns the world the other way in the view. Its transform's scale is ignored; `zoom` sizes what it shows. A view is measured in view units from its top left, y downward: the screen's pixels when it is drawn to the screen. The view matrix and the conversions use `Trig`, so they come out the same on every target, and `worldToView` and `viewToWorld` go through the view matrix, so a point picked is where it was drawn.

raylib's `Camera2D` is one whose position is raylib's target, whose rotation is raylib's in radians and negated (raylib's turns the world, this one turns itself), and whose zoom and offset are raylib's.

```haxe
var camera = new Camera2D();
camera.offset.set(width / 2, height / 2);
camera.transform.position.copyFrom(player.position);
camera.zoom = 2;
var view = camera.computeViewMatrix(viewScratch);
var shown = camera.computeBounds(width, height, boundsScratch);
var pointed = camera.viewToWorld(mouseX, mouseY, pointerScratch);
```

```haxe
function new()
final transform:Transform2D
var zoom:Float
final offset:Vector2D
function copyFrom(other:Camera2D):Camera2D
function computeViewMatrix(?out:Matrix2D):Matrix2D
function worldToView(x:Float, y:Float, ?out:Vector2D):Vector2D
function viewToWorld(x:Float, y:Float, ?out:Vector2D):Null<Vector2D>
function computeBounds(viewWidth:Float, viewHeight:Float, ?out:Bounds2D):Bounds2D
```

- `new`: Creates a camera at the origin, unturned, at zoom 1, its position showing at the view's top left.
- `transform`: Gets where it looks, in world units, and how it is turned, in radians; its scale is ignored.
- `zoom`: Gets or sets how near it is: 1 until set. More than 1 shows less of the world, larger; less than 0 shows it turned half round. At 0 it shows nothing, and a point in the view has no place in the world (`viewToWorld`).
- `offset`: Gets where in the view its position shows, in view units from the view's top left; the top left until changed. Half the view's size centers it.
- `copyFrom`: Sets this camera to another's transform, zoom and offset.
  - `other`: The camera to copy.
  - returns: This camera.
- `computeViewMatrix`: Returns the matrix that puts the world into the view: it moves the position to the origin, turns the world back by the rotation, scales it by the zoom, and moves it to the offset.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The view matrix, from world units to view units.
- `worldToView`: Returns where a point in the world shows in the view.
  - `x`: The point's x, in world units.
  - `y`: The point's y.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The point, in view units.
- `viewToWorld`: Returns where in the world a point in the view is, as a pointer picks.
  - `x`: The point's x, in view units.
  - `y`: The point's y.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The point, in world units; null at zoom 0, where it has none, the out unchanged.
- `computeBounds`: Returns the part of the world in a view of a size, to skip what is outside it before drawing.
  - `viewWidth`: The view's width, in view units.
  - `viewHeight`: The view's height.
  - `out`: Optional. The box to write into; a new one when omitted.
  - returns: The box, in world units; empty at zoom 0, where nothing shows.

  When the camera is turned, the box is the axis-aligned one that holds the turned view, so it holds a little more than is shown.

## Camera3D

*class* in [`geometry/src/helix/geometry/Camera3D.hx`](../../geometry/src/helix/geometry/Camera3D.hx), `import helix.geometry.Camera3D;`

Represents a view of a 3D world: where it is and which way it looks (a `Transform3D`), and how it projects what it sees.

It is steered by its transform as any object is: `transform.moveForward`, `yaw`, `pitch`, `orbit`, `lookAt`. Its scale is ignored, as a scaled view would stretch what it shows. The projection is perspective unless `orthographic` is set. The aspect, width over height, is passed to each call that projects rather than kept, since it changes with the window.

```haxe
var camera = new Camera3D();
camera.transform.position.set(0, 2, 8);
camera.transform.lookAt(0, 0, 0);
var view = camera.computeViewMatrix(viewScratch);
var projection = camera.computeProjectionMatrix(width / height, projectionScratch);
```

```haxe
function new()
final transform:Transform3D
var orthographic:Bool
var fieldOfView:Float
var orthographicHeight:Float
var near:Float
var far:Float
function copyFrom(other:Camera3D):Camera3D
function computeViewMatrix(?out:Matrix3D):Matrix3D
function computeProjectionMatrix(aspect:Float, ?out:Matrix3D):Matrix3D
function computeFrustum(aspect:Float, ?out:Frustum3D):Frustum3D
function project(x:Float, y:Float, z:Float, aspect:Float, ?out:Vector3D):Vector3D
function computeRay(viewX:Float, viewY:Float, aspect:Float, ?out:Ray3D):Ray3D
```

- `new`: Creates a camera at the origin looking down -z.
- `transform`: Gets where it is and which way it looks: down its -z, its +y up.
- `orthographic`: Gets or sets a value indicating whether it projects without perspective, things the same size however far; false until set.
- `fieldOfView`: Gets or sets the field of view, top to bottom, in radians, for a perspective projection; pi / 4 until set.
- `orthographicHeight`: Gets or sets how much it shows top to bottom, in world units, for an orthographic projection; 10 until set.
- `near`: Gets or sets the nearest distance it shows, in world units; 0.1 until set.
- `far`: Gets or sets the farthest distance it shows, in world units; 1000 until set.
- `copyFrom`: Sets this camera to another's transform and projection.
  - `other`: The camera to copy.
  - returns: This camera.
- `computeViewMatrix`: Returns the matrix that puts the world into the camera's space, its transform undone, its scale ignored.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The view matrix.
- `computeProjectionMatrix`: Returns the matrix that projects the camera's space into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.
  - `aspect`: The view's width over its height.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The projection matrix.
- `computeFrustum`: Returns what the camera sees, to test what is in view before drawing it.
  - `aspect`: The view's width over its height.
  - `out`: Optional. The frustum to write into; a new one when omitted.
  - returns: The frustum, in world units.
- `project`: Returns where a point in the world lands in the view, from -1 to 1 across and up, with its depth.
  - `x`: The point's x, in world units.
  - `y`: The point's y.
  - `z`: The point's z.
  - `aspect`: The view's width over its height.
  - `out`: Optional. The vector to write into: x and y from -1 (left, bottom) to 1, z the depth from -1 (near) to 1 (far); a new one when omitted.
  - returns: The point; outside -1 to 1 when it isn't in view.

  A point behind a perspective camera has a depth past 1. One level with its position, which lands nowhere, gives infinities or NaN.
- `computeRay`: Returns the ray from the camera through a point of its view, for picking: from the camera's position for a perspective camera, and from the point on its near plane, along its forward, for an orthographic one.
  - `viewX`: The point's x, -1 at the view's left to 1 at its right.
  - `viewY`: Its y, -1 at the bottom to 1 at the top.
  - `aspect`: The view's width over its height.
  - `out`: Optional. Set to the ray.
  - returns: The ray, its direction of length 1.

## Frustum3D

*class* in [`geometry/src/helix/geometry/Frustum3D.hx`](../../geometry/src/helix/geometry/Frustum3D.hx), `import helix.geometry.Frustum3D;`

Represents what a view sees: six planes bounding a volume, from any view-projection matrix.

It answers whether something is in view, so what isn't can be skipped before it is drawn: a camera's (`Camera3D.computeFrustum`), a light's that casts shadows, or a box dragged out to pick with. Each test errs toward "in view": something near a corner outside it may be counted in, but nothing in it is counted out.

```haxe
camera.computeFrustum(aspect, frustum);
for (thing in things)
if (frustum.intersectsBounds(thing.bounds))
draw(thing);
```

```haxe
function new()
static function fromMatrix(viewProjection:Matrix3D, ?out:Frustum3D):Frustum3D
final planes:Array<Float>
function copyFrom(other:Frustum3D):Frustum3D
function contains(x:Float, y:Float, z:Float):Bool
function intersectsSphere(x:Float, y:Float, z:Float, radius:Float):Bool
function intersectsBounds(bounds:Bounds3D):Bool
```

- `new`: Creates a frustum that holds everything until it is set from a matrix (`fromMatrix`).
- `fromMatrix`: Returns the volume a view-projection matrix shows: what lands inside GL's clip space, -1 to 1 on each axis.
  - `viewProjection`: The view matrix composed with the projection (`Matrix3D.compose(view, projection)`).
  - `out`: Optional. The frustum to fill; a new one when omitted.
  - returns: The frustum.
- `planes`: Gets the planes' 24 numbers: left, right, bottom, top, near and far, each a, b, c and d, where a point (x, y, z) is on the inside when a x + b y + c z + d is 0 or more. Each plane's (a, b, c) is of length 1, so that sum is the distance from it.
- `copyFrom`: Sets this frustum to another's planes.
  - `other`: The frustum to copy.
  - returns: This frustum.
- `contains`: Returns whether a point is inside.
  - `x`: The point's x, in the matrix's world units.
  - `y`: The point's y.
  - `z`: The point's z.
  - returns: True when it is inside or on a plane.
- `intersectsSphere`: Returns whether a sphere is at least partly inside.
  - `x`: The center's x, in the matrix's world units.
  - `y`: The center's y.
  - `z`: The center's z.
  - `radius`: The radius.
  - returns: True when some of it may be inside.
- `intersectsBounds`: Returns whether a box is at least partly inside.
  - `bounds`: The box, in the matrix's world units.
  - returns: True when some of it may be inside.

  An empty box is never inside.

## Geometry2D

*class* in [`geometry/src/helix/geometry/Geometry2D.hx`](../../geometry/src/helix/geometry/Geometry2D.hx), `import helix.geometry.Geometry2D;`

Provides tests on points, segments, triangles, polygons and circles in a plane, their points given as plain numbers.

Lines that are parallel within a ten-millionth (by the cross product of their directions) don't cross.

```haxe
static function intersectSegments(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?out:Vector2D):Bool
static function isPointInTriangle(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Bool
static function isPointInPolygon(x:Float, y:Float, points:Array<Float>):Bool
static function getDistanceToSegment(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float):Float
static function intersectsCircleSegment(cx:Float, cy:Float, radius:Float, ax:Float, ay:Float, bx:Float, by:Float):Bool
```

- `intersectSegments`: Returns whether two segments cross, and where. Parallel segments, overlapping ones too, don't.
  - `ax`: The first segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - `cx`: The second segment's start x.
  - `cy`: Its start y.
  - `dx`: Its end x.
  - `dy`: Its end y.
  - `out`: Optional. Set to where they cross, when they do.
  - returns: True when they cross, their ends included.
- `isPointInTriangle`: Returns whether a point is inside a triangle, its edges not included.
  - `x`: The point's x.
  - `y`: Its y.
  - `ax`: The triangle's first corner's x.
  - `ay`: Its y.
  - `bx`: The second corner's x.
  - `by`: Its y.
  - `cx`: The third corner's x.
  - `cy`: Its y.
  - returns: True when it is inside; false for a triangle with no area.
- `isPointInPolygon`: Returns whether a point is inside a polygon, by how many of its edges a ray from the point crosses. A point on an edge may count either way.
  - `x`: The point's x.
  - `y`: Its y.
  - `points`: The polygon's corners in order, flat: x, y, x, y.
  - returns: True when it is inside; false for fewer than 3 corners.
- `getDistanceToSegment`: Returns how far a point is from the nearest point of a segment.
  - `x`: The point's x.
  - `y`: Its y.
  - `ax`: The segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - returns: The distance.
- `intersectsCircleSegment`: Returns whether a circle and a segment touch.
  - `cx`: The circle's center x.
  - `cy`: Its center y.
  - `radius`: Its radius.
  - `ax`: The segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - returns: True when they touch, the circle's edge included.

## Mesh3D

*class* in [`geometry/src/helix/geometry/Mesh3D.hx`](../../geometry/src/helix/geometry/Mesh3D.hx), `import helix.geometry.Mesh3D;`

Represents a mesh: a surface made of triangles, as arrays a GPU or a file takes: positions, and for each vertex its normal, texture coordinates, tangent and color when it has them; and the indices of each triangle's corners, or none when the vertices are the triangles in order. A triangle's front is the side its corners are counterclockwise from.

The `fromX` functions make the usual shapes, centered on the origin, +y up, a shape about an axis turning about y, and two triangles across each cell of their slices and stacks. Each has normals of length 1 from the shape itself, texture coordinates (u along the slices from 0 to 1, v from the top, 0, to the bottom, 1, as images are stored), indices, and no tangents or colors; the vertices on a seam are doubled, so each side has its own texture coordinates. They use `Trig`, so a shape is the same on every target. Each takes an optional out, last, whose arrays it reuses.

A model read from a file (helix-services' `Model3D`) holds its meshes as these, each with its material's index beside it.

```haxe
function new()
static function fromBox(width:Float, height:Float, depth:Float, ?out:Mesh3D):Mesh3D
static function fromPlane(width:Float, depth:Float, columns:Int, rows:Int, ?out:Mesh3D):Mesh3D
static function fromDisk(radius:Float, slices:Int, ?out:Mesh3D):Mesh3D
static function fromSphere(radius:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D
static function fromHemisphere(radius:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D
static function fromCylinder(bottomRadius:Float, topRadius:Float, height:Float, slices:Int, stacks:Int, capped:Bool, ?out:Mesh3D):Mesh3D
static function fromCapsule(radius:Float, height:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D
static function fromTorus(radius:Float, tubeRadius:Float, slices:Int, sides:Int, ?out:Mesh3D):Mesh3D
static function fromTorusKnot(radius:Float, tubeRadius:Float, slices:Int, sides:Int, p:Int, q:Int, ?out:Mesh3D):Mesh3D
static function merge(first:Mesh3D, second:Mesh3D, ?out:Mesh3D):Mesh3D
var positions:Array<Float>
var normals:Null<Array<Float>>
var texCoords:Null<Array<Float>>
var tangents:Null<Array<Float>>
var colors:Null<Array<Float>>
var indices:Null<Array<Int>>
var vertexCount(get, never):Int
var triangleCount(get, never):Int
function copyFrom(other:Mesh3D):Mesh3D
function transform(matrix:Matrix3D, ?out:Mesh3D):Mesh3D
function toUnindexed(?out:Mesh3D):Mesh3D
function computeNormals(?weldDistance:Float, ?out:Array<Float>):Array<Float>
function computeTangents(?out:Array<Float>):Null<Array<Float>>
function computeBounds(?out:Bounds3D):Bounds3D
```

- `new`: Creates an empty mesh: no positions, nothing else.
- `fromBox`: Returns a box.
  - `width`: Its size along x.
  - `height`: Along y.
  - `depth`: Along z.
  - `out`: Optional. Set to the box.
  - returns: The box: four vertices a face, each face's texture its whole.
- `fromPlane`: Returns a flat rectangle on the XZ plane, facing +y.
  - `width`: Its size along x.
  - `depth`: Along z.
  - `columns`: Cells along x, at least 1.
  - `rows`: Cells along z, at least 1.
  - `out`: Optional. Set to the plane.
  - returns: The plane; its texture's top at -z.
- `fromDisk`: Returns a flat disk on the XZ plane, facing +y; with few slices, a regular polygon.
  - `radius`: Its radius.
  - `slices`: Its sides, at least 3.
  - `out`: Optional. Set to the disk.
  - returns: The disk: a vertex at its center and one at each corner, the texture a circle touching its edges.
- `fromSphere`: Returns a sphere, its poles on y.
  - `radius`: Its radius.
  - `slices`: Around, at least 3.
  - `stacks`: Pole to pole, at least 2.
  - `out`: Optional. Set to the sphere.
  - returns: The sphere.
- `fromHemisphere`: Returns the top half of a sphere, open at its base, its pole at +y and its base on the XZ plane.
  - `radius`: Its radius.
  - `slices`: Around, at least 3.
  - `stacks`: Pole to base, at least 1.
  - `out`: Optional. Set to the hemisphere.
  - returns: The hemisphere.
- `fromCylinder`: Returns a cylinder along y, or a cone or a truncated one when the radii differ.
  - `bottomRadius`: Its base's radius, at -height / 2.
  - `topRadius`: Its top's, at height / 2; 0 makes a cone.
  - `height`: Its height.
  - `slices`: Around, at least 3.
  - `stacks`: Base to top, at least 1.
  - `capped`: Whether its ends are closed, each by a disk; an end of radius 0 has none.
  - `out`: Optional. Set to the cylinder.
  - returns: The cylinder.
- `fromCapsule`: Returns a capsule along y: a cylinder with half a sphere on each end.
  - `radius`: Its radius.
  - `height`: Its height between the two half spheres' centers; its whole height is this and two radii.
  - `slices`: Around, at least 3.
  - `stacks`: In each half sphere, at least 1.
  - `out`: Optional. Set to the capsule.
  - returns: The capsule.
- `fromTorus`: Returns a torus about y, lying on the XZ plane.
  - `radius`: From its center to the middle of its tube.
  - `tubeRadius`: The tube's radius.
  - `slices`: Around the ring, at least 3.
  - `sides`: Around the tube, at least 3.
  - `out`: Optional. Set to the torus.
  - returns: The torus.
- `fromTorusKnot`: Returns a tube wound into a (p, q) torus knot about y: p times about the y axis while q times through the ring; p 2 and q 3 make a trefoil.
  - `radius`: The ring's radius, from its center to the tube's middle at its widest.
  - `tubeRadius`: The tube's radius.
  - `slices`: Along the knot, at least 3.
  - `sides`: Around the tube, at least 3.
  - `p`: Turns about the y axis, at least 1.
  - `q`: Turns through the ring, at least 1.
  - `out`: Optional. Set to the knot.
  - returns: The knot.
- `merge`: Returns two meshes as one: the second's vertices after the first's. What one has and the other lacks (normals, texture coordinates, tangents, colors) is dropped; the result has indices when either has.
  - `first`: One.
  - `second`: The other.
  - `out`: Optional. Set to the two; may be either.
  - returns: The mesh.
- `positions`: Gets or sets the positions, x, y and z each.
- `normals`: Gets or sets the normals, x, y and z a vertex, of length 1; null for none.
- `texCoords`: Gets or sets the texture coordinates, u and v a vertex; null for none.
- `tangents`: Gets or sets the tangents, x, y, z and w a vertex: the way u grows along the surface, square to the normal, w 1 or -1 for the way v grows (the bitangent is the normal crossed with the tangent, times w); null for none.
- `colors`: Gets or sets the colors, red, green, blue and alpha a vertex, 0 to 1; null for none.
- `indices`: Gets or sets the indices, three a triangle; null when the vertices are the triangles in order.
- `vertexCount`: Gets the number of vertices.
- `triangleCount`: Gets the number of triangles.
- `copyFrom`: Copies another mesh into this one, its arrays copied.
  - `other`: The mesh.
  - returns: This mesh.
- `transform`: Returns the mesh moved by a transform: its positions as points, its normals by the transform's inverse transposed, made length 1 again, and its tangents' directions as directions. A transform that turns it inside out (a negative scale on one axis) turns its triangles round, so their fronts stay outside.
  - `matrix`: The transform.
  - `out`: Optional. Set to the moved mesh; may be this one.
  - returns: The moved mesh.
- `toUnindexed`: Returns the mesh without indices: each triangle's three vertices its own, in order. With `computeNormals` after it, a shape whose triangles' normals are each their own, so its faces look flat.
  - `out`: Optional. Set to the result; may be this one.
  - returns: The mesh.
- `computeNormals`: Returns normals from the triangles: each vertex's the sum of the triangles it is a corner of, weighted by their areas, made length 1. Given a weld distance, vertices nearer each other than it share one normal, so a shape with doubled vertices on its seams stays smooth across them.
  - `weldDistance`: Optional. How near vertices share a normal, 0 for those at the very same point. Omitted, none share: a vertex's normal is its own triangles' alone, so a mesh without indices (`toUnindexed`) has a flat normal on each triangle.
  - `out`: Optional. Set to the normals, x, y and z a vertex.
  - returns: The normals; assign them to `normals` to use them.
- `computeTangents`: Returns tangents from the positions, texture coordinates and normals, for normal mapping: for each vertex, the way u grows across the triangles it is a corner of, made square to its normal, and w the way v grows. It reads the triangles by their indices, or the vertices three at a time when there are none.
  - `out`: Optional. Set to the tangents, x, y, z and w a vertex.
  - returns: The tangents, to assign to `tangents`; null for a mesh without texture coordinates or normals.
- `computeBounds`: Returns the bounds of its positions.
  - `out`: Optional. Set to the bounds.
  - returns: The bounds; empty for a mesh without positions.

## Ray3D

*class* in [`geometry/src/helix/geometry/Ray3D.hx`](../../geometry/src/helix/geometry/Ray3D.hx), `import helix.geometry.Ray3D;`

Represents a ray: a point it starts from and a direction it goes in, for picking and line of sight.

A ray meets a plane, a sphere, bounds, a triangle or a mesh at most once: the first point at or after its origin. Starting inside a sphere, bounds or a closed mesh, that is where it leaves. Each test returns where, as a `RayHit3D`, or null when the ray misses, its out unchanged. A hit's distance is how far along the direction it is, in the direction's lengths: with a direction of length 1, in world units. Shapes are given as plain numbers, as `Frustum3D` and `Bounds3D` take them. Given an out, no test allocates.

```haxe
function new()
final origin:Vector3D
final direction:Vector3D
function set(x:Float, y:Float, z:Float, dx:Float, dy:Float, dz:Float):Ray3D
function copyFrom(other:Ray3D):Ray3D
function computePoint(distance:Float, ?out:Vector3D):Vector3D
function transform(matrix:Matrix3D, ?out:Ray3D):Ray3D
function intersectPlane(x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, ?out:RayHit3D):Null<RayHit3D>
function intersectSphere(x:Float, y:Float, z:Float, radius:Float, ?out:RayHit3D):Null<RayHit3D>
function intersectBounds(bounds:Bounds3D, ?out:RayHit3D):Null<RayHit3D>
function intersectTriangle(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float, ?out:RayHit3D):Null<RayHit3D>
function intersectMesh(mesh:Mesh3D, ?transform:Matrix3D, ?out:RayHit3D):Null<RayHit3D>
```

- `new`: Creates a ray from the origin along -z.
- `origin`: Gets the point it starts from.
- `direction`: Gets the way it goes; any length but 0.
- `set`: Sets the origin and the direction.
  - `x`: The origin's x.
  - `y`: Its y.
  - `z`: Its z.
  - `dx`: The direction's x.
  - `dy`: Its y.
  - `dz`: Its z.
  - returns: This ray.
- `copyFrom`: Copies another ray into this one.
  - `other`: The ray.
  - returns: This ray.
- `computePoint`: Returns the point a distance along the ray.
  - `distance`: How far, in the direction's lengths.
  - `out`: Optional. Set to the point.
  - returns: The point.
- `transform`: Returns the ray moved by a transform: its origin as a point, its direction as a direction. A ray put into a mesh's own space with its transform's inverse meets the mesh where the world's ray meets the mesh drawn with the transform.
  - `matrix`: The transform.
  - `out`: Optional. Set to the moved ray; may be this one.
  - returns: The moved ray.
- `intersectPlane`: Returns where the ray meets a plane, from either side. The hit's normal is the plane's, as given.
  - `x`: A point on the plane's x.
  - `y`: Its y.
  - `z`: Its z.
  - `nx`: The plane's normal's x.
  - `ny`: Its y.
  - `nz`: Its z.
  - `out`: Optional. Set to the hit.
  - returns: The hit; null when the ray runs along the plane or away from it.
- `intersectSphere`: Returns where the ray meets a sphere: where it goes in, or from inside, where it comes out. The hit's normal points out of the sphere.
  - `x`: The center's x.
  - `y`: Its y.
  - `z`: Its z.
  - `radius`: The radius.
  - `out`: Optional. Set to the hit.
  - returns: The hit; null when it misses or the sphere is behind it.
- `intersectBounds`: Returns where the ray meets bounds: where it goes in, or from inside, where it comes out. The hit's normal points out of the face it is on.
  - `bounds`: The bounds; empty ones are never met.
  - `out`: Optional. Set to the hit.
  - returns: The hit; null when it misses or the bounds are behind it.
- `intersectTriangle`: Returns where the ray meets a triangle, from either side. The hit's normal is the triangle's front's: the side its corners are counterclockwise from.
  - `ax`: The first corner's x.
  - `ay`: Its y.
  - `az`: Its z.
  - `bx`: The second corner's x.
  - `by`: Its y.
  - `bz`: Its z.
  - `cx`: The third corner's x.
  - `cy`: Its y.
  - `cz`: Its z.
  - `out`: Optional. Set to the hit.
  - returns: The hit; null when it misses, runs along it, or the triangle has no area.
- `intersectMesh`: Returns where the ray first meets a mesh's triangles, from either side, as `intersectTriangle` meets each. With a transform, the hit's point, normal and distance are in the ray's space, the world's, as the other tests' are.
  - `mesh`: The mesh.
  - `transform`: Optional. Where the mesh is: its positions are moved by it. Omitted, they are as they are.
  - `out`: Optional. Set to the hit; its `triangle` says which, counted in the order the indices (or the vertices) give them.
  - returns: The nearest hit; null when it meets none.

## RayHit3D

*class* in [`geometry/src/helix/geometry/RayHit3D.hx`](../../geometry/src/helix/geometry/RayHit3D.hx), `import helix.geometry.RayHit3D;`

Represents where a ray meets something (`Ray3D`'s tests): how far along it, the point, and the surface's normal there.

```haxe
function new()
var distance:Float
final point:Vector3D
final normal:Vector3D
var triangle:Int
function copyFrom(other:RayHit3D):RayHit3D
```

- `new`: Creates a hit at the origin, distance 0.
- `distance`: Gets or sets how far along the ray, in its direction's lengths.
- `point`: Gets the point.
- `normal`: Gets the surface's normal at the point, of length 1.
- `triangle`: Gets or sets which of a mesh's triangles was met (`Ray3D.intersectMesh`), counted from 0; -1 for any other test.
- `copyFrom`: Copies another hit into this one.
  - `other`: The hit.
  - returns: This hit.
