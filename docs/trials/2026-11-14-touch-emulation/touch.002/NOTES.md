# NOTES

## Compile errors
1. `Main.hx:52 Unterminated regular expression`: I wrote `~/` (not Haxe) for integer division. Changed to `/`.
2. `Float should be Int` for `DrawText`'s posX: `400 - MeasureText(..)/2` is a Float in Haxe. Wrapped in `Std.int`.

Compiles cleanly now (`haxe build.hxml`). Not run.

## Guesses / uncertainties
- **Touch emulation**: I call `EnableTouchEmulation()` only when `!IsTouchAvailable()`. Guessed this is the intended "at a desk"
  switch. Unsure whether it should be called unconditionally (a laptop with touch and a mouse would then also get mouse-as-finger).
  Also unclear whether it must be called before or after `EnableVirtualGamepad`; I call it before.
- **Pause button**: no "pause" gamepad button exists, so I used `GAMEPAD_BUTTON_MIDDLE_RIGHT` (Start) as a virtual button at the top
  right (center (760, 40), radius 28, label "II"), and read it with `IsGamepadButtonPressed(0, ...)`. Guess: a button's `position` is its
  center in screen pixels (doc says so) and the button is drawn at `EndDrawing`, so over my own "Paused" text. Its look is a ring, not
  filled; "round" is satisfied only by the ring. A physical gamepad's Start also toggles pause (a side effect).
- **Reset vs. stick**: used `blockedBounds: [resetBounds]` so a finger on Reset stays a free finger (counts as mouse, so `GuiButton`
  sees it). The doc says free fingers count as the mouse; I relied on that for raygui. Unverified: whether `GuiButton` fires on the
  finger's press/release the same way as a real mouse. Also, Reset (x 350-450) overlaps the left stick's zone (0-400), hence the block.
  The right half of Reset is outside the left zone anyway.
- **Stick zone**: I set the left stick's `touchZone` to the left half explicitly, though with `right` disabled the doc's default is
  the *whole screen*, which would break "left half only". Explicit zone avoids that. `basePlacement` floating is also explicit.
- **Slot 0 / physical gamepad**: ball reads `GetGamepadAxisMovement(0, LEFT_X/Y)`, which is the virtual stick or a physical one, per
  the docs (physical replaces virtual in slot 0). I assumed the axis is already dead-zoned and normalized to a unit circle (so 300 px/s
  max); the doc says it rises to 1 at the radius "in any direction", but I don't clamp the vector length for a physical pad's diagonal
  (could be up to 1.41 * 300).
- **Y axis sign**: assumed +Y is down (as raylib's gamepad axes, and the doc's "down it as y").
- **Drawing**: ball isn't clamped to the screen. Hint visibility is left default (shown until first touch).
- `GetFrameTime()` for speed; the doc doesn't need it.

## API changes I'd suggest
- Name the buttons for common uses (e.g. a documented "pause/start" recommendation), and say in `VirtualButtonOptions` whether a
  button is filled/ring-shaped by default.
- State plainly in `EnableTouchEmulation` whether it should be called before `EnableVirtualGamepad`, and whether it is needed at
  all given that "a mouse click leaves the virtual gamepad unplugged, but with touch emulation..." (that sentence in
  VirtualGamepad's class doc is garbled).
- Make the default touch zone with one stick disabled less surprising (whole screen), or document it next to `left`.
- Have `EnableVirtualGamepad` offer an option to mark raygui/own-UI rectangles as buttons vs. blocked areas; `blockedBounds` works but
  its link to raygui isn't obvious. Say whether `blockedBounds` rects are copied (doc says they follow field changes, so references).
- `EnableTouchEmulation` / `IsTouchEmulated` are no-op stubs in Device.hx; a note which are unbuilt would help.
