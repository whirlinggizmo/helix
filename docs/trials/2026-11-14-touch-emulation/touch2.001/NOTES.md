# NOTES

## Compile errors
1. `Main.hx:58: Float should be Int` for `DrawText`'s `posX`. `W / 2` and `MeasureText(..)/2` are Float in Haxe. I wrapped them in `Std.int`.
That was the only error. Nothing in the extras gave one.

## Guesses / unsure
- **Touch emulation only without touch.** I call `EnableTouchEmulation()` when `!IsTouchAvailable()`. The docs say that on a device
  with touch both work as fingers, so calling it always might be fine. I wasn't sure whether a laptop with touch and a mouse should
  get it, so I left it to the "desktop with no touch screen" case.
- **Pause button as a virtual gamepad button.** I used `VirtualButtonOptions` with `GAMEPAD_BUTTON_MIDDLE_RIGHT`, read with
  `IsGamepadButtonPressed(0, ...)`. The doc says nothing about which gamepad button suits a pause button, so I guessed Start. The
  label is "II" (the doc only says the default is "" for non-face buttons). It is round, drawn at the top right (800-50, 50), radius 30.
  I assume it is drawn at `EndDrawing`, over my frame, in that position. Its pressed state follows a finger that lands on it, and
  "pressed" (not "down") should fire once per tap.
- **Physical gamepad.** A physical gamepad in slot 0 replaces the virtual gamepad, so while one is plugged in the on-screen pause
  button is hidden and pause can't be toggled from the screen (a physical button isn't wired up). Unsure whether the physical
  gamepad's left stick reads the same way; I assumed `GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X/Y)` does for both.
- **`IsGamepadAvailable(0)` check.** The doc says the virtual gamepad is plugged in by the first touch and mouse clicks alone don't
  plug it in, except with touch emulation. I gate on `IsGamepadAvailable` only to be safe; the axis would be 0 anyway.
- **Left stick touch zone.** With the right stick disabled, the default zone is the whole screen, so I set the left stick's
  `touchZone` to the left half (0,0,400,450). The zone follows the rectangle's fields, so a window resize wouldn't update my fixed numbers.
- **Reset and blockedBounds.** I put the Reset rectangle in `blockedBounds` so a finger there stays free and the free finger counts as
  the mouse for `GuiButton`. I assume a free finger on a phone really presses a raygui button (the docs say a free finger counts as the
  mouse). I'm not sure whether a finger that lands on Reset and slides out then holds the stick (it shouldn't: it stays free).
- **Where the virtual gamepad draws.** It is drawn at `EndDrawing`, over everything, so it covers the raygui Reset button and
  "Paused" if they overlap. They don't overlap with my layout. I guessed that the stick hint is drawn in the lower left of the left half.
- **Stick placement.** `VIRTUAL_STICK_BASE_FLOATING` is the default, which is the "appears where a finger lands" behavior.
- **Speed.** Axis is -1..1 with a dead zone, so 300 px/s is the max. Diagonals aren't normalised by me; I assume the stick reads
  within a unit circle ("rising evenly to 1 at the radius in any direction"). I didn't clamp the ball to the screen.
- **Paused and the stick.** While paused I don't move the ball but the stick still reads. Reset still works while paused.

## API changes I'd suggest
- `EnableVirtualGamepad` options could take a plain-number `Rectangle`/`Vector2` literal; now `new Rectangle(..)` is needed (I assumed
  the constructors take x, y, w, h and x, y; it compiled).
- A named constant or helper for a pause/start button (like `VIRTUAL_BUTTON_...`), and a default round button without a gamepad
  button meaning.
- Say if `IsGamepadButtonPressed` fires for a button tapped within a single frame (down and up before a poll).
- Let a stick's touchZone be given as a share of the screen so it follows resizing, like the default.
- Say how a raygui button and the virtual gamepad should be combined; `blockedBounds` works but is easy to miss. It could take raygui
  bounds automatically.
- `Device.hx`: `EnableTouchEmulation`, `DisableTouchEmulation` and `IsTouchEmulated` are outside the generated block with empty bodies;
  say they aren't built yet. A desktop program has to guess whether to call `EnableTouchEmulation` always.
- The docs for `IsVirtualGamepadVisible` say "on a device with touch", while the class doc says touch emulation also draws it. Make them agree.
