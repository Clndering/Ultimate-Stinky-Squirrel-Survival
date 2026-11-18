# Stinky Squirrel: Woodland Watch

Restore eight woodland watch posts with a squad of up to six rangers. The eight operations have 30 escalating enemy waves across them, plus their boss encounters. Objectives change between waves. Defend or capture a point, bring a flag back to its beacon, hit a kill quota, escort the cart, recover cores, and survive timed ambushes. Two new enemies debut in every operation, and earlier enemies return in later waves. Completing the campaign secures the forest. Each chapter you clear stays unlocked, and you can return to earlier chapters with your unlocked gear.

## Play on your computer

1. Import this folder's `project.godot` in **Godot 4.7.2**, then press **F5**.
2. Choose **Choose Operation**, open **The Silent Bell**, and select **Deploy Solo**.
3. Follow the briefing and gold marker. When a boss starts an attack, move out of the orange outline. After defeating the boss, return to the green marker.

On this PC, you can also run `build/windows/WoodlandWatch.exe`. Keep its `.pck` file beside it.

| Action | Controls |
| --- | --- |
| Move | WASD or arrow keys |
| Aim and fire | Mouse and left click |
| Reload | R |
| Dash toward the mouse | Space |
| Open a nearby chest | E |
| Open the menu | Esc |
| Revive a downed teammate | Stand beside them for 2.5 seconds |

Once a squad reaches the boss, it can retry from that checkpoint during the current session. The Armory has nine weapons. The Birch Auto and Tempest Repeater have been retired. Existing saves fall back to an unlocked SMG or AR for those two selections. The early shotgun and pistol fire deliberately, while later automatics increase both fire rate and per-shot damage within their class. The sniper and railgun remain precision weapons. Guns after the starters require chapter clears and, for higher tiers, field XP. Existing weapon licenses and earned skins carry forward. Select Veteran in Choose Operation for more enemies, stronger attacks, and extra rewards. Replaying a cleared operation rotates its roster. Pick up field XP and acorns to bank them when the chapter is complete. The Armory, Ranger Wardrobe, encyclopedias, and graphics settings are available from the main menu.

Look for a handful of spread-out chests in each operation. Press **E** by a chest with a colored latch, or tap **Open** on a phone. Its rarity determines the strength of an upgrade drop or the size of its acorn or XP reward. Walk over the loot to collect it. The whole upgrade catalog can appear. Upgrades last for the operation, and chest perks collected before the boss carry into a checkpoint retry.

The **Admin Console** is in **Learn & Settings** on the title screen and in the pause menu. Its local password is `1234`. Use `/help`, `/status`, `/unlockall` to temporarily open all eight operations and unlock gear, and `/unlockoriginal` to restore the backup made before the override. To reset your own profile, open the console from the title, type `/reset`, then `/reset confirm` within 30 seconds. The game keeps a JSON backup and your settings.

New weapon licenses need more field XP. The Railgun and Mistral also require one and two Veteran clears of chapter 5 or later, respectively. Premium skins ask for more kills and later milestones, and outfits require chapter clears. Previously earned gear for the active weapons remains available.

## Ranger levels and prestige

Rangers gain one level per 250 banked field XP, up to level 50. Their level follows them between outfits. Enemy health and damage rise by 2% for each level above 1 of the highest-level ranger in the squad. This applies in solo play, LAN, and public rooms.

At level 50, choose **Progress Tools → Prestige**. This backs up your profile and resets all ordinary progress, including level, operations, gear, currencies, and discoveries. Each of the three prestige ranks unlocks one high-powered ranger skin and carries forward any earlier prestige skins. You can equip them in the Ranger Wardrobe. Prestige is included in save exports.

## Transfer a save

At the title screen, open **Progress Tools → Export Save JSON** to back up local progress. Use **Import Save JSON** in Windows or in the browser to restore it. Import asks before replacing progression and saves a backup of the previous profile in local game storage. These buttons transfer your character, progress, and unlocks. Settings and room campaign saves are managed separately.

## Play together

Use the separate WoodlandWatch_Server package and its START HERE guide for play.stinkysquirrel.online. The package runs on Windows 11 without opening the Godot editor.

- **Over the internet:** Open **Start Online Host.cmd**, then **Share Online Playtest.cmd** to generate a temporary link. Players choose **Fern Creek** or **Lantern Hollow**. Each public room has its own campaign and space for six rangers. See the [Windows hosting guide](HOSTING.md).
- **On the same network:** Use native desktop builds. Choose an operation and select **Host LAN Co-op**. Other players choose **Join by Address** on the Windows title screen, then enter the host's local IP. The native LAN uses UDP port 27844.
- **Public rooms:** Choose **Join Fern Creek** or **Join Lantern Hollow** in the Windows app or at the game website. Both use the same rooms when the public server is running.
- **Browser controls:** Open the same game link on your phone and turn it sideways. Drag the left stick to move, and drag the right stick to aim and fire. Both sticks can be held at the same time. Touch browsers render at game resolution and cap at 60 FPS. The Performance preset is the default for new mobile profiles. The browser also supports keyboard and mouse.

## Sharing and reuse

The project maintainers make the Woodland Watch contributions available under [CC0 1.0 Universal](LICENSE.md) to the extent they hold rights in them. See the original game record for the provenance of incorporated material.

## Original game files

Woodland Watch is a separate Godot project derived from the Ultimate Stinky Squirrel Survival desktop source at [commit 05cd3e9](https://github.com/Clndering/Ultimate-Stinky-Squirrel-Survival/commit/05cd3e98bbf8a5a784131df7d5338fc3e873b32a). It carries forward the isometric pixel art, original sounds, nine active weapons and their skins, the original six ranger outfits, 32 regular enemy types, eight bosses, custom HUD sprites, weather, and graphics settings. Campaign progress uses a separate save.

The [source record](reference/SOURCE_PROVENANCE.md) identifies both original HTML versions, the assets compared against them, and the archived desktop notes.
