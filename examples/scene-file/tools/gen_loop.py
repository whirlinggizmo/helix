"""Lays the scene-file example's track and writes it as assets/scenes/track.scene: a closed loop of Kenney's Racing Kit pieces
(assets/kit) walked piece by piece from a layout string, with the barriers along the straights' outsides, a gantry over the start line,
the scenery, the checkpoints on the centerline, the sun, the car and the chase camera. Run it after changing the layout; the numbers in
the file are its output, so the loop closes by construction (the script refuses to write one that doesn't).

The kit's conventions, checked against the files' geometry: a road piece is modeled on a tile of 1 unit, 0.02 high, and placed at a scale of
16 x 2 x 16 (a 16 m tile, the road a 4 cm step); a straight runs along its local -z from its entry edge at z = 0, x from 0 to 1 across, the
asphalt from x 0.155 to 0.845; a corner of k tiles a side (roadCornerLarge k = 2, roadCornerLarger k = 3) is an arc about its local (k, 0)
of centerline radius k - 0.5, from the entry at (0.5, 0) running -z to the exit at (k, -(k - 0.5)) running +x. A heading h is a yaw about
+y, 0 along +z, left turns adding, so forward is (sin h, cos h) in x, z and the right-hand side is (-cos h, sin h). A rotation a about y
takes a local (x, z) to (x cos a + z sin a, -x sin a + z cos a)."""
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / 'assets' / 'scenes' / 'track.scene'
TILE = 16.
ROAD_HEIGHT = 2.  # The road pieces' y scale: 0.02 x 2, a 4 cm step.
# The loop: S<n> a straight of n tiles, L<k> a left corner of k tiles a side, R<k> a right one.
LAYOUT = 'S4 L2 S2 L2 S4 L2 S2 L2'


def forward(h):
    return math.sin(h), math.cos(h)


def right(h):
    return -math.cos(h), math.sin(h)


def turned(a, x, z):
    """A local x, z turned by a about y."""
    return x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)


def wrap(a):
    """An angle in -pi..pi."""
    while a > math.pi:
        a -= 2 * math.pi
    while a <= -math.pi:
        a += 2 * math.pi
    return a


def num(v):
    """A number rounded for the file: integers without a point."""
    r = round(v, 4)
    return int(r) if r == int(r) else r


def piece(name, file, x, z, yaw, scale, y=0., **more):
    node = {'kind': 'Model', 'name': name, 'file': f'kit/{file}.glb', 'position': [num(x), num(y), num(z)]}
    if yaw != 0:
        node['rotation'] = [0, num(wrap(yaw)), 0]
    node['scale'] = [num(s) for s in scale]
    node.update(more)
    return node


def placed(name, file, px, pz, a, lx, lz, scale, y=0., **more):
    """A piece turned by a, positioned so its local (lx, lz) (in tiles) lands on px, pz."""
    dx, dz = turned(a, lx * TILE, lz * TILE)
    return piece(name, file, px - dx, pz - dz, a, scale, y, **more)


def lay(layout):
    """Walks the layout from the origin heading -z: the road nodes, the straights (their entry point, heading and tile count), the corners
    (their middle point and heading there) and the end point, which must be the start for a closed loop."""
    x, z, h = 0., 0., math.pi
    road, straights, corners = [], [], []
    count = 0
    for token in layout.split():
        kind, n = token[0], int(token[1:])
        fx, fz = forward(h)
        if kind == 'S':
            straights.append((x, z, h, n))
            i = 0
            while i < n:
                count += 1
                # The start grid is the first straight's first two tiles; a pair of tiles is one long piece.
                if count == 1 and n >= 2:
                    file, tiles = 'roadStartPositions', 2
                elif n - i >= 2:
                    file, tiles = 'roadStraightLong', 2
                else:
                    file, tiles = 'roadStraight', 1
                road.append(placed(f'road_{len(road)}', file, x + fx * i * TILE, z + fz * i * TILE, h + math.pi, .5, 0, [TILE, ROAD_HEIGHT, TILE],
                                   shadowCasting=False))
                i += tiles
            x += fx * n * TILE
            z += fz * n * TILE
        else:
            k = n
            file = {2: 'roadCornerLarge', 3: 'roadCornerLarger'}[k]
            r = (k - .5) * TILE
            if kind == 'L':
                a = h + math.pi / 2
                node = placed(f'road_{len(road)}', file, x, z, a, k, -(k - .5), [TILE, ROAD_HEIGHT, TILE], shadowCasting=False)
                exit_local = (.5, 0)
                turn = math.pi / 2
            else:
                a = h + math.pi
                node = placed(f'road_{len(road)}', file, x, z, a, .5, 0, [TILE, ROAD_HEIGHT, TILE], shadowCasting=False)
                exit_local = (k, -(k - .5))
                turn = -math.pi / 2
            road.append(node)
            ox, oz = node['position'][0], node['position'][2]
            cx, cz = turned(a, k * TILE, 0)
            cx, cz = ox + cx, oz + cz
            ex, ez = turned(a, exit_local[0] * TILE, exit_local[1] * TILE)
            ex, ez = ox + ex, oz + ez
            # The arc's middle: along the bisector of the entry and the exit seen from the center.
            bx, bz = (x - cx) + (ex - cx), (z - cz) + (ez - cz)
            bl = math.hypot(bx, bz)
            corners.append((cx + bx / bl * r, cz + bz / bl * r, h + turn / 2, kind))
            x, z, h = ex, ez, h + turn
    return road, straights, corners, (x, z, wrap(h))


def barriers(straights):
    """Barrier walls along each straight's outside (the loop turns left, so its right), one a tile, their thickness outward."""
    nodes = []
    for sx, sz, h, n in straights:
        fx, fz = forward(h)
        rx, rz = right(h)
        for i in range(n):
            # The wall's +x runs back along the straight from its origin at the tile's far end, its thickness (its -z) outward.
            ox = sx + fx * (i + 1) * TILE + rx * 6
            oz = sz + fz * (i + 1) * TILE + rz * 6
            nodes.append(piece(f'barrier_{len(nodes)}', 'barrierWall', ox, oz, h + math.pi / 2, [TILE, TILE, TILE]))
    return nodes


def scenery(straights, corners):
    """The gantry over the start line, flags beside it, the grandstand and light posts along the first straight, banner towers and pylons
    at the corners, trees outside."""
    nodes = []
    sx, sz, h, n = straights[0]
    fx, fz = forward(h)
    rx, rz = right(h)
    a = h + math.pi
    # The start line 20 m along the first straight: the gantry across it (its x spans the tile), the flags at its feet.
    lx, lz = sx + fx * 20, sz + fz * 20
    nodes.append(piece('gantry', 'overhead', lx - rx * 8, lz - rz * 8, a, [TILE, TILE, TILE]))
    nodes.append(piece('flag_left', 'flagCheckers', lx - rx * 9.5, lz - rz * 9.5, a, [10, 10, 10]))
    nodes.append(piece('flag_right', 'flagCheckers', lx + rx * 9.5, lz + rz * 9.5, a, [10, 10, 10]))
    # The grandstand beside tiles 2 and 3 of the first straight, outside the barrier, its seats (its local -z side) toward the track.
    gx, gz = sx + fx * 2 * TILE + rx * 26, sz + fz * 2 * TILE + rz * 26
    nodes.append(piece('grandstand', 'grandStand', gx, gz, h - math.pi / 2, [TILE, TILE, TILE]))
    for i in (1, 3):
        px, pz = sx + fx * i * TILE - rx * 9, sz + fz * i * TILE - rz * 9
        nodes.append(piece(f'light_{i}', 'lightPostLarge', px, pz, a, [TILE, TILE, TILE]))
    # Each corner: a banner tower at its outside, pylons at its inside, a few trees further out.
    for i, (cx, cz, ch, kind) in enumerate(corners):
        rx, rz = right(ch)
        out = 1 if kind == 'L' else -1
        tower = 'bannerTowerRed' if i % 2 else 'bannerTowerGreen'
        nodes.append(piece(f'tower_{i}', tower, cx + rx * out * 12, cz + rz * out * 12, ch + math.pi, [10, 10, 10]))
        for j in range(3):
            fx, fz = forward(ch)
            px = cx - rx * out * 7 + fx * (j - 1) * 3
            pz = cz - rz * out * 7 + fz * (j - 1) * 3
            nodes.append(piece(f'pylon_{i}_{j}', 'pylon', px, pz, 0, [TILE, TILE, TILE]))
        for j, (d, s, tree) in enumerate(((22, 6, 'treeLarge'), (28, -8, 'treeSmall'), (19, -14, 'treeLarge'), (26, 14, 'treeSmall'))):
            fx, fz = forward(ch)
            px = cx + rx * out * d + fx * s
            pz = cz + rz * out * d + fz * s
            nodes.append(piece(f'tree_{i}_{j}', tree, px, pz, 0, [10, 10, 10]))
    return nodes


def checkpoints(straights, corners):
    """Eight on the centerline: 0 at the start line, then alternately each corner's middle and each later straight's middle."""
    points = []
    sx, sz, h, n = straights[0]
    fx, fz = forward(h)
    points.append((sx + fx * 20, sz + fz * 20))
    for i, (cx, cz, ch, kind) in enumerate(corners):
        points.append((cx, cz))
        if i + 1 < len(straights):
            sx, sz, h, n = straights[i + 1]
            fx, fz = forward(h)
            points.append((sx + fx * n * TILE / 2, sz + fz * n * TILE / 2))
    nodes = []
    for i, (x, z) in enumerate(points):
        nodes.append({'kind': 'Node3D', 'name': f'checkpoint_{i}', 'position': [num(x), 1, num(z)],
                      'behaviors': [{'kind': 'Checkpoint', 'props': {'index': i, 'radius': 10, 'race': '@race'}}]})
    return nodes


def main():
    road, straights, corners, end = lay(LAYOUT)
    if abs(end[0]) > 1e-6 or abs(end[1]) > 1e-6 or abs(wrap(end[2] - math.pi)) > 1e-9:
        raise SystemExit(f'the loop {LAYOUT!r} does not close: it ends at {end}')
    sx, sz, h, n = straights[0]
    fx, fz = forward(h)
    scene = {
        'helix-scene': 1,
        'stage': {
            'ambient': {'color': '#dfe8ff', 'intensity': .2},
            'environment': {'file': 'environments/venice_sunset_1k.hdr', 'intensity': .55, 'rotation': 2.2},
            'background': {'file': 'environments/venice_sunset_1k.hdr', 'blur': .15},
            'tonemap': 'aces',
            'exposure': .2,
        },
        'nodes': [
            # The sun 37 degrees up, shining toward -x and +z: a car heading down the first straight (-z) throws its shadow toward the
            # chase camera behind it.
            {'kind': 'DirectionalLight', 'name': 'sun', 'rotation': [-.64, 2.11, 0], 'color': '#fff1dc', 'intensity': 3.5,
             'shadowCasting': True, 'shadowDistance': 70, 'shadowMapSize': 2048, 'shadowColor': '#24304a', 'shadowStrength': .9},
            {'kind': 'Model', 'name': 'ground', 'file': 'kit/ground.glb', 'position': [0, -.01, 0], 'scale': [480, 1, 480], 'shadowCasting': False},
            {'kind': 'Node3D', 'name': 'track', 'children': road},
            {'kind': 'Node3D', 'name': 'barriers', 'children': barriers(straights)},
            {'kind': 'Node3D', 'name': 'scenery', 'children': scenery(straights, corners)},
            {'kind': 'Node3D', 'name': 'race', 'behaviors': [{'kind': 'Race', 'props': {'car': '@car', 'countdown': 3}}]},
            {'kind': 'Node3D', 'name': 'checkpoints', 'children': checkpoints(straights, corners)},
            {'scene': 'scenes/car.scene', 'name': 'car', 'position': [num(sx + fx * 6), .04, num(sz + fz * 6)], 'rotation': [0, num(wrap(h)), 0],
             'behaviors': [{'kind': 'Car', 'props': {'race': '@race'}}]},
            {'kind': 'Camera3D', 'name': 'chase', 'position': [num(sx - fx * 8), 4, num(sz - fz * 8)], 'fovY': .9, 'far': 600,
             'behaviors': [{'kind': 'ChaseCamera', 'props': {'target': '@car', 'distance': 9, 'height': 3.5, 'lag': .25}}]},
        ],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(scene, indent=2) + '\n', encoding='utf-8')
    print(f'{OUT.relative_to(HERE.parent.parent.parent)}: {len(road)} road pieces, the loop closes at {tuple(round(v, 3) for v in end)}')


if __name__ == '__main__':
    main()
