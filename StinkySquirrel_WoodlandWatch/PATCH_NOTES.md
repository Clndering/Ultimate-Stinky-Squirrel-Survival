# Stinky Squirrel: Nightwatch — Glow UI & Combat / Navigation Fix

Target engine: **Godot 4.7 / 4.7.2**, GDScript, GL Compatibility renderer.

## Fixed
- **Phantom / multiplied bullet trails:** Before this update, the firing loop reused the location of the previous pellet impact as the muzzle of the next pellet. Every projectile ray now starts from the original weapon muzzle. Piercing rounds only produce follow-up segments for their actual allowed penetration count; regular bullets stop at their first hit.
- **Squirrels stuck behind trees/rocks:** Obstacles now use smaller 8×8 lookup buckets; movement slides along collisions and blocked enemies probe short routes around each obstacle with a persistent turning preference. This is deliberately lightweight to avoid frame-time spikes from per-enemy A* searches.
- **Stray rectangle on title screen:** The outer health box was not hidden when switching off the gameplay HUD. The full HUD containers now hide on menu pages.

## UI refresh
- Glowing, tinted Nightwatch menu with the original pixel-art ranger and squirrel boss portraits, gold/teal/violet section colors, stronger hierarchy and borders.
- Native StyleBox shadows for soft glow, enhanced button hover/focus, glowing headings and a slowly pulsing menu title.
- A single pre-rendered, low-cost atmosphere backdrop is displayed **only when menus are open**, not during gameplay.
- Condensed bottom HUD to acorns, bank and best wave; empty upgrades sidebar hidden.
- Existing settings, skins, progression import, weather and native graphics options retained.

## Test notes
- Source and asset SHA tests passed: all 27 PNG images and six original WAV files are unchanged. Boss theme and existing shaders unchanged.
- All five ENet multiplayer RPC methods retained.
- Local Python behavioral simulation over the game's obstacle map (26 starting positions, 18-second horizon) saw direct-path movement reach 14/26 locations and the proposed steering reach 26/26. This is **not** a Godot gameplay test.
- The environment has no Godot 4.7 runtime; the GDScript has passed static checks only. **Godot compilation, actual six-PC networking and 100-FPS performance were not tested here.** Check FPS with optional settings off, and report any parser or runtime errors.

## Install
1. Extract this ZIP into a new folder.
2. In Godot 4.7, Import the `project.godot` file inside the `StinkySquirrel_Godot47_Glow_UI_CombatFix` folder.
3. Press F5.
4. Check menu layout, shotgun impacts and several squirrels navigating a tree.
5. Enable the FPS counter from Settings to measure frame rate on your machine.

This version maintains the existing native save file path: `user://stinky_squirrel_native_save.json`.
