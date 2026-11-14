# Notes

## Compile errors
None. The original built cleanly.

## Warnings logged
1. `TakeScreenshot: shot.png: Screenshot could not be saved: EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.`
   Changed: TakeScreenshot is now called on the last frame just before `EndDrawing()`, not after it. shot.png is now written and shows the title screen.

## Guesses
None. (The async loaders had finished well before frame 120, so I did not change them.)
