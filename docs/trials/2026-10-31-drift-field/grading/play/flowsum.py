import json,sys
for p in sys.argv[1:]:
  try: d=json.load(open(p))
  except Exception as e: print(p,'missing'); continue
  print('==',p,(d.get('error') or '')[:400]); r=d.get('result') or {}
  for k,v in r.items():
    if k=='levels':
      for L in v:
        print('  L',L['level'],'gather',L['gather'],'last',L['last'],'check',L['check']['events'],L['check']['mismatches'][:3],'after',L.get('after'),'err',L.get('error'))
        print('     first', {kk:L['first'][kk] for kk in ('nRocks','nCrystals','sidesOk','minCrystalRockGap','text')})
        for t in L.get('then',[]) : print('     then',t)
    elif k=='errors': print('  errors', [e for e in v if '404' not in e], 'n404', sum('404' in e for e in v))
    else: print(' ',k,v)
