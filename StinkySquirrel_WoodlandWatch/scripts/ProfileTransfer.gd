extends RefCounted

const FORMAT := "woodland-watch-progress"
const VERSION := 1
const RangerProgress := preload("res://scripts/RangerProgress.gd")
const MAX_BYTES := 262144
const COUNTER_LIMIT := 2000000000
const COUNTERS := ["kills", "best_wave", "boss_kills", "acorns", "field_xp", "late_veteran_clears", "prestige"]

static func encode(profile: Dictionary) -> String:
    return JSON.stringify({"format": FORMAT, "version": VERSION, "progress": profile}, "  ") + "\n"

static func _count(value: Variant, limit: int = COUNTER_LIMIT) -> int:
    if not (value is int or value is float):
        return -1
    var number := float(value)
    if not is_finite(number) or number < 0.0 or number > float(limit) or floorf(number) != number:
        return -1
    return int(number)

static func decode(text: String, weapon_skins: Dictionary, outfits: Dictionary,
        enemies: Array, chapters: int) -> Dictionary:
    if text.length() > MAX_BYTES or text.to_utf8_buffer().size() > MAX_BYTES:
        return {"error": "That file is too large for a Woodland Watch save."}
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary) or parsed.get("format") != FORMAT or _count(parsed.get("version"), VERSION) != VERSION:
        return {"error": "Choose a Woodland Watch progress file exported from this menu."}
    var raw: Variant = parsed.get("progress")
    if not (raw is Dictionary) or not raw.has("campaign_clears") or not raw.has("field_xp"):
        return {"error": "This file is missing its progress data."}

    var profile := {}
    for key in COUNTERS:
        var amount := _count(raw.get(key, 0))
        if amount < 0 or (key == "prestige" and amount > RangerProgress.MAX_PRESTIGE):
            return {"error": "The save has an invalid progress total."}
        profile[key] = amount
    var cleared := _count(raw.get("campaign_clears"), chapters)
    var rules := _count(raw.get("unlock_rules_version", 2), COUNTER_LIMIT)
    if cleared < 0 or rules < 1:
        return {"error": "The save has invalid campaign progress."}
    profile.campaign_clears = cleared
    profile.unlock_rules_version = rules
    profile.weapon = raw.weapon if raw.get("weapon") is String and weapon_skins.has(raw.weapon) else "shotgun"
    profile.character = raw.character if raw.get("character") is String and outfits.has(raw.character) else "scout"

    var possible_skins: Array = []
    for weapon in weapon_skins:
        for i in range(1, weapon_skins[weapon].size()):
            possible_skins.append("%s:%d" % [weapon, i])
    var allowed := {
        "weapon_kills": weapon_skins.keys(), "gun_skins": weapon_skins.keys(), "chapter_completions": [],
        "discovered": enemies, "earned_weapons": weapon_skins.keys(), "earned_skins": possible_skins,
        "earned_outfits": outfits.keys()
    }
    for chapter in range(1, chapters + 1):
        allowed.chapter_completions.append(str(chapter))
    for key in allowed:
        var source: Variant = raw.get(key, {})
        if not (source is Dictionary):
            return {"error": "The save has an invalid gear or chapter list."}
        var filtered := {}
        for id in allowed[key]:
            if not source.has(id):
                continue
            var value: Variant = source[id]
            match key:
                "weapon_kills", "chapter_completions":
                    var amount := _count(value)
                    if amount < 0:
                        return {"error": "The save has an invalid kill or chapter count."}
                    filtered[id] = amount
                "gun_skins":
                    if value is String and weapon_skins[id].has(value):
                        filtered[id] = value
                _:
                    if value is bool and value:
                        filtered[id] = true
        profile[key] = filtered
    return {"progress": profile}
