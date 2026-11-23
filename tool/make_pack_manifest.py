"""يولّد pack/manifest.json لحزمة الصوت على فرع audio-work (التطبيق بيحمّل الناقص بس)."""
import hashlib, json, os, sys
root = sys.argv[1]  # مسار pack/
files = {}
for d, _, fs in os.walk(os.path.join(root, 'assets')):
    for f in sorted(fs):
        p = os.path.join(d, f)
        files[os.path.relpath(p, root)] = [os.path.getsize(p), hashlib.md5(open(p, 'rb').read()).hexdigest()[:10]]
total = sum(v[0] for v in files.values())
json.dump({'version': 1, 'count': len(files), 'bytes': total, 'files': files}, open(os.path.join(root, 'manifest.json'), 'w'), ensure_ascii=False, separators=(',', ':'))
print(len(files), 'files', total, 'bytes')
