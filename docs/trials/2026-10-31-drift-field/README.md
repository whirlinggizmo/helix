# 2D trial: Drift Field (2026-10-31)

Whether agents writing raylib from memory can build a game on the API added since the [async trial](../2026-10-30-async/README.md):
a 2D camera that zooms, turns and picks, a second view clipped to a frame, seeded randomness, dropped files, with the async loads.
Three fresh agents (two Opus, one Sonnet) were each given the brief below as their prompt, and a directory holding only the
[spec](spec.md), the [assets](assets) and [build-web.hxml](build-web.hxml). The spec says what the game does and names no function.

All three built against one commit, c50a861: a worktree of it with its own haxelib, so nothing changed in the repository while they
worked reached one agent and not another. Each agent's game and notes are in `agent-1/` to `agent-3/`, with `compiles.md`: every compile
it ran and its whole output, taken from its transcript, so nothing it left out of its notes is lost.

## The brief

The async trial's, its first line reworded and its account of how raylib looks in Haxe cut to one line:

> Implement the game described in `<dir>/spec.md` in Haxe, using **raylib 5.5's API**.
>
> - **The API is raylib 5.5's,** implemented in Haxe as `helix.ray.Raylib`.
> - **Files.** The game's files are in `<dir>/web/assets/`; the program names them as `"assets/player.png"`, `"assets/coin.wav"` and
>   `"assets/levels/level1.txt"`.
> - **Read nothing outside `<dir>`:** no library sources, no documentation, no web. Learn helix-ray only from what the compiler tells
>   you.
> - **You may compile**, as often as you like: `cd <dir> && HAXELIB_PATH=<worktree>/build/haxelib haxe build-web.hxml`. Fix what the
>   compiler reports. Don't run the program; it is run for you afterwards, in a browser and natively.
> - **Write to `<dir>` only:** `Main.hx` (and more `.hx` if you like), then `NOTES.md` with:
>   - every compile error you hit, in order, and what you changed for it;
>   - each function or behavior you were unsure of, and what you guessed;
>   - anything you expect to work differently from raylib on the desktop.
> - Stop when it compiles cleanly and the notes are written, and reply with one line saying so.

## Grading

By two agents that wrote neither the spec nor the games, neither seeing the other's results or the agents' notes:

- **[Reading](grading/reading.md):** the code against the spec, 65 items, each met, wrong, missing or can't tell, with the line that
  settles it.
- **[Playing](grading/play.md):** each game in headless Chromium and natively on a private display (xdotool, and real XDND drags for
  dropped files), 10 items. The field was graded by its coordinates: the grading build puts a [recorder](grading/recorder/trial/Recorder.hx)
  on `helix.ray.Raylib` by a macro, logging each draw call, so the games and helix-ray are left as they are. The drop files are in
  [grading](grading); the drivers in [grading/play](grading/play).

## Results

| | Agent 1 (Opus) | Agent 2 (Opus) | Agent 3 (Sonnet) |
|---|---|---|---|
| Compiles to a clean build (probes included) | 6 | 3 | 5 |
| Reading: met / wrong / missing / can't tell, of 65 | 62 / 3 / 0 / 0 | 62 / 2 / 0 / 1 | 59 / 6 / 0 / 0 |
| Playing at c50a861: met / wrong, of 10, page and native alike | 9 / 1 | 9 / 1 | 7 / 3 |
| Playing after 4972b77 | 10 / 0 | 10 / 0 | 7 / 3 |
| Randomness | `SetRandomSeed`, `GetRandomValue` | `SetRandomSeed`, `GetRandomValue` | its own LCG |

Met in all three, on both targets: the speed (298 to 302 px a second, on a diagonal too, with frames throttled), a click flying the ship
to the point under the pointer at zoom 0.5, 1 and 2 and turned (error 0 against raylib's formula), the zoom clamp, the turn rate and R,
the map clipped by `BeginScissorMode` at every zoom, turn and size, the text outside camera mode and keeping to the edges after a resize,
rocks and the edge stopping the ship, the level flow to "You win! Score: 75", the best score after a reload and a restart, Escape.
Nothing crashed.

## What it found

- **`UnloadDroppedFiles` deleted the dropped bytes,** so all three games, which unload the list straight after starting the read as
  raylib allows, refused every drop, on both targets. In raylib the file stays on disk. Fixed in 4972b77: it lets go of the list alone,
  the bytes kept until the next drop; the same games, rebuilt, play dropped levels on both targets.
- **raylib's generator carried over; a hand-rolled one didn't.** Agents 1 and 2 seeded raylib's, and their fields match over runs and
  between the page and natively, and differ by seed. Agent 3 wrote an LCG whose product passes 2^53: in the page its field crowds the
  top-left, natively every rock is one rectangle and the seed changes nothing. That is the agent's fault, not helix-ray's.
- **A refused synchronous call, named but not called, says nothing useful.** Agents 1 and 2 learned signatures with `$type(...)`;
  `$type(LoadTexture)` gives "Macro functions must be called immediately / Invalid macro access" rather than the refusal, which needs a
  call. Both then called it.
- **The one line was enough.** Two agents met "Type not found" or "Unknown identifier : Camera2D" and added `import helix.ray.*;` at
  once; the third's game compiled the first time. All three switched every load to the Async ones from the compiler's messages, as in
  the async trial, and set `SetExitKey(KEY_NULL)` unprompted.
- The games' own faults, by grade: agent 3 saves the best score only at a level's end, never null-checks its texture and sound, and
  takes "12abc" for a number; agent 2 never clamps the frame time; agents 1 and 3 draw crystals `SKYBLUE` for cyan; agent 2's map
  frame is 4 px over.

## How far it goes

- Three agents and one 2D game of 435 to 574 lines each, all Claude.
- Gamepad, touch and native sound weren't exercised (the dummy driver plays nothing).
- The drop files the play grader used are its own, made from the spec when it didn't find the ones written for it: a valid level with
  seed 777, the same with seed 778, and one with `width=wide` and no `target`.
- The 3D trial whose loads come one after another waits for models and materials.
