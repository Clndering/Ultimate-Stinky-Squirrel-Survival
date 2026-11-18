# Stinky Squirrel: Woodland Watch

This is the standalone cooperative campaign for Godot 4.7.2. The [source record](reference/SOURCE_PROVENANCE.md) documents the original Ultimate Stinky Squirrel Survival files. Treat the original desktop, mobile, and standalone HTML projects as upstream sources.

## Architecture

- `Main.tscn` opens `scripts/Main.gd`, which manages the campaign, combat, progression, UI, and cooperative sessions.
- `scripts/Campaign.gd` defines the field sites, authored encounters, bosses, and training. `scripts/FieldPatterns.gd` defines chapter enemy debuts and the objective for each wave.
- `scripts/World.gd` draws the isometric terrain, actors, weather, effects, and field objectives. `scripts/HudMeter.gd` draws the custom meters.
- `art/`, `ui/`, `audio/`, and `shaders/` contain the original visual and sound resources. `reference/` is archival material. Keep original art bytes and nearest-neighbor rendering. Use the existing custom HUD sprites for counters.
- The launchers and browser gateway are described in [HOSTING.md](HOSTING.md). The Godot host runs combat, objectives, and revives. Clients submit input and render compact, timestamped snapshots. NetState holds the presentation fields and GuestMotion smooths remote positions. Keep full combat simulation on the host at a fixed tick. Preserve the terrain mesh cache. Native LAN uses ENet. The Web client uses same-origin WebSockets at `/play` and `/play/lantern-hollow`. Each room has independent progress.

## Campaign rules

- The eight operations have three to five escalating waves each. Follow the objective plan for each wave before the boss. Keep flag ownership, capture contesting, projectile hits, and rewards on the host. Keep objective transitions and rewards authoritative on the host. Chest interaction uses E, validates live player proximity on the host, and drops one reward. Replicate loot and keep unopened chests and collected perks at the boss checkpoint.
- Confirm a chapter clear and grant its rewards on the host. A boss checkpoint lasts for the current operation session. Persist cleared chapters, field XP, and acorns separately from the original game's save. JSON transfer handles an individual player's local progress and backs up before replacing it.
- Keep gear license requirements and training deterministic. Keep nine playable weapons and preserve the two retired weapons in legacy save data. Retain existing skins and glows, outfits, 32 regular enemy types, and eight boss identities. Player careers cap at level 50. Prestige resets local progression and carries forward prestige skins. Derive enemy health and damage scaling on the host from the highest connected ranger level. Introduce two new enemy types per operation. Preserve applied legacy unlocks. Boss patterns and hit tests must agree with the warnings rendered in World.gd. Keep combat cooperative, including proximity revives.
- Keep the project on GL Compatibility for Windows and Godot Web. The terrain atlas is built from the original PNGs. Use fixed, lightweight graphics without a full-screen post-processing pass. Keep the original pixel art, weather, custom HUD, and enemy attack warnings. Ship matching Windows and Web builds in the separate server package. Keep local caches and export output out of source control.

## Verification

With the project folder open, run `python -X utf8 validate_static.py` to verify the embedded source sprites, sound files, and archived HTML digest. Import resources in Godot 4.7.2 and run the project. For changes to campaign or networking, check that two clients can play the same operation through the defense, boss, and clear, and that the host alone settles chapter progression.

The original desktop review files are historical. Use this file and [HOSTING.md](HOSTING.md) for current project instructions.
