# Stinky Squirrel: Nightwatch

A pixel-art wave-survival game set in an endless forest. This repository currently contains the standalone browser game and a Godot project archive.

## Play the browser game

1. Open [Stinky_Squirrel_Nightwatch_LAN_Coop.html](Stinky_Squirrel_Nightwatch_LAN_Coop.html).
2. Use GitHub’s **Download raw file** option to save it to your computer.
3. Open the saved file in a current version of Chrome or Edge.

The game’s images and sounds are embedded in the HTML file. No separate assets folder is needed. The browser edition includes a WebRTC co-op lobby for up to six players. Browser and network settings can affect peer connections.

## Godot project

Download [StinkySquirrel_Godot47_XP.rar](StinkySquirrel_Godot47_XP.rar), extract it, and open the included project.godot file with Godot 4.7.2. Let Godot import the assets, then press F5 to run the project.

The desktop build uses native ENet networking on UDP port 27844. Players joining a LAN session need the host computer’s local IP address. Firewall and router settings can block connections.

## Game features

- Isometric pixel-art combat, waves, bosses, and weather.
- Multiple weapons, skins, upgrades, and permanent progression.
- Custom HUD icons and an in-game encyclopedia.
- Solo play and co-op modes, depending on the version.

## Project status

This game is under active development. The browser edition and native Godot project use different networking systems. The desktop LAN game, browser co-op, performance, and mobile Safari support require testing on the intended computers and devices. A target near 100 FPS on capable desktop hardware is a goal, not a guarantee.

The current repository contains the standalone HTML game and the desktop Godot archive. The separate iPhone/iPad Godot Web project is not included here yet.

## License

No license has been chosen. Please contact the owner before reusing the game, source code, or artwork.
