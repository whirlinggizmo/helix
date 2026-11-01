"""Prints each game's results per target, from play/N/*.json."""
import json, sys, os
D = os.path.dirname(os.path.abspath(__file__))

def load(n, tag, t):
    p = f'{D}/{n}/{tag}.{t}.json'
    if not os.path.exists(p): return None
    d = json.load(open(p))
    if d.get('error'): print('   ERROR', tag, t, d['error'][:300])
    return d.get('result')

def fsig(s):
    return (tuple(tuple(r) for r in s['rocks']), tuple(tuple(c) for c in s['crystals']))

def diff(a, b):
    if a is None or b is None: return 'n/a'
    ra, rb = fsig(a), fsig(b)
    if ra == rb: return 'identical'
    md = 0
    if len(ra[0]) == len(rb[0]) and len(ra[1]) == len(rb[1]):
        for x, y in zip(ra[0] + ra[1], rb[0] + rb[1]):
            md = max(md, max(abs(p - q) for p, q in zip(x, y)))
        return f'differ (max coord diff {md:.3g})'
    return f'differ (counts {len(ra[0])}/{len(ra[1])} vs {len(rb[0])}/{len(rb[1])})'

for n in sys.argv[1:] or ['1', '2', '3']:
    print(f'######## game {n}')
    fields = {}
    for t in ('page', 'native'):
        for tag in ('field1', 'field2'):
            r = load(n, tag, t)
            if r: fields[(t, tag)] = r.get('level1')
        fl = load(n, 'flow', t)
        if fl:
            for lv in fl['levels']:
                fields[(t, 'flowL%d' % lv['level'])] = lv['first']
    for k, v in fields.items():
        if v: print('  field', k, {kk: v.get(kk) for kk in ('nRocks', 'nCrystals', 'sidesOk', 'minCrystalRockGap', 'crystalColor')}, 'field', v.get('fieldRect'))
    print('  L1 page run1 vs run2:', diff(fields.get(('page', 'field1')), fields.get(('page', 'field2'))))
    print('  L1 native run1 vs run2:', diff(fields.get(('native', 'field1')), fields.get(('native', 'field2'))))
    print('  L1 page vs native:', diff(fields.get(('page', 'field1')), fields.get(('native', 'field1'))))
    print('  L1 field vs flow L1 (page):', diff(fields.get(('page', 'field1')), fields.get(('page', 'flowL1'))))
    for L in (2, 3):
        print(f'  L{L} page vs native:', diff(fields.get(('page', f'flowL{L}')), fields.get(('native', f'flowL{L}'))))
