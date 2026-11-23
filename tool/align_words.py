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


def local(S, T):
    """محاذاة محلية (Smith-Waterman) لكلمات مقطع داخل نافذة من التفريغ: (بداية، نهاية، عدد المتطابق)."""
    n, m = len(S), len(T)
    if n == 0 or m == 0:
        return None
    H = np.zeros((n + 1, m + 1), dtype=np.float32)
    B = np.zeros((n + 1, m + 1), dtype=np.int8)
    best, bi, bj = 0.0, 0, 0
    for i in range(1, n + 1):
        si = S[i - 1]
        for j in range(1, m + 1):
            c = sim(si, T[j - 1])
            d = H[i - 1, j - 1] + (2.0 if c == 0 else (1.0 if c < 1 else -1.0))
            u = H[i - 1, j] - 0.8
            l = H[i, j - 1] - 0.8
            v = max(0.0, d, u, l)
            H[i, j] = v
            B[i, j] = 0 if v == 0 else (1 if v == d else (2 if v == u else 3))
            if v > best:
                best, bi, bj = v, i, j
    if best <= 0:
        return None
    i, j, nm, j1 = bi, bj, 0, bj - 1
    j0 = j1
    while i > 0 and j > 0 and B[i, j] != 0:
        k = B[i, j]
        if k == 1:
            if sim(S[i - 1], T[j - 1]) < 1.0:
                nm += 1
            j0 = j - 1
            i -= 1; j -= 1
        elif k == 2:
            i -= 1
        else:
            j -= 1
    return j0, j1, nm


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
    global susp, missing, START
    import time
    START = time.time()
    susp, missing = [], []
    # تحديد كل ملف صوت تبع أنهي نص: أكبر تداخل في الكلمات (كل نص لملف واحد)
    from collections import Counter
    sc = {f['file']: Counter(sum((words_of(x['text']) for x in f['segments']), [])) for f in scripts}
    pairs = []
    for k, wav in enumerate(wavs, 1):
        Tw = Counter(f for f in (fold(w[2]) for w in json.load(open(os.path.join(wdir, f'part{k}.words.json'), encoding='utf-8'))) if f)
        for f in scripts:
            inter = sum((Tw & sc[f['file']]).values())
            pairs.append((inter / max(1, sum(sc[f['file']].values())), k, f['file']))
    assign, used = {}, set()
    for score, k, fn in sorted(pairs, reverse=True):
        if k in assign or fn in used: continue
        assign[k] = next(f for f in scripts if f['file'] == fn); used.add(fn)
    if len(sys.argv) > 1 and os.environ.get('ONLY'):
        only = int(os.environ['ONLY'])
    else:
        only = None
    for k, wav in enumerate(wavs, 1):
        if only and k != only: continue
        W = json.load(open(os.path.join(wdir, f'part{k}.words.json'), encoding='utf-8'))
        T = [fold(w[2]) for w in W]
        keep = [i for i, t in enumerate(T) if t]
        W = [W[i] for i in keep]; T = [T[i] for i in keep]
        best = assign[k]
        segs = best['segments']
        sil = silences(wav)
        dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', wav], capture_output=True, text=True).stdout)
        pos, bad, ok = 0, 0, 0
        for si, s in enumerate(segs):
            S = words_of(s['text'])
            L = len(S)
            win = T[pos:pos + (60 if L < 4 else 900)]
            r = local(S, win)
            if r is None:
                cov = 0
            else:
                j0, j1, nm = r
                cov = nm / max(1, L)
            need = 1.0 if L <= 2 else (0.75 if L <= 5 else 0.55)
            if cov < need:
                bad += 1
                susp.append((os.path.basename(wav)[-8:], best['file'], si, round(cov, 2), s['path'], s['text'][:60]))
                missing.append(s)
                out = os.path.join(ROOT, s['path'])
                pass
                continue
            a_t, b_t = W[pos + j0][0], W[pos + j1][1]
            pos = pos + j1 + 1
            # القص عند السكتات المحيطة
            before = [(e, st) for st, e in sil if e <= a_t + 0.15 and e >= a_t - 0.8]
            a_c = (max(before)[0] + max(before)[1]) / 2 if before else max(0, a_t - 0.12)
            a_c = max(a_c, a_t - 0.5)
            after = [(st, e) for st, e in sil if st >= b_t - 0.15 and st <= b_t + 0.9]
            b_c = min(after)[0] + 0.12 if after else b_t + 0.15
            ok += 1
            out = os.path.join(ROOT, s['path'])
            os.makedirs(os.path.dirname(out), exist_ok=True)
            subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-ss', f'{a_c:.3f}', '-to', f'{min(dur, b_c):.3f}', '-i', wav,
                            '-af', 'silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,afade=t=in:d=0.02',
                            '-ac', '1', '-ar', '24000', '-b:a', '40k', out], check=True)
        matched = ok
        S = segs
        report.append((os.path.basename(wav), best['file'], len(segs), f'ok {ok}', f'missing {bad}'))
        print(*report[-1], flush=True)
    json.dump(susp, open('/tmp/suspicious.json', 'w'), ensure_ascii=False, indent=0)
    json.dump([{'path': m['path'], 'text': m['text']} for m in missing], open('/tmp/missing_segments.json', 'w'), ensure_ascii=False, indent=0)
    return report


if __name__ == '__main__':
    main()
