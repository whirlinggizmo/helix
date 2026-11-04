# Notes

## Compile errors, in order
1. `Type not found : Texture2D` -> added `import helix.raylib.*;` (types aren't brought in by `Raylib.*`).
2. `Type not found : GuiSkin` -> added `import helix.raylib.extras.GuiSkin;` (`GuiSkins.*` doesn't bring the class).
3. `Class<NPatchInfo> cannot be called` (I wrote `NPatchInfo(...)` as the GuiSkins doc example does) -> `new NPatchInfo(...)`.
4. `Unknown identifier : LoadTextureAsync` -> guessed `import helix.raylib.extras.Textures.*;` (sync `LoadTexture` error named it, with callback signature).
5. `Type not found : helix.raylib.extras.Fonts` -> guessed `extras.Text`; it compiled (LoadFontExAsync resolved).
6. `Int should be Bool` on GuiButton -> compare `!= 0`.
7. `Float should be Array<Float>` (GuiSlider value) and `Bool should be Array<Bool>` (GuiCheckBox) -> pointer-style args are 1-element arrays; return value ignored.
8. `Unknown identifier : LoadFontExAsync` -> fixed by the Text import (see 5).

## Guesses / unclear docs
- Doc example uses `NPatchInfo(...)` without `new` and with "..." args: constructor signature (source, l, t, r, b, layout) and `NPATCH_NINE_PATCH` guessed from raylib's struct; it compiled.
- Doc says `LoadTextureAsync` but not in which module, nor its callback signature.
- Pressed cell: slices.txt says the shape is 45 rows and "sits 4 px lower"; I guessed the art occupies rows 4..48 of the cell, so source rect y+4, h 45.
- Slice margins applied identically to the shortened pressed cell (14 each).
- Whether the skin rect is the NPatchInfo source rect in whole-sheet coordinates (assumed yes, not cell-relative).
- Per-control override: for the close button I swap BUTTON/BASE skin around the one call and restore; docs don't say whether that's intended (no per-call skin).
- Slider FILL/HANDLE skins: assumed the bar fills only the value portion; handle size unknown (raygui style).
- Disabled state: assumed GuiDisable()/GuiEnable() triggers the skin's `disabled` patch.
- Skins need all textures loaded first; I set them in a `build()` after the last async callback and draw nothing until then.
- Main loop: used a plain `while(!WindowShouldClose())` on a web target; it compiled, but I couldn't verify it works in browsers.
- Colors: title with DrawTextEx, not a skin; text color on skinned buttons left at style default (docs say style's text colors).

## Suggested API changes
- Put NPatchInfo/GuiSkin type in an import reachable by `GuiSkins.*`, or say which imports are needed in the doc header.
- Fix the doc example (`new NPatchInfo`, show the real args).
- Provide `GuiSkinFromSheet(texture, cellW, cellH, margins, states)` slicing a stacked sheet automatically; per-cell trimming is error-prone.
- A scoped override (`GuiWithSkin(BUTTON, part, skin, () -> ...)`) or per-call skin for the one-off close button.
- Document the async module names and the web main-loop pattern in the same place.
- Mention that GuiButton returns Int and slider/check box take array "pointers" in the Haxe binding.
