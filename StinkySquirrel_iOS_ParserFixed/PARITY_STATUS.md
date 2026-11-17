# Parity checklist against latest HTML (GPU Graphics & HUD build)

Original reference: `reference/ORIGINAL_LATEST_UNMODIFIED.html`.
Target: **same visuals, all gameplay systems, same progression balance, and six-player co-op**.

| Component | Port status | What remains |
|---|---|---|
| 27 original sprites and their raw bytes | Exact copied assets | Verify actual imported pixel filtering at all screen resolutions |
| Terrain art / isometric projection / wrap | Implemented based on original math | Screenshots at multiple map locations; lighting/postprocessing parity |
| Ranger outfits / split-leg walk animation | Native sprite-region implementation | Frame-by-frame comparison |
| Original music / effects | Audio files transferred | Validate original volumes, exact loop and boss transition behaviors |
| Shotgun, pistol, SMG, AR, sniper, Railgun | Native definitions with same starting stats | Every attachment visual, projectile spread, and advanced interactions |
| Meta kills and Railgun unlock | Implemented with original threshold data | Some skin-mission gates / achievements not yet mirrored |
| Common/Uncommon/Rare/Epic/Legendary | Original weights and multipliers implemented | All stacked-upgrade edge cases and unique synergies |
| 18 enemy/boss identifiers | Ported | Specialized stats, attacks, animations and telegraphs need precise verification |
| All eight boss encounters | Native initial attack mechanics | Reproduce exact JS multi-phase behavior and timings |
| Acorn pickup and healing | Native | Upgrade reroll frequency restrictions; balancing |
| 192x192 toroidal world | Native | Props, wave spawning across seam, all particle cases |
| Six-player host + five guests | Native ENet skeleton | Protocol differs; connection, rollback, VFX and stability testing |
| Encyclopedia and run-upgrade list | Basic native pages and tooltips | UI portraits and full discovery/legendary data matching |
| Native UI | Functional first pass | Exact original menu, HUD, gun-preview and button styling is outstanding |
| Advanced Graphics and weather | Basic time/color and rain | Full WebGL2 shader feature parity / native depth implementation outstanding |
| FPS and performance | Native rendering and obstacle buckets | Real GPU benchmarks on target PC outstanding |
| Novelty fake ads | Basic optional toast text | Original parody popup appearance/cadence is outstanding |
| Save import | JSON migration from HTML | Import achievements, other per-client browser flags and reconcile overwrites |

**The project must not be described as a finished identical port before all incomplete items have been addressed and real gameplay has been compared.**


## November 2026 — Visual/UI pass

- Main menu grouped into colored Play / Progression / Learn cards, with stat panels.
- Wardrobe previews display original ranger PNGs.
- Right-sidebar upgrade chips show colored rarity border/tooltips.
- Native Graphics settings include per-effect toggles, strength sliders, presets, AA and anisotropic filters.
- Native CanvasItem post-process GPU shader is optional/inactive when all shader effects are off.
- Full real 3D-depth SSR/SSAO/volumetrics/TAA remain unimplemented; the settings identify their native 2D visual counterparts.
- Rendering speed and shader compatibility have not been validated in Godot 4.7 here.
