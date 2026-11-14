# Library trial: text offsets, texture icons and image buttons (2026-11-14)

Whether agents use three additions to `extras.GuiSkins` correctly from their doc comments alone, before any of it was written: a
skin's text offset for each state (a pressed face sitting lower, its text with it), a texture drawn for one of raygui's icons
(`GuiSetIconTexture`), and a button of images (`GuiTextureButton`). Fifteen fresh Sonnet agents in five rounds of three, each a
`claude -p` in a directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), were given
[the task](task.md): a main menu of three buttons with icons, a raised face, a pressed face 4 texels lower, one button disabled, one
whose face lifts on hover, and a round sound toggle of images alone. [The brief](module/brief.md) pointed at the extra's doc comments
in `module/api/`, the calls' bodies empty. The runs compiled their programs, natively, and didn't run them. Each run's program and
notes are in the folder named for it (`buttons.001` to `.003` for round one, `buttons2.*` to `buttons5.*` after).

| round | cost | turns | time |
|---|---|---|---|
| one | $0.170, $0.170, $0.162 | 6, 6, 5 | 37, 38, 36 s |
| two | $0.143, $0.156, $0.176 | 4, 4, 7 | 31, 36, 41 s |
| three | $0.160, $0.162, $0.151 | 5, 5, 5 | 36, 37, 34 s |
| four | $0.161, $0.160, $0.157 | 5, 6, 6 | 31, 34, 34 s |
| five | $0.177, $0.209, $0.186 | 6, 8, 6 | 43, 50, 44 s |

All fifteen compiled, and all fifteen used every new call for its part: the icons through `GuiSetIconTexture` on raygui's spare icons and
`GuiIconText`, the toggle through `GuiTextureButton`, the faces' moves through the text offsets. By round three the runs set the
same offsets: (0, -2) normal and disabled, (0, 2) pressed, (0, -4) for Quit's lifted focused face.

## What it found, and what changed

| round | finding | change |
|---|---|---|
| one | Whether the icon and text are centered together | the icon is laid out as raygui's: the two aligned together as the control aligns its text |
| one | Which way an offset points | x right and y down |
| one | Whether an image button's clear corners answer the pointer, and whether a disabled one reports a click | the whole rectangle answers; a disabled one always returns 0 |
| two | The text is centered over the whole button, lip included, so it sits 2 pixels low on a raised face, and there was no offset for the normal state | `normalTextOffset` |
| two | Whether an icon's source is in texels | it is |
| three | Every run asked for a skin for one button, the offsets made from the art, and a hit test skipping clear corners | `GuiSetSkinOnce`; `GuiSkinFromSheet`'s `lip` and `lift`; `GuiTextureButton`'s `clickMask` |
| four | Whether a disabled call takes `GuiSetSkinOnce`'s skin, and whether the bottom border holds the lip | the next call of that control takes it, drawn or disabled alike; the bottom border includes the lip |
| four | The fill mode and fill edge were set per kind of control, so two progress bars couldn't differ (asked by the user after round four, a health bar clipped with a tip beside an experience bar stretched with none, as Godot's and Unity's bars are set each) | `GuiSkin`'s `fillMode` and `fillEdge`, `GuiSetSkinFillMode` and `GuiSetSkinFillEdge` gone; the task gained the two bars |
| five | Whether a one-call skin brings its text offsets, fill mode and edge | it's drawn in full |

In rounds four and five all six runs used the additions as their docs say, setting no offset by hand, and in round five each gave the
two bars different fills with `GuiSetSkinOnce`.

Every run hit `LoadTexture`'s refusal first and moved to `LoadTextureAsync`, as the refusal says.
