# Library trial: TakeScreenshot (2026-11-14)

Whether agents save a screenshot with `TakeScreenshot` as it is here, and whether its refusal sends them to the fix. `TakeScreenshot`
returns at once, the next `EndDrawing` saves that frame and returns once the file is written, and `CloseWindow` refuses a screenshot
with no `EndDrawing` called after `TakeScreenshot`. raylib's reads the screen at once, so a C program calls it after `EndDrawing`.
Fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials' sandbox
(`run_entrant.py --trial`), built and ran [a title screen](task.md) natively, saving `shot.png` on its last frame. Each run's program
and notes are in the folder named for it.

- **docs** ([brief](module/brief.md)): raylib 5.5's headers and examples, and helix-raylib's pages for the window and drawing, text
  and textures (`module/docs/api/`).
- **blind** ([brief](blind/brief.md)): the headers and examples alone, as the blind trials have them.
- **fix** ([brief](fix/brief.md)): a [Main.hx](fix/Main.hx) given, calling `TakeScreenshot` after its last `EndDrawing` and closing
  the window, to build, run and fix.

The refusal as tried: "TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()".

| round | runs | cost | turns | time |
|---|---|---|---|---|
| docs | 004, 005, 006 | $0.17, $0.16, $0.18 | 9, 9, 9 | 86, 77, 79 s |
| blind | 004, 006, 007 | $0.14, $0.16, $0.13 | 9, 12, 9 | 80, 83, 95 s |
| fix | 004, 005, 006 | $0.11, $0.11, $0.11 | 6, 6, 7 | 63, 63, 64 s |

All nine built and ran, and each `shot.png` showed the title screen. None met a compile error for the screenshot, and none saved
a black `shot.png`.

- **docs:** all three called `TakeScreenshot` as the pages give it, two before the last frame's `EndDrawing`, docs.004 between the
  last two frames. None met the refusal.
- **blind:** all three called it after the last `EndDrawing`, as a C program does, read the refusal and moved the call before
  `EndDrawing`. The next run saved the screenshot.
- **fix:** all three read the refusal and moved the call before `EndDrawing`.

The runs before: docs.001 to .003 had pages with `TakeScreenshotAsync` still in them, and blind.001 to .003 and fix.001 to .003
a longer refusal ("EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing."). They went as
these did. blind.005 doesn't count: `run_entrant.py` copied this record into its directory, and it read the answer there. The runner
leaves a trial's README.md out now.
