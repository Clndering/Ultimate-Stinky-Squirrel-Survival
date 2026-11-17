# AGENTS.md — iOS Safari / itch.io Godot Web project

## Project identity

Existing mobile-browser adaptation of Stinky Squirrel: Nightwatch. This editable Godot 4.7 GDScript project targets Godot Web on Safari/itch.io. It is not a native Xcode/App Store app. Open this folder's project.godot. Main scene: Main.tscn. A Git baseline commit records the source present at the November 2026 audit.

## Architecture

- scripts/Main.gd owns shared gameplay plus mobile-web detection, touch-input routing, mobile performance settings, and web-safe menu behavior.
- scripts/TouchOverlay.gd handles indexed multi-touch move/aim/fire sticks and dash, reload, and pause controls. It is shown during gameplay when enabled.
- scripts/World.gd draws the isometric world. scripts/HudMeter.gd implements HUD meters. Main.tscn attaches Main.gd to the root Node2D.
- art/ contains the original game, HUD, enemy, and upgrade sprites. ui/guns/ contains weapons and ui/guns/glows/ premium-skin glow images. audio/ contains six WAV files and a boss OGG. shaders/native_post.gdshader provides optional visual effects. Mobile-web mode limits particles and disables the full-screen pass.
- export_presets.cfg has the iOS Safari + itch.io (Web) preset using Compatibility and single-threaded web export.
- tools/check_ios_web.py checks expected source/export configuration. tools/package_itch.py packages a complete real Godot Web export and rejects missing engine files.
- reference/ORIGINAL_LATEST_UNMODIFIED.html is the bundled HTML source reference. Its SHA-256 is recorded in reference/sha256.txt. validate_static.py checks source/reference integrity. These Python checks do not test gameplay.
- Root Markdown and text files describe history, parser fixes, parity, export, release, and save import.

The tracked source contains 122 PNGs and seven audio files. Both projects' bundled HTML references have the same verified SHA-256. Their Godot scripts, import settings, and export configuration differ by platform.

## Platform behavior

The Web build targets WebGL 2 with threading disabled. Touch-capable Web devices enable two-thumb controls, larger targets, graphics safeguards, and a 60 FPS cap. The cap is not a performance guarantee. Keyboard and mouse remain available. Browser pause/close actions return to the title.

Native desktop uses ENet/UDP port 27844 and supports up to six players. Browsers cannot use this native UDP transport, so the Web build hides ENet controls. Web multiplayer is not implemented. Standalone HTML uses separate WebRTC/manual-signaling code and cannot join native ENet.

## Requirements

- Make the smallest reliable change in this existing project. Preserve gameplay, saves, original art, weapons/skins, enemies/bosses, upgrades/progression, weather, admin commands, and HUD icons.
- Preserve desktop six-player LAN in the desktop project. Do not expose unsupported ENet controls in browser builds.
- Do not restore chess-piece HUD icons or the star-shaped kill icon. Do not rebuild the game or make replacement archives unless asked.
- Keep move, aim/fire, dash, reload, and pause controls usable together. Hide the touch overlay on menus and upgrades.
- Preserve sharp pixels and mobile performance safeguards. Approximately 100 FPS on capable desktop hardware is a goal. The Web build's cap is 60 FPS.
- Keep shared gameplay consistent with desktop and HTML when platform limits allow.
- Preserve progress. Admin password is 1234; commands include /unlockall and /unlockoriginal. Restore uses the snapshot from before the first unlock override.
- Keep .godot/ generated cache out of Git; keep source, import settings, UID files, presets, docs, and original assets in Git.
- Never claim Safari touch, performance, or release behavior without testing the exported game on a real device/browser.

## Checks

Run python -X utf8 validate_static.py for source/reference integrity and python -X utf8 tools/check_ios_web.py for expected mobile/export source settings on Windows. Neither checks gameplay or the Web export. Godot 4.7 can import and parse with godot --headless --editor --path . --quit; inspect output for errors. Export actual Web files before running python tools/package_itch.py. Its required files include index.html, index.js, index.wasm, and index.pck. Test the published itch.io build in Safari with two-thumb controls, reload/dash/pause, upgrades, saves, audio, and rotation.

## Audit findings

- The static asset check passed, and the web configuration check passed 33/33 assertions. Godot 4.7.2 headless startup of a temporary mobile-project copy returned exit code 0 with no script/parse errors. The editor asset-import attempt in temporary copies reported a safe-save failure. Neither check validates an export or device behavior.
- PARITY_STATUS.md lists unverified work for boss phases/timing, advanced upgrade combinations, achievements/skin gates, graphics, menus, save import, and performance.
- The Web export, published itch.io page, and iPhone/iPad touch behavior remain unverified.
- Use UTF-8 mode for the Python checks on Windows. Default encoding failed to decode the embedded HTML/source, while UTF-8 mode passed.
