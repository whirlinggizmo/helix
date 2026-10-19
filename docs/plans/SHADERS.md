# Milestone 13: the shader library (design)

The design for the roadmap's milestone 13: `helix.shaders`, ready surface, screen and sprite shaders a game attaches in a line. Settled with the user on 2026-10-18: bloom works on an HDR scene (float targets, the tone mapping moved to the chain's end when a stage draws into one); a 3D outline and a silhouette are an extra pass per model; surface shaders gain skinning in this milestone, so the library works on characters; each library shader is a typed class with its parameters as fields. **Done when:** a gallery example shows each one on both targets, and its autopilot checks each one's pixels: the same within a tolerance in the browser and natively, and different from the effect turned off.

## What exists

- **Surface shaders** (decisions 69, 70, 78, 79): an app's `.glsl` with `@include_block helix_surface`, packed by `tools/pack_shader.py` into a `.hxshader` (GLSL 410 and 300 es, with `--sdl-gpu` SPIR-V, MSL and HLSL), loaded by `Shaders`, attached by `Material.setShader`, parameters by name in `ShaderParameters` (std140 offsets from the reflection), own textures from slot 5, a vertex hook in model space. They receive lights, shadows and the environment, and instance like the lit program. Not skinned (a skinned model ignores its material's shader, decision 87); they cast shadows through the framework's depth program, so a hook's movement or a `discard` doesn't reach the shadow. (Phase 2 changed both: below.)
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
- **Composition**, the one rule: a material has one surface shader. Hit flash and rim are small enough to be in every surface shader (a flash color and amount, a rim color and power, both off by default), so `HitFlash` and `Rim` attach to a material whatever its shader. As built (phase 2): they are the material's own terms, in the stage's fragment block beside its emission, which the lit program applies and every surface shader's `helix_output` applies (an app's shader too, with no change to it); `HitFlash` and `Rim` are views of the material's. Outline and silhouette are passes, not shaders, so they stack with any of them.

## Surface shaders

- **Toon** (bands, a shadow color, the rim), **Rim**, **HitFlash** (`trigger(color, seconds)`, or `amount` held), **Dissolve** (amount, edge color and width; a noise texture generated once by the library, or the game's own), **Water** (the vertex hook's waves, depth colors, Fresnel, glints): the `shaders` example's three moved into the library, that example keeping one shader of its own to show how one is written.
- **Skinned:** the surface vertex stage gains a skinned variant (joints and weights, the joint texture `Stage3D` already fills), packed beside the static one, so every surface shader draws on a skinned model.
- **Shadows that match:** a surface shader with a vertex hook or a `discard` gets a caster variant (the depth program with the hook and the shader's alpha test), so a dissolving model's shadow dissolves and water's waves move their shadow. A shader without either keeps the framework's caster.
- **Passes:** a model gets extra passes drawn after the stage's opaque pass. **Outline**: the model again, pushed out along its normals by a width in world units (or pixels, held by the distance), front faces culled, flat color, depth tested. **Silhouette**: the model again where it's behind something (depth test greater, no depth write), flat color with an alpha. Both instance and skin like the model.

**Phase 2 as built:**

- **Variants in the `.hxshader`** (format 2): a surface shader packs its program and `skinned` beside it; one with a vertex hook or a `discard` (found in its source, comments aside) also packs `caster` and `skinnedCaster`. All are programs of one sokol-shdc run over the same parameters; `Shader.skinned` and `Shader.caster` are Shaders of their own (`shader.skinned.caster` the skinned caster), replaced together on a reload. The skinned vertex stage moves each vertex by its joints (the framework's `skinning.glsl`, included) before the app's hook, so the hook works in the model's space as posed. The joints are texture slot 5, so an app's own surface textures start at 6.
- **The caster's fragment stage is the app's own**, over a copy of the surface block whose `helix_output` writes nothing: its discards cut the shadow exactly, and the GPU's compiler drops the shading nothing reads. The reflection still lists the shading's textures, which the stage binds, the shadow slot always the one-texel stand-in, never the map being drawn. The casters are drawn from the lit models' records (the hook and the fragment stage read them), a run alike in program, material and mesh one draw.
- **Draw order:** the opaque models without a silhouette, the opaque sprites, the silhouettes, the opaque models with a silhouette, every outline, then the see-through. The silhouetted models after their silhouettes, so a model's own parts (hair over a head, clothes over a body) never show it through itself; a depth offset was tried first and showed the layered character through itself. The passes are framework programs (`flat3d`, `skinnedflat3d`) reading the draw's own instance records; `PipelineDesc` gained `DepthTest` (`Off`, `LessEqual`, `Greater`) and `CullFace` (`None`, `Back`, `Front`), which each adapter maps to its API.
- **The outline's width is in world units** only; pixels held by the distance are left until a game asks.
- **Time:** `HitFlash.trigger(color, seconds)` fades over the stage's time (`Stage3D.time`, as particles advance) from the first draw after it; `amount` holds one. The flash is mixed over the light after the exposure, so the tone mapping (or an HDR chain's) applies to it as to the light.
- **Dissolve** shades as the stage does (`helix_shade`) and adds `edgeIntensity` and `scale` to the design's fields; its default noise (`ShaderLibrary.getNoise`) is 128 texels a side, three octaves of value noise from an integer hash, its values spread evenly so the amount is the share cut, the same texels on every target. **Water** colors deep where it's looked into and shallow toward grazing (its "depth colors"), reflecting the stage's environment where there is one. **Toon**'s rim is the material's `Rim`.

## Screen effects and HDR

- **Float targets:** `createRenderTarget(w, h, format)` with RGBA8 and RGBA16F (WebGL2 through `EXT_color_buffer_float`; asked, so `canRender(format)` says whether), and targets without depth or multisampling for the chain's intermediates.
- **An HDR scene:** `PostProcess` opens the scene in RGBA16F when the chain has an effect that wants HDR (Bloom, Tonemap) and the platform can; a `Stage3D` drawing into an HDR target writes its light after the exposure, untone-mapped, as sRGB values running past 1 (so sprites, particles and text blend into it as into the screen; an effect wanting linear light decodes), and the tone mapping (`Tonemap`, added for you after the last effect wanting HDR, using the stage's mode) follows. Without float targets the chain runs as today, 8-bit, Bloom thresholding the tone-mapped frame.
- **Sizes:** an effect can ask for intermediates at a fraction of the screen and read more than one input (Bloom's downsample chain); `PostProcess.add` and `remove` replace passing the array each frame, the order kept, each effect's `enabled` as today.
- **The effects:** **Bloom** (threshold with a soft knee, a downsample chain of half sizes with a 13-tap filter, upsampled with a tent filter and added, intensity), **Tonemap**, **Fxaa** (FXAA 3.11 quality, on the tone-mapped frame), **Blur** (separable Gaussian at a size, radius), **Vignette**, **ColorLut** (a 32-cube LUT as a 1024 x 32 strip; `ColorLut.identity()` to start from, a game's PNG for a grade), **Crt** (scanlines, a curvature, a mask, the flicker), **ChromaticAberration**, **Pixelate** (a cell size in pixels).
- The HUD stays out: it's drawn after `present()`, as now.

**Phase 3 as built:**

- **Classes over `LibraryScreenEffect`** (a `ScreenEffect` whose shader is the library's, its fields writing its parameters held to their ranges; `Tonemap` moved onto it): `Bloom`, `Fxaa`, `Blur`, `Vignette`, `ColorLut`, `Crt`, `ChromaticAberration`, `Pixelate`.
- **The intermediates API needed no change.** Bloom asks for its chain as fractions (`.5` to `1/64` going down, `.5` to `1/32` coming up: eleven textures), and reading one while drawing the next is `drawInto(target, source)` with its second input through its own texture, set before each step. Coming up needs a texture of its own per level (a target pass clears, so a level can't be added onto in place), so the chain is a level down and a level up at each size but the smallest.
- **Bloom** is one program, its step chosen by a uniform (uniform branches only): the first step down decodes, thresholds with Karis's soft knee and filters with the 13 taps weighting each group of four by `1 / (1 + luma)` (Karis's average, against fireflies); the further steps down filter alone; each step up is the level down at its size plus the one below through a 3 x 3 tent; the last pass adds the first level up to the frame times `intensity / LEVELS` (the levels are summed coming up) and encodes it again. `LEVELS` is 6. Where the frame reaching it is 8-bit (no half floats, or after a `Tonemap` of the chain's own, as the example's H key does), `toneMappedThreshold` (.8 of linear light) replaces `threshold` (1): it reads the format of its source.
- **Fxaa** is FXAA 3.11's quality version at preset 12 (five steps: 1, 1.5, 2, 4, 12 texels), its steps written out as calls, luma from the frame's sRGB values by Rec. 601. **Blur** is two passes of 17 fixed-weight taps (sigma a third of the radius), across into one intermediate at `resolution` of the frame, then down over the frame from it. **ColorLut** reads two squares half a texel inside their edges and mixes by blue; `ColorLut.identity()` is the strip's texels, and the library keeps one identity texture a GPU (`ShaderLibrary.getIdentityLut`) for a `ColorLut` without a grade. **Crt**'s grille picks its channel arithmetically (`clamp(1 - abs(vec3(0, 1, 2) - column))`).
- **The `postprocess` example** chains them in the order a game would (Bloom, Fxaa, Blur, Pixelate, ColorLut, its own Sepia, ChromaticAberration, Crt, Vignette), two lamps glowing far past white for the bloom, and a teal-and-orange grade made from the identity strip in code. Its autopilot samples the chain (Bloom, Fxaa, Vignette in an HDR scene), Bloom next to the lamps against Bloom off (Fxaa and Vignette left: a chain of two, 8-bit), every effect alone against all off, and Bloom over a tone-mapped frame against none.
- **Found:** an HDR scene's clear color is tone mapped with the light (the chain's `Tonemap` sees it as light), while an 8-bit scene shows it as given, so a background of clear color alone darkens a little when an effect wanting HDR turns on (Neutral's toe: 0x14161c becomes about 0x01040f). A stage's own background is tone mapped either way. Left as it is; a game drawing a sky doesn't see it.

## Sprite shaders

- A third kind, `helix_sprite`, packed like the others with the sprite vertex stage (the sprite's position, UV, tint; its texture at slot 0, the region's UV and a 0-to-1 UV across the quad).
- `Sprite2D.effect` (and `Batch2D.draw` taking one): runs in a batch split where the effect changes, as they split by texture now; a sprite without one draws as today.
- **SpriteOutline** (color, width in texels, 8 taps), **SpriteFlash** (`trigger(color, seconds)`), **SpriteDissolve**, **PaletteSwap** (the sprite's red channel indexes a palette texture's row: a game's palette PNG, a row per variant, `row` chooses).

**Phase 4 as built:**

- **The kind is a framework program's.** `src/helix/graphics/shaders/effect2d.glsl` holds the sprite kind's vertex stage and its `helix_sprite` block, and a program of its own (drawing as `sprite2d` does) whose generated `Effect2DLayout` is the vertices `Batch2D` packs: `sprite2d`'s position, UV and tint, and each vertex its sprite's region (`u0, v0, u1, v1`). `pack_shader.py` takes the vertex stage and the block from that file, so the layout and the stage can't drift. The 0-to-1 UV across the quad is worked out in the fragment stage from the UV and the region (`helix_quad_uv()`), not carried; for a nine-slice it runs across the whole region, every slice carrying it. The texel size and the time are the framework's block 1 (`helix_sprite_info`: the texture's size, the batch's time). An app's own textures start at slot 1.
- **The block** (`helix_uv`, `helix_region`, `helix_quad_uv`, `helix_texture_size`, `helix_texel_size`, `helix_time`, `helix_tint`, `helix_texel_at`, `helix_sprite_color`, `helix_output`) adds `helix_region_texel_at(uv)`: transparent outside the region and read no nearer its edge than half a texel, so an outline's taps never bleed in a neighbor from an atlas. `helix_sprite_color()` is the framework's sprite (texel times tint, distance-field text as `sprite2d` draws it), so an effect over text works.
- **`helix.graphics.SpriteEffect`** is the kind's object, as `ScreenEffect` is the screen's: a `Shader` of kind sprite and its `ShaderParameters`; an app's `.hxshader` (`Shaders.load`) becomes one with `new SpriteEffect(shader)`, the library's classes extend it. `prepare(time)` brings an effect to the batch's time before each draw with it (`SpriteFlash`'s fade).
- **Shared, not per sprite.** An effect's parameters are its own, read as the batch ends: the sprites given one effect draw with its values, and those drawn one after another with one effect and texture are one draw. A sprite wanting values of its own (its own flash, another palette row) gets an effect of its own, a draw of its own. Per-sprite values in the vertices were left out: no library effect needs more than the tint and region there.
- **`Batch2D.effect`** is a property of the batch's state, as `camera` is, rather than a parameter of `sprite`: what is drawn under it (sprites, nine-slices, text, shapes) goes through it, and a run closes where it changes. Its vertices go into an upload of their own (`Effect2DLayout`, grown as needed), so a frame without effects uploads and draws exactly as before. `Batch2D.time` is the clock effects see; `Stage2D.draw` sets it to the stage's time, sets each node's `effect` (a `Sprite2D`'s, none for the rest) and leaves the batch without one.
- **The four:** `SpriteOutline` (color, width 0 to 32 texels; eight taps at the width, the diagonals at the same distance; under the sprite's own texels, faded with its tint's alpha), `SpriteFlash` (`trigger(color, seconds)` fading over the batch's time from its first draw, or `amount` held, as `HitFlash`), `SpriteDissolve` (amount, edge color and width, scale; the library's noise laid across the region, `discard` below the threshold), `PaletteSwap` (palette texture and row; the sprite and the palette read by `texelFetch` at exact texels whatever their sampling, the sprite's within its region, so an index never blends with a neighbor).
- **The `sprite2d` example** gains the four (an outline shared by the sheet and the spin, a dissolve on the tint, a flash on the flip, a creature of indexed pixels made in code with a three-row palette) and an autopilot holding the time and sampling each against it off.

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
