# NOTES

Assets in `assets/` don't exist here (only compiled, not run); `assets/` is an empty dir I made.

## Compile errors
1. `GuiProgressBar(..., health, 0, 100)`: "Float should be Array<Float>" for `value`. raygui's `float *value` is an `Array<Float>` in
   Haxe, so I pass `[health]`. (Fresh array each frame; the bar only displays, so nothing is read back.)
That was the only one; everything else compiled first time (`NPatchInfo` constructor, `LoadTextureAsync`, `WindowShouldClose` loop).

## Guesses / unsure
- **Loading**: the target is JS, so I used `LoadTextureAsync` and `LoadTextureAtlasAsync` and wait until all have called back before
  setting skins/drawing. I did not know whether sync `LoadTexture` works on JS. `LoadTextureAsync` isn't documented in the two extras
  (I took it from the GuiSkins doc example). A `while(!WindowShouldClose())` loop is a guess for JS too (no documented main-loop helper).
- **Atlas file**: passed `assets/icons.xml` to `LoadTextureAtlasAsync`; doc says the texture is "the file the atlas names, beside it".
  Names looked up as `sword.png` etc., with extension, per the doc.
- **Health bar skin**: one `NPatchInfo` (source 0,0,96,16; left/right 16, top/bottom 0, `NPATCH_THREE_PATCH_HORIZONTAL`) used for both
  grey box and red fill. Unsure if top/bottom 0 with a three-patch layout is what GuiSkins expects, or whether it wants 1+ borders. Used
  `GUI_SKIN_FILL_CLIPPED` (left cap always, right cap only when full) and `GuiSetSkinFillEdge(PROGRESSBAR, barTip)` for the tip. Unsure
  whether the tip is drawn *over* the fill end centred on the clipped edge (as doc says) and whether that edge is the clipped width or
  includes the cap; I assumed value/max across the control.
- **Skin scope**: `GuiSetSkin(DEFAULT, BASE)` for the panel also sets every control's base (per doc), so I set it *first* and the
  PROGRESSBAR skins after, as the doc instructs. Skins are global, so the panel's rope also applies to any other control I add.
- **Panel**: `GuiPanel(bounds, null)` - unsure if null text is OK for the Haxe binding (raygui's accepts NULL). Rope patch uses
  `NPATCH_MODE_TILE` both ways (not `TILE_FIT`, which scales tiles); with TILE the last tile is cut - TILE_FIT might look better at "any size".
- **Gauge**: `DrawTextureFillEx` with `TEXTURE_FILL_CLOCKWISE`, centre = bottom-middle of dest (the hub of the half-circle), start
  angle 270 (clockwise from up = pointing left), sweep 180. Unsure whether startAngle accepts -90 vs 270 (both the same I'd hope).
  `GetTextureFillEdgeEx` returns x,y = centre, z = angle, so I computed the needle tip myself with sin/cos (z clockwise from up:
  `x = hub.x + sin*r`, `y = hub.y - cos*r`) and drew it with `DrawLineEx`. Needle length 90 is arbitrary.
- **Fill edge of non-radial**: `GetTextureFillEdge` takes `(dest, amount, direction)` (no texture); the class doc example passes `(ball, mana, dir)`, which matches.
  The froth is centred on the edge (as the doc example does), so half of it sits above the mana's surface, half below.
- **Cooldown grey**: drew the icon with a `GRAY` tint, then the clockwise fill in `WHITE` over it. A true desaturated look would need a shader; tint is an approximation.
- **Hexagon**: "96 across" read as corner to corner (radius 48), flat sides top/bottom, first point at angle 0 (right). Texcoords map
  radius 48 onto 0.375 of the texture (portrait 128 shown at 96 px, i.e. scale 0.75), so the whole portrait's central 96 px square-ish
  region shows. `pointCount` is 6 with no repeated first point since the doc says it closes itself. Does `center` need to be among the texcoords? I gave it (0.5,0.5) implicitly ("drawn with the texture's middle").
- **Window fit**: `SetMouseRenderTextureFit` called every frame, before drawing; `DrawRenderTextureFit(target, false, WHITE)` (no integer scale; 1280x720 is exactly 2x anyway).
- **Layout** (all positions) is mine; the task didn't specify any.
- Raygui controls answer the mouse only if the skin controls are interactive; the progress bar isn't, so mouse use is moot here.

## API changes I'd suggest
- A doc line stating whether `GuiProgressBar` skins use the nine-patch borders on the *clipped* width and where the fill edge is for a value (min/max) ≠ 0..1.
- Say what `NPatchInfo.layout` should be for a horizontal-caps-only skin, or let skin helpers take caps (`GuiSkinFromCaps`).
- `GetTextureFillEdge` for radial could offer an `out` Vector2 point at a radius (needle tip) so users needn't do the trig.
- A grey/desaturated tint or `DrawTextureFill` flag for the "grey icon + colour reveal" cooldown pattern.
- Document `startAngle` range (negative / >360) and `LoadTextureAsync`, and whether atlas loading takes the `.xml` or the `.png` path.
- `GuiSkinFromTexture`'s long optional-argument list forces `null, null, null` to reach `tint`/modes; named-field `GuiSkin` structInit or an options object would be easier.
