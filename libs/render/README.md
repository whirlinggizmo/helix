# helix-render

Drawing over [helix-platform](../platform/README.md)'s graphics and [helix-services](../services/README.md)' shaders: 2D and 3D
batches, draw lists, text, unlit and lit materials, lights, shadows, environment maps, points, views for stereo and post-processing.
It is what an engine layer draws with: helix-raylib (raylib's API) and a three.js layer are the two it is judged by.

| Package | What |
|---|---|
| `helix.render` | `Renderer`: textures, render targets, cube textures, meshes, models and fonts on the GPU, and the frame, recorded pass by pass and drawn at its end. `Batch2D` and `DrawList2D`: sprites, shapes and text in a camera's units or the viewport's pixels, batched into as few GPU draws as their order allows. `Batch3D` and `DrawList3D`: meshes and models with their `Material3D`s, instanced and skinned, and lines, points, triangles, billboards, sprites, shapes and text, through a camera or several `View3D`s at once. `GpuFont2D` and `TextLayout2D`: text measured, wrapped and aligned. Lights, `Environment3D`, `Fog3D`. |
| `helix.render.effects` | `PostProcess`: a linear frame brought to the screen by the renderer's exposure and tone mapping, with bloom, grading, FXAA or a program's own pass between. |

It depends on helix-services (images, fonts, models and shaders), helix-platform, helix-formats, helix-geometry, helix-math and
helix-log.

## Using it

```
-lib helix-render
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-render <checkout>/libs/render
```

## Set aside

helix-render was built in stages from its agreed API (docs/DECISIONS.md, 34) through stage 3, and is set aside there (DECISIONS 53):
no engine draws on it, since helix-raylib's rebuild on it failed its size and speed gates, and its later stages wait for an engine that
needs them. It stays on main with its examples, tests and checks. Every member of a later stage throws, naming its stage.

1. **Done:** the renderer and its recorded frame (target passes, copy on write, clears in order, viewport and scissor), textures,
   render targets and cube textures, `Batch2D` and `DrawList2D` (sprites, shapes, text, draw lists, culling), fonts and text layout,
   and `Batch3D`'s unlit work: views, the batch draws (lines, points, triangles, billboards, sprites, shapes and text in a plane),
   unlit meshes and models (tints, `MeshState3D`, instancing, skinning by a bone texture, polygon modes), `DrawList3D`, and the
   compile macros for a program's own shaders.
2. **Done:** lit materials and lights: `Lambert`, `Phong` and `MetallicRoughness` (with clearcoat, sheen, specular and ior) shaded by
   `DirectionalLight3D`, `PointLight3D`, `SpotLight3D` and `HemisphereLight3D` in three.js's units and formulas, each draw by the 8
   lights reaching its box most, and by the ambient light; normal, metallic-roughness, occlusion, emissive and light maps; flat
   shading; `lighting.glsl` and `material.glsl` for a program's own lit shader; and a mesh drawn as points larger than a pixel. A
   program giving no light links none of it (`Light3D` says what links it), and a lit material there is drawn black.
3. Shadows.
4. Environment maps and the background.
5. Post-processing.
6. Fog.
7. Morph targets.

Waiting on the libraries below (docs/ROADMAP.md): `TargetDepth.Texture` until the platform samples depth; the second texture
coordinates (`occlusionTexture` and `lightTexture` read the first set until helix-geometry's `Mesh3D` holds a second).

## A frame

```haxe
var renderer = new Renderer(graphics);
var batch = new Batch2D(renderer);
var ship = renderer.createTexture(shipImage);
// each frame:
renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101820);
batch.begin();
batch.drawTexture(ship, 100, 80);
batch.end();
renderer.endFrame();
graphics.present();
```

A frame is recorded as it is drawn and reaches the GPU at `endFrame`: the shaders built, then each render target's pass in the order
begun, then the screen's. A draw that reads a render target reads it as it was at that point of the frame; a target drawn into again
after something read it is copied on write.

## Shaders

A program's own shader is helix-services' (`Shader`, `ShaderValues`), compiled while the program builds by the type that owns its
vertex stage: `Batch2D.compileShader` and `compileShaderStages` for sprites, shapes and text, `Batch3D`'s for the batch draws,
`Material3D`'s for meshes, `ScreenEffect`'s for a screen pass, and `Batch3D.makeShaderExpr` for a layer's own macro. Each type's doc
comment lists the names it fills; a shader reads what it declares. The includes helix-render gives:

| Include | What |
|---|---|
| `<helix/render/shaders/view.glsl>` | The `View` block: a view's matrices, its viewport, the target's kind, exposure, tone mapping and fog (`View3D`). |
| `<helix/render/shaders/clip.glsl>` | The clip planes, `clipPlanes` and `clipPlaneCount` (`Batch3D.clipPlanes`), for a program's own stage that reads them; declared nowhere else. |
| `<helix/render/shaders/color.glsl>` | `decodeSrgb`, `encodeSrgb`, `applyToneMapping`, `applyFog`, `encodeColor`, `writeColor` (`View3D`). |
| `<helix/render/shaders/batch.glsl>` | A batch draw's attributes, uniforms and outputs, and `placeBatchVertex` (`Batch3D`). |
| `<helix/render/shaders/mesh.glsl>` | A mesh's attributes, the per-draw uniforms and outputs, and `placeVertex`: skinned and instanced (`Material3D`). |
| `<helix/render/shaders/lighting.glsl>` | The `Lighting` block, the draw's lights and the shadings (`Batch3D`). |
| `<helix/render/shaders/material.glsl>` | A material's names, `readMaterialSurface`, `shadeMaterial`, `writeMaterialColor` (`Material3D`). |

## Colors

What a target holds is its format's: RGBA8 and the screen hold sRGB, RGBA16F holds linear light. 2D draws as stored into sRGB and
decodes into linear. 3D works in linear light and encodes for the target; the batch draws and an `Unlit` material with `colorSpace`
Srgb multiply as stored, as raylib does, so its colors pass through.

## Examples

Each example in `examples/` shows one thing, and builds from the hxml files beside it, as the platform's do (`-D sdl_gpu` and
`build-native-gpu.hxml` draw with SDL_GPU):

- `sprites`: sprites split from a sheet and flipped, shapes from a white texel on the same sheet in one GPU draw with them, a wrapped
  text panel recorded once as a `DrawList2D`, and a measured label, under a following camera.
- `targets`: a render target drawn into, read, and drawn into again in one frame (copy on write), with a clear recorded mid-batch, a
  viewport and a scissor.
- `unlit`: `Batch3D`'s unlit work: an instanced mesh with per-copy colors, a model drawn with a tint and a `MeshState3D`, lines,
  points of one pixel and large ones, a grid recorded as a `DrawList3D`, and text in a plane.
- `lit`: lit materials and lights: spheres shaded Lambert, Phong and MetallicRoughness (metallic, and with a clear coat) under a sun, a
  hemisphere light, a point light and a spot light, and a cube lit only by its emissive light.

Its tests are in `tests/`: the CPU-side work (layout, culling, batching, copy on write) on every target (`helix.py test`), and pixel
checks drawn on each backend (`tools/render_checks.py`).

The API reference is [api/](api/README.md), one page per package.
