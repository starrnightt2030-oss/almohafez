"""يضبط مشروع أندرويد المُولَّد: الأذونات واسم التطبيق وخدمة التعرف على الصوت."""
import re, pathlib

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
x = m.read_text(encoding='utf-8')
perms = ('    <uses-permission android:name="android.permission.INTERNET"/>\n'
         '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n')
if 'RECORD_AUDIO' not in x:
    x = x.replace('<application', perms + '    <application', 1)
x = re.sub(r'android:label="[^"]*"', 'android:label="المحفظ"', x, count=1)
intent = ('        <intent>\n'
          '            <action android:name="android.speech.RecognitionService" />\n'
          '        </intent>\n')
if 'RecognitionService' not in x:
    if '<queries>' in x:
        x = x.replace('<queries>', '<queries>\n' + intent, 1)
    else:
        x = x.replace('</manifest>', '    <queries>\n' + intent + '    </queries>\n</manifest>')
m.write_text(x, encoding='utf-8')
print(x)

for name in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    p = pathlib.Path(name)
    if p.exists():
        g = p.read_text(encoding='utf-8')
        g = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', g)
        g = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', g)
        p.write_text(g, encoding='utf-8')
        print('patched', name)
