# Library trial: touch emulation (2026-11-14)

Whether agents use touch emulation correctly from its doc comments alone, before any of it was written: `EnableTouchEmulation`,
`DisableTouchEmulation` and `IsTouchEmulated` in `extras.Device`, the left mouse button working as one finger, as Godot's
`emulate_touch_from_mouse` and Unity's `TouchSimulation` have it. Nine fresh Sonnet agents in three rounds of three, each a `claude -p`
in a directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), were given
[the task](task.md): a ball moved by an on-screen stick, an on-screen pause button and a raygui Reset button, worked by the mouse at a
desk. [The brief](module/brief.md) pointed at Device's and VirtualGamepad's doc comments in `module/api/`, the new calls' bodies empty.
The runs compiled their programs, natively, and didn't run them. Each run's program and notes are in the folder named for it
(`touch.001` to `.003` for round one, `touch2.*` and `touch3.*` after).

| round | cost | turns | time |
|---|---|---|---|
| one | $0.174, $0.182, $0.187 | 6, 7, 7 | 33, 37, 37 s |
| two | $0.184, $0.176, $0.181 | 6, 6, 6 | 38, 32, 36 s |
| three | $0.175, $0.172, $0.180 | 6, 5, 6 | 33, 31, 35 s |

All nine compiled, and all nine enabled touch emulation, worked the stick and the pause button through `VirtualGamepad`, and kept a
finger on Reset free with `blockedBounds`.

## What it found, and what changed

| round | finding | change |
|---|---|---|
| one | Every run enabled touch emulation only without touch (`if (!IsTouchAvailable())`), unsure what a device with touch does with it | a touch and the left mouse button both work as fingers on a device with touch |
| one | Whether touch emulation is enabled before or after `EnableVirtualGamepad` | it takes effect at the next press, before or after |
| one | VirtualGamepad's sentence on the mouse read as garbled | what plugs the virtual gamepad in, as one paragraph: a touch, a press of the left mouse button with touch emulation, a tilt stick once the tilt is on |
| two | Every run still kept the guard, from the task's "a desktop with no touch screen" | the task's line became "with a mouse at a desk" |
| two | `IsVirtualGamepadVisible` said "on a device with touch", the class doc "or with touch emulation" | both say "or with touch emulation" |
| three | `hintVisible` said "on a device with touch" | it says "or with touch emulation" too |

In round three all three runs enabled touch emulation unconditionally and read the order as the docs give it.

Every run set the left stick's touch zone by hand, as one stick alone takes the whole window by default, and read the pause button
through a gamepad button (`GAMEPAD_BUTTON_MIDDLE_RIGHT`), finding no plain on-screen button. Both are VirtualGamepad's as it was
before this trial.
