# Notes

## Compile errors, in order
1. `Main.hx:460 FilePathList has no field length` / `Array access is not allowed on FilePathList`: I had guessed it was an array. Probing showed it has `count` and `paths` (Array<String>). Changed to `files.count` and `files.paths[0]`.
2. `LoadTexture`, `LoadSound`, `LoadFileText`: "Synchronous loading is not supported. See ...Async". Switched to `LoadTextureAsync`, `LoadSoundAsync`, `LoadFileTextAsync` with callbacks, and added a Boot mode ("Loading...") until the three loads finish.
(Earlier I probed signatures by assigning functions to `var x:Int` to read the types in the error messages; those errors were deliberate.)

## Unsure, and what I guessed
- Whether `SaveFileText("best.txt", ...)` works and persists on the page (it compiled without a sync-refusal). Guessed it persists (reload) and that `LoadFileTextAsync("best.txt")` reads it back; its failure is treated as best = 0.
- Whether a missing level file calls the `failed` callback of `LoadFileTextAsync`. Guessed yes; that means "you win".
- Whether the `failed` callback of LoadTextureAsync is also fine to leave the game in Boot (it traces and stays on "Loading...").
- `LoadDroppedFiles` / `UnloadDroppedFiles(files)`: I unload the list right after taking the first path, then load that path async. Guessed the bytes stay readable.
- `GetFileName` on a dropped path returns the base name.
- `SetExitKey(KEY_NULL)` so Escape does not close the window.
- Touch: only mouse events are used (guessed a tap becomes a left mouse press). No touch API calls.
- Gamepad: `IsGamepadAvailable(0)`, buttons 1..17 for starting, left stick axes with a 0.25 dead zone.
- `GetKeyPressed()` is drained each frame to detect "any key" and, in play, to not leak keys into the title.
- Camera2D rotation sign: assumed positive `rotation` turns the view clockwise; E adds, Q subtracts.
- `GetScreenToWorld2D` used for clicks; `BeginScissorMode` takes screen pixels (clips the map).
- Field is generated with my own xorshift32 generator seeded from the file (not `GetRandomValue`), so it matches across targets.
- Level file with width/height < 1 or non-numeric/missing keys is "Not a level"; rocks/crystals clamped to 5000.
- A level with zero crystals ends only on time.

## Expected to differ from raylib on the desktop
- All file loading is asynchronous (callbacks); synchronous Load* calls are refused.
- Mouse/touch/drop handling follows the browser; the drop's path is a virtual one.
- HiDPI: I use GetScreenWidth/Height for layout and scissor; on a scaled display the scissor may be off versus raylib desktop.
