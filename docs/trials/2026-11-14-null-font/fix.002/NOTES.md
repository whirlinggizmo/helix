# Notes

## Compile errors (in order)
1. The original Main.hx built with no errors.
   (While trying a fix, I swapped in `LoadTexture`, `LoadFontEx` and `TakeScreenshot`. The compiler rejected each as "Not supported" and pointed to the `*Async` versions. I reverted to the async calls.)

## Warnings logged
1. `FONT: MeasureTextEx refused: the font is null. An asynchronously loaded font is invalid until its loaded callback is called.`
   Cause: the font was measured right after `LoadFontExAsync`, before it had loaded.
   Fix: measure each font in the frame loop once its callback has set it. Drawing of the title and prompt waits for that measurement. The panel was already guarded.

## Guesses
- Text spacing of 2 was kept from the original.
- `--frames=N` takes the screenshot via `TakeScreenshotAsync` on frame N, and the loop exits when its done callback fires.
- A frame count of 120 is enough for the async loads to finish, so the screenshot shows the title.
