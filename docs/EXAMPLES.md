# Examples

Every example runs in the browser and natively on Linux/X11, built and developed as [BUILDING.md](../BUILDING.md) says (`python3 tools/example.py <name> dev`). **F9 saves a screenshot** in any of them: a download in the browser, natively a PNG in `~/Pictures/<example>/` (or `HELIX_EXPORT`). Autopilot scripts take them too (`{"op": "screenshot"}`).

## The catalog

The catalog follows the earlier C frameworks' example names. Each example matches the feature, not the original's scene.

| Example | Shows |
|---|---|
| `app-skeleton` | a window cleared each frame |
| `app-hello` | shapes and text |
| `app-tick` | a fixed-rate simulation, time scale and the tick fraction |
| `app-window` | window size, position, fullscreen and displays (get/set/can/request) |
| `app-gamepad` | four pads in the W3C standard layout |
| `app-touch` | two-finger pan, pinch and twist; images and mipmaps |
| `audio-music` | streamed music and decoded clips, with play state |
| `asset-fetch` | assets from a host, the cache, and asking whether a host answers |
| `asset-force-fetch` | ensure with a source and past the cache |
| `quit` | quitting mid-load: shutdown runs after the frame |
| `hello3d` | an orbiting 3D camera, depth-tested shapes and lines, a 2D overlay |
| `meshes` | generated meshes on a `Stage3D`: lit, instanced models with glTF materials |
| `materials` | metallic-roughness steps, unlit, emissive, a normal map, see-through; a sun and a point light |
| `lights` | directional, point and spot lights on a stage, beside an immediate grid |
| `animation` | skinned characters (Quaternius's modular women): a skeleton and 24 clips from a file of animations alone, an outfit of skinned parts from files of their own bound to it by joint name and swapped at run time, a sword in a socket (a joint), crossfades, posed shadows |
| `ui` | menus (helix.ui): a main menu, settings (toggle, slider, a name typed in) and a scrolling list of levels in nine-slice panels, laid out in a fitted 1280 x 720 design, used by the pointer, keys or a pad |
| `scene3d` | the pointer over a scene: shapes in a ring hovered and clicked to select, a HUD button over the world that captures the pointer, an unpickable ground and label (helix.scene.Pointer) |
| `pick` | every kind a Stage3D picks: a cube, a sphere, a sprite, a text, a glTF car and a walking skinned character, the hit's point, normal and distance shown |
| `model` | a glTF model (Kenney's sports car with headlights added in Blender: a .gltf, its buffer and texture files beside it) loaded into nodes: parts and lights found by name, a chase camera on a camera node |
| `instancing` | 400 cubes sharing a mesh and material as one draw, six cars' parts one draw each, see-through cubes kept in order; SPACE: a material each, a draw each |
| `sprite3d` | sprites on a Stage3D facing the camera, upright, flat on the ground and free; masked, blended and added; instanced by texture |
| `text3d` | text in the world: labels facing the camera, a sign's text (a TrueType font) turning with its node; lines on the ground |
| `particles` | GPU particles: a fountain, trailing sparks, a campfire's flames (a flipbook) and smoke (curves) on a 3D stage; confetti on a 2D one |
| `shadows` | a sun and a circling spot casting into one shadow map, a layer each; a ball that casts nothing and one nothing shadows; distance, bias, map size, strength and tint live |
| `environment` | image-based light from two 1K Poly Haven HDRs, prepared a few milliseconds a frame: plastic and gold roughness steps, a mirror, a normal map, a pearl (a surface shader shaded by the stage) and a car, no lights; a background sharp to blurred, Neutral, ACES or no tone mapping, exposure and turn live |
| `sprite2d` | sprites on a `Stage2D`: a sheet's regions, pivots, rotation, a mirror, a tint, hovering by `toLocalX` |
| `stage2d` | a world stage through a zooming camera and a HUD stage, in one batch: shapes, a sprite, text, a turning group, a trailing emitter |
| `textures` | one texture drawn smooth then sharp (sampling per draw); `name.ktx` loading this GPU's compressed variant (BC7, ASTC, ETC2) or the PNG |
| `font` | TrueType fonts loaded and baked into distance fields in Haxe: a measured, centered title, several sizes, kerning |
| `tilemap` | a scrolling, zooming tile map of sprites cut from one sheet, culled to the view; props on their pivots, coins hovered and collected |
| `render-target` | drawing into textures: a low-resolution pixel view, an orthographic minimap, a text label worn by a globe |
| `shaders` | Stage3D materials drawn by the example's own surface shaders: toon shading, a double-sided dissolve through a noise texture, water moved by a vertex hook |
| `postprocess` | screen effects of the example's own shaders (`shaders/*.glsl`, packed into `.hxshader` assets, reloaded as they're edited) over a finished frame |

## Larger examples: Asteroids and Blocks


Both are whole games, built and developed like every other example, on HeliX's own 2D API, `Ticker` and shared launchers. Each has autopilot scripts that must end in the same game on both targets.

- **Asteroids** (`examples/asteroids`): menus, flight, splitting rocks, waves, Ogg sound, keyboard/pointer/gamepad, letterboxed with a camera viewport area.
- **Blocks** (`examples/blocks`): falling blocks, with keyboard, gamepad and touch.

```console
python3 tools/example.py asteroids dev
python3 tools/example.py blocks autopilot --browser /path/to/chromium --shdc /path/to/sokol-shdc
```


Their assets' credits: [examples/assets/CREDITS.md](../examples/assets/CREDITS.md).
