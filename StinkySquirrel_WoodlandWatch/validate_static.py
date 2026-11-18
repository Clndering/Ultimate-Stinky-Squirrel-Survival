"""Static integrity tests only; does not execute Godot or validate gameplay parity."""
from pathlib import Path
import json, base64,hashlib,re, random,math,zipfile,wave
root=Path(__file__).resolve().parent
s=(root/'reference/ORIGINAL_LATEST_UNMODIFIED.html').read_text()
assert hashlib.sha256(s.encode()).hexdigest()==(root/'reference/sha256.txt').read_text().split()[0]
parser=json.JSONDecoder()
files={}
for key,folder in [('const ART_DATA=','art'),('Object.assign(ART_DATA,','art'),('const ORIGINAL_AUDIO=','audio')]:
    i=s.index(key)+len(key); obj,_=parser.raw_decode(s[i:])
    for name,url in obj.items():
        ext='png' if folder=='art' else 'wav'
        expected=base64.b64decode(url.split(',',1)[1])
        path=root/folder/(name+'.'+ext)
        assert path.exists(),str(path)
        assert path.read_bytes()==expected,name
        files[name]=path
assert len(list((root/'art').glob('*.png')))==28
assert (root/'art/xp.png').exists()
assert len(list((root/'art/encyclopedia').glob('*.png'))) >= 19
assert len(list((root/'art/encyclopedia/upgrades').glob('*.png'))) >= 39
with wave.open(str(root/'audio/woodland_boss_assault.wav'), 'rb') as soundtrack:
    assert soundtrack.getnframes() / soundtrack.getframerate() >= 20
assert (root/'audio/boss_theme.ogg').exists()
for filename in ['scripts/Main.gd','scripts/World.gd','scripts/Campaign.gd','scripts/BossPatterns.gd']:
    source=(root/filename).read_text()
    found=re.findall(r'^func\s+(\w+)\(',source,re.M)
    assert len(found)==len(set(found)),f'duplicate function names {filename}'
    stack=[]
    quote=None
    skip=False
    esc=False
    for ch in source:
        if ch=='\n': skip=False
        if skip:continue
        if quote:
            if esc:esc=False
            elif ch=='\\':esc=True
            elif ch==quote:quote=None
            continue
        if ch=='#':skip=True;continue
        if ch in '"\'':quote=ch;continue
        if ch in '({[':stack.append(ch)
        elif ch in ')}]':
            assert stack and '({['.index(stack.pop())==')} ]'.replace(' ','').index(ch),(filename,ch)
    assert not stack
print('PASS: 27 original PNG assets plus new XP and encyclopedia art, 6 exact original WAVs, original boss theme and new boss track, SHA-256, GDScript balanced delimiters, no duplicate native functions.')
print('CAUTION: This is static verification, not a Godot compilation, runtime benchmark, exact parity test, or LAN gameplay test.')
