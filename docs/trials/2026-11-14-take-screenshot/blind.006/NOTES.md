# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` — switched to `LoadTextureAsync(path, cb)`.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` (twice, 64 and 24 px) — switched to `LoadFontExAsync(path, size, null, 0, cb)`.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()` — I had called it after `EndDrawing()`. Moved it to just before `EndDrawing()` on the last frame.

## Guesses
- Async loaders were not in the docs. I guessed callbacks fire on a later frame, so the loop null-checks the assets, draws only once all are loaded, and counts `--frames` as done only once they are ready.
- Passed `null, 0` for the codepoints in `LoadFontExAsync` to mean the default character set. It loaded 95 glyphs.
- "Blinking once a second" read as 0.5 s on and 0.5 s off, driven by `GetTime()`.
- Prompt placed 30 px below the title's bottom edge (title y 120 + 64 + 30).
- Panel is centered at (190, 95), 420x260.
