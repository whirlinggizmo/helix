# Notes

## Compile errors, in order
1. `Main.hx:33 Type not found : Texture2D` (only `import helix.ray.Raylib` and `Raylib.*`). I tried `Texture`, same error, then added `import helix.ray.*;`, which made the types resolve (Texture2D, Sound, Camera2D, Vector2, Color, ...).
2. `LoadFileText`, `LoadTexture`, `LoadSound`: "Synchronous loading is not supported. See LoadFileTextAsync / LoadTextureAsync / LoadSoundAsync(fileName, loaded, ?failed)". I switched every load to the Async form with callbacks; a `ready` counter gates the title start on texture+sound, a `loading` flag pauses play updates while a level file loads; a failed level load means "no more levels" (win).
After that it compiled cleanly.

## Unsure, and what I guessed
- `SaveFileText("best.txt", ...)` compiled; I guessed it persists on the page (localStorage-like) and natively as a file, and that `LoadFileTextAsync("best.txt")` reads it back. Unverified.
- Dropped files: guessed `IsFileDropped()`, `LoadDroppedFiles()` (`.count`, `.paths[0]`), `UnloadDroppedFiles`, then `LoadFileTextAsync(path, ...)` to read the dropped file. Compiled, behavior on the page unknown.
- Touch/tap: I rely on touch being emulated as a left mouse click (`IsMouseButtonPressed`); no explicit touch/gesture code.
- `GetMouseWheelMove` zoom step 0.1 per notch (spec gives no step).
- `Camera2D` built with `new Camera2D(offset, target, rotation, zoom)`; Q/E add/subtract degrees to rotation; positive rotation sense assumed raylib's.
- `BeginScissorMode` for the map clip; assumed it takes screen pixels.
- `SetExitKey(KEY_NULL)` so Escape goes to my handler instead of closing the window.
- Random field: own 31-bit LCG (not raylib's random), so the same file gives the same field on both targets.
- Ship collision box is the texture's size; crystal pickup is circle-vs-box.
- A click-target that is completely blocked by a rock is dropped.
- Pressing a key on the title while assets are still loading is ignored.

## Expected differences from desktop raylib
- All file loads are asynchronous (callbacks), so a level starts a frame or more after the request.
- The saved best score's storage on the page is not a real file; desktop writes `best.txt` in the working directory.
- Dropped-file paths on the page are probably not real paths.
- Tap-to-start/move depends on touch-to-mouse emulation.
