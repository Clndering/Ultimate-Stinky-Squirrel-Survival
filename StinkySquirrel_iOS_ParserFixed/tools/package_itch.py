"""Package an ACTUAL Godot Web export into an itch.io upload ZIP.

Use AFTER exporting the Godot project to build/itch/index.html.
This script never fabricates Godot's .wasm/.pck engine artifacts.
"""
from pathlib import Path
import sys, zipfile

root = Path(__file__).resolve().parents[1]
folder = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / 'build' / 'itch'
output = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else root / 'Stinky_Squirrel_iOS_ITCH_UPLOAD.zip'

if not folder.is_dir():
    raise SystemExit(f'No Godot export found: {folder}\nExport the project from Godot first.')
files = sorted(p for p in folder.rglob('*') if p.is_file())
required = ['index.html', 'index.js', 'index.wasm', 'index.pck']
missing = [n for n in required if not (folder / n).is_file()]
if missing:
    raise SystemExit(f'Not a complete runnable Godot Web export. Missing: {missing}\nUse Godot > Project > Export > Web, not Export PCK/ZIP.')
if output.parent == folder or folder in output.parents:
    raise SystemExit('Choose an output outside the export directory.')
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for f in files:
        archive.write(f, f.relative_to(folder).as_posix())
with zipfile.ZipFile(output) as check:
    if check.testzip() is not None:
        raise SystemExit('ZIP integrity test failed.')
    for name in required:
        assert name in check.namelist(), name
print(f'ITCH.IO READY: {output} ({len(files)} files, {output.stat().st_size:,} bytes)')
