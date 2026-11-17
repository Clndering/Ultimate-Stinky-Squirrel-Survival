# Stinky Squirrel 2 — XP / Pixel-Clarity Update

## Changes

- Turned off temporal/spatial anti-aliasing, depth-of-field, motion blur and softened texture sampling for every graphics preset, including existing saved configurations. Native shader now samples screen pixels with nearest-neighbor filtering. Atmospheric color, glow, weather and lighting options remain available.
- Replaced wordy during-run labels for health, enemies, kills, wave and acorns with compact symbols/icons. Condensed ammo/reload labels. Kept weapon names and readable menu/help instructions.
- Every enemy now drops a permanent-on-ground XP crystal when killed (separately from the original probabilistic acorn drop). XP amount is based on enemy type and increases with the level of the enemy. Enemy level increases every two waves.
- Nearby crystals magnetize toward living players. Once the wave is cleared, *all* remaining XP accelerates toward the nearest living player, with no required proximity trigger. The wave advances only after XP is collected and outstanding XP level-up picks are resolved.
- Three-card rarity upgrades now appear on gaining an XP level, not on wave completion. Multi-level jumps queue additional picks. Acorn rerolls remain, now limited to one per level-up.
- Introduced a stepped mint-color pixel-style XP meter, XP crystal world sprite and 19 enemy/boss/unknown encyclopedia portraits plus 39 bespoke upgrade artwork thumbnails.
- XP, enemy levels, XP drops, and wave transitions are host authoritative and included in six-player ENet co-op snapshots. Guests cannot choose host upgrades.
- Preserved the existing 6-player LAN rules, guns/skins/glows, permanent progression, acorns, weather, controls, admin console and save import.

## How to open

Open `project.godot` in **Godot 4.7**, import the assets, and press Run. Existing local saves are not overwritten by this source ZIP. The HTML edition is distributed separately and runs from a single `.html` file, including its embedded original art, audio, and new encyclopedia pictures.

## Test coverage and limitations

- `python validate_static.py` passed: confirms the original 27 PNG assets, original six WAVs, the boss theme and original HTML SHA-256 match their source; it also checks new art counts and GDScript function-name / balanced delimiter integrity.
- The HTML edition passed JavaScript `node --check` and headless Chromium smoke tests: solo play/start, XP pickup and multi-level choice queue, wave-end vacuum, encyclopedia portraits and all upgrade images, menu settings/presets, admin commands and backup restore.
- **Godot runtime has not been compiled or played in this environment.** Godot 4.7 was not available, so its scene loading, visual output, performance, LAN connections, and controller/browser interoperability need testing in the Godot editor and on multiple devices. These tests do not establish FPS.
- Network protocols differ by design: native Godot uses ENet/UDP on port 27844, while HTML uses its existing WebRTC manual signaling. They cannot join one another's multiplayer sessions. They are close parallel editions of the same game, not a byte-for-byte identical renderer or networking stack.
