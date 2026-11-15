# Task: a pixel-art game's screen

Write a small raylib program in Haxe (helix-raylib), in a resizable window starting at 1280 x 720, at 60 frames a second, that draws a
pixel-art game at 320 x 180 design pixels, whatever the window's size.

- **The level:** a 20 x 11 grid of 16 x 16 tiles (solid blocks along the bottom and a few platforms, drawn as colored squares with a
  1-pixel darker edge), and a small 12 x 14 character standing on the floor, slowly turning (rotated a few degrees back and forth), so its
  pixels show whether they stay on the design's grid.
- **Pixel art:** the design shown as large as fits, its shape kept, at a whole multiple of its size, every pixel a square block, with
  bars where the window's shape differs.
- **Mouse:** the tile under the mouse pointer is outlined in yellow, in design pixels, at any window size or shape.
- **HUD:** "SCORE 0420" at the top left and a heart at the top right, kept clear of a phone's notch and rounded corners.
- **A 3D view:** pressing Tab switches to a 3D view of the same level (the tiles as cubes, a camera framing all of it at a vertical field
  of view of 40 degrees at the design's shape), shown with no bars, more of the world showing on the window's longer side, the level never
  cut off whether the window is wider or taller than 16:9. Tab switches back.
- **Fit modes:** pressing F cycles the 2D view through every way the design can fit the window, its name shown in the HUD.
- **Done when:** it compiles. The screen fitting calls aren't built yet, so it isn't run.
