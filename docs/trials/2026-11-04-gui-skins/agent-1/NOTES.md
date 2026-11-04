# Notes

## Compile errors, in order
1. `Type not found : Texture2D` — `import helix.raylib.Raylib.*` brings in no types. Added `import helix.raylib.Raylib;` (no effect), then `import helix.raylib.Texture2D;` (worked).
2. `Type not found : Font` — added `helix.raylib.Font`, `Rectangle`, `Color`, `Vector2`, `NPatchInfo` imports the same way (guessed the package; all resolved). `GuiSkin` imported from `helix.raylib.extras.GuiSkin`.
3. `Unknown identifier : LoadTextureAsync`, `LoadFontExAsync`, `SetMainLoop` — guessed `helix.raylib.extras.Textures.*` (worked for LoadTextureAsync) and `Fonts.*` (`Type not found`). Replaced font load with sync `LoadFontEx` to provoke the hint; the compiler named `helix.raylib.extras.Text`. Imported that. Dropped `SetMainLoop` (doesn't exist) for `while (!WindowShouldClose()) frame();`.
4. `Int should be Bool` on every `if (GuiButton(...))` — GuiButton returns Int; changed to `!= 0`.
5. `Float should be Array<Float>` for GuiSlider `value`, `Bool should be Array<Bool>` for GuiCheckBox `checked` — by-reference params; made `volume`/`fullscreenOpt` one-element arrays and stopped assigning the return.

## Where the skins docs left me guessing
- **NPatchInfo construction**: docs say `NPatchInfo(...)` in the example, so I guessed an anonymous-struct literal `{source, left, top, right, bottom, layout}` with `NPATCH_NINE_PATCH`. It compiled, so fine, but the docs never say.
- **Which module imports are needed / where types live** (see errors 1–3): not in the docs.
- **Close button, per-widget override**: no "skin one control instance" mechanism, so I swap `GuiSetSkin(BUTTON, BASE, closeSkin)` before the X and restore after. I assumed skins are read at draw time (immediate mode). Unconfirmed.
- **Close skin with only `normal` set**: I passed the focused cell as `normal` only and assumed focused/pressed/disabled then fall back to it. Docs say null → normal, which supports it.
- **Disabled state**: I assumed `GuiDisable()` makes the skin's `disabled` patch draw; docs only mention `STATE_DISABLED` in passing.
- **Slider parts**: assumed SLIDER uses BASE (box), FILL (bar), HANDLE (handle) as the constant docs suggest. Bar = pressed cell, handle = normal cell.
- **The pressed cell is 45 rows** within a 49 cell (slices.txt note); I used the full 49-row source for pressed. Unsure whether the nine-slice bottom margin then lands on transparent pixels. Might need a 45-high source rect.
- **Text color / font on skins**: assumed `GuiSetFont` + `TEXT_SIZE` style applies; text stays the style's colors.
- **Margins are per cell** (given), so each cell's NPatchInfo has its own source rect with y offset i*49.
- **Panel**: drew with `DrawTextureNPatch` rather than a skinned control (no panel-less skin target for plain drawing); considered `GuiPanel` with a PANEL skin but it wasn't clear PANEL exists as a control for skins. Quit "disabled in a page" was ambiguous; I disabled it always.
- **Main loop on web**: `while` loop compiles, but I can't tell if it yields to the browser so async loads complete. Not run, as instructed.

## What I'd change
- Provide `NPatchInfo` helper e.g. `GuiSkinFromSheet(tex, cellW, cellH, margins, states)` that cuts vertical/horizontal sheets itself — this task is exactly that.
- Offer a per-call override (`GuiSetSkinOnce` or push/pop `GuiPushSkin`) for one-off controls like the close button.
- Document the imports needed (types package) in the GuiSkins example, and say whether skins are read at draw time.
- Say explicitly how `GuiDisable` interacts with `disabled`, and which controls use which parts (table of control → parts).
- Allow skinning DrawPanel/GuiPanel/GuiGroupBox so the panel itself needn't be drawn by hand.
- Mention the main loop story for web next to the async loaders.
