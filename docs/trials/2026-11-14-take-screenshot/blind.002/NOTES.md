# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` — switched to `LoadTextureAsync` with a callback that stores the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` (64px) — switched to `LoadFontExAsync(path, size, null, 0, cb, err)`.
3. Same for the 24px font — same change.

The draw loop shows only the background until all three assets have loaded.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshot could not be saved: EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.` — moved `TakeScreenshot` to just before `EndDrawing()` on the last frame. No warnings after that.

## Guesses
- Passed `null` and `0` for the codepoints/count of `LoadFontExAsync` to get the default glyph set (worked: 95 glyphs).
- "Blinking once a second" is read as visible for 0.5 s, hidden for 0.5 s, driven by `GetTime()`.
- Prompt is placed 20 px below the title's 64 px line (y = 204). Title is at y = 120 (top of text).
- Background colour (18,18,26) is a guess for "dark".
- `SetExitKey(0)` so Escape doesn't close the window (task only says Enter).
- The last frame's screenshot may or may not catch the prompt mid-blink; in my run it was visible.
