# helix-ray

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../services/README.md) and [helix-platform](../platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.ray.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them |
| `helix.ray.Raymath` | raymath's vectors, matrices and quaternions, as `raymath.h` names them, imported apart as raylib includes it |
| `helix.ray.Vector2`, `Vector3`, `Color`, `Texture2D`, `Camera3D`, `Model`, `Shader`, `RenderTexture2D` and the rest | raylib's structs, with their fields |

The window and frame, the keyboard, mouse, touch and gamepads, shapes, textures, the default font, sounds, text files; in 3D the
camera, glTF and GLB models, meshes, shapes, render textures, rays; raylib's shaders, compiled as the program builds for every target.
Not here yet: skinned models and animations, fonts from files, and images on the CPU.

## Using it

```
-lib helix-ray
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-ray <checkout>/ray
```

`-D helix-ray-files=<directory>` names where the program's shaders are as it builds (default `web`), and `-D helix-ray-native-root=<directory>`
where a native program finds its files, relative to itself (default `../web`).

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.

## Depends on

helix-services and helix-platform (and helix-math and helix-log under them).

## Credit

helix-ray's API and the flow of a program on it are [raylib](https://www.raylib.com)'s, by Ramon Santamaria (@raysan5) and its
contributors, mirrored in Haxe. A small API that a programmer can hold in their head and guess right is hard to make; raylib's is, and
this library is built on that work. Portions are from raylib 5.5 (its default font, its default shader, its header's comments, and its
API description, `vendor/raylib/raylib_api.json`, with `raymath_api.json` made from `raymath.h` by raylib's parser), altered; zlib
license, `vendor/raylib/LICENSE`.
