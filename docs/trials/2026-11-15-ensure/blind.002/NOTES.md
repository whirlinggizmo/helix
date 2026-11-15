# Notes

## Compile errors (in order)
1. `Main.hx:18: Not enough arguments, expected animCount:Array<Int>` — `LoadModelAnimations` takes the count as an out `Array<Int>`; I pass `[0]` and read `cnt[0]`.

## Warnings logged
1. `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()` — moved `TakeScreenshot` to just before `EndDrawing()` on the last frame.

## Guesses
- Animation is chosen by exact name `CharacterArmature|Idle` (the list also has Idle_Gun etc.); it is applied to all four body-part models by frame index modulo frameCount, one frame per tick.
- Camera orbit radius sqrt(3^2+6^2) ~ 6.708 (6 out, 3 up at start), 0.3 rad/s, looking at (0,1,0).
- Panel placed with a 10px margin from the bottom left; text at 40px with spacing 2, white, offset (20,40) in it.
- `music.looping = true` set as a field on the Music struct.
- Floor: 20x20 gray plane; sky-blue background.
