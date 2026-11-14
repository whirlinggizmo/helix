# Notes

## Compile errors
None. `haxe build.hxml` compiled `Main.hx` on the first try.

## Design
- `EnableTouchEmulation()` once at start, so the mouse works as a finger for the stick, the pause button and Reset.
- `EnableVirtualGamepad(0, ...)`: left stick floating, with an explicit touch zone of the left half; right stick disabled;
  one button for pause; `blockedBounds` holds Reset's rectangle.
- Ball reads `GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X/Y)` x 300 px/s x `GetFrameTime()`. A physical pad in slot 0 replaces
  the virtual one per the docs, so the same read covers both.
- Pause is a virtual button (`GAMEPAD_BUTTON_MIDDLE_RIGHT`) at (750, 50), radius 30, label "II", toggled on `IsGamepadButtonPressed`.
- Reset is `GuiButton` at the bottom middle (it straddles x = 400, the border of the stick's zone, hence `blockedBounds`).

## Guesses / unsure
- **Right stick disabled and the default touch zone.** The docs say the default zone is "the whole screen with one" stick, so I set
  the left stick's `touchZone` to the left half explicitly. Without it, a finger on the right half would also move the stick.
- **Which gamepad button for pause.** Nothing says which button suits a pause button. I chose `MIDDLE_RIGHT` (Start). Only the
  four face buttons have default positions, so I set `position` myself; the doc says a button without one isn't drawn.
- **Button shape.** The docs say the button is a ring with a radius; I assumed this gives the "round" button. The label "II" is
  plain text, so I'm not sure it renders as a pause glyph in the default font.
- **Button vs. stick zone.** The pause button is in the right half, so it doesn't overlap the left zone. Docs say buttons win anyway.
- **Reset and the mouse.** I assumed `GuiButton` reads the mouse, and that a free finger (including an emulated one) counts as the
  mouse, as the docs say. A finger on Reset is on a blocked bound, so it stays free and presses it. I didn't know if the finger
  landing on Reset *and* the blocked bounds both being needed was redundant: Reset lies half in the left zone, so I think it's needed.
- **Gating on `IsGamepadAvailable(0)`.** Before the first touch the virtual gamepad isn't plugged in, so I check availability
  before reading axes and buttons. The axes might read 0 anyway; unsure.
- **Where things draw.** The virtual gamepad draws at `EndDrawing`, above my "Paused" text and the Reset button. Nothing in the
  button is hidden by that, but the pause button could cover drawn content under it.
- **Hint.** `hintVisible` defaults true "on a device with touch". With emulation on a desktop I'm unsure whether it shows.
- **Emulation timing.** "Takes effect at the next press", before or after enabling; I call it before.
- `GuiButton` returns `Int` in this binding; I compared to `0`. The type came from the compile, not the docs.
- Both `Device` and `VirtualGamepad` are imported with `.*`; I only used `EnableTouchEmulation` from Device.

## API suggestions
- A one-call `EnableVirtualGamepad` preset such as "one left stick and one pause button" would remove the need to disable the right
  stick and set the touch zone by hand.
- State what a default-position-less button does besides "isn't drawn", and whether it's still read.
- Say what `IsGamepadAvailable(0)` is before the first touch, and whether axis reads are safe then (they probably return 0).
- Give `blockedBounds` an easy way to take a raygui bounds from the same Rectangle variable (it does follow the fields, which is good;
  state that the same instance can be shared).
- Name a pause/start button convention, e.g. a `VirtualButtonOptions` shape option (round vs. square) and a glyph.
- Put `EnableTouchEmulation` in `VirtualGamepad` or have `EnableVirtualGamepad` imply it on a desktop with a mouse; it's an easy
  step to forget, and it lives in a different module.
- `IsTouchEmulated`/`EnableTouchEmulation` are static stubs with empty bodies in `Device.hx` rather than forwarded to `RDevice`,
  unlike the rest of the file. Perhaps unfinished.
