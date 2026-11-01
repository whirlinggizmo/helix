"""text_55: raylib 5.5's text and codepoint functions, those helix-ray keeps from 5.5 (TextReplace and LoadUTF8, which 6.2 changed by
choice, and those 6.2 didn't change), against helix-ray's. One list for both sides (shared/gen.py's syntax): NULL is null and size
CodepointToUTF8's out, in ref.c.in and TextBits55.hx.in."""


def ints(*items):
    """A list of ints, as C and Haxe write it."""
    return {'c': '(int[]){ ' + ', '.join(map(str, items)) + ' }', 'hx': '[' + ', '.join(map(str, items)) + ']'}


def with_list(template, listed):
    """A case whose statements hold a list written apart in C and Haxe, at @L@."""
    return {'c': template.replace('@L@', listed['c']), 'hx': template.replace('@L@', listed['hx'])}


CASES = [
    # TextReplace: 5.5's, null when any is null or the text replaced is empty (6.2's gives "", and takes a null replacement as "").
    'str("replace", TextReplace("hello world", "o", "0"));',
    'str("replacelonger", TextReplace("a-b-c", "-", "<->"));',
    'str("replacerun", TextReplace("aaa", "aa", "b"));',
    'str("replacenone", TextReplace("abc", "x", "y"));',
    'str("replaceemptysearch", TextReplace("abc", "", "y"));',
    'str("replacenullby", TextReplace("abc", "b", NULL));',
    'str("replacenulltext", TextReplace(NULL, "b", "c"));',
    'str("replaceutf8", TextReplace("héllo hé", "é", "→"));',
    # LoadUTF8: 5.5's, "" for no codepoints (6.2's gives null).
    with_list('str("utf8", LoadUTF8(@L@, 4));', ints(72, 233, 0x2192, 0x1F600)),
    with_list('str("utf8none", LoadUTF8(@L@, 0));', ints(65)),
    with_list('str("utf8past", LoadUTF8(@L@, 2));', ints(0x110000, 66)),
    'num("length", TextLength("héllo→"));',
    'num("lengthnull", TextLength(NULL));',
    'flag("equal", TextIsEqual("abc", "abc"));',
    'flag("equalnot", TextIsEqual("abc", "abd"));',
    'flag("equalnull", TextIsEqual(NULL, "abc"));',
    'str("upper", TextToUpper("héllo World 1"));',
    'str("uppernull", TextToUpper(NULL));',
    'str("lower", TextToLower("HÉLLO wORLD 1"));',
    'str("lowernull", TextToLower(NULL));',
    {'c': 'str("toutf8", CodepointToUTF8(0x20AC, &size)); num("toutf8size", size);',
     'hx': 'str("toutf8", CodepointToUTF8(0x20AC, size)); num("toutf8size", size[0]);'},
    {'c': 'str("toutf8four", CodepointToUTF8(0x1F600, &size)); num("toutf8foursize", size);',
     'hx': 'str("toutf8four", CodepointToUTF8(0x1F600, size)); num("toutf8foursize", size[0]);'},
    {'c': 'str("toutf8past", CodepointToUTF8(0x110000, &size)); num("toutf8pastsize", size);',
     'hx': 'str("toutf8past", CodepointToUTF8(0x110000, size)); num("toutf8pastsize", size[0]);'},
]
