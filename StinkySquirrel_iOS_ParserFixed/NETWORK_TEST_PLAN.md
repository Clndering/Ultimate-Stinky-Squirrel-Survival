# Native six-player LAN regression checklist

Use identical copies of the Godot project on up to six PCs. This native build uses UDP 27844 rather than browser WebRTC codes.

1. On host: choose HOST 6-PLAYER LAN. Confirm waves start.
2. On five guests: enter host LAN IPv4 address and select JOIN LAN BY IP.
3. Verify all six players are visible at distinct coordinates after the join.
4. Test independent WASD movement, mouse aiming, firing, reload and mouse-directed dash for every slot.
5. Compare health, ammo, enemy HP, wave count and boss identity on all screens.
6. Defeat normal waves and bosses; make sure the host's upgrade selection advances everyone.
7. Test wraparound movement at the 192x192 seam, pickup healing, ranger appearance and character passives.
8. Leave and reconnect one guest, then test another wave. Confirm the host isn't affected by a dropout.
9. Note average and minimum FPS during large swarms. Native 60 FPS is a goal, NOT a verified result.
10. If connecting fails, check client isolation, UDP/firewall restrictions, wrong IP address and router policies.

Not validated on real physical computers in the authoring sandbox.
