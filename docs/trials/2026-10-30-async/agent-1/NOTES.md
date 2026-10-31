# NOTES

## Compile errors, in order

First compile, written as a plain raylib program (sync loads in main, `FileExists` + `LoadFileText`):

1. `Main.hx:38 LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)`
   - Changed to `LoadTextureAsync` with a callback that stores the texture and decrements a `pending` counter.
2. `Main.hx:39 LoadSound: Synchronous loading is not supported. See LoadSoundAsync(...)`
   - Changed to `LoadSoundAsync`, same pattern.
3. `Main.hx:41 FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)`
   (best-score file)
   - Changed to `FileExistsAsync(BEST_FILE, exists -> ...)`, which then calls `LoadFileTextAsync` if it exists.
4. `Main.hx:99 FileExists: ...` (level file)
   - The level start became asynchronous: `startLevel` sets a "loading" state, asks `FileExistsAsync`, and on `false` shows
     "You win!"; on `true` calls `LoadFileTextAsync` and `beginLevel(n, text)` parses and starts the level.
5. `Main.hx:104 LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(...)`
   - Fixed by the restructuring in 4. (The `LoadFileText` of the best-score file at line 42 was not reported separately; the
     restructuring in 3 removed it anyway.)
6. `Main.hx:109 You can't iterate on a Dynamic value, please specify Iterator or Iterable`
   - A follow-on of error 5 (the refused `LoadFileText` had no usable type). Gone once the text came from the callback's
     `String`; I also typed `lines:Array<String>` explicitly.

Second compile: clean. Later small edits (exit key, gamepad, null guards) all compiled clean first time.

## Unsure of, and what I guessed

- **Async callbacks and the `while (!WindowShouldClose())` loop.** The compiler accepted the classic raylib loop, so I assumed
  helix-ray drives it (e.g. per animation frame in the browser) and that the async callbacks fire between frames. The game shows
  "Loading..." on the title until the texture, sound and best score are in, and a "Loading..." screen between levels.
- **`FileExistsAsync` for the level files.** I ask it before `LoadFileTextAsync` to decide "You win!" (no more levels). I guessed it
  answers `false` for a file not in the program's assets in the browser (a fetch 404). If `LoadFileTextAsync` fails anyway, its
  `failed` callback also shows "You win!".
- **Saving the best score.** I used `SaveFileText("best.txt", ...)` and read it back with `FileExistsAsync` + `LoadFileTextAsync`,
  guessing helix-ray keeps saved files across reloads in the browser (local storage or similar). Saved whenever the score passes
  the best (each coin), so a new best is there at once. I did not use `SaveStorageValue`/`LoadStorageValue`.
- **`failed` callbacks for the texture/sound.** Guessed they get an error string; on failure the game draws a blue square and plays
  no sound rather than crashing.
- **Escape.** `SetExitKey(KEY_NULL)` so Escape doesn't close the window, then `IsKeyPressed(KEY_ESCAPE)` returns to the title.
- **"Any key, click, tap or gamepad button".** `GetKeyPressed() != 0`, left/right `IsMouseButtonPressed`, `IsGestureDetected(GESTURE_TAP)`,
  and `GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN`. Guessed a tap also produces `GESTURE_TAP` without enabling gestures
  (raylib's default enabled-gesture set includes tap).
- **The "Time!" / "You win!" screens** last 3 seconds then return to the title (any input after the first second skips them), so
  the key held at the end of play doesn't skip it at once.
- **Gamepad:** gamepad 0 only, left stick with a 0.2 dead zone, combined with keys and clamped to length 1 so diagonals aren't faster.
- **Resizing:** layout uses `GetScreenWidth/Height` each frame; the player is clamped to the window and a coin outside a shrunk
  window is moved back in.
- **Collision:** player treated as a circle of radius min(width, height)/2 at the sprite's centre, `CheckCollisionCircles`.
- `Color` constructed with `new Color(r, g, b, a)`, `Vector2` with `new Vector2(x, y)`; `Texture2D.width/height` read as fields.

## Expected to differ from raylib on the desktop

- Loading is asynchronous: there is a brief "Loading..." on the title and between levels where desktop raylib would block.
- Everything that touches files is callback-shaped, so desktop raylib code (`LoadTexture`, `FileExists`, `LoadFileText`) won't port
  as-is; it was rewritten here.
- Where `best.txt` lives (browser storage vs a file next to the program) is up to helix-ray; desktop raylib would write it to the
  working directory.
- `SetTargetFPS(60)` in the browser probably follows the display's refresh rate; the movement uses `GetFrameTime()` so speed is the same.
