"""يضبط مشروع أندرويد المُولَّد: الأذونات واسم التطبيق وخدمة التعرف على الصوت،
والتوقيع بمفتاح ثابت (لازم عشان التحديثات تتثبت فوق النسخة القديمة من غير ما تمسحها)."""
import re, pathlib, shutil, sys

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
x = m.read_text(encoding='utf-8')
perms = ('    <uses-permission android:name="android.permission.INTERNET"/>\n'
         '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'
         '    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n')
if 'RECORD_AUDIO' not in x:
    x = x.replace('<application', perms + '    <application', 1)
x = re.sub(r'android:label="[^"]*"', 'android:label="سند"', x, count=1)
intent = ('        <intent>\n'
          '            <action android:name="android.speech.RecognitionService" />\n'
          '        </intent>\n'
          '        <intent>\n'
          '            <action android:name="android.intent.action.TTS_SERVICE" />\n'
          '        </intent>\n')
if 'RecognitionService' not in x:
    if '<queries>' in x:
        x = x.replace('<queries>', '<queries>\n' + intent, 1)
    else:
        x = x.replace('</manifest>', '    <queries>\n' + intent + '    </queries>\n</manifest>')
m.write_text(x, encoding='utf-8')
print(x)

# مفتاح التوقيع الثابت: كل نسخة لازم تتوقّع بنفس المفتاح، وإلا أندرويد يرفض يثبّت التحديث فوق القديم.
# المفتاح مش في الريبو (الريبو عام): الـ workflow بيفكّه من GitHub Secrets في android-signing/ قبل السكريبت ده
import os
if not pathlib.Path('android-signing/almohafez.keystore').exists() or not os.environ.get('KEYSTORE_PASSWORD'):
    sys.exit('ERROR: signing key missing — add ANDROID_KEYSTORE_B64 and ANDROID_KEYSTORE_PASSWORD in Settings > Secrets and variables > Actions')
shutil.copy('android-signing/almohafez.keystore', 'android/app/almohafez.keystore')
signed = False
for name in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    p = pathlib.Path(name)
    if not p.exists():
        continue
    g = p.read_text(encoding='utf-8')
    g = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', g)
    g = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', g)
    if name.endswith('.kts'):
        block = (
            '    signingConfigs {\n'
            '        create("release") {\n'
            '            storeFile = file("almohafez.keystore")\n'
            '            storePassword = System.getenv("KEYSTORE_PASSWORD")\n'
            '            keyAlias = "almohafez"\n'
            '            keyPassword = System.getenv("KEYSTORE_PASSWORD")\n'
            '        }\n'
            '    }\n\n')
        g = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', g)
    else:
        block = (
            '    signingConfigs {\n'
            '        release {\n'
            "            storeFile file('almohafez.keystore')\n"
            '            storePassword System.getenv("KEYSTORE_PASSWORD")\n'
            "            keyAlias 'almohafez'\n"
            '            keyPassword System.getenv("KEYSTORE_PASSWORD")\n'
            '        }\n'
            '    }\n\n')
        g = re.sub(r'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release', g)
    # حجم أصغر: معالجات ARM بس (كل الموبايلات تقريبًا)، ومكتبات النظام مضغوطة جوّه الـ APK
    if 'abiFilters' not in g:
        if name.endswith('.kts'):
            g = re.sub(r'(defaultConfig\s*\{)', r'\1\n        ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a") }', g, count=1)
            g = re.sub(r'(\n\s*buildTypes\s*\{)', '\n    packaging {\n        jniLibs { useLegacyPackaging = true }\n    }\n' + r'\1', g, count=1)
        else:
            g = re.sub(r'(defaultConfig\s*\{)', r"\1\n        ndk { abiFilters 'armeabi-v7a', 'arm64-v8a' }", g, count=1)
            g = re.sub(r'(\n\s*buildTypes\s*\{)', '\n    packagingOptions {\n        jniLibs { useLegacyPackaging true }\n    }\n' + r'\1', g, count=1)
    if 'almohafez.keystore' not in g:
        g = re.sub(r'(\n\s*buildTypes\s*\{)', '\n' + block.rstrip('\n') + r'\1', g, count=1)
    p.write_text(g, encoding='utf-8')
    print('patched', name)
    print(g)
    signed = 'almohafez.keystore' in g and ('getByName("release")' in g or 'signingConfigs.release' in g)
if not signed:
    sys.exit('ERROR: release signing was not applied — refusing to build an unsigned/debug-signed APK')
