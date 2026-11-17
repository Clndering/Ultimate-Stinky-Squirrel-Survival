"""Source-level release gate. This cannot replace Godot/Safari runtime testing."""
from pathlib import Path
from collections import Counter
import configparser,re,subprocess,sys
root=Path(__file__).resolve().parents[1]
source=(root/'scripts/Main.gd').read_text()
touch=(root/'scripts/TouchOverlay.gd').read_text()
world=(root/'scripts/World.gd').read_text()
project=(root/'project.godot').read_text()
export=(root/'export_presets.cfg').read_text()
checks = {
    'native 4.7 project': '"4.7"' in project,
    'WebGL2 Compatibility renderer': 'gl_compatibility' in project,
    'web export platform': 'platform="Web"' in export,
    'single-threaded web': 'variant/thread_support=false' in export,
    'Web GDExtensions off': 'variant/extensions_support=false' in export,
    'adaptive browser canvas': 'html/canvas_resize_policy=2' in export,
    'viewport disables Safari gesture zoom': 'user-scalable=no' in export,
    'web touch keyboard': 'html/experimental_virtual_keyboard=true' in export,
    'mobile touch UI source': 'scripts/TouchOverlay.gd' in source,
    'dual independent thumb indices': all(t in touch for t in ['left_touch','right_touch','InputEventScreenTouch','InputEventScreenDrag']),
    'dash queued and consumed': 'consume_dash()' in touch and '_local_dash()' in source,
    'reload queued and consumed': 'consume_reload()' in touch and '_local_reload()' in source,
    'touch direction controls': 'move_vector()' in source and 'aim_vector()' in source,
    'mobile pause signal': 'menu_requested.emit()' in touch and '_mobile_menu_requested' in source,
    'menu hides touch overlay': 'page == "playing" and bool(settings.get("touch_controls"' in source,
    'no web ENet host/join': source.count('if OS.has_feature("web"):\n        toast_message="WEB')==2,
    'ENet host/join error variables explicitly typed': 'var err:=peer.' not in source and 'var err: int = int(peer.call("create_server", PORT, MAX_GUESTS))' in source and 'var err: int = int(peer.call("create_client", addr, PORT))' in source,
    'mobile full-screen shader skipped': 'fx_rect.visible = shader_needed and not mobile_web' in source,
    'mobile particle limit': '130 if mobile_web else 320' in source,
    'pixel icons preserved': all((root/'art/hud'/f'{x}.png').is_file() for x in ['enemies','kills','record']),
    'XP leveling preserved': all(t in source for t in ['_create_xp_drop', 'xp_vacuum','_open_level_upgrade']),
    'itch packaging helper present': (root/'tools/package_itch.py').is_file(),
    'project main scene present': (root/'Main.tscn').is_file(),
}
for path in root.rglob('*.gd'):
    code=path.read_text()
    names=re.findall(r'^func\s+(\w+)\s*\(',code,re.M)
    checks[f'GDScript unique func names: {path.relative_to(root)}']=len(names)==len(set(names))
    for rel in re.findall(r'(?:res://)([\w\d_\-/\.]+)',code):
        if rel.endswith(('.gd','.png','.wav','.ogg','.gdshader','.tscn')):
            checks[f'resource {rel}']= (root/rel).is_file()
failed=[name for name,valid in checks.items() if not valid]
for name in failed: print('FAIL:',name)
print(f'{len(checks)-len(failed)}/{len(checks)} source/project checks passed.')
if failed:sys.exit(1)
print('IMPORTANT: no Godot 4.7 compile/export, iOS Safari WebGL2, multiplayer, or touch-device runtime test was performed.')
