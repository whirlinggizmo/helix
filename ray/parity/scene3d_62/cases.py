"""scene3d_62: raylib 6.2's spheres, capsules and billboards, and a knot given tangents by GenMeshTangents drawn by a shader reading them,
as both draw them between scene.c.in's and Main.hx.in's DrawGrid and EndMode3D (shared/gen.py's syntax); scene3d's templates, its
camera, checks and shaded made there. 6.2 reordered DrawCapsule's slices and rings, a choice helix-ray leaves as 5.5's, so a capsule's
case is written for each side."""


def capsule(call, rest, slices, rings, color):
    """A capsule's case: helix-ray's call with 5.5's order (slices, rings), raylib 6.2's with its own (rings, slices)."""
    return {'c': f'{call}({rest}, {rings}, {slices}, {color});', 'hx': f'{call}({rest}, {slices}, {rings}, {color});'}


CASES = [
    'DrawSphere(V3(-2.5, 0.6, -3), 0.6, GREEN); DrawSphereWires(V3(-2.5, 0.6, -3), 0.62, 6, 8, DARKGREEN);',
    'DrawSphereEx(V3(-4, 0.6, -1), 0.5, 3, 5, LIME); DrawSphereWires(V3(-4, 0.6, -1), 0.52, 3, 5, DARKGREEN);',
    capsule('DrawCapsule', 'V3(1.6, 0.4, -3), V3(2.4, 1.4, -3), 0.35', 8, 4, 'ORANGE'),
    capsule('DrawCapsuleWires', 'V3(1.6, 0.4, -3), V3(2.4, 1.4, -3), 0.36', 8, 4, 'BROWN'),
    capsule('DrawCapsule', 'V3(-1, 0.4, -1), V3(-0.4, 1.2, -1), 0.3', 6, 0, 'GOLD'),
    'DrawBillboard(camera, checks, V3(4.8, 0.8, 0), 1, WHITE);',
    # Flipped, their parts kept inside the texture: helix-ray's textures clamp where raylib's repeat (a difference of its own, not 6.2's).
    'DrawBillboardRec(camera, checks, R(40, 30, 20, 24), V3(3.4, 0.8, 1), V2(-1, 1), WHITE);',
    'DrawBillboardPro(camera, checks, R(8, 8, 32, 24), V3(-5.5, 0.8, 1), V3(0, 1, 0), V2(1.2, 0.9), V2(0.6, 0.45), 25, WHITE);',
    'DrawBillboardPro(camera, checks, R(40, 30, 20, 24), V3(-3.5, 0.8, 1.5), V3(0, 1, 0), V2(-1.2, -0.9), V2(0, 0), 0, WHITE);',
    'DrawModel(shaded, V3(5.5, 0.6, -1), 0.4, WHITE);',
]
