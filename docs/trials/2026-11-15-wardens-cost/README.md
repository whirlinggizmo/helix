# Wardens with raylib's loads and an ensure (2026-11-15)

Whether an agent builds Wardens cheaper when raylib's synchronous loads work, with the files ensured first, than when each load is
an `...Async` call. Fifteen fresh Sonnet agents built [Wardens](../wardens/spec.md) in a page as
[the page trial's](../2026-11-14-page-iteration) did, with the native build as the last step, 3 hours each at most:

- **main** (`base.001` to `.006`): helix at `0012bce`. raylib's loads are refused there, and each refusal names its `...Async` call.
- **ensure** (`ensure.001` to `.009`): the branch `ensure-assets`. raylib's loads read a file ensured first. The brief has one more
  line: "**Files.** A file must be local before raylib's loads read it: ensure it with `EnsureAssetAsync(fileName, ensured)`, or
  several with `EnsureAssetsAsync(fileNames, ensured)` (`import helix.raylib.extras.Assets.*;`), then load it as raylib does."

The runs are in `/home/rknopf/projects/local/helix/trials/wardens-cost`. The harness (`run_entrant.py --page`,
`docs/trials/wardens/page`) is in the two checkouts' working trees, in no commit.

## Rounds

Each round's entrants started 90 seconds apart and ran together on coinspinner.

| round | runs | helix | brief |
|---|---|---|---|
| 1, 10:23 | base.001 to .003 | main, `0012bce` | as above |
| 1, 10:23 | ensure.001 to .003 | `1748e6b` | as above |
| 2, 12:36 | ensure.004 to .006 | `7f66628`: an ensured font loads at once | as above |
| 3, 16:11 | base.004 to .006 | main, `0012bce` | a Shaders line added |
| 3, 16:11 | ensure.007 to .009 | `f6fb846`: `LoadCompiledShader` | a Shaders line added |

Round 3's line, in both briefs: "**Shaders.** A shader is compiled as the program is built, from raylib's GLSL (`#version 330`): a
line in `build.hxml` for each, `--macro helix.raylib.Raylib.CompileShaderFile("shaders/flash.vs", "shaders/flash.fs",
"shaders/flash.shader")`, `null` for a stage being raylib's default." It ends, for main, "Load the `.shader` file with
`LoadCompiledShaderAsync("shaders/flash.shader", loaded)` in place of `LoadShader`", and for ensure, "Ensure the `.shader` file as
any other, then load it with `LoadCompiledShader("shaders/flash.shader")` in place of `LoadShader`."

## Runs

| run | cost | time | turns | lines | page runs | `...Async` calls | input | cache write | cache read | output |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base.001 | $2.14 | 23.9 min | 78 | 1,576 | 31 | 7 | 120 | 167k | 7.1M | 76k |
| base.002 | $2.23 | 27.2 min | 80 | 1,822 | 32 | 17 | 122 | 172k | 7.5M | 80k |
| base.003 | $2.20 | 25.8 min | 69 | 1,766 | 33 | 18 | 102 | 178k | 6.4M | 85k |
| ensure.001 | $1.82 | 16.5 min | 54 | 1,471 | 17 | 2 | 100 | 147k | 5.6M | 68k |
| ensure.002 | $2.39 | 29.4 min | 82 | 1,599 | 34 | 2 | 124 | 184k | 8.2M | 83k |
| ensure.003 | $1.82 | 23.5 min | 51 | 1,679 | 15 | 4 | 90 | 150k | 5.1M | 71k |
| ensure.004 | $1.66 | 20.3 min | 47 | 1,547 | 18 | 3 | 74 | 148k | 4.0M | 67k |
| ensure.005 | $2.19 | 20.8 min | 66 | 1,684 | 23 | 3 | 104 | 176k | 6.8M | 81k |
| ensure.006 | $2.42 | 21.1 min | 76 | 1,647 | 35 | 2 | 108 | 197k | 7.5M | 89k |
| base.004 | $2.13 | 25.5 min | 53 | 1,861 | 15 | 16 | 98 | 173k | 6.6M | 78k |
| base.005 | $1.88 | 20.8 min | 51 | 1,742 | 16 | 16 | 90 | 159k | 5.4M | 71k |
| base.006 | $1.56 | 17.8 min | about 42 | 1,573 | 12 | 11 | 72 | 141k | 3.7M | 63k |
| ensure.007 | $1.69 | 16.4 min | 51 | 1,501 | 15 | 0 | 76 | 152k | 4.2M | 66k |
| ensure.008 | $2.09 | 26.0 min | 67 | 1,739 | 23 | 0 | 98 | 171k | 6.3M | 78k |
| ensure.009 | $1.91 | 19.6 min | 53 | 1,562 | 16 | 0 | 88 | 164k | 5.1M | 74k |

Lines are the program's Haxe. Page runs are its `node run.cjs` commands. Input (uncached), cache write, cache read and output are
tokens, from `result.json`. base.006's `result.json` holds only a turn after its end, when a background run it had already read
finished. Its turns are its 41 tool uses and one, and its time is its `run.log`'s.

| | cost | time | turns |
|---|---:|---:|---:|
| main, round 1 | $2.19 | 25.6 min | 76 |
| ensure, round 1 | $2.01 | 23.1 min | 62 |
| ensure, round 2 | $2.09 | 20.7 min | 63 |
| main, round 3 | $1.86 | 21.4 min | 49 |
| ensure, round 3 | $1.89 | 20.7 min | 57 |

## What it found

**Round 1 is the one round comparing the two as a program meets them.** main's three entrants wrote raylib's loads, met their
refusals at their first compile (tool step 11 to 14) and changed every load to its `...Async` call behind a loading screen (7 to 18
calls a program). ensure's ensured every file with one `EnsureAssetsAsync` and loaded them with raylib's own calls in its callback.
None met "not ensured" in a run: each read of it was the Assets extra's page. ensure's cost $2.01 against main's $2.19, in 62 turns
against 76, but its runs spread from $1.82 to $2.39 against main's $2.14 to $2.23, so three runs a side show a lean, not a result.

**In round 3 both briefs said how to load.** main's Shaders line names `LoadCompiledShaderAsync("shaders/flash.shader", loaded)`, and
its three entrants wrote every load as an `...Async` call from the start and met no load refusal. ensure's wrote raylib's loads after
one `EnsureAssetsAsync`. The two cost the same, $1.86 and $1.89, so once a program knows how its loads go, an `...Async` call and an
ensured synchronous load cost alike. main's fall from round 1 (76 turns to 49, failed builds from 4 to 6 a run to 0 to 2, page runs
from 31 to 33 to 12 to 16, the rounds not overlapping) goes with the load refusals it no longer met and the shader refusal. What
round 1 cost main is learning at its first compile that its loads differ from raylib's. ensure's fall over the rounds (62 turns to
57) is within its runs' spread.

**A font ensured must be whole at once** (round 1). An ensured font was given empty and filled a frame or two later. ensure.001's
`SetTextureFilter` on the font it had just loaded threw in the page, and ensure.003 saw the empty font and turned to
`LoadFontExAsync`. `7f66628` makes the glyphs during the call. None of round 2 or 3 met it.

**Before the Shaders line, every entrant wrote its GLSL in strings.** All nine of rounds 1 and 2 called `LoadShaderFromMemory`
(ensure.006 `LoadShader` too), read the refusal, moved the GLSL to files and added the `CompileShaderFile` lines the refusal names,
at their next step. ensure's entrants then loaded the result with `LoadCompiledShaderAsync`, the only `...Async` calls left in their
programs beside ensure.003's font. base.002 and ensure.006 also met `CompileShaderFile`'s error for a fragment shader reading
`fragPosition` with raylib's default vertex shader, and wrote a vertex shader.

**With the line, none wrote `LoadShader`.** All six of round 3 wrote their shaders as files and their `CompileShaderFile` lines
first, with no shader error in a build. main's loaded them with `LoadCompiledShaderAsync`. ensure's ensured the `.shader` files with
the rest and loaded them with `LoadCompiledShader`, and their programs have no `...Async` call.

**What both met, in every round.** Fourteen of the fifteen wrote a skinning vertex shader of their own for the hit flash, as the lit
shaders' vertex stage isn't a program's to use. Seven first used `VirtualButtonOptions` without its import. Seven compared an
`Int` from `Std.parseInt` with `null`. Four called `rlGetTextureIdDefault`, read its refusal and drew their quads with the default
texture or a white one of their own. Most noted that `UpdateModelAnimationMasked` blends two animations where a crossfade under an
attack needs three.

## Scoring

Each program was built for the page as it stood, from its own `build.hxml`, and run in headless Chromium on the GPU at 1280 x 720
(`score_page.py --viewport 1280x720`): main's against `0012bce`, ensure's all against `f6fb846`. All fifteen built and drew their
title. Each logged one console error, the browser's 404 for `wardens.sav`, which a first run hasn't saved. base.006's title shows the
warden lying down.

Round 3's six were also run into play through their own `run.cjs` and options, in the sandbox's software browser, with 40 enemies
for 240 frames or more. Each drew the arena, the crowd lit and skinned through its own shader, and the HUD, and ended in play, at
its level-up cards or at its game over.

Not scored: frame times, the spec's items, and the native builds beyond each entrant's own run of its `native/Main`.
