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

## What helix-raylib adds

`Raylib`, `Raymath`, `Rlgl` and `Raygui` are raylib 5.5's API and nothing more (docs/DECISIONS.md 24, 38). What helix-raylib adds is in the
package `helix.raylib.extras`, each module imported apart:

| Module | What it holds |
|---|---|
| `Window` | the window's requests (`SetWindowSizeAsync`, `SetWindowPositionAsync`, `MaximizeWindowAsync` and the rest), `ToggleFullscreenAsync`, `ToggleBorderlessWindowedAsync`, `DisableCursorAsync`, `EnableCursorAsync`, the clipboard (`GetClipboardTextAsync`, `SetClipboardTextAsync`, `GetClipboardImageAsync`) and `TakeScreenshotAsync` |
| `Files` | the file reads, writes and questions (`LoadFileTextAsync`, `SaveFileTextAsync`, `FileExistsAsync`, `LoadDirectoryFilesAsync` and the rest), `ExportDataAsCodeAsync` and the automation event lists' files |
| `Textures` | the image and texture loads (`LoadTextureAsync`, `LoadImageAsync`, `LoadImageAnimAsync` and the rest), `ExportImageAsync` and `ExportImageAsCodeAsync` |
| `Text` | the font loads (`LoadFontAsync`, `LoadFontExAsync`, `LoadFontFromMemoryAsync`, `LoadFontDataAsync`) and `ExportFontAsCodeAsync` |
| `Models` | `LoadModelAsync`, `LoadModelAnimationsAsync`, `LoadMaterialsAsync`, `ExportMeshAsync` and `ExportMeshAsCodeAsync` |
| `Audio` | `LoadSoundAsync`, `LoadWaveAsync`, `LoadWaveFromMemoryAsync`, `LoadMusicStreamAsync`, `ExportWaveAsync` and `ExportWaveAsCodeAsync` |
| `Gui` | raygui's file loads: `GuiLoadStyleAsync` and `GuiLoadIconsAsync` |
| `Device` | what a game needs from the device and the page that raylib has no call for: `GetWindowSafeArea`, `GetRunOption`, `IsPlatformWeb`, `GetPlatformOS`, `IsTouchScreenAvailable`, `IsFinePointerAvailable`, `IsWindowCloseable`, `IsFullscreenAvailable`, `SetScreenOrientationAsync`, `GetScreenOrientation`, and the tilt (`EnableTiltAsync`, `GetTilt`, `SetTiltRange`, `CalibrateTilt`, `DisableTilt`) |

The async versions of raylib's calls are in one module for each raylib module, named for it: rtextures' in `Textures`, rtext's in
`Text`, rmodels' in `Models`, raudio's in `Audio`. rcore's alone would be some 50 calls, so it is split three ways: `Window`, `Files`
and `Device`. A feature helix-raylib adds on its own gets a module of its own, never a place in an existing one. Each module is
generated by `tools/gen_raylib.py` from its own section in `src/helix/raylib/modules/`, is kept under 300 lines, and holds no static
variable with an initializer, so a program links only the functions it calls.

raylib's call a page can't wait for doesn't compile, naming the one that replaces it, its module and its import ("See
LoadTextureAsync(...) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)"); so do emscripten's calls raylib's web
programs make (`emscripten_set_main_loop` and the rest), saying what to write instead. A program that reaches the page or the host
itself for what `Device`, `Files` or `Window` answers (the URL's query, `Sys.getEnv`, `matchMedia`, `maxTouchPoints`,
`screen.orientation`, `env(safe-area-inset-*)`, `deviceorientation`, the page's storage and fullscreen) builds with a warning at each
place, naming the call and its module's import, when it is built with `-D helix-raylib-host-warnings`; it is off by default, since a
program may reach the host on purpose.

## Skinned models

`UpdateModelAnimation` and `UpdateModelAnimationEx` pose a model, and each draw after draws it in that pose, so one model can be posed and
drawn many times in a frame. Under raylib's default shader a model is skinned on the GPU. A shader of the program's own skins on the GPU
when its vertex stage includes `<helix/raylib/shaders/skinning.glsl>`, or declares raylib's `skinning.vs` inputs (`vertexBoneIds`,
`vertexBoneWeights`, `uniform mat4 boneMatrices[N]`); any other is skinned on the CPU, every vertex each call. The include's head comment
says what it declares, with an example: `helixSkin()` is the vertex's skin matrix, and `helixSkinNormal(normal)` moves a normal as raylib
does.

```glsl
#version 330
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
uniform mat4 mvp;
void main() {
    gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
}
```

## What a model holds

raylib leaves textures and shaders to the program: its `UnloadModel` frees a model's meshes and nothing else. helix-raylib counts holders
instead (docs/DECISIONS.md 25), so nothing a program drops leaks and nothing it still uses is freed. A texture is held by the program from
its load until `UnloadTexture`, and by each material map given it; a shader by the program from `LoadShader` until `UnloadShader`, and by
each material given it; a material by the program from `LoadMaterialDefault` until `UnloadMaterial`, and by each model whose `materials`
holds it; a mesh likewise, through `UnloadMesh` and `meshes`. `LoadModelFromMesh` takes over the program's hold on its mesh. A file loaded
more than once shares its textures and GPU buffers, each load holding them, until its last load is unloaded. raylib's code runs as it is:
`model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture`, then `UnloadTexture(texture)` and `UnloadModel(model)`, frees the
texture once, at `UnloadModel`. Where it differs: a texture or shader copied out of a material and used after its model is unloaded is
freed (raylib's leaks and still works), a material or mesh shared between models works (raylib's C frees it twice), and a texture or
shader given to a material and never unloaded stays while the program runs.

## OBJ models

`LoadModelAsync` reads an OBJ file, and `LoadMaterialsAsync` an .mtl file, as raylib 6.2's `LoadOBJ` and raylib's `LoadMaterials` read
them with tinyobj_loader_c, its quirks kept, and the `obj_62` and `obj` parity suites hold them to raylib's own C. helix-formats'
`ObjFile` and `MtlFile` read what the file says; helix-raylib makes of it what raylib makes. Where tinyobj_loader_c's reading is broken (it
reads outside its buffers or uninitialized memory, misreads a form the OBJ and MTL formats give, or reads one name two ways), helix-raylib
reads the file as the format has it, and a file that breaks the format fails to load: docs/DECISIONS.md 28 lists each.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `text`: a TrueType font loaded and drawn beside the default font.
- `images`: an image made on the CPU, a circle and text drawn into it, drawn as a texture.

## Checked against raylib

`parity/` holds suites that check helix-raylib against raylib's own C: each function against one release, 6.2 where helix-raylib took one of
its fixes and 5.5 elsewhere (docs/DECISIONS.md 24). `python3 tools/raylib_parity.py` runs them (Linux); [parity/README.md](parity/README.md)
says what each covers and how to add a case.

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
