"""rlgl_62: raylib 6.2's rlgl, those calls helix-ray takes from 6.2, read back from rlgl's batch against helix-ray's frame. One list for
both sides (shared/gen.py's syntax): tex and tex2 are textures, tri, quad and seg add a triangle's, a quad's and a line's vertices at an x,
drawn prints each vertex drawn since the last with its draw call's texture, and polygons GL's polygon mode, all in ref.c.in and
RlglBits.hx.in. Each case starts on a new draw call, RL_QUADS with the white texture, as each drawn flushes the batch. Each fix has a
case built from the input that showed its bug in raylib 5.5."""

CASES = [
    # rlSetTexture then a change of mode: the texture is kept (5.5 drew the triangles untextured).
    'rlSetTexture(tex.id); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlSetTexture(0); drawn("trianglestextured");',
    'rlSetTexture(tex.id); rlBegin(RL_LINES); seg(0); rlEnd(); rlSetTexture(0); drawn("linestextured");',
    'rlSetTexture(tex.id); rlBegin(RL_QUADS); quad(0); rlEnd(); rlSetTexture(0); drawn("quadstextured");',
    # A second change of mode without another rlSetTexture draws with the white texture.
    'rlSetTexture(tex.id); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlBegin(RL_LINES); seg(2); rlEnd(); rlSetTexture(0); drawn("secondmode");',
    'rlSetTexture(tex.id); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlBegin(RL_LINES); seg(2); rlEnd(); rlBegin(RL_TRIANGLES); tri(4); rlEnd(); '
    'rlSetTexture(0); drawn("thirdmode");',
    # The same mode again keeps the draw call and its texture.
    'rlSetTexture(tex.id); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlBegin(RL_TRIANGLES); tri(2); rlEnd(); rlSetTexture(0); drawn("samemode");',
    # rlSetTexture(0) leaves the vertices after it with the draw call's texture, until the next change of mode.
    'rlSetTexture(tex.id); rlBegin(RL_QUADS); quad(0); rlEnd(); rlSetTexture(0); rlBegin(RL_QUADS); quad(2); rlEnd(); drawn("zerosamemode");',
    'rlSetTexture(tex.id); rlBegin(RL_QUADS); quad(0); rlEnd(); rlSetTexture(0); rlBegin(RL_TRIANGLES); tri(2); rlEnd(); drawn("zeronewmode");',
    # Another texture in the same mode, and one set inside rlBegin and rlEnd.
    'rlSetTexture(tex.id); rlBegin(RL_QUADS); quad(0); rlEnd(); rlSetTexture(tex2.id); rlBegin(RL_QUADS); quad(2); rlEnd(); rlSetTexture(0); '
    'drawn("switch");',
    'rlBegin(RL_TRIANGLES); tri(0); rlSetTexture(tex2.id); tri(2); rlEnd(); rlSetTexture(0); drawn("inside");',
    # Nothing set: the white texture in every mode.
    'rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlBegin(RL_LINES); seg(2); rlEnd(); rlBegin(RL_QUADS); quad(4); rlEnd(); drawn("untextured");',
    # rlSetTexture before the first change of mode of a pair, the second without: the first's texture, then white.
    'rlSetTexture(tex2.id); rlBegin(RL_LINES); seg(0); rlEnd(); rlBegin(RL_QUADS); quad(2); rlEnd(); rlSetTexture(0); drawn("pair");',
    # rlPushMatrix past its 32: the 33rd saves nothing and changes nothing (5.5 wrote past the stack), so 32 pops end the transform.
    {'c': 'for (int i = 0; i < 33; i++) rlPushMatrix(); rlTranslatef(1, 2, 3); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); '
          'for (int i = 0; i < 32; i++) rlPopMatrix(); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlPopMatrix(); rlBegin(RL_TRIANGLES); tri(5); rlEnd(); '
          'drawn("overflow");',
     'hx': 'for (i in 0...33) rlPushMatrix(); rlTranslatef(1, 2, 3); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); '
           'for (i in 0...32) rlPopMatrix(); rlBegin(RL_TRIANGLES); tri(0); rlEnd(); rlPopMatrix(); rlBegin(RL_TRIANGLES); tri(5); rlEnd(); '
           'drawn("overflow");'},
    # 6.2's point calls: the size is 1 whatever is set, as on GL 3.3; ending point mode ends wire mode.
    'rlSetPointSize(5); num("pointsize", rlGetPointSize());',
    'polygons("polygonsfirst"); rlEnableWireMode(); polygons("polygonswire"); rlDisablePointMode(); polygons("polygonspointoff");',
]
