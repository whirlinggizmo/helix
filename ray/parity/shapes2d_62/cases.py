"""shapes2d_62: the 2D shapes helix-ray takes from raylib 6.2 (docs/DECISIONS.md 24), read back from rlgl's batch, against helix-ray's
frame: those 6.2 fixed (the sectors, rings, rectangle and polygon outlines, rounded rectangles, the triangle, the line test), those calling
them (the circles, the B-spline's and Catmull-Rom's round ends), and 6.2's own (dashed lines, thick outlines, the V ellipses). One list
for both sides (shared/gen.py's syntax): c, c2, c3 and c4 are colors, tex a 32 x 16 white texture, cam a Camera2D and cp
CheckCollisionLines' out point, all made in ref.c.in and ShapeBits.hx.in. A case named for a bug is built from the input that shows it."""

CASES = [
    ('circle', 'DrawCircle(340, 30, 20, c);'),
    ('circlev', 'DrawCircleV(V2(390.5, 30), 15, c);'),
    ('circlezero', 'DrawCircleV(V2(10, 10), 0, c);'),
    ('circlebig', 'DrawCircleV(V2(400, 300), 250, c);'),
    ('sector', 'DrawCircleSector(V2(440, 30), 20, 0, 270, 12, c);'),
    ('sectorswap', 'DrawCircleSector(V2(490, 30), 20, 300, 30, 8, c);'),
    ('sectorzero', 'DrawCircleSector(V2(490, 30), 20, -45, 45, 3, c);'),
    ('sector360', 'DrawCircleSector(V2(490, 30), 20, 350, 370, 5, c);'),
    ('sectorauto', 'DrawCircleSector(V2(100, 100), 30, 0, 360, 0, c);'),
    ('sectorauto2', 'DrawCircleSector(V2(100, 100), 7.5, 10, 100, 1, c);'),
    ('sectorodd', 'DrawCircleSector(V2(100, 100), 12, 0, 90, 5, c);'),
    ('sectortiny', 'DrawCircleSector(V2(100, 100), 0.3, 0, 180, 0, c);'),
    # #6045: the segments picked rounded up, 6 for a quarter of radius 50 where 5.5 gave 5.
    ('sectorquarter', 'DrawCircleSector(V2(100, 100), 50, 0, 90, 0, c);'),
    # #4843: a radius of 0 or less draws nothing, where 5.5 drew one of 0.1.
    ('sectornegative', 'DrawCircleSector(V2(100, 100), -5, 0, 90, 4, c); DrawCircleSector(V2(100, 100), 0, 0, 90, 0, c);'),
    # More than a turn is one turn.
    ('sectorover', 'DrawCircleSector(V2(100, 100), 20, 0, 400, 0, c);'),
    ('sectorlines', 'DrawCircleSectorLines(V2(540, 30), 20, 45, 200, 10, c);'),
    ('sectorlinesauto', 'DrawCircleSectorLines(V2(540, 30), 20, 200, 45, 0, c);'),
    ('sectorlineszero', 'DrawCircleSectorLines(V2(540, 30), 20, -30, 30, 3, c);'),
    # A whole turn has no lines from the center.
    ('sectorlinesturn', 'DrawCircleSectorLines(V2(540, 30), 20, 10, 370, 12, c);'),
    ('sectorlinesnegative', 'DrawCircleSectorLines(V2(540, 30), -20, 0, 90, 4, c); DrawCircleSectorLines(V2(540, 30), 20, 30, 30, 4, c);'),
    ('ring', 'DrawRing(V2(180, 90), 10, 25, 0, 360, 24, c);'),
    ('ringswap', 'DrawRing(V2(240, 90), 10, 25, 200, 20, 12, c);'),
    ('ringreversed', 'DrawRing(V2(240, 90), 25, 10, 30, 300, 0, c);'),
    ('ringzero', 'DrawRing(V2(240, 90), 10, 25, -60, 60, 2, c);'),
    ('ringsector', 'DrawRing(V2(240, 90), 0, 25, 0, 180, 6, c);'),
    ('ringsame', 'DrawRing(V2(240, 90), 10, 25, 40, 40, 6, c);'),
    ('ringnegative', 'DrawRing(V2(240, 90), -5, -10, 0, 90, 4, c);'),
    # An edge of 0 or less draws nothing, whichever radius is the larger; 5.5 checked it only after a swap.
    ('ringnegativeouter', 'DrawRing(V2(240, 90), -10, -5, 0, 90, 4, c);'),
    ('ringover', 'DrawRing(V2(240, 90), 10, 25, 0, 720, 0, c);'),
    ('ringlines', 'DrawRingLines(V2(300, 90), 10, 25, 30, 300, 12, c);'),
    ('ringlinesauto', 'DrawRingLines(V2(300, 90), 25, 10, 300, 30, 0, c);'),
    ('ringlinessector', 'DrawRingLines(V2(300, 90), 0, 25, -90, 90, 5, c);'),
    ('ringlinesturn', 'DrawRingLines(V2(300, 90), 10, 25, 0, 360, 12, c);'),
    ('ringlinesnegative', 'DrawRingLines(V2(300, 90), -10, -5, 0, 90, 4, c);'),
    # #4669: the outline through its edge pixels' centers, half a pixel inside, where 5.5 ran along the edges past each corner.
    ('rectlines', 'DrawRectangleLines(680, 70, 40, 40, c);'),
    ('rectlinesex', 'DrawRectangleLinesEx(R(730, 70, 50, 40), 5, c);'),
    ('rectlinesexthick', 'DrawRectangleLinesEx(R(10, 10, 10, 6), 8, c); DrawRectangleLinesEx(R(10, 10, 6, 10), 8, c);'),
    # #6027: a thickness between half the height and the height, which 5.5 left to overlap.
    ('rectlinesexhalf', 'DrawRectangleLinesEx(R(10, 10, 20, 10), 7, c);'),
    # #6035: a negative thickness draws outside; 0 draws bars of no width there.
    ('rectlinesexzero', 'DrawRectangleLinesEx(R(10, 10, 20, 10), 0, c);'),
    ('rectlinesexnegative', 'DrawRectangleLinesEx(R(10, 10, 20, 10), -3, c);'),
    ('rounded', 'DrawRectangleRounded(R(10, 130, 80, 50), 0.4, 6, c);'),
    ('rounded0', 'DrawRectangleRounded(R(10, 130, 80, 50), 0, 6, c);'),
    ('rounded1', 'DrawRectangleRounded(R(10, 130, 80, 50), 1, 0, c);'),
    ('rounded2', 'DrawRectangleRounded(R(10, 130, 50, 80), 2, 5, c);'),
    # #4683: a rectangle under a pixel wide is rounded too, where 5.5 drew it square.
    ('roundedthin', 'DrawRectangleRounded(R(10, 130, 0.5, 80), 0.5, 5, c);'),
    # #6159: 1 to 3 segments are drawn as asked, where 5.5 picked its own.
    ('roundedfew', 'DrawRectangleRounded(R(10, 130, 80, 50), 0.6, 2, c);'),
    ('roundedlines', 'DrawRectangleRoundedLines(R(100, 130, 80, 50), 0.4, 6, c);'),
    ('roundedlinesauto', 'DrawRectangleRoundedLines(R(100, 130, 80, 50), 1, 0, c);'),
    ('roundedlines0', 'DrawRectangleRoundedLines(R(100.7, 130.2, 80.5, 50.9), 0, 6, c);'),
    ('roundedlinesfew', 'DrawRectangleRoundedLines(R(100, 130, 80, 50), 0.5, 3, c);'),
    ('triangle', 'DrawTriangle(V2(300, 130), V2(290, 180), V2(340, 180), c);'),
    ('trianglecw', 'DrawTriangle(V2(350, 130), V2(400, 180), V2(350, 180), c);'),
    ('trianglegradient', 'DrawTriangleGradient(V2(300, 130), V2(290, 180), V2(340, 180), c, c2, c3);'),
    ('trianglelinesex', 'DrawTriangleLinesEx(V2(300, 130), V2(290, 180), V2(340, 180), 4, c);'),
    ('trianglelinesexnegative', 'DrawTriangleLinesEx(V2(300, 130), V2(290, 180), V2(340, 180), -3, c);'),
    ('trianglelinesexfilled', 'DrawTriangleLinesEx(V2(300, 130), V2(290, 180), V2(340, 180), 50, c);'),
    # #6004: the thickness across the sides, where 5.5's turned its angle into radians twice and measured it from the corners.
    ('polylinesex', 'DrawPolyLinesEx(V2(720, 155), 7, 25, 10, 4, c);'),
    ('polylinesexthick', 'DrawPolyLinesEx(V2(720, 155), 3, 25, 200, 30, c);'),
    ('polylinesexnegative', 'DrawPolyLinesEx(V2(720, 155), 6, 25, 0, -4, c);'),
    ('splinebasis', 'DrawSplineBasis(PTS(V2(220, 220), V2(270, 260), V2(320, 210), V2(370, 270), V2(410, 220)), 5, 3, c);'),
    ('splinecatmullrom', 'DrawSplineCatmullRom(PTS(V2(430, 220), V2(480, 260), V2(530, 210), V2(580, 270), V2(620, 220)), 5, 3, c);'),
    ('splinebasisshort', 'DrawSplineBasis(PTS(V2(1, 2), V2(3, 4), V2(5, 6)), 3, 3, c);'),
    # 0 thick: the round ends have no radius and draw nothing.
    ('splinebasisflat', 'DrawSplineBasis(PTS(V2(220, 220), V2(270, 260), V2(320, 210), V2(370, 270)), 4, 0, c);'),
    # 6.2's own.
    ('dashed', 'DrawLineDashed(V2(10, 10), V2(200, 73), 9, 4, c);'),
    ('dashedshort', 'DrawLineDashed(V2(10, 10), V2(15, 12), 9, 4, c);'),
    ('dashednone', 'DrawLineDashed(V2(10, 10), V2(200, 73), 0, 4, c);'),
    ('dashedlast', 'DrawLineDashed(V2(200, 73), V2(10, 10.5), 7, 7, c);'),
    ('circlelinesex', 'DrawCircleLinesEx(V2(100, 100), 30, 5, c);'),
    ('circlelinesexnegative', 'DrawCircleLinesEx(V2(100, 100), 30, -4, c);'),
    ('circlelinesexfilled', 'DrawCircleLinesEx(V2(100, 100), 30, 40, c);'),
    ('sectorlinesex', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 90, 0, 6, c);'),
    ('sectorlinesexwide', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 270, 12, 6, c);'),
    ('sectorlinesexhalf', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 20, 200, 9, 4, c);'),
    ('sectorlinesexturn', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 360, 24, 5, c);'),
    ('sectorlinesexturnout', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 360, 24, -5, c);'),
    ('sectorlinesexout', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 30, 120, 8, -6, c);'),
    ('sectorlinesexoutwide', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 300, 10, -8, c);'),
    ('sectorlinesexfine', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 90, 30, 6, c);'),
    ('sectorlinesexfiner', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 90, 36, 6, c);'),
    ('sectorlinesexturnodd', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 360, 15, 5, c);'),
    ('sectorlinesexout2', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 350, 35, -8, c);'),
    ('sectorlinesexout3', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 300, 6, -12, c);'),
    ('sectorlinesexout4', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 200, 4, -15, c);'),
    ('sectorlinesexout5', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 120, 2, -15, c);'),
    ('sectorlinesexout6', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 330, 4, -20, c);'),
    ('sectorlinesexfilled', 'DrawCircleSectorLinesEx(V2(100, 100), 40, 0, 40, 4, 30, c);'),
    ('sectorlinesexnone', 'DrawCircleSectorLinesEx(V2(100, 100), 0, 0, 40, 4, 3, c); DrawCircleSectorLinesEx(V2(100, 100), 40, 10, 10, 4, 3, c);'),
    ('ellipsev', 'DrawEllipseV(V2(40.5, 90), 30, 15, c);'),
    ('ellipselinesv', 'DrawEllipseLinesV(V2(110, 90.25), 30, 15, c);'),
    ('ellipselinesex', 'DrawEllipseLinesEx(V2(110, 90), 30, 15, 4, c);'),
    ('ellipselinesexnegative', 'DrawEllipseLinesEx(V2(110, 90), 30, 15, -3, c);'),
    ('ellipselinesexfilled', 'DrawEllipseLinesEx(V2(110, 90), 30, 15, 15, c);'),
    ('ringlinesex', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 270, 0, 3, c);'),
    ('ringlinesexturn', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 360, 24, 3, c);'),
    ('ringlinesexturnout', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 360, 24, -3, c);'),
    ('ringlinesexout', 'DrawRingLinesEx(V2(240, 90), 10, 30, 20, 210, 12, -3, c);'),
    ('ringlinesexoutwide', 'DrawRingLinesEx(V2(240, 90), 10, 30, 20, 330, 12, -6, c);'),
    ('ringlinesexoutnarrow', 'DrawRingLinesEx(V2(240, 90), 10, 30, 20, 50, 3, -6, c);'),
    ('ringlinesexsector', 'DrawRingLinesEx(V2(240, 90), 0, 30, 0, 90, 8, -3, c);'),
    ('ringlinesexnarrow', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 20, 4, 5, c);'),
    ('ringlinesexnarrowodd', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 21, 5, 5, c);'),
    ('ringlinesexcross', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 30, 6, 5, c);'),
    ('ringlinesexcrossodd', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 30, 5, 5, c);'),
    ('ringlinesexout9', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 340, 34, -4, c);'),
    ('ringlinesexout10', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 300, 5, -6, c);'),
    ('ringlinesexout11', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 100, 2, -6, c);'),
    ('ringlinesexout12', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 60, 1, -8, c);'),
    ('ringlinesexout13', 'DrawRingLinesEx(V2(240, 90), 12, 30, 0, 90, 2, -8, c);'),
    ('ringlinesexout3', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 250, 3, -6, c);'),
    ('ringlinesexout4', 'DrawRingLinesEx(V2(240, 90), 9, 30, 0, 150, 2, -6, c);'),
    ('ringlinesexout5', 'DrawRingLinesEx(V2(240, 90), 20, 30, 0, 300, 3, -3, c);'),
    ('ringlinesexout6', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 350, 4, -6, c);'),
    ('ringlinesexout7', 'DrawRingLinesEx(V2(240, 90), 15, 30, 0, 175, 2, -4, c);'),
    ('ringlinesexout8', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 330, 3, -8, c);'),
    # Left out: a hole the outward thickness closes, whose caps meet exactly at the center, where float and double rounding decide
    # whether they cross.
    ('ringlinesexfilled', 'DrawRingLinesEx(V2(240, 90), 10, 30, 0, 90, 6, 20, c);'),
    ('ringlinesexswap', 'DrawRingLinesEx(V2(240, 90), 30, 10, 300, 40, 0, 2.5, c);'),
    # The shapes texture: a part of a texture of its own, then back to the white pixel.
    ('shapestexture', 'SetShapesTexture(tex, R(4, 2, 8, 6)); DrawCircleSector(V2(20, 20), 9, 0, 90, 3, c); DrawRing(V2(20, 20), 4, 9, 0, 90, 2, c); '
        'DrawPolyLinesEx(V2(20, 20), 4, 9, 10, 2, c); DrawTriangle(V2(1, 1), V2(1, 9), V2(9, 9), c); DrawRectangleRounded(R(10, 10, 30, 20), 0.5, 3, c); '
        'DrawTriangleLinesEx(V2(1, 1), V2(1, 9), V2(9, 9), 1, c); DrawEllipseLinesEx(V2(20, 20), 9, 5, 2, c); '
        'DrawCircleSectorLinesEx(V2(20, 20), 9, 0, 90, 3, 2, c); DrawRingLinesEx(V2(20, 20), 4, 9, 0, 90, 2, 1, c); SetShapesTexture(tex, R(0, 0, 0, 5)); '
        'DrawTriangle(V2(1, 1), V2(1, 9), V2(9, 9), c);'),
    # Lines through a 2D camera: DrawRectangleLines' half pixel is in the transform's units, which BeginMode2D doesn't set; then
    # under a transform's scale.
    ('camera', 'BeginMode2D(cam); DrawRectangleLines(10, 20, 30, 40, c); DrawRectangleLines(-5, -5, 10, 10, c2);'),
    ('cameraend', 'EndMode2D(); DrawRectangleLines(10, 20, 30, 40, c);'),
    ('scaled', 'rlPushMatrix(); rlScalef(2, 4, 1); DrawRectangleLines(10, 20, 30, 40, c); rlPopMatrix();'),
    # Spline points and the line test.
    'vec2("quadratic", GetSplinePointBezierQuadratic(V2(10, 20), V2(50, 70), V2(90, 10), 0.4));',
    'flag("lines1", CheckCollisionLines(V2(0, 0), V2(10, 10), V2(0, 10), V2(10, 0), OUT(cp))); vec2("lines1at", cp);',
    'flag("lines2", CheckCollisionLines(V2(0, 0), V2(10, 0), V2(0, 1), V2(10, 1), OUT(cp))); vec2("lines2at", cp);',
    'flag("lines3", CheckCollisionLines(V2(0, 0), V2(4, 4), V2(0, 10), V2(10, 0), OUT(cp))); vec2("lines3at", cp);',
    'flag("lines4", CheckCollisionLines(V2(5, -5), V2(5, 5), V2(0, 0), V2(10, 0), OUT(cp))); vec2("lines4at", cp);',
    'flag("lines5", CheckCollisionLines(V2(0, 0), V2(5, 5), V2(5, 5), V2(10, 0), OUT(cp))); vec2("lines5at", cp);',
    'flag("lines6", CheckCollisionLines(V2(0, 0), V2(10, 0), V2(5, 0), V2(15, 0), OUT(cp))); vec2("lines6at", cp);',
    # #5510: a nearly vertical segment, its x spanning a few millionths, which 5.5's bounds test missed.
    'flag("lines7", CheckCollisionLines(V2(520.21936, 67.8957138), V2(520.219299, 179.760956), V2(469.264191, 99.073822), V2(571.237671, 101.955383), '
        'OUT(cp))); vec2("lines7at", cp);',
    'flag("lines8", CheckCollisionLines(V2(742.540466, 62.1793976), V2(742.540588, 145.028503), V2(652.848206, 74.9973526), V2(810.844177, 70.2308807), '
        'OUT(cp))); vec2("lines8at", cp);',
    'flag("lines9", CheckCollisionLines(V2(0, 0), V2(10, 0), V2(10, -5), V2(10, 5), OUT(cp))); vec2("lines9at", cp);',
]
