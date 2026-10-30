# helix-ray

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../services/README.md) and [helix-platform](../platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.ray.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them, with raymath's |
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

`-D helix-ray-files=<directory>` names where the program's files are as it builds (default `web`), and `-D helix-ray-native-root=<directory>`
where a native program finds them, relative to itself (default `../web`). A page loads before `main` the files its program names, and
those under `-D helix-ray-preload=<folder>,...`; the rest it loads with the `...Async` functions.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.

## Depends on

helix-services and helix-platform (and helix-math and helix-log under them).

## Credit

helix-ray's API and the flow of a program on it are [raylib](https://www.raylib.com)'s, by Ramon Santamaria (@raysan5) and its
contributors, mirrored in Haxe. A small API that a programmer can hold in their head and guess right is hard to make; raylib's is, and
this library is built on that work. Portions are from raylib 5.5 (its default font, its default shader and its header's comments),
altered; zlib license, `vendor/raylib/LICENSE`.
