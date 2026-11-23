"""تقطيع تسجيلات الصوت على المقاطع بدقة باستخدام تفريغ Whisper (توقيت كل كلمة).

الاستخدام: python3 tool/align_words.py <dir-with-partN.words.json> <wav1> ... <wavN>
- بيعرف كل ملف صوت تبع أنهي ملف نص (بمقارنة الكلام)
- بيحاذي كلمات النص بكلمات التفريغ، وبيقطع عند أقرب سكتة لحدود كل مقطع
- بيصدّر mp3 لكل مقطع في المسار المكتوب في tool/audio_index.json
"""
import json, os, re, subprocess, sys
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDX = json.load(open(os.path.join(ROOT, 'tool/audio_index.json'), encoding='utf-8'))
LET = 'ءابتثجحخدذرزسشصضطظعغفقكلمنهوي'
MAP = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي'}


def fold(w):
    return ''.join(c for c in (MAP.get(ch, ch) for ch in w) if c in LET)


def words_of(text):
    return [f for f in (fold(w) for w in re.split(r'\s+', text)) if f]


def sim(a, b):
    if a == b:
        return 0.0
    if not a or not b:
        return 1.0
    # تشابه تقريبي سريع: بادئة مشتركة + طول
    if a[:3] == b[:3] and abs(len(a) - len(b)) <= 2:
        return 0.35
    sa, sb = set(a), set(b)
    j = len(sa & sb) / len(sa | sb)
    return 0.6 if j >= 0.7 else 1.0


def align(S, T, band=600):
    """محاذاة كلمات النص S بكلمات التفريغ T. بيرجع لكل i في S أقرب j في T (أو -1)."""
    n, m = len(S), len(T)
    INF = 1e9
    dp = np.full((n + 1, m + 1), INF, dtype=np.float32)
    bt = np.zeros((n + 1, m + 1), dtype=np.int8)
    dp[0, :] = np.arange(m + 1) * 0.6
    dp[:, 0] = np.arange(n + 1) * 1.0
    for i in range(1, n + 1):
        c = int(i * m / n)
        lo, hi = max(1, c - band), min(m, c + band)
        si = S[i - 1]
        for j in range(lo, hi + 1):
            best = dp[i - 1, j - 1] + sim(si, T[j - 1]); k = 1
            v = dp[i - 1, j] + 1.0
            if v < best: best, k = v, 2
            v = dp[i, j - 1] + 0.6
            if v < best: best, k = v, 3
            dp[i, j] = best; bt[i, j] = k
    # أحسن نهاية
    j = int(np.argmin(dp[n, :]))
    i = n
    match = [-1] * n
    while i > 0 and j > 0:
        k = bt[i, j]
        if k == 1:
            if sim(S[i - 1], T[j - 1]) < 1.0:
                match[i - 1] = j - 1
            i -= 1; j -= 1
        elif k == 2:
            i -= 1
        elif k == 3:
            j -= 1
        else:
            break
    return match


def silences(wav, noise='-38dB', d=0.12):
    out = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', wav, '-af', f'silencedetect=noise={noise}:d={d}', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    st = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', out)]
    en = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', out)]
    return list(zip(st, en))


def main():
    wdir = sys.argv[1]
    wavs = sys.argv[2:]
    scripts = [f for f in IDX['files'] if f['file'].startswith('سند_صوت_')]
    report = []
    for k, wav in enumerate(wavs, 1):
        W = json.load(open(os.path.join(wdir, f'part{k}.words.json'), encoding='utf-8'))
        T = [fold(w[2]) for w in W]
        keep = [i for i, t in enumerate(T) if t]
        W = [W[i] for i in keep]; T = [T[i] for i in keep]
        head = set(T[:80])
        best = max(scripts, key=lambda f: len(head & set(sum((words_of(s['text']) for s in f['segments'][:12]), []))))
        segs = best['segments']
        S, owner = [], []
        for si, s in enumerate(segs):
            for w in words_of(s['text']):
                S.append(w); owner.append(si)
        match = align(S, T)
        matched = sum(1 for x in match if x >= 0)
        sil = silences(wav)
        dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', wav], capture_output=True, text=True).stdout)
        # بداية كل مقطع = بداية أول كلمة متطابقة فيه
        starts = []
        for si in range(len(segs)):
            idxs = [i for i, o in enumerate(owner) if o == si]
            js = [match[i] for i in idxs if match[i] >= 0]
            starts.append(W[min(js)][0] if js else None)
        ends = []
        for si in range(len(segs)):
            idxs = [i for i, o in enumerate(owner) if o == si]
            js = [match[i] for i in idxs if match[i] >= 0]
            ends.append(W[max(js)][1] if js else None)
        # حدود القطع: سكتة بين نهاية المقطع وبداية اللي بعده
        cuts = [0.0]
        for si in range(1, len(segs)):
            a = ends[si - 1]; b = starts[si]
            if a is None or b is None:
                cuts.append(None); continue
            lo, hi = min(a, b) - 0.4, max(a, b) + 0.4
            cand = [(e - s, (s + e) / 2) for s, e in sil if e > lo and s < hi]
            cuts.append(max(cand)[1] if cand else (a + b) / 2)
        cuts.append(dur)
        # الحدود المفقودة: تقسيم بالتناسب مع عدد الحروف
        for si in range(1, len(cuts) - 1):
            if cuts[si] is None:
                p = next(x for x in range(si - 1, -1, -1) if cuts[x] is not None)
                q = next(x for x in range(si + 1, len(cuts)) if cuts[x] is not None)
                L = [len(segs[x]['text']) for x in range(p, q)]
                cuts[si] = cuts[p] + (cuts[q] - cuts[p]) * sum(L[:si - p]) / sum(L)
        bad = 0
        for si, s in enumerate(segs):
            a, b = cuts[si], cuts[si + 1]
            rate = len(s['text']) / max(0.1, b - a)
            if rate < 6 or rate > 30 or starts[si] is None:
                bad += 1
            out = os.path.join(ROOT, s['path'])
            os.makedirs(os.path.dirname(out), exist_ok=True)
            subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-ss', f'{max(0, a - 0.05):.3f}', '-to', f'{b + 0.05:.3f}', '-i', wav,
                            '-af', 'silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,afade=t=in:d=0.02',
                            '-ac', '1', '-ar', '24000', '-b:a', '48k', out], check=True)
        report.append((os.path.basename(wav), best['file'], len(segs), f'{matched}/{len(S)} words', f'suspicious {bad}'))
        print(*report[-1], flush=True)
    return report


if __name__ == '__main__':
    main()
