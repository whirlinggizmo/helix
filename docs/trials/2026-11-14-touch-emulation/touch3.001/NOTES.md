# NOTES

## Compile errors
1. `Main.hx:58: Float should be Int` (`DrawText` posX): `W / 2 - MeasureText(...) / 2` is a Float in Haxe. Wrapped in `Std.int(...)`.
That was the only error; `haxe build.hxml` now compiles cleanly.

## Guesses / unsure points
- **Pause button as a virtual button.** The task wants a round on-screen button top right. I used a `VirtualButtonOptions` read as
  `GAMEPAD_BUTTON_MIDDLE_RIGHT`, with `position` at the top right, radius 28, label "II", and read it with `IsGamepadButtonPressed(0, ...)`.
  The docs don't say whether a non-face button with a `position` is drawn as a ring (they say only that one *without* a position isn't),
  nor which gamepad button suits "pause"; I chose MIDDLE_RIGHT (Start) by convention. The doc says `position` is the center, which I assumed.
- **Pause with a physical gamepad.** Buttons are hidden while a physical gamepad is in the slot, but I assume they still read (like
  `visible:false`). Not stated for the physical-replaces-virtual case; physical Start would pause anyway, since the same call reads it.
- **Left half only.** With the right stick `enabled:false`, the default touch zone becomes the whole screen, so I set the left stick's
  `touchZone` to the left half explicitly. I assumed a disabled stick doesn't capture fingers, so the right half does nothing.
- **Floating base.** The default `basePlacement` is FLOATING, which matches "appears where a finger lands". I assumed the stick is
  drawn only while held (the hint is shown before the first touch, which I left on).
- **Reset button vs stick.** I passed the Reset rectangle in `blockedBounds` so a finger there stays free and counts as the mouse for
  `GuiButton`. I assumed raygui reads the mouse position/press that touch emulation produces for free fingers. The Reset button is at the
  bottom middle, which lies in the left half's touch zone (x 340-460 crosses 400), so the blocking matters. I used the rectangle object
  directly because the doc says bounds follow field changes.
- **Drawing order.** The virtual gamepad is drawn at `EndDrawing` over everything, so the pause button and stick appear above my
  "Paused" text and the raygui button. Where the virtual pause ring sits relative to the screen corner (margin 10 px) is my choice.
- **Touch emulation.** I call `EnableTouchEmulation()` unconditionally, including on phones; the doc says touch and mouse both work as
  fingers there. "Takes effect at the next press" — I assumed that is fine before `EnableVirtualGamepad`. A mouse press also plugs the
  gamepad in, so slot 0 reads from the first press.
- Stick axes: assumed Y positive downward, matching screen coordinates, so I add `ay * SPEED * dt` directly. Diagonals reach magnitude
  up to 1 per the doc ("evenly to 1 at the radius in any direction"), so no normalising.
- `GuiButton` returns Int here, so I compare `!= 0`.
- The ball isn't clamped to the screen; the task doesn't ask.

## API changes I'd suggest
- A `VirtualButtonOptions` shape option (round vs. ring is implied; say so) and a `GAMEPAD_BUTTON` default "Pause" label/position preset.
- Say whether a disabled stick still captures fingers and what the default touch zone is then (only implied by "with one").
- Let `blockedBounds` accept a raygui-style request ("block this widget") or document that raygui sees blocked fingers as the mouse.
- Document the gamepad-button read when a physical gamepad replaces the virtual one, and whether hidden buttons still read.
- An `IsTouchEmulated`-style note on whether `IsVirtualGamepadVisible` is true at a desk before the first press.
- Make `GetVirtualStickBase`/`Knob` and `IsVirtualStickHeld` docs state they're valid before the gamepad is plugged in.
