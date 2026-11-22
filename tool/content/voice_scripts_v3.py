"""يولّد نصوص الصوت الناقصة من محتوى التطبيق الحالي (ملفات ≤ ٢٠ ألف حرف)،
ويحدّث tool/audio_index.json بالمسار المقابل لكل مقطع عشان التقطيع بعد التسجيل يبقى تلقائي."""
import json, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = sys.argv[1] if len(sys.argv) > 1 else '/tmp/voice_v3'
LIMIT = 20000
SEP = '\n\n…\n\n'
os.makedirs(OUT, exist_ok=True)
A = lambda p: os.path.join(ROOT, p)
def have(path):
    return os.path.exists(A(path))

def clean(t):
    t = re.sub(r'\s+', ' ', t).strip()
    return t

# ١) عبارات التفاعل من voice_lines.dart
src = open(A('lib/data/voice_lines.dart'), encoding='utf-8').read()
voice = []
for key, body in re.findall(r"'([a-z_]+)': \[(.*?)\n  \]", src, re.S):
    lines = re.findall(r"'((?:[^'\\]|\\.)*)'", body)
    for i, line in enumerate(lines, 1):
        path = f'assets/audio/voice/{key}_{i}.mp3'
        if key == 'welcome' or not have(path):
            voice.append((path, clean(line)))

tj = json.load(open(A('assets/quran/tajweed_course.json'), encoding='utf-8'))['chapters']
lib = json.load(open(A('assets/quran/library.json'), encoding='utf-8'))['categories']
def lessons(units):
    segs = []
    for u in units:
        for l in u['lessons']:
            for i, p in enumerate(l.get('paras', []), 1):
                path = f"assets/audio/lessons/{l['id']}_{i}.mp3"
                if not have(path): segs.append((path, clean(p)))
    return segs
def quizzes(units):
    segs = []
    for u in units:
        for l in u['lessons']:
            for k, q in enumerate(l.get('quiz', []), 1):
                for suf, txt in (('q', q.get('q', '')), ('w', q.get('why', ''))):
                    path = f"assets/audio/quiz/{l['id']}_{k}_{suf}.mp3"
                    if txt and not have(path): segs.append((path, clean(txt)))
    return segs
hb = json.load(open(A('assets/quran/hadith.json'), encoding='utf-8'))['books']
def hadith(book_ids):
    segs = []
    for b in hb:
        if b['id'] not in book_ids: continue
        for sec in b['sections']:
            for it in sec['items']:
                base = f"assets/audio/hadith/{b['id']}_{it['n']}"
                if not have(base + '.mp3'): segs.append((base + '.mp3', clean(it['x'])))
                if it.get('s') and not have(base + '_s.mp3'):
                    segs.append((base + '_s.mp3', clean(f"{it.get('t') or ''}. {it['s']}".lstrip('. '))))
    return segs

groups = [
    ('10', 'عبارات_التفاعل', 'عبارات التفاعل والتشجيع', voice),
    ('11', 'دروس_التجويد', 'شرح دروس التجويد', lessons(tj)),
    ('12', 'أسئلة_التجويد', 'أسئلة التجويد وتوضيحاتها', quizzes(tj)),
    ('13', 'دروس_المكتبة', 'شرح دروس المكتبة', lessons(lib)),
    ('14', 'أسئلة_المكتبة', 'أسئلة المكتبة وتوضيحاتها', quizzes(lib)),
    ('15', 'أحاديث_كل_مسلم', 'أحاديث يحتاجها كل مسلم وشرحها', hadith({'essential'})),
    ('16', 'الأربعون_النووية', 'الأربعون النووية وشرحها', hadith({'nawawi'})),
    ('17', 'الأحاديث_القدسية', 'الأربعون القدسية وشرحها', hadith({'qudsi'})),
]

idx_path = A('tool/audio_index.json')
idx = json.load(open(idx_path, encoding='utf-8'))
idx['files'] = [f for f in idx['files'] if not f['file'].startswith('سند_صوت_') and not re.match(r'^1[0-9]-', f['file'])]
summary = []
flat = [(title, path, text) for num, slug, title, segs in groups for path, text in segs]
parts, cur, size = [], [], 0
for title, path, text in flat:
    add = len(text) + (len(SEP) if cur else 0)
    if cur and size + add > LIMIT:
        parts.append(cur); cur, size = [], 0; add = len(text)
    cur.append((title, path, text)); size += add
if cur: parts.append(cur)
for i, part in enumerate(parts, 1):
    titles = list(dict.fromkeys(t for t, _, _ in part))
    name = f'سند_صوت_{i:02d}.txt'
    body = SEP.join(t for _, _, t in part)
    assert len(body) <= LIMIT, (name, len(body))
    open(os.path.join(OUT, name), 'w', encoding='utf-8').write(body + '\n')
    idx['files'].append({'file': name, 'title': ' + '.join(titles), 'segments': [{'path': p, 'text': t} for _, p, t in part]})
    summary.append((name, len(part), len(body), ' + '.join(titles)))
json.dump(idx, open(idx_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for s in summary: print(*s)
print('files', len(summary), 'segments', sum(s[1] for s in summary), 'chars', sum(s[2] for s in summary))
