import json, re, sys
dl = sys.argv[1]; out = sys.argv[2]
names = "الفاتحة البقرة آل_عمران النساء المائدة الأنعام الأعراف الأنفال التوبة يونس هود يوسف الرعد إبراهيم الحجر النحل الإسراء الكهف مريم طه الأنبياء الحج المؤمنون النور الفرقان الشعراء النمل القصص العنكبوت الروم لقمان السجدة الأحزاب سبأ فاطر يس الصافات ص الزمر غافر فصلت الشورى الزخرف الدخان الجاثية الأحقاف محمد الفتح الحجرات ق الذاريات الطور النجم القمر الرحمن الواقعة الحديد المجادلة الحشر الممتحنة الصف الجمعة المنافقون التغابن الطلاق التحريم الملك القلم الحاقة المعارج نوح الجن المزمل المدثر القيامة الإنسان المرسلات النبأ النازعات عبس التكوير الانفطار المطففين الانشقاق البروج الطارق الأعلى الغاشية الفجر البلد الشمس الليل الضحى الشرح التين العلق القدر البينة الزلزلة العاديات القارعة التكاثر العصر الهمزة الفيل قريش الماعون الكوثر الكافرون النصر المسد الإخلاص الفلق الناس".split()
names = [n.replace('_', ' ') for n in names]
assert len(names) == 114, len(names)
info = json.load(open(f'{dl}/info.json'))
u = json.load(open(f'{dl}/ara-quranuthmanihaf.json'))['quran']
s = json.load(open(f'{dl}/ara-quransimple.json'))['quran']
MARKS = re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ]')
def bare(w): return MARKS.sub('', w)
basm = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ '
surahs = [{'n': names[i], 'r': 'مكية' if info['chapters'][i]['revelation'] == 'Mecca' else 'مدنية', 'a': []} for i in range(114)]
mis = 0
for a, b in zip(u, s):
    c, v = a['chapter'], a['verse']
    st = b['text']
    if v == 1 and c not in (1, 9) and st.startswith(basm):
        st = st[len(basm):]
    ut = ' '.join(t for t in a['text'].split() if bare(t))
    st = ' '.join(t for t in st.split() if bare(t))
    if len(ut.split()) != len(st.split()): mis += 1
    surahs[c-1]['a'].append([ut, st])
juz = [[r['start']['chapter'], r['start']['verse']] for r in info['juzs']['references']]
mq = info['maqras']
rub = [[r['start']['chapter'], r['start']['verse']] for r in mq['references']]
json.dump({'s': surahs, 'juz': juz, 'rub': rub}, open(f'{out}/quran.json', 'w'), ensure_ascii=False, separators=(',', ':'))
print('mismatch', mis, 'rub', len(rub))
