# Lanternholm ported to helix-raylib (2026-11-14)

What a program shaped as three.js shapes it needs that helix-raylib's API and extras don't give. One Opus agent ported Lanternholm, a
small TypeScript program on three.js (`lanternholm/`, the spec in [templates/lanternholm](../templates/lanternholm/spec.md)), to
helix-raylib with the extras, natively, from [the brief](brief.md) and [the task](task.md), against helix at `de1745a` (the
`helix-lantern` worktree), 4 hours at most.

| cost | time | turns | input | cache write | cache read | output | lines |
|---:|---:|---:|---:|---:|---:|---:|---:|
| $14.45 | 45.3 min | 154 | 238 | 418k | 32.9M | 226k | 4,158 Haxe, 736 GLSL |

## Grades

Graded by a fresh Opus agent on [the 35 items](../templates/lanternholm/grading.md), from the code and the screenshots the grading
names, taken natively on a private display, beside the original's references: **21 met, 13 wrong, 1 can't tell** (35, the frame
rate, not timed). Its dawn, noon, dusk, night and close-up shots sit close to the references.

Eight of the thirteen are the port's own choices: no resizable window (1), no touch (2), counts set for its high tier (6, 13, 24,
25, 30), sound started at launch (33) and `--frames` without a shot (34). The rest:

- **19, the glow at night:** its halos are blocky. Its bloom blurs in few passes, as more than about ten render passes a frame failed
  natively with "Invalid native upload" (the platform's `NativeGraphics`), which is a bug to find.
- **28, the controls' fonts:** drawn in raylib's default font. It loaded the system's serif and sans by absolute path
  (`/usr/share/fonts/...`), which didn't load.
- **8, the mist** drifting down the fall, and **23, the needlewood** drawn as a bare pole: the port's.

## What it wrote itself

| what | where | lines |
|---|---|---:|
| Shadows: an orthographic light camera, depth packed into RGB, 3x3 filtering, depth materials for plain and instanced draws | `Main.hx`, `Gfx.hx`, `depth*.vs/fs`, `shadow.glsl` | 120 |
| Particles: a CPU pool drawn as billboards (smoke, mist, dust, fireflies) | `Particles.hx` | 200 |
| Bloom: a glow mask, a bright pass, blurs at a quarter and an eighth, a composite | `Main.hx`, `bright.fs`, `blur.fs`, `composite.fs` | 75 |
| Lighting: a sky fill, a point light, ACES tone mapping, shared uniforms | `common.glsl`, `Gfx.hx` | 160 |
| Meshes: merging, vertex colours, flat shading, box, sphere, cylinder, torus, tube, icosahedron, octahedron | `Geo.hx` | 470 |
| A colour per instance, in each instance matrix's last row, as `DrawMeshInstanced` takes transforms alone | `lit_inst.vs`, `grass.vs`, `Gfx.hx` | 70 |
| An orbit camera with easing and limits, and the pointer over the island | `Main.hx` | 70 |
| UI chrome: rounded translucent panels, a blur behind them, a slider, icons | `Ui.hx`, `backdrop.fs` | 280 |
| Sound made in code: a filter, noise loops and swept tones into an `AudioStream` | `Audio.hx` | 145 |
| A leaf atlas drawn in code | `LeafAtlas.hx` | 210 |

What changed for it: the Lighting extra's lights and shadows and the Materials extra (docs/trials/2026-11-16-lighting-materials),
an emitter extra next (ROADMAP). The upload failure and absolute paths are bugs to fix.
