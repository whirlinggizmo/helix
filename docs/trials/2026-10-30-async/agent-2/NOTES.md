# Notes: Coin Garden on helix-ray

## Compile errors, in order

1. `Main.hx:44: LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)`
2. `Main.hx:45: LoadSound: Synchronous loading is not supported. See LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void)`

   For both: I called `LoadTextureAsync` / `LoadSoundAsync` and stored the result in the callback. `player` and `coinSound` can be
   null until they arrive, so drawing the sprite and playing the sound check for null first, and the player's size falls back to
   32x32 (the PNG's size) until the texture is in.

After that it compiled cleanly. Nothing else was reported. I had already guessed `LoadFileTextAsync` existed before writing
(by analogy with the async loaders), and it compiled with the signature I guessed: `(fileName, loaded:String->Void, ?failed)`.

## Things I was unsure of, and what I guessed

- **The main loop.** I wrote raylib's `while (!WindowShouldClose()) { ... }` loop in `main`, with `CloseWindow()` after it. It
  compiled, so I assume helix-ray turns it into a per-frame callback in the browser. If it doesn't, the browser would hang.
- **Level files that don't exist.** I used `LoadFileTextAsync`'s `failed` callback as "this level doesn't exist, the player has won".
  I assumed `failed` is called for a missing file (a 404 in the browser) rather than `loaded` getting an empty string or null.
  If a missing file instead gave empty text, the game would start a level with the default values (5 coins, 20 s, target 8),
  not show "You win!". I didn't use `FileExists` (I expected it to be refused like the sync loads).
- **Saving the best score.** I used `SaveFileText("best.txt", ...)` to save and `LoadFileTextAsync("best.txt", ...)` at start to read
  it back. I assumed helix-ray keeps files the program writes (in browser storage on the web) and that the async load finds them.
  The best score is saved the moment the score passes it (on each coin), and again at a level's end / Escape. If the saved file
  isn't readable this way, "Best:" would show 0 after a reload. While the best-score load is pending the title shows "Best: 0".
- **Escape.** raylib closes the window on Escape by default, so I called `SetExitKey(KEY_NULL)`. I assumed `KEY_NULL` exists (it
  compiled).
- **"Any key, click, tap or gamepad button".** `GetKeyPressed() != 0`, `IsMouseButtonPressed` (left or right),
  `IsGestureDetected(GESTURE_TAP)` with `GetTouchPointCount() > 0`, and `GetGamepadButtonPressed() != GAMEPAD_BUTTON_UNKNOWN`.
  I assumed a tap on the web also produces a left mouse press, as it does in raylib's web backend.
- **Gamepad stick.** `GetGamepadAxisMovement(g, GAMEPAD_AXIS_LEFT_X/Y)` over gamepads 0..3 that are available, with a 0.2 dead zone I
  added. The movement vector is clamped to length 1, so a diagonal is no faster than 240 px/s.
- **Speed.** `GetFrameTime()` scales movement and the level timer, so speed doesn't depend on the frame rate.
- **Resizing.** `SetConfigFlags(FLAG_WINDOW_RESIZABLE)` before `InitWindow`; all layout uses `GetScreenWidth()/GetScreenHeight()`
  every frame (title centered, time at top right, player and coins clamped back inside the window). I assumed those report the
  resized size on the web (canvas size) too.
- **Struct construction.** `new Color(r, g, b, 255)`, `new Vector2(x, y)`, `new helix.ray.Rectangle(x, y, w, h)`; they compiled. I
  assumed `Vector2` is a mutable reference type (I change `c.x` in place for coins in the array).
- **After "Time!" / "You win!"** I show the message for 2.5 seconds, then the title. The spec only says "then the title again"; the
  wait is my choice so the message can be read.
- **While a level file loads** a "Loading level N..." screen is shown for a frame or so.

## What I expect to differ from raylib on the desktop

- Texture and sound load asynchronously, so for the first frames the sprite may not be drawn and a coin collected before the sound
  arrives makes no sound. With desktop raylib both would be there before the first frame.
- Level files and the best score are read asynchronously, so the title can show "Best: 0" briefly before the saved value arrives.
- The best score lives where helix-ray keeps saved files (browser storage on the web); on desktop raylib it would be a `best.txt`
  next to the program.
- `GetGamepadButtonPressed()` in raylib returns the last button pressed, which may still be reported for a while after the press; if
  so, a held gamepad button could restart the game as soon as the title reappears.
