# Task: a game's main menu

Write a small raylib program in Haxe (helix-raylib) that draws a game's main menu with raygui, its controls drawn from textures, on an
800 x 450 window targeting 60 frames a second.

- **Buttons:** "Play", "Options" and "Quit", raygui's buttons drawn from `assets/button.png`, a sheet of four cells of 192 x 64 top
  down: normal, focused, pressed and disabled, each a nine-patch with borders of 16 at the sides and top and 20 at the bottom. In the
  normal, focused and disabled cells the button's face is raised: its bottom 4 texels are a darker lip. In the pressed cell the face
  is pushed down 4 texels onto the lip. A pressed button's text moves down with its face.
- **Icons on buttons:** each of the three buttons shows an icon before its text, from `assets/icons.png`, a row of three 24 x 24
  images: a triangle for Play, a gear for Options and a door for Quit. The text sits after the icon, not over it.
- **Options greyed:** the Options button is disabled until Play has been pressed once.
- **Sound toggle:** a round button in the corner, an image alone with no text: `assets/sound_on.png` and `assets/sound_on_pressed.png`
  while sound is on, `assets/sound_off.png` and `assets/sound_off_pressed.png` while it's off (each 48 x 48), the pressed image shown
  while it's held. Clicking it turns sound on or off.
- **Hover lift:** the Quit button is drawn from `assets/button_quit.png`, a sheet laid out as `button.png`, red, whose focused cell's
  face is 2 texels higher than its normal cell's. Its text lifts with its face while the pointer is over it.
- **Bars:** under the buttons, raygui's progress bars for the hero's health and experience, both over `assets/bar_grey.png`
  (96 x 16, round caps 16 texels wide at each end). Health is `assets/bar_red.png` (the same size and caps), revealed as health
  rises like a thermometer, its left cap always showing and its right cap only when full, with a round tip
  (`assets/bar_tip.png`, 16 x 16) at the end of the red. Experience is `assets/bar_blue.png` (the same size and caps), stretched
  to the experience, with no tip. Health goes from 0 to 100 and back over 10 seconds, experience from 0 to 100 over 20.
- **Done when:** `haxe build.hxml` compiles it without errors. Some calls aren't built yet, so it isn't run.
