# NOTES

## Compile errors hit
1. `GuiProgressBar(..., health * 100, 0, 100)`: "Float should be Array<Float>". The value is a pointer in the Haxe binding, so I keep a
   one-element `Array<Float>` (`healthV`) and set `healthV[0]` each frame.
2. `SetMainLoop`: unknown identifier. I guessed it existed for the JS target. I replaced it with a plain
   `while (!WindowShouldClose()) frame();`. I don't know how a JS build is meant to yield to the browser. I did not check, so this may
   block there.

## Guesses / unsure
- **Loading**: I used `LoadTextureAsync` (seen in the GuiSkins doc example) for textures and `LoadTextureAtlasAsync` for the atlas. I
  show "Loading..." until every callback has fired. I passed `assets/icons.xml` to the atlas call and assume the texture is found beside it.
- **GuiSkinFromTexture**: its `horizontalPatchMode`/`verticalPatchMode` parameters are not forwarded to `RGuiSkins.GuiSkinFromTexture`
  in the API source (`GuiSkinFromSheet` does the same). So the rope's `NPATCH_MODE_TILE` on the panel may be silently ignored. The panel
  asks for tiled twists this way (`GuiSetSkin(DEFAULT, GUI_SKIN_BASE, ...)`), and I can't tell whether it works. The alternative
  would be to draw the panel myself with `DrawTextureNPatchEx`, but the task wants raygui's panel.
- **NPatchInfo layout** for the 96x16 bars: I used `NPATCH_THREE_PATCH_HORIZONTAL` with left/right 16 and top/bottom 0. For the tip
  (16x16, drawn whole) I used a 0-border `NPATCH_NINE_PATCH`. I'm unsure what a skin wants for a part that isn't stretched.
- **Thermometer**: `GUI_SKIN_FILL_CLIPPED` plus `GUI_SKIN_FILL_EDGE` is my reading of the docs. Both are set on `PROGRESSBAR`. I assume
  the tip is centered on the end of the red automatically, so I draw nothing myself. I'm unsure whether the edge is drawn at 0 and at full.
- **Panel / skin timing**: skins are set once after loading, DEFAULT first, then PROGRESSBAR. `GuiPanel(bounds, null)` takes a null
  text; I assumed that is allowed.
- **Speed gauge**: the radial fill works about dest's middle, but the dial's center is the bottom middle of the 200x100 image. With
  `dest` = 200x100 the sweep would be centered on the wrong point. I passed dest 200x100, `startAngle` -90, `fillDegrees` 180 and
  `TEXTURE_FILL_CLOCKWISE`, assuming it handles a half-circle in a half-height rect. If it doesn't, dest would have to be 200x200 with
  a source taller than the texture. The "left end" being -90 follows from "degrees clockwise from straight up". The needle is a
  `DrawLineEx` from the bottom middle of dest to `GetTextureFillEdgeEx`, which assumes the edge point is on the rim and that the rim's
  center is dest's bottom middle. That is not what the doc says (it says dest's rim).
- **Mana froth**: I took the fill edge as the middle of the surface line and drew the 64x12 froth centered on it, as in the doc example.
  The ball is 128x128 and its source is the full 128x128 texture.
- **Cooldown**: the grey is `GRAY` as the tint on a normal `DrawTexture` of the icon. Is a multiplied tint right for "grey"? A
  desaturated icon would be better, and there is no such call. The fill is `TEXTURE_FILL_CLOCKWISE` from up with amount 0..1.
- **Hexagon**: `DrawTexturePoly` needs a closed fan, so I appended the first point again with `pointCount` 7. I'm unsure whether it
  closes the fan itself (then the count would be 6). Texcoords are `0.5 + 0.5*cos/sin`, so the 128 px portrait is scaled to the 96 px
  hexagon across (corner to corner, radius 48).
- **Mouse**: raygui reads the mouse in window space, so I used `GetRenderTextureFitRect` with `SetMouseOffset` (negative of the
  rect's origin) and `SetMouseScale` (640/width, 360/height). I assumed `DrawRenderTextureFit` with `integerScale=false` fills as
  large as fits, and that the offset/scale pair maps as raylib documents.
- **Atlas icons**: I draw each `sword`..`bow` with `DrawTexturePro` from `GetTextureAtlasRect`, at 64x64. I assumed the image names match
  the XML's `name` with no `.png` extension, and that `atlas.texture` is the sheet.
- **Background**: `DrawTextureTiled` with scale 0.5 and origin (0,0), rotation 0.
- Layout (where each widget sits on the 640x360 screen) is my own choice. The task didn't say.
- Nothing ran, because the calls aren't built.

## API changes I'd suggest
- Forward the patch modes in `GuiSkinFromTexture`/`GuiSkinFromSheet` (currently dropped).
- A radial fill with a pivot or center parameter, or say in `DrawTextureFillEx` where a half-circle's center is. A gauge's dial is a
  half-height image.
- A needle helper (a texture drawn at the edge, rotated by its angle in z), plus a grey/desaturated tint or draw mode for a cooldown.
- Make `DrawTexturePoly` close the fan itself, or say that it does not. Say what `pointCount` counts.
- Document the mouse mapping for `DrawRenderTextureFit` (a helper to set the mouse offset and scale).
- Say which loop to use on the JS target, and whether `LoadTexture` works there.
- Say what `NPatchInfo` layout a skin wants for a `GUI_SKIN_FILL_EDGE` part.
- Doc whether `GuiPanel`'s text can be null.
