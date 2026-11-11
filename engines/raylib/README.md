# helix-raylib

[raylib](https://www.raylib.com) 5.5's API in Haxe.

| Type | What |
|---|---|
| `helix.raylib.Raylib` | raylib's functions, constants and colors, and beside each call that waits for a file or the window the `...Async` call that replaces it |
| `helix.raylib.Raymath` | raymath |
| `helix.raylib.Rlgl` | rlgl |
| `helix.raylib.Raygui` | raygui 4.5-dev |
| `helix.raylib.Raylib6` | the calls raylib 6.0 adds, ahead of the move to raylib 6: `UpdateModelAnimationEx`, two animations blended |
| `helix.raylib.Rlights` | rlights, from raylib's lighting examples |
| `helix.raylib.extras` | what a program opts into that raylib has no call for: lit and PBR shaders, a virtual gamepad, a model's bounds as posed, models merged into one, the device (safe area, touch, orientation, tilt), raygui skins from images, debug drawing and frame stats, many copies of a sprite in one call |
| `helix.raylib.Vector2`, `Color`, `Model` and the rest | raylib's structs |

Each raylib header is a class, imported as C includes the header: `import helix.raylib.Raylib.*;` brings `raylib.h`'s functions,
constants and colors in unqualified, `import helix.raylib.Rlgl.*;` brings `rlgl.h`'s, and so on for `Raymath`, `Raygui`, `Raylib6` and
`Rlights`. `import helix.raylib.*;` brings the structs.

## Differences from raylib

- Files load with the `...Async` calls beside raylib's, in `Raylib` and `Raygui`.
- With `-D helix-raylib-portable-sys`, a page has a `Sys`, and Haxe's `sys.io.File`, `sys.FileSystem` and `sys.io.Process`, and the
  `Sys` calls that wait or leave the program, don't compile. Each names the raylib call to use.
- Shaders are compiled ahead of time (`CompileShaderFile`) and loaded from the file (`LoadCompiledShaderAsync`) or its data
  (`LoadCompiledShaderFromData`).
- Models, shapes and images follow raylib 6.2, which fixed bugs in 5.5.
- A lost GPU context is recovered automatically. Render textures are cleared.
- Not supported: IQM, VOX and M3D models, morph targets, models drawn as points, and compressed images.

See the [API reference](https://whirlinggizmo.github.io/helix/api/helix/raylib/index.html) for everything else.

## Using it

```
-lib helix-raylib
-D helix-company=<company>
-D helix-product=<product>
```

The two names are required. They say where the program's saves and cache are kept, so two programs keep apart, and natively
they name the program to the system. Each is one directory's name. A build without them fails, saying so.

Until it is on haxelib, install it and the libraries it depends on from GitHub:

```
haxelib git helix-math https://github.com/whirlinggizmo/helix main libs/math
haxelib git helix-formats https://github.com/whirlinggizmo/helix main libs/formats
haxelib git helix-platform https://github.com/whirlinggizmo/helix main libs/platform
haxelib git helix-geometry https://github.com/whirlinggizmo/helix main libs/geometry
haxelib git helix-log https://github.com/whirlinggizmo/helix main libs/log
haxelib git helix-services https://github.com/whirlinggizmo/helix main libs/services
haxelib git helix-raylib https://github.com/whirlinggizmo/helix main engines/raylib
```

Defines, set in the build's hxml:

- `-D helix-raylib-native-root=<directory>`: where a native program finds its files, relative to itself. Default `../web`.
- `-D helix-raylib-custom-frame-control`: raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`. `EndDrawing` only draws. The program calls
  `SwapScreenBuffer`, `WaitTime` and `PollInputEvents`.
- `-D helix-raylib-portable-sys`: gives a page a `Sys` (the program's options from the URL's query, the console and the clock) and
  refuses on every target what a page can't answer: Haxe's file calls (`sys.io.File`, `sys.FileSystem`), `sys.io.Process` and the `Sys`
  calls a page has no answer for. Each refusal names the raylib call to use, so a program that builds natively builds for the page. Off
  by default, when a build is Haxe's as shipped.
- `-D helix-raylib-host-warnings`: warns at build time where the program reaches the page or host directly for something
  `Raylib` provides. Off by default.
- `-D helix-raylib-frame-stats`: for timing a program without changing it. With the `frame_stats` option (`--frame_stats=120,1200`
  natively, `?frame_stats=120,1200` in a page), records frames 121 to 1200 (`StartFrameStatsRecording`), prints the stats as
  `frame_stats` and a JSON object, and closes the window. In a page the object is also `window.helixResult`. Off by default.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `frame_stats`: the frame stats read (`helix.raylib.extras.Debug`), the last half second's and a recording's.
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
