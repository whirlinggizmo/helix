# Effects inventory

Visual effects, shaders and particle systems found in the earlier projects, listed as candidates for helix's libraries. Nothing here
is committed to. Before any entry is built, it is judged by what other engines provide (Godot, Unity, three.js, raylib's examples) and
whether a program using the library directly would want it.

"Where it was" paths are relative to the `whirlinggizmo/` projects directory. `helix/` is HeliX, `wgrender-c/` the earlier C framework,
`gamejams/` the two games. "In helix already?" paths are relative to this repository. Where a source did not say, the cell says
"unclear".

Fit labels:

- **render, built in**: part of helix-render's batches or materials.
- **render, include**: a GLSL include a program's own shader pulls in.
- **render, effect class**: a class beside `FxaaEffect` in `libs/render/src/helix/render/effects/`.
- **raylib, shader or example**: a shader in helix-raylib's shaders (a directory that does not exist yet) or a helix-raylib example.
- **example only**: a small program in a library's `examples/`, not a library member.

## Particles and emitters

Both HeliX and the C framework drove particles the same way. The CPU writes one birth record per particle when it is born (position,
birth time, velocity, life, size scale, spin, a random number). The GPU works out where the particle is from its age, one instanced quad
a particle, one draw an emitter. `wgrender-c/` is where it started and HeliX's `Emitter` is its port.

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Birth-record GPU emitter, 3D | `wgrender-c/include/wgr_emitter3d.h`, `wgrender-c/src/wgr_emitter.c`, `helix/src/helix/particle/Emitter.hx`, `helix/src/helix/graphics/shaders/particle3d.glsl` | Many camera-facing quads from one texture, placed on the GPU from age, up to 65,536 alive with newer ones replacing the oldest. | render, built in (an emitter class over instanced billboards), or a library of its own: unclear | no |
| Birth-record emitter, 2D | `wgrender-c/include/wgr_emitter2d.h`, `helix/src/helix/render2d/Particles2D.hx` | The same emitter in stage pixels, drawn with the 2D members in layer order. | render, built in, drawn through `Batch2D` | no |
| Emission: rate, bursts, prewarm | `helix/src/helix/particle/Emitter.hx` (`rate`, `burst`, `prewarm`, `emitting`) | A steady rate in particles a second, bursts of N, a switch that lets the live ones finish, and prewarm that starts a steady emitter as if it had run for some seconds (smoke already rising). | with the emitter | no |
| Spawn shape and velocity cone | `helix/src/helix/particle/Emitter.hx` (`setSpawnBox`, `setSpawnSphere`, `setVelocity`) | Born in a box or evenly in a sphere, moving at a speed along a direction turned up to `spread` radians off it, with a speed variance. | with the emitter | no |
| Gravity, drag, inherited velocity | `helix/src/helix/particle/Emitter.hx`, `particle3d.glsl` | Gravity as an acceleration, drag that slows in proportion to speed (so gravity over drag is the terminal speed), and a fraction of the emitter's own movement taken at birth. | with the emitter | no |
| Size and color over life as keyed curves | `wgrender-c/include/wgr_emitter3d.h` (`add_size_key`, `add_color_key`), `particle3d.glsl` | Up to 8 keys each over 0..1 of the life, straight lines between them, alpha in the color so a key can fade. Curve keys are read from two vec4s and one chosen arithmetically, because an indexed uniform array failed to link on Adreno's GLES driver. | with the emitter. Keep the Adreno workaround. | no |
| Palette tint per particle | `helix/src/helix/particle/Emitter.hx` (`addPaletteColor`) | Up to 8 colors, one picked at birth by each particle, so one emitter makes confetti of many colors. | with the emitter | no |
| Spin and flipbook | `helix/src/helix/particle/Emitter.hx` (`setSpin`, `setFrames`), `wgrender-c/examples/particles.c` | Random spin between two rates from a random angle, and an atlas split into a grid played once over the life (explosions) or looped from a random frame (flames). | with the emitter | no |
| Stretch along motion | `helix/src/helix/particle/Emitter.hx` (`stretch`), `particle3d.glsl` | The quad's top points along the velocity on screen and is as long as the distance moved in some seconds, trailing behind (sparks, rain, streaks). Stretched particles do not spin. | with the emitter | no |
| Alpha mode per emitter | `helix/src/helix/particle/Emitter.hx` (`setAlphaMode`) | Added (glows, sparks, fire), blended (smoke, rain), or cutoff, set for the whole emitter. | with the emitter. `Material3D.blend` exists. | partly: `libs/render/src/helix/render/Material3D.hx` |
| Seeded determinism | `helix/src/helix/particle/Emitter.hx` (`seed`) | The same seed and settings give the same particles. | with the emitter | no |
| Particles left behind a moving emitter (trail) | `wgrender-c/include/wgr_emitter3d.h` (`set_position`, `jump`) | Particles stay where they were born when the emitter moves, and steady spawns are spread along the path since the last frame, so a fast emitter leaves a smooth trail. `jump` moves without spawning. | with the emitter | no |
| Particle presets | `helix/src/helix/particle/ParticlePreset.hx` | Recipes sized by one number: Explosion, SmokePuff, Sparks, Dust, Fire, Smoke, Rain, Snow, Confetti. Sparks is life .3 to .7 s, added, stretched .04, gravity 7 sizes a second squared, 30 in a burst. | example only, or a helper beside the emitter | no |
| Example: fountain, sparks, campfire, confetti | `helix/examples/particles/App.hx`, `wgrender-c/examples/particles.c` | A blended fountain, added sparks thrown from a circling point and stretched, a flipbook fire under keyed-curve smoke, and 2D confetti on click. | example only | no |
| Collect effect, 2D | `helix/src/helix/scene/Collect2D.hx`, used by `gamejams/katawami/src/Game.hx` (`spawnSparks`) | Sprites burst from a point, scatter for a moment, then each flies along a quadratic curve bowed sideways, speeding up (t squared) and shrinking to 60%, to a target node, one after another, with a callback on each arrival and when all are done. Katawami used 4 gold sparks of size 12, scatter 22, scatter .2 s, fly .45 s, stagger .04 s. | render, include or an example. It is scene-level (a target node), so it may belong above helix-render. | no |
| Collect effect, 3D | `helix/src/helix/scene/Collect3D.hx` | The same, in the world: sprites burst up and out, scatter, then arc in to a target node. | as Collect2D | no |
| Confetti burst, 2D | `gamejams/katawami/src/ui/Menu.hx` (`Particles2D.confetti(110)`) | 110 pieces of paper thrown up from random places over the visible area, in bursts a few frames apart, behind the menu. | example only (the Confetti preset) | no |
| Confetti burst, web | `gamejams/voronoys_vortex/src/voronoiContainer.ts` (`js-confetti`) | Two bursts of the js-confetti library on a win. It draws on its own DOM canvas, not in the game's renderer. | none (replaced by the Confetti preset) | no |

## Material shaders

HeliX's were surface shaders over its stage's shading, packed with `ShaderPacker`. The C framework's were custom materials against
`wgr.glsl`. In helix a program's shader is a fragment stage with `Material3D.shaderValues`, using `lighting.glsl` and `material.glsl`.

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Toon | `helix/src/helix/shader/toon.glsl`, `wgrender-c/examples/shaders/toon.glsl` | Each light's lambert term quantized to N bands, the unlit side held at a shadow color. HeliX's bands its shadow term too, so shadows band with the light. | raylib, shader or example, or render, include (a banding helper in `lighting.glsl`) | no |
| Rim light | `helix/src/helix/shader/Rim.hx`, `wgrender-c/examples/shaders/toon.glsl` | A color added by `pow(1 - dot(n, v), power)`, brightest at grazing angles. In HeliX it is a field on every material, off until set. | render, include | no |
| Hit flash on a material | `helix/src/helix/shader/HitFlash.hx` | A color mixed over the lit result after exposure, all at a trigger and fading over some seconds, so it works on the stage's own shading and on every library shader. | render, include (a flash value in the material block), or an example | no. Needs a program's shader: `Material3D.shaderValues`. |
| Pulsing white flash | `wgrender-c/examples/shaders/sprite_fx.glsl` | White mixed over a sprite by a sine pulse. | merged with Hit flash | no |
| Dissolve | `helix/src/helix/shader/dissolve.glsl`, `wgrender-c/examples/shaders/dissolve.glsl` | Discards where noise is below a rising threshold with a glowing edge. HeliX's reads the noise triplanar in model space (so it needs no UVs), dithers the edge's opacity with a 4 x 4 Bayer pattern so the model stays opaque and unsorted, and its discard reaches the shadow caster. | raylib, shader or example. A discard that reaches the shadow pass wants a hook in helix-render's shadow caster: unclear how. | no |
| Water | `helix/src/helix/shader/water.glsl`, `wgrender-c/examples/shaders/wave.glsl` | A vertex hook moves the surface along its normals in travelling waves and tilts the normals by the slope. The fragment shades deep to shallow by view angle, reflects the environment at grazing angles (Fresnel) and adds glints. | example only (needs a vertex stage: `compileShaderStages`) | no |
| Unlit with emission | `helix/src/helix/shader/unlit.glsl` | Base color times a color plus emission, no light, still exposed and tone mapped. | render, built in | yes: `Shading3D.Unlit` in `libs/render/src/helix/render/Shading3D.hx` |
| Image-based lighting | `wgrender-c/include/wgr_environment.h`, `helix/src/helix/render3d/Environment3D.hx`, `helix/examples/environment/App.hx` | An equirectangular .hdr prepared into diffuse irradiance and blurred reflections per roughness, on a worker thread, with a sharp or blurred background and rotation. | render, built in | yes: `libs/render/src/helix/render/Environment3D.hx`, `EnvironmentBake3D.hx` |
| Glass and see-through | `helix/examples/materials/App.hx`, `helix/examples/instancing/App.hx` | Alpha-blended materials that keep back-to-front order among instanced draws. | render, built in | yes: `Material3D.blend` |

## Model passes

HeliX's `ModelPass3D` draws a model again after the stage's opaque models, with its own flat shader, static or skinned, instanced like
the model. The C framework had no model passes.

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Outline | `helix/src/helix/shader/Outline.hx`, `helix/src/helix/render3d/ModelPass3D.hx`, `Mesh3D.passVertices` | Draws the model again pushed out along its normals by a width in world units with front faces culled, so the far side of the shell shows as a band. The normals are averaged over every vertex at the same position, so a low-poly model's hard edges (split vertices) do not crack the shell. A cube's flat faces move out less than the width, by .58 of it. | render, built in (a pass in `Batch3D`) or example only. Keep the averaged normals. | no |
| Silhouette | `helix/src/helix/shader/Silhouette.hx` | Draws the model's shape in a flat blended color only where something nearer hides it (depth greater), before the model itself, so its own layered parts never hide it. | as Outline | no |
| Model pass base | `helix/src/helix/render3d/ModelPass3D.hx` | Both are one class with a push distance and a depth mode, not two shaders. | as Outline | no |

## Sprite effects

HeliX's were sprite shaders, drawn through `Node2D.effect`, `Batch2D.effect` or a 3D sprite. They read `helix_region_texel_at` so an atlas
neighbor never leaks in.

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Sprite outline | `helix/src/helix/shader/sprite_outline.glsl`, `wgrender-c/examples/shaders/sprite_fx.glsl` | Eight reads around each pixel (sides and diagonals), only inside the sprite's region, drawing a color where the sprite is see-through next to an opaque texel. The C one used 8 reads on a circle and a hard 0.5 alpha test. | raylib, shader or example | no. A program's `Batch2D` shader is possible: unclear if its sprites keep their region. |
| Sprite flash | `helix/src/helix/shader/sprite_flash.glsl` | A color mixed over the sprite's, alpha kept. | raylib, shader or example | no |
| Sprite ring | `helix/src/helix/shader/sprite_ring.glsl` | A ring drawn across a sprite's quad from where the pixel is in it, with inner and outer radius, edge softness, an inside fill alpha, dashes that turn, and a pulse. It reads no texel, so a 1 x 1 white texture does. Edges smooth over at least a pixel by `fwidth`. | render, include or raylib, shader | no |
| Sprite dissolve | `helix/src/helix/shader/sprite_dissolve.glsl` | Dissolve with a noise laid across the sprite's region. | merged with Dissolve | no |
| Palette swap | `helix/src/helix/shader/palette_swap.glsl` | The sprite's red channel is a column of a palette texture, a row chosen per variant, both read with `texelFetch` so an index is never blended. | raylib, shader or example | no |
| Pixel-art sharp sampling | `helix/examples/shader-gallery/App.hx` (indexed-pixel creature and checkerboard) | A gallery of sprites drawn sharp beside the effects. | example only | unclear |
| Squash and shine on a rolling ball | `gamejams/katawami/src/play/Ball.hx` | Pickups drawn as decals on a sphere, squashed toward the rim as a decal on a sphere is, with a shine sprite over all. Sprites in squashing nodes, no shader. | none (game code) | no |
| Rotating light sprites | `gamejams/voronoys_vortex/src/voronoiContainer.ts` (`light1`, `light2`) | Two light sprites turned at .02 and .01 radians a frame over a reachable cell. | none (game art) | no |

## Screen effects

HeliX's ran in a `PostProcess` chain on sRGB or HDR frames. In helix `PostProcess` runs linear effects, then the resolve (exposure and
tone mapping), then display effects.

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Bloom | `helix/src/helix/shader/bloom.glsl` | Light past a threshold with a soft knee, a 13-tap filter down a chain (Jimenez's, each group of four weighted by brightness so a lone texel does not flicker), a 3 x 3 tent filter back up. | render, effect class | yes: `libs/render/src/helix/render/effects/BloomEffect.hx` |
| Blur | `helix/src/helix/shader/blur.glsl` | Gaussian in two passes, 17 taps, at a fraction of the frame's size, taps written out (no indexed array) for mobile compilers. | render, effect class | no |
| FXAA | `helix/src/helix/shader/fxaa.glsl` | Lottes's FXAA 3.11 quality, preset 12, luma worked out from sRGB, steps unrolled for mobile compilers. | render, effect class | yes: `libs/render/src/helix/render/effects/FxaaEffect.hx` |
| Tone mapping | `helix/src/helix/shader/tonemap.glsl`, `wgrender-c/include/wgr_scene.h` | Khronos PBR Neutral, ACES (Narkowicz) or clamp, after an exposure in stops. | render, built in | yes: `libs/render/src/helix/render/ToneMapping.hx`, `shaders/color.glsl` |
| Color LUT | `helix/src/helix/shader/color_lut.glsl` | A 32 x 32 x 32 cube as a 1024 x 32 strip, blue between two squares, each read half a texel in so filtering never crosses a square. | render, effect class | yes: `libs/render/src/helix/render/effects/ColorGradeEffect.hx` (also brightness, contrast, saturation) |
| Vignette | `helix/src/helix/shader/vignette.glsl`, `wgrender-c/examples/shaders/vignette.glsl` | Shades toward a color from a radius to the corners. The C one also tinted the middle. | raylib, shader or example | no. `ShaderEffect.hx` shows a vignette as its example. |
| CRT | `helix/src/helix/shader/crt.glsl`, `wgrender-c/examples/shaders/scanlines.glsl` | Bent glass, dark lines between rows, an aperture grille chosen arithmetically, and flicker. The C one was scanlines, a red and blue shift and flicker. | raylib, shader or example | no |
| Chromatic aberration | `helix/src/helix/shader/chromatic_aberration.glsl` | Red and blue read a little inward and outward of green, more toward the edges. | raylib, shader or example | no |
| Pixelate | `helix/src/helix/shader/pixelate.glsl` | The frame in square cells, each the color at its middle. | raylib, shader or example | no |
| Screen-effect chain | `helix/examples/postprocess/App.hx`, `wgrender-c/examples/postprocess.c` | Effects in order, each on or off, one an example's own sepia shader reloaded while the dev server ran. | example only | yes: `libs/render/src/helix/render/effects/PostProcess.hx`, `ShaderEffect.hx` |
| Shader gallery | `helix/examples/shader-gallery/App.hx`, `helix/examples/shaders/App.hx` | Every library shader alone over one still scene, parameters on sliders. | example only | no |
| Screen transitions: Fade, Slide, Iris, Diamond, Noise | `helix/src/helix/scene/transition/`, `helix/examples/transitions/App.hx` | A cover swaps the screen at its middle: fade, a slide in eight directions (or back out), a round or diamond hole closing on a point, squares scattered over and away. Drawn with 2D shapes, not shaders, with delay, hold and ease options. | above helix-render (a scene or engine library), or example only | no |
| Fade and zoom of HTML screens | `gamejams/voronoys_vortex/public/css/ui.css` (`fadeIn`, `fadeOut`, `zoomIn`, `expand-mask`) | CSS keyframes over DOM screens. The zoom is commented out in use, and `expand-mask` and `rotate` are defined but unclear if used. | none | no |
| Glow of landing sparks | `gamejams/katawami/src/ui/Hud.hx` | A white rectangle over the HUD's bar at alpha .56 fading by .08 a frame each time the last spark lands. | none (HUD code) | no |

## Ground and world effects

| Effect | Where it was | What it does | Fit in helix | In helix already? |
|---|---|---|---|---|
| Ground ring, selection, range | `helix/src/helix/shader/sprite_ring.glsl` | See Sprite ring. A selection under a unit, a target on the ground, a spell's reach. | as Sprite ring | no |
| Decals, 3D | `helix/src/helix/render3d/Decals3D.hx`, `helix/src/helix/decal/DecalPool.hx` | A fixed pool of flat sprites. Once full, the oldest is reused, the next ones to go fade by how soon, and with a life they fade out on the game's clock (so a pause holds them). `placeOn` puts one on a pick hit and the node carries it. Lifted a little so it does not flicker into the surface. Skid marks, footsteps, scorch, bullet holes. | render, built in or example only | no |
| Decals, 2D | `helix/src/helix/render2d/Decals2D.hx` | The same on a 2D ground. | as Decals, 3D | no |
| Ground-facing sprite | `helix/src/helix/render3d/SpriteFacing3D.hx`, `sprite3d.glsl` | A sprite quad facing the camera, upright (the camera's right flattened, world up), or lying on the ground, or on its own axes. | render, built in | partly: billboards are in `Batch3D` (`libs/render/src/helix/render/Batch3D.hx`). Ground facing: unclear. |
| Environment background | `helix/src/helix/graphics/shaders/background3d.glsl`, `wgrender-c/include/wgr_scene.h` (`set_background`) | One triangle at the far plane showing the cube map in each pixel's view direction, a mip for blur, turned and scaled as the lighting is, then tone mapped. | render, built in | yes: `libs/render/src/helix/render/Environment3D.hx`, `CubeTexture3D.hx` |
| Shadow maps | `wgrender-c/src/wgr_shadow.c`, `wgrender-c/examples/shadows.c`, `helix/examples/shadows/App.hx` | A depth map per casting light (directional, spot), compared through a comparison sampler, with a distance, a bias in texels, a strength and a tint of what the shadow leaves. | render, built in | partly: `libs/render/src/helix/render/LightShadow3D.hx` declares the API; stage 3 builds it (a light casting shadows throws until then) |
| Fog | none in the sources read | Not found in HeliX or the C framework. | render, built in | yes: `libs/render/src/helix/render/Fog3D.hx` |
| Instanced batching | `helix/examples/instancing/App.hx`, `wgrender-c/examples/instancing.c` | Models that agree on mesh and material but differ in transform and tint are one draw, also into the shadow map. | render, built in | yes, per `libs/render/README.md` (instancing) |
| Trails (ribbon) | none in the sources read | No ribbon or line trail was found. Trails were particles left behind a moving emitter (see Particles). | n/a | no |

## Wardens uses

From the Effects section of `docs/trials/jam-survivors/spec.md`.

| Wardens effect | Entries it would exercise |
|---|---|
| Death bursts: 40 red sparks flying out and falling, added to what is behind, fading in 0.6 s, up to 2,000 alive | Birth-record GPU emitter, 3D; emission (burst); spawn shape and velocity cone; gravity and drag; size and color over life; stretch along motion; alpha mode (added); the Sparks preset as a model |
| Target ring: thin ring around the warden at sword reach, pulsing once a second, by a shader the game writes from ground coordinates | Sprite ring (shape, pulse, `fwidth` edge smoothing), as a procedural shader: Ground and world effects, Ground ring |
| Spawn warnings: red circle on the ground filling from the middle out over 1 s, fill passed in by the game | Sprite ring (the inside fill), as a procedural shader with a value from the game |
| Hit flash: white for 0.1 s on an animated, lit enemy | Hit flash on a material; Pulsing white flash; a program's shader on a skinned, lit mesh (`Material3D.shaderValues`) |
