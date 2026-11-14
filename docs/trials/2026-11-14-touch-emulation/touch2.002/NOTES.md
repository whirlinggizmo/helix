# Notes

## Compile errors
1. `Main.hx:54: Unterminated regular expression`: I wrote `~/` for integer division, which isn't Haxe. Changed to
   `Std.int(MeasureText(...) / 2)`. That was the only error; the rest compiled first time.

## Guesses / unsure points
- **Pause button as a virtual button.** There is no "round button" call, so I used a `VirtualButtonOptions` read as
  `GAMEPAD_BUTTON_MIDDLE_RIGHT`, at (760, 40), radius 24, label "II", and read it with `IsGamepadButtonPressed(0, ...)`.
  Guessed that any `GAMEPAD_BUTTON_*` works and that a button with a `position` is drawn. The docs only describe the face-button defaults.
  A physical gamepad's Start button toggles pause too, because it is the same gamepad button. I think that's fine.
- **Touch emulation.** Called `EnableTouchEmulation()` only when `!IsTouchAvailable()`, as the task says "no touch screen". The docs say a
  laptop may have both touch and a mouse, and that with touch both work as fingers, so calling it unconditionally might also be right.
  Order relative to `EnableVirtualGamepad` doesn't matter per the docs.
- **Reset vs. stick.** Put the Reset rectangle in `blockedBounds`, so a finger there stays free and counts as the mouse, which
  `GuiButton` reads. I assumed raygui's `GuiButton` sees an emulated or free finger as the mouse (the docs say free fingers count as the
  mouse). Not checked, since the program isn't run. The button straddles the x=400 line, so the left stick's zone (0..400) overlaps it.
- **Left stick zone.** Set `touchZone` to the left half explicitly. The default with the right stick disabled is the whole screen, so
  I had to set it. `right: {enabled: false}` is needed for that reason, and I assumed a disabled stick draws nothing.
- **Pause button vs. stick zone.** The docs say buttons capture a finger even inside a stick's zone. The pause button is on the right
  half anyway.
- **Where things draw.** The virtual gamepad draws at `EndDrawing`, over everything, including the raygui Reset button and the "Paused"
  text. The pause button would cover anything placed under it. The stick appears only while a finger holds it, and a hint near the
  bottom-left corner is shown before the first touch (default). I left that on.
- **Axis sign.** Assumed `GAMEPAD_AXIS_LEFT_Y` is positive downward, as in raylib's gamepads, so `ball.y += ay`. The docs don't say.
- **Plug-in.** A mouse click alone doesn't plug the virtual gamepad in, and emulation makes it a finger, so I rely on that. The
  first press on the pause button also plugs in the gamepad, but may not itself register as a press. Not stated.
- **Speed.** 300 px/s × axis × `GetFrameTime()`. The axis is circular, so max speed is 300 along any direction. I also clamp the
  ball to the window (not requested).
- Reading slot 0 means a physical gamepad (first one takes slot 0) drives the ball, as required.

## API suggestions
- A `VIRTUAL_BUTTON`-style default for pause/start/menu (a small round button in a corner) would save choosing a gamepad button and
  position by hand.
- Say outright whether Y axes are positive down, and whether `GuiButton` and the other raygui calls see free fingers as the mouse.
- Offer `blockedBounds` as an explicit "UI rectangle" in the docs for raygui, as I used it here. It's the only mention of raygui.
- `EnableTouchEmulation` / `IsTouchEmulated` are plain empty stubs in `Device.hx`. They are outside the generated region and hold
  no logic, so it's unclear whether they work yet.
- A virtual stick's hint is described as at "the bottom outer corner" by its zone. Say which corner for a left-half zone.
- `VirtualGamepadOptions` could take a `touchEmulation: true` flag, so one call sets up desk testing.
