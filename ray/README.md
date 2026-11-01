# helix-ray

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../services/README.md) and [helix-platform](../platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.ray.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them |
| `helix.ray.Raymath` | raymath's vectors, matrices and quaternions, as `raymath.h` names them, imported apart as raylib includes it |
| `helix.ray.Rlgl` | rlgl's matrix stack, immediate drawing and render state, as `rlgl.h` names them, imported apart as raylib includes it |
| `helix.ray.Vector2`, `Vector3`, `Color`, `Texture2D`, `Camera3D`, `Model`, `Shader`, `RenderTexture2D` and the rest | raylib's structs, with their fields |

The window and frame, the keyboard, mouse, touch and gamepads, text input, shapes, textures, blend and scissor modes, the default
font and TrueType and OpenType fonts (signed distance fields too), sounds and their aliases, waves (loaded, converted, cropped and
exported as raylib's are), music with its length, position and seeking, audio streams fed by the program or its callback, text files; images on the CPU in raylib's uncompressed pixel
formats (made, changed and drawn into as raylib's are, byte for byte, but for resizing), exported as PNG or QOI, and screenshots; in 3D
the camera, glTF and GLB models, raylib's shapes and billboards (its vertices, in its order), its generated meshes (vertex for vertex,
the same on every target), tangents, mesh buffers updated and meshes exported, render textures, rays and their collisions; raylib's
shaders, compiled as the program builds for every target; rlgl's render state (culling, depth, wire mode, viewport, scissor) and its
batch, flushed as raylib's is; automation events, recorded and played as raylib's, and raylib's random numbers for a seed. Not here
yet: materials loaded from files, skinned models and animations, models drawn as points, animated (GIF) and compressed images, and
updating a texture's pixels.

## Using it

```
-lib helix-ray
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-ray <checkout>/ray
```

`-D helix-ray-files=<directory>` names where the program's shaders are as it builds (default `web`), and `-D helix-ray-native-root=<directory>`
where a native program finds its files, relative to itself (default `../web`). `-D helix-ray-custom-frame-control` is raylib's
`SUPPORT_CUSTOM_FRAME_CONTROL`: `EndDrawing` only draws, and the program calls `SwapScreenBuffer`, `WaitTime` and `PollInputEvents`.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `text`: a TrueType font loaded and drawn beside the default font.
- `images`: an image made on the CPU, a circle and text drawn into it, drawn as a texture.

## Depends on

helix-services and helix-platform (and helix-formats, helix-math and helix-log under them).

## Credit

helix-ray's API and the flow of a program on it are [raylib](https://www.raylib.com)'s, by Ramon Santamaria (@raysan5) and its
contributors, mirrored in Haxe. A small API that a programmer can hold in their head and guess right is hard to make; raylib's is, and
this library is built on that work. Portions are from raylib 5.5 (its default font, its default shader, its header's comments, and its
API description, `vendor/raylib/raylib_api.json`, with `raymath_api.json` and `rlgl_api.json` made from `raymath.h` and `rlgl.h` by raylib's parser), altered; zlib
license, `vendor/raylib/LICENSE`. The meshes raylib generates with par_shapes are made by a port of its part of it, by Philip Rideout;
MIT license, `vendor/par_shapes/LICENSE`.
The `text` example's font is [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono
Project Authors, under the SIL Open Font License 1.1 (`examples/text/web/assets/OFL.txt`).
