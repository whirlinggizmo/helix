"""collisions: raylib's 3D ray tests and collision checks against helix-ray's. One list for both sides (shared/gen.py's syntax), its
rays and shapes spelled once here; box is made in ref.c.in and CollisionBits.hx.in."""

RAYS = ['NEW(Ray, V3(0, 0, -10), V3(0, 0, 1))', 'NEW(Ray, V3(0.2, 0.1, 0), V3(0.6, 0, 0.8))',
        'NEW(Ray, V3(5, 5, 5), V3(-0.577350, -0.577350, -0.577350))', 'NEW(Ray, V3(0, 3, 0), V3(1, 0, 0))']

CASES = []
for i, ray in enumerate(RAYS):
    CASES += [
        f'hit("sphere{i}", GetRayCollisionSphere({ray}, V3(0, 0.5, 0), 1.5));',
        f'hit("box{i}", GetRayCollisionBox({ray}, box));',
        f'hit("triangle{i}", GetRayCollisionTriangle({ray}, V3(-2, -1, 1), V3(2, -1, 1), V3(0, 2, 1)));',
        f'hit("quad{i}", GetRayCollisionQuad({ray}, V3(-2, -1, 0.5), V3(2, -1, 0.5), V3(2, 2, 0.5), V3(-2, 2, 0.5)));',
        f'hit("mesh{i}", GetRayCollisionMesh({ray}, GenMeshCube(1, 2, 3), MatrixMultiply(MatrixRotateY(0.3), MatrixTranslate(0.1, 0, 0))));',
    ]
CASES += [
    'flag("boxes1", CheckCollisionBoxes(box, NEW(BoundingBox, V3(1, 2, 1), V3(3, 3, 3))));',
    'flag("boxes2", CheckCollisionBoxes(box, NEW(BoundingBox, V3(1.1, 0, 0), V3(3, 3, 3))));',
    'flag("spheres1", CheckCollisionSpheres(V3(0, 0, 0), 1, V3(1, 1, 1), 0.8));',
    'flag("spheres2", CheckCollisionSpheres(V3(0, 0, 0), 1, V3(1, 1, 1), 0.7));',
    'flag("boxsphere1", CheckCollisionBoxSphere(box, V3(2, 3, 0), 1.42));',
    'flag("boxsphere2", CheckCollisionBoxSphere(box, V3(2, 3, 0), 1.41));',
]
