# Drift Field: notes

## Compile errors, in order

1. Probe program (`InitWindow`, `LoadTexture`, `LoadFileText`, a `while (!WindowShouldClose())` loop):
   - `LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName, loaded, ?failed)`
   - `LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName, loaded, ?failed)`
   Changed: the texture, the sound, the level files, dropped files and the saved best score all load through the `...Async`
   functions with callbacks. The `while (!WindowShouldClose())` loop was accepted as written.
2. A second probe with `$type(...)` to read signatures:
   - `$type(LoadFileText)` / `$type(FileExists)`: `Macro functions must be called immediately`. Called them instead and got
     `FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName, answer)`. I don't call `FileExists`;
     a missing level is detected by `LoadFileTextAsync`'s `failed` callback.
   - `Unknown identifier : SaveStorageValue` (removed in raylib 5.x anyway). Changed: the best score goes in a file with
     `SaveFileText("driftfield_best.txt", ...)` and is read back at start with `LoadFileTextAsync`.
   - `Unknown identifier : Camera2D` under `import helix.ray.Raylib.*` alone. Changed: added `import helix.ray.*;` for the types.
   - `Unknown identifier : SetMainLoop` (only probing; not needed since the plain loop compiles).
3. The game compiled cleanly on its first full build.

## Unsure of, and what I guessed

- **Asset loading timing.** I guessed the async loads complete while the loop runs, so the ship is drawn as a white square until
  the texture arrives, and the coin sound is skipped until it has loaded.
- **Saving the best score.** I guessed `SaveFileText` works on the page (some persistent storage) and that a later
  `LoadFileTextAsync` of the same name reads it back there rather than fetching it from the server. Natively it is a file in the
  working directory. A missing file calls `failed`, and best stays 0.
- **Dropped files.** I guessed `LoadDroppedFiles().paths[0]` can be passed to `LoadFileTextAsync` on the page as well as natively,
  and that the failed callback runs when it can't be read. Only the first dropped file is used.
- **Missing level = win.** Detected by `LoadFileTextAsync`'s `failed` callback (I assumed a 404 on the page arrives there).
- **Determinism.** The field comes from `SetRandomSeed(seed)` and then `GetRandomValue` in a fixed order (each rock: width, height,
  x, y; then each crystal x, y with up to 200 retries to keep clear of rocks). I assumed `GetRandomValue` gives the same sequence
  on the page and natively. Crystals that can't find a clear spot in 200 tries are left out.
- **Escape.** raylib closes the window on Escape by default, so I call `SetExitKey(KEY_NULL)` and handle Escape myself.
- **Tap.** I assumed a tap shows up as `IsMouseButtonPressed(MOUSE_BUTTON_LEFT)` (raylib maps a touch to the mouse), and also
  start on `GESTURE_TAP` on the title.
- **Gamepad buttons.** Checked buttons 1..17 with `IsGamepadButtonPressed` on gamepads 0..3, and the left stick with a 0.2 dead zone.
- **Zoom.** Each wheel step multiplies zoom by 1.1, clamped to 0.5..2. `Camera2D.rotation` is in degrees, as in raylib; Q turns
  anticlockwise, E clockwise.
- **Movement directions** are in world axes, not relative to the turned view.
- **Fly-to.** A click inside the field (and not on the map) sets the target. It is dropped when the ship reaches it, when a key or
  the stick moves the ship, or when a rock stops it moving forward (otherwise it would stay stuck pushing against the rock).
- **Ship collision** is a 24 x 24 box centred on the ship (the sprite is 32 x 32). Moves go one axis at a time, so the ship slides
  along rocks and the field's edge.
- **End screens.** "You win! Score: N" and "Time! Score: N" stay up for 3 seconds (or until a key/click after half a second), then
  the title comes back. A level file that exists but doesn't parse shows a message and goes back to the title.
- **Custom level score.** Dropped on the title, it starts the score at 0; dropped in play, the score carries on. When it ends the
  title comes back whatever the count. "Not a level: name" shows near the bottom of the window for 3 seconds, on the title or in play.
- **Map.** The whole field scaled to fit 200 x 120 at the bottom right, clipped with `BeginScissorMode`, framed with a white outline;
  rocks, crystals and the ship (a yellow dot) are on it.

## Expected to differ from raylib on the desktop

- Loading is asynchronous, so the first frame or two may show the white placeholder square instead of the sprite, and
  the title's "Best" may show 0 briefly before the saved value arrives.
- Moving between levels goes through a short "Loading..." state while the next file is read.
- On the page the best score lives wherever helix-ray's `SaveFileText` stores it, not in a file next to the program.
