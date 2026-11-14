# NOTES

## Compile errors
1. `DrawText` x argument: `W / 2 - MeasureText(...) / 2` is a Float (Haxe `/` is always Float); wrapped in `Std.int`. Nothing else failed; it compiled on the second try.

## Guesses / unsure
- **Touch emulation on desktop:** I call `EnableTouchEmulation()` when `!IsTouchAvailable()`. The doc says `IsTouchAvailable` is unchanged by emulation, so the guard is meaningful. On a touch laptop with a mouse, emulation stays off, so the mouse wouldn't work the controls. Unsure whether to enable it unconditionally (the doc doesn't say what a real finger plus emulation does). Both calls are stubs here, so I couldn't check.
- **Pause button:** the API has no round standalone button, so I used a virtual *button* (`GAMEPAD_BUTTON_MIDDLE_RIGHT`, radius 28, label "II", `position` top right) and read it with `IsGamepadButtonPressed(0, ...)`. Guesses: that a button not in the face-button diamond works when given an explicit `position` (doc says one without a position "isn't drawn", so I gave one); that "Pressed" fires once per finger landing; that the label "II" fits. Drawn at `EndDrawing`, over everything, so its look can't be changed in-frame.
- Because the pause button is read through the gamepad, a physical gamepad's Start button also toggles pause, and a physical gamepad in slot 0 hides the on-screen pause button (the docs say the virtual gamepad is hidden then). Acceptable, but untested.
- **Reset button vs. stick:** `GuiButton` reads the mouse, and the docs say free fingers count as the mouse. I put Reset's rectangle in `blockedBounds` so a finger landing there stays free (and so presses raygui) instead of capturing the stick. Unsure whether a finger holding the *stick* that slides over Reset also clicks it (the docs say it keeps the stick, and a captured finger isn't the mouse, so presumably not).
- **Left stick zone:** `left.touchZone` = left half explicitly (also the default with two sticks, but with the right stick disabled the default becomes the whole screen, so I set it). The zone is fixed to 800x450, not following window size.
- `basePlacement` set on the gamepad options as floating (the default); the hint is visible until the first touch (default).
- Stick values: assumed y positive = down, matching screen axes, so I add `ay` to y directly. I normalise if length > 1 in case the axes read per-axis (square) rather than circular; the doc says "1 at the radius in any direction", so this may be redundant.
- Slot 0 used for both virtual and physical; physical replaces virtual, as documented.
- `GuiButton` returns Int here (compared `!= 0`).

## API suggestions
- A first-class virtual "tap button" with a shape/anchor (top-right) and a `pressed` query that doesn't go through gamepad button codes; Start as a pause button is a workaround.
- Say whether `EnableTouchEmulation` should be conditional on `IsTouchAvailable()`, or make an `EnableTouchEmulationIfNoTouch`-like option; and say whether it is a no-op on devices with real touch.
- Document default `Reset`-style raygui interplay: a `blockedBounds` example is there, but state explicitly that raygui sees free fingers as the mouse.
- Options defaults for positions are tied to the screen's size; an `anchor` (e.g. top-right with margin) would remove hard-coded coordinates.
- `Device.EnableTouchEmulation` lives in Device but is described mostly in terms of VirtualGamepad; cross-link it from VirtualGamepad's doc (it is, but only in passing).
