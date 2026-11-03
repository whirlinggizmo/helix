"""shapes3d: raylib 5.5's 3D shapes, read back from rlgl's batch, against helix-ray's frame; the spheres, capsules and billboards are 6.2's
(shapes3d_62). One list for both sides (shared/gen.py's syntax): c is a color, p a point, texture a 32 x 16 white texture and camera a
Camera, made in ref.c.in and ShapeBits3D.hx.in."""

CASES = [
    ('line', 'DrawLine3D(p, V3(-1, 0.5, 4), c);'),
    ('point', 'DrawPoint3D(p, c);'),
    ('circle', 'DrawCircle3D(p, 2.5, V3(1, 1, 0), 30, c);'),
    ('triangle', 'DrawTriangle3D(p, V3(2, 2, 3), V3(1, 3, 3), c);'),
    ('strip', 'DrawTriangleStrip3D(PTS3(V3(0, 0, 0), V3(1, 0, 0), V3(0, 1, 0), V3(1, 1, 0), V3(0, 2, 1), V3(1, 2, 1)), 6, c);'),
    ('cube', 'DrawCube(p, 2, 3, 4, c);'),
    ('cubewires', 'DrawCubeWires(p, 2, 3, 4, c);'),
    ('cylinder', 'DrawCylinder(p, 1, 2, 3, 7, c);'),
    ('cone', 'DrawCylinder(p, 0, 2, 3, 5, c);'),
    ('cylinderex', 'DrawCylinderEx(p, V3(2, 4, 1), 1, 0.5, 6, c);'),
    ('coneex', 'DrawCylinderEx(p, V3(2, 4, 1), 0, 0.5, 6, c);'),
    ('cylinderwires', 'DrawCylinderWires(p, 1, 2, 3, 7, c);'),
    ('cylinderwiresex', 'DrawCylinderWiresEx(p, V3(2, 4, 1), 1, 0.5, 6, c);'),
    ('plane', 'DrawPlane(p, V2(3, 5), c);'),
    ('ray', 'DrawRay(NEW(Ray, p, V3(0, 0.6, 0.8)), c);'),
    ('grid', 'DrawGrid(5, 1.5);'),
    ('box', 'DrawBoundingBox(NEW(BoundingBox, V3(-1, -2, -3), V3(2, 1, 0.5)), c);'),
    # A shape under rlgl's matrix stack.
    ('cubeturned', 'rlPushMatrix(); rlRotatef(40, 0, 1, 1); DrawCube(p, 1, 1, 1, c); rlPopMatrix();'),
]
