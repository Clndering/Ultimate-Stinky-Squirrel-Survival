# STINKY SQUIRREL 2 — Release Review Build

## Contents

- `Stinky_Squirrel_2_FinalReview.html`: complete standalone browser edition. Open in Chrome or Edge. Uses its embedded original pixel assets and audio; no installation required for solo mode. Browser multiplayer uses manual-code WebRTC signaling and may be affected by browser or LAN restrictions.
- `StinkySquirrel_Godot47_FinalReview/`: native Godot 4.7 GDScript source. Open `project.godot` in Godot 4.7; let the editor import assets; run `Main.tscn`.

## User-requested HUD change

Removed the chess pawn used for enemies, the star used for kills, and the chess queen used for the best-wave record from both editions. The counters now have matching, purpose-made **nearest-neighbor pixel sprites**: orange squirrel, ivory skull, and amber trail flag. Kept the star-like XP marker (not a kill indicator) and all existing acorn counters.

## Additional code repairs from review

- Native Godot: fixed the ellipse renderer calls through a safe pixel-ellipse helper.
- Native Godot: connected previously ineffective upgrade branches to combat, acorn magnet, effective dash recharge, cooldown, reload, and elemental effects; a LUCKY_CHAMBER bonus applies to every fifth shot.
- Native Godot: replaced ENet peer-ID-based spawn offsets with compact player slots, spawned waves around a living player, and retained guest kill progress from host-authoritative snapshots with run-generation protection.
- Browser HTML: delayed DOUBLE_TAP echo shots do not leak into later runs, paused games, or the defeat screen.
- All original assets, audio, encyclopedia portraits, upgrades, and prior progression systems were preserved.

## Verification performed

1. `node --check` passed for the extracted complete browser JavaScript.
2. Headless Chromium solo smoke suite: **19/19 pass**. Covered title boot, HUD images/values, settings presets, both encyclopedia tabs and embedded images, admin unlock/restore, start, XP pickup, level-up choices, wave-end XP vacuum, pause/resume, and uncaught page exceptions.
3. Static Godot integrity validator: **pass**; source original PNG/WAV SHA verification, 3 GDScript files with balanced delimiters and no duplicate function declarations.
4. Additional structural audit: **pass**; all 146 original files present, all 122 PNGs decodable, original six WAVs and OGG present, all gun/skin/glow textures, all 39 upgrade IDs have native effect handlers, and the 3 HUD PNGs are embedded byte-for-byte in HTML.

## Unverified / release qualification

**This is a release-review candidate, not a guaranteed error-free final binary.** Godot 4.7 was not installed in the build environment, so GDScript compilation, scene rendering, actual Godot gameplay, hardware performance, and native ENet LAN/6-player regression tests were not possible. A live browser WebRTC two-client integration test was attempted but blocked/timed out by the environment's local networking restrictions; do not interpret that as a test pass. The browser and Godot editions use different multiplayer transports and cannot join the same multiplayer room.

**Before distributing publicly**, open the Godot project in Godot 4.7, resolve any editor errors, play a complete multi-wave solo run and boss wave, and run 2- and 6-player LAN sessions (join/leave/rejoin, death/revive, upgrade queue, level-up and saves, network latency, controller/keyboard, 100 FPS target). Repeat a six-browser WebRTC test on real computers on a permitted LAN. Check builds on target OS/GPU resolutions.

The original native source describes itself as a fidelity port WIP; this review deliberately does not claim a runtime parity guarantee that was not established.
