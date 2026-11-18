extends RefCounted
## Authored operations for Woodland Watch. Chapter numbers are one-based.
## A chapter's training becomes available after that chapter is cleared.

const MISSIONS := [
    {
        "title": "The Silent Bell",
        "briefing": "Hold the bell clearing through three attacks. Once the bell rings, face the Crowned Menace.",
        "objective_type": "hold",
        "objective": "Scout Post bell",
        "start": Vector2(27, 27),
        "site": Vector2(35, 25),
        "weather": "clear",
        "guard_seconds": 12.0,
        "roster": ["normal", "speedy", "normal", "speedy", "normal", "speedy"],
        "reinforcements": ["normal", "speedy"],
        "boss": "king",
        "boss_count": 1,
        "reward_acorns": 16
    },
    {
        "title": "Poison at Reedwater",
        "briefing": "Recover filter cores from the creek raiders, then bring the Reedwater sluice back online.",
        "objective_type": "salvage",
        "objective": "Reedwater sluice",
        "start": Vector2(58, 34),
        "site": Vector2(64, 45),
        "weather": "mist",
        "guard_seconds": 15.0,
        "roster": ["toxic", "speedy", "spitter", "normal", "toxic", "spitter", "toxic"],
        "reinforcements": ["speedy", "toxic"],
        "boss": "toxicboss",
        "boss_count": 1,
        "reward_acorns": 20
    },
    {
        "title": "Cold Iron Crossing",
        "briefing": "Walk beside the thaw pump cart and clear the road as it moves between stops.",
        "objective_type": "escort",
        "objective": "Crossing thaw pump",
        "start": Vector2(81, 74),
        "site": Vector2(89, 66),
        "weather": "snow",
        "guard_seconds": 18.0,
        "roster": ["armored", "speedy", "armored", "ranger", "speedy", "guard", "armored", "ranger"],
        "reinforcements": ["armored", "speedy"],
        "boss": "frostboss",
        "boss_count": 1,
        "reward_acorns": 24
    },
    {
        "title": "Four Voices in Fern Hollow",
        "briefing": "Reach the three relay posts in order. Each signal brings a stronger Council response.",
        "objective_type": "relay",
        "objective": "Fern Hollow relay",
        "start": Vector2(42, 89),
        "site": Vector2(51, 96),
        "weather": "clear",
        "guard_seconds": 21.0,
        "roster": ["guard", "skirmisher", "healer", "normal", "guard", "ranger", "skirmisher", "healer"],
        "reinforcements": ["guard", "skirmisher"],
        "boss": "council",
        "boss_count": 4,
        "reward_acorns": 30
    },
    {
        "title": "Below the Rootline",
        "briefing": "Hunt the tunnel wardens. Eliminate the marked targets before the Burrower emerges.",
        "objective_type": "hunt",
        "objective": "Rootline seismograph",
        "start": Vector2(112, 104),
        "site": Vector2(123, 99),
        "weather": "rain",
        "guard_seconds": 22.0,
        "roster": ["bombardier", "skirmisher", "armored", "bombardier", "healer", "guard", "bombardier", "skirmisher"],
        "reinforcements": ["bombardier", "armored"],
        "boss": "burrower",
        "boss_count": 1,
        "reward_acorns": 34
    },
    {
        "title": "The Lightning Line",
        "briefing": "Disarm the storm capacitors at four sites. Stay close to each capacitor to ground it under fire.",
        "objective_type": "sabotage",
        "objective": "East Ridge lightning mast",
        "start": Vector2(133, 55),
        "site": Vector2(143, 47),
        "weather": "wind",
        "guard_seconds": 24.0,
        "roster": ["ranger", "speedy", "bombardier", "ranger", "guard", "spitter", "ranger", "skirmisher", "healer"],
        "reinforcements": ["ranger", "speedy"],
        "boss": "stormboss",
        "boss_count": 1,
        "reward_acorns": 38
    },
    {
        "title": "Threads Across the Trail",
        "briefing": "Survive the Empress's ambush. Keep moving through the woods until the trail opens.",
        "objective_type": "survive",
        "objective": "Silkwood trail winch",
        "start": Vector2(97, 149),
        "site": Vector2(105, 160),
        "weather": "mist",
        "guard_seconds": 26.0,
        "roster": ["skirmisher", "spitter", "skirmisher", "healer", "guard", "spitter", "skirmisher", "armored", "healer", "guard"],
        "reinforcements": ["skirmisher", "spitter"],
        "boss": "weaver",
        "boss_count": 1,
        "reward_acorns": 44
    },
    {
        "title": "Last Watch",
        "briefing": "Reinforce five beacon posts. Move to each marked position and hold it under the final assault.",
        "objective_type": "rotation",
        "objective": "Nightwatch beacon",
        "start": Vector2(155, 147),
        "site": Vector2(167, 142),
        "weather": "rain",
        "guard_seconds": 30.0,
        "roster": ["armored", "bombardier", "spitter", "guard", "ranger", "healer", "skirmisher", "bombardier", "ranger", "armored", "toxic", "speedy"],
        "reinforcements": ["bombardier", "guard"],
        "boss": "nutpocalypse",
        "boss_count": 1,
        "reward_acorns": 60
    }
]

# Each entry is granted on the following deployment based on prior chapter clears.
# Rarity values refer to the existing upgrade strength tiers.
const APPROACH_WAVES := [3, 3, 4, 3, 4, 4, 4, 5]
const FIELD_OFFSETS := [Vector2.ZERO, Vector2(5, 3), Vector2(9, -2), Vector2(5, -7), Vector2(-2, -5)]
const ADDITIONAL_ENEMIES := ["charger", "grenadier", "splitter", "wisp", "bulwark", "stalker"]

const SQUAD_TRAINING := [
    [["FOREST_BOOTS", 0], ["ECHO_DASH", 0]],
    [["BARK_ARMOR", 0], ["STINK_REPELLENT", 0]],
    [["ICE_ROUNDS", 0], ["ACORN_MAGNET", 0]],
    [["FIRE_ROUNDS", 0], ["BLOODSCENT", 0]],
    [["CHAIN_LIGHTNING", 0], ["ACORN_FEAST", 0], ["BARK_ARMOR", 1]],
    [["ACORN_SATELLITES", 4]],
    [["ENTROPY_NOVA", 4], ["ABSOLUTE_ZERO", 4], ["SINGULARITY_SHELLS", 4]],
    [["OVERKILL_ENGINE", 4]]
]

const WEAPON_TRAINING := {
    "shotgun": ["DRAGONS_BREATH", "ICE_BUCK", "DOUBLE_TAP", "SHATTER_BLAST"],
    "pistol": ["QUICKDRAW", "LUCKY_CHAMBER", "FAN_FIRE", "FROST_TIP"],
    "smg": ["OVERCLOCK", "INCENDIARY_FEED", "SPRAY_N_PRAY", "ICE_STREAM"],
    "ar": ["HOLLOWPOINT", "BURST_CORE", "RICOCHET_ROUNDS", "CRYO_BURST"],
    "sniper": ["DEADEYE", "PIERCE", "THERMAL_LANCE", "GLACIAL_SPIKE"],
    "railgun": ["CAPACITOR", "PHASE_DRILL", "ION_STORM", "OVERCHARGE"]
}
const WEAPON_TRAINING_MILESTONES := [1, 3, 5, 7]

static func training_for_chapter(chapter_number: int, weapon: String) -> Array[Dictionary]:
    return training_for_clears(chapter_number - 1, weapon)

static func training_for_clears(completed_count: int, weapon: String) -> Array[Dictionary]:
    var training: Array[Dictionary] = []
    for index in range(clampi(completed_count, 0, SQUAD_TRAINING.size())):
        for grant in SQUAD_TRAINING[index]:
            training.append({"id": grant[0], "rarity": grant[1], "scope": "squad"})
    var upgrades: Array = WEAPON_TRAINING.get(weapon, [])
    for index in range(upgrades.size()):
        if completed_count >= WEAPON_TRAINING_MILESTONES[index]:
            training.append({"id": upgrades[index], "rarity": 0, "scope": "weapon"})
    return training
