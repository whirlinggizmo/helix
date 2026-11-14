# NOTES

`haxe build.hxml` compiles `Main.hx` with no errors. Not run (assets absent, calls unbuilt).

## Compile errors hit
- `LoadTexture: Not supported. Use LoadTextureAsync` (11 times). Changed every load to `LoadTextureAsync` into static fields, and the
  atlas to `LoadTextureAtlasAsync`. The loop draws black until all have arrived (`ready()`), then sets the skins once
  (skins need the loaded textures). A plain `while` loop is used; I don't know whether JS needs a different main-loop idiom.

## Guesses / unsure
- **GuiSkinFromTexture's `horizontalPatchMode` / `verticalPatchMode`**: its body doesn't pass them on, and `GuiSkinFromSheet`'s
  likewise. I passed `NPATCH_MODE_TILE` for the rope panel as the docs say, but cannot tell it takes effect. The task needs
  repeating twists, so this is the riskiest spot. The fallback would be skipping `GuiPanel` for the frame and calling
  `DrawTextureNPatchEx` myself, but the task says raygui's panel.
- **Panel skin**: the doc says `GuiPanel` draws `DEFAULT`'s `GUI_SKIN_BASE`, so I set it on `DEFAULT`. That is also set on every
  control, including the progress bar; I set the progress bar's own skin first in code, but the doc says "set DEFAULT's first and
  each control's own after", and I first did the opposite order.
  Fixed: DEFAULT is now set first, the bar's after.
- **Progress bar skins**: base/fill use a nine-patch with left/right borders 16, top/bottom 0 (round caps). Edge (`bar_tip`) uses
  borders 0. Unsure whether a 0-border patch is valid, or whether the edge should be a patch at all; it is "drawn whole at the
  texture's size", so a plain texture would be more natural than a `GuiSkin`. `GuiSkinFromTexture` is the only constructor offered.
- **`GuiProgressBar` value** is `Array<Float>` (pointer emulation); min 0, max 100 for health.
- **Mouse mapping**: `GetRenderTextureFitRect` gives the rect; I used `SetMouseOffset(-x, -y)` and `SetMouseScale(1/scale)`. Whether
  raygui reads the offset mouse isn't documented in the extras. Taken from raylib's own API.
- **Hexagon**: `DrawTexturePoly` points are absolute pixels, so I added the center to each. Texcoords are 0.5+0.5cos/sin so the whole
  128 portrait is squeezed into the 96-wide hexagon. The center is drawn at texcoord (0.5,0.5) ("the texture's middle").
  Hex orientation: points start at angle 0, so vertices are left/right (96 across point to point).
- **Gauge**: `DrawTextureFillEx` with `TEXTURE_FILL_CLOCKWISE`, startAngle -90 (left, straight up = 0), fillDegrees 180, dest = the
  200x100 rect. Unclear whether a radial fill's center is dest's center (the middle of the 100px height) or whether I must pass a
  200x200 dest so the centre falls on the dial's hub. The doc says "about the middle" so I think dest's middle would put the center
  mid-texture, wrong for a half dial. I drew the fill on the 200x100 rect but computed the needle on a 200x200 rect
  (hub at 260,230); the two may disagree. A `center` or "half circle" option would remove the guess.
- **Needle** is `DrawLineEx` from the hub to `GetTextureFillEdgeEx`; no needle texture was given.
- **Cooldown**: `TEXTURE_FILL_CLOCKWISE` default start is straight up, as the task wants.
- **Mana ball**: `GetTextureFillEdge` takes no texture (docs example in the class comment passes `ball, mana, dir`; the signature is
  `dest, amount, dir`), the same as I used. The froth is centered on the edge point, unclipped to the ball.
- **Atlas**: `atlas.texture` is used for the draw, with `GetTextureAtlasRect` for the source. Names `sword` etc. assumed to lack
  the `.png` extension (Kenney XML names carry it, "sword.png"?). Unknown which the lookup expects.
- **DrawRenderTextureFit** `integerScale` false: 1280x720 is exactly 2x so either works.

## API changes I'd make
- Make the tiling modes in `GuiSkinFromTexture`/`GuiSkinFromSheet` actually forwarded (bodies drop them), and `GuiSetSkinFillMode`/
  `GuiSetSkin` ordering rule enforced or documented louder.
- A radial fill needs an explicit center, or a documented half-circle case (`DrawTextureFillEx` dest vs. texture size).
- `GuiSkinFromEdge(texture)` / a way to give a plain texture for `GUI_SKIN_FILL_EDGE`.
- The class example in `Textures` passes `GetTextureFillEdge(ball, mana, dir)` consistent with the signature, but its `DrawTextureFill`
  example uses 64x64 for a texture that elsewhere is 128; harmless.
- Say whether atlas names include the file extension.
