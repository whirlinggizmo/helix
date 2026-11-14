# Notes

## Compile errors (in order)
1. `Main.hx:52: TakeScreenshot: Not supported. Use TakeScreenshotAsync(...)` — switched to `TakeScreenshotAsync("shot.png", done, failed)` and kept drawing the scene until it reports done.

## Warnings logged
None (only INFO lines).

## Guesses
- `LoadTexture`/`LoadFont` aren't used; the docs list only async loaders, so I used `LoadTextureAsync` and `LoadFontExAsync` and draw only once each is valid.
- Loaded the font twice (64 and 24 px) rather than scaling one, so each size is rasterized natively. `codepoints` null, count 0 (printable ASCII).
- First screenshot attempt was all black: my wait loop drew empty frames, and the screenshot reads the frame being ended. Fixed by redrawing the full scene while waiting.
- Letter spacing 2 px for both sizes (not specified).
- "Blinking once a second": prompt on for 30 frames, off for 30. Forced on for the screenshot frame so `shot.png` shows it.
- Prompt placed 20 px under the title's measured bottom (120 + measured height); title colored white, prompt light gray; background (18,18,24).
- Panel drawn with `DrawTexturePro` scaled to 420x260 at (190, 95).
