# Grading Lanternholm

A reviewer grades each run against [the spec](spec.md), from screenshots the harness takes and from the program's code, without the
entrant's notes until the grades are in. Each item is **met**, **wrong** (there, but not as the spec says), **missing**, or **can't
tell**, with a line saying what was seen.

## Screenshots taken
Each at 1280 x 720, 120 frames after start:
- `--hour=0.27` (dawn), `--hour=0.5` (noon), `--hour=0.73` (dusk) and `--hour=0.95` (night), the default camera, beside
  [reference/](reference).
- `--hour=0.5 --cam=1.2,1.6,3.2 --look=0,0.4,0`, close up, beside `reference/close.png`.
- `--hour=0.5 --cam=0.5,-6,6 --look=0,-0.8,0`, from below.
- Night, close up: `--hour=0.95 --cam=1.2,1.6,3.2 --look=0,0.4,0`.

## Items
| # | item | how it's judged |
|---|---|---|
| 1 | Window, background, camera start | the default view against the references |
| 2 | Orbit and zoom, limits, easing; touch: drag, tap, pinch | the code; a scripted drag where the harness has input |
| 3 | The island floats | two shots a second apart differ by the bob |
| 4 | Outline and top, the hill | the views |
| 5 | Underside, veins | from below |
| 6 | Crystals, their glow | from below, day and night |
| 7 | Pond, its look | close up |
| 8 | Stream and waterfall, mist | noon and close up |
| 9 | Path | close up |
| 10 | Hut, its parts | close up |
| 11 | Chimney smoke, puffs rising and fading | close up, shots on successive frames |
| 12 | Dock, boat | close up |
| 13 | Boulders | the views |
| 14 | Time of day eases from the slider | the code |
| 15 | Sun and moon, their paths | dawn, noon, dusk and night |
| 16 | Sky: day, dawn and dusk band, night with stars | the four times |
| 17 | Light changes with the time | the four times |
| 18 | Shadows from the sun and the moon | noon and close up |
| 19 | Glow at night | night |
| 20 | Grass swaying | close up; the code for the sway |
| 21 | Flowers, closed at night | close up, day and night |
| 22 | Mushrooms, their glow | close up, day and night |
| 23 | Trees, the six kinds, swaying | close up; the code for the kinds |
| 24 | Dust | the views |
| 25 | Fireflies at night | night close up |
| 26 | Nubbins hop, sleep at night | shots on successive frames; the code |
| 27 | The hut at night | night close up |
| 28 | Controls: title, toolbar, panel, hint, keys 1 to 3, H | the views; the code for the keys |
| 29 | Time tool and its words | the code |
| 30 | Plant tool: growth, refusals, the limit | the code; a scripted tap where the harness has input |
| 31 | Poke tool: chirp and hop by strength | the code |
| 32 | Hints fade once used | the code |
| 33 | Sound: ambience, chirp, plant, thud, mute | the code |
| 34 | Options: hour, cam, look, frames, shots | the runs themselves |
| 35 | Smooth at 60 frames a second | the frame stats, timed |

A run's score is the count of items met, and the wrong and missing items are listed by what an engine would have given for them.
