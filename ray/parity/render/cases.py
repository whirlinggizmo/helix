"""render: rlgl's blending and color mask, and render textures, as both draw them between scene.c.in's and Main.hx.in's ClearBackground and
the frame's end (shared/gen.py's syntax). target (a 200 x 100 render texture), checks (a 64 x 64 checked texture) and frame (0, 1 or 2) are
made there."""

# Each blend mode drawn half over a blue band, a cell of 70 x 70 each: x is 10 + 78 * the mode's place.
MODES = [
    ('BLEND_ALPHA', ''),
    ('BLEND_ADDITIVE', ''),
    ('BLEND_MULTIPLIED', ''),
    ('BLEND_ADD_COLORS', ''),
    ('BLEND_SUBTRACT_COLORS', ''),
    ('BLEND_ALPHA_PREMULTIPLY', ''),
    ('BLEND_CUSTOM', 'rlSetBlendFactors(RL_ONE_MINUS_DST_COLOR, RL_ZERO, RL_FUNC_ADD); '),
    ('BLEND_CUSTOM_SEPARATE', 'rlSetBlendFactorsSeparate(RL_DST_COLOR, RL_ZERO, RL_ONE, RL_ZERO, RL_FUNC_REVERSE_SUBTRACT, RL_FUNC_ADD); '),
]

CASES = [
    f'{setup}DrawRectangle({10 + 78 * i}, 10, 70, 35, NEW(Color, 40, 120, 200, 255)); BeginBlendMode({mode}); '
    f'DrawRectangle({25 + 78 * i}, 20, 40, 50, NEW(Color, 200, 80, 40, 160)); EndBlendMode();'
    for i, (mode, setup) in enumerate(MODES)
] + [
    # Custom factors changed while in the custom mode take effect only when the mode is set again.
    'rlSetBlendFactors(RL_ONE, RL_ONE, RL_FUNC_ADD); BeginBlendMode(BLEND_CUSTOM); DrawRectangle(10, 100, 60, 40, NEW(Color, 100, 0, 0, 255)); '
    'rlSetBlendFactors(RL_ZERO, RL_ONE_MINUS_SRC_COLOR, RL_FUNC_ADD); DrawRectangle(80, 100, 60, 40, NEW(Color, 100, 0, 0, 255)); '
    'BeginBlendMode(BLEND_CUSTOM); DrawRectangle(150, 100, 60, 40, NEW(Color, 100, 0, 0, 255)); EndBlendMode();',
    # A factor GL doesn't have leaves the factors as they were (BLEND_ALPHA's, EndBlendMode's); the equation still changes.
    'rlSetBlendFactors(12345, RL_ONE, RL_FUNC_SUBTRACT); BeginBlendMode(BLEND_CUSTOM); DrawRectangle(220, 100, 60, 40, NEW(Color, 0, 100, 0, 255)); EndBlendMode();',
    # Red and alpha alone written; the batch drawn first, as the mask reaches what waits in it.
    'DrawRectangle(300, 100, 60, 40, SKYBLUE); rlDrawRenderBatchActive(); rlColorMask(true, false, false, true); '
    'DrawRectangle(310, 110, 40, 20, WHITE); rlDrawRenderBatchActive(); rlColorMask(true, true, true, true);',
    # A render texture's alpha as each mode leaves it, drawn over the checks (twice their size, repeated) and over the background, and
    # premultiplied.
    'BeginTextureMode(target); ClearBackground(BLANK); DrawRectangle(10, 10, 80, 80, NEW(Color, 230, 40, 40, 128)); '
    'BeginBlendMode(BLEND_ADDITIVE); DrawPoly(V2(110, 50), 12, 35, 0, NEW(Color, 40, 200, 40, 128)); EndBlendMode(); '
    'rlSetBlendFactorsSeparate(RL_SRC_ALPHA, RL_ONE_MINUS_SRC_ALPHA, RL_ONE, RL_ONE, RL_FUNC_ADD, RL_MAX); BeginBlendMode(BLEND_CUSTOM_SEPARATE); '
    'DrawRectangle(130, 20, 60, 60, NEW(Color, 40, 40, 230, 100)); EndBlendMode(); EndTextureMode();',
    'DrawTexturePro(checks, R(0, 0, 100, 50), R(20, 170, 200, 100), V2(0, 0), 0, WHITE); DrawTextureRec(target.texture, R(0, 0, 200, -100), V2(20, 170), WHITE);',
    'DrawTextureRec(target.texture, R(0, 0, 200, -100), V2(230, 170), WHITE);',
    'BeginBlendMode(BLEND_ALPHA_PREMULTIPLY); DrawTextureRec(target.texture, R(0, 0, 200, -100), V2(440, 170), WHITE); EndBlendMode();',
]
