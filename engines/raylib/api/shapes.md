# rshapes: 2D shapes and collisions

[Back to the library](README.md)


```haxe
static function SetShapesTexture(texture:Texture2D, source:Rectangle):Void
static function GetShapesTexture():Texture2D
static function GetShapesTextureRectangle():Rectangle
static function DrawPixel(posX:Int, posY:Int, color:Color):Void
static function DrawPixelV(position:Vector2, color:Color):Void
static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void
static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawLineStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawLineBezier(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void
static function DrawCircleSector(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawCircleSectorLines(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawCircleGradient(centerX:Int, centerY:Int, radius:Float, inner:Color, outer:Color):Void
static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void
static function DrawEllipse(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void
static function DrawEllipseLines(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void
static function DrawRing(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawRingLines(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void
static function DrawRectangleRec(rec:Rectangle, color:Color):Void
static function DrawRectanglePro(rec:Rectangle, origin:Vector2, rotation:Float, color:Color):Void
static function DrawRectangleGradientV(posX:Int, posY:Int, width:Int, height:Int, top:Color, bottom:Color):Void
static function DrawRectangleGradientH(posX:Int, posY:Int, width:Int, height:Int, left:Color, right:Color):Void
static function DrawRectangleGradientEx(rec:Rectangle, topLeft:Color, bottomLeft:Color, topRight:Color, bottomRight:Color):Void
static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void
static function DrawRectangleRounded(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void
static function DrawRectangleRoundedLines(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void
static function DrawRectangleRoundedLinesEx(rec:Rectangle, roundness:Float, segments:Int, lineThick:Float, color:Color):Void
static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function DrawTriangleLines(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function DrawTriangleFan(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawTriangleStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawPoly(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void
static function DrawPolyLines(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void
static function DrawPolyLinesEx(center:Vector2, sides:Int, radius:Float, rotation:Float, lineThick:Float, color:Color):Void
static function DrawSplineLinear(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBasis(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineCatmullRom(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBezierQuadratic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBezierCubic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineSegmentLinear(p1:Vector2, p2:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBezierQuadratic(p1:Vector2, c2:Vector2, p3:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function GetSplinePointLinear(startPos:Vector2, endPos:Vector2, t:Float):Vector2
static function GetSplinePointBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2
static function GetSplinePointCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2
static function GetSplinePointBezierQuad(p1:Vector2, c2:Vector2, p3:Vector2, t:Float):Vector2
static function GetSplinePointBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, t:Float):Vector2
static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool
static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool
static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool
static function CheckCollisionCircleLine(center:Vector2, radius:Float, p1:Vector2, p2:Vector2):Bool
static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool
static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool
static function CheckCollisionPointTriangle(point:Vector2, p1:Vector2, p2:Vector2, p3:Vector2):Bool
static function CheckCollisionPointLine(point:Vector2, p1:Vector2, p2:Vector2, threshold:Int):Bool
static function CheckCollisionPointPoly(point:Vector2, points:Array<Vector2>, pointCount:Int):Bool
static function CheckCollisionLines(startPos1:Vector2, endPos1:Vector2, startPos2:Vector2, endPos2:Vector2, collisionPoint:Vector2):Bool
static function GetCollisionRec(rec1:Rectangle, rec2:Rectangle):Rectangle
```

- `SetShapesTexture`: Sets the texture, and the rectangle of it, that the filled shapes sample.
  - `texture`: The texture.
  - `source`: The part of it, in pixels.

  Pointing it at a white pixel in a font's texture lets shapes and text share one draw.

  A texture with no id, or an empty rectangle, restores the default white pixel.
- `GetShapesTexture`: Returns the filled shapes' texture, raylib's default white pixel unless `SetShapesTexture` set another.
  - returns: The texture.
- `GetShapesTextureRectangle`: Returns the rectangle of the shapes texture that the filled shapes sample.
  - returns: The rectangle, in pixels.
- `DrawPixel`: Draws one pixel.
  - `posX`: The x.
  - `posY`: The y.
  - `color`: The color.
- `DrawPixelV`: Draws one pixel.
  - `position`: The position.
  - `color`: The color.
- `DrawLine`: Draws a line one pixel wide. See `DrawLineEx` for drawing a line of a thickness.
  - `startPosX`: The start's x.
  - `startPosY`: The start's y.
  - `endPosX`: The end's x.
  - `endPosY`: The end's y.
  - `color`: The color.
- `DrawLineV`: Draws a line one pixel wide. See `DrawLineEx` for drawing a line of a thickness.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawLineEx`: Draws a line of a thickness.
  - `startPos`: The start.
  - `endPos`: The end.
  - `thick`: The thickness, in pixels; 0 or less draws nothing.
  - `color`: The color.
- `DrawLineStrip`: Draws lines one pixel wide from each point to the next. See `DrawSplineLinear` for drawing them of a thickness.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 2 or more.
  - `color`: The color.
- `DrawLineBezier`: Draws a line of a thickness that eases in and out from start to end, as an S.
  - `startPos`: The start.
  - `endPos`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawCircle`: Draws a filled circle.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius; 0 or less draws nothing.
  - `color`: The color.
- `DrawCircleV`: Draws a filled circle.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `color`: The color.
- `DrawCircleSector`: Draws a filled slice of a circle, clockwise from one angle to another.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawCircleSectorLines`: Draws a slice of a circle's outline, one pixel wide, with lines from the center to its ends.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.

  A whole turn draws no lines from the center.
- `DrawCircleGradient`: Draws a filled circle that blends from one color at its center to another at its edge.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `inner`: The color at the center.
  - `outer`: The color at the edge.
- `DrawCircleLines`: Draws a circle's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLinesV`: Draws a circle's outline, one pixel wide.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawEllipse`: Draws a filled ellipse.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radiusH`: The radius across.
  - `radiusV`: The radius up and down.
  - `color`: The color.
- `DrawEllipseLines`: Draws an ellipse's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radiusH`: The radius across.
  - `radiusV`: The radius up and down.
  - `color`: The color.
- `DrawRing`: Draws a filled ring, or a slice of one, clockwise from one angle to another.
  - `center`: The center.
  - `innerRadius`: The radius of its hole; 0 or less draws a slice of a circle.
  - `outerRadius`: The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawRingLines`: Draws a ring's outline, or a slice of one, one pixel wide, with lines across its ends.
  - `center`: The center.
  - `innerRadius`: The radius of its hole; 0 or less draws a slice of a circle.
  - `outerRadius`: The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.

  A whole turn draws no lines across the ends.
- `DrawRectangle`: Draws a filled rectangle.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `DrawRectangleV`: Draws a filled rectangle.
  - `position`: The top-left corner.
  - `size`: The width and height.
  - `color`: The color.
- `DrawRectangleRec`: Draws a filled rectangle.
  - `rec`: The rectangle.
  - `color`: The color.
- `DrawRectanglePro`: Draws a filled rectangle turned about a point of it.
  - `rec`: The rectangle; its x and y are where the point is drawn.
  - `origin`: The point it turns about, from its top-left corner.
  - `rotation`: The turn, in degrees clockwise.
  - `color`: The color.
- `DrawRectangleGradientV`: Draws a filled rectangle that blends from one color at its top to another at its bottom.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `top`: The color at the top.
  - `bottom`: The color at the bottom.
- `DrawRectangleGradientH`: Draws a filled rectangle that blends from one color at its left to another at its right.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `left`: The color at the left.
  - `right`: The color at the right.
- `DrawRectangleGradientEx`: Draws a filled rectangle that blends between a color at each corner.
  - `rec`: The rectangle.
  - `topLeft`: The top-left corner's color.
  - `bottomLeft`: The bottom-left corner's color.
  - `topRight`: The bottom-right corner's color.
  - `bottomRight`: The top-right corner's color.

  `topRight` colors the bottom-right corner and `bottomRight` the top-right one, as in raylib 5.5.
- `DrawRectangleLines`: Draws a rectangle's outline, one pixel wide, its lines through the centers of its edge pixels. See `DrawRectangleLinesEx` for drawing an outline of a thickness.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.

  The lines sit half a pixel inside the edges, scaled by the matrix `rlPushMatrix` and its kin set (`rlGetMatrixTransform`).

  A 2D camera's zoom isn't in that matrix, so under a camera the lines sit half a unit inside the edges.
- `DrawRectangleLinesEx`: Draws a rectangle's outline of a thickness, inside it, or outside it for a negative thickness.
  - `rec`: The rectangle.
  - `lineThick`: The lines' thickness; more than half the rectangle's width or height is half its shorter side, and 0 or less draws the outline that thick outside the rectangle (bars of no width, for 0).
  - `color`: The color.
- `DrawRectangleRounded`: Draws a filled rectangle with rounded corners.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLines`: Draws a rounded rectangle's outline, one pixel wide, its lines through the centers of its edge pixels. See `DrawRectangleRoundedLinesEx` for drawing an outline of a thickness.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 or less for square (`DrawRectangleLines`, the rectangle cut to whole pixels), 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLinesEx`: Draws a rounded rectangle's outline, its lines outside it.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
  - `lineThick`: The lines' thickness; 1 or less draws them one pixel wide.
  - `color`: The color.
- `DrawTriangle`: Draws a filled triangle.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.

  The points must go counterclockwise on the screen, as raylib's must.

  While back faces are culled (`rlEnableBackfaceCulling`, the default), points that go clockwise face away and draw nothing.
- `DrawTriangleLines`: Draws a triangle's outline, one pixel wide.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
- `DrawTriangleFan`: Draws filled triangles that all share the first point, each from it to the next two points.
  - `points`: The points, the shared one first.
  - `pointCount`: How many of them to draw, 3 or more.
  - `color`: The color.

  The points after the first must go counterclockwise on the screen, as `DrawTriangle`'s must.
- `DrawTriangleStrip`: Draws filled triangles, each from a point to the two before it.
  - `points`: The points.
  - `pointCount`: How many of them to draw, 3 or more.
  - `color`: The color.
- `DrawPoly`: Draws a filled regular polygon.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `color`: The color.
- `DrawPolyLines`: Draws a regular polygon's outline, one pixel wide. See `DrawPolyLinesEx` for drawing an outline of a thickness.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `color`: The color.
- `DrawPolyLinesEx`: Draws a regular polygon's outline of a thickness, inside it, or outside it for a negative thickness.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `lineThick`: The lines' thickness, measured across each side; past the center it fills the polygon, and a negative thickness draws the outline that thick outside it.
  - `color`: The color.
- `DrawSplineLinear`: Draws straight lines of a thickness from each point to the next.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 2 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBasis`: Draws a B-spline of a thickness with round ends, passing near the points rather than through them.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineCatmullRom`: Draws a Catmull-Rom spline of a thickness with round ends, through every point but the first and last, which only steer it.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBezierQuadratic`: Draws quadratic Bezier curves of a thickness, one after another: points, then a control point between each two.
  - `points`: The points: start, control, end, then a control and an end for each further curve.
  - `pointCount`: How many of them to draw through, 3 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBezierCubic`: Draws cubic Bezier curves of a thickness, one after another: points, then two control points between each two.
  - `points`: The points: start, two controls, end, then two controls and an end for each further curve.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentLinear`: Draws a straight line of a thickness.
  - `p1`: The start.
  - `p2`: The end.
  - `thick`: The thickness, in pixels; 0 or less draws nothing.
  - `color`: The color.
- `DrawSplineSegmentBasis`: Draws one piece of a B-spline of a thickness, between the middle two of four points.
  - `p1`: The first point.
  - `p2`: The second.
  - `p3`: The third.
  - `p4`: The fourth.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentCatmullRom`: Draws one piece of a Catmull-Rom spline of a thickness, through the middle two of four points.
  - `p1`: The first point, which steers it.
  - `p2`: The start.
  - `p3`: The end.
  - `p4`: The fourth point, which steers it.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentBezierQuadratic`: Draws a quadratic Bezier curve of a thickness.
  - `p1`: The start.
  - `c2`: The control point.
  - `p3`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentBezierCubic`: Draws a cubic Bezier curve of a thickness.
  - `p1`: The start.
  - `c2`: The start's control point.
  - `c3`: The end's control point.
  - `p4`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `GetSplinePointLinear`: Returns a point on a straight line.
  - `startPos`: The start.
  - `endPos`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBasis`: Returns a point on one piece of a B-spline, between the middle two of four points.
  - `p1`: The first point.
  - `p2`: The second.
  - `p3`: The third.
  - `p4`: The fourth.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointCatmullRom`: Returns a point on one piece of a Catmull-Rom spline, through the middle two of four points.
  - `p1`: The first point, which steers it.
  - `p2`: The start.
  - `p3`: The end.
  - `p4`: The fourth point, which steers it.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBezierQuad`: Returns a point on a quadratic Bezier curve.
  - `p1`: The start.
  - `c2`: The control point.
  - `p3`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBezierCubic`: Returns a point on a cubic Bezier curve.
  - `p1`: The start.
  - `c2`: The start's control point.
  - `c3`: The end's control point.
  - `p4`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `CheckCollisionRecs`: Returns whether two rectangles overlap. See `GetCollisionRec` for finding where they overlap.
  - `rec1`: One rectangle.
  - `rec2`: The other.
  - returns: True when they overlap.
- `CheckCollisionCircles`: Returns whether two circles overlap.
  - `center1`: One circle's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionCircleRec`: Returns whether a circle and a rectangle overlap.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - `rec`: The rectangle.
  - returns: True when they overlap.
- `CheckCollisionCircleLine`: Returns whether a circle and a line between two points touch.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - `p1`: The line's start.
  - `p2`: Its end.
  - returns: True when they touch.
- `CheckCollisionPointRec`: Returns whether a point is inside a rectangle.
  - `point`: The point.
  - `rec`: The rectangle.
  - returns: True when it is inside.
- `CheckCollisionPointCircle`: Returns whether a point is inside a circle.
  - `point`: The point.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - returns: True when it is inside.
- `CheckCollisionPointTriangle`: Returns whether a point is inside a triangle.
  - `point`: The point.
  - `p1`: The triangle's first point.
  - `p2`: Its second.
  - `p3`: Its third.
  - returns: True when it is inside.

  A point on an edge is outside.
- `CheckCollisionPointLine`: Returns whether a point is on a line between two points, within a margin.
  - `point`: The point.
  - `p1`: The line's start.
  - `p2`: Its end.
  - `threshold`: How far from the line the point may be, in pixels.
  - returns: True when it is on it.
- `CheckCollisionPointPoly`: Returns whether a point is inside a polygon.
  - `point`: The point.
  - `points`: The polygon's corners, in order.
  - `pointCount`: How many of them it has, 3 or more.
  - returns: True when it is inside.
- `CheckCollisionLines`: Returns whether two lines, each between two points, cross, and where.
  - `startPos1`: One line's start.
  - `endPos1`: Its end.
  - `startPos2`: The other's start.
  - `endPos2`: Its end.
  - `collisionPoint`: Set to where they cross, when they do; null leaves it out.
  - returns: True when they cross.
- `GetCollisionRec`: Returns where two rectangles overlap.
  - `rec1`: One rectangle.
  - `rec2`: The other.
  - returns: The overlap, or an empty rectangle at 0, 0 when they don't.
