# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` -> switched to LoadTextureAsync with a callback storing the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` -> switched to LoadFontExAsync; the loop skips drawing until both assets have arrived.

## Warnings logged
1. `TakeScreenshot: ... EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.` -> moved TakeScreenshot to just before EndDrawing on the last frame.

## Guesses
- Command line args via `Sys.args()`.
- Async callbacks fire while the main loop runs (worked; no explicit pumping).
- Font spacing 2 for both texts; blink = visible for the first half of each second (GetTime).
- Prompt placed at y = 120 + title height + 20.
- Panel drawn with DrawTexturePro scaled to 420x260; background color (20,20,28).
- `--frames` counts frames including those spent waiting on assets.
