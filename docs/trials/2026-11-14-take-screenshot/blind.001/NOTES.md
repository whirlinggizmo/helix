# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` — switched to `LoadTextureAsync` with a callback storing the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` — switched to `LoadFontExAsync` with a callback; the draw loop skips drawing until both have loaded.

## Warnings logged
1. `TakeScreenshot: ... EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.` — moved the call to before `EndDrawing()` on the last frame (C raylib allows it after).

## Guesses
- Blink: visible for half of each second (`Std.int(GetTime()*2) % 2 == 0`).
- Prompt placed at y = 120 + title measured height + 20 (spec said only "under the title").
- Panel centered at (190, 95), 420x260.
- Passed `null, 0` as codepoints to `LoadFontExAsync` (default glyph set); it worked.
- Frame count excludes frames spent waiting for assets to load.
