"""shapes3d_62: raylib 6.2's spheres, capsules and billboards, read back from rlgl's batch, against helix-ray's frame. One list for both
sides (shared/gen.py's syntax): c is a color, p a point, texture a 32 x 16 white texture and camera a Camera, made in ref.c.in and
ShapeBits3D62.hx.in.

6.2's fixes: DrawSphereEx draws rings bands with a normal at each vertex (#4926, #6000; 5.5 drew rings + 1 and no normals), DrawSphereWires
the same bands (5.5 drew rings + 2, past the bottom pole), DrawCapsule and DrawCapsuleWires draw at least one ring (#5909; 5.5 divided
by 0 rings), and DrawBillboardPro moves a flipped billboard's part by the size the other way (#5276). 6.2 reordered DrawCapsule's slices
and rings, a choice helix-ray leaves as 5.5's, so a capsule's case is written for each side."""


def capsule(name, call, start, end, radius, slices, rings):
    """A capsule's case: helix-ray's call with 5.5's order (slices, rings), raylib 6.2's with its own (rings, slices)."""
    args = f'{start}, {end}, {radius}'
    return {'c': f'{call}({args}, {rings}, {slices}, c); shape("{name}");', 'hx': f'{call}({args}, {slices}, {rings}, c); shape("{name}");'}


CASES = [
    # Of radius 1: raylib 6.2's rlNormal3f no longer makes a normal of length 1 after the matrix (rlScalef by the radius), which
    # helix-ray's rlgl, 5.5's, does.
    ('sphere', 'DrawSphere(p, 1, c);'),
    ('sphereex', 'DrawSphereEx(p, 1, 5, 7, c);'),
    ('sphereex2', 'DrawSphereEx(p, 1, 2, 3, c);'),
    ('spherewires', 'DrawSphereWires(p, 1.5, 5, 7, c);'),
    ('spherewires2', 'DrawSphereWires(p, 0.5, 2, 3, c);'),
    capsule('capsule', 'DrawCapsule', 'p', 'V3(2, 4, 1)', 0.75, 6, 3),
    capsule('capsulesphere', 'DrawCapsule', 'p', 'p', 0.75, 6, 3),
    capsule('capsulewires', 'DrawCapsuleWires', 'p', 'V3(2, 4, 1)', 0.75, 6, 3),
    # No rings: 5.5 divided by them and drew no caps; 6.2 draws one ring.
    capsule('capsulerings0', 'DrawCapsule', 'p', 'V3(2, 4, 1)', 0.75, 6, 0),
    capsule('capsulewiresrings0', 'DrawCapsuleWires', 'p', 'V3(2, 4, 1)', 0.75, 5, -2),
    ('billboard', 'DrawBillboard(camera, texture, p, 2, c);'),
    # Flipped both ways.
    ('billboardflip', 'DrawBillboard(camera, texture, p, -2, c);'),
    ('billboardrec', 'DrawBillboardRec(camera, texture, R(4, 2, 16, 8), p, V2(-2, 1), c);'),
    ('billboardpro', 'DrawBillboardPro(camera, texture, R(4, 2, 16, 8), p, V3(0.2, 1, 0), V2(2, -1.5), V2(0.5, 0.25), 30, c);'),
    ('billboardproflip', 'DrawBillboardPro(camera, texture, R(4, 2, 16, 8), p, V3(0, 1, 0), V2(-3, -1.5), V2(0, 0), 0, c);'),
]
