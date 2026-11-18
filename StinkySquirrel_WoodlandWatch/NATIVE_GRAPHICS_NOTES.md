# Native Godot graphics and performance

- Based on last working Godot 4.7 ellipse parser fix. Original PNG, WAV, and reference HTML untouched.
- The original CanvasItem world renderer remains unchanged in projection and sprite layering.
- Optional GPU shader is a single full-screen native `canvas_item` pass. **It is invisible and does zero work when all shader options are disabled.** No browser Canvas, no texture upload per frame.
- Open **Settings → Graphics** for independent toggles and sliders for sun shafts, bloom, atmosphere fog, edge-based faux AO, contact shadows, color grade, vignette, tone map, chromatic aberration, focus blur, camera motion blur, outlines, stylized wet reflections, flare, film grain, and long-exposure trails. Additional anti-aliasing modes and anisotropic sampling.
- A native 2D renderer cannot provide genuine 3D SSR, depth-buffer SSAO, true volumetric fog or temporal anti-aliasing without a depth-aware 2.5D scene. These controls are honestly described as GPU-based 2D approximations where needed.
- Balanced is not selected automatically: defaults match original sharp pixel-art scene, except the already existing contact shadows. Presets: Original Pixels, Performance, Balanced, Cinematic.
- Rendering at a stable 100 FPS is hardware dependent. No measured benchmark is available in the build environment; keep high-cost options off on school PCs.
- Native ENet LAN code/port unchanged. Simulated LAN regression is not possible here without a Godot runtime.
- Save migration instructions are in SAVE_IMPORT_GUIDE.txt.
