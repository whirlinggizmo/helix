# Wardens on raylib C, helix-raylib and a plain binding (2026-11-15)

What an agent pays to build Wardens with an engine that looks like raylib, against raylib itself. raylib in C is the baseline: a
language and an API agents know well. Nine fresh Sonnet agents built [Wardens](spec.md) natively from the spec alone, no
extras and no hints, 3 hours each at most, three on each:

- **C** (`c.001` to `.003`): raylib 5.5 in C, its own library (`run_entrant.py --engine c`, the brief
  [brief-c.md](brief-c.md)).
- **helix-raylib** (`helix.001` to `.003`): the branch `ensure-assets` at `3493423` (`run_entrant.py --engine helix`, the brief
  [brief-helix.md](brief-helix.md)). Natively its loads are raylib's synchronous ones, and `LoadShader` is refused for
  `LoadCompiledShader`.
- **raylib-hx** (`hx.001` to `.003`): raylib 5.5 in Haxe through a plain binding, [raylib-hx](https://github.com/foreignsasquatch/raylib-hx)
  at `a32f420` (hxcpp externs over raylib's C), with its raylib moved to the 5.5 tag and raygui 4.5-dev and rlights bound in its own
  style (the brief [brief-hx.md](brief-hx.md)). The harness's raylib-hx engine was removed once this was recorded. Its brief is the helix-raylib brief but for
  the line on how raylib looks: package `raylib`, `import raylib.Raylib.*; import raylib.Types;`, structs of raylib's names and
  fields, its pointers pointer types.

Asked from memory, without tools, two Sonnet agents knew raylib-hx by name alone, and rated their guesses at its imports, structs and
pointers 10 to 25 out of 100. Its API was as new to the entrants as helix-raylib's.

The C and helix-raylib runs started at 20:24, 90 seconds apart and taken in turn. The raylib-hx runs started at 20:47, while those
ran. All ran on coinspinner. The runs and the binding were deleted once graded and recorded.

## Runs

| run | cost | time | turns | lines | builds | failed | runs | input | cache write | cache read | output | items met |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| c.001 | $2.68 | 21.1 min | 71 | 1,898 | 16 | 0 | 32 | 96 | 196k | 6.9M | 121k | 36 |
| c.002 | $2.67 | 25.4 min | 68 | 1,700 | 25 | 1 | 33 | 106 | 186k | 7.4M | 118k | 37 |
| c.003 | $1.85 | 14.0 min | 45 | 1,267 | 11 | 1 | 15 | 78 | 139k | 4.4M | 84k | 37 |
| helix.001 | $2.55 | 28.7 min | 65 | 2,035 | 27 | 4 | 28 | 110 | 183k | 7.3M | 108k | 34 |
| helix.002 | $1.96 | 23.9 min | 49 | 1,944 | 23 | 5 | 19 | 80 | 146k | 4.3M | 94k | 35 |
| helix.003 | $3.02 | 30.4 min | 109 | 2,249 | 41 | 4 | 52 | 156 | 205k | 10.3M | 116k | 36 |
| hx.001 | $3.91 | 29.9 min | 108 | 2,607 | 50 | 12 | 50 | 166 | 247k | 13.4M | 157k | 35 |
| hx.002 | $2.90 | 20.8 min | 80 | 1,849 | 17 | 8 | 4 | 144 | 191k | 9.9M | 113k | 32 |
| hx.003 | $6.06 | 49.4 min | 173 | 1,782 | 59 | 11 | 76 | 296 | 316k | 28.8M | 191k | 35 |

Lines are the program's own source. Builds are its `cmake --build` or `haxe build.hxml` commands, failed the ones with an error,
and runs its runs of the native program. Input (uncached), cache write, cache read and output are tokens, from `result.json`.
Items met are of the 37 in [grading.md](../templates/wardens/grading.md).

| | cost | turns | cache read | output | failed builds | items met |
|---|---:|---:|---:|---:|---:|---:|
| C | $2.40 | 61 | 6.2M | 108k | 0 to 1 | 36.7 |
| helix-raylib | $2.51 | 74 | 7.3M | 106k | 4 to 5 | 35.0 |
| raylib-hx | $4.29 | 120 | 17.4M | 154k | 8 to 12 | 34.0 |

## What it found

**helix-raylib costs about what C does.** $2.51 against $2.40, 5% more, where each group's runs spread by more than a dollar ($1.85 to
$2.68, $1.96 to $3.02). Each met the refusal of `LoadShader` once and wrote `CompileShaderFile` lines after it. The rest of their 4 to
5 failed builds were Haxe's ordinary errors: a `Float` where an `Int` goes, an optional count, a mixed array.

**A plain binding costs much more.** raylib-hx's cheapest run ($2.90) cost more than every C and helix-raylib run but one, and its
mean is 79% over C's. Its entrants failed 8 to 12 builds each, 39 to 119 errors in all, where helix-raylib's met 6 to 12. raylib's C
reached them through the binding: a pointer or a C string where a Haxe type was expected (`raylib.utils.IntPointer should be Int`,
`cpp.CastCharStar should be String`), a struct field the binding lacks (`raylib.MeshImpl has no field boneCount`), and errors only the
C++ compiler gave, from a name of the program's own meeting one of raylib's C macros (`expected ')' before numeric constant`) or a
pointer conversion the Haxe compiler let through. hx.003 spent 173 turns and 28.8M tokens of cache reads.

**What Haxe costs can't be read off raylib-hx.** Its cost is mostly its binding's, the C showing through, not the language's. Over a
plain binding, what helix-raylib does was worth about $1.80 a run here.

**The cheap runs weren't the unfinished ones.** Every run met 32 to 37 items. c.003, the cheapest of the nine, met all 37. A run cost
more when it wrote more and ran its program more to look at it (c.001 ran its program 32 times, c.003 15), not when it met more.

**What was graded wrong:**

| run | items wrong |
|---|---|
| c.001 | 22: an in-view spawn point taken when an out-of-view one was drawn |
| helix.001 | 10, 11: the touch controls turn on only when a finger is down and the left mouse button isn't, and helix-raylib reports a finger as the left button, as raylib does; 13: each attack restarts the legs' run cycle |
| helix.002 | 15: every character surface drawn alike; 25: the gem a stretched sphere, not a spinning crystal |
| helix.003 | 22: one spawn in four put in view on purpose |
| hx.001 | 1: the view not kept framed when resized; 15: an outfit's metallic and roughness taken from its first mesh |
| hx.002 | 2, 8, 12, 21: every skinned body posed wrongly, arms bent up at the shoulders; 14: HitRecieve blending over 0.1 s |
| hx.003 | 21: the enemies' meshes merged by clustering their vertices, breaking their arms; 26: sparks that don't fade |

## Grading

[grading.md](../templates/wardens/grading.md) lists 37 items of the spec, each judged from the code, from screenshots, or both. Speed isn't
graded: it is timed apart, on the GPU. `take_screenshots.py` ran each native program on a private display of 1280 x 720 with
`--enemies=10 --seed=1`: the title, a click on its Play button (found on the title's shot), play, D held, pause, play on, and a second
run with `--enemies=200`, on Mesa's software renderer. Each run was graded by a fresh Opus agent from its code and the shots, without
its notes ([review-brief.md](../templates/wardens/review-brief.md)).

The first grades passed hx.002 on all 37 items: its reviewer judged the bodies from the code, which shares one skeleton as it should,
and the play shots are small. The brief then asked that every body be judged in the shots too, its title shot large, and all nine were
graded again by fresh agents, the grades above. Between the two passes c.003's grade moved by one item (its sword's reach of 2.3 m
read once as wrong, once as within the spec), so a difference of an item between two runs is a reviewer's, not the program's.

Not measured: frame times, touch on a touch screen, sound, and the gamepad.
