import json,re
lines=[l.rstrip('\n') for l in open('luthfi.txt',encoding='utf-8')]
L=[l for l in lines if l.strip() and not l.startswith('#')][:6236]
info=json.load(open('info.json'))
counts=[len(c['verses']) for c in info['chapters']]
refs=[(s+1,a+1) for s in range(114) for a in range(counts[s])]
ann={(x['surah'],x['ayah']):x['annotations'] for x in json.load(open('tajweed.json'))}
q=json.load(open('/home/claude/almohafez/assets/quran/quran.json'))
PM='ۖۗۘۙۚۛۜ۩'
M='ۗۖۘۙۚۛۜ۩'
exp={'hamzat_wasl':'ٱ','qalqalah':'قطبجد','lam_shamsiyyah':'ل','ghunnah':'نم','silent':'۟اويى'}
for r in ('madd_6','madd_2','madd_muttasil','madd_munfasil','madd_246'): exp[r]='اويىٰۦۧٓۥ'
RULES=['hamzat_wasl','silent','lam_shamsiyyah','madd_2','madd_246','madd_muttasil','madd_munfasil','madd_6','ghunnah','qalqalah','ikhfa','ikhfa_shafawi','idghaam_ghunnah','idghaam_no_ghunnah','idghaam_shafawi','idghaam_mutajanisayn','idghaam_mutaqaribayn','iqlab']
basm='بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ '
out=[];mism=0;badA=0;dropped=0
for (s,a),orig in zip(refs,L):
    # build transformed text + map transformed idx -> orig idx
    keep=[True]*len(orig)
    for m in re.finditer(' ['+PM+']',orig):
        keep[m.start()]=keep[m.start()+1]=False
    for i,c in enumerate(orig):
        if c=='ۭ': keep[i]=False
    for m in re.finditer('([ًٌٍ])ۢ(?! ب)',orig):
        keep[m.start()+1]=False
    tmap=[i for i in range(len(orig)) if keep[i]]
    T=''.join(orig[i] for i in tmap)
    an=ann[(s,a)]
    ok_all=all(any(c in exp[x['rule']] for c in T[x['start']:x['end']]) for x in an if x['rule'] in exp)
    if not ok_all: badA+=1
    off=0;text=orig
    if a==1 and s not in (1,9) and orig.startswith('بِسْمِ'):
        p=-1
        for _ in range(4): p=orig.index(' ',p+1)
        off=p+1;text=orig[off:]
    res=[]
    for x in an:
        if x['rule'] not in RULES: continue
        if not ok_all:
            if x['rule'] not in exp or not any(c in exp[x['rule']] for c in T[x['start']:x['end']]): dropped+=1;continue
        st=tmap[x['start']]; en=tmap[x['end']-1]+1 if x['end']-1<len(tmap) else len(orig)
        st-=off;en-=off
        if st<0: continue
        res.append([RULES.index(x['rule']),st,en])
    words=[w for w in text.split(' ') if w and not all(c in PM for c in w)]
    simple=q['s'][s-1]['a'][a-1][1].split(' ')
    if len(words)!=len(simple): mism+=1
    out.append([text,res])
print('bad ayahs',badA,'dropped',dropped,'word mismatch',mism)
json.dump({'rules':RULES,'a':out},open('/home/claude/almohafez/assets/quran/tajweed.json','w'),ensure_ascii=False,separators=(',',':'))
