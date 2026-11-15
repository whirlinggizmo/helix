# Notes

## Compile errors
None. It compiled on the first build; the only later edits were cleanups (level centering, a redundant `dist` computation).

## Guesses / unsure
- **Fit change on the fly:** I call `SetScreenFit` again on Tab and F, assuming it can be called any time (also mid-loop, outside Begin/EndDrawing) and takes effect on the next `BeginDrawing`.
- **3D under `SCREEN_FIT_EXPAND`, CANVAS, integerScale=false:** I assumed non-integer so no leftover bars appear. With integerScale true, the doc says leftover (<1 design pixel) is bars, which the task forbids.
- **Camera framing:** I framed the 16:9 design height (180/16 = 11.25 units) at fovy 40 and used `GetScreenFitFovy(40)` every frame. Assumed this keeps the whole level visible on a taller window, and a wider window just shows more at the sides.
- **Growing fits in 2D:** `GetScreenWidth/Height` then exceed 320x180 (KEEP_WIDTH, KEEP_HEIGHT, EXPAND), so I centre the level by (GetScreenWidth - 320) / 2 and subtract that offset from `GetMousePosition`. I assume the mouse is in those same design pixels (doc says so) and fractional under no-fit; I floor it.
- **GetScreenSafeArea:** assumed design pixels under a fit, so HUD text and heart sit at its corners; unsure whether it is relative to the grown design (I assume yes) rather than the 320x180 core.
- **STRETCH:** with `SCREEN_FIT_STRETCH` the design is 320x180 stretched, non-square pixels; I treat that as expected.
- **F cycling:** 5 fits x integerScale on/off (STRETCH shown once per toggle; its name shows without INT/FREE although integerScale flips it, a no-op).
- Drawing text with the default font inside a viewport stretch: assumed it renders at the design size.

## What I'd change in the API
- A getter for the current design size / fit (e.g. `GetScreenFit`) so the program need not track its own state, and for the offset of the original design inside a grown one.
- A `GetScreenFitScale()` to learn the integer scale actually used.
- State whether `SetScreenFit` is legal inside a frame, and whether it resets the camera/mouse state.
- A way to ask for "expand" with an integer scale and no bars (the doc's leftover bars conflict with that); the 3D view needs non-integer there.
- Name the pixel unit of `GetScreenFitRectangle` more clearly with respect to DPI (stated, but easy to miss).
