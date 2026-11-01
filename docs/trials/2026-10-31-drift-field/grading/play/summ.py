import json,sys
for p in sys.argv[1:]:
  d=json.load(open(p)); print('==',p, d.get('error','')[:300])
  for k,v in (d.get('result') or {}).items():
    print(' ',k, v if k=='errors' else {kk:v.get(kk) for kk in ('nRocks','nCrystals','sidesOk','minCrystalRockGap','text','textAfter','error') if kk in v})
