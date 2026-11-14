# Notes

## Compile errors
None.

## Warnings logged
1. `WARNING: FONT: MeasureTextEx refused: the font is null. An asynchronously loaded font is invalid until its loaded callback is called.`
   Changed: MeasureTextEx was called right after LoadFontExAsync, before the fonts had loaded. Sizes are now measured in the loop once each font is non-null, and drawing is skipped until then.

## Guesses
- Guessed that measuring lazily (first frame the font exists) was better than blocking until the fonts loaded.
- Kept the async loaders and TakeScreenshotAsync as written, since they compiled and worked.
