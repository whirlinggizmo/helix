# Notes

## Compile errors
None. `haxe build.hxml` compiled on the first try. Constructors `new Color(r,g,b,a)`, `new Vector3(..)`, `new Camera3D(pos, target, up, fovy, projection)` and `new Rectangle(..)` were guessed from the C structs' field order.

## Guesses / unsure
- **Fit modes in 2D:** F calls `SetScreenFit` again with the new fit, assuming a repeated call just replaces the setting (no `ClearScreenFit` first). Unsure whether it is cheap to call or resets anything.
- **3D view:** Tab calls `SetScreenFit(320, 180, CANVAS, EXPAND, false)`. I chose EXPAND for "no bars, more world on the longer side", `integerScale=false` because whole-multiple scaling leaves bars of under one design pixel, and CANVAS because pixel art no longer matters in 3D. Unsure whether stretch mode matters for 3D under VIEWPORT (is the 3D rendered at design resolution and upscaled?).
- **Fovy:** `camera.fovy = GetScreenFitFovy(40)` every frame in 3D. The camera is framed at the design's 16:9 (the level is 20 x 11 units, so height 11.25 needed to fit the width). I assumed that on a window wider than 16:9 under EXPAND the vertical fov stays 40 and more shows sideways, and on a taller one the fov widens so the level's width stays in view.
- **Mouse:** `GetMousePosition` assumed to be in design pixels (320 x 180) under the fit, including under the bars (it may be outside 0..320 there; I bound-check the tile).
- **Safe area:** `GetScreenSafeArea` is called each frame in design pixels (2D), since it may change with rotation. It is unclear whether under EXPAND/KEEP_* (design grown) the safe area is relative to the grown screen; I assume so. The HUD is laid out from the safe rect's left/top/right edges. The notch inset in the doc says "screen's coordinates", so the grown screen is assumed.
- **GetScreenWidth/Height** are not used: the level is anchored at the design's top-left (0,0), so under KEEP_WIDTH/HEIGHT/EXPAND growth the level sits in the top-left of the grown screen, not centred. Unclear whether the design's origin stays top-left or is centred in the grown area.
- Under STRETCH the pixels are not square; the doc says integerScale is ignored there.

## Changes I'd make to the API
- A fit that reports the current design size beyond `GetScreenWidth`, and a way to read the current fit/stretch (`GetScreenFit`), so a program need not track it.
- Say explicitly where the design's origin sits when a fit grows the screen (left/top, or centred with negative coordinates).
- Say whether `SetScreenFit` may be called every frame / on each mode change.
- Ship a helper like `ScreenToDesign` for pointers outside the design (in the bars).
