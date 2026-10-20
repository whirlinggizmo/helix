# Examples

Every example runs in the browser and natively on Linux/X11, built and developed as [BUILDING.md](../BUILDING.md) says (`python3 tools/example.py <name> dev`). **F9 saves a screenshot** in any of them: a download in the browser, natively a PNG in `~/Pictures/<example>/` (or `HELIX_EXPORT`). Autopilot scripts take them too (`{"op": "screenshot"}`).

## The catalog

The catalog follows the earlier C frameworks' example names. Each example matches the feature, not the original's scene.

| Example | Shows |
|---|---|
| `app-skeleton` | a window cleared each frame |
| `app-hello` | shapes and text |
| `app-tick` | a fixed-rate simulation, time scale and the tick fraction |
| `app-window` | window size, position, fullscreen and displays (properties, `can` and `request`) |
| `app-gamepad` | four pads in the W3C standard layout |
| `app-touch` | two-finger pan, pinch and twist; images and mipmaps |
| `audio-music` | streamed music and decoded clips, with play state; the music bus faded, a crossfade to a second track, pitch and pan, and natively with `HELIX_ASSET_HOST` the music played as it downloads |
| `asset-fetch` | assets from a host, the cache, and asking whether a host answers |
| `asset-force-fetch` | ensure with a source and past the cache |
| `scenes` | a game's flow on a scene stack: the built-in splash ("press any key" until a press unlocks audio), a title, a level loading behind the built-in loading scene, a pause menu pushed over it and popped, fades between; its autopilot runs the flow on both targets |
| `quit` | quitting mid-load: shutdown runs after the frame |
| `hello3d` | an orbiting 3D camera, depth-tested shapes and lines, a 2D overlay |
| `meshes` | generated meshes on a `Stage3D`: lit, instanced models with glTF materials |
| `materials` | metallic-roughness steps, unlit, emissive, a normal map, see-through; a sun and a point light |
| `lights` | directional, point and spot lights on a stage, beside an immediate grid |
| `animation` | skinned characters (Quaternius's modular women): a skeleton and 24 clips from a file of animations alone, her skinned parts from files of their own bound to it by joint name, crossfades, pausing, posed shadows (dressing her is the dressing room's) |
| `dressing-room` | a character creator: a character on a turntable dressed slot by slot (head, body, legs, feet, what she holds) from ten outfits whose parts mix freely (its own `Outfit`, over `Model.bindSkeleton`, `Node3D.collectModels` and `findAttachment`, with `Models` sharing the files); each part a tile (`helix.ui.Tile`) pictured from the part itself through a render target as its file loads, a slot's files loaded when its tab opens; poses, Random and Reset; the camera frames the slot; pointer, keys or a pad move across the grid |
| `ui` | menus (helix.ui): a main menu, settings, controls and a scrolling list of levels, the main menu in a nine-slice panel and the others in rounded ones, laid out in a fitted 1280 x 720 design, used by the pointer, keys or a pad; the settings set the master, music and effects buses with music playing under them (an effect as the effects slider is let go, the music muted by a toggle) and a color picker chooses the background, the controls list an `Actions` map's actions with their bindings, rebound by the next key, button, axis or touch and reset, all saved and loaded through `Storage`; its autopilot rebinds jump, resets it, sets the music's volume and mutes it, and sets the background by dragging in the picker, by typing hex (refused text first), by typing decimal channels after its button cycles the format, and by keys, sampling it in the swatch and behind the panel, the same final game and samples on both targets |
| `scene-file` | a racer slice entirely from a scene file and behaviors (helix.scene.SceneFile, helix.behavior): the sky, the sun's shadows, a closed loop of Kenney's Racing Kit pieces with barriers and scenery, the checkpoints, the race, the car (a prefab) and the chase camera all in `scenes/track.scene`; Car, ChaseCamera, Checkpoint and Race behaviors drive it at a fixed 60 Hz; R destroys the instance and makes it again; its autopilot drives a lap on both targets |
| `scene3d` | the pointer over a scene: shapes in a ring hovered and clicked to select, a HUD button over the world that captures the pointer, an unpickable ground and label (helix.scene.Pointer) |
| `pick` | every kind a Stage3D picks: a cube, a sphere, a sprite, a text, a glTF car and a walking skinned character, the hit's point, normal and distance shown |
| `model` | a glTF model (Kenney's sports car with headlights added in Blender: a .gltf, its buffer and texture files beside it) loaded in one line into a tree of the file's nodes: its wheels (models) and headlights (spot lights) found by name; D drives it, C rides along through a `Camera3D` under the car, H the headlights; the circling camera the examples share (`Orbit`) |
| `instancing` | 400 cubes sharing a mesh and material as one draw, six cars' parts one draw each, see-through cubes kept in order; SPACE: a material each, a draw each |
| `sprite3d` | sprites on a Stage3D facing the camera, upright, flat on the ground and free; masked, blended and added; instanced by texture and effect; the library's sprite effects on 3D sprites (outlined trees, a dissolving sign, a flashing logo) and one of the example's own (`shaders/heat.glsl`, an `.hxshader` asset: the flames shimmer), with an autopilot sampling each against it off |
| `text3d` | text in the world: labels facing the camera, a sign's text (a TrueType font) turning with its node; lines on the ground |
| `particles` | GPU particles: a fountain, trailing sparks, a campfire's flames (a flipbook) and smoke (curves) on a 3D stage; confetti on a 2D one |
| `shadows` | a sun and a circling spot casting into one shadow map, a layer each; a ball that casts nothing and one nothing shadows; distance, bias, map size, strength and tint live |
| `environment` | image-based light from two 1K Poly Haven HDRs, prepared a few milliseconds a frame: plastic and gold roughness steps, a mirror, a normal map, a pearl (a surface shader shaded by the stage) and a car, no lights; a background sharp to blurred, Neutral, ACES or no tone mapping, exposure and turn live |
| `sprite2d` | sprites on a `Stage2D`: a sheet's regions, pivots, rotation, a mirror, a tint, hovering by `toLocalX`; the library's sprite effects (an outline shared by two sprites, a dissolve, a flash, also over the title's text, a palette swap of indexed pixels) and one of the example's own (`shaders/wave.glsl`, an `.hxshader` asset: a logo waving), with an autopilot sampling each against it off |
| `motion` | the game's clock, tweens by every easing (yoyo, for ever), a timer dropping sparks that fall and fade by tweens, a ball along a closed curve at a steady speed, a floor by `Collide2D`, colors dealt by a seeded `Random`; the clock paused and slowed |
| `stage2d` | a world stage through a zooming camera and a HUD stage, in one batch: shapes (a square box, a rounded one and a rounded outline among them), a sprite, text, a turning group, a trailing emitter |
| `textures` | one texture drawn smooth then sharp (sampling per draw); `name.ktx` loading this GPU's compressed variant (BC7, ASTC, ETC2) or the PNG |
| `font` | TrueType fonts loaded and baked into distance fields in Haxe: a measured, centered title, several sizes, kerning |
| `tilemap` | a scrolling, zooming tile map of sprites cut from one sheet, culled to the view; props on their pivots, coins hovered and collected |
| `render-target` | drawing into textures: a low-resolution pixel view, an orthographic minimap, a text label worn by a globe |
| `shaders` | surface shaders in a lit scene: the floor drawn by the example's one shader of its own (`shaders/checker.glsl`, an `.hxshader` asset reloaded as it's edited) beside the library's (`helix.shaders`) where they meet the stage: `Toon` on a car and on a skinned character, `Dissolve` (laid over the model in its own space) with its shadow dissolving, `Water` with its waves moving its shadow, `Unlit`, `Outline` and `Silhouette` passes (her silhouette through a wall), `HitFlash` on a library shader and on the stage's own shading; its autopilot holds the time and samples the frame's pixels (each effect, and unlike it turned off; the water's shadow at two held times, unlike, and the sphere's under the stage's own shading, alike), alike on both targets |
| `postprocess` | a chain of the library's screen effects in the order a game would build one (Bloom on an HDR scene, Fxaa, Blur, Pixelate, ColorLut, Crt, ChromaticAberration, Vignette), the tone mapping put first, and one effect of the example's own (`shaders/sepia.glsl`, packed into a `.hxshader` asset, reloaded as it's edited); its autopilot samples the chain, Bloom on and off, the example's own effect, and the background alike with the chain HDR and without |
| `shader-gallery` | every library shader alone over one still scene (a car, a sphere and a skinned character behind a wall, a row of sprites), chosen from a menu by kind (surface: Unlit, Toon, Rim, HitFlash, Dissolve, Water; passes: Outline, Silhouette; screen: Bloom, Tonemap, Fxaa, Blur, Vignette, ColorLut, Crt, ChromaticAberration, Pixelate, and Bloom then Vignette; sprite: SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap), its parameters on sliders and its colors on `helix.ui` color pickers; its autopilot holds the time, her pose and the camera, samples each shader where it shows against it off, and types a color into Unlit's picker and drags SpriteOutline's hue, sampling the change, alike on both targets |

## Larger examples: Asteroids and Blocks


Both are whole games, built and developed like every other example, on HeliX's own 2D API, `Ticker` and shared launchers. Each has autopilot scripts that must end in the same game on both targets.

- **Asteroids** (`examples/asteroids`): menus, flight, splitting rocks, waves, Ogg sound, keyboard/pointer/gamepad, letterboxed with a camera viewport area.
- **Blocks** (`examples/blocks`): falling blocks, with keyboard, gamepad and touch.

```console
python3 tools/example.py asteroids dev
python3 tools/example.py blocks autopilot release-sokol-gl --browser /path/to/chromium
```


Their assets' credits: [examples/assets/CREDITS.md](../examples/assets/CREDITS.md).
