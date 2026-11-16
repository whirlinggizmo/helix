# Grading Wardens

A reviewer grades each run against [the spec](spec.md), from screenshots of its native program and from its code, without the
entrant's notes until the grades are in. Each item is **met**, **wrong** (there, but not as the spec says), **missing**, or **can't
tell**, with a line saying what was seen.

## Screenshots taken
`../../tools/take_screenshots.py <run>` runs the run's native program on a private display of 1280 x 720 (so going fullscreen keeps that size), with
`--enemies=10 --seed=1`, and saves in `<run>/grading/`:
- `title.png`, 4 seconds after start.
- With `--click X,Y` (the Play button, found on `title.png`): `play.png` 3 seconds after the click, `move.png` while D is held for
  1.5 seconds, `pause.png` a second after Escape, then after Escape again `play-later.png` 8 seconds on and `late.png` 30 more.
- `crowd.png`, from a second run with `--enemies=200`, 20 seconds after the click.

The renderer is Mesa's software one, so the shots are for what is drawn, never for speed.

## Items
| # | item | how it's judged |
|---|---|---|
| 1 | Window 1280 x 720, resizable; the arena stays framed and the HUD at the edges when resized | the code |
| 2 | Title: "Wardens", the best time, Play and Quit, the warden idling and turning slowly | `title.png` |
| 3 | Play goes fullscreen; Quit ends the game | the code |
| 4 | Pause on Escape or P: Resume, Restart, Title and a volume slider, 0 to 100%, saved with the best time | `pause.png`; the code for the keys and the save |
| 5 | Game over: time survived, level, enemies defeated, a new best called out, Restart and Title | the code; `crowd.png` or `late.png` when she has died |
| 6 | Ground 40 x 40 with a grid, low walls nothing passes | the play shots; the code for the walls |
| 7 | Camera at about 55 degrees from 14 meters, following smoothly; a sun and a fill | the play shots; the code |
| 8 | The warden from the four Adventurer parts on one skeleton, animated together | the play shots; the code |
| 9 | Moving: WASD, arrows, left stick; 5 m/s whatever the frame rate, no faster diagonally; faces where she moves | `move.png`; the code |
| 10 | Touch stick: appears where a finger lands on the play area, moves her as the left stick does, stops on lift | the code |
| 11 | Touch buttons: pause at the top right, switch at the bottom right once she has both weapons; neither moves her; menus tapped | the code |
| 12 | Animations: Idle, Run, the attack, HitRecieve, Death | the shots; the code |
| 13 | The attack from the waist up while moving, the legs running on | the code; `move.png` |
| 14 | Changes between animations blend over 0.2 seconds | the code |
| 15 | Materials as authored, metallic and roughness honoured | the play shots; the code |
| 16 | The weapon in her right hand, following it through every animation | the play shots; the code |
| 17 | Sword: every 0.8 s, 2 m, a 120 degree arc in front, 10 damage | the code |
| 18 | Gun: every 0.5 s, nearest within 12 m in a 90 degree arc, a glowing sphere at 20 m/s, first hit, 6 damage | the code |
| 19 | Both weapons: the one picked last held, Q or a shoulder button switches | the code |
| 20 | Health 100, a bar above her head facing the camera | the play shots |
| 21 | Enemies: the other outfits' parts, tinted red, running | the play shots |
| 22 | Spawning at the edge, out of view where they can; 2.5 m/s at her; pushing apart | the code; `crowd.png` |
| 23 | Contact 8 damage a second; enemy health 20, +5 a minute; HitRecieve and Death; sinking away | the code |
| 24 | Waves: 5 at the start, the most alive +10 every 30 seconds, up to 200 | the code |
| 25 | Gems: dropped on a kill, small, green, spinning; drawn to her within 3 m; 1 experience | the shots; the code |
| 26 | Death bursts: 40 red sparks, flying and falling, drawn added, fading over 0.6 s; up to 2,000 | the shots; the code |
| 27 | Target ring: thin, as wide as the sword's reach, pulsing once a second, from the game's own shader on ground coordinates | the play shots; the code |
| 28 | Spawn warnings: a red circle filling from the middle over 1 second, by the game's own shader with the fill passed in | the code; the shots |
| 29 | Hit flash: white for 0.1 s, still animating, by the game's own shader on the animated, lit enemy | the code |
| 30 | Experience bar along the top; level 2 at 5 gems, each level 5 more than the last | the play shots; the code |
| 31 | Level up: play stops, three cards with name, icon and text; picked by click, tap, arrows and Enter, or gamepad | the code; a shot when one shows |
| 32 | The cards: Sharper blade, Quick hands, Long reach, Gun once, More bullets, as the spec gives them | the code |
| 33 | Gear: a random part of an outfit she isn't wearing, swapped at once without a jump, its bonus | the code |
| 34 | Cards and buttons drawn from `panel.png` and `button.png` as nine-slices, corners unstretched | `title.png`, `pause.png` |
| 35 | HUD: experience bar and level, time survived, enemies defeated and frames a second, gear and weapon icons; none turns with the camera | the play shots |
| 36 | Sound: the five effects, music looping and ducked to half when paused, all following the volume | the code |
| 37 | Run options `--enemies=N` and `--seed=N` from the command line; the same seed plays the same enemies | the runs; the code |

A run's score is the count of items met. Speed (no stutter at 200 enemies) is not graded here: it is timed apart, on the GPU.
