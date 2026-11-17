# Stinky Squirrel: Nightwatch — Godot 4.7 UI + graphics update

**Native Godot WIP.** This is based on the latest Godot 4.7 build whose 100 FPS was reported by the user (ellipse parser fix). The gameplay logic, 27 PNG sprites, 7 original audio assets and ENet networking handlers are preserved.

## What's new

- Main menu remade as HTML-inspired color-coded **Play / Progression / Learn & Settings** cards with progression stats.
- Original ranger outfit portraits in Wardrobe, a clearer compact HUD with health bar, rarity-colored upgrade icons and mouse tooltips.
- **Settings → General**: toggle FPS, music, weather and fictional novelty ads.
- **Settings → Graphics**: 16 individually switchable effects plus strength sliders, anti-aliasing modes, and anisotropic texture sampling.
- Optional native Godot GPU screen-reading shader with sunlight shafts, bloom, fog, edge-based stylized ambient shading, outlines, grading, vignette, filmic contrast, chromatic aberration, pseudo-focus blur, motion blur, lens flare and grain.
- Ground contact shadows, wet-ground highlights and projectile trails are native world-drawing options and do not enable the full-screen shader by themselves.
- Performance-first presets: Original Pixels, Performance, Balanced, Cinematic. Original Pixels maintains the previous renderer's look by default; avoid enabling all effects if you want to maintain your current FPS.
- Snow, mist and wind add lightweight native particles/tints to the existing day/weather cycle.
- SAVE_IMPORT_GUIDE.txt explains how to create your own browser progress JSON.

## Open in Godot 4.7

1. Extract ZIP into a new folder (not on top of an older version).
2. Open the **Godot 4.7 standard editor** and import `project.godot`.
3. Press F5 and open Settings → Graphics.
4. Start with **Original Pixels**. Turn on individual effects one by one while monitoring your FPS counter.

You do not need .NET. All players should use this same Godot project version for LAN tests.

## Faithfulness and test limitations

The original HTML reference is only in the **Full** ZIP in `reference/ORIGINAL_LATEST_UNMODIFIED.html`. The Small ZIP contains the playable Godot project, art, audio, scripts, shader and save-import guide, but not the duplicate HTML reference.

The game is a native GDScript/CanvasItem implementation, not a WebView wrapper or exact full conversion. **3D depth-buffer effects** such as authentic SSR, 3D SSAO, volumetric fog and TAA still require an actual depth-aware scene and a proper engine renderer. These 2D shader techniques are visually styled alternatives, clearly labeled in the settings.

Static source and archive checks pass; this environment has no Godot executable, so Godot 4.7 compilation, measured FPS and physical six-PC LAN remain **unverified**. A previously reported 100 FPS baseline is not a benchmark of this update.

## Glow UI and combat/nav maintenance
- New luminous HTML-inspired lobby, original hero and boss sprites, glowing themed cards, clearer headings, button-focus outlines.
- The empty top-left health panel no longer appears on the title screen; the full HUD containers are hidden correctly.
- Shotgun pellets each start at the same muzzle; bullets only continue after a target if a piercing upgrade actually allows it.
- Enemies slide around blockers and commit to a short detour to skirt trees and rocks. Spatial buckets tightened for lower collision-query overhead.
- Original art, weapon values, weather, GPU settings, saves and 6-player ENet protocol remain in place.
- FPS on your own PC must be rechecked; native runtime was not available in this environment.
