extends RefCounted

# Each attack locks its target when the warning appears.
const PATTERNS := {
    "king": [["charge", "cleave"], ["charge_combo", "cleave", "rings"]],
    "toxicboss": [["poison_bloom", "fan"], ["poison_bloom", "toxic_grid", "fan"]],
    "frostboss": [["ice_cross", "rings"], ["ice_cross", "shards", "rings"]],
    "council": [["lance", "cleave"], ["crossfire", "lance", "split_rings"]],
    "burrower": [["tunnel", "cleave"], ["tunnel", "minefield", "charge_combo"]],
    "stormboss": [["storm", "lance"], ["storm", "crossfire", "split_rings"]],
    "weaver": [["web", "fan"], ["web", "minefield", "crossfire"]],
    "nutpocalypse": [["crossfire", "rings", "shards"], ["charge_combo", "reactor", "split_rings", "crossfire"]]
}

static func action(kind: String, enraged: bool, index: int) -> String:
    var phase: Array = PATTERNS[kind][1 if enraged else 0]
    return phase[posmod(index, phase.size())]
