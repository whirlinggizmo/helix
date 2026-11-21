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
- `results/`: one file a trial, `<date>-<name>.md`, its first lines saying what it asked and what it found. Nothing else of a
  trial is in the repository.

## Running one

- **Its inputs.** What its entrants are given (a task, briefs, build files, a draft's sources) is made in
  `/home/rknopf/projects/local/helix/trials/<trial>/inputs/`, from a template, and handed to `run_entrant.py --trial`.
- **Where.** Each entrant runs in a directory of its own under `/home/rknopf/projects/local/helix/trials/<trial>/`, outside any git
  repository, as it would read the repository's commit messages. It is a fresh `claude -p`, never a subagent of a session working on
  helix. Its saves and cache are in `.home/<entrant>` beside it.
- **Its walls.** A sandbox (bubblewrap) lets it write only to its directory, its saves and its session, and hides the rest of the home,
  the machine's devices and /tmp. It runs on a private display with no sound and no session D-Bus.
- **Against what.** One commit of helix: a worktree with its own haxelib, so nothing changes under the entrant.
- **Watching.** As AGENTS.md's "Watch, don't wait" says, with `tools/watch_job.py` on its `run_entrant.py` process and its session's
  transcript (`~/.claude/projects/<its directory, dashed>/*.jsonl`, which grows each turn; `run.log` holds only the start and end),
  its deadline the brief's budget.
- **Recording.** `results/<date>-<name>.md` says what the entrants were given, briefly, and the commit it was tried at. It gives the runs (cost, time, turns, the tokens in and out from `result.json`, and a game's items met),
  what was found and what changed for it. A game's runs are graded by fresh agents from each program's code and screenshots
  (`take_screenshots.py`, the template's `review-brief.md`), without its notes.
- **Pruning.** Once its results file is committed, `prune_trial.py <results file> <runs directory>` deletes the runs and the inputs.
  The transcripts stay.
