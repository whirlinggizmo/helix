# Library trial: casts from an object, and Color in braces (2026-11-15)

Whether a refused `cast` from an object sends agents to the fix, and whether they find `Color` in braces. helix-raylib refuses a `cast`
from an object to a class or an abstract in the program's own code, on every target, as natively the object was read as the class
and crashed ("cast: Not supported from an object to VirtualButtonOptions, a class. Write the object in braces where a
VirtualButtonOptions is expected, without cast."), and `Color` takes an object in braces where a color is expected. Fresh Sonnet
agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`),
built and ran [a pause menu](task.md) natively: a panel, five swatches given as RGB values, and two buttons of the VirtualGamepad extra.
Each run's program and notes are in the folder named for it.

- **fix** ([brief](fix/brief.md)): a [Main.hx](fix/Main.hx) given, its colors and buttons written as `cast {...}`, to build, run
  and fix.
- **docs** ([brief](module/brief.md)): helix-raylib's page for its types, `Color`'s braces among them.
- **blind** ([brief](blind/brief.md)): without it.

All three had raylib 5.5's headers and examples and the VirtualGamepad and Device extras' pages, which the task needs.

| round | runs | cost | turns | time |
|---|---|---|---|---|
| fix | 001, 002, 003 | $0.18, $0.16, $0.16 | 15, 10, 13 | 174, 177, 168 s |
| docs | 001, 002, 003 | $0.40, $0.37, $0.38 | 7, 7, 18 | 27, 27, 182 s |
| blind | 001, 002, 003 | $0.21, $0.19, $0.27 | 10, 8, 18 | 242, 210, 178 s |

All nine built and ran, and each `shot.png` showed the menu with both buttons. docs.001's and docs.002's times are `result.json`'s.

- **fix:** all three read the ten refusals, removed each `cast` and wrote the objects in braces, the colors too. None wrote
  `new Color`.
- **docs:** docs.002 wrote its colors in braces. docs.001 and docs.003 wrote `new Color(...)`. None wrote a `cast`.
- **blind:** all three wrote `new Color(...)`. None wrote a `cast`.

No entrant writing the program fresh wrote a `cast` from an object, so the refusal met only the given program, and sent each of its
three to the fix. Six of the nine also called `TakeScreenshot` after `EndDrawing`, read its refusal and moved the call, as
[the TakeScreenshot trial](../2026-11-14-take-screenshot) found. All nine turned off the virtual gamepad's default sticks, which the task
didn't name.
