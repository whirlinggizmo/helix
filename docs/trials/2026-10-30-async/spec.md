# Coin Garden (2D, with levels)

A small 2D game.

- **Window:** 960 x 540, resizable. The 2D layout keeps to the window's edges when it is resized.
- **Title:** a text "Coin Garden" and "Press any key, click or tap to start", centered. The best score saved from an earlier run is shown
  under it ("Best: 12"). Any key, click, tap or gamepad button starts at level 1.
- **Levels:** each level is a text file, `assets/levels/level1.txt`, `assets/levels/level2.txt` and so on; the program builds the name
  from the level's number. A file has one `key=value` per line:
  - `coins`: how many coins are on the field at a time;
  - `seconds`: how long the level lasts;
  - `target`: the score to reach in the level to go on to the next;
  - `background`: the field's color, as `r,g,b`.
  When a level's file doesn't exist, the player has won: show
  "You win! Score: N", then the title again.
- **Play:**
  - The player is a sprite from `assets/player.png`, moved by the arrow keys, WASD, or a gamepad's left stick, at 240 pixels a second
    whatever the frame rate, no faster on a diagonal.
  - The level's number of coins at a time, each a yellow circle drawn as a shape (no image), at random places. Touching one collects
    it: it plays `assets/coin.wav`, adds 1 to the score, and a new coin appears elsewhere.
  - The score (the total across levels), the level's number and its target are text at the top left; the time left is at the top right.
- **End of a level:** when its time runs out, if the level's score reached its target, the next level is loaded; if not, "Time! Score:
  N" and the title again. A new best score is saved at once, so it is there after a reload or a restart.
- **Escape** returns to the title from play.
