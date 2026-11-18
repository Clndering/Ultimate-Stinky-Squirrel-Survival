extends RefCounted

const MAX_LEVEL := 50
const XP_PER_LEVEL := 250
const MAX_PRESTIGE := 3
const OUTFITS := {
    "sunwarden":{"name":"Sunwarden","perk":"+65% damage, +50 maximum HP","requirement":"Prestige 1","kind":"prestige","value":1,"damage":1.65,"health":150.0,"speed":1.0,"tint":Color("#ffcf63")},
    "stormwarden":{"name":"Stormwarden","perk":"+100% damage, +75 maximum HP, +22% speed","requirement":"Prestige 2","kind":"prestige","value":2,"damage":2.0,"health":175.0,"speed":1.22,"tint":Color("#8de4ff")},
    "voidwarden":{"name":"Voidwarden","perk":"+150% damage, +100 maximum HP, +30% speed, fire and ice","requirement":"Prestige 3","kind":"prestige","value":3,"damage":2.5,"health":200.0,"speed":1.30,"tint":Color("#e3a3ff")}
}

static func level(field_xp: int) -> int:
    return clampi(1 + maxi(field_xp, 0) / XP_PER_LEVEL, 1, MAX_LEVEL)

static func enemy_scale(top_level: int) -> float:
    return 1.0 + .02 * (clampi(top_level, 1, MAX_LEVEL) - 1)
