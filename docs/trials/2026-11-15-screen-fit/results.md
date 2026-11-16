# Library trial: the Screen extra (2026-11-15)

Whether agents can fit a 320 x 180 pixel-art game to any window with the Screen extra's draft (`SetScreenFit` with its stretch and fit
modes, `ClearScreenFit`, `GetScreenFitRectangle`, `GetScreenFitFovy` and `GetScreenSafeArea`), learning it from its doc comments alone.
Two fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials' sandbox
(`run_entrant.py --trial`), were given [the brief](module/brief.md), [the task](task.md) (a level of tiles whose sprite turns, the tile
under the mouse outlined, a HUD in the safe area, every fit cycled with F, and a 3D view under expand) and the extra as tried
([module/docs/api](module/docs/api)), not built, compiling for JavaScript ([build.hxml](build.hxml)). Both compiled, in 7 and 8 turns,
under a minute and $0.15 and $0.17, screen-fit.001 on its first build. Both chose `SCREEN_STRETCH_VIEWPORT` with integer scaling for the
pixel art, and `SCREEN_FIT_EXPAND` with `GetScreenFitFovy` for the 3D view.

## What it found

| finding (both agents unless noted) | to do |
|---|---|
| Where the design sits when a fit grows the screen: screen-fit.001 left it at the top left, screen-fit.002 centred it by hand | open: a rule, centred or top left |
| The fit, its stretch and the integer scale in use, kept by the program to show them | `GetScreenFit` and `GetScreenFitScale` |
| Whether `SetScreenFit` may be called at any time, and from which frame it takes effect | said in the doc comments |
| Whether the safe area is of the design grown or of the design alone | said in the doc comments |
