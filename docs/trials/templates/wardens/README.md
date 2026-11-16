# Wardens

A 3D top-down survivors-like: skinned characters wearing swappable gear and weapons held at a bone, up to 200 animated enemies, a
level-up choice drawn as skinned UI, sound, saves and run options. The engine trials build it.

- `spec.md`: the game, naming no engine or function. `grading.md`: its 37 items a run is graded on.
- `assets/`: its models, sounds and UI art, made by `gen_assets.py` and `render_outfits.py` from `icon-sources/` and the packs
  `assets/README.md` names.
- An entrant's brief and build files for each engine: `native/` (helix-raylib natively, `brief-extras.md` with the extras),
  `native-c/` (raylib 5.5 in C), `page/` (helix-raylib with a page to build and run in as it works, native at the end) and `three/`
  (three.js).
- `review-brief.md`: the brief of the agent grading a run.

A trial is made from it by `../../tools/run_entrant.py` (`--engine helix`, `c` or `three`, `--extras`, `--page`), its native runs
shot by `take_screenshots.py` and graded with `review-brief.md`, and recorded in `docs/trials/<date>-<name>/` with the spec and
briefs it used and its `results.md`.
