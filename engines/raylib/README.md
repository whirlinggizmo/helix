# helix-raylib

[raylib](https://www.raylib.com) 5.5's API in Haxe. A raylib program runs in a page and natively.

| Type | What |
|---|---|
| `helix.raylib.Raylib` | raylib's functions, constants and colors |
| `helix.raylib.Raymath` | raymath |
| `helix.raylib.Rlgl` | rlgl |
| `helix.raylib.Raygui` | raygui 4.5-dev |
| `helix.raylib.extras` | what helix-raylib adds: async loads, PBR lighting, device and window info |
| `helix.raylib.Vector2`, `Color`, `Model` and the rest | raylib's structs |

Three things differ from raylib:

- Files load with the `...Async` calls in `helix.raylib.extras`. A page can't wait for a file.
- `LoadShader` takes constant file names. Shaders compile with the program.
- Models, shapes and images follow raylib 6.2, which fixed bugs in 5.5.

Not supported: IQM, VOX and M3D models, morph targets, models drawn as points, and compressed images.

See the [API reference](https://whirlinggizmo.github.io/helix/api/helix/raylib/index.html) for everything else.

## Using it

```
-lib helix-raylib
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-raylib <checkout>/engines/raylib
```

Defines, set in the build's hxml:

- `-D helix-raylib-files=<directory>`: where the shaders are at build time. Default `web`.
- `-D helix-raylib-native-root=<directory>`: where a native program finds its files, relative to itself. Default `../web`.
- `-D helix-raylib-custom-frame-control`: raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`. `EndDrawing` only draws. The program calls
  `SwapScreenBuffer`, `WaitTime` and `PollInputEvents`.
- `-D helix-raylib-host-warnings`: warns at build time where the program reaches the page or host directly for something
  `helix.raylib.extras` provides. Off by default.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `text`: a TrueType font loaded and drawn beside the default font.
- `images`: an image made on the CPU, a circle and text drawn into it, drawn as a texture.

## Depends on

helix-services and helix-platform (and helix-formats, helix-math and helix-log under them).

## Credit

helix-raylib's API and the flow of a program on it are [raylib](https://www.raylib.com)'s, by Ramon Santamaria (@raysan5) and its
contributors, mirrored in Haxe. A small API that a programmer can hold in their head and guess right is hard to make; raylib's is, and
this library is built on that work. Portions are from raylib 5.5 (its default font, its default shader, its header's comments, and its
API description, `vendor/raylib/raylib_api.json`, with `raymath_api.json` and `rlgl_api.json` made from `raymath.h` and `rlgl.h` by raylib's parser), altered; zlib
license, `vendor/raylib/LICENSE`. The meshes raylib generates with par_shapes are made by a port of its part of it, by Philip Rideout;
MIT license, `vendor/par_shapes/LICENSE`.
`Raygui` is a port of raygui 4.5-dev, the `raygui.h` raylib 5.5 ships, by Ramon Santamaria (@raysan5) and its contributors: its
controls, default style and built-in icons, altered; its API description, `vendor/raygui/raygui_api.json`, is made from `raygui.h` by
raylib's parser; zlib license, `vendor/raygui/LICENSE`.
The bunnymark's texture, `tests/bunnymark/wabbit_alpha.png`, is raylib 5.5's `textures_bunnymark` resource, under the same zlib license.
The `text` example's font is [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono
Project Authors, under the SIL Open Font License 1.1 (`examples/text/web/assets/OFL.txt`).
