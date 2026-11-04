# Task: a skinned main menu

Write a small raylib program in Haxe: a game's main menu drawn with raygui, every control skinned from the game's UI art.

- **Window:** 800 x 450. The background is dark blue-gray.
- **Panel:** a panel 360 x 300 in the middle, drawn with `assets/panel.png` as a nine-slice (its corners must not stretch), holding:
  - **Title:** "WARDENS" near the top.
  - **Buttons:** Play, Options and Quit, one under the other, each drawn from `assets/button.png`. The sheet has four states stacked vertically (normal, focused, pressed, disabled), and `assets/slices.txt` gives the cell size and margins. Hovering, pressing and a disabled button must each show their own state. Quit is disabled in a page (it means nothing there).
  - **Volume slider:** 0 to 100. Its box uses the panel art, and its bar and handle use the button art's pressed and normal cells.
  - **Close button:** a small square "X" button in the panel's top-right corner, drawn with the button art's focused cell in every state, while the other buttons keep their own skin.
- **Font:** `assets/font.ttf` at size 20 for the controls.
- **Behavior:** clicking Play prints "play", Options toggles a check box "Fullscreen" under the slider, and X prints "close".
