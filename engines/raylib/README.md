# helix-raylib

[raylib](https://www.raylib.com) 5.5's API in Haxe.

| Type | What |
|---|---|
| `helix.raylib.Raylib` | raylib's functions, constants and colors, and the `...Async` calls the asset loads name |
| `helix.raylib.Raymath` | raymath |
| `helix.raylib.Rlgl` | rlgl |
| `helix.raylib.Raygui` | raygui 4.5-dev |
| `helix.raylib.Raylib6` | the calls raylib 6.0 adds, ahead of the move to raylib 6: `UpdateModelAnimationEx`, two animations blended |
| `helix.raylib.extras` | features beyond raylib's API that a program opts into: lighting and shadows, PBR materials, particles, sprite batches, tweens, a virtual gamepad, the device's safe area and sensors, a design size fitted to the window, GUI skins, debug drawing and frame stats |
| `helix.raylib.extras.tweens` | helix-tweens' tweens, with `ColorTween` accepting raylib's `Color` |
| `helix.raylib.Vector2`, `Color`, `Model` and the rest | raylib's structs |

Each raylib header is a class, imported as C includes the header: `import helix.raylib.Raylib.*;` brings `raylib.h`'s functions,
constants and colors in unqualified, `import helix.raylib.Rlgl.*;` brings `rlgl.h`'s, and so on for `Raymath`, `Raygui` and `Raylib6`.
`import helix.raylib.*;` brings the structs.

## Differences from raylib

- `EndDrawing`, `WaitTime`, a file call (`LoadFileText`, `SaveFileText`), a clipboard call, a screen read (`LoadImageFromScreen`,
  `LoadImageFromTexture`) and `TakeScreenshot` are unsupported in a function used as a value, in a constructor or in a variable's
  initial value (see "Calls that wait").
- A load from memory (`LoadImageFromMemory`, `LoadFontFromMemory`, `LoadWaveFromMemory`) is unsupported. Each names its `...Async`
  call.
- The first `TakeScreenshot` made with nothing drawn on the screen yet, as between frames, saves the next frame, and that frame's
  `EndDrawing` returns once the file is written. raylib's saves what the back buffer holds.
- A window or cursor request (`ToggleFullscreen`, `SetWindowSize`, `DisableCursor`) returns at once, and the window changes at a
  later frame. `IsWindowFullscreen` and the other window reads report the window as it is. A refusal is logged.
- With `-D helix-raylib-portable-sys`, a page has a `Sys`, and Haxe's `sys.io.File`, `sys.FileSystem` and `sys.io.Process`, and the
  `Sys` calls that wait or leave the program, are unsupported. Each names the raylib call to use.
- Shaders are compiled ahead of time (`CompileShaderFile`) and loaded from the file (`LoadCompiledShader`, `LoadCompiledShaderAsync`) or its data
  (`LoadCompiledShaderFromMemory`).
- Models, shapes and images follow raylib 6.2, which fixed bugs in 5.5.
- A lost GPU context is recovered automatically. Render textures are cleared.
- Unsupported: IQM, VOX and M3D models, morph targets, models drawn as points, and compressed images.

See the [API reference](https://whirlinggizmo.github.io/helix/api/helix/raylib/index.html) for everything else.

## Calls that wait

In a page, each function of the program that calls `EndDrawing`, `WaitTime`, a file call, a clipboard call, a screen read or `TakeScreenshot` is built as
an async function, and each call of it is awaited. So is a function calling one that does, and a function declared in a function and only ever called by its
name. The program writes nothing for this. Natively the same calls block.

These can't wait, and a call there is unsupported:

- a function used as a value (a callback, a function kept in a variable and passed on);
- a constructor, and a variable's initial value;
- a function an interface declares, and an override of a function that doesn't wait.

In a page, a function that waits gives the page's own JavaScript calling it a promise.

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
haxelib git helix-tweens https://github.com/whirlinggizmo/helix main libs/tweens
haxelib git helix-log https://github.com/whirlinggizmo/helix main libs/log
haxelib git helix-services https://github.com/whirlinggizmo/helix main libs/services
haxelib git helix-raylib https://github.com/whirlinggizmo/helix main engines/raylib
```

Defines, set in the build's hxml:

- `-D helix-raylib-asset-hosts=<urls and directories>`: where the program's files come from, unless the program calls `SetAssetHosts`
  or the `asset_hosts` option names the hosts (the Assets extra). The list is separated by commas, in the order the hosts are asked.
  A URL is fetched from, natively and in a page; a directory is relative to the program's own. Default `../web` natively, the page's
  own directory in a page.
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

Each fits its design to the window, a phone's included, with `SetScreenFit` and `SCREEN_FIT_EXPAND` (`helix.raylib.extras.Screen`),
but `extras/textures`, which fits its render texture itself.

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `frame_stats`: the frame stats read (`helix.raylib.extras.Debug`), the last half second's and a recording's.
- `text`: a TrueType font loaded and drawn beside the default font.
- `images`: an image made on the CPU, a circle and text drawn into it, drawn as a texture.
- `box2d`: a pyramid of boxes stepped by helix-box2d, a box dragged or a ball thrown down where the pointer presses.
- `jolt`: a stack of cubes stepped by helix-jolt and lit by the Lighting extra, spheres dropped onto it and fired from the camera.
- `extras/particles3d`: a fountain, one 3D emitter of the Particles extra, its particles worked out on the GPU (`helix.raylib.extras.Particles`).
- `extras/particles2d`: a sparkler, one 2D emitter of the Particles extra, its sparks drawn in the sprite batch.
- `extras/screen`: an 800 x 450 design fitted to the window, each fit, stretch, integer scale and bar color (clear in a transparent window) a key away
  (`helix.raylib.extras.Screen`).
- `extras/tweens`: a panel sliding in and its title fading in after it, a sequence, and a ball going back and forth for ever
  (`helix.raylib.extras.tweens`).

## Depends on

helix-services, helix-platform, helix-geometry, helix-tweens and helix-math (and helix-formats and helix-log under them).

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
The speed comparison's bunnymark (`tools/gen_speed.py`) takes its texture, `wabbit_alpha.png`, from raylib 5.5's release (its
`textures_bunnymark` resource), under the same zlib license; it isn't kept here.
The `text` example's font is [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono
Project Authors, under the SIL Open Font License 1.1 (`examples/text/web/assets/OFL.txt`).
