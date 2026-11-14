# Notes

## Compile errors
None. It built on the first try.

## Warnings logged
None. The run logged only INFO lines.

## Guesses
- Textures and fonts load only through the `...Async` calls, so I draw each asset once its callback has run. The 24 px prompt is a second `LoadFontExAsync` of the same file.
- Letter spacing is 2 for `MeasureTextEx` and `DrawTextEx`. The task gave no value.
- "Blinking once a second" is a 60-frame cycle: visible for frames 0-14, hidden for 15-44, visible for 45-59. The last frame of a 120-frame run (index 119) falls in the visible part, so the shot shows the prompt.
- Background colour (20,20,28) and prompt colour LIGHTGRAY are my choice.
- The prompt sits 30 px under the title's 64 px line box (y = 214).
- The screenshot is requested after the frame before the last, so the last `EndDrawing` writes it.
