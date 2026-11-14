# Task: a game's status widgets

Write a small raylib program in Haxe (helix-raylib) that draws a game's status widgets, each from textures, on a 1280 x 720 window
targeting 60 frames a second. The screen is drawn at 640 x 360 into a render texture, shown as large as fits the window with its
aspect kept, raygui's controls answering the mouse where they're shown. The amounts change over time so each widget moves.

- **Health bar:** raygui's progress bar, its box `assets/bar_grey.png` and its progress `assets/bar_red.png`, both 96 x 16 with round
  caps 16 texels wide at each end. The red bar is revealed as health rises, like a thermometer: its left cap always shows, its right
  cap only at full health, and a small round tip (`assets/bar_tip.png`, 16 x 16) sits at the end of the red. Health goes from 0 to 100
  and back over 10 seconds.
- **Mana ball:** a glass ball (`assets/ball_glass.png`, 128 x 128) filled from the bottom with mana (`assets/ball_mana.png`, 128 x 128),
  froth (`assets/froth.png`, 64 x 12) riding on the mana's surface. Mana goes from 0 to full and back over 6 seconds.
- **Cooldown:** an ability icon (`assets/icon.png`, 64 x 64), drawn grey, with the full-color icon revealed clockwise from twelve
  o'clock as the ability recharges over 3 seconds.
- **Speed gauge:** a half-circle gauge (`assets/gauge.png`, 200 x 100, the dial's top half) revealed from the left end around to the
  right as speed rises, a needle drawn at the revealed edge.
- **Panel:** raygui's panel behind the widgets, its frame a rope (`assets/rope_frame.png`, 96 x 96, borders 24), the rope's twists
  repeating along each side rather than stretching, at any size of panel.
- **Background:** a stone texture (`assets/stone.png`, 64 x 64) repeated across the whole screen at half its size.
- **Portrait:** the hero's portrait (`assets/portrait.png`, 128 x 128) drawn inside a hexagon 96 pixels across, beside the health bar.
- **Icons:** the ability icons for a row of four slots come from one sheet, `assets/icons.png` with `assets/icons.xml` (Kenney's
  format), the images `sword.png`, `shield.png`, `potion.png` and `bow.png`.
- **Done when:** `haxe build.hxml` compiles it without errors. The new calls aren't built yet, so it isn't run.
