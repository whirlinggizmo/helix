# NOTES

## Compile errors
1. `DrawText` posX: `Float should be Int` (`W / 2 - MeasureText(...) / 2` is Float in Haxe). Wrapped in `Std.int(...)`.
That was the only error; the program compiles. It has not been run.

## Guesses / unsure
- **Touch emulation on/off:** I call `EnableTouchEmulation()` only when `!IsTouchAvailable()`. The doc says `IsTouchAvailable` is
  unchanged by emulation, so the check is stable. A laptop with touch and a mouse gets no emulation, so its mouse can't work the
  controls. Unclear if that is wanted; `IsFinePointerAvailable` seemed no better.
- **Order:** I enable emulation before `EnableVirtualGamepad`; the docs don't say whether order matters.
- **Pause button:** there is no "plain" button API, so it's a virtual button read as `GAMEPAD_BUTTON_MIDDLE_RIGHT` with label "II". I
  chose that gamepad button arbitrarily. Position is the button's center (assumed from "center"), top right, inset 20px from the
  safe area. Whether a button with an explicit `position` is drawn in the top right (not the default diamond) I took from the docs
  ("Another button without a position is up and isn't drawn" implies positioned ones are drawn). The round look is the ring.
  It is drawn by `EndDrawing`, over everything, so over "Paused" if they overlapped (they don't).
- **Pause toggling with a physical gamepad:** the same button read also reacts to the physical pad's MIDDLE_RIGHT (Start), since slot 0
  is shared. Intended side effect.
- **Stick zone:** with the right stick disabled the default zone is the whole screen, so I set `left.touchZone` to the left half
  explicitly. The Rectangle uses `W / 2` as Float; no Rectangle constructor check beyond compiling.
- **Stick appears where the finger lands:** `VIRTUAL_STICK_BASE_FLOATING`. `hintVisible` (default true) also shows a faint stick before
  the first touch; the task says it "appears where a finger lands", so I may want `hintVisible: false`. I left the default.
- **Reset vs. stick:** `blockedBounds: [resetBounds]` keeps a finger on Reset free (so it counts as the mouse for `GuiButton`). The
  docs say a free finger counts as the mouse, so I rely on `GuiButton` seeing it. Not sure `GuiButton` reads the touch-emulated
  mouse position on the frame of landing. Reset is drawn by me, and the virtual gamepad doesn't draw over it except at EndDrawing.
- **Reset bounds** use the safe area bottom; the doc coordinates are said to match `GetScreenWidth`, so I assumed no scaling.
- **Stick reading:** `GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X/Y)` is -1..1 with y down; I multiply by 300*dt without
  normalising diagonals (the dead-zone/radius doc says it rises evenly to 1 in any direction, so length ≤ 1).
- **Paused:** the stick and button still capture fingers while paused; only the ball is frozen.
- **Plugging in:** the pad is only plugged in on the first touch, so `IsGamepadButtonPressed` for the very first touch (landing on the pause
  button) may or may not count. Unclear.

## API changes I'd suggest
- A plain round on-screen button not tied to a gamepad button (or a named "pause"/start-button default and position).
- Say in `VirtualButtonOptions` whether `position` is the center in screen pixels, and that label can be any text.
- Say whether raygui reads the emulated/free finger, and make `blockedBounds` accept a raygui-style helper.
- `EnableTouchEmulation` could take a default of "when no touch", e.g. `EnableTouchEmulationIfNoTouch()`; every desktop-tried phone
  program would write that same `if`.
- Let a stick take `hintVisible`-like option at gamepad level plus a `Device`-aware default so desktops without emulation show nothing.
- Document whether `EnableTouchEmulation` order relative to `EnableVirtualGamepad` matters.
