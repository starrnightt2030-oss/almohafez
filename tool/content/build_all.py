import json,re,copy
from tajweed_course import COURSE
import tajweed_more as TM
from library_content import LIBRARY
import library_more as LM
from essential_hadith import ESSENTIAL
from voice_lines import LINES
A='/home/claude/almohafez/assets/quran/'
old_t={l['id'] for c in COURSE for l in c['lessons']}
old_l={l['id'] for c in LIBRARY for l in c['lessons']}
# ---- tajweed
course=copy.deepcopy(COURSE)
for c in course:
    c['lessons']+=TM.EXTRA.get(c['id'],[])
course+=TM.NEW_CHAPTERS
for c in course:
    c['practice']=[list(r) for r in TM.PRACTICE.get(c['id'],[])]
# ---- library order
lib=copy.deepcopy(LIBRARY)
for c in lib: c['lessons']+=LM.EXTRA.get(c['id'],[])
byid={c['id']:c for c in lib+LM.NEW_CATS}
order=['aqeedah','quran','seerah','taharah','salah','siyam','zakah','hajj','muamalat','family','halal','adab','tazkiyah','adhkar']
lib=[byid[i] for i in order]
for grp in (course,lib):
    ids=set()
    for c in grp:
        for l in c['lessons']:
            assert l['id'] not in ids,l['id']; ids.add(l['id'])
            for q in l['quiz']: assert 0<=q['a']<len(q['o'])
json.dump({'chapters':course},open(A+'tajweed_course.json','w'),ensure_ascii=False,separators=(',',':'))
json.dump({'categories':lib},open(A+'library.json','w'),ensure_ascii=False,separators=(',',':'))
# ---- essential hadith
d=json.load(open('/home/claude/dl/riyad_assalihin.json'))
M=re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ‏]')
def norm(t):
    t=M.sub('',t);t=re.sub('[أإآٱ]','ا',t).replace('ة','ه').replace('ى','ي');return re.sub(r'\s+',' ',t)
def clean(t):
    t=t.replace('‏','').replace('\r','');t=re.sub('[ \t]+',' ',t);t=re.sub(r'\s*\n\s*','\n',t)
    return t.strip().lstrip('-').strip()
pool=[(h,norm(h['arabic'])) for h in d['hadiths']]
secs={};n=0
for q,ti,sec,sh in ESSENTIAL:
    k=norm(q); m=[h for h,t in pool if k in t]
    assert m, q
    n+=1
    secs.setdefault(sec,[]).append({'n':n,'t':ti,'x':clean(m[0]['arabic']),'s':sh})
H=json.load(open(A+'hadith.json'))
H['books']=[b for b in H['books'] if b['id']!='essential']
H['books'].insert(0,{'id':'essential','title':'أحاديث يحتاجها كل مسلم','author':'مختارات من رياض الصالحين',
  'desc':'أهم الأحاديث النبوية التي ينبغي لكل مسلم أن يتعلمها ويعمل بها، مع عنوان وشرح ميسّر لكل حديث.',
  'sections':[{'title':k,'items':v} for k,v in secs.items()]})
json.dump(H,open(A+'hadith.json','w'),ensure_ascii=False,separators=(',',':'))
# ---- supplementary voice scripts (new content only)
SEP='\n\n…\n\n'
idx=json.load(open('/home/claude/almohafez/tool/audio_index.json'))
idx['files']=[f for f in idx['files'] if f['file'][:2] in ('01','02','03','04','05')]
def add(name,title,segs):
    idx['files'].append({'file':name,'title':title,'segments':[{'path':p,'text':x} for p,x in segs]})
    body=SEP.join(x for _,x in segs)
    open('/home/claude/voice_scripts2/'+name,'w').write(body+'\n')
    print(name,len(segs),'segments',len(body.split()),'words')
import os; os.makedirs('/home/claude/voice_scripts2',exist_ok=True)
segs=[]
for c in course:
    for l in c['lessons']:
        if l['id'] in old_t: continue
        for i,p in enumerate(l['paras']): segs.append((f'assets/audio/lessons/{l["id"]}_{i+1}.mp3',p))
add('06_شروحات_التجويد_الإضافية.txt','شروحات التجويد الإضافية',segs)
segs=[]
for c in lib:
    for l in c['lessons']:
        if l['id'] in old_l: continue
        for i,p in enumerate(l['paras']): segs.append((f'assets/audio/lessons/{l["id"]}_{i+1}.mp3',p))
add('07_شروحات_المكتبة_الإضافية.txt','شروحات المكتبة الإضافية',segs)
segs=[]
for grp,old in ((course,old_t),(lib,old_l)):
    for c in grp:
        for l in c['lessons']:
            if l['id'] in old: continue
            for k,q in enumerate(l['quiz']):
                qq=q['q'].rstrip(':')+'؟' if q['q'].endswith(':') else q['q']
                segs.append((f'assets/audio/quiz/{l["id"]}_{k+1}_q.mp3',qq))
                segs.append((f'assets/audio/quiz/{l["id"]}_{k+1}_w.mp3',q['why']))
add('08_أسئلة_إضافية.txt','أسئلة الدروس الإضافية',segs)
segs=[]
for s in H['books'][0]['sections']:
    for it in s['items']:
        segs.append((f'assets/audio/hadith/essential_{it["n"]}.mp3',re.sub(r'\s*\n\s*',' ',it['x'])))
        segs.append((f'assets/audio/hadith/essential_{it["n"]}_s.mp3',f'{it["t"]}. {it["s"]}'))
add('09_أحاديث_كل_مسلم.txt','أحاديث يحتاجها كل مسلم',segs)
json.dump(idx,open('/home/claude/almohafez/tool/audio_index.json','w'),ensure_ascii=False,indent=1)
tl=sum(len(c['lessons']) for c in course); ll=sum(len(c['lessons']) for c in lib)
print('tajweed',len(course),'chapters',tl,'lessons | library',len(lib),'cats',ll,'lessons | essential',n)
