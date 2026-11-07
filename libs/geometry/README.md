# helix-geometry

Geometry for games: pure Haxe, built on [helix-math](../math/README.md).

- `Camera2D`, `Camera3D`: views of a world, their matrices, and what they see; a 3D camera's ray through a point of its view, to pick
  with.
- `Frustum3D`: what a camera sees, and whether a point, a sphere or bounds are in it.
- `Ray3D`, `RayHit3D`: rays and where they meet a plane, a sphere, bounds, a triangle or a mesh.
- `Mesh3D`: surfaces of triangles: the usual shapes made (box, plane, disk, sphere, hemisphere, cylinder and cone, capsule, torus,
  torus knot), merged and moved, their normals and tangents computed.
- `Geometry2D`: segments crossing, points in triangles and polygons, distances to segments, circles touching them.

```haxe
import helix.geometry.Camera3D;
import helix.geometry.Mesh3D;
import helix.geometry.Ray3D;
import helix.geometry.RayHit3D;

var ball = Mesh3D.fromSphere(0.5, 24, 12);
var ray = camera.computeRay(pointerX / width * 2 - 1, 1 - pointerY / height * 2, width / height, new Ray3D());
var hit = ray.intersectMesh(ball, placement, new RayHit3D());
```

## Using it

```
-lib helix-geometry
```

Until it is on haxelib, install it and the libraries it depends on from GitHub:

```
haxelib git helix-math https://github.com/whirlinggizmo/helix main libs/math
haxelib git helix-geometry https://github.com/whirlinggizmo/helix main libs/geometry
```

The API reference is [api/](api/README.md). Its tests, in `tests/`,
build with `-lib helix-geometry` alone.

## Depends on

helix-math.

## Credit

`Geometry2D`'s tests follow [raylib](https://www.raylib.com) 5.5's rshapes, by Ramon Santamaria (@raysan5) and its contributors,
altered; zlib license, `vendor/raylib/LICENSE`.
