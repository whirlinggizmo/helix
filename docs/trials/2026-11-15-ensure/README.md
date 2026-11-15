# Library trial: ensuring files before raylib's loads (2026-11-15)

Whether one line in the brief brings agents to the Assets extra's ensure, and whether a program built natively then works in a page
unchanged. raylib's synchronous loads (`LoadModel`, `LoadTexture`, `LoadFontEx`, `LoadMusicStream`, `LoadSound` and the rest) read a
file at once natively. In a page a load reads only a file ensured first (`EnsureAssetAsync`, `EnsureAssetsAsync`). A load of any other
fails as raylib's load of a missing file does, logging why and giving raylib's empty result. Fresh Sonnet agents, each a `claude -p` in
a directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), built and ran
[a character viewer](task.md) natively: four glTF parts posed by a fifth file's clip, a panel image with a title in a TrueType font,
looping music and a sound on Space. Each run's program and notes are in the folder named for it.

- **line** ([brief](line/brief.md)): the brief's line "A file must be local before raylib's loads read it: ensure it with
  `EnsureAssetAsync(fileName, ensured)`, or several with `EnsureAssetsAsync(fileNames, ensured)`".
- **blind** ([brief](blind/brief.md)): without it.

Both had raylib 5.5's headers and examples, and nothing else about the library.

| round | runs | cost | turns | time |
|---|---|---|---|---|
| line | 001, 002, 003 | $0.21, $0.22, $0.22 | 15, 17, - | 13.0, 12.9, 17.6 min |
| blind | 001, 002, 003 | $0.22, $0.16, $0.16 | 14, 10, 11 | 12.9, 2.2, 2.2 min |

All six built and ran natively, and each `shot.png` showed the warden, the panel and its title. Each was then built for a page from its
own `build.hxml` (`score_page.py --viewport 1280x720`, the window the task asks for) and run in headless Chromium.

- **line:** all three ensured all nine files with one `EnsureAssetsAsync`, then loaded them in its callback, showing "Loading..."
  meanwhile (line.001 loads them in the loop once the callback has set a flag). All three pages drew the warden, the panel and its
  title as natively, with no errors.
- **blind:** none ensured a file. blind.001's and blind.003's pages drew the floor and the title in raylib's default font, with no warden
  and no panel. blind.002's page stopped at its first frame: its program reads
  `anims[0].frameCount` from `LoadModelAnimations`, which gave no animations, as a C program reading raylib's NULL there would crash.

The line alone brought every entrant to the ensure, and the program it wrote worked in a page unchanged. Without it, every program
worked natively and failed in a page as a program whose files are missing does.

The same two things met every entrant, in both rounds, and neither is the ensure. `LoadModelAnimations`' count is raylib's
`int *animCount`, an `Array<Int>` here and not optional; all six first called it without one and read the compiler's message (two then
met "You can't iterate on a Dynamic value", from the first error). All six called `TakeScreenshot` after `EndDrawing`, read its
refusal and moved the call, as [the TakeScreenshot trial](../2026-11-14-take-screenshot) found.

**Times.** line.001, line.002, line.003 and blind.001 started their first native builds together, at 05:26, and each build stopped
writing objects at 05:27: hxcpp blocked writing to its output pipe, haxe waiting to read. They ended about 05:37, and the entrants'
rebuilds took about a minute each. The same program built alone, its compile cache cold, took 53 seconds and wrote nothing to stderr,
so the stall needs the builds together. About ten minutes of those four runs' times is that stall. line.003's run then waited on its own
background loop, `while pgrep -f "haxe build.hxml"`, which matches its own shell, until the loop was stopped at 05:43. Its notes and
`shot.png` were written by then. Its turns aren't known: its `result.json` holds only the turn after the loop ended.
