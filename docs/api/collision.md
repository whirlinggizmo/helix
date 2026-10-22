# helix.collision

[Back to the index](README.md)

## Body2D

*class* in `src/helix/collision/Body2D.hx`

An arcade body: a box moved by its velocity and gravity over a grid of solid tiles, sliding along what it meets (Collide2D.moveAndSlide), its velocity stopped against it, and what it touches kept: the ground under it, a wall either side, a ceiling. A platformer's player or enemy, a top-down character with no gravity. step runs it: in a Ticker's fixed step (helix.time), so it moves the same at any frame rate. Bodies don't push each other; Collide2D's overlaps meet them.

```haxe
function new(x:Float, y:Float, width:Float, height:Float)
var x:Float
var y:Float
var previousX(default, null):Float
var previousY(default, null):Float
function getDrawnX(fraction:Float):Float
function getDrawnY(fraction:Float):Float
var width:Float
var height:Float
var centerX(get, never):Float
var centerY(get, never):Float
var bottom(get, never):Float
var velocityX:Float
var velocityY:Float
var gravity:Float
var maxFallSpeed(default, set):Float
var grounded(default, null):Bool
var blockedLeft(default, null):Bool
var blockedRight(default, null):Bool
var blockedAbove(default, null):Bool
var airTime(default, null):Float
function place(x:Float, y:Float):Void
function step(dt:Float, tileSize:Float, solid:(Int, Int) -> Bool):Void
```

- `new`: A width x height box with its top-left at x, y (world units), still, with no gravity.
- `x`: Its left edge, in world units.
- `y`: Its top edge, in world units.
- `previousX`: Its left edge before its last step, in world units: drawn between the two (getDrawnX).
- `previousY`: Its top edge before its last step, in world units.
- `getDrawnX`: Its left edge as drawn fraction of the way from before its last step to now (a Ticker's fraction): where a frame between ticks draws it, and where a camera following it looks.
- `getDrawnY`: Its top edge as drawn fraction of the way from before its last step to now.
- `width`: Its width, in world units.
- `height`: Its height, in world units.
- `centerX`: Its center across, in world units.
- `centerY`: Its center down, in world units.
- `bottom`: Its bottom edge, where it stands, in world units.
- `velocityX`: Its speed across, world units a second, + right.
- `velocityY`: Its speed down, world units a second, + down.
- `gravity`: Its acceleration down, world units a second each second (0, the start: none, top-down).
- `maxFallSpeed`: The fastest it falls, world units a second, at least 0.
- `grounded`: Whether it stood on a solid at its last step.
- `blockedLeft`: Whether a solid stopped its left side at its last step.
- `blockedRight`: Whether a solid stopped its right side at its last step.
- `blockedAbove`: Whether a solid stopped its top at its last step: it hit its head.
- `airTime`: Seconds since it was last grounded, 0 while it is: a jump a moment after walking off a ledge (coyote time) asks whether this is short.
- `place`: Puts its top-left at x, y at once (a respawn: drawn there, not moved there), still, touching nothing until its next step.
- `step`: Runs it dt seconds over a grid of tiles of tileSize, each solid or not by solid(column, row): gravity speeds its fall (held to maxFallSpeed), it moves by its velocity, across then down, sliding along what it meets, and a side that meets a solid stops its velocity that way. A body standing still on the ground stays grounded: gravity presses it down each step.

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
var cellSize(default, null):Float
var count(default, null):Int
function insert(item:T, x:Float, y:Float, width:Float, height:Float):Void
function update(item:T, x:Float, y:Float, width:Float, height:Float):Void
function remove(item:T):Bool
function clear():Void
function query(x:Float, y:Float, width:Float, height:Float, out:Array<T>):Array<T>
```

- `new`: Cells cellSize across and down. Throws for a size of 0 or less.
- `cellSize`: Its cell size.
- `count`: How many items it holds.
- `insert`: Puts item in by its rectangle (an item already in is moved).
- `update`: Moves item to its new rectangle: insert again.
- `remove`: Takes item out; false when it wasn't in.
- `clear`: Takes everything out.
- `query`: The items in the cells the rectangle covers, each once, into out (emptied first), which it returns: what might overlap it.
