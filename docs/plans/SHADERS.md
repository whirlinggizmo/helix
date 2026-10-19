# Milestone 13: the shader library (design)

The design for the roadmap's milestone 13: `helix.shaders`, ready surface, screen and sprite shaders a game attaches in a line. Settled with the user on 2026-10-18: bloom works on an HDR scene (float targets, the tone mapping moved to the chain's end when a stage draws into one); a 3D outline and a silhouette are an extra pass per model; surface shaders gain skinning in this milestone, so the library works on characters; each library shader is a typed class with its parameters as fields. **Done when:** a gallery example shows each one on both targets, and its autopilot checks each one's pixels: the same within a tolerance in the browser and natively, and different from the effect turned off.

## What exists

- **Surface shaders** (decisions 69, 70, 78, 79): an app's `.glsl` with `@include_block helix_surface`, packed by `tools/pack_shader.py` into a `.hxshader` (GLSL 410 and 300 es, with `--sdl-gpu` SPIR-V, MSL and HLSL), loaded by `Shaders`, attached by `Material.setShader`, parameters by name in `ShaderParameters` (std140 offsets from the reflection), own textures from slot 5, a vertex hook in model space. They receive lights, shadows and the environment, and instance like the lit program. Not skinned (a skinned model ignores its material's shader, decision 87); they cast shadows through the framework's depth program, so a hook's movement or a `discard` doesn't reach the shadow.
- **Screen effects:** `ScreenEffect` over a `helix_screen` shader; `PostProcess` draws the scene into a screen-sized RGBA8 target, runs the effects but the last through two more, and the last into the screen pass, under the HUD. No other size, no float format, one input each.
- **Render targets:** `createRenderTarget(w, h)`, RGBA8 with an unsampleable depth, multisampled like the screen, stored top row first on every backend (decision 68). `TextureFormat` has RGBA16F for sampled textures only.
- **Tone mapping** runs inside every 3D program (`Stage3D.tonemap`, `exposure`); sprites and text aren't tone mapped.
- **2D** has no custom shader: `Batch2D` always draws the sprite program, its tint only multiplies.
- **Examples:** `shaders` (toon with rim, dissolve, water), `postprocess` (vignette, scanlines with a chromatic offset), `render-target` (a manual pixelate).
- **The autopilot** compares the final game, not pixels; screenshots are exported for people to look at.
- **The earlier frameworks** shipped the same mechanism (custom shaders and an effect chain) with example shaders, never a library: no bloom (no float targets), no FXAA, LUT, palette swap or 3D outline. Their lessons kept here: GL targets stored top-down by flipping as drawn (HeliX has it); a chain checked with two effects, as two flips cancel; the HUD kept out of the effects; on Adreno a dynamic uniform index the compiler can't bound links to nothing (select arithmetically, read the generated 300 es); pixel tests at a few points with a tolerance, not golden images.

## The library's shape

`helix.shaders`, one class per shader, its parameters as fields with their ranges, defaults that look right:

```haxe
var toon = new Toon(material);          // the material's surface shader from now on
toon.bands = 3;
var flash = new HitFlash(material);     // any surface shader's material can flash too (below)
flash.trigger(0xffffffff, .12);

var outline = new Outline(model, 0x000000ff, .02);   // an extra pass on a model
var seen = new Silhouette(model, 0x3fa9ffff);         // where it's hidden behind something

post.add(new Bloom());                  // PostProcess's chain, in order
post.add(new Vignette(.4));
post.add(new Fxaa());

sprite.effect = new SpriteOutline(0xff8800ff, 2);
```

- **Packed into the program, not loaded.** A library shader's `.glsl` lives in `src/helix/shaders/` and is packed at build time (the same `pack_shader.py`, all backends) into generated Haxe that embeds its `.hxshader` in the class that uses it. So `new Toon(material)` works at once with no load and no asset, dead-code elimination drops the shaders a game doesn't use, and the dev loop repacks one when its source changes (a hot reload, as an app shader's).
- **Parameters** are fields over the same `ShaderParameters` (a field set writes its member); colors `0xRRGGBBAA` as everywhere, ranges clamped and documented. A game's own shader stays as it is: `.hxshader`, `Shaders.load`, parameters by name.
- **Composition**, the one rule: a material has one surface shader. Hit flash and rim are small enough to be in every library surface shader (a flash color and amount, a rim color and power, both off by default), so `HitFlash` and `Rim` attach to a material whatever its shader, and on a material with no surface shader they use the stage's lit one with the same two terms. Outline and silhouette are passes, not shaders, so they stack with any of them.

## Surface shaders

- **Toon** (bands, a shadow color, the rim), **Rim**, **HitFlash** (`trigger(color, seconds)`, or `amount` held), **Dissolve** (amount, edge color and width; a noise texture generated once by the library, or the game's own), **Water** (the vertex hook's waves, depth colors, Fresnel, glints): the `shaders` example's three moved into the library, that example keeping one shader of its own to show how one is written.
- **Skinned:** the surface vertex stage gains a skinned variant (joints and weights, the joint texture `Stage3D` already fills), packed beside the static one, so every surface shader draws on a skinned model.
- **Shadows that match:** a surface shader with a vertex hook or a `discard` gets a caster variant (the depth program with the hook and the shader's alpha test), so a dissolving model's shadow dissolves and water's waves move their shadow. A shader without either keeps the framework's caster.
- **Passes:** a model gets extra passes drawn after the stage's opaque pass. **Outline**: the model again, pushed out along its normals by a width in world units (or pixels, held by the distance), front faces culled, flat color, depth tested. **Silhouette**: the model again where it's behind something (depth test greater, no depth write), flat color with an alpha. Both instance and skin like the model.

## Screen effects and HDR

- **Float targets:** `createRenderTarget(w, h, format)` with RGBA8 and RGBA16F (WebGL2 through `EXT_color_buffer_float`; asked, so `canRenderFloat()` says whether), and targets without depth or multisampling for the chain's intermediates.
- **An HDR scene:** `PostProcess` opens the scene in RGBA16F when the chain has an effect that wants HDR (Bloom, Tonemap) and the platform can; a `Stage3D` drawing into an HDR target writes linear light after the exposure and skips its tone mapping, and the chain ends with the tone mapping (`Tonemap`, added for you when the chain asks for HDR, using the stage's mode). Without float targets the chain runs as today, 8-bit, Bloom thresholding the tone-mapped frame.
- **Sizes:** an effect can ask for intermediates at a fraction of the screen and read more than one input (Bloom's downsample chain); `PostProcess.add` and `remove` replace passing the array each frame, the order kept, each effect's `enabled` as today.
- **The effects:** **Bloom** (threshold with a soft knee, a downsample chain of half sizes with a 13-tap filter, upsampled with a tent filter and added, intensity), **Tonemap**, **Fxaa** (FXAA 3.11 quality, on the tone-mapped frame), **Blur** (separable Gaussian at a size, radius), **Vignette**, **ColorLut** (a 32-cube LUT as a 1024 x 32 strip; `ColorLut.identity()` to start from, a game's PNG for a grade), **Crt** (scanlines, a curvature, a mask, the flicker), **ChromaticAberration**, **Pixelate** (a cell size in pixels).
- The HUD stays out: it's drawn after `present()`, as now.

## Sprite shaders

- A third kind, `helix_sprite`, packed like the others with the sprite vertex stage (the sprite's position, UV, tint; its texture at slot 0, the region's UV and a 0-to-1 UV across the quad).
- `Sprite2D.effect` (and `Batch2D.draw` taking one): runs in a batch split where the effect changes, as they split by texture now; a sprite without one draws as today.
- **SpriteOutline** (color, width in texels, 8 taps), **SpriteFlash** (`trigger(color, seconds)`), **SpriteDissolve**, **PaletteSwap** (the sprite's red channel indexes a palette texture's row: a game's palette PNG, a row per variant, `row` chooses).

## Checking pixels

- **The autopilot gains `sample`**: `{"op": "sample", "name": "bloom", "points": [[x, y], ...]}` reads the frame's pixels at points given in the design's units and puts them into the published result under the name. `tools/example.py` compares samples between the browser and native within a tolerance (3 per channel by default, more where a script says, as bloom and FXAA differ by GPU), besides the final game as now.
- **The gallery's script** shows each effect in turn over the same still frame (time held), samples the points where the effect shows, and asserts them unlike the same points with the effect off (by at least a set amount), so a shader drawing nothing fails. Chains are checked with two effects at least.
- **Unit tests** over the packing (each library shader packs for every backend, its parameters' offsets as its fields write them) and `PostProcess`'s plan (which targets at which sizes and formats for a chain).

## The example

`shader-gallery`: one still scene with a model, a skinned character and a row of sprites, a menu (the `ui` module) listing every library shader by kind, each turned on alone with its parameters shown and adjustable, and outline plus silhouette with a wall in front. Its autopilot visits each and samples, in Chrome and natively under sokol and SDL3, and SDL_GPU's build is drawn on a real GPU at the checkpoint.

## Order of work

1. **Foundations:** float and depthless targets on the three adapters; `PostProcess.add`, sizes and inputs; the HDR scene and `Tonemap`; the library's packing into generated Haxe with hot reload; the autopilot's `sample` and the tolerance comparison.
2. **Surface:** skinned surface shaders and matching casters; Toon, Rim, HitFlash, Dissolve, Water; Outline and Silhouette passes.
3. **Screen:** Bloom, Fxaa, Blur, Vignette, ColorLut, Crt, ChromaticAberration, Pixelate.
4. **Sprites:** the `helix_sprite` kind, `Sprite2D.effect`, the four sprite shaders.
5. **The gallery** and its autopilot; the `shaders` and `postprocess` examples trimmed to writing one's own; decision, HISTORY, roadmap.

Each phase is checked in the browser as it goes and natively at its end (the type check, the unit tests, the examples built under the three profiles), the full checkpoint and one push at the milestone's end.
