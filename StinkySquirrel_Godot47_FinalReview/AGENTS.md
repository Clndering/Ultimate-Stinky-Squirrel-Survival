# AGENTS.md — Desktop Godot project

## Project identity

Existing desktop build of Stinky Squirrel: Nightwatch, an isometric pixel-art wave-survival game in Godot 4.7 GDScript. Open this folder's project.godot. Main scene: Main.tscn. A Git baseline commit records the source present at the November 2026 audit.

## Architecture

- scripts/Main.gd owns game/run state, weapons and skins, ranger cosmetics, enemies and bosses, waves, XP/acorns/upgrades, HUD and menus, settings, saves, local admin commands, and multiplayer.
- scripts/World.gd draws the isometric world, terrain, obstacles, actors, projectiles, effects, weather, and weapons. It loads source art and premium weapon glow textures.
- scripts/HudMeter.gd implements custom meters. Main.tscn attaches Main.gd to the root Node2D.
- art/ contains the original game, HUD, enemy, and upgrade sprites. ui/guns/ contains weapon sprites; ui/guns/glows/ contains premium-skin glows. audio/ contains six WAV files and a boss OGG. shaders/native_post.gdshader implements optional 2D effects.
- reference/ORIGINAL_LATEST_UNMODIFIED.html is the bundled HTML source reference. Its SHA-256 is recorded in reference/sha256.txt. validate_static.py checks the digest, exact original sprite/sound bytes, art counts, GDScript delimiters, and duplicate function names.
- Root Markdown and text files document release review, parity, networking, graphics, save import, progression, HUD, and combat.

The tracked source contains 122 PNGs and seven audio files. Preserve the source pixel art and custom HUD icons.

## Platform and networking

project.godot targets Godot 4.7 with the GL Compatibility renderer at a 1280 × 720 design resolution. Native LAN uses ENet/UDP port 27844 with one host and up to five guests. RPCs and host-authoritative snapshots are in scripts/Main.gd. NETWORK_TEST_PLAN.md describes manual LAN tests requiring physical computers.

The bundled reference HTML implements six-player co-op using browser WebRTC/manual signaling. It cannot connect to the native ENet transport.

## Requirements

- Make the smallest reliable change in this existing project. Preserve gameplay, saves, art, six-player LAN, weapons/skins, enemies/bosses, upgrades/progression, weather, graphics settings, admin commands, and HUD icons.
- Do not restore chess-piece HUD icons or the star-shaped kill icon. Do not rebuild the game or make replacement archives unless asked.
- Preserve crisp nearest-neighbor pixels. Keep expensive full-screen effects off by default and check performance. Approximately 100 FPS on capable hardware is a goal, not a verified result.
- Check desktop and mobile impacts before changing shared logic. Keep desktop, mobile, and HTML behavior consistent where platform limits allow.
- Preserve user progress. Admin password is 1234; commands include /unlockall and /unlockoriginal. Restore uses the snapshot from before the first unlock override.
- Keep .godot/ generated cache out of Git; keep source, import settings, UID files, presets, docs, and original assets in Git.
- Do not claim LAN, performance, parity, or release checks unless they were performed.

## Checks

From this folder, python -X utf8 validate_static.py checks source/reference integrity on Windows but does not run Godot. Godot 4.7 can import and parse with godot --headless --editor --path . --quit. Check its output for errors. Follow parser checks with solo gameplay and the manual LAN plan when those areas change. Godot writes generated data under .godot/.

## Audit findings

- Existing Godot user log records an unreliable 4,506-byte packet above the 1,392-byte MTU. Periodic host snapshots include entity arrays, particles, traces, and other run data. Check loss under crowded waves when changing snapshot content.
- PARITY_STATUS.md lists unverified work for boss phases/timing, advanced upgrade combinations, achievements/skin gates, graphics, menus, save import, and performance.
- Six-player networking, the approximately 100 FPS goal, and target-hardware graphics performance remain unverified.
- Godot 4.7.2 headless startup of a temporary desktop-project copy returned exit code 0 with no script/parse errors. This does not validate visible gameplay, export, or LAN. The editor asset-import attempt in temporary copies also reported a safe-save failure.
- Use UTF-8 mode for the Python check on Windows. Default encoding failed to decode the embedded HTML, while UTF-8 mode passed.
