# Task: a pause menu

Write a small raylib program in Haxe (helix-raylib): a touch game's pause menu, in an 800 x 450 window at 60 frames a second.

- **Background:** dark gray, (30, 32, 40).
- **Panel:** a 420 x 260 rectangle in the middle of the window, colored (52, 58, 74), with a 2-pixel outline colored (120, 132, 160).
- **Title:** "PAUSED" at 40 pixels in raylib's default font, centered across the panel, 30 pixels below its top, in white.
- **Swatches:** five 48 x 48 squares in a row across the panel's middle, 16 pixels apart, centered, in these colors, each fully opaque:
  (230, 41, 55), (255, 161, 0), (0, 228, 48), (0, 121, 241), (200, 122, 255).
- **Touch buttons:** two on-screen buttons from helix-raylib's VirtualGamepad extra, drawn as on a phone: "II" at the window's top right,
  read as `GAMEPAD_BUTTON_MIDDLE_RIGHT`, and "OK" at the bottom right, read as `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`, each of radius 40,
  centered 60 pixels in from the window's edges. Touch emulation is on, so they show on a desktop.
- **Buttons pressed:** "OK" closes the window. "II" toggles the panel's outline between its color and white.
- **Stopping:** `--frames=N` closes it after N frames, saving `shot.png` (raylib's screenshot call) on the last.
- **Done when:** it builds, runs with `--frames=60`, and `shot.png` shows the menu with both buttons.
