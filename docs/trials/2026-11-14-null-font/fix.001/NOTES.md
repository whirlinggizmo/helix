# Notes

## Compile errors
None. The original built cleanly.

## Warnings logged
- `WARNING: FONT: MeasureTextEx refused: the font is null. An asynchronously loaded font is invalid until its loaded callback is called.`
  The fonts load asynchronously, so `font` and `small` were still null when `MeasureTextEx` ran before the loop.
  Changed: the measuring now happens inside the loop, once each font is non-null. Drawing of the title and prompt is also guarded on that. No warnings after the change.

## Guesses
- Kept the async loaders and screenshot calls as written, since they worked.
- Left the 2 px letter spacing and the colors (LIGHTGRAY prompt, dark background) as in the original; the task doesn't specify them.
