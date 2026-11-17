# Dodgeable stink blobs + 10% weapon range update

Based on the previous Glow HUD Godot 4.7 project.

- Replaced instant enemy hitscan / laser lines with small moving vapor blobs.
- Different projectile speeds and sizes for regular, toxic, ice, and blast attacks.
- Collision is determined after travel, using swept hit checks; players can dodge.
- Projectile collisions with trees/rocks are checked at a limited rate to preserve FPS.
- Enemy projectiles replicate through the existing host snapshot to all five guests, with bounded visual interpolation between updates.
- Cleared projectile state at the start of runs and waves.
- Increased weapon ranges 10%: Shotgun 350->385, Pistol 430->473, SMG 300->330, AR 420->462, Sniper 620->682, Railgun 1050->1155.
- No changes to original art, gun skins, existing HUD, save files, or gameplay damage outside moving projectile hits.

Testing: static and source regression checks have been run. Actual frame rate and live Godot/LAN play are unverified in this environment.
