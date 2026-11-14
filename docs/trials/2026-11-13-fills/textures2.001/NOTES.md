# NOTES

## Compile errors
1. `GuiProgressBar(..., health, 0, 100)`: "Float should be Array<Float>". The value is a by-reference parameter, so I pass a one-element array (`healthRef`).
2. `frame(): Not supported in a function used as a value.` I first drove the loop with `requestAnimationFrame(function loop...)`. I changed it to `while (!WindowShouldClose()) frame();` in `main`. That compiles, but it would block a browser tab if the JS target really runs it that way. I don't know the intended JS main-loop idiom.

## Guesses / unsure
- **`GetTextureFillEdge` signature:** the `Textures` class doc example calls `GetTextureFillEdge(ball, mana, dir)`. The real signature is `(dest, amount, dir)` with no texture, so I followed the signature. The doc example is stale.
- **`GetTextureFillEdge` return:** it is a `Vector3`, and I read `.x`/`.y` as pixels in the same space as `dest`. I assumed that is the screen space I draw in, not texture space.
- **Froth placement:** I centred the froth on the edge point. I'm not sure whether the froth should be clipped to the ball.
- **Gauge:** I used `DrawTextureFillEx` with `TEXTURE_FILL_CLOCKWISE`, centre (100, 100), start -90, sweep 180.
  - The centre is given in "pixels", but I can't tell whether it is relative to `dest` or to the screen. I assumed relative to `dest`. The hub for the needle I computed in screen space.
  - `startAngle` is "degrees clockwise from straight up", so -90 is the left end.
  - Needle angle is `edge.z`; I computed the direction as (sin, -cos).
- **Fill edge for the health bar:** `GuiSetSkinFillEdge` draws the tip "centered on the fill's end". I assume it stays inside the bar vertically, and I didn't know whether it needs the progress bar's fill mode to be CLIPPED. I set CLIPPED because the task wants the right cap shown only at full health.
- **Skin `NPatchInfo`:** `GuiSkin` takes raylib's `NPatchInfo`. I built it as a struct-init with `source`, borders and `layout`, and used `NPATCH_NINE_PATCH` and `NPATCH_THREE_PATCH_HORIZONTAL`. I'm unsure whether `source` must be the whole texture, and whether a 3-patch layout is right for the bar (border top/bottom 0).
- **Panel skin:** it is set on `DEFAULT`/`GUI_SKIN_BASE` with TILE modes. `DEFAULT` skin propagates to every control (e.g. the progress bar's base) so I set `DEFAULT` first and `PROGRESSBAR` after, as the docs advise. I used TILE rather than TILE_FIT. TILE cuts the last twist at any size, while TILE_FIT scales each twist slightly and never cuts one. I'm unsure which the task means by "repeating rather than stretching".
- **`GuiPanel` text:** I passed `null` for the text. I assume that is accepted.
- **Mouse:** `SetMouseRenderTextureFit` is called each frame before drawing. I assume it is valid before `BeginTextureMode`.
- **Hexagon:** radius 48 around the centre (96 across, point to point), texcoords mapped from the unit circle so the square portrait is cropped to the hexagon.
- **Atlas:** `LoadTextureAtlasAsync("assets/icons.xml")`. Names are used with their extension (`sword.png`).
- **Async loading:** I used `LoadTextureAsync` as in the `GuiSkins` doc example, and wait until all have loaded before setting the skins.
- **Speed gauge fill direction:** a radial fill with start -90 and sweep 180 should reveal left-to-right over the top. I couldn't confirm this without running it.
- **Cooldown grey:** I drew the icon tinted `GRAY`. A true desaturated look would need a separate greyscale texture or shader.

## API suggestions
- Fix the `GetTextureFillEdge` example in the `Textures` class doc.
- State whether `center` in the `*Ex` fill calls is relative to `dest` or absolute.
- Say how a program's main loop should be written for the JS target.
- Provide a helper such as `NPatchInfo` constructors (`NPatchInfo.horizontal(w,h,left,right)`).
- Add a greyscale tint or draw mode for cooldown icons.
- Document whether `GuiPanel` accepts a null title.
