# Async trial (2026-10-30)

Whether agents writing raylib from memory take to helix-ray's `...Async` loads with nothing but the compiler to tell them
(DECISIONS 20 to 22). Three fresh agents (two Opus, one Sonnet) were each given the brief below, the [spec](spec.md), the
[assets](assets) and [build-web.hxml](build-web.hxml), in a directory of their own. Each one's game and notes are in
`agent-1/` to `agent-3/`.

## The brief

Each agent had the same brief, with `<dir>` set to its own directory. It doesn't mention the Async loads or `Raymath`. The spec
builds each level's file name from the level's number, so a synchronous load is the natural first try.

> Write the game in `<dir>/spec.md` in Haxe, using **raylib 5.5's API**.
>
> - **How raylib looks here.** helix-ray is raylib 5.5 in Haxe. Each raylib header is a class in package `helix.ray`: `raylib.h` is
>   `helix.ray.Raylib`, and `import helix.ray.Raylib.*;` brings its functions, constants and colors in unqualified, as raylib names
>   them. raylib's structs are classes of the same names and fields in `helix.ray`. Write it as you would write a raylib game.
> - **Files.** The game's files are in `<dir>/web/assets/`; the program names them as `"assets/player.png"`, `"assets/coin.wav"` and
>   `"assets/levels/level1.txt"`.
> - **Read nothing outside `<dir>`:** no library sources, no documentation, no web. Learn helix-ray only from what the compiler tells
>   you.
> - **You may compile**, as often as you like: `cd <dir> && HAXELIB_PATH=<repo>/build/haxelib haxe build-web.hxml`. Fix what the
>   compiler reports. Don't run the program; it is run for you afterwards, in a browser and natively.
> - **Write to `<dir>` only:** `Main.hx` (and more `.hx` if you like), then `NOTES.md` with:
>   - every compile error you hit, in order, and what you changed for it;
>   - each function or behavior you were unsure of, and what you guessed;
>   - anything you expect to work differently from raylib on the desktop.
> - Stop when it compiles cleanly and the notes are written, and reply with one line saying so.

## Results

Each game was built for the page and natively, and played by a script in Chromium and on a private display. For the win, level 3's
file was taken away.

| | Agent 1 | Agent 2 | Agent 3 |
|---|---|---|---|
| Compile errors in the first build | 6 | 2 | 13 |
| Builds to a clean compile | 2 | 2 | 2 |
| Levels by a built name, the next level, "You win!" | page and native | page and native | page and native |
| The best score after a reload or restart | yes | yes | yes |
| `Raymath` | not used | not used | imported unprompted |

- **The error messages were enough.** Each agent changed every synchronous load in one pass, from the signature the message gives.
  Agent 2 guessed `LoadFileTextAsync` before the compiler asked for it.
- All three showed a loading state while files arrived, guarded the texture and sound against null, set `SetExitKey(KEY_NULL)` and
  saved the best score with `SaveFileText`.

## What it found

- **`TextFormat` was missing.** Agent 3 called it 8 times and replaced it with string concatenation. It was added in 82b3a2f.
- **A refused call's result was `Dynamic`,** which caused a knock-on error for agent 1 ("You can't iterate on a Dynamic value").
  Since DECISIONS 21, a refused call keeps raylib's result type.
- **A log line repeated the path** (`LoadFileTextAsync: best.txt: best.txt: no source has it`). Fixed in 82b3a2f.

## How far it goes

- It was small: three agents and one 2D game of about 300 lines each.
- All three agents were Claude, so "agents know raylib" here means "Claude knows raylib".
- The loads were independent of each other. Chained loads, such as a model, then its textures, then a level naming them, would test
  harder.
- The agents never ran their games, so it didn't show how they would debug a load that fails while the game runs.
- The trial's author also wrote the play scripts that graded it.

The next trial suggested was a 3D game whose loads come one after another, and a model from another family if one is available.
