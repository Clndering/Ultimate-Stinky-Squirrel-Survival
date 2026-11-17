# Stinky Squirrel: Nightwatch — iOS Safari / itch.io Godot Web edition

This folder is an **editable Godot 4.7 project**, adapted from the latest `StinkySquirrel2_FINAL.rar` source. It is **not** a native iOS (Xcode/App Store) project. The intended deployment is a **Godot Web / WebAssembly export** on itch.io, played in iOS Safari (preferably landscape orientation).

## What changed

- Native Godot twin-stick multi-touch overlay while playing: left thumb walks, right thumb aims + fires, and separate on-screen dash/reload/pause controls. Individual `InputEventScreenTouch.index` values allow simultaneous fingers.
- Controls automatically enable on web devices detected as touchscreens; they can be toggled in Settings > General. Keyboard and mouse controls remain for desktop.
- Adjusted menu and upgrade touch targets. Upgrade choices remain touch-selectable because the joystick overlay is hidden outside gameplay.
- Added a web export preset configured for **GL Compatibility/WebGL 2**, **single-threaded**, **adaptive canvas resizing**, experimental on-screen keyboard, and phone-friendly viewport CSS.
- Mobile Safari defaults to a 60 FPS cap; the expensive fullscreen shader is disabled on touch-web devices to protect frame rate and sharp pixels. This is a *cap*, not an FPS guarantee.
- Browser-safe 'quit' behavior returns to the title screen instead of blanking the iframe.
- Browser build hides ENet LAN host/join UI rather than allowing an unsupported UDP socket to fail.

## Export to itch.io (Windows / macOS / Linux)

1. Open `project.godot` in **Godot 4.7.x**, preferably 4.7.2, and install the matching **Export Templates** in Editor > Manage Export Templates. Let the editor import all textures/audio.
2. Choose **Project > Export**. Select **iOS Safari + itch.io (Web)**, provided by `export_presets.cfg`.
3. Confirm **Thread Support: OFF**, **Extensions: OFF**, **Canvas Resize Policy: Adaptive** and the **Compatibility** renderer in Project Settings. For a native iOS app you would need a separate workflow; do not choose `iOS` in the Export dialog for itch.io browser play.
4. Click **Export Project** and save the runnable web export to `build/itch/index.html`. Godot should emit `index.html`, `index.js`, `index.wasm`, `index.pck`, and any other necessary generated files, in the same output directory. **Never rename only index.html after exporting.**
5. Run `python tools/package_itch.py` from anywhere (or double-click the tool from a terminal) to generate `Stinky_Squirrel_iOS_ITCH_UPLOAD.zip` from the **actual exported files**. This helper refuses to package incomplete exports.
6. On itch.io, create/edit a project with **Kind of project: HTML Game**, upload that **ZIP** as the browser-playable build, choose **This file will be played in the browser**, and select **Mobile Friendly**. Use the launch-in-fullscreen option and landscape orientation for iPhone/iPad. Test the live itch.io page, not `file://`.
7. Test in real iPhone Safari and iPad Safari: load game, play solo with both thumbs, level up, collect XP/acorns, reload/dash/pause, open encyclopedia, save/refresh, mute/unmute, rotate the device, and confirm touch targets are usable. Test desktop Firefox/Chrome too.

### Notes and limitations

- **WebGL 2 required.** Some Safari/iOS device combinations have WebGL compatibility or memory limitations. This cannot be guaranteed without device testing.
- **Solo web mode is enabled.** The original 6-player LAN code uses ENet/UDP, which browser sandboxes cannot host or join. Multiplayer would require an independently hosted WebSocket/WebRTC transport and corresponding server/runtime changes. The previous native desktop LAN functions remain in source for future work.
- **Browser save data:** `user://` storage relies on the browser/site's storage policy; private-browsing mode, clearing site data, or an origin change may remove progress. Test saving on the published itch.io URL.
- **Audio:** iOS Safari may wait for user interaction before enabling sound; starting a run from the game menu provides user interaction.
- **iOS browser fullscreen/orientation lock:** Safari and itch.io control how much UI can be hidden; the web build cannot force every device into landscape orientation. Rotate the device manually as needed.
- **Not a verified release binary:** The source has undergone static checks, but Godot 4.7.x and physical iOS Safari device execution were not available in this environment. You must run Godot's parser/export and real-device smoke tests before calling it production-ready.

## Package layout

- `project.godot` — editable native Godot project.
- `export_presets.cfg` — Web preset ready for the Godot export dialog.
- `Main.tscn`, `scripts/`, `art/`, `audio/`, `ui/`, `shaders/` — game source and assets.
- `scripts/TouchOverlay.gd` — new mobile virtual controls.
- `tools/package_itch.py` — packages **real Godot-generated Web files** into itch.io's ZIP upload format.
- `validate_static.py` — existing source/asset integrity checks, *not* a runtime test.
- `reference/` — original HTML asset reference from the previous native port.

Official docs: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html and https://itch.io/docs/creators/html5.
