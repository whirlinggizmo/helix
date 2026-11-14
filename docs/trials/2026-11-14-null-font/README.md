# Library trial: a null font (2026-11-14)

Whether agents keep a font that's still loading out of the text calls, and whether the refusal sends them to the fix: the text calls
(`DrawTextEx`, `DrawTextPro`, `DrawTextCodepoint`, `DrawTextCodepoints`, `MeasureTextEx`) refusing a null font, as a font is until its
`LoadFontExAsync` calls back, where natively they crashed (`helix-raylib-blind.018` of the Wardens extras trial met it), and each
asynchronous loader saying its asset is invalid until `loaded` is called. Nine fresh Sonnet agents in three rounds of three, each a
`claude -p` in a directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), built and ran
[a title screen](task.md) natively: a panel, "WARDENS" in a font file centered by `MeasureTextEx`, and a blinking prompt in the same
font. Each run's program and notes are in the folder named for it.

- **docs** ([brief](module/brief.md)): raylib 5.5's headers and examples, and helix-raylib's pages for text and textures (`module/docs/api/`).
- **blind** ([brief](blind/brief.md)): the headers and examples alone, as the blind trials have them.
- **fix** ([brief](fix/brief.md)): a [Main.hx](fix/Main.hx) given, measuring and drawing with its fonts as soon as it asked for them, to
  build, run and fix.

| round | cost | turns | time |
|---|---|---|---|
| docs | $0.33, $0.19, $0.18 | 12, 9, 9 | 80, 63, 61 s |
| blind | $0.16, $0.13, $0.16 | 10, 7, 10 | 74, 63, 75 s |
| fix | $0.11, $0.14, $0.11 | 7, 9, 7 | 60, 75, 60 s |

All nine built and ran, and each `shot.png` showed the title screen.

- **docs and blind:** all six loaded the fonts with `LoadFontExAsync` (the compiler's refusal of `LoadFontEx` names it) and drew
  nothing until each was loaded, with the pages and without them. None met the refusal.
- **fix:** all three read the refusal the program logged ("FONT: MeasureTextEx refused: the font is null. An asynchronously loaded font
  is invalid until its loaded callback is called."), and measured each font once it had loaded, drawing nothing until then.

The six writing their own program met `TakeScreenshot`'s refusal, as the Wardens runs did (and fix.002, trying it in place of the
given `TakeScreenshotAsync`), and three saved a black `shot.png` first, its frame drawn empty while the screenshot waited.
