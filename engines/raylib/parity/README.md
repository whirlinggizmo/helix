# helix-raylib's parity suites

helix-raylib behaves as raylib does, and these suites check it against raylib's own C. Each suite is a C reference built against a raylib
release and a Haxe harness or program doing the same with helix-raylib. raygui's suites build raygui's C (the `raygui.h` raylib 5.5 ships in its
examples) into their reference. `tools/raylib_parity.py` builds and runs both and compares what they
give: numbers line by line (value suites), or the frames they draw (pixel suites).

## The oracle

Each function has one oracle (docs/DECISIONS.md 24). Where helix-raylib took a bug fix from a later release, that release's C is the oracle
(6.2 now). Everywhere else it is raylib 5.5's. A suite names its oracle in its manifest (`"oracle": "5.5"`), so a suite only holds
functions that share one. A fix taken from 6.2 moves its function's cases into a 6.2 suite, or into a new one. A version bump (a later
release's API taken) is a rerun: change the suites' oracles, pin the release's tarball in the tool (`RELEASES`), and the bars show what
moved.

## Running

```console
python3 tools/raylib_parity.py              # every suite
python3 tools/raylib_parity.py shapes2d     # the suites named
python3 tools/raylib_parity.py --list       # the suites, their oracles and what each covers
```

Linux only. The C references and native programs run on a private display (`tools/private_display.py`, Xvfb and Openbox), with SDL's dummy
audio driver and no session bus. raylib's desktop build needs a C compiler, make, X11 and GL headers. The first run fetches each release
from GitHub, checks it against its sha256 and builds `libraylib.a` into `build/raylib/<version>/`. Everything the suites build goes in
`build/raylib-parity/<suite>/`: the generated sources (`src/`), the reference (`ref`, `ref.txt` or `raylib.png`), the harness's output (`js.txt`,
`cpp.txt`) or frames (`gl.png`, `sdl_gpu.png`). The tool exits 1 when any suite fails.

## The suites

| Suite | Oracle | Kind | What |
|---|---|---|---|
| `shapes2d` | 5.5 | values | the 2D Draw functions' vertices as rlgl batches them, the spline points, the 2D collisions |
| `shapes2d_62` | 6.2 | values | the 2D shapes 6.2 fixed, their vertices; the line test |
| `shapes3d` | 5.5 | values | the 3D shapes, vertex for vertex |
| `shapes3d_62` | 6.2 | values | the spheres, capsules and billboards, vertex for vertex |
| `meshes` | 5.5 | values | the generated meshes and their bounds |
| `meshes_62` | 6.2 | values | `GenMeshTangents`, with indices and without, and `ExportMesh`'s text |
| `collisions` | 5.5 | values | the 3D ray tests and collision checks |
| `collisions_62` | 6.2 | values | `GetRayCollisionSphere`, missing a sphere behind the ray |
| `cameras` | 5.5 | values | the camera matrix, world to screen, screen to ray, and rcamera's turns, over 700 cameras |
| `cameras_62` | 6.2 | values | rcamera's moves forward and right and `UpdateCameraPro`, Z-up and X-up cameras among them |
| `camera_update` | 5.5 | values | `UpdateCamera` in each mode over scripted input, from Y-up starts |
| `camera_update_62` | 6.2 | values | `UpdateCamera` in each mode from a Z-up start |
| `raymath` | 5.5 | values | every raymath function over three inputs each, a singular matrix and zero vectors among them |
| `raymath_62` | 6.2 | values | `MatrixDecompose`, 6.2's |
| `core_62` | 6.2 | values | file names, Base64, SHA-1, `MakeDirectory`, `QuaternionFromVector3ToVector3` |
| `images` | 5.5 | values | `LoadImageAnim` and `LoadImageAnimFromMemory` on GIFs (disposal, transparency, interlacing, a background index) and a PNG, their frames byte for byte; the first frame `LoadImage`, `LoadImageFromMemory` and `LoadTexture` read and a font `LoadFont` reads from a GIF |
| `stereo` | 5.5 | values | `LoadVrStereoConfig` for two displays and other clip planes, rlgl's stereo flag and matrices |
| `images_62` | 6.2 | values | the image functions 6.2 fixed, their images byte for byte |
| `animation` | 6.2 | values | glTF skeletons and animations, bone matrices, CPU skinning and blending |
| `materials` | 5.5 | values | `LoadMaterialDefault`'s maps, `IsMaterialValid`, what `UnloadMaterial` frees and keeps (a texture another load shares), a texture given to a model freed after `UnloadTexture` and `UnloadModel` |
| `materials_62` | 6.2 | values | glTF materials: each map's color, value and texture, its pixels |
| `obj` | 5.5 | values | `LoadMaterials` on an .mtl file: each map's color, value and texture, its pixels; none from a file it can't read |
| `obj_62` | 6.2 | values | OBJ models: their meshes split as raylib splits them, their vertices (corners naming what the file lacks among them), each mesh's material, the library's materials and textures, files raylib can't read |
| `modular` | 6.2 | values | real-world models: Quaternius' modular woman, each part its own file, animated from a file of its own |
| `text_55` | 5.5 | values | the text functions kept from 5.5: `TextReplace`, `LoadUTF8`, and those 6.2 didn't change |
| `text_62` | 6.2 | values | the text and codepoint functions taken from 6.2, null text and its 1024-byte buffers |
| `fonts_62` | 6.2 | values | `GenImageFontAtlas` (rows, the atlas grown, the skyline packer) and `LoadFontFromImage`'s scan |
| `fontfile_62` | 6.2 | values | `LoadFontEx` on a TrueType file: only the glyphs the font has, the Unicode spaces (hxcpp alone) |
| `fontcode` | 5.5 | values | `ExportFontAsCode`'s header byte for byte: the default font, a TrueType font, a font from an image (hxcpp alone) |
| `rlgl_62` | 6.2 | values | rlgl's texture across changes of mode, the matrix stack's overflow |
| `scene2d` | 5.5 | pixels | a 2D scene of the Draw functions, textures and text |
| `scene2d_62` | 6.2 | pixels | a 2D scene of the shapes 6.2 fixed |
| `scene3d` | 5.5 | pixels | a 3D scene of the shapes, generated models and shaders |
| `scene3d_62` | 6.2 | pixels | the spheres, capsules and billboards, and a mesh given tangents, in that scene |
| `render` | 5.5 | pixels | rlgl's blend modes, custom factors and color mask, a render texture's alpha under them; texture updates, read back and mipmaps under raylib's filters; render textures kept across passes and frames; `DrawMeshInstanced` |
| `wires` | 5.5 | pixels | rlgl's render state: wires, culling, wire mode, the depth mask and test |
| `points` | 5.5 | pixels | rlgl's point mode: `DrawModelPoints` and `DrawModelPointsEx` (a cloud, indexed meshes), point mode with culling, the batch as points |
| `skinning` | 6.2 | pixels | greenman skinned by the default shader (on the GPU, raylib's CPU skinning its oracle), by raylib's skinning shader, and blended |
| `crowd` | 6.2 | pixels | one greenman posed and drawn 240 times in a frame, each in its own pose, by the default shader and by raylib's skinning shader |
| `lighting` | 6.2 | pixels | raylib's lighting example (rlights.h, lighting.vs and lighting.fs) as `extras.Lights` builds it in: point and directional lights, one off; greenman lit and posed twice in a frame (on the GPU, raylib's CPU skinning its oracle), and lit by a program's own shader over `<helix/raylib/shaders/skinning.glsl>` and `lights.glsl` |
| `modular_scene` | 6.2 | pixels | the modular woman dressed and holding the sword, CPU-skinned |
| `waves` | 5.5 | values | `LoadWave` on WAV, Ogg Vorbis, MP3 (with a LAME tag and without), QOA and FLAC (refused): frames, rate, sample size, channels and every sample, natively and in a page; FLAC music refused |
| `cubemaps_62` | 6.2 | pixels | `LoadTextureCubemap` in each layout, raylib's skybox example, and cubes sampling cubemaps through their material |
| `vr` | 5.5 | pixels | raylib's VR simulator: both eyes drawn into a render texture (shapes and a model), drawn through its distortion shader |
| `raygui` | 5.5 | pixels | raygui 4.5-dev's controls in each state `GuiSetState` sets, its C built against raylib 5.5 |
| `raygui_input` | 5.5 | pixels | raygui's containers, lists, text editing, color pickers, icons, tooltips and wrapped text over three frames of played input |
| `raygui_values` | 5.5 | values | raygui's default style, what each control returns and changes over scripted mouse input, and the vertices the controls batch |

Each suite's manifest says in full what it covers (`covers`), and `notes` say why a bar is where it is.

## A suite

`<suite>/manifest.json`:

- `oracle`: the raylib release its C reference is built against.
- `covers`, `notes`: what it checks, and what a reader should know about its numbers.
- `kind`: `values` or `pixels`.
- `generated`: its two sides come from one list (below). Otherwise `reference` names its C file and `harness` its Haxe files, kept side by
  side, their lines named alike.
- `main`: the Haxe main class.
- `link`: false for a reference built against raylib's headers alone (`camera_update` builds rcamera.h itself).
- `assets`: files put into the suite's build directory before anything runs, by where they go: a path in the repository (`../assets/`),
  a script run with the destination as its argument (`makerig.py`), or `raylib:<path>`, a file from the oracle's own source.
- `resources`: files compiled into the Haxe harness (`-resource`), by name.
- `targets`: the targets a value suite's harness runs on, `js` and `cpp` unless it names others: `fontfile_62` runs in hxcpp alone, as its
  glyphs are rasterized by the native rasterizer, which Node hasn't; `waves` runs in hxcpp and `page`, the harness in a headless
  Chromium (Playwright's, muted, through `tools/page_check.cjs`), as its sounds are decoded by Web Audio, which Node hasn't. A page
  harness leaves its lines in `window.helixResult`.
- Value suites: `tolerance`, the largest difference allowed in a section (or one for each target, `{"cpp": 0, "page": 0}`), and `bars`,
  a section's own (`worst`, a target's own by its name, and `nonfinite`, how many numbers may be NaN or infinite where the other
  side's are not). `hex`: numbers printed as a double's bits. `sections`: how lines are
  grouped (below).
- Pixel suites: `frames`, how long helix-raylib's program runs (`HELIX_QUIT_AFTER_FRAME`); `backends`, for each backend it is built for (`gl`, `sdl_gpu`),
  how many pixels may differ from raylib's frame at all.

### Value suites

Both sides print lines, each led by its case's name: `pixel drawn 6`, then `pixel T 10 12 0 0 ...`. The C side prints to its output, the
Haxe side through `shared/Parity.hx`'s `line` and `save`. The tool reads both by section: a line's first word, or the group of the
manifest's `sections.pattern` matched against it. `sections.headers` names first words that start a block (`file 0`), which the sections after
are named under. A scale line, `NAME scale SCALE CLASS`, sets what the lines after it are measured against and adds CLASS to their
section's name (`cameras`: each camera's size, and whether it is regular or degenerate).

Within a section the lines are compared word by word. Words and integers must match. Other numbers must be within the bar, as
|a - b| / max(1, |a|, |b|, scale). raylib computes in floats, helix-raylib in doubles, so a few ulps of a float are the floor.

`shared/parity.h` and `shared/Parity.hx` print raylib's batch and helix-raylib's frame (`shape`), meshes, images (`image`, their bytes in hex), ray
hits and values alike.
`shared/StubGraphics.hx` is graphics that keeps nothing, `shared/DiskFiles.hx` files from the working directory, and `shared/PngDecoder.hx`
PNG files decoded in Haxe, for a harness that reads an image's pixels on every target.

### Pixel suites

The C reference draws three frames and saves the third as `ref.png`. helix-raylib's program draws the same and saves its third with
`TakeScreenshotAsync("helix.png")`. Both run on the private display's software renderers (Mesa), so a frame is the same from run to run.

## Adding a case

In a generated suite, add a line to its `cases.py`. A case is written once, in the syntax `shared/gen.py` describes: `V2`, `V3` and `R` as
they are, `PTS(...)` and `PTS3(...)` for point arrays, `NEW(Type, ...)` for a struct, `OUT(x)` for a pointer, `LET(x, Type, e)` for a
local. `('name', 'DrawThing(...);')` draws and prints the vertices. A value is printed by the printers (`hit("name", ...)`, `flag`,
`vec2`, `rect`, `box`, `num`, `color`, `mesh`, `image`, `str` for text). What needs setting up (a texture, a camera) goes in the templates (`ref.c.in` or `scene.c.in`,
and `<Main>.hx.in`). A case that can't be written once is `{'c': ..., 'hx': ...}`. In a suite kept side by side, add the case to both, its
lines named alike.

Then run the suite. A new case that differs is a finding: fix helix-raylib, or say in the manifest's `notes` why it differs. Bars sit a
little above today's worst, so a change that makes a suite worse fails it. One that makes a suite better can lower its bar.

## Adding a suite

Make `<suite>/` with its manifest and its two sides, and add it to the table above. A suite holds one oracle's functions.
