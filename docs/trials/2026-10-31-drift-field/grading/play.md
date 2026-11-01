# Play-test grading: Drift Field, three games

Graded only on what was observed running: the recorder's `REC` lines, frame arrival times, screenshots and the page's console. The
builds in `grading/builds/N` were used as they were; nothing was rebuilt. Page means Chromium headless (Playwright 1.64, SwiftShader,
`--mute-audio`, 960x540 viewport, served on an ephemeral port). Native means `builds/N/native/Main` on the private display from
`run_native.py` (Xvfb with Openbox, `SDL_AUDIO_DRIVER=dummy`, no D-Bus). Input came from xdotool, and drops from a real XDND drag out of a
GTK window. Each native run had its own `XDG_DATA_HOME` under `grading/xdg/`, except the restart checks, which reused the first run's.

The drop files `custom.txt`, `custom-other-seed.txt` and `not-a-level.txt` were missing from `grading/`, so I made them there.
`custom.txt` is a valid level (seed 777, 1500x1000, 10 rocks, 8 crystals, 30 s, target 5). `custom-other-seed.txt` is the same with
seed 778. `not-a-level.txt` has `width=wide` and no `target`.

The drivers, raw logs and per-scenario JSON are in `grading/play/` (`lib.cjs`, `scenarios.cjs`, `run.cjs`, `N/<scenario>.<target>.{log,json}`).
Screenshots are in `grading/play/N/*.png`.

## Summary

| # | Item | 1 page | 1 native | 2 page | 2 native | 3 page | 3 native |
|---|------|--------|----------|--------|----------|--------|----------|
| 1 | Field: deterministic, page = native, rock sides, crystals clear | met¹ | met¹ | met¹ | met¹ | **wrong** | **wrong** |
| 2 | Speed 300, diagonal no faster, independent of frame rate | met | met | met | met | met | met |
| 3 | Click to fly at zoom 0.5/1/2 and turned; R; clamp; 90°/s | met | met | met | met | met | met |
| 4 | Map 200x120 bottom right, clipped at every zoom and turn | met | met | met² | met² | met | met |
| 5 | Text outside camera mode, kept to edges on resize, view fills, ship centred | met | met | met | met | met | met |
| 6 | Dropped files (custom plays as "Custom"; not-a-level notice ~3 s) | **wrong** | **wrong** | **wrong** | **wrong** | **wrong** | **wrong** |
| 7 | Level flow, best saved at once and kept, Escape | met | met | met | met | **wrong** | **wrong** |
| 8 | Rocks and the edge stop the ship; it slides | met | met | met | met | met | met |
| 9 | Gathering adds 1 (+ sound) | met | met³ | met | met³ | met | met³ |
| 10 | No crash, exception or console error | met⁴ | met | met⁴ | met | met⁴ | met |
| | **met / wrong / missing** | **9 / 1 / 0** | **9 / 1 / 0** | **9 / 1 / 0** | **9 / 1 / 0** | **7 / 3 / 0** | **7 / 3 / 0** |

1. The numbered levels were all checked. The custom and custom-other-seed fields could not be compared, because no dropped level ever
   plays (item 6).
2. The 200x120 map is clipped by a scissor of exactly 200x120. The 2 px white frame is drawn around it at 204x124.
3. The score went up by 1 for every crystal gathered. The sound can't be observed natively, because the audio driver is the dummy one.
4. The only console errors were "Failed to load resource: 404". At start-up, a page with no saved best fetches the best-score file from
   the server and gets a 404. Every dropped file gets one too (item 6). There were no page errors or exceptions.

## The most serious faults

- **All three games, both targets: a dropped level never plays.** Dropping `custom.txt` (and `custom-other-seed.txt`, `level2.txt`,
  `level3.txt`) on the title or in play shows "Not a level: custom.txt" for 2.97 s, and the game stays as it was. Each drop also logs a
  404 in the page. Natively the real XDND drop arrives (the right file name is shown) and fails the same way. All three games release
  the dropped files (`UnloadDroppedFiles`) before their `LoadFileTextAsync` of the dropped path has read them. In helix-ray that removes
  the dropped file's bytes from memory, so the load then misses, even natively, where the file exists on disk. Game 3 starts the load
  before unloading and still fails, because the load reads at a later frame. That is ordinary raylib code, so this looks like a trap in
  helix-ray's API as much as a fault in the games. Its doc comment says "A file loaded from one keeps what it loaded", which these
  programs can't meet with an async load.
- **Game 3: the field isn't what the spec asks for, and differs between targets.**
  - In the page, every rock and crystal lies in the top-left quarter of the field. At level 1 (2000x1200), rocks end by x 927 and y 615,
    and crystals stay within x 13 to 954 and y 16 to 597. Levels 2 and 3 are the same, and rock sides only reach about 100.
  - Natively, all the rocks are the same rectangle `[0, 604, 87, 140]` at level 1, 12 copies stacked at the left edge. Levels 2 and 3 do
    the same, with `[0, 1061, 87, 140]` at level 3, 30 copies. Crystals spread over the whole height but only half the width.
  - Page and native fields differ by up to 1650 px. Each target repeats its own field exactly from run to run.
  - Screenshots: `play/3/click-z0.5-native.png` (one grey block at the left edge) and `play/3/turned-zoom2-page.png` (the map shows
    everything in its top-left).
- **Game 3: the best score isn't saved at once.** After gathering 3 crystals mid-level, a page reload and a native SIGKILL followed by a
  restart both show "Best: 0". Games 1 and 2 show "Best: 3". A best reached at a level's end does survive a reload or restart (75).
- Minor, game 3: as a level ends, the HUD shows the next level's number over the old, emptied field for 1 or 2 frames, for example
  "Level: 2 | Crystals: 20 / 12". After level 3 it shows "Level: 4".

## Evidence per game

### Game 1

1. **Field.**
   - Level 1: 12 rocks and 20 crystals. Level 2: 20 and 25. Level 3: 30 and 30.
   - Every rock side is in 40..160.
   - Crystals are clear of rocks: the smallest gap from a crystal's edge to a rock is 21, 28 and 47 px for levels 1, 2 and 3.
   - Level 1's field was identical over three page runs (field1, field2 and the campaign) and three native runs. Levels 2 and 3, reached
     by play, were identical between page and native.
   - The field rect is `[0,0,2000,1200]`, colour 16,24,64. Crystals are SKYBLUE, 102,191,255, at radius 8.
2. **Speed**, from the camera target over frame arrival times while a key is held:
   - Page: right 298.8, left 300.4, up-right 300.8 and down-left 299.9 px/s. The step is 4.95 to 5.04 px at a 16.5 ms frame.
   - Page with frames throttled to about 18/s (`requestAnimationFrame` replaced): 301.5, 300.6, 297.9 and 299.7 px/s, with a 16.7 px step
     at 55 ms.
   - Native: 300.2, 300.0, 300.1 and 299.9 px/s.
   - Native with the process paused 40 ms of every 60 ms: 299.8, 309.9, 299.9 and 291.1 px/s. The step is 13.0 to 13.26 px at 44 ms, so
     about 297 to 300. The spread comes from the arrival-time jitter while paused.
3. **Click.**
   - The expected point was worked out with raylib's GetScreenToWorld2D from the recorded camera of the frame before the click.
   - At zoom 1, 0.5 and 2 unturned, at -45° and zoom 1, and at +90° with zoom 0.5 and 2, the cross was drawn exactly on the expected point
     (error 0) and the ship stopped exactly there (error 0), on both targets.
   - 12 wheel notches out clamp the zoom at 0.5, and 25 notches in clamp it at 2.
   - Turning measured -90.3 and +90.2 °/s on the page, and -90.2 and +89.5 °/s natively. R gives back zoom 1 and rotation 0.
   - An arrow key during a flight removes the cross and stops the flight.
4. **Map.** A scissor `[750,410,200,120]` at 960x540. It moves to `[1070,590,…]` at 1280x720 and `[490,290,…]` at 700x420, with the
   frame `DrawRectangleLinesEx` on the same rect, at every zoom and turn. A crystal dot drawn at x 749.7 is clipped by the scissor.
5. **Text and resize.**
   - Every DrawText is outside BeginMode2D. The HUD sits at (10,10), (10,34) and (10,58), and "Time" at 872 for 960 wide, unchanged at
     every zoom and turn.
   - After a resize to 1280x720, 700x420 and back, the camera offset is (640,360), (350,210) and (480,270), and "Time" moves to 1192 and
     612.
   - Screenshots `resize-*-page.png` and `resize-*-native.png` show the field filling the window with the ship centred.
6. **Drops** fail as described above. The not-a-level notice lasts 2.97 s on the title. In play the notice is shown and play goes on
   unchanged.
7. **Flow**, autopiloted over the recorded crystals:
   - Level 1 ends when the last crystal is gathered, with 41 s left, and "Loading..." gives level 2. Level 2 ends with 32 s left, and
     level 3 with 35 s left.
   - Then "You win! Score: 75" shows for 3.0 s, followed by the title with "Best: 75".
   - Idle in level 1: after 59.94 s, "Time! Score: 0" for 3.02 s, then the title.
   - "Best: 75" is there after a page reload and after a native restart. "Best: 3" after a mid-level reload or kill shows the best is
     saved at once.
   - Escape in play goes to the title. On the title, Escape starts a game (any key starts), and the program never quits.
8. **Collisions.**
   - Holding up-right against the left side of rock `[549,253,123,139]`, the ship stops 12.0 px from the side (its half size), slides up
     from y 367 to 257, then passes over the top. It never overlaps the rock.
   - At the left edge it stops at x 12.0 while y moves 212 px. At the top edge it stops at y 12.0 while x moves -148 px.
   - Native gives the same: gap 12.002, x 12.002, y 12.001.
9. **Gathering.** On every frame of the campaign, crystals gone equals score added: 19 + 24 + 29 events with no mismatch on both
   targets, and 75 in all. In the page, `AudioBufferSourceNode.start` was called 75 times over the 75 crystals.
10. No crash. Native runs exited 0 and wrote nothing on stderr.

### Game 2

1. **Field.** The same counts and positions as game 1 (it uses `GetRandomValue` the same way): sides 40..160, crystal gaps 21, 28 and
   47. It was identical over runs and across targets for levels 1, 2 and 3. Crystals are 0,255,255 and the field 10,20,60.
2. **Speed:**
   - Page: 298.6, 300.2, 300.5 and 299.4 px/s. Throttled: 300.4, 300.7, 300.5 and 299.3 px/s.
   - Native: 300.0, 299.9, 299.9 and 300.1 px/s.
   - Native paused: 309.5, 309.6, 291.2 and 300.0 px/s. The step is 13.45 px at 45.2 ms, which is 298.
3. **Click.**
   - The cross and the arrival were exact (error 0) in all six configurations on both targets.
   - The zoom clamps at 0.5 and 2. Turning measured ±90 °/s (-88.2 and +90.3 natively), and R resets.
   - A key cancels a flight.
4. **Map.** The scissor `[750,410,200,120]` follows the window at every zoom and turn. The frame is drawn 2 px outside it,
   `[748,408,204,124]`.
5. **Text and resize** behave as in game 1: camera offset (640,360) and (350,210), "Time" at 1192 and 612.
6. **Drops** fail as described. The notice lasts 2.97 s on the title and 2.49 s or more in play, with play unchanged.
7. **Flow.**
   - Levels 1 to 3 each end when every crystal is gathered, with 41, 31 and 33 s left. Then "You win! Score: 75" for 3.0 s, followed by
     the title with "Best: 75".
   - Time out: "Time! Score: 0" after 59.97 s, then the title 3.02 s later.
   - "Best: 75" after a reload and after a restart, and "Best: 3" after a mid-level reload or kill.
   - Escape in play goes to the title. Escape on the title does nothing, and the program never quits.
8. **Collisions.** It stops 16 px from the rock side (half its 32 px sprite) and slides from y 367 to 256. At the edges it stops at
   x 16 and y 16 and slides 212 and -148 px. Native is the same.
9. **Gathering.** 19 + 24 + 29 events with no mismatch. 75 sound starts in the page.
10. No crash. Native runs exited 0.

### Game 3

1. **Field: wrong.**
   - Counts are right: 12/20, 20/25 and 30/30 rocks/crystals. Sides are within 40..160 (page 40..~100, native always 87x140).
   - Crystals are clear: the smallest gap is 9, 5 and 5 px in the page, and 153, 225 and 300 px natively.
   - The page field is confined to the top-left quarter. All the native rocks are one repeated rectangle.
   - Page and native differ, by up to 937 px at level 1, 1430 px at level 2 and 1650 px at level 3.
   - Each target is identical between its own runs (level 1 over three runs each).
2. **Speed:**
   - Page: 299.1, 300.2, 299.5 and 299.5 px/s. Throttled: 300.3, 301.1, 300.9 and 298.9 px/s.
   - Native: 299.9, 300.0, 300.1 and 300.0 px/s.
   - Native paused: 290.5 to 309.7 px/s. The step is 12.75 to 12.99 px at 42.6 ms, which is about 300.
3. **Click.**
   - The ship arrives exactly on the expected point (error 0) in all six configurations on both targets.
   - The cross is drawn at integer coordinates, so it is up to 0.74 px off in the page and 1.10 px off natively when turned.
   - The zoom clamps at 0.5 and 2. Turning measured -89.7 and +90.0 °/s in the page, and -87.9 and +90.2 °/s natively. R resets, and a
     key cancels a flight.
4. **Map.** The scissor `[750,410,200,120]` follows the window. The frame `DrawRectangleLines` is on the same rect.
5. **Text and resize** behave as in game 1.
6. **Drops** fail as described. On the title the notice lasts 2.97 s. In play nothing is shown at all, and play goes on unchanged.
7. **Flow: wrong on "saved at once".**
   - The levels advance when every crystal is gathered, with 48, 42 and 47 s left in the page.
   - After level 3 the title shows "You win! Score: 75" as a banner under the name.
   - Time out: the title with "Time! Score: 0" after 59.95 s.
   - Best 75 after a reload and a restart. A mid-level reload or kill gives "Best: 0", because the best is only saved when a level ends.
   - Escape in play goes to the title. Escape on the title starts a game, and the program never quits.
   - My first campaign run in the page stalled at level 2 because of the stale HUD frames. The driver now waits for the level's field.
     That stalled run is the one that gave the time-out with "Time! Score: 20", the title after it, and Best 20 after a reload.
8. **Collisions.**
   - Page: it stops 17.04 px from the side of rock `[843,231,62,95]`, about 1 px short because a blocked step isn't taken. It slides from
     y 299 to 236. The edges stop it at 16 and it slides.
   - Native, with the only rock `[0,604,87,140]` approached from its right: it stops at a gap of 17.03 and slides from y 719 to 607.
     The edges stop it at 16.
9. **Gathering.** 19 + 24 + 29 events with no mismatch on both targets. 75 sound starts in the page.
10. No crash. Native runs exited 0.

## What couldn't be checked

- Sound natively, under the dummy audio driver.
- Comparing custom and custom-other-seed, because no dropped level plays.
- A gamepad. Touch was not tried.

## After the fix

I re-ran these checks on the builds in `grading/builds-fixed/N/`. They are the same games built against the fixed helix-ray, in which
`UnloadDroppedFiles` frees only the list. The drop files are the ones above. The page drops went through a DataTransfer on the canvas.
The native drops were real XDND drags on the private display.

The driver is the `drops2` scenario (`BUILDS=builds-fixed`). Its results are in `play/N/fixed-drops.{page,native}.{json,log}`, with
screenshots in `play/N/fixed-*.png`. In one run per game and target it does this:
1. On the title, it drops `custom.txt` and gathers every crystal to end the level.
2. It drops `custom-other-seed.txt`, then `custom.txt` again.
3. It drops `not-a-level.txt` on the title.
4. In level 1, it drops `custom.txt`.
5. In level 1, it drops `not-a-level.txt`.

| Item 6 after the fix | 1 page | 1 native | 2 page | 2 native | 3 page | 3 native |
|---|---|---|---|---|---|---|
| `custom.txt` on the title plays as "Custom", then the title | met | met | met | met | met¹ | met¹ |
| `custom.txt` in play plays as "Custom" | met | met | met | met | met | met |
| `not-a-level.txt` shows "Not a level: not-a-level.txt" ~3 s, game unchanged | met | met | met | met | met² | met² |
| custom ≠ custom-other-seed | met | met | met | met | met | **wrong** |
| custom twice the same; page = native | met | met | met | met | **wrong** (page ≠ native) | **wrong** (page ≠ native) |
| **Item 6 overall** | **met** | **met** | **met** | **met** | **wrong** | **wrong** |

1. Game 3 ends the custom level with "Time! Score: 8" on the title, although every crystal was gathered and the target of 5 was
   passed. The spec says the title comes back whatever the count, so the title is right but the message misleads.
2. Game 3 shows the notice only on the title, which is what the spec says. A not-a-level drop in play shows nothing, and play goes on
   unchanged.

With item 6 now met, games 1 and 2 are 10 met of 10 on both targets. Game 3 is 7 met and 3 wrong (items 1, 6 and 7) on both targets.

### Evidence

- **On the title.** In every game and target, `custom.txt` starts play on the frame its bytes arrive. The HUD shows "Level: Custom" and
  a 1500x1000 field with 10 rocks and 8 crystals. Rock sides are in 40..160 and every crystal is clear of the rocks.
  - Game 1: after the 8th crystal (with 18 to 19 s left) it goes straight to the title, which shows "Best: 8".
  - Game 2: "Level done! Score: 8" for 3.0 s, then the title.
  - Game 3: the title with the banner "Time! Score: 8".
- **In play.** Dropping `custom.txt` in level 1 replaces it with "Level: Custom", the same field as the custom dropped on the title.
- **Not a level.** "Not a level: not-a-level.txt" shows for 2.97 to 2.98 s.
  - On the title, nothing else changes.
  - In level 1, the level, the field (the same rocks) and all 20 crystals are kept, and the time runs on (60 → 56 in the page, 60 → 53
    natively).
  - Games 1 and 2 show the notice in play too. Game 3 shows it only on the title.
- **Fields:**
  - Games 1 and 2: custom and custom-other-seed differ. Custom dropped twice, and custom on the title against custom in play, are
    identical. Page and native are identical for both files, with a largest difference of 0.
  - Game 3 page: custom ≠ other-seed and custom twice is the same, but everything is in the top-left part of the field. For custom,
    rocks end by x 707 and y 519 in 1500x1000, and crystals stay within x 723 and y 245.
  - Game 3 native: all 10 rocks are `[0,490,87,140]` in both files. The crystals are the same too, so custom and custom-other-seed give
    **identical** fields. Seeds 777 and 778 make no difference.
  - Game 3 page ≠ native, by up to 716 px (custom) and 733 px (other seed).
- **Errors.** No crash. Native runs exited 0. The page's only console error was the start-up 404 for the best-score file. The drops
  logged no 404s.
