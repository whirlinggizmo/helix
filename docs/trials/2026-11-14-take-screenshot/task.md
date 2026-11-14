# Task: a title screen

Write a small raylib program in Haxe (helix-raylib): a game's title screen, in an 800 x 450 window at 60 frames a second.

- **Panel:** `assets/ui/panel.png` drawn as a 420 x 260 box in the middle of the window, on a dark background.
- **Title:** "WARDENS" in `assets/ui/font.ttf` at 64 pixels, centered across the window (measured with `MeasureTextEx`), 120 pixels from
  the top.
- **Prompt:** "PRESS ENTER" in the same font at 24 pixels, centered under the title, blinking once a second.
- **Enter:** pressing Enter closes the window.
- **Stopping:** `--frames=N` closes it after N frames, saving `shot.png` (raylib's screenshot call) on the last.
- **Done when:** it builds, runs with `--frames=120`, and `shot.png` shows the title screen.
