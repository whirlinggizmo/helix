# Notes

## Compile errors
None. It built on the first try.

## Warnings logged
None. The run logged only INFO lines.

## Guesses
- The docs list `LoadTextureAsync` and `LoadFontExAsync` in place of raylib's `LoadTexture` and `LoadFontEx`. I used those. The program draws nothing from them until their callbacks have run.
- Letter spacing is 2 px for both texts. The task gives none.
- "Blinking once a second" is read as on for 30 frames and off for 30.
- The prompt sits at y = 214, 30 px under the title's 64 px line. The task gives no distance.
- The "Enter closes the window" case breaks out of the loop and calls `CloseWindow()`.
