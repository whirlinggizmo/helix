# Wardens with the extras (2026-11-13)

Whether helix-raylib's extras make Wardens cheaper, quicker or more correct to build than raylib alone. Six fresh Sonnet agents built
[Wardens](../wardens/spec.md) natively, as the blind trials do ([../README.md](../README.md)), against one commit of helix:

- **Without the extras** (`helix-raylib-blind.016` to `.018`): the blind trials' brief, raylib 5.5's headers and examples alone.
- **With the extras** (`helix-raylib-docs.001` to `.003`): the same, with [a brief](../wardens/native/brief-extras.md) adding one line
  that points at the extras, and the extras' doc comments as their generated API page (`engines/raylib/api/extras.md`) in
  `docs/extras.md` (`run_entrant.py --extras`).

The spec asks for what the extras do without naming them: her parts posed as one, her attacks from the waist up while she moves
(`Models`), materials drawn as authored, metallic and roughness honoured (`Lighting`), and touch controls (`VirtualGamepad`). For this
trial it gained the attack on the move, and the gun's 90 degree arc in front of her, which keeps her upper body from turning to a
target behind her. The blind runs before it were on the spec without either, and aren't compared here.

## Runs

Five rounds with the extras, each started together on coinspinner, 3 hours each at most, against the helix commit named. The extras'
docs changed between rounds, from what the round before found. The first round ran beside the three without them.

| round | helix | runs | what changed before it |
|---|---|---|---|
| one | `8271fd7` | blind.016 to .018, docs.001 to .003 | |
| two | `84579fe` | docs.004 to .006 | the extras' own types in `helix.raylib.extras`, beside the extras taking them |
| three | `e5881b4` | docs.007 to .009 | a page for each extra (`docs/extras/`), CompileShaderFile's stage errors at the file's line |
| four | `65b2cd7` | docs.010 to .012 | the spec asks for the touch stick as a player sees it, not as a recipe |
| five | `cb3cf8b` | docs.013 to .015 | an example for each extra (`docs/extras/examples/`), the Textures extra, touch emulation |

| run | cost | time | turns | lines | extras used |
|---|---:|---:|---:|---:|---|
| blind.016 | $2.84 | 20.9 min | 77 | 2,262 | |
| blind.017 | $2.52 | 23.2 min | 80 | 1,962 | |
| blind.018 | $2.47 | 22.2 min | 74 | 1,810 | |
| docs.001 | $1.65 | 15.6 min | 51 | 1,847 | Models, Lighting, GuiSkins, Device |
| docs.002 | $2.10 | 18.6 min | 58 | 1,984 | Models, Lighting, Device |
| docs.003 | $2.06 | 16.5 min | 58 | 1,942 | Models, Lighting, GuiSkins |
| docs.004 | $2.11 | 20.9 min | 69 | 1,354 | Models, Lighting, VirtualGamepad, GuiSkins, Device |
| docs.005 | $1.70 | | | 1,698 | Models, Lighting, GuiSkins |
| docs.006 | $3.10 | 27.6 min | 97 | 2,096 | Models, Lighting, GuiSkins, Device |
| docs.007 | $1.47 | 11.7 min | 36 | 1,813 | Models, Lighting, GuiSkins, Device |
| docs.008 | $2.02 | 15.5 min | 63 | 1,684 | Models, Lighting, GuiSkins, Device |
| docs.009 | $2.50 | 20.7 min | 79 | 1,948 | Models, Lighting, GuiSkins, Device |
| docs.010 | $1.88 | 17.7 min | 65 | 1,718 | Models, Lighting, VirtualGamepad, GuiSkins, Device |
| docs.011 | $2.32 | 17.6 min | 78 | 1,980 | Models, Lighting, VirtualGamepad |
| docs.012 | $2.48 | 23.1 min | 78 | 1,805 | Models, Lighting, VirtualGamepad, GuiSkins |
| docs.013 | $2.56 | 18.3 min | 60 | 1,870 | Models, Lighting, VirtualGamepad, GuiSkins, Device (touch emulation) |
| docs.014 | $2.39 | 17.9 min | 66 | 1,743 | Models, Lighting, VirtualGamepad, GuiSkins, Device |
| docs.015 | $2.20 | 15.9 min | 65 | 1,816 | Models, Lighting, VirtualGamepad, GuiSkins |

Turns are `result.json`'s; docs.005's holds its cost alone. Lines are the program's Haxe. "Models" is the masked blend
(`UpdateModelAnimationMasked`) and `LoadModelFromModels`, in every run with the extras, and "Lighting" is `LoadPbrShader`. No run used
Textures.

All eighteen built natively and in a page unchanged. The runs with the extras cost 17% less than the three without them
($2.17 against $2.61 on average) and took 18.4 minutes against 22.1, in 66 turns against 77.

## three.js beside them

The same spec, built on three.js 0.187 by three fresh Sonnet agents (`three-blind.001` to `.003`, 2026-11-14,
`run_entrant.py --engine three`), each in JavaScript from `src/main.js`, bundled with esbuild and run in Chromium by the harness's
`run.cjs` (screenshots at set seconds, the page's console). npm was open to them, three.js's own files the only docs.

| run | cost | time | turns | lines |
|---|---:|---:|---:|---:|
| three.001 | $1.46 | 12.3 min | 34 | 1,342 |
| three.002 | $1.33 | 10.1 min | 28 | 1,184 |
| three.003 | $1.37 | 11.4 min | 37 | 1,299 |

None added a package beyond three.js. Each gave a character's parts one skeleton (three.002 merged them into one mesh), as the outfits
asked, and wrote by hand what the extras gave the helix runs: the upper-body blend, the parts rebound to one rig, a hit flash in the
shader, and a nine-patch in CSS.

Where the helix runs' turns went, from their transcripts against three.js's (round five and the blind runs):

- **Running and fixing:** 14 to 17 turns fixing what ran wrong, against 4, each after an hxcpp build of 15 to 50 seconds, against
  esbuild's second. The fixes include profiling and adding options to reach a game state, which three.js's runs mostly left to `run.cjs`.
- **Compile errors:** 5 to 6 turns a run, against none. Every run met the async loaders' refusals (`LoadModel`, `LoadShader`),
  `sys.io.File`'s, and `CompileShaderFile`, which isn't in the extras' docs.
- **Reading:** the extras' pages, 9 turns and about 25k tokens a run, against one or two reads of three.js's sources. That reading,
  and the screenshots, kept a larger context in every later turn: most of the difference in cost is reading that context again.
- **Written by hand in every helix run:** a skinning vertex shader, for a character shader of its own (a hit flash); camera-facing
  quads for health bars and sparks.

## Frame times

At 200 enemies (`?enemies=200&seed=1` and each program's own option to start playing, as `start=play`, with god mode where it has
one), in headless Chromium on coinspinner's GPU (ANGLE over Vulkan) with its frame rate cap lifted: the mean and 95th percentile of
600 frames after 120, from 5 seconds into play, the enemies arrived. helix-raylib's pages were run with `SetTargetFPS` taking no effect,
as most of them hold themselves to 60 frames a second. Some reached a level-up's choice within the frames, which stops the game but
still draws it.

| run | mean | p95 | | run | mean | p95 |
|---|---:|---:|---|---|---:|---:|
| docs.010 | 3.03 ms | 3.5 | | three.003 | 5.43 ms | 6.5 |
| docs.012 | 3.05 | 3.5 | | three.002 | 5.55 | 7.8 |
| docs.009 | 3.10 | 4.0 | | three.001 | 5.61 | 6.5 |
| docs.014 | 3.29 | 3.8 | | blind.018 | 11.40 | 12.2 |
| docs.007 | 3.67 | 3.9 | | blind.017 | 15.37 | 17.1 |
| docs.013 | 3.74 | 4.0 | | blind.016 | 15.70 | 32.5 |
| docs.002 | 4.14 | 4.5 | | docs.006 | 16.14 | 34.6 |
| docs.008 | 4.47 | 4.7 | | docs.011 | 60.67 | 68.0 |
| docs.015 | 4.53 | 4.9 | | docs.005 | 61.02 | 66.6 |
| docs.003 | 4.87 | 5.2 | | docs.001 | 61.98 | 81.4 |

docs.004 drew nothing once play started in the page ("Invalid draw"), and isn't timed.

- **docs.001, .005 and .011** gave the characters a shader of their own, a raylib vertex stage without the bones, so helix-raylib skins
  them on the CPU, as raylib does: their posed vertices worked out and uploaded for each draw, 84% of docs.005's frame.
- **three.js's frame** is mostly its scene graph: in three.003's, the animation mixer writing each bone as an object (42%), each
  quaternion's write keeping its Euler angles too, the world matrices of every node (17%), and the walk that culls and lists the draws
  (15%), against 10% drawing.

Each helix page asks the server for its save file (`wardens.sav`) at start, a 404 before the first save.
