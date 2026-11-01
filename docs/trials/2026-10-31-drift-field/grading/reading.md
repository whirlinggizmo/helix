# Drift Field: grading by reading

Each game is one file, `agent-N/Main.hx`; a cell's `:n` is a line in it. No game was built or run. helix-ray's behavior was read
from `helix/ray/src/helix/ray/` where it decides an item (cited as `RCore.hx:n`, `MemoryFiles.hx:n` and so on).

Grades: **met**, **wrong**, **missing**, **can't tell** (by reading).

| # | Item | agent-1 | agent-2 | agent-3 |
|---|------|---------|---------|---------|
| W1 | Window 960 x 540 | met :97 | met :65 | met :354 |
| W2 | Resizable | met :96 | met :64 | met :353 |
| W3 | View fills the window on resize | met :466, :484 | met :485, :495 | met :275, :420 |
| W4 | Ship kept at the center on resize | met :465-466 | met :485 | met :275 |
| W5 | Text and map keep to the window's edges | met :539, :471-474 | met :548-549, :572 | met :297-298, :326 |
| T1 | "Drift Field" centered | met :488 | met :502 | met :332 |
| T2 | "Press any key, click or tap to start" centered | met :489 | met :503 | met :335 |
| T3 | "Best: N" under it | met :490 | met :504 | met :336 |
| T4 | "Drop a level file to play it" under that | met :491 | met :505 | met :337 |
| T5 | Any key starts at level 1 | met :138, :119-120, :162 | met :259-261, :318-320 | met :343, :400-407 |
| T6 | Click or tap starts | met :140-142 | met :262, :264 | met :345 (a touch is the left button, Raylib.hx:1528) |
| T7 | Gamepad button starts | met :144-149 | met :266 | met :347 |
| L1 | File name built from the number | met :169 | met :131-133 | met :129 |
| L2 | Reads the seven `key=value` keys | met :17-46 | met :98-129 | met :44-60 |
| L3 | Level not started before its file arrives | met :167-177 | met :138-146 | met :400-409, :411 |
| L4 | Missing file: "You win! Score: N", then the title | met :178-181, :126-129 | met :147-155, :323-326 | met :149-152, :333-334 (a banner on the title) |
| F1 | Field made from the seed, the same on the page and natively | met :240-249 | met :189-196 | **wrong** :38-42 |
| F2 | Rocks at random places, sides 40 to 160 | met :245-248 | met :192-195 | met :81-83 |
| F3 | Crystals at random places clear of the rocks | met :253-270 | met :200-217 | met :87-93 |
| F4 | Rocks gray rectangles, drawn as shapes | met :514 | met :529 | met :279 |
| F5 | Crystals cyan circles of radius 8 | **wrong** :516 | met :523, :531 | **wrong** :282 |
| F6 | Field's edge a white outline | met :517 | met :532 | met :283 |
| F7 | Black outside the field, dark blue inside | met :484, :512 | met :495, :527 | met :420, :277 |
| S1 | Ship is `assets/player.png`, safe before it arrives | met :102, :523-527 | met :71-75, :538-542 | met :358-361, :400, :288 (see notes) |
| S2 | Starts at the field's center, moved off any rock | met :273-291 | met :229-254 | met :95-116 |
| S3 | Arrow keys and WASD move it | met :367-374 | met :355-362 | met :181-188 |
| S4 | Gamepad left stick moves it | met :380-396 | met :363-372 | met :189-196 (pad 0 only) |
| S5 | 300 world px/s whatever the frame rate | met :401, :111-113 | met :396, :84 | met :225, :372-374 |
| S6 | No faster on a diagonal, keys and stick | met :375-378, :387-390 | met :373-377 | met :218-224 |
| S7 | Click or tap on the field flies it there at the same speed | met :403-424 | met :380-407 | **wrong** :212-217 |
| S8 | Flight ends on arrival or a key/stick move | met :400, :415-417 | met :395, :402-404 | met :219-220, :231-235 |
| S9 | Small cross at the point until arrival | met :518-522 | met :533-537 | met :284-287 |
| S10 | Rocks stop it; it slides along them | met :309-343 | can't tell :445-476, :84 | met :165-176 |
| S11 | Field's edge stops it; it slides | met :299 | met :450, :464 | met :169, :173 |
| S12 | Touching a crystal gathers it: +1, gone for the level | met :430-436 | met :411-417 | met :250-260 |
| S13 | Plays `assets/coin.wav`, safe before it arrives | met :103, :437-438 | met :76, :418-419 | met :362-365, :400, :261 (see notes) |
| V1 | View follows the ship | met :465 | met :485 | met :211, :275 |
| V2 | Wheel zooms, clamped 0.5 to 2 | met :352-354 | met :340-342 | met :198-200 |
| V3 | Q and E turn 90 degrees a second | met :355-358 | met :343-346 | met :201-204 |
| V4 | R resets zoom to 1 and turn to 0 | met :359-362 | met :347-350 | met :205-208 |
| V5 | Click while zoomed or turned goes under the pointer (the view's camera) | met :363, :404 | met :386, :484-486 | met :211-213 |
| M1 | 200 x 120 at the bottom right | met :471-474 | met :546-549 | met :295-298 |
| M2 | Framed | met :557 | met :564 | met :312 |
| M3 | Whole field, ship a dot | met :544-555 | met :550-562 | met :300-310 |
| M4 | Nothing spills outside the frame | met :548-556 | met :556-563 | met :303-311 |
| X1 | Score (total across levels) at top left | met :535, :161 | met :568, :319 | met :322, :405 |
| X2 | Level number | met :536 | met :569 | met :323 |
| X3 | Crystals gathered and target | met :537 | met :570 | met :324 |
| X4 | Time left at top right | met :538-539 | met :571-572 | met :325-326 |
| X5 | Text doesn't turn or zoom (drawn outside camera mode) | met :528-540 | met :543, :566-572 | met :289, :426 |
| E1 | Level ends when the time runs out | met :444-448 | met :425-429 | met :265-268 |
| E2 | Level ends when every crystal is gathered | met :445 | met :426 | met :249-266 |
| E3 | Count reached the target: next level loaded | met :458-459 | met :437-438 | met :148-155 |
| E4 | Otherwise "Time! Score: N", then the title | met :460-461, :126-129 | met :439-440, :323-326 | met :144-145, :333-334 |
| E5 | New best saved at once | met :220-225, :439 | met :170-175, :420 | met :158-163, :267 |
| E6 | Best loaded at start | met :104-108 | met :77-81 | met :366-370 |
| D1 | Valid dropped file played at once, from the title | **wrong** :196-202 | **wrong** :280-287 | **wrong** :377-397 |
| D2 | Valid dropped file played at once, in play | **wrong** :196-202 | **wrong** :280-287 | **wrong** :377-397 |
| D3 | Its number shown as "Custom" | met :534 (unreachable, D1) | met :567 (unreachable, D1) | met :321 (unreachable, D1) |
| D4 | When it ends, the title whatever the count | met :454-456 | met :435-436, :323-326 | met :144-145 |
| D5 | A non-level leaves the game as it was | met :203-206 | met :288-290 | met :383-386 |
| D6 | "Not a number" is detected | met :29 | met :110 | **wrong** :53, :56 |
| D7 | "Not a level: <name>" shown for 3 seconds | met :215-218, :499-500 | met :299-302, :514-515 | met :385-386, :338-339 |
| Q1 | Escape returns to the title from play | met :346-348 | met :333-336 | met :412-415 |
| Q2 | Escape doesn't close the program | met :99 | met :68 | met :356 |

Counts (65 items):

| | met | wrong | missing | can't tell |
|---|---|---|---|---|
| agent-1 | 62 | 3 | 0 | 0 |
| agent-2 | 62 | 2 | 0 | 1 |
| agent-3 | 59 | 6 | 0 | 0 |

## The drop fault all three share (D1, D2)

`UnloadDroppedFiles` removes the dropped files' bytes from memory at once (`RCore.hx:1554-1559`, `Runtime.memory.remove`). A read of
a dropped path happens later: `LoadFileTextAsync` waits for the saves "at a later poll" (`Runtime.hx:296-302`), then
`Assets.load` asks `MemoryFiles.read`, which queues the read and looks the bytes up only when it is polled (`MemoryFiles.hx:69-81`,
`:150-155`). agent-1 (:196-202) and agent-2 (:280-287) unload before they even ask for the text; agent-3 (:382, :397) asks and
unloads in the same frame. In each the bytes are gone when the read runs, the other sources don't have `helix-ray-dropped/<n>/<name>`,
and the failed callback shows "Not a level: <name>". So every drop, valid or not, is refused, and "Custom" (D3) is never reached.

In raylib the same code works: the file stays on disk after `UnloadDroppedFiles`. This is a trap in helix-ray as much as in the
games: its doc, "A file loaded from one keeps what it loaded" (`Raylib.hx`, `UnloadDroppedFiles`), doesn't say the load must have
answered first.

## agent-1

- **F5, crystal color:** `SKYBLUE` (102, 191, 255) is a light blue, not cyan (:516, the map's :554 too).
- **D1, D2:** see above; the unload is at :198, before the read at :202.

Notes, not faults: the collision box is 24 x 24 (:59, :295) while the sprite is drawn 32 x 32 (:525), its opaque part 28 x 28, so
the sprite overlaps a rock by 2 px on a side. A flight also ends when the ship is stuck on a rock (:422-423), which the spec doesn't
ask for but doesn't forbid. A dropped level from the title zeroes the score; in play it carries on (:209-210).

## agent-2

- **D1, D2:** see above; the unload is at :282, before the read at :287.
- **S10, can't tell:** the frame time isn't clamped (:84, and `GetFrameTime` is the raw real delta, `RCore.hx:436-438`), and
  `moveShip` checks only where a step lands (:449-475). A frame longer than about 0.24 s (300 px/s times it is more than a
  40 px rock plus the 32 px ship) can carry the ship through a rock, e.g. a page tab hidden and shown again, or a native window
  dragged.

Notes, not faults: `GetGamepadButtonPressed` returns a button *held*, not just pressed (`Raylib.hx:1789-1794`), so a button still held
when a message gives way to the title starts a game at once (:266). A dropped level always zeroes the score (:293). A custom level
ends with a 3 s message before the title (:436), where agent-1 goes straight to the title. A malformed numbered level counts as a win
(:143-144).

## agent-3

- **F1, determinism:** the generator is an LCG in Int arithmetic, `rngState * 1103515245 + 12345 & 0x7fffffff` (:40). hxcpp wraps
  the product at 32 bits; the JS build emits the same expression (`web/app.js`), where the product of a 31-bit state and
  1103515245 reaches 2^61, beyond a double's 53 exact bits, so its low bits are rounded away before `&`. The states part after a few
  steps (the seed's own first product is exact, the ones after aren't), and the page's field differs from the native one. The
  comment "same on every target" (:39) is wrong.
- **F5, crystal color:** `SKYBLUE` (:282), as agent-1; the map draws them as 2 px squares (:309).
- **S7, click on the field:** any click is clamped into the field (:214-215) rather than ignored off it, so a click in the black
  outside sends the ship to the nearest edge point; a click on the map sends it to whatever world point lies under the map.
- **D1, D2:** see above; the read is asked at :382 and the bytes dropped at :397, in the same frame.
- **D6, "not a number":** `Std.parseFloat` reads a leading number and ignores the rest (:53), so `rocks=12abc` or `seconds=60s`
  is taken as a level; only a value with no leading number (NaN, :56) is refused.

Notes, not faults today: the texture and sound are never null-checked (:97, :166, :261, :288, :430-431); the guard is the title's
gate, `ready >= 2` (:400). The drop path (:388-390) skips that gate, so a level dropped before `player.png` arrives would crash at
:97, which is unreachable only because drops fail (D1). Neither async load has a `failed` callback (:358-365), so if either file
can't be loaded the title can never start. A missing `level1.txt` does nothing at all (:402), not "You win". "You win" and "Time!"
show as a banner on the title (:333-334), not before it. A dropped level started while the next numbered level is loading is
replaced by it when that answer arrives, still labeled "Custom" (:149-155, :388). When blocked on an axis the ship doesn't move on
it (:170-175), leaving a gap of up to a step (5 px at 60 fps, 30 px at the 0.1 s clamp). The "Not a level" notice is drawn only on
the title (:338-339), so dropped in play it runs out unseen.

## Play tests worth running

1. Drop `grading/custom.txt` (a valid level) on the title and again in play, in Chromium and natively. By reading, all three show
   "Not a level: custom.txt" and keep their state; a fix should start a "Custom" level.
2. Drop `grading/not-a-level.txt` (`width=wide`, `target` missing), and a file whose value is `rocks=12abc`: all three should
   refuse the first; agent-3 will accept the second.
3. Level 1's field in Chromium against native, e.g. rock rectangles logged or a screenshot at a fixed camera. agent-3's should
   differ; agent-1's and agent-2's should match.
4. agent-2: hold a key into a rock, hide the page's tab for a few seconds (or drag the native window), come back: does the ship
   pass through?
5. Zoom to 2, turn about 45 degrees, click a crystal: the cross and the ship's goal should be under the pointer. agent-3: click
   outside the field and on the map.
6. Resize to small and large windows: ship centered, time at the right edge, map at the bottom right and clipped.
7. Escape in play natively: back to the title, the program still open.
8. Gather a few crystals, reload the page and restart natively: "Best" holds the new score. agent-3: quit mid-level (it saves only
   at a level's end or on Escape).
9. Finish level 3 above target: "You win! Score: N" then the title. Let a level's time run out below target: "Time! Score: N".
10. Keys on a diagonal and a stick pushed fully diagonal: 300 px/s, measured from logged positions; also at a low frame rate.
11. Gamepad button and touch tap start a game; agent-2: hold a button through a "Time!" message.
12. agent-3: rename `coin.wav` and see the title never start.
