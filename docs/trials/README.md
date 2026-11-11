# Trials

A trial gives part of helix to fresh agents who know nothing of it, and reads where they guess. Each folder here is one trial's record,
and [wardens](wardens) holds Wardens, the game the engine trials build.

## When

- **A library's API, before it's written.** Fresh agents write against its types and doc comments alone (AGENTS.md). A guess one
  makes is answered by changing the API, so the question can't come up again.
- **A departure from raylib, before it's pushed.** A change adding or moving a refusal, an extra or a build step in helix-raylib gets a
  blind trial. Each guess an entrant makes at the change is answered where the entrant met it: in the refusal's message, or in the
  doc of the call it reached for.

## Runs

Each entrant runs in a directory of its own outside any git repository, as it would read the repository's commit messages, under
`/home/rknopf/projects/local/helix/trials`:

- **A game's (a blind trial).** `<game>/<arm>-blind.<NNN>`, as `wardens/helix-raylib-blind.001` and `wardens/raylib-c-blind.001`.
- **An API's (a library trial).** `<api>/<arm>-docs.<NNN>`, as `frame-stats-recording/helix-raylib-docs.001`: the API tried, and
  "docs" as its entrants learn it from doc comments alone.

`<arm>` is what the entrant writes against (helix-raylib, raylib-c). `<NNN>` counts that arm's runs of the game or API across trials.
Beside them, `.home/<run>` holds each run's saves and cache, and each score's copy of a run is kept beside it, named for the score
(`<run>.page`, `<run>.frames`), the run's own directory left as the entrant left it. A trial's record here, `<date>-<api>` or the
game's folder, names its runs.

## A blind trial

- **Entrants.** Three on helix-raylib, on Sonnet, and the control: three writing the same game in C on raylib 5.5 itself, briefed
  alike but for the language and the build. Each is a fresh `claude -p` started in a run directory of its own (see Runs). None is a
  subagent of a session working on helix, as that session's commit messages would reach it.
- **What each is given.** A brief, the game's spec ([Wardens](wardens/spec.md)), raylib 5.5's own headers and C examples, and
  the game's assets. Nothing of helix's docs or sources. Where helix-raylib differs from raylib, the compiler says so.
- **How it builds.** Natively, with `haxe build.hxml`, against one commit of helix (a worktree with its own haxelib, so nothing changes
  under the entrant). It runs `./native/Main` on a private display, with no sound and no session D-Bus, and its saves and cache in
  directories of its own. It sees its game through raylib's screenshots. Its brief says nothing of pages.
- **Its walls.** It runs in a sandbox (bubblewrap) that lets it write only to its directory, its saves and its session, and hides the
  rest of the home (other checkouts, other entrants), the machine's devices and /tmp. The brief's "write only here" and "read nothing
  else" are kept by the sandbox, not by the entrant.
- **What it hands back.** The program, and `NOTES.md`: each compile error it hit and what it changed, each place raylib had no call for
  what the spec asks, and each guess.
- **Scoring.** Each program is built for the page as it stands and run there, its whole directory served, to see whether it works
  unchanged (`score_page.py`). Its frame time is taken by the library under it, not by the entrant: the program is built as it stands
  with the frame stats' hook (helix-raylib's `-D helix-raylib-frame-stats`; for raylib C, stock raylib 5.5 with `EndDrawing` wrapped at
  link time) and run at each load for a fixed run of frames (`score_frames.py`). Its notes are read against the change being tried.
- **Watching.** Each entrant's log is read every ten minutes while it runs. A harness fault stops the run early.

The harness is [wardens](wardens): each arm's brief and build file (`native/` for helix-raylib's `build.hxml`, `native-c/` for the
control's `CMakeLists.txt`), and `run_entrant.py`, which makes an entrant's directory from them, the spec, the assets and raylib 5.5's
release, and starts it against a checkout of helix; `score_page.py` builds and runs each helix-raylib entrant's program in a page;
`score_frames.py` times each entrant's program, natively (on a private display, or with `--desktop` on this machine's) and with
`--page` in a page:

```console
python3 docs/trials/wardens/run_entrant.py /home/rknopf/projects/local/helix/trials/wardens/helix-raylib-blind.001 --helix ../helix-blind-a
python3 docs/trials/wardens/run_entrant.py /home/rknopf/projects/local/helix/trials/wardens/raylib-c-blind.001 --helix ../helix-blind-a --engine c
python3 docs/trials/wardens/score_page.py /home/rknopf/projects/local/helix/trials/wardens/helix-raylib-blind.00* --helix ../helix-blind-a
python3 docs/trials/wardens/score_frames.py /home/rknopf/projects/local/helix/trials/wardens/*-blind.00? --helix ../helix-blind-a --page
```
