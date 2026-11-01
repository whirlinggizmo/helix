# Drift Field: notes

## How I learned the API

Only from the compiler: small probe programs of `$type(...)` lines, compiled with `build-web.hxml`. One early probe went
in a sibling directory (`../probe1`) by mistake. I deleted it right away and did every later probe in this directory, in `Main.hx`.

What the probes showed:
- Absent: `SetMainLoop`, `emscripten_set_main_loop`, `SaveStorageValue`, `LoadStorageValue` (the last two match raylib 5.5, which dropped them).
- Present and not in raylib: `LoadFileTextAsync`, `LoadTextureAsync` and `LoadSoundAsync`, each `(fileName, loaded, ?failed)`.
- `LoadFileText` returns `Null<String>` and `LoadFileData` returns `Null<haxe.io.Bytes>`.
- `FilePathList` has `count:Int` and `paths:Array<String>`.
- Constructors: `Camera2D(offset, target, rotation, zoom)`, `Vector2(x, y)`, `Rectangle(x, y, w, h)` and `Color(r, g, b, a)`.

## Compile errors, in order

1. In a probe, `$type(new helix.ray.Camera2D)` gave `Expected (`. I changed it to `$type(helix.ray.Camera2D.new)` to read the constructor's type.
2. In the game, `Main.hx:72: Cannot call constructor like this, use 'new helix.ray.Color()' instead`. I had written `Color.new(...)` in
   expressions. I replaced every `X.new(` with `new X(` and after that it compiled with no errors or warnings.

## Things I was unsure of, and what I guessed

- **Main loop.** I used raylib's desktop loop, `while (!WindowShouldClose()) { ... }`. I found no `SetMainLoop` or
  `emscripten_set_main_loop`, and the compiler accepted the while loop for JS, so I assumed helix-ray makes it work in the browser.
  If it doesn't, the page will hang on the web.
- **Loading files.** All loads use the `*Async` versions: levels, dropped files, `best.txt`, the texture and the sound. I couldn't tell
  whether the plain `LoadFileText` and `LoadTexture` work in the browser before the file has been fetched. Until the texture arrives,
  the ship is drawn as a white circle. Until the sound arrives, gathering a crystal makes no sound.
- **The "failed" callback.** I assumed a missing level file calls `failed`, and treated that as the player having won. A file that
  loads but doesn't parse is treated as a win too.
- **Best score.** I save it with `SaveFileText("best.txt", ...)` the moment it is beaten, and read it at start with
  `LoadFileTextAsync`, where a failure means 0. I assumed that on the web this file persists across reloads (for example in browser
  storage). If it doesn't, the best score won't survive a reload on the page.
- **Dropped files.** `LoadDroppedFiles` gives the path, I start `LoadFileTextAsync(path)`, then call `UnloadDroppedFiles` straight away.
  I assumed the dropped file's bytes stay readable after the unload, as a file on disk would.
- **The random field.** `SetRandomSeed(seed)` then `GetRandomValue` builds the rocks first and then the crystals. I assumed
  raylib's generator gives the same numbers on every target. Each crystal gets up to 200 tries to land clear of the rocks; if none
  works, it is dropped.
- **"Any key, click, tap or gamepad button."** The game starts on any of: `GetKeyPressed() != 0`, a left or right mouse press,
  `IsGestureDetected(GESTURE_TAP)`, or `IsGamepadButtonPressed` for buttons 1 to 17 on pads 0 to 3. I used a loop rather than
  `GetGamepadButtonPressed()` because in raylib that returns the last button pressed, not just this frame's.
- **Escape.** `SetExitKey(KEY_NULL)`, so Escape takes play back to the title instead of closing the window.
- **Message screens.** "You win", "Time!" and the end of a custom level ("Level done! Score: N") show for 3 seconds and then go to
  the title. Any input skips them after the first second.
- **"Not a level: <name>".** This shows at the bottom of whatever screen is up (the title, or play, which carries on) for 3 seconds.
  The name is `GetFileName(path)`.
- **Score with a custom level.** Dropped on the title, a custom level starts from score 0. Dropped during play, it keeps the running
  score. A custom level that ends always goes back to the title.
- **Click to move.** A left press counts only on a point inside the field, and only when no key or stick is moving the ship. Its
  world point comes from `GetScreenToWorld2D(mouse, camera)`, so zoom and turn are taken into account. If the ship is blocked
  (moving less than 5% of a step) for half a second, the target is dropped, so it can't push against a rock forever. I assumed a tap
  shows up as a left mouse press, as raylib does on the web.
- **Collision.** The ship is a 28x28 box for rocks and edges. It moves one axis at a time, and a blocked axis is bisected up to the
  contact, which makes it slide. Crystals use a circle of radius 14 against radius 8.
- **Zoom and turn.** One wheel notch multiplies zoom by 1.1, clamped to 0.5 to 2. Q turns one way and E the other.
  `Camera2D.rotation` is in degrees, as in raylib.
- **The ship sprite.** Drawn 32x32, centered, and rotated so its top points where it is moving. I assumed the art faces up.
- **The map.** The field is fitted into 200x120 with its aspect kept, and clipped by `BeginScissorMode`, so nothing spills out.
  `BeginScissorMode` takes screen pixels, as in raylib, and I assumed that holds after a resize and on high-DPI screens.
- **Frame time.** Clamped to 0.1 s so a stall can't make the ship jump through a rock.

## What I expect to differ from raylib on the desktop

- raylib has no `*Async` loaders. On the desktop the game would use `LoadFileText`, `LoadTexture` and `LoadSound`.
- On the desktop, `best.txt` would be a file in the working directory. On the web it goes wherever helix-ray puts saved files.
- On the web, audio may stay silent until the first user gesture. The press that starts the game counts as one.
