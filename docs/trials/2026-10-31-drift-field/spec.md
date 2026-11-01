# Drift Field (2D, a field larger than the window)

A small 2D game: a ship gathering crystals in a field larger than the window, the view following it.

- **Window:** 960 x 540, resizable. The view fills the window when it is resized, the ship kept at its center, and the text keeps to
  the window's edges.
- **Title:** a text "Drift Field" and "Press any key, click or tap to start", centered, with the best score saved from an earlier run
  under it ("Best: 12"), and "Drop a level file to play it" under that. Any key, click, tap or gamepad button starts at level 1.
- **Levels:** each level is a text file, `assets/levels/level1.txt`, `assets/levels/level2.txt` and so on; the program builds the name
  from the level's number. A file has one `key=value` per line:
  - `seed`: the number the field is made from;
  - `width`, `height`: the field's size, in world pixels;
  - `rocks`: how many rocks;
  - `crystals`: how many crystals;
  - `seconds`: how long the level lasts;
  - `target`: how many crystals to gather in the level to go on to the next.
  When a level's file doesn't exist, the player has won: show "You win! Score: N", then the title again.
- **The field:** made at the level's start from its seed: rocks at random places, each side 40 to 160, and crystals at random places
  clear of them. The same file makes the same field every time, on the page and natively. Rocks are gray rectangles, crystals cyan
  circles of radius 8, both drawn as shapes. The field's edge is drawn as a white outline. The background outside the field is black,
  inside it dark blue.
- **The ship:** the sprite `assets/player.png`, starting at the field's center (moved off any rock it lands on).
  - Moved by the arrow keys, WASD or a gamepad's left stick, at 300 world pixels a second whatever the frame rate, no faster on a
    diagonal.
  - A click or tap on the field sends it flying to that point in the world at the same speed, until it arrives or a key or stick
    moves it. The point is marked with a small cross until it arrives.
  - Rocks and the field's edge stop it: it slides along them rather than passing through.
  - Touching a crystal gathers it: it plays `assets/coin.wav` and adds 1 to the score. A gathered crystal is gone for the level.
- **The view** follows the ship.
  - The mouse wheel zooms, from 0.5 to 2; `Q` and `E` turn the view, 90 degrees a second. `R` puts zoom and turn back to 1 and 0.
  - Clicking while zoomed or turned still sends the ship to the point under the pointer.
- **The map:** a 200 x 120 view of the whole field at the window's bottom right, framed, the ship a dot on it. Nothing drawn
  in the map spills outside its frame.
- **Text** at the top left: the score (the total across levels), the level's number, crystals gathered in the level and its target;
  at the top right, the time left. The text doesn't turn or zoom with the view.
- **End of a level:** when its time runs out or every crystal is gathered, if the level's count reached its target, the next level is
  loaded; if not, "Time! Score: N" and the title again. A new best score is saved at once, so it is there after a reload or a restart.
- **A dropped file:** a level file dropped on the window, on the title or in play, is played at once as a level of its own, with its
  number shown as "Custom". When it ends the title comes back, whatever the count. A dropped file that isn't a level (a key missing or
  not a number) leaves the game as it was and shows "Not a level: <its name>" on the title for 3 seconds.
- **Escape** returns to the title from play.
