# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` → switched to `LoadTextureAsync` with a callback that stores the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync(...)` (two uses) → switched to `LoadFontExAsync` with callbacks, `null` codepoints and count 0.
3. `TakeScreenshot: Not supported. Use TakeScreenshotAsync(...)` → switched to `TakeScreenshotAsync`.

## Warnings logged
None. Only INFO lines (GL, file loading, font loaded, screenshot exported).

## Guesses
- Asynchronous loads: I guessed the callbacks fire while the frame loop runs, so drawing is skipped until texture and fonts are all loaded. This worked.
- First attempt kept the screenshot wait loop empty (Begin/EndDrawing only), which gave a black `shot.png`. Now the wait loop keeps drawing the scene until the screenshot callback fires.
- Passing `null` for the codepoints of `LoadFontExAsync` means the default ASCII set.
- Blink: on for the first half of each second, off for the second half (the task didn't say the duty cycle). It uses `GetTime()`.
- Prompt Y: title top at 120 + measured title height + 20 px gap. "120 pixels from the top" was read as the title's top edge.
- Background color (20,20,28) was my pick for "dark".
- Enter is checked after `EndDrawing`, and `--frames=N` counts drawn frames.
