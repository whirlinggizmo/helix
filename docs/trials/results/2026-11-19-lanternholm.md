# Lanternholm built on helix-raylib with the extras (2026-11-19)

What its entrants were given is in `docs/trials/2026-11-19-lanternholm/` at commit `7b0b153`, the paths below under it.

What Lanternholm costs an agent to build from its spec on helix-raylib with the extras, and what the extras leave the agent to
write. Three fresh Sonnet agents built [Lanternholm](../templates/lanternholm/spec.md) natively from the brief (`brief.md`), against
helix at `6e68f47`, 4 hours each at most. They started together at 22:19 on coinspinner, where another session's builds ran for
about 15 of the minutes, so the times are a shared machine's.

| run | cost | time | turns | input | cache write | cache read | output | lines | met of 35 |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
| 1 | $3.31 | 22.3 min | 89 | 124 | 232k | 9.5M | 144k | 2,761 Haxe, 250 GLSL | 28 |
| 2 | $4.74 | 35.5 min | 134 | 178 | 298k | 17.5M | 180k | 2,982 Haxe, 218 GLSL | 30 |
| 3 | $3.63 | 28.4 min | 81 | 106 | 257k | 9.2M | 168k | 3,283 Haxe, 217 GLSL | 31 |

Each ended saying the spec was met. The [port](2026-11-14-lanternholm-port.md) before the extras had 21 of 35 for $14.45.
It was one Opus agent porting the three.js source, so the two differ by more than the extras.

## Grades

Each run was graded by a fresh Opus agent on [the 35 items](../templates/lanternholm/grading.md), from its code and the screenshots
the grading names, taken natively on a private display, without its notes. Item 35, the frame rate, is "can't tell" in each: the
display's GL is software, and nothing was timed. No item is missing in any run. The wrong items:

- **Run 1:** the crystals 1.7 times the spec's length (6), the pond one flat gray-green (7), the waterfall a gray column and its
  mist a dark blob (8), 9 trees at the start where the spec has 11 (23), the dust dark specks (24), and the title's face (28).
- **Run 2:** the stream's water still (8), the boat one colour, its gunwale's never drawn (12), dawn and dusk lit flat, with no
  orange on the sun's side (17), and the title's face (28).
- **Run 3:** the grass (20) and the trees' leaves (23) never swaying, by one line of its vertex stage, and the title's face (28).

The title's serif face is wrong in all three, as in the port. Every other wrong item is one run's own.

## What they wrote themselves

| what | run 1 | run 2 | run 3 |
|---|---|---|---|
| Shadows | the Lighting extra's, a 4096 map | the Lighting extra's, 2048 | the Lighting extra's, 4096 |
| A lit shader of its own, for the sway, the flowers closing and the glow | 67 GLSL lines, calling `helixLight` | 92, its own light with `helixShadow` | 121, its own light with `helixShadow` |
| Particles (smoke, mist, dust, fireflies) | its own billboards | its own billboards, 221 lines | its own billboards |
| The glow at night | a bloom pass, 3 render textures | additive billboards | additive billboards |
| The sky, sun, moon and stars | a full-screen shader, 84 lines | 82 | 96 |
| A mesh builder | 225 lines | 237 | 305 |
| Sound made in code, as `Wave`s | 117 lines | 122 | 124 |

None wrote a shadow, where the port wrote 120 lines of them. Each made one light, the sun by day and the moon by night, and cast
its shadows with `EnableLightShadows` and `BeginShadowMode`. None used the Particles extra. Run 2's notes say its page went
unread, as sprites were enough.

## Found

- **`helixShadow` alone lit nothing, 2 of 3.** A shader of the program's own calling `helixShadow` and reading no other field of
  `lights` was drawn as if no light cast, without a word. Runs 2 and 3 each kept a dead read of the lights. Fixed (`1c26cce`).
- **`gl_FragCoord.y` on the screen, 1 of 3.** Run 2's sky shader flips it. Run 2 judged its sky from its screenshots. From a
  program's first screen read on, helix-raylib drew each frame into a target (DECISIONS 75), where `gl_FragCoord.y` counted from
  the top. A probe on a GPU (NVIDIA) found the C implementation of raylib counting from the bottom on the screen and in a render
  texture. helix-raylib matched it except in the frames of a screen read on GL and in a page, and on the screen in every frame on
  SDL_GPU. Fixed: `gl_FragCoord.y` counts from the bottom row of the image in every pass (DECISIONS 84). On the trial's display
  (Xvfb, Mesa's llvmpipe) the C implementation counts the screen from the top once the same shader has drawn into a render texture
  in the frame, and from the bottom without that pass. Six of raylib 5.5's example shaders read `gl_FragCoord`.
- **No serif face, 3 of 3.** The spec asks for a serif title and the program ships no font, so each asked for a font of the
  system's by its absolute path. A path is read under the asset host, natively as in a page, so the load failed and each drew in
  raylib's default font. The port met the same. The failure read "no source has it", and now reads "file not found in any of the
  asset sources". Run 3's notes say `FileExists` answers true for such a path. Checked natively, `FileExists` answers false, and
  its log read "Loading" with no line after. Fixed: a false answer logs the failure, and "Loading" is a load's line alone.
- **`TakeScreenshot` missed the controls, 3 of 3.** Each called it after its last `EndDrawing` and quit, and `CloseWindow` refused
  the screenshot. Each moved the call before `EndDrawing`, where the draws waiting in rlgl's batch weren't in the screenshot, as in
  raylib. Each found `rlDrawRenderBatchActive` within a round. Fixed: the screen reads draw the batch first (DECISIONS 85).
- **`LoadShaderFromMemory`'s refusal, 3 of 3.** Each moved to `CompileShaderFile` and `LoadCompiledShader` from the message alone.
- **Compile errors otherwise** were Haxe's and GLSL's: a type in another module without its import (3 of 3, five rounds in run 2,
  where the compiler named other things), an integer literal past 32 bits (2), a private member read from another class (2), an
  array of mixed types (2), and `patch`, a reserved word in GLSL (2).
- **Not reproduced:** run 2's notes say `gl_FrontFacing` seemed inverted. The probe's cube, a mesh of the library's drawn without
  culling, is front-facing on the screen.
- **Not checked:** run 1's grader took its dark waterfall, mist and dust for translucent draws lowering a render texture's alpha.
