# Stinky Squirrel

## Woodland Watch

Woodland Watch is the eight-operation cooperative campaign for up to six players. The Windows app, iPhone, Android, and desktop browsers can join the same public rooms. Windows also supports LAN play.

- [Download or browse the complete Godot 4.7.2 source project](StinkySquirrel_WoodlandWatch/)
- [Open the game website](https://play.stinkysquirrel.online/)
- [Host your own rooms on Windows](StinkySquirrel_WoodlandWatch/HOSTING.md)
- [Sharing and reuse terms](StinkySquirrel_WoodlandWatch/LICENSE.md)

## Nightwatch archives


A pixel-art wave-survival game about defending an endless forest. This repository contains the standalone browser edition and the editable Godot projects for desktop and mobile web.

## Choose a version

| Version | What it is | Start here |
| --- | --- | --- |
| Browser game | One self-contained HTML file for desktop browsers. It includes its own WebRTC co-op lobby for up to six players. | [Download the standalone HTML game](Stinky_Squirrel_Nightwatch_LAN_Coop.html) |
| Desktop | Editable Godot 4.7 project with native Windows export settings and six-player LAN co-op. | [Open the desktop Godot project](StinkySquirrel_Godot47_FinalReview/) |
| iPhone and iPad web | Editable Godot Web project with touch controls, intended for Safari and itch.io. Web play is single-player. | [Open the mobile web project](StinkySquirrel_iOS_ParserFixed/) |

The desktop game uses ENet over UDP. The browser game uses a separate WebRTC connection flow. Those editions cannot join each other's sessions.

## Play the browser edition

1. Open the standalone HTML game file above.
2. Choose GitHub's download or raw-file option and save the file to your computer.
3. Open the saved file in a current version of Chrome or Edge.
4. Select Play Solo, or use the in-game co-op lobby if your browser and local network allow peer connections.

The artwork and sounds are embedded in the HTML file. It does not need a separate assets folder.

## Open the desktop project

1. Install Godot 4.7.2.
2. Open the desktop project folder and select its project.godot file.
3. Let Godot import the assets, then press F5 to run the project.
4. To export a Windows build, install the matching Godot export templates and use the Windows Desktop preset.

The native LAN host listens on UDP port 27844. Guests join using the host computer's local network address. A firewall or router can block connections.

## Use the iPhone and iPad web project

This project exports to Godot Web for Safari and itch.io. It is not an App Store application. Open its project.godot in Godot 4.7.2 and use its iOS Safari + itch.io (Web) export preset. The touch overlay provides movement and aim/fire sticks, dash, reload, and pause.

The project includes export and itch.io packaging instructions in its [mobile setup guide](StinkySquirrel_iOS_ParserFixed/README_IOS_ITCH.md). Test the exported game on an actual iPhone or iPad before sharing it as a release.

## Game features

- Isometric pixel-art combat with waves, bosses, weather, weapons, upgrades, and permanent progression.
- Weapon and ranger cosmetics, encyclopedia, and custom pixel HUD icons.
- A local admin console with progression commands.
- Native six-player LAN on desktop and browser-based co-op in the standalone HTML edition.

## Project layout

- The standalone HTML game is at the repository root.
- The desktop and mobile Godot source live in separate folders. Each includes its own project guidance and validation notes.
- The original HTML reference is included inside both Godot projects.
- The RAR archive at the repository root is preserved as an additional download.

## Development status

This is an active project. The Godot ports document areas where parity, multiplayer, device support, and performance still need hands-on testing. The desktop target is around 100 FPS on capable hardware, but that target has not been verified across machines. The mobile web build and iPhone/iPad controls need real-device testing.

## License

No reuse license has been selected for this project. Contact the owner before reusing the game, code, or artwork.
