# Notes

## Compile errors
1. `Main.hx:49 TakeScreenshot: Not supported. Use TakeScreenshotAsync(...)` — switched to `TakeScreenshotAsync("shot.png", done)` and keep looping until `done` fires, then break.

(Before that I used `LoadTextureAsync` / `LoadFontExAsync` from the docs instead of `LoadTexture` / `LoadFont`; no error, since I read the docs first.)

## Warnings logged
None (only INFO lines).

## Guesses
- Panel drawn with `DrawTexturePro` (stretched to 420x260), not a nine-patch.
- Font loaded at 64 px via `LoadFontExAsync` and scaled down to 24 for the prompt.
- Letter spacing 2 for both texts (task gives none).
- Prompt placed 30 px below the title's bottom (title y + measured height); the task says only "under the title".
- Blink: visible for half a second, hidden for half, using `GetTime()`.
- Dark background color (20,20,28).
- Assets load asynchronously, so nothing is drawn until they arrive.
