# helix.collision

[Back to the index](README.md)

## Collide2D

*class* in `src/helix/collision/Collide2D.hx`

2D collision tests in floats, the same on every target (sums, products and square roots round alike everywhere; nothing transcendental): overlaps of rectangles (x, y the top-left, width and height), circles and convex polygons (points as flat x, y pairs, in either winding); points inside them; segments and rays against them, with where and the normal (Hit2D); sweeps, a shape moved by dx, dy until it meets another; and a box moved and slid over a grid of solid tiles (Move2D). Touching edges don't overlap. Polygon tests are the separating axis theorem, so a concave polygon is split into convex ones first. A SpatialHash2D narrows which pairs to test.

```haxe
static function rectRect(ax:Float, ay:Float, aw:Float, ah:Float, bx:Float, by:Float, bw:Float, bh:Float):Bool
static function circleCircle(ax:Float, ay:Float, ar:Float, bx:Float, by:Float, br:Float):Bool
static function rectCircle(rx:Float, ry:Float, rw:Float, rh:Float, cx:Float, cy:Float, r:Float):Bool
static function pointInRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
static function pointInCircle(px:Float, py:Float, cx:Float, cy:Float, r:Float):Bool
static function pointInPolygon(px:Float, py:Float, points:Array<Float>):Bool
static function polygonPolygon(a:Array<Float>, b:Array<Float>, ?hit:Hit2D):Bool
static function polygonCircle(points:Array<Float>, cx:Float, cy:Float, r:Float):Bool
static function rectPolygon(rx:Float, ry:Float, rw:Float, rh:Float, points:Array<Float>, ?hit:Hit2D):Bool
static function segmentDistanceSquared(ax:Float, ay:Float, bx:Float, by:Float, px:Float, py:Float):Float
static function segmentSegment(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?hit:Hit2D):Bool
static function rayRect(ox:Float, oy:Float, dx:Float, dy:Float, rx:Float, ry:Float, rw:Float, rh:Float, hit:Hit2D):Bool
static function rayCircle(ox:Float, oy:Float, dx:Float, dy:Float, cx:Float, cy:Float, r:Float, hit:Hit2D):Bool
static function sweepRectRect(ax:Float, ay:Float, aw:Float, ah:Float, dx:Float, dy:Float, bx:Float, by:Float, bw:Float, bh:Float, hit:Hit2D):Bool
static function sweepCircleCircle(ax:Float, ay:Float, ar:Float, dx:Float, dy:Float, bx:Float, by:Float, br:Float, hit:Hit2D):Bool
static function moveAndSlide(x:Float, y:Float, width:Float, height:Float, dx:Float, dy:Float, tileSize:Float, solid:(Int, Int) -> Bool, out:Move2D):Move2D
```

- `rectRect`: Whether two rectangles overlap.
- `circleCircle`: Whether two circles overlap.
- `rectCircle`: Whether a rectangle and a circle overlap.
- `pointInRect`: Whether the point is inside the rectangle (on its left or top edge counts, its right or bottom doesn't).
- `pointInCircle`: Whether the point is inside the circle.
- `pointInPolygon`: Whether the point is inside the polygon (convex or not, by crossings).
- `polygonPolygon`: Whether two convex polygons overlap (the separating axis theorem). With hit, its normal is the way to move a out of b by its depth, the least such move.
- `polygonCircle`: Whether a convex polygon and a circle overlap.
- `rectPolygon`: Whether a rectangle and a convex polygon overlap.
- `segmentDistanceSquared`: The square of the distance from a point to a segment.
- `segmentSegment`: Whether segment a to b crosses segment c to d (not when they only touch or lie along each other); with hit, where along a to b (time) and the point.
- `rayRect`: Whether the ray from ox, oy along dx, dy (its whole length: time 1 is its end) meets the rectangle: into hit the time, point and normal (0, 0 and time 0 from inside).
- `rayCircle`: Whether the ray from ox, oy along dx, dy (time 1 its end) meets the circle: into hit the time, point and normal (time 0 and no normal from inside).
- `sweepRectRect`: Whether rectangle a, moved by dx, dy, meets rectangle b on the way: into hit the time of the meeting, a's top-left then, and the normal (a already overlapping b: time 0, no normal).
- `sweepCircleCircle`: Whether circle a, moved by dx, dy, meets circle b on the way: into hit the time, a's center then, and the normal.
- `moveAndSlide`: Moves the box at x, y (its top-left), width by height, by dx, dy over a grid of tiles of tileSize, each solid or not by solid(column, row), sliding along what it meets: first across, stopped at a solid tile's side, then down or up the same; into out the place it ended and which sides met a solid. A box starting inside a solid tile is left where it is on that axis.

## Hit2D

*class* in `src/helix/collision/Hit2D.hx`

What a 2D test found (Collide2D): where along a ray or a sweep (time, 0 at its start to 1 at its end), the point there, the surface's normal (a unit vector out of what was hit; 0, 0 when the test started inside), and how deep an overlap goes along that normal. One is kept and filled again, not made a test.

```haxe
function new()
var time:Float
var x:Float
var y:Float
var normalX:Float
var normalY:Float
var depth:Float
function reset():Void
```

- `new`: Nothing found yet.
- `time`: How far along the ray or sweep, 0 to 1.
- `x`: The hit's x.
- `y`: The hit's y.
- `normalX`: The normal's x, out of what was hit.
- `normalY`: The normal's y.
- `depth`: How deep an overlap goes along the normal (the least move apart); 0 for a ray or sweep that stops short.
- `reset`: Clears it.

## Move2D

*class* in `src/helix/collision/Move2D.hx`

Where a move-and-slide ended (Collide2D.moveAndSlide): the box's new place, and which of its sides met a solid on the way, so a game knows it stands on the ground (bottom), hit a wall (left, right) or its head (top). One is kept and filled again.

```haxe
function new()
var x:Float
var y:Float
var left:Bool
var right:Bool
var top:Bool
var bottom:Bool
```

- `new`: Nothing moved yet.
- `x`: The box's left edge after the move.
- `y`: The box's top edge after the move.
- `left`: Whether its left side met a solid.
- `right`: Whether its right side met a solid.
- `top`: Whether its top met a solid.
- `bottom`: Whether its bottom met a solid: it stands on something.

## SpatialHash2D<T>

*class* in `src/helix/collision/SpatialHash2D.hx`

Which things might touch, before asking which do: items kept by their rectangle in cells of one size, and a rectangle's query giving the items in the cells it covers (each once), so a game tests a few pairs with Collide2D instead of every pair. Cells are about the size of a common item; a moved item is updated with its new rectangle.

```haxe
function new(cellSize:Float)
function getCellSize():Float
function getCount():Int
function insert(item:T, x:Float, y:Float, width:Float, height:Float):Void
function update(item:T, x:Float, y:Float, width:Float, height:Float):Void
function remove(item:T):Bool
function clear():Void
function query(x:Float, y:Float, width:Float, height:Float, out:Array<T>):Array<T>
```

- `new`: Cells cellSize across and down. Throws for a size of 0 or less.
- `getCellSize`: Its cell size.
- `getCount`: How many items it holds.
- `insert`: Puts item in by its rectangle (an item already in is moved).
- `update`: Moves item to its new rectangle: insert again.
- `remove`: Takes item out; false when it wasn't in.
- `clear`: Takes everything out.
- `query`: The items in the cells the rectangle covers, each once, into out (emptied first), which it returns: what might overlap it.
