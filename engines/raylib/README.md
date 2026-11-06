# helix-raylib

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../../libs/services/README.md) and [helix-platform](../../libs/platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.raylib.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them |
| `helix.raylib.Raymath` | raymath's vectors, matrices and quaternions, as `raymath.h` names them, imported apart as raylib includes it |
| `helix.raylib.Rlgl` | rlgl's matrix stack, immediate drawing and render state, as `rlgl.h` names them, imported apart as raylib includes it |
| `helix.raylib.Raygui` | raygui, raylib's immediate-mode GUI, as the `raygui.h` raylib 5.5 ships names it (raygui 4.5-dev): its controls, style, font, state, tooltips and icons, imported apart (`import helix.raylib.Raygui.*;`) |
| `helix.raylib.extras.Window`, `Files`, `Textures`, `Text`, `Models`, `Audio` | the `...Async` loads, requests and writes in place of raylib's calls a page can't wait for, a module for each of raylib's modules (rcore's in `Window` and `Files`), each imported apart (`import helix.raylib.extras.Textures.*;`) |
| `helix.raylib.extras.Device` | the safe area, run options, device, window abilities, screen orientation and tilt, which raylib has no call for (`import helix.raylib.extras.Device.*;`) |
| `helix.raylib.Vector2`, `Vector3`, `Color`, `Texture2D`, `Camera3D`, `Model`, `Shader`, `RenderTexture2D` and the rest | raylib's structs, with their fields |

The window and frame, the keyboard, mouse, touch and gamepads, text input, shapes (with 6.2's fixes), textures (their pixels updated and read back, their mipmaps made and filtered as raylib's GL filters them; cubemaps from an image in any of raylib's layouts, drawn as a skybox or sampled by a shader), every blend mode (rlgl's custom factors too) and scissor modes, the default
font and TrueType and OpenType fonts (signed distance fields too, exported as C code), sounds and their aliases, waves (loaded, converted, cropped and
exported as raylib's are), music with its length, position and seeking, audio streams fed by the program or its callback, text files; images on the CPU in raylib's uncompressed pixel
formats (made, changed and drawn into as raylib's are, byte for byte, but for resizing; with 6.2's fixes), exported as PNG or QOI, GIF files (their first frame as an image, texture or font image, and every frame with `LoadImageAnimAsync`, composited as raylib 5.5's are), and screenshots; in 3D
the camera, glTF and GLB models and their materials (as raylib 6.2 reads them: its metallic-roughness image split into roughness and metalness maps), OBJ models
and the .mtl materials they name, as raylib 6.2's `LoadOBJ` and `LoadMaterials` make them (`LoadMaterialsAsync` in place of `LoadMaterials`), skinned models and their animations (read, mixed between frames and between animations, and skinned
on the CPU or by a skinning shader, as raylib 6.2 does), raylib's shapes and billboards (its vertices, in its order), its generated meshes (vertex for vertex,
the same on every target), tangents, mesh buffers updated and meshes exported, render textures (kept from frame to frame), instanced meshes, rays and their collisions; VR stereo rendering as raylib's simulator draws it; raylib's
shaders, compiled as the program builds for every target, their uniforms' initializers kept; rlgl's render state (blending, the color mask, culling, depth, wire mode, viewport, scissor) and its
batch, flushed as raylib's is; automation events, recorded and played as raylib's, and raylib's random numbers for a seed. IQM, VOX and M3D models
and animations aren't read (docs/DECISIONS.md 27). Not here yet: morph targets, models drawn as points, and compressed images.

## Using it

```
-lib helix-raylib
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-raylib <checkout>/engines/raylib
```

`-D helix-raylib-files=<directory>` names where the program's shaders are as it builds (default `web`), and `-D helix-raylib-native-root=<directory>`
where a native program finds its files, relative to itself (default `../web`). `-D helix-raylib-custom-frame-control` is raylib's
`SUPPORT_CUSTOM_FRAME_CONTROL`: `EndDrawing` only draws, and the program calls `SwapScreenBuffer`, `WaitTime` and `PollInputEvents`.
`-D helix-raylib-host-warnings` warns, as the program builds, at each place its own code reaches the page or the host for what
`helix.raylib.extras` answers on every target (the URL's query, `matchMedia`, the page's storage and the rest), naming the call; it is
off by default, as a program may reach the host on purpose.

What helix-raylib adds beyond raylib's API is the package `helix.raylib.extras`, each module imported apart, and it is documented
where the API is: [docs/api/raylib-extras.md](../../docs/api/raylib-extras.md), with [docs/api/raylib.md](../../docs/api/raylib.md)
for `Raylib` itself.

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
