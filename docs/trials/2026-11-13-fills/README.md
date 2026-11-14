# Library trial: texture fills and the Textures extra (2026-11-13)

Whether agents use a new extra, `extras.Textures`, and the fill additions to `extras.GuiSkins` correctly from their doc comments alone,
before any of it was written. Nine fresh Sonnet agents in three rounds of three, each a `claude -p` in a directory of its own outside
any repository, in the blind trials' sandbox (`run_entrant.py --trial`), were given [the task](task.md): a game's status widgets (a
thermometer health bar, a mana ball, a cooldown, a half-circle gauge with a needle, a rope-framed panel, a tiled floor, a portrait in a
hexagon, four icons from an atlas) drawn into a render texture fitted to the window. [The brief](module/brief.md) pointed at the two
extras' doc comments in `module/api/`, the calls' bodies empty. The runs compiled their programs and didn't run them. Each run's
program and notes are in the folder named for it (`textures.001` to `.003` for round one, `textures2.*` and `textures3.*` after).

| round | cost | turns | time |
|---|---|---|---|
| one | $0.217, $0.270, $0.198 | 6, 11, 5 | 55, 75, 49 s |
| two | $0.223, $0.203, $0.217 | 7, 5, 6 | 55, 46, 54 s |
| three | $0.236, $0.243, $0.249 | 9, 7, 10 | 55, 57, 58 s |

All nine compiled, and all nine used every new call for its widget: none wrote a fill, a tiled draw, a polygon or an atlas reader of
its own. By round three the three runs set the gauge up the same way: the hub at (100, 100) from dest's top-left, a start of 270 and a
sweep of 180.

## What it found, and what changed

| round | finding | change |
|---|---|---|
| one | The radial fill turned about dest's middle, and the gauge's hub is the bottom's middle | `DrawTextureFillEx` and `GetTextureFillEdgeEx` take the point the fill turns about, its start and its sweep |
| one | A fill's edge texture was a skin, made from a patch, where a tip is one texture drawn whole | `GuiSetSkinFillEdge(control, texture)` |
| one | The mouse mapped to the render texture by hand, from `SetMouseOffset` and `SetMouseScale` | `SetMouseRenderTextureFit` |
| one | Whether `DrawTexturePoly` closes the polygon, and whether an atlas's names keep their extension | each said in its doc |
| one | The GuiSkins draft's bodies forwarded to the shipped calls and dropped the new patch modes, which all three took for a bug | the trial's drafts given empty bodies |
| two | Whether the origin is from dest's top-left or the screen's, `ballBounds` read as a texture, and the angles' ranges | the origin from dest's top-left, as `DrawTexturePro`'s; `ballRectangle`; [0, 360) and [0, 360] |
| three | Reaching the patch modes in `GuiSkinFromTexture` took `null, null, null, WHITE` | the patch modes are the skin's fields alone, `NPATCH_MODE_STRETCH` in a made skin |
| three | Whether the fill edge is clipped to the control | it isn't: half of it lies outside at the minimum and the maximum |
| three | Which `NPatchInfo` layout a bar with caps wants | a skin's patch takes any of raylib's layouts, `NPATCH_THREE_PATCH_HORIZONTAL` for a bar with caps |

Left as they are:

- A radial edge gives the hub and the angle, and two of round three's runs wanted a point on the rim. A needle texture turns about the
  hub at the angle, and a rim point in a rectangular dest is no radius of a round dial.
- A skin on `DEFAULT` skins every control, and raygui has no panel control to skin alone.
- A regular-polygon helper, a greyscale draw and a `Float` form of `GuiProgressBar`, each asked for by one or two runs.

`LoadTextureAtlas`, waiting, was in the drafts and isn't in the extra: helix-raylib's asset loads don't wait (DECISIONS 72), and all
nine runs used `LoadTextureAtlasAsync`. Its reader is chosen by the atlas file's extension as the program builds, and an atlas's
texture is read as PNG and the platform's other formats, never GIF.

All three rounds were unsure how a page's main loop runs, as the build compiled to JavaScript under a brief with nothing about pages.
[build.hxml](build.hxml) now checks the program for C++ (`--no-output`), and the brief says the program is native.
