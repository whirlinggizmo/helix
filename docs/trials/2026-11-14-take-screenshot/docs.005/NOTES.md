# Notes

## Compile errors
None. It built on the first try.

## Warnings logged
None. Only INFO lines were logged.

## Guesses
- Textures and fonts load only through the `*Async` calls, so I draw each one only once its callback has run (null check plus `IsTextureValid`/`IsFontValid`).
- Fonts are loaded with `LoadFontExAsync` at 64 and 24, one font for each size.
- Letter spacing is 2 (the task gave none).
- The prompt's y is 120 + 64 + 30, a guess at "under the title".
- Blink: visible for the first half of each second of `GetTime()`.
- The title and prompt are centered with `MeasureTextEx` width.
- `--frames=N` calls `TakeScreenshot` on frame N, before that frame's `EndDrawing`, then exits.
- The screenshot showed the prompt in the "on" phase, so the blink is visible in the shot.
