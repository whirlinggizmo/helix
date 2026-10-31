# Notes: Coin Garden on helix-ray

## Compile errors, in order

First build (raylib-style code as I'd write it on the desktop) gave 13 errors in one pass:

1. `LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName, loaded:Texture2D->Void, ?failed)`
   -> loaded player.png with `LoadTextureAsync`, storing the texture in the callback.
2. `LoadSound: Synchronous loading is not supported. See LoadSoundAsync(...)` -> `LoadSoundAsync`, same pattern.
3. `LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(...)` (best score file) -> `LoadFileTextAsync`;
   the failed callback leaves best at 0. A counter of pending loads moves a new "loading" state to the title when all three answer.
4. `TextFormat: Not implemented` (8 places) -> Haxe string concatenation instead.
5. `FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName, answer:Bool->Void)` (does the next level
   exist?) -> `FileExistsAsync`; when false, "You win!"; when true, `LoadFileTextAsync` for the level (its failed callback also wins).
6. `LoadFileText` again for the level file -> as above, inside the FileExistsAsync answer.

Second build: clean. Later edits (SetExitKey, null guards, input tweaks) also compiled clean first time.

## Unsure of, and what I guessed

- Whether `while (!WindowShouldClose()) { ... }` in `main` works on the web. It compiled, so I assumed helix-ray handles the
  blocking loop (raylib web normally needs `emscripten_set_main_loop`).
- Whether `SetConfigFlags(FLAG_WINDOW_RESIZABLE)` before `InitWindow` makes the canvas follow the browser window. Layout reads
  `GetScreenWidth/Height` each frame, so it follows whatever size is reported.
- Saving the best score: used `SaveFileText("best.txt", ...)` and `LoadFileTextAsync("best.txt", ...)`, guessing helix-ray keeps
  saves across reloads in the browser (localStorage or similar) and as a file natively. Did not try SaveStorageValue/LoadStorageValue.
- Whether the async callbacks can fire during the same frame/call (synchronously). The code tolerates either: it sets the loading
  state before calling and the callbacks set the next state.
- Whether a failed texture/sound load calls `failed` or gives an invalid object; I guard `player`/`coinSound` against null only.
- "Any key, click, tap or gamepad button": `GetKeyPressed() != 0`, left/right `IsMouseButtonPressed`, `GetGestureDetected() ==
  GESTURE_TAP`, `GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN`. Guessed a tap also reaches the mouse functions, as in raylib.
- `SetExitKey(KEY_NULL)` so Escape returns to the title instead of closing the window (raylib's default exit key is Escape).
- Player collision: a circle of radius max(width, height)/2 around the sprite centre against the coin circle (radius 12).
- Gamepad stick: 0.2 dead zone, vector clamped to length 1 so diagonals are no faster; frame-rate independence via `GetFrameTime()`.
- Coins are placed at least 80 px from the player and below the 40 px HUD band, and clamped back inside the window after a resize.
- The best score is saved on every coin that beats it, and again at the level's end.

## Expected to differ from desktop raylib

- No synchronous loads: the program shows "Loading..." for the first frames and briefly between levels while level files load.
- `TextFormat` is unavailable, so formatting is plain Haxe strings.
- Audio in the browser probably won't play until the first user gesture (the title's key/click covers that).
- Where `best.txt` lives (browser storage vs. a file beside the program) is up to helix-ray.
