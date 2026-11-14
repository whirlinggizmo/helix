# Notes

## Compile errors
None. It built on the first try.

## Warnings logged
None. The log had only INFO lines.

## Guesses
- `LoadTexture`/`LoadFontEx` are replaced by `LoadTextureAsync`/`LoadFontExAsync` (per the docs), so I load in callbacks and draw only once the assets are valid (`IsTextureValid`/`IsFontValid`).
- Loaded two fonts, at 64 and 24 px, rather than scaling one.
- Title and prompt spacing: 2 px (the task gave none).
- Title "120 pixels from the top" is taken as the text's top y; the prompt sits 20 px under the title's measured height.
- Blink: visible for the first half of each second, via `GetTime() % 1.0 < 0.5`.
- `--frames=N` read from `Sys.args()`; screenshot is taken on frame N, before `EndDrawing`.
- Background color (20,22,30) is my choice for "dark".
