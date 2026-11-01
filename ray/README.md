# helix-ray

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../services/README.md) and [helix-platform](../platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.ray.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them |
| `helix.ray.Raymath` | raymath's vectors, matrices and quaternions, as `raymath.h` names them, imported apart as raylib includes it |
| `helix.ray.Rlgl` | rlgl's matrix stack, immediate drawing and render state, as `rlgl.h` names them, imported apart as raylib includes it |
| `helix.ray.Vector2`, `Vector3`, `Color`, `Texture2D`, `Camera3D`, `Model`, `Shader`, `RenderTexture2D` and the rest | raylib's structs, with their fields |

The window and frame, the keyboard, mouse, touch and gamepads, text input, shapes (with 6.2's fixes), textures (their pixels updated too), every blend mode (rlgl's custom factors too) and scissor modes, the default
font and TrueType and OpenType fonts (signed distance fields too), sounds and their aliases, waves (loaded, converted, cropped and
exported as raylib's are), music with its length, position and seeking, audio streams fed by the program or its callback, text files; images on the CPU in raylib's uncompressed pixel
formats (made, changed and drawn into as raylib's are, byte for byte, but for resizing; with 6.2's fixes), exported as PNG or QOI, and screenshots; in 3D
the camera, glTF and GLB models and their materials (as raylib 6.2 reads them: its metallic-roughness image split into roughness and metalness maps), OBJ models
and the .mtl materials they name, as raylib 6.2's `LoadOBJ` and `LoadMaterials` make them (`LoadMaterialsAsync` in place of `LoadMaterials`), skinned models and their animations (read, mixed between frames and between animations, and skinned
on the CPU or by a skinning shader, as raylib 6.2 does), raylib's shapes and billboards (its vertices, in its order), its generated meshes (vertex for vertex,
the same on every target), tangents, mesh buffers updated and meshes exported, render textures, rays and their collisions; raylib's
shaders, compiled as the program builds for every target; rlgl's render state (blending, the color mask, culling, depth, wire mode, viewport, scissor) and its
batch, flushed as raylib's is; automation events, recorded and played as raylib's, and raylib's random numbers for a seed. IQM, VOX and M3D models
and animations aren't read (docs/DECISIONS.md 27). Not here yet: morph targets, models drawn as points, and animated (GIF) or compressed images.

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

## What a model holds

raylib leaves textures and shaders to the program: its `UnloadModel` frees a model's meshes and nothing else. helix-ray counts holders
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
`ObjFile` and `MtlFile` read what the file says; helix-ray makes of it what raylib makes. Where tinyobj_loader_c's reading is broken (it
reads outside its buffers or uninitialized memory, misreads a form the OBJ and MTL formats give, or reads one name two ways), helix-ray
reads the file as the format has it, and a file that breaks the format fails to load: docs/DECISIONS.md 28 lists each.

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.
- `model`: a glTF model on a grid, the camera turning about it.
- `text`: a TrueType font loaded and drawn beside the default font.
- `images`: an image made on the CPU, a circle and text drawn into it, drawn as a texture.

## Checked against raylib

`parity/` holds suites that check helix-ray against raylib's own C: each function against one release, 6.2 where helix-ray took one of
its fixes and 5.5 elsewhere (docs/DECISIONS.md 24). `python3 tools/ray_parity.py` runs them (Linux); [parity/README.md](parity/README.md)
says what each covers and how to add a case.

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
