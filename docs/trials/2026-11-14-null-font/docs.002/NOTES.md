# Notes

## Compile errors (in order)
1. `Main.hx:45: TakeScreenshot: Not supported. Use TakeScreenshotAsync(...)` — switched to `TakeScreenshotAsync("shot.png", () -> done = true)`, called once on the last frame, and the loop ends in its callback so the file is written before closing.

## Warnings logged
None (only INFO lines).

## Guesses
- No sync `LoadTexture`/`LoadFont` in the docs: used `LoadTextureAsync` and `LoadFontExAsync` (two fonts, 64 and 24 px, so each draws unscaled); nothing draws until loaded.
- Letter spacing of 2 px for both fonts (the task gave none).
- Prompt placed 20 px under the title's measured height; blink is on for the first half of each second of `GetTime()`.
- Background colour (18,18,24); panel stretched to 420x260 with `DrawTexturePro`.
- `--frames=N` parsed from `Sys.args()`.
