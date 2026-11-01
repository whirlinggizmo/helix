"""collisions_62: raylib 6.2's GetRayCollisionSphere (6.2 #6231: no hit on a sphere behind the ray; point, normal and distance 0 on a miss)
against helix-ray's. One list for both sides (shared/gen.py's syntax)."""

# collisions' four rays (from outside, from inside, diagonal, missing), then rays the sphere is behind: wholly, from just outside it, and
# off to one side.
RAYS = ['NEW(Ray, V3(0, 0, -10), V3(0, 0, 1))', 'NEW(Ray, V3(0.2, 0.1, 0), V3(0.6, 0, 0.8))',
        'NEW(Ray, V3(5, 5, 5), V3(-0.577350, -0.577350, -0.577350))', 'NEW(Ray, V3(0, 3, 0), V3(1, 0, 0))',
        'NEW(Ray, V3(0, 0, -10), V3(0, 0, -1))', 'NEW(Ray, V3(0, 0.5, 1.6), V3(0, 0, 1))', 'NEW(Ray, V3(3, 0.5, 0), V3(1, 0, 0))']

CASES = [f'hit("sphere{i}", GetRayCollisionSphere({ray}, V3(0, 0.5, 0), 1.5));' for i, ray in enumerate(RAYS)]
