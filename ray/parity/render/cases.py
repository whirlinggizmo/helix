"""render: rlgl's blending and color mask, and render textures, as both draw them between scene.c.in's and Main.hx.in's ClearBackground and
the frame's end (shared/gen.py's syntax). target (a 200 x 100 render texture), checks (a 64 x 64 checked texture) and frame (0, 1 or 2) are
made there; so are red (a 32 x 32 red image), tile (8 x 8 green and blue checks), patched and second (textures of red), copy (a 32 x 32 render
texture), gray (a 16 x 16 grayscale ramp's texture), dark (8 x 4 of grayscale dark gray), trail (a 200 x 60 render texture) and readBack (none yet)."""

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
    # A texture made red again each frame (before its first draw, in memory), drawn into a render texture, then a rectangle of it replaced:
    # the screen's draws before and after the update both show the checks, as rlgl's batch is drawn after it; the render texture keeps
    # the red (shown by the case after: the screen is drawn after every render texture pass of its frame).
    'UpdateTexture(patched, red.data); BeginTextureMode(copy); ClearBackground(BLANK); DrawTexture(patched, 0, 0, WHITE); EndTextureMode(); '
    'DrawTexture(patched, 20, 290, WHITE); UpdateTextureRec(patched, R(4, 4, 8, 8), tile.data); DrawTexture(patched, 60, 290, WHITE);',
    # A grayscale texture's rectangle from grayscale bytes; a rectangle past the edge changes nothing.
    'UpdateTextureRec(gray, R(4, 6, 8, 4), dark.data); UpdateTextureRec(gray, R(12, 12, 8, 8), tile.data); '
    'DrawTextureEx(gray, V2(180, 290), 0, 2, WHITE);',
    # A render texture keeps what it holds: cleared in the first frame alone, a square added each frame and a second pass each frame.
    'BeginTextureMode(trail); if (frame == 0) ClearBackground(NEW(Color, 0, 0, 0, 0)); DrawRectangle(10 + frame * 40, 10, 30, 30, NEW(Color, 230, 40, 40, 160)); '
    'EndTextureMode(); BeginTextureMode(trail); DrawRectangle(20 + frame * 40, 25, 30, 30, NEW(Color, 40, 40, 230, 160)); EndTextureMode(); '
    'DrawTextureRec(trail.texture, R(0, 0, 200, -60), V2(240, 290), WHITE);',
    # Within a render texture, a draw flushed before the update keeps the old pixels; the one after shows the new.
    'LET(colors, Color *, LoadImageColors(tile)); UpdateTexture(second, red.data); UpdateTextureRec(second, R(8, 0, 8, 8), colors); '
    'BeginTextureMode(copy); DrawTexture(second, 0, 0, WHITE); rlDrawRenderBatchActive(); UpdateTextureRec(second, R(0, 0, 8, 8), tile.data); '
    'DrawTexture(second, 16, 16, WHITE); EndTextureMode(); DrawTextureRec(copy.texture, R(0, 0, 32, -32), V2(140, 290), WHITE);',
    # A texture read back once drawn and updated (raylib's LoadImageFromTexture; helix-ray's answers after the frame, its update in it),
    # made a texture again and drawn.
    {'c': 'if (frame == 1) readBack = LoadTextureFromImage(LoadImageFromTexture(patched)); if (readBack.id > 0) DrawTexture(readBack, 440, 290, WHITE);',
     'hx': 'if (frame == 0) LoadImageFromTextureAsync(patched, image -> readBack = LoadTextureFromImage(image)); '
           'if (readBack != null) DrawTexture(readBack, 440, 290, WHITE);'},
]
