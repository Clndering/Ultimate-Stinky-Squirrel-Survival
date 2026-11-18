extends RefCounted

## A pair debuts in each operation. Earlier pairs return as reinforcements.
const DEBUTS := [
    ["acorn_caster","bramble_skipper"],
    ["reed_spitter","creek_spinner"],
    ["rime_lancer","hail_hopper"],
    ["council_piper","acorn_marshal"],
    ["root_borer","spore_pod"],
    ["bolt_scribe","thunder_fan"],
    ["silk_diver","loom_warden"],
    ["core_sentinel","cinder_comet"]
]

# Profile fields: name, field description, health, speed, damage, attack, movement, accent.
const ROSTER := {
    "acorn_caster":["Acorn Caster","Throws a short three-shot spread, then backs out of reach.",54,72,8,"triplet","kite","#f9b66a"],
    "bramble_skipper":["Bramble Skipper","Races across your aim and leaves a pair of shots behind.",58,120,9,"trail","strafe","#acf490"],
    "reed_spitter":["Reed Spitter","Fires a poison fan with wide lanes between shots.",66,68,9,"fan","kite","#92df80"],
    "creek_spinner":["Creek Spinner","Sends slow pinwheel rings from the streambank.",62,85,9,"pinwheel","orbit","#7de6d0"],
    "rime_lancer":["Rime Lancer","Draws a frost lane, then sends a locked three-shot burst.",92,66,12,"lane","anchor","#a5ddff"],
    "hail_hopper":["Hail Hopper","Cuts across the clearing and fires two crossing fans.",67,112,9,"cross","strafe","#d1e9fd"],
    "council_piper":["Council Piper","Marks a series of shots that sweeping movement can dodge.",84,78,10,"sweep","orbit","#ebc890"],
    "acorn_marshal":["Acorn Marshal","Fires paired diagonal lanes and holds its distance.",128,59,15,"gates","anchor","#ffe298"],
    "root_borer":["Root Borer","Warns before a fast charge and fires a ring from its starting point.",100,102,13,"rush","press","#ccae85"],
    "spore_pod":["Spore Pod","Plants a bloom under a ranger that bursts into slow spores.",96,52,12,"pod","anchor","#d6a2f0"],
    "bolt_scribe":["Bolt Scribe","Sets up two parallel lines with a safe channel between them.",94,86,12,"channel","kite","#ffe976"],
    "thunder_fan":["Thunder Fan","Alternates a wide shot spread with a phase-shifted ring.",102,90,12,"thunder","orbit","#bba2ff"],
    "silk_diver":["Silk Diver","Drops a snare and spreads cold shots outward from its landing zone.",87,121,12,"snare","strafe","#f6c9e4"],
    "loom_warden":["Loom Warden","Casts a wide moving curtain with a gap near the middle.",136,61,15,"curtain","anchor","#fac3a8"],
    "core_sentinel":["Core Sentinel","Launches two offset rings with different speeds.",155,71,17,"double_ring","press","#ff8a6b"],
    "cinder_comet":["Cinder Comet","Circles the squad and sweeps a long rotating burst.",103,130,14,"spiral","orbit","#ffb15d"]
}

const WAVE_OBJECTIVES := [
    ["hold","capture","quota"],
    ["salvage","flag","hold"],
    ["escort","quota","escort","survive"],
    ["relay","capture","flag"],
    ["hunt","quota","flag","hunt"],
    ["sabotage","capture","sabotage","survive"],
    ["survive","flag","hunt","capture"],
    ["rotation","quota","flag","capture","rotation"]
]

const OBJECTIVE_NAMES := {
    "hold":"Hold the point", "capture":"Capture the objective", "quota":"Defeat the squad",
    "flag":"Capture the flag", "salvage":"Recover supplies", "escort":"Escort the cart",
    "survive":"Survive the ambush", "relay":"Activate the relay", "hunt":"Hunt wardens",
    "sabotage":"Ground the capacitor", "rotation":"Defend the next beacon"
}

static func previous_debuts(chapter: int) -> Array[String]:
    var earlier: Array[String] = []
    for index in range(chapter - 1):
        earlier.append_array(DEBUTS[index])
    return earlier
