# Notes: Drift Field on helix-ray

## Compile errors, in order

Before writing the game I compiled two probe files with `$type(...)` to learn signatures.

1. `$type(LoadTexture)`, `$type(LoadSound)`, `$type(LoadFileText)`, `$type(FileExists)`:
   "Macro functions must be called immediately". Changed the probe to call them.
2. `SaveStorageValue`: "Unknown identifier" (raylib 5.5 has no SaveStorageValue either). `LoadStorageValue`: same.
   I store the best score with `SaveFileText` in `driftfield_best.txt` and read it back with `LoadFileTextAsync`.
3. `LoadTexture(...)`: "Synchronous loading is not supported. See LoadTextureAsync(fileName, loaded, ?failed)".
   Same for `LoadSound` (-> `LoadSoundAsync`), `LoadFileText` (-> `LoadFileTextAsync`) and `FileExists`
   (-> `FileExistsAsync`). I switched every load to the Async form.

The game itself (Main.hx) compiled cleanly on the first try after that.

## Things I was unsure of, and what I guessed

- **Constructors.** I guessed `new Color(r,g,b,a)`, `new Vector2(x,y)`, `new Rectangle(x,y,w,h)` and
  `new Camera2D(offset, target, rotation, zoom)` in raylib's field order. They compiled; the Camera2D argument order
  is my guess from the C struct.
- **Main loop.** I wrote raylib's `while (!WindowShouldClose())` loop. It compiles, and the generated JS wraps main in
  a runtime boot, so I assume helix-ray turns the loop into per-frame calls on the web.
- **Async callbacks.** I don't know whether a native Async load calls back at once or a frame later, so the game copes
  with either: a token drops answers to stale level requests, and the ship uses a 32x32 box until the texture arrives.
- **A missing level file** I take to be the `failed` callback of `LoadFileTextAsync` (shows "You win!").
  A level file that exists but doesn't parse also counts as a win.
- **Best score persistence.** `SaveFileText` to a relative path. On the web I don't know where that goes, or whether it
  survives a reload (localStorage?). Natively it's a file in the working directory.
- **Dropped files.** `LoadDroppedFiles().paths` and `GetFileName`; I read the dropped path with `LoadFileTextAsync`,
  assuming that works on the web for a dropped file's path.
- **Touch/tap.** I take a tap as `GetTouchPointCount()` going from 0 to more, at `GetTouchPosition(0)`, as well as a
  left mouse press. If the web maps a tap to a mouse press too, both give the same point in the same frame, which is harmless.
- **Any key** is `GetKeyPressed() != 0` (Escape left out); a gamepad button is `GetGamepadButtonPressed() != 0`.
- **Escape.** `SetExitKey(KEY_NULL)` so Escape goes back to the title instead of closing the window.
- **Random field.** `SetRandomSeed(seed)` then `GetRandomValue` for each rock's size and place, then crystals (up to 200
  tries each, kept 2 px clear of rocks). I assume `GetRandomValue` gives the same values on the web and natively.
- **Level file validation.** A value has to look like a number (`-?digits(.digits)?`); a missing key or bad value
  makes it "Not a level: <name>".
- **Zoom** steps by x1.1 per wheel notch, kept between 0.5 and 2. Rotation follows raylib's Camera2D, in degrees.
- **End messages** ("You win!", "Time!") show for 3 seconds, then the title comes back. A custom level that reaches its
  target shows "Level done! Score: N" (the spec doesn't give a wording for that).
- **Map** keeps the field's shape, scaled to fit 200x120 and centered, and is clipped with `BeginScissorMode`.

## What I expect to differ from raylib on the desktop

- Loads are asynchronous, so the first frames may draw the ship as an orange box before the sprite arrives.
- The best-score file's location on the web is unknown to me (see above).
- `BeginScissorMode` uses screen pixels; on a high-DPI display it may clip differently if helix-ray doesn't scale it.
