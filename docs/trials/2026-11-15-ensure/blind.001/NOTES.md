# Notes

## Compile errors (in order)
1. `Main.hx:17: Not enough arguments, expected animCount:Array<Int>` — `LoadModelAnimations` takes the count as an `Array<Int>` out-param; passed `[0]`.
2. `Main.hx:19: You can't iterate on a Dynamic value` — annotated the result as `Array<ModelAnimation>`.

## Warnings logged
- `TakeScreenshot: Screenshot could not be saved: Screenshots are generated during EndDrawing()` — called it after `EndDrawing()`; moved the call before `EndDrawing()` on the last frame, then break afterwards.

## Guesses
- `LoadFontEx(path, 40, null, 0)` for default glyph set.
- `music.looping = true` to loop the music stream.
- Animation advances one frame per rendered frame, wrapping at `frameCount`; the same clip is applied to all four models.
- Clip picked by name `CharacterArmature|Idle` (falls back to the first clip).
- Floor is a 20x20 `DrawPlane` in GRAY; orbit speed 0.3 rad/s; fovy 45; target at (0,1,0).
- Panel text placed at (20, 758-120+... i.e. y=638) with spacing 2.
