# Library trial: raygui's skins (2026-11-04)

Whether agents can skin raygui's controls from a game's art, learning `extras.GuiSkins` from its doc comments alone. Two fresh Sonnet
agents, each a `claude -p` in a scratch directory outside any repository, were given [the task](task.md) (a main menu: a nine-slice
panel, three buttons from a four-state sheet, a skinned slider, a one-off close button), the art from the jam's assets, and the API as
it was tried ([api-as-tried](api-as-tried)), its functions not yet built. Both compiled cleanly in 11 and 13 turns, about $0.20 each.
Their programs and notes are in `agent-1/` and `agent-2/`.

## What it found, and what changed

| finding (both agents unless noted) | change to the API |
|---|---|
| "Type not found: GuiSkin": it was `helix.raylib.extras.GuiSkin`, which neither guessed | `GuiSkin` is `helix.raylib`'s, beside raylib's types, which both had imported already |
| The doc's example wrote `NPatchInfo(...)`, which isn't Haxe | the example shows a real call |
| Cutting a stacked sheet into four patches by hand, the error-prone part of the task | `GuiSkinFromSheet(texture, cellWidth, cellHeight, left, top, right, bottom)` cuts raygui's four states down or across |
| No skin target for a panel; agent 1 drew it by hand | `DEFAULT`'s base is what `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw, and setting `DEFAULT` sets every control, as `GuiSetStyle(DEFAULT, ...)` does |
| Unsure which parts each control has, and how a disabled control draws | a table of controls and parts, and the states each draws, in the module's doc |
| A one-off button's skin: both put the old skin back after the call | kept: `GuiGetSkin` then `GuiSetSkin` around the call, as raygui's style is changed and put back, now said to work in the docs |

Not the skins' (the general API, met in passing): `GuiButton` returns an `Int`, as raygui 4.5's C does; a control's pointer is a
one-element array; the extras modules were found from the compiler's refusals.
