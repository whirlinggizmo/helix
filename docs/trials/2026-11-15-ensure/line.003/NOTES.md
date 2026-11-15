# Notes

## Compile errors (in order)
1. `Main.hx:39: Not enough arguments, expected animCount:Array<Int>` — `LoadModelAnimations` takes the count as an out-parameter array; passed `[0]` and read `cnt[0]`.

## Warnings logged
1. `TakeScreenshot: Screenshots are generated during EndDrawing()` — I called it after `EndDrawing()`; moved it before `EndDrawing()` on the last frame.

## Guesses
- Asset loading is done inside the `EnsureAssetsAsync` callback; the loop draws "Loading..." until it fires.
- The animation is applied to all four part models (they share the armature); I assumed the skeletons match.
- Idle clip chosen by name `CharacterArmature|Idle`; stepped one frame per tick.
- Panel drawn with DrawTexturePro stretched to 360x120 at (10,590); title at (30,630).
- Orbit speed 0.4 rad/s, floor is a 20x20 gray plane, camera targets (0,1,0).
