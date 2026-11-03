"""text_62: raylib 6.2's text and codepoint functions, those helix-raylib takes from 6.2 (its fixes), against helix-raylib's. One list for
both sides (shared/gen.py's syntax): rep(n, piece) makes long text, NULL is null, font the default font, and split, codepoints and
codepoint print what their functions give, all in ref.c.in and TextBits.hx.in. Each fix has a case built
from the input that showed its bug in raylib 5.5."""


def strings(*items):
    """A list of texts, as C and Haxe write it."""
    return {'c': '(char *[]){ ' + ', '.join(items) + ' }', 'hx': '[' + ', '.join(items) + ']'}


def with_list(template, listed):
    """A case whose statements hold a list written apart in C and Haxe, at @L@."""
    return {'c': template.replace('@L@', listed['c']), 'hx': template.replace('@L@', listed['hx'])}


CASES = [
    # TextFormat: a null format gives "" (5.5 passed it to vsnprintf); past 1023 bytes, cut to 1020 and "...".
    'str("format", TextFormat("%d|%5.2f|%-4s|%x|%X|%o|%c|%%|%03i|%+d|%e|%g", 42, 3.14159, "hi", 255, 255, 8, 65, 7, 5, 12345.678, 0.0001));',
    'str("formatnull", TextFormat(NULL));',
    'str("formatlong", TextFormat("%s", rep(1100, "a")));',
    'str("formatcut", TextFormat("x%s", rep(600, "é")));',
    'str("formatfit", TextFormat("%s", rep(1023, "b")));',
    # TextSubtext: a negative position gives "" (5.5 read before the text), a length past the end is clamped, at most 1023 bytes.
    'str("subtext", TextSubtext("héllo", 1, 2));',
    'str("subtextcut", TextSubtext("héllo", 0, 2));',
    'str("subtextnegative", TextSubtext("hello", -1, 3));',
    'str("subtextzero", TextSubtext("hello", 2, 0));',
    'str("subtextpast", TextSubtext("hello", 5, 1));',
    'str("subtextlong", TextSubtext("hello", 3, 100));',
    'str("subtextnull", TextSubtext(NULL, 0, 3));',
    'str("subtextbig", TextSubtext(rep(1500, "ab"), 1, 2000));',
    # TextInsert: 5.5 copied from the wrong places; 6.2 clamps the position and refuses a result of 1023 bytes or more.
    'str("insert", TextInsert("hello", " world", 5));',
    'str("insertstart", TextInsert("hello", "X", 0));',
    'str("insertmiddle", TextInsert("hello", "XY", 2));',
    'str("insertcut", TextInsert("héllo", "X", 2));',
    'str("insertpast", TextInsert("ab", "X", 10));',
    'str("insertnegative", TextInsert("ab", "X", -1));',
    'str("insertnull", TextInsert(NULL, "X", 0));',
    'str("insertnullinsert", TextInsert("ab", NULL, 0));',
    'str("insertfit", TextInsert(rep(1000, "a"), rep(22, "b"), 500));',
    'str("insertfull", TextInsert(rep(1000, "a"), rep(23, "b"), 500));',
    # TextJoin: a text that would pass 1023 bytes is left out, the ones after still joined (5.5 could write past its buffer).
    with_list('str("join", TextJoin(@L@, 3, ", "));', strings('"a"', '"b"', '"c"')),
    with_list('str("joinnull", TextJoin(@L@, 3, "-"));', strings('"a"', 'NULL', '"c"')),
    with_list('str("joinnodelimiter", TextJoin(@L@, 3, NULL));', strings('"a"', '"b"', '"c"')),
    with_list('str("joinnone", TextJoin(@L@, 0, ","));', strings('"a"')),
    with_list('str("joinskip", TextJoin(@L@, 3, "--"));', strings('rep(400, "a")', 'rep(400, "b")', 'rep(400, "c")')),
    with_list('str("joinfit", TextJoin(@L@, 3, "+"));', strings('rep(1000, "a")', '"b"', '"c"')),
    # TextSplit: one byte delimits, at most 1023 bytes read and 128 pieces (5.5 read a byte past its buffer).
    'split("split", "a,b,,c", 44);',
    'split("splitedges", ",", 44);',
    'split("splitempty", "", 44);',
    'split("splitnull", NULL, 44);',
    'split("splitbyte", "aébéc", 195);',
    'split("splitmany", rep(200, "x,"), 44);',
    'split("splitlong", rep(1500, "y"), 44);',
    'split("splitlonger", rep(10, TextFormat("%s,", rep(150, "w"))), 44);',
    # TextFindIndex: null text gives -1 (5.5 crashed).
    'num("find", TextFindIndex("héllo wörld", "wö"));',
    'num("findnone", TextFindIndex("hello", "xyz"));',
    'num("findempty", TextFindIndex("hello", ""));',
    'num("findnull", TextFindIndex(NULL, "a"));',
    # TextToPascal and TextToCamel: each run of underscores dropped (5.5 skipped a character after one and ended the text at one not
    # followed by a to z).
    'str("pascal", TextToPascal("hello_world"));',
    'str("pascalruns", TextToPascal("__a__b__"));',
    'str("pascalend", TextToPascal("hello_"));',
    'str("pascaldigit", TextToPascal("a_1b_c"));',
    'str("pascalcaps", TextToPascal("HELLO_world"));',
    'str("pascalutf8", TextToPascal("é_été"));',
    'str("pascalempty", TextToPascal(""));',
    'str("pascalnull", TextToPascal(NULL));',
    'str("pascallong", TextToPascal(rep(600, "ab_")));',
    'str("camel", TextToCamel("hello_world"));',
    'str("camelfirst", TextToCamel("Hello_World"));',
    'str("camelruns", TextToCamel("x__y___z"));',
    'str("camelend", TextToCamel("a_b_"));',
    'str("camelempty", TextToCamel(""));',
    'str("camelnull", TextToCamel(NULL));',
    # TextToSnake: a space is an underscore, never two together, and capitals in a run are one word (5.5 kept spaces and put an
    # underscore before every capital).
    'str("snake", TextToSnake("helloWorld"));',
    'str("snakepascal", TextToSnake("HelloWorld"));',
    'str("snakespace", TextToSnake("Hello World"));',
    'str("snakeacronym", TextToSnake("HTTPServer"));',
    'str("snakeacronyms", TextToSnake("getHTTPResponseCode"));',
    'str("snakedigit", TextToSnake("Vector2D"));',
    'str("snakealready", TextToSnake("already_Snake"));',
    'str("snakespaces", TextToSnake("  lead  and   trail  "));',
    'str("snakecaps", TextToSnake("ABC"));',
    'str("snakeutf8", TextToSnake("été Fini"));',
    'str("snakeempty", TextToSnake(""));',
    'str("snakenull", TextToSnake(NULL));',
    'str("snakelong", TextToSnake(rep(400, "aB")));',
    # TextToInteger and TextToFloat: null text gives 0 (5.5 crashed).
    'num("integer", TextToInteger("123"));',
    'num("integernegative", TextToInteger("-45"));',
    'num("integerplus", TextToInteger("+7"));',
    'num("integertail", TextToInteger("12abc"));',
    'num("integernone", TextToInteger("abc"));',
    'num("integerspace", TextToInteger(" 5"));',
    'num("integerempty", TextToInteger(""));',
    'num("integernull", TextToInteger(NULL));',
    'num("float", TextToFloat("3.25"));',
    'num("floatnegative", TextToFloat("-0.1"));',
    'num("floatexponent", TextToFloat("1e3"));',
    'num("floatpoint", TextToFloat("+.5"));',
    'num("floatend", TextToFloat("7."));',
    'num("floatlong", TextToFloat("123456.789"));',
    'num("floatnull", TextToFloat(NULL));',
    # The codepoint functions: null text gives '?' and a size of 1, a count of 0, no codepoints (5.5 crashed); the codepoint before
    # starts at a size of 1.
    'codepoint("first", "hé", 0);',
    'codepoint("firsttwo", "éh", 0);',
    'codepoint("firstthree", "→x", 0);',
    'codepoint("firstfour", "\U0001f600", 0);',
    'codepoint("firstempty", "", 0);',
    'codepoint("firstnull", NULL, 0);',
    'codepoint("next", "éh", 1);',
    'codepoint("nextfour", "\U0001f600!", 1);',
    'codepoint("nextempty", "", 1);',
    'codepoint("nextnull", NULL, 1);',
    'codepoint("previous", "hé", 2);',
    'codepoint("previousthree", "a→", 2);',
    'codepoint("previousfour", "a\U0001f600", 2);',
    'codepoint("previousascii", "ab", 2);',
    'codepoint("previousnull", NULL, 2);',
    'num("count", GetCodepointCount("héllo→\U0001f600"));',
    'num("countempty", GetCodepointCount(""));',
    'num("countnull", GetCodepointCount(NULL));',
    'codepoints("codepoints", "héllo→\U0001f600");',
    'codepoints("codepointsempty", "");',
    'codepoints("codepointsnull", NULL);',
    # GetGlyphIndex: a font that isn't valid gives 0 (5.5 read its glyphs); a character the font lacks is its '?'.
    'num("glyph", GetGlyphIndex(font, 65));',
    'num("glyphmissing", GetGlyphIndex(font, 0x4E2D));',
    'num("glyphfirst", GetGlyphIndex(font, 32));',
    {'c': 'num("glyphinvalid", GetGlyphIndex((Font){ 0 }, 65));', 'hx': 'num("glyphinvalid", GetGlyphIndex(new Font(), 65));'},
]
