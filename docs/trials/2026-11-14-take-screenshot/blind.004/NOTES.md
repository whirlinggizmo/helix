# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` -> used `LoadTextureAsync` with a callback storing the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` (x2, 64 and 24 px) -> used `LoadFontExAsync` with callbacks; the main loop draws only a blank frame until all three assets have loaded.

## Warnings logged
1. `TakeScreenshot: Screenshots are generated during EndDrawing()` (shot.png not saved) -> moved `TakeScreenshot` to before `EndDrawing()` on the last frame.

## Guesses
- Blink phase: "once a second" taken as 30 frames on / 30 off. Made it hidden for the first half of each second and visible for the second, so frame 120 shows the prompt.
- Letter spacing 2 (title) and 1 (prompt) in MeasureTextEx/DrawTextEx; not specified.
- Prompt placed 30 px below the title's bottom (y = 214).
- `SetExitKey(0)` so Escape doesn't close; passing 0 for KEY_NULL was a guess.
- Frames count only after assets finish loading.
