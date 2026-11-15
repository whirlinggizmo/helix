# Notes

## Compile errors (in order)
1. `Main.hx:38: Not enough arguments, expected animCount:Array<Int>` — `LoadModelAnimations` takes an `Array<Int>` out-param for the count; passed `[0]`.
2. `Main.hx:39: You can't iterate on a Dynamic value` — annotated the result as `Array<ModelAnimation>`.

## Warnings logged
1. `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()` — moved the `TakeScreenshot` call to just before `EndDrawing()` on the last frame.
No other warnings.

## Guesses
- `EnsureAssetsAsync` callback: guessed a no-argument `function()`; it compiled. Everything is loaded inside it, with a "Loading..." screen until then.
- Animation: picked the clip named exactly `CharacterArmature|Idle`, stepping one frame per rendered frame, applied to all four body parts with `UpdateModelAnimation`.
- Orbit speed 0.2 rad/s, camera fovy 45, target (0,1,0), floor 20x20 plane — all my choices.
- Panel texture stretched to 360x120 with `DrawTexturePro`; title at (20, panel top + 40) in white with spacing 2.
- `--frames=N` parsed from `Sys.args()`.
- Music looping set with `music.looping = true`.
