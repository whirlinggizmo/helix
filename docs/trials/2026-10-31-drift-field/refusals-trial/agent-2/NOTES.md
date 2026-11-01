# Drift Field: notes

## How I learned the API

From the compiler only: `$type(...)` on each raylib function I meant to use, which printed its Haxe signature as a warning, and
`$type(Type.new)` for the constructors of `Camera2D`, `Vector2`, `Rectangle` and `Color`. Two probe identifiers didn't exist:
`SetMainLoop` and `emscripten_set_main_loop`, so I wrote raylib's usual `while (!WindowShouldClose())` loop.
`SaveStorageValue`/`LoadStorageValue` don't exist either (they aren't in raylib 5.5), so the best score goes in a file.

## Compile errors, in order

1. Probe: `$type(new Camera2D)` was a parse error (`Expected (`). Changed to `$type(Camera2D.new)`.
2. First full build, four errors:
   - `LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(...)`: changed to `LoadTextureAsync`, keeping the
     texture when its callback arrives; until it does, the ship is drawn as a white square.
   - `LoadSound: ... See LoadSoundAsync(...)`: changed to `LoadSoundAsync`; nothing plays until it has loaded.
   - `FileExists: Synchronous file access is not supported. See FileExistsAsync(...)`: changed to `FileExistsAsync`.
   - `LoadFileText: ... See LoadFileTextAsync(...)`: the best score is read with `LoadFileTextAsync` inside the `FileExistsAsync`
     answer. Level files and dropped files were already read with `LoadFileTextAsync`.
3. After that it compiled cleanly.

## Unsure, and what I guessed

- **The main loop.** I wrote a blocking `while (!WindowShouldClose())`. It compiled, and the JS output shows the loop body handed to a
  runtime callback, so it seems to be meant that way. The code after the loop goes into a second callback, run on close.
- **SaveFileText on the web.** It compiled without an async variant, so I guessed it writes somewhere persistent (local storage)
  that `FileExistsAsync`/`LoadFileTextAsync` of the same name read back after a reload. The file is `driftfield_best.txt`, relative
  to the working directory natively. The best score is saved as soon as it is beaten (on each crystal gathered), not only at a level's
  end.
- **The random field.** `SetRandomSeed(seed)` then `GetRandomValue` for every rock (width, height, x, y) and every crystal
  (x, y, up to 200 tries until it's clear of every rock). I'm counting on helix-ray's generator matching across targets, so the
  same file makes the same field on the page and natively. A crystal that finds no clear place in 200 tries is left out.
- **Dropped files.** `IsFileDropped`/`LoadDroppedFiles`, then `LoadFileTextAsync` of `paths[0]`, then `UnloadDroppedFiles` straight
  away, before the load finishes. I guessed that a load already started still reads the dropped file after the list is unloaded.
  If it doesn't, every drop shows "Not a level". Only the first file of a drop is used.
- **Level parsing.** A line without `=` is ignored. Any of the seven keys missing, or with a value that isn't a plain number, means
  "Not a level". I also refuse widths or heights under 100 and non-positive `seconds`.
- **A level file that won't load** (the next numbered level missing) counts as the win, whatever the failure was.
- **Gestures.** A tap is taken from `IsGestureDetected(GESTURE_TAP)` with `GetTouchPosition(0)`, as well as from a left click. I
  wasn't sure whether a tap also shows up as a mouse press; if it does, both set the same target, so it doesn't matter. A click
  outside the field is ignored.
- **Gamepad "any button":** `GetGamepadButtonPressed() != 0` (raylib's 0 is `GAMEPAD_BUTTON_UNKNOWN`). The stick has a 0.2 dead zone,
  and stick plus keys are capped at length 1, so a diagonal is no faster.
- **Escape.** `SetExitKey(KEY_NULL)`, so Escape returns to the title from play instead of closing the window. On the title, any key
  starts the game, Escape included.
- **Zoom.** Each wheel notch multiplies the zoom by (1 + 0.1 × wheel), clamped to 0.5–2. Q turns the view one way and E the other
  (the camera's rotation in degrees).
- **Collision.** The ship is a 32 × 32 box (the sprite's size), moved one axis at a time and pushed back to the edge of whatever it
  hits, so it slides. A flight to a clicked point stops when the ship can't move at all. A crystal is gathered when it comes within
  8 + 16 px of the ship's center.
- **End of level.** If it's out of time or every crystal is gathered and the target is met, the next level loads; otherwise "Time!
  Score: N" shows for 3 s, then the title. A custom level always goes back to the title after a 3 s message, and its score starts
  from 0. Starting from the title resets the score to 0.
- **"Not a level: <name>"** shows for 3 seconds near the bottom of whatever screen is up, the title or play, and the game is left as
  it was.
- Crystals are drawn in pure cyan, `Color(0, 255, 255, 255)`, since raylib has no CYAN constant. The field inside is `Color(16, 24, 64)`.

## Expected differences from raylib on the desktop

- Textures, sounds and file reads arrive by callback rather than straight away: for a frame or so the ship may be a white square,
  and a level shows "Loading..." while its file is read.
- The best score's persistence on the web depends on where `SaveFileText` writes (see above).
- Code after the loop (unloading, `CloseWindow`) only runs if the runtime calls the close callback. On a page it probably never runs.
