"""Writes a suite's two sides from its one list of cases (engines/raylib/parity/README.md): its cases.py's CASES, in a neutral syntax both C and Haxe
read once translated, put into its templates (ref.c.in, or scene.c.in for a pixel suite, and its Haxe harness's <Main>.hx.in) where
@CASES@ stands. Imported by tools/ray_parity.py, which writes them under build/ray-parity, never beside the suite.

A case is a string of statements, written the same for both, or (name, statements) for a drawing whose vertices shape(name) then prints.
The statements use V2(x, y), V3(x, y, z) and R(x, y, w, h) as they are, and the printers shared/parity.h and shared/Parity.hx both have
(mesh, image, hit, flag, num, color, vec2, rect, box, str), and these, which the two write differently:

    PTS(a, b, ...)      a Vector2 array           C (Vector2[]){ a, b }      Haxe [a, b]
    PTS3(a, b, ...)     a Vector3 array           C (Vector3[]){ a, b }      Haxe [a, b]
    NEW(Type, a, b)     a struct                  C ((Type){ a, b })         Haxe new Type(a, b)
    OUT(x)              a pointer to change x     C &x                       Haxe x
    LET(x, Type, e)     a local                   C Type x = e               Haxe var x = e

A case that can't be written once is {'c': ..., 'hx': ...}."""
import importlib.util
from pathlib import Path


def _call(s, word):
    """(start, end, arguments) of the first call word(...) in s, its arguments split at their top-level commas; None if there's none."""
    i = 0
    while True:
        i = s.find(word + '(', i)
        if i < 0:
            return None
        if i == 0 or not (s[i - 1].isalnum() or s[i - 1] == '_'):
            break
        i += 1
    depth, j, parts, start = 0, i + len(word), [], i + len(word) + 1
    while True:
        ch = s[j]
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
            if depth == 0:
                parts.append(s[start:j].strip())
                return i, j + 1, parts
        elif ch == ',' and depth == 1:
            parts.append(s[start:j].strip())
            start = j + 1
        elif ch == '"':
            j = s.index('"', j + 1)
        j += 1


def translate(s, c):
    """s, in the neutral syntax, as C (c) or Haxe."""
    forms = {
        'PTS': lambda a: '(Vector2[]){ ' + ', '.join(a) + ' }' if c else '[' + ', '.join(a) + ']',
        'PTS3': lambda a: '(Vector3[]){ ' + ', '.join(a) + ' }' if c else '[' + ', '.join(a) + ']',
        'NEW': lambda a: f'(({a[0]}){{ {", ".join(a[1:])} }})' if c else f'new {a[0]}({", ".join(a[1:])})',
        'OUT': lambda a: '&' + a[0] if c else a[0],
        'LET': lambda a: f'{a[1]} {a[0]} = {", ".join(a[2:])}' if c else f'var {a[0]} = {", ".join(a[2:])}',
    }
    changed = True
    while changed:
        changed = False
        for word, form in forms.items():
            found = _call(s, word)
            if found:
                start, end, args = found
                s = s[:start] + form([translate(a, c) for a in args]) + s[end:]
                changed = True
    return s


def case(entry, c):
    """One case as C (c) or Haxe statements."""
    if isinstance(entry, dict):
        return entry['c' if c else 'hx']
    if isinstance(entry, tuple):
        name, statements = entry
        return translate(statements, c) + f' shape("{name}");'
    return translate(entry, c)


def cases(suite):
    """The CASES of suite's cases.py."""
    spec = importlib.util.spec_from_file_location(f'parity_{suite.name}_cases', suite / 'cases.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.CASES


def generate(suite, out, c_template, hx_template):
    """Writes suite's C (from c_template, without its .in) and Haxe (from hx_template) into out, each case on its own line; returns their
    paths."""
    listed = cases(suite)
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for template, c, indent in ((c_template, True, '    '), (hx_template, False, '\t\t')):
        source = (suite / template).read_text(encoding='utf-8')
        at = source.index('@CASES@')
        line_start = source.rfind('\n', 0, at) + 1
        indent = source[line_start:at]
        body = ('\n' + indent).join(case(entry, c) for entry in listed)
        path = out / template[:-3]
        path.write_text(source.replace('@CASES@', body), encoding='utf-8')
        written.append(path)
    return written
