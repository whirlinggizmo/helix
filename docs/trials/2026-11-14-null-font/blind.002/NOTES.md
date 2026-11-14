# Notes

## Compile errors (in order)
1. `LoadTexture`, `LoadFontEx` (x2), `TakeScreenshot`: "Not supported. Use ...Async instead."
   Changed to `LoadTextureAsync`, `LoadFontExAsync` (codepoints null, count 0) and `TakeScreenshotAsync`,
   with the results held in variables; the loop draws only the background until all assets have loaded.
   The window closes when the screenshot's `done` callback fires.

## Warnings logged
None (only INFO lines).

## Guesses
- Passing `null` for the codepoints array in `LoadFontExAsync` gives the default glyph set (it did: 95 glyphs).
- Whether the async callbacks run without being pumped by me: they did, via the normal frame loop.
- Text spacing 2 for `MeasureTextEx`/`DrawTextEx` (not specified).
- Blink: visible 30 frames, hidden 30 frames. Prompt placed at y=204 (title y + 64 + 20); the task gave no figure.
- Frame counter starts once assets are loaded, so `--frames=N` counts drawn title frames.
