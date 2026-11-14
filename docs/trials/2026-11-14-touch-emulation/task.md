# Task: phone controls tried at a desk

Write a small raylib program in Haxe (helix-raylib) for phones, on an 800 x 450 window targeting 60 frames a second.

- **Ball:** a ball in the middle of the screen, moved by an on-screen stick as a gamepad's left stick moves it, at up to 300 pixels a
  second. A physical gamepad's left stick moves it too.
- **Stick:** the on-screen stick appears where a finger lands on the left half of the screen, and lifting the finger stops the ball.
- **Pause:** a round on-screen button in the top right corner pauses and unpauses. "Paused" is drawn while paused.
- **Reset:** a raygui button "Reset" at the bottom middle puts the ball back in the middle. A finger on the Reset button presses it,
  and never moves the stick.
- **At a desk:** with a mouse at a desk, a press of the mouse works the stick, the pause button and Reset as a finger
  does, so the phone controls can be tried with a mouse.
- **Done when:** `haxe build.hxml` compiles it without errors. Some calls aren't built yet, so it isn't run.
