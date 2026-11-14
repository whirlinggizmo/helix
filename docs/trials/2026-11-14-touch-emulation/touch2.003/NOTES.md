# Notes

## Compile errors
1. `Main.hx:72: Float should be Int (posX)` — `DrawText` takes an Int x; `W / 2 - MeasureText(...) / 2` is a Float in Haxe. Wrapped it in `Std.int(...)`.
Nothing else failed; `haxe build.hxml` now compiles cleanly.

## Guesses / unsure
- **Touch emulation:** I call `EnableTouchEmulation()` only when `!IsTouchAvailable()`. The doc says that on a device with touch both work as fingers, so calling it always may be fine too; I chose the narrower reading of "on a desktop with no touch screen". A laptop with touch and a mouse therefore gets no emulation, which may not be wanted (the doc says `IsFinePointerAvailable`/touch can both be true).
- **Virtual gamepad is only "plugged in" by a first touch.** Before the first touch `IsGamepadAvailable(0)` is false, so I gate reading the axes on it. Unsure whether `GetGamepadAxisMovement` on an unplugged slot is safe/0; gating seemed safest. It also means the stick hint/pause button visibility before first touch relies on the doc ("buttons and fixed sticks drawn from the moment it's enabled", a floating stick shows only its hint).
- **Pause button:** there is no "pause" concept, so I used a `VirtualButtonOptions` with `GAMEPAD_BUTTON_MIDDLE_RIGHT` (Start) at the top-right, radius 28, label "II", read through `IsGamepadButtonPressed(0, ...)`. A default label for a non-face button is "", so I set one. Whether `IsGamepadButtonPressed` fires on a virtual button at the frame of the press (vs. down state) is assumed from the doc. Because a physical pad in slot 0 hides the virtual one, Start on a real pad also toggles pause — a side effect I accept.
- **Where it's drawn:** the virtual gamepad draws at `EndDrawing`, over everything, including the raygui Reset button and the "Paused" text. The button and stick are not overlapped by those in my layout.
- **Reset vs. stick:** I put the Reset rectangle in `blockedBounds` so a finger landing there stays free (and counts as the mouse for raygui's `GuiButton`). I assumed raygui reads the free finger as the mouse via touch/mouse position; the doc says a free finger counts as the mouse. A finger that slides from the stick onto Reset keeps the stick (per doc).
- **Left stick touch zone:** set explicitly to the left half (`0,0,W/2,H`) although it's the default with the right stick disabled... the default says "the whole screen with one [stick]", so the explicit zone is required, and I disabled the right stick (`right: {enabled:false}`).
- **Sign of Y:** assumed `GAMEPAD_AXIS_LEFT_Y` is positive downward (as raylib), so it maps directly to screen y.
- **Speed:** the stick reads 0..1 past the dead zone; I clamp the vector length to 1 so diagonals don't exceed 300 px/s (assumed square-ish reading is possible on a physical pad).
- **Paused:** the ball is frozen when paused, including from the physical stick.
- `VirtualStickOptions`/`VirtualButtonOptions` are `@:structInit`; I used anonymous-structure literals, which compiled. `Rectangle`/`Vector2` have constructors (`new Rectangle(...)`).

## API suggestions
- `IsTouchAvailable` + `EnableTouchEmulation` is a very common pair; an `EnableTouchEmulation(onlyWithoutTouch)` or an automatic option would remove the boilerplate.
- A built-in "pause/toggle" button kind or a way to make a button a latch would be handy; reading `Pressed` of Start is indirect.
- Say explicitly whether `GetGamepadAxisMovement` returns 0 on an unplugged virtual slot, and whether `IsGamepadAvailable` is true before the first touch.
- Say whether raygui widgets see a free finger as the mouse (position and press), and whether `blockedBounds` is the intended way to let raygui buttons work.
- `EnableVirtualGamepad` options: with `right: {enabled:false}` the left stick's default zone becomes the whole screen; a note on this in `touchZone` is present but easy to miss.
- `DrawText` taking Int means `MeasureText` math needs `Std.int`; unrelated to extras, but a Float overload would help.
