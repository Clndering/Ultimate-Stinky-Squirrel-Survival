# Nightwatch Godot 4.7 — Quit confirmation, admin tools, gun glows

Built on **StinkySquirrel_Godot47_Dodgeable_Stink_Blobs**, retaining the original
pixel-art source, six-player LAN RPC signatures, HUD, weather and damage rules.

## Closing or leaving
- ESC during play opens Pause, as before.
- ESC while paused or on the title screen opens a Quit Game confirmation.
- Title → QUIT GAME, Paused/Defeated → QUIT GAME, and the OS window close button
  (including Alt+F4 when Godot delivers the close notification) ask for confirmation.
- Main Menu during a run asks for confirmation before leaving. Progress is flushed
  on confirmed exit. Cancel keeps the game open.

## Admin console
- Main Menu → LEARN & SETTINGS → ADMIN CONSOLE; also available in Pause.
- Password: `1234` (local only; not a security mechanism).
- `/help`, `/status`, `/unlockall`, `/unlockoriginal`.
- First `/unlockall` writes a snapshot of the untouched progress to
  `user://stinky_squirrel_admin_original_backup.json`, then enables temporary
  override for weapons, cosmetics, wardrobe, and encyclopedia entries.
- Using `/unlockall` again never overwrites the original snapshot.
- `/unlockoriginal` restores the snapshot exactly and disables the override.
- Save metadata stores `admin_mode` so that the override survives a restart.
- Admin commands are strictly local and do not change LAN network protocol.
- If you earned kills while the admin override was enabled, `/unlockoriginal`
  intentionally restores the *pre-cheat* snapshot, so those temporary stats
  are discarded. Your settings aren't reverted.

## Cosmetic auras
- 13 premium gun skins (all non-base skins) have new two-tone gradient/aura
  sprites pre-generated at 106 × 58 pixels. They are composited behind the
  unchanged original pixel-art gun PNGs in gameplay and showcased in Armory.
- This is two small textures per premium gun, NOT a new full-screen shader.
- Gun-skin missions match the HTML progression thresholds. Previously equipped
  skins remain available, regardless of the new mission checks.

## Verification
- Static source tests and image asset hashes can be checked in the validation
  script. Runtime Godot 4.7 and physical LAN machines aren't available here;
  frame rates cannot be guaranteed until tested on your system.
