# The jam: helix-raylib against HeliX (planned)

Whether a framework's structure (HeliX: a stage, nodes, a loader, UI, an animator) beats a familiar API agents were trained on
(helix-raylib: raylib 5.5's, with raygui) when agents build a real game with the docs in hand, as they would in practice. Its answer
decides Gyre's shape (DECISIONS 40): if HeliX's entrants don't do better, HeliX's useful parts become services or extras, and Gyre's
API isn't kept for its own sake.

The game is [Wardens](spec.md), a 3D top-down survivors-like: skinned characters wearing swappable gear and weapons held at a bone,
up to 200 animated enemies, a level-up choice drawn as skinned UI, sound, saves and run options. It is small enough for an agent's
session, and it leans on what an engine is for (models, animation, attachments, UI, many things on screen) more than on game logic,
which would be the same on either side.

The blind trials of helix-raylib ([../README.md](../README.md)) build the same game natively, from raylib's own headers: helix-raylib's
brief and `build.hxml` are in `native/`, the C control's brief and `Makefile` in `native-c/`, and `run_entrant.py` starts an entrant. The rest of this page is the jam's.

## Entrants

Three on each engine, all Sonnet, each a fresh `claude -p` from a scratch directory outside any git repository, against one commit
of each repository (a worktree with its own haxelib copy, so nothing changes under an entrant while it works):

- **helix-raylib:** `import helix.raylib.Raylib.*;` with `Raygui`, `Raymath`, `Rlgl` and the extras. Its docs: engines/raylib/README.md,
  docs/api/raylib*.md and docs/api/raylib-extras.md, as files in the entrant's directory.
- **HeliX:** `-lib helix`, a game written as `haxelib run helix init` writes one. Its docs: its README, BUILDING.md, docs/ (the guide,
  DISPLAY_MODEL) and its API docs, copied in the same way.

## The brief (each entrant's prompt)

> Build the game in `<dir>/spec.md` in Haxe with `<engine>`, for the browser and natively.
>
> - **Docs:** the engine's docs are in `<dir>/docs/`. Read them as you need. Don't read the engine's sources or the web.
> - **Assets:** the game's files are in `<dir>/assets/`.
> - **Building:** `<build command for the page>` and `<build command native>`. Build as often as you like. You may run the page in
>   `<headless runner>` to see a screenshot, as a developer would look.
> - **Writing:** write to `<dir>` only: the game's `.hx` files, then `NOTES.md` with each build error and what you changed, each place the
>   docs left you guessing and what you guessed, and anything you expect not to work.
> - **Budget:** stop at 3 hours or when the spec is met, whichever comes first, and reply with one line saying which.

The engine names, build commands and runner are filled in per engine. Nothing else differs.

## Measured

| measure | how |
|---|---|
| Effort | tokens in and out, wall-clock time, from each transcript |
| Builds | the builds run, how many failed, and the errors by kind |
| Code | lines written, split by a reviewer into engine-substitute code (what an engine could have given: animation blending, attachments, UI widgets, nine-slice drawing, pooling, a particle system, a skinning shader) and game logic |
| Spec met | a reviewer's reading of the code against the spec's items (met, wrong, missing, can't tell), and a play pass on both targets driven by input scripts, as the drift-field trial graded |
| Bugs | what the play pass finds, by severity |
| Frame time | `enemies=50`, `100` and `200`, `seed=1`, `quit_after_frame=1200`: the mean and p95, natively (GL and SDL_GPU) and in a page, on the real display; the page again with Chromium's CPU throttled 4x, as a phone |
| Shaders | the shaders each entrant wrote (the ground effects, the hit flash), and how its animated enemies are skinned: on the GPU (and by what: the engine's own, a shader of its pieces, one written whole) or on the CPU |
| Size | the page's files fetched, raw, gzip and brotli; the native binary stripped |
| Startup | to the title's first frame, natively and in a page |
| A change | a fresh Sonnet, given the finished game and its notes, adds a dash on Space (a 4 meter dash, 2 seconds' cooldown shown as a bar under the warden) and a new card ("Twin blades": a second sword in the left hand, on `Wrist.L`, striking behind her). Measured as above, plus what it broke |

The reviewers are agents that wrote neither the spec nor a game, and see neither the other engine's results nor the entrants' notes
until their grades are in.

## Before the run

- **Engines ready:** raygui and its skins built on helix-raylib, and both engines building the spec's features: skinned parts on one
  skeleton, an attachment at a bone, blended animations, many skinned models, a nine-slice image, a program's own shader on a ground
  quad and on an animated, lit model, many additive sprites.
- **Prototypes:** a prototype of the hard parts on each engine by the person running the jam (not an entrant), so a failure is the
  entrant's and not a missing feature. What the prototypes find is fixed first and recorded.
- **Assets:** made and put in `assets/`. The characters are Quaternius's Ultimate Modular Women (CC0, the 40 parts, `Sword.glb`,
  `Gun.glb` and `Animations.glb` with its 24 clips), as HeliX's dressing-room example has them. The UI art, font, sounds, music and dungeon models are CC0 from Kenney, KayKit and HoliznaCC0, credited in `assets/CREDITS.md`. The icons are drawn by a script kept here (`gen_assets.py`).
- **Run options checked** on both engines' builds, so measuring needs nothing from an entrant beyond the spec.
- **Briefs:** each brief states its exact checks and time budget, and nothing beyond them.
