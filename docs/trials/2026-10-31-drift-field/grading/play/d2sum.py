import json,sys
for p in sys.argv[1:]:
  d=json.load(open(p)); print('==',p,(d.get('error') or '')[:300]); r=d.get('result') or {}
  for k,v in r.items():
    if isinstance(v,dict) and 'first' in v:
      f=v['first']; print(' ',k,'level',v['level'],'rocks',f['nRocks'],'crystals',f['nCrystals'],'sides',f['sidesOk'],'gap',f['minCrystalRockGap'],'field',f['fieldRect']['w'],f['fieldRect']['h'],'| before:',v['before'][:60])
      if 'end' in v: print('     end',v['end'])
    elif k=='errors': print('  errors',[e for e in v if '404' not in e],'n404',sum('404' in e for e in v))
    else: print(' ',k,v)
  def sig(k):
    f=r.get(k,{}).get('first'); return f and (f['rocks'],f['crystals'])
  print('  custom vs other-seed differ:', sig('title_custom')!=sig('title_other'), '| custom vs custom again same:', sig('title_custom')==sig('title_custom_again'), '| title custom vs play custom same:', sig('title_custom')==sig('play_custom'))
