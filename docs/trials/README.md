# Trials

A trial gives part of helix to fresh agents who know nothing of it, and reads where they guess and what it costs them.

## When

- **A library's API, when the user asks.** Fresh agents write against its types and doc comments alone (AGENTS.md). A guess one
  makes is answered by changing the API, so the question can't come up again. An extra is found only when a brief hands it over.
- **A departure from raylib, before it's pushed.** A change adding or moving a refusal or a build step in helix-raylib gets a trial.
  Each guess an entrant makes at the change is answered where the entrant met it: in the refusal's message, or in the doc of the call
  it reached for. A change bringing helix-raylib back to raylib's own behaviour needs none.
- **What an engine costs to build with.** Fresh agents build a game from its spec, on helix-raylib and on raylib in C, the baseline.

## Layout

- `templates/`: what a trial is made from. [wardens](templates/wardens) and [lanternholm](templates/lanternholm) are games, each
  with its spec, assets, grading and a brief for each engine. [api](templates/api) is a trial of part of helix-raylib's API.
  `assets/` holds the files the earlier 2D trials gave, which the size ladder names.
- `tools/`: `run_entrant.py` makes an entrant from a template and starts it, in a sandbox. `take_screenshots.py` shoots a native run
  for grading. `score_page.py` and `score_frames.py` build a run for a page and time it. `prune_trial.py` deletes a trial's runs once
  it is recorded. Each says how with `--help`.
- `<date>-<name>/`: a trial, holding what its entrants were given (spec or task, briefs, build files, a variant's docs) and
  `results.md`. Its entrants' source and the assets stay out (`.gitignore`).

## Running one

- **Where.** Each entrant runs in a directory of its own under `/home/rknopf/projects/local/helix/trials/<trial>/`, outside any git
  repository, as it would read the repository's commit messages. It is a fresh `claude -p`, never a subagent of a session working on
  helix. Its saves and cache are in `.home/<entrant>` beside it.
- **Its walls.** A sandbox (bubblewrap) lets it write only to its directory, its saves and its session, and hides the rest of the home,
  the machine's devices and /tmp. It runs on a private display with no sound and no session D-Bus.
- **Against what.** One commit of helix: a worktree with its own haxelib, so nothing changes under the entrant.
- **Watching.** As AGENTS.md's "Watch, don't wait" says, with `tools/watch_job.py` on its `run_entrant.py` process and its session's
  transcript (`~/.claude/projects/<its directory, dashed>/*.jsonl`, which grows each turn; `run.log` holds only the start and end),
  its deadline the brief's budget.
- **Recording.** `results.md` gives the runs (cost, time, turns, the tokens in and out from `result.json`, and a game's items met),
  what was found and what changed for it. A game's runs are graded by fresh agents from each program's code and screenshots
  (`take_screenshots.py`, the template's `review-brief.md`), without its notes.
- **Pruning.** Once `results.md` is committed, `prune_trial.py <trial> <runs directory>` deletes the runs. The transcripts stay.

## Trials

| trial | asked | found |
|---|---|---|
| [2026-11-19-lanternholm](2026-11-19-lanternholm/results.md) | What Lanternholm costs to build from its spec on helix-raylib with the extras, and what the extras leave to write | $3.31 to $4.74 a run, 28 to 31 of 35 met; each cast the Lighting extra's shadows and wrote its own particles; `helixShadow` alone lit nothing |
| [2026-11-18-quaternions](2026-11-18-quaternions/results.md) | Whether agents get past a `Vector4` that isn't a `Quaternion`, as it is in C | The one that met it (1 of 3) retyped its keys from the compiler's message alone; all met the task, $0.19 to $0.23 |
| [2026-11-16-example-headers](2026-11-16-example-headers/results.md) | Whether agents reach for `rlights.h` and `reasings.h`, raylib's examples' headers, unprompted | 0 of 3 for either: each wrote its own lights' uniforms and easing curves |
| [2026-11-16-particles](2026-11-16-particles/results.md) | Whether agents make a camp at night's effects with the Particles extra from its page alone | 3 of 3 met the task, $0.32 to $0.63, no compile error; a shell spawn, a pulse, speed apart from direction and keys including the ends asked for |
| [2026-11-17-lighting-tweens](2026-11-17-lighting-tweens/results.md) | Whether agents use the Lighting extra and the tweens when the brief hands them over, on the example headers trial's task | 3 of 3 used both and wrote no shader or curve, $0.23 to $0.24, about 40% fewer tokens written; two tweens of one value in a sequence left each guessing |
| [2026-11-15-wardens-baseline](2026-11-15-wardens-baseline/results.md) | What Wardens costs on helix-raylib, on raylib C and through a plain Haxe binding | helix-raylib $2.51 a run, C $2.40, raylib-hx $4.29; C's pointers and macros leak through a plain binding |
| [2026-11-15-wardens-cost](2026-11-15-wardens-cost/results.md) | Whether raylib's loads after an ensure cost less than `...Async` loads, in a page | A lean in round 1 ($2.01 against $2.19); alike once the brief says how to load |
| [2026-11-15-lighting-shadows](2026-11-15-lighting-shadows/results.md) | The Lighting extra's shadows, emissive and alpha cutoff, as a draft | Shadows drew the scene twice a light; a program's own lit shader got no lights |
| [2026-11-15-shadowmaps](2026-11-15-shadowmaps/results.md) | Porting raylib's shadowmap example, as a draft | Both ported it unchanged, asking only which texture unit the depth binds to |
| [2026-11-15-screen-fit](2026-11-15-screen-fit/results.md) | The Screen extra's fits, as a draft | Both fitted as meant; asked where the design sits when a fit grows the screen |
| [2026-11-14-lanternholm-port](2026-11-14-lanternholm-port/results.md) | What a three.js-shaped program needs that helix-raylib lacks | 21 of 35 met; it wrote shadows, particles, bloom and meshes itself, and met a render-pass failure |

Retired, their findings acted on. Each record is in the commit named:

| trial | asked | found | commit |
|---|---|---|---|
| 2026-11-15-ensure | Whether a brief's line brings agents to ensuring files, so a native program works in a page | The three told ensured every file and worked in a page unchanged; the three not told drew nothing there | `5f751aa` |
| 2026-11-15-object-casts | Whether a refused `cast` from an object sends agents to braces | All three meeting the refusal wrote the objects in braces; none writing fresh cast | `2c53370` |
| 2026-11-14-take-screenshot | `TakeScreenshot` saving at the next `EndDrawing` | C's habit of calling it after `EndDrawing` met the refusal, and the refusal fixed it | `f532c32` |
| 2026-11-14-touch-emulation | Touch emulation from its doc comments, as a draft | The left mouse button as one finger, built as Godot and Unity have it | `38215a5` |
| 2026-11-14-null-font | Whether a font still loading is kept out of the text calls | None met the refusal unprompted; given one, all measured once loaded | `1520942` |
| 2026-11-14-page-iteration | Whether building in a page as an agent works makes Wardens cheaper | No difference: $2.28 against $2.17 | `2fccc69` |
| 2026-11-14-buttons | GuiSkins' text offsets, icon textures and image buttons, as drafts | Built after five rounds | `03590b0` |
| 2026-11-13-fills | The Textures extra and GuiSkins' fills, as drafts | Built after three rounds | `03590b0` |
| 2026-11-13-wardens-extras | Whether the extras make Wardens cheaper | 17% cheaper, $2.17 against $2.61 | `8271fd7` |
| 2026-11-13-masked-blend, -aim | `UpdateModelAnimationMasked` from its doc comments | Used correctly in about 2 minutes; by hand, two of three mixed the poses wrongly | `b47a70d` |
| 2026-11-10-frame-stats-recording | The frame stats' recording, as a draft | Both compiled cleanly; their questions answered in the docs | `4aad0ea` |
| 2026-11-06-retained-sketch | What a retained engine on raylib's API needs | Nine gaps; the graph costs 6 to 8% at 400 robots | `02e9c1b` |
| 2026-11-04-gui-skins | Skinning raygui from a game's art, as a draft | GuiSkin moved to helix.raylib, a sheet cutter added | `d8126b8` |
| 2026-11-04-debug-drawing | The Debug extra's drawing, as a draft | Frame stats sized to the window; a missing import made a compiler note | `609e814` |
| 2026-10-31-drift-field | Refusals as deprecations in place of macros | Worse: refusals met later; dropped | `678c2dc` |
| 2026-10-30-async | Whether agents take to `...Async` loads from the compiler alone | All three switched from the errors alone | `b1da719` |
