# Notes

## Compile errors
1. `Main.hx:57: Unterminated regular expression` — I wrote `~/` (not Haxe) for integer division in the "Paused" centering. Changed to `Std.int(x / 2)`. No other errors; `haxe build.hxml` then compiles clean.

## Guesses / unsure points
- **Pause button as a virtual button.** There is no "plain" virtual button, only buttons read as gamepad buttons. I chose `GAMEPAD_BUTTON_MIDDLE_RIGHT` (Start) with label "II", `position` (750, 50), `radius` 30, and toggle on `IsGamepadButtonPressed(0, ...)`. Unsure the button is drawn round: the doc says "ring"/"circle" so I assume so. Unsure where the label draws (assumed centered in the ring). Since a physical gamepad's Start also toggles pause, that's a side effect I accepted.
- **Pause button via the virtual gamepad vs. raygui/own drawing.** Chose the virtual button so a finger on it is captured (not a free finger/mouse), and it works with touch emulation by the mouse.
- **Gating on `IsGamepadAvailable(0)`.** Docs say the first touch (or a left mouse press with touch emulation) plugs the gamepad in. I assumed that before then, axes/buttons read nothing, so I guard on availability. Unsure whether the very first press that plugs it in already counts as the stick landing / button press.
- **Reset button vs. stick.** Reset (350..450 x 390..430) straddles the left-half boundary at x=400, so I put its rectangle in `blockedBounds`; a finger landing there stays free, counts as the mouse, and raygui's `GuiButton` sees it. I assumed `GuiButton` reads the mouse state the free finger produces (including emulated press) — not verified, since nothing is run. Not sure whether GuiButton's press fires on release when the virtual gamepad is drawn later at `EndDrawing` (no conflict expected).
- **Touch zone.** With the right stick disabled, the default left zone would be the *whole screen* ("the whole screen with one"). The task wants the left half only, so I set `left.touchZone` to (0,0,400,450) explicitly. The task wording "left half" made me suspect the default would otherwise surprise.
- **Stick base placement.** Default `VIRTUAL_STICK_BASE_FLOATING` — base is where the finger lands, as the task asks. Hint shows (hintVisible default true) before first touch; fine.
- **Stick axis direction/scale.** Assumed Y positive = down (matches screen) and magnitude 0..1, so ball velocity = axis * 300 px/s. Assumed the left stick keeps reading 0 after the finger lifts (ball stops). Diagonal is not clamped by me; docs say "evenly to 1 at the radius in any direction" so I assumed it's already radial-limited.
- **Physical gamepad.** "A physical gamepad plugged into the slot replaces the virtual one": I used slot 0 for both, so one code path reads either. `IsGamepadAvailable(0)` is true for either.
- **`EnableTouchEmulation` timing.** Called before `EnableVirtualGamepad`; docs say either order and it takes effect at the next press.
- **Device.hx unused otherwise.** I didn't call `IsTouchAvailable`/`IsFinePointerAvailable`; touch emulation is always on, so the mouse works on a phone too (docs: touch and mouse both work).
- `Rectangle`/`Vector2` constructed with `new`; assumed positional constructors exist (it compiled).

## API suggestions
- A plain `VirtualButtonOptions` without a gamepad-button identity would be nicer for UI buttons like pause; borrowing `MIDDLE_RIGHT` is a workaround. A dedicated "pause/menu" default (position, "II" label) would help.
- `touchZone` defaulting to the whole screen when only one stick is enabled is easy to miss; a `left`-half option or a doc example for it would help.
- `blockedBounds` would be easier if raygui buttons could be registered automatically, or a doc example showed the Reset-style case.
- Say explicitly what `IsGamepadAvailable(0)` is before the first touch, and whether the plugging-in press itself is delivered.
- `VirtualButtonOptions.position` doc says "Another button without a position is up and isn't drawn" — clarify for non-face buttons like Start that a position is required.
- Document when emulated mouse touch ends/lifts if the pointer leaves the window.
