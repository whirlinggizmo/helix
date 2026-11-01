"""shapes2d_62: the 2D shapes helix-ray takes from raylib 6.2 (docs/DECISIONS.md 24), read back from rlgl's batch, against helix-ray's
frame: those 6.2 fixed (the sectors, rings, rectangle and polygon outlines, rounded rectangles, the triangle, the line test) and those
calling them (the circles, the B-spline's and Catmull-Rom's round ends). One list
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
    # #6004: the thickness across the sides, where 5.5's turned its angle into radians twice and measured it from the corners.
    ('polylinesex', 'DrawPolyLinesEx(V2(720, 155), 7, 25, 10, 4, c);'),
    ('polylinesexthick', 'DrawPolyLinesEx(V2(720, 155), 3, 25, 200, 30, c);'),
    ('polylinesexnegative', 'DrawPolyLinesEx(V2(720, 155), 6, 25, 0, -4, c);'),
    ('splinebasis', 'DrawSplineBasis(PTS(V2(220, 220), V2(270, 260), V2(320, 210), V2(370, 270), V2(410, 220)), 5, 3, c);'),
    ('splinecatmullrom', 'DrawSplineCatmullRom(PTS(V2(430, 220), V2(480, 260), V2(530, 210), V2(580, 270), V2(620, 220)), 5, 3, c);'),
    ('splinebasisshort', 'DrawSplineBasis(PTS(V2(1, 2), V2(3, 4), V2(5, 6)), 3, 3, c);'),
    # 0 thick: the round ends have no radius and draw nothing.
    ('splinebasisflat', 'DrawSplineBasis(PTS(V2(220, 220), V2(270, 260), V2(320, 210), V2(370, 270)), 4, 0, c);'),
    # The shapes texture: a part of a texture of its own, then back to the white pixel.
    ('shapestexture', 'SetShapesTexture(tex, R(4, 2, 8, 6)); DrawCircleSector(V2(20, 20), 9, 0, 90, 3, c); DrawRing(V2(20, 20), 4, 9, 0, 90, 2, c); '
        'DrawPolyLinesEx(V2(20, 20), 4, 9, 10, 2, c); DrawTriangle(V2(1, 1), V2(1, 9), V2(9, 9), c); DrawRectangleRounded(R(10, 10, 30, 20), 0.5, 3, c); '
        'SetShapesTexture(tex, R(0, 0, 0, 5)); DrawTriangle(V2(1, 1), V2(1, 9), V2(9, 9), c);'),
    # Lines through a 2D camera: DrawRectangleLines' half pixel is in the transform's units, which BeginMode2D doesn't set; then
    # under a transform's scale.
    ('camera', 'BeginMode2D(cam); DrawRectangleLines(10, 20, 30, 40, c); DrawRectangleLines(-5, -5, 10, 10, c2);'),
    ('cameraend', 'EndMode2D(); DrawRectangleLines(10, 20, 30, 40, c);'),
    ('scaled', 'rlPushMatrix(); rlScalef(2, 4, 1); DrawRectangleLines(10, 20, 30, 40, c); rlPopMatrix();'),
    # The line test.
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
