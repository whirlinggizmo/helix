# Notes

## Compile errors (in order)
1. `LoadTexture`, `LoadFontEx` ×2: "Not supported. Use ...Async". Switched to `LoadTextureAsync` / `LoadFontExAsync` with callbacks; the loop skips drawing until all three are loaded.

## Warnings logged
1. `TakeScreenshot: ... Screenshots are generated during EndDrawing()` — moved the call to just before `EndDrawing()` on the last frame.

## Guesses
- Passing `null, 0` for codepoints in `LoadFontExAsync` means the default charset (worked: 95 glyphs).
- Blink: 30 frames off / 30 on, phase chosen so the prompt is visible on frame 120 for the screenshot.
- Letter spacing 2 (title) / 1 (prompt); prompt placed 30px under the title's bottom (y=214).
- Colors (dark background, RAYWHITE title, GOLD prompt) chosen by me.
