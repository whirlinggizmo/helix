"""shapes3d: raylib 5.5's 3D shapes and billboards, read back from rlgl's batch, against helix-ray's frame. One list for both sides
(shared/gen.py's syntax): c is a color, p a point, texture a 32 x 16 white texture and camera a Camera, made in ref.c.in and
ShapeBits3D.hx.in."""

CASES = [
    ('line', 'DrawLine3D(p, V3(-1, 0.5, 4), c);'),
    ('point', 'DrawPoint3D(p, c);'),
    ('circle', 'DrawCircle3D(p, 2.5, V3(1, 1, 0), 30, c);'),
    ('triangle', 'DrawTriangle3D(p, V3(2, 2, 3), V3(1, 3, 3), c);'),
    ('strip', 'DrawTriangleStrip3D(PTS3(V3(0, 0, 0), V3(1, 0, 0), V3(0, 1, 0), V3(1, 1, 0), V3(0, 2, 1), V3(1, 2, 1)), 6, c);'),
    ('cube', 'DrawCube(p, 2, 3, 4, c);'),
    ('cubewires', 'DrawCubeWires(p, 2, 3, 4, c);'),
    ('sphere', 'DrawSphere(p, 1.5, c);'),
    ('sphereex', 'DrawSphereEx(p, 1.5, 5, 7, c);'),
    ('spherewires', 'DrawSphereWires(p, 1.5, 5, 7, c);'),
    ('cylinder', 'DrawCylinder(p, 1, 2, 3, 7, c);'),
    ('cone', 'DrawCylinder(p, 0, 2, 3, 5, c);'),
    ('cylinderex', 'DrawCylinderEx(p, V3(2, 4, 1), 1, 0.5, 6, c);'),
    ('coneex', 'DrawCylinderEx(p, V3(2, 4, 1), 0, 0.5, 6, c);'),
    ('cylinderwires', 'DrawCylinderWires(p, 1, 2, 3, 7, c);'),
    ('cylinderwiresex', 'DrawCylinderWiresEx(p, V3(2, 4, 1), 1, 0.5, 6, c);'),
    ('capsule', 'DrawCapsule(p, V3(2, 4, 1), 0.75, 6, 3, c);'),
    ('capsulesphere', 'DrawCapsule(p, p, 0.75, 6, 3, c);'),
    ('capsulewires', 'DrawCapsuleWires(p, V3(2, 4, 1), 0.75, 6, 3, c);'),
    ('plane', 'DrawPlane(p, V2(3, 5), c);'),
    ('ray', 'DrawRay(NEW(Ray, p, V3(0, 0.6, 0.8)), c);'),
    ('grid', 'DrawGrid(5, 1.5);'),
    ('box', 'DrawBoundingBox(NEW(BoundingBox, V3(-1, -2, -3), V3(2, 1, 0.5)), c);'),
    ('billboard', 'DrawBillboard(camera, texture, p, 2, c);'),
    ('billboardrec', 'DrawBillboardRec(camera, texture, R(4, 2, 16, 8), p, V2(-2, 1), c);'),
    ('billboardpro', 'DrawBillboardPro(camera, texture, R(4, 2, 16, 8), p, V3(0.2, 1, 0), V2(2, -1.5), V2(0.5, 0.25), 30, c);'),
    # A shape under rlgl's matrix stack.
    ('cubeturned', 'rlPushMatrix(); rlRotatef(40, 0, 1, 1); DrawCube(p, 1, 1, 1, c); rlPopMatrix();'),
]
