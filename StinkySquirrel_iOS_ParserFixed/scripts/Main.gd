extends Node2D
## Stinky Squirrel: Nightwatch — native fidelity-port WORK IN PROGRESS.
## The original source is supplied unchanged in reference/ for exhaustive parity work.
## This native implementation is independent of HTML, JavaScript, WebView and .NET.

const MAP := 192.0
const PORT := 27844
const HOST_ID := 1
const MAX_GUESTS := 5
const CENTER := Vector2(640, 368)
const BOSS_KINDS := ["king","toxicboss","frostboss","council","burrower","stormboss","weaver","nutpocalypse"]
const BOSS_NAMES := ["THE CROWNED MENACE","TOXIC MATRIARCH","FROST BARON","THE ACORN COUNCIL","CLOCKWORK BURROWER","STORM HERALD","THE SILKEN EMPRESS","THE NUTPOCALYPSE"]
const BOSS_WAVES := [5,10,15,20,25,30,35,40]
const WEAPONS := {
    "shotgun":{"name":"Shotgun","ammo":6,"cooldown":.52,"reload":1.25,"damage":18.0,"pellets":6,"spread":.66,"range":385.0,"unlock":0},
    "pistol":{"name":"Pistol","ammo":12,"cooldown":.22,"reload":.95,"damage":15.0,"pellets":1,"spread":.06,"range":473.0,"unlock":110},
    "smg":{"name":"SMG","ammo":28,"cooldown":.085,"reload":1.4,"damage":8.5,"pellets":1,"spread":.18,"range":330.0,"unlock":250},
    "ar":{"name":"AR","ammo":20,"cooldown":.14,"reload":1.3,"damage":11.0,"pellets":1,"spread":.09,"range":462.0,"unlock":425},
    "sniper":{"name":"Sniper","ammo":4,"cooldown":.95,"reload":1.5,"damage":58.0,"pellets":1,"spread":.025,"range":682.0,"unlock":650},
    "railgun":{"name":"RAILGUN","ammo":3,"cooldown":1.32,"reload":2.25,"damage":295.0,"pellets":1,"spread":0.0,"range":1155.0,"unlock":2400}
}
const WEAPON_ORDER := ["shotgun","pistol","smg","ar","sniper","railgun"]
const CHARACTER_SKINS := {
    "scout":{"name":"Forest Scout","perk":"No passive bonus","requirement":"Starter ranger","kind":"starter","value":0},
    "trailblazer":{"name":"Trailblazer","perk":"+14% movement speed","requirement":"180 total kills","kind":"kills","value":180},
    "sharpsight":{"name":"Sharpsight","perk":"+12% weapon damage","requirement":"Reach wave 10","kind":"wave","value":10},
    "ironbark":{"name":"Ironbark","perk":"+35 maximum HP","requirement":"Defeat 5 bosses","kind":"bosses","value":5},
    "cindercloak":{"name":"Cindercloak","perk":"Igniting shots","requirement":"600 total kills","kind":"kills","value":600},
    "frostbound":{"name":"Frostbound","perk":"Freezing shots","requirement":"Wave 20 and 8 bosses","kind":"special","value":8}
}
const SKIN_OPTIONS := {
    "shotgun":["Woodland","Blaze Core","Aurora Moss"],
    "pistol":["Courier","Cherry Volt","Blue Ember"],
    "smg":["Scrapwire","Slime Pop","Neon Static"],
    "ar":["Canopy","Sunset","Royal Fern"],
    "sniper":["Long Night","Icepine","Golden Hush"],
    "railgun":["Void Prism","Starfall","Solar Reactor","Celestial Static"]
}
# Cosmetic unlock missions mirror the original HTML source. An already-equipped
# skin from an earlier native build remains accessible, even if requirements changed.
const GUN_SKIN_REQUIREMENTS := {
    "shotgun":[["starter",0],["weapon_kills",116],["best_wave",11]],
    "pistol":[["total_kills",116],["weapon_kills",87],["boss_kills",3]],
    "smg":[["total_kills",261],["weapon_kills",145],["best_wave",15]],
    "ar":[["total_kills",406],["weapon_kills",160],["boss_kills",6]],
    "sniper":[["total_kills",609],["weapon_kills",131],["best_wave",20]],
    "railgun":[["railgun",0],["weapon_kills",218],["best_wave",46],["boss_kills",38]]
}
const ADMIN_BACKUP_FILE := "user://stinky_squirrel_admin_original_backup.json"
const ADMIN_PASSWORD := "1234"
const ADMIN_COMMANDS := ["/help", "/status", "/unlockall", "/unlockoriginal"]
const RARITY_NAMES := ["Common","Uncommon","Rare","Epic","Legendary"]
const RARITY_WEIGHTS := [47,28,15,8,2]
const RARITY_SCALES := [1.0,1.28,1.7,2.2,3.0]
const RARITY_COLORS := ["#e7dfca","#a6ec96","#78c6ff","#d6a2ff","#ffd469"]
const GENERAL_UPGRADES := {
    "FOREST_BOOTS":"Move 12% faster", "BARK_ARMOR":"+24 max HP and heal", "ACORN_FEAST":"Heal 35 HP and gain 3 permanent acorns", "ECHO_DASH":"Dash recharges faster",
    "STINK_REPELLENT":"Poison and ice resist +30%", "CHAIN_LIGHTNING":"Hits can arc to another squirrel", "FIRE_ROUNDS":"Bullets ignite enemies",
    "ICE_ROUNDS":"Bullets chill enemies", "BLOODSCENT":"Damage restores a small amount of health", "ACORN_MAGNET":"Acorns drift toward players"
}
const UNIQUE_UPGRADES := {
    "shotgun":{"DRAGONS_BREATH":"Shotgun shells ignite","ICE_BUCK":"Buckshot freezes enemies","DOUBLE_TAP":"Shotgun fires an echo blast","SHATTER_BLAST":"Frozen kills create bursts"},
    "pistol":{"QUICKDRAW":"Faster trigger and reload","LUCKY_CHAMBER":"Every 5th shot is stronger","FAN_FIRE":"Extra rapid fire","FROST_TIP":"Pistol builds chill"},
    "smg":{"SPRAY_N_PRAY":"Wider and denser spray","OVERCLOCK":"SMG fires faster","INCENDIARY_FEED":"Flaming rounds","ICE_STREAM":"SMG chill stream"},
    "ar":{"BURST_CORE":"Three-round bursts","RICOCHET_ROUNDS":"Rounds chain to nearby targets","HOLLOWPOINT":"Bonus damage","CRYO_BURST":"Icy burst rounds"},
    "sniper":{"DEADEYE":"Critical damage while steady","PIERCE":"Shots pierce extra enemies","THERMAL_LANCE":"Piercing flame lance","GLACIAL_SPIKE":"Frozen piercing spikes"},
    "railgun":{"CAPACITOR":"Faster railgun charging","PHASE_DRILL":"More railgun penetration","ION_STORM":"Chain lightning","OVERCHARGE":"More boss damage"}
}
const LEGENDARY_UPGRADES := {
    "ENTROPY_NOVA":"Periodic burning shockwaves",
    "SINGULARITY_SHELLS":"Hits cause area explosions",
    "ABSOLUTE_ZERO":"Huge area freezing pulses",
    "ACORN_SATELLITES":"Orbiting offensive acorns",
    "OVERKILL_ENGINE":"Damage increases with kills"
}
const ENEMY_DESCRIPTIONS := {
    "normal":"The ordinary Stinky Squirrel. Reliable, aggressive and numerous.",
    "speedy":"A fast and fragile squirrel that punishes standing still.",
    "toxic":"Leaves lingering poisonous clouds.",
    "armored":"Heavy bark protection and more health.",
    "spitter":"Fires dangerous toxic shots from a distance.",
    "skirmisher":"A nimble flanker that chases from unexpected angles.",
    "bombardier":"Throws explosive acorns to deny space.",
    "healer":"Restores health to neighboring squirrels.",
    "guard":"Protects its allies while absorbing damage.",
    "ranger":"A distant sharpshooter that harasses your squad.",
    "king":"Charging royal squirrel with summoned reinforcements.",
    "toxicboss":"A poison queen unleashing toxic pools and projectiles.",
    "frostboss":"Creates frost zones and icy projectiles.",
    "council":"Four dangerous captains fighting together.",
    "burrower":"Underground ambushes and explosive mines.",
    "stormboss":"Lightning strikes and electric volleys.",
    "weaver":"Web traps and summoning attacks.",
    "nutpocalypse":"Huge mechanical squirrel with explosions and beams."
}
# Squad-shared XP: every enemy drops a collectable prism; all allies level together.
const XP_VALUE := {"normal":8,"speedy":10,"toxic":12,"armored":17,"spitter":14,"skirmisher":14,"bombardier":19,"healer":17,"guard":19,"ranger":16,"king":180,"toxicboss":210,"frostboss":210,"council":125,"burrower":270,"stormboss":300,"weaver":330,"nutpocalypse":510}
const ENC_SPRITES := {"normal":"squirrel","speedy":"speedy","toxic":"toxic","armored":"bruiser","spitter":"toxic","king":"boss","toxicboss":"boss","frostboss":"boss","council":"boss","burrower":"boss","stormboss":"boss","weaver":"boss","nutpocalypse":"boss"}
const UPGRADE_ICONS := {"FOREST_BOOTS":"👢","BARK_ARMOR":"🛡","ACORN_FEAST":"🌰","ECHO_DASH":"💨","STINK_REPELLENT":"☣","CHAIN_LIGHTNING":"⚡","FIRE_ROUNDS":"🔥","ICE_ROUNDS":"❄","BLOODSCENT":"♥","ACORN_MAGNET":"🧲"}
const ENEMY_ORDER := ["normal","speedy","toxic","armored","spitter","skirmisher","bombardier","healer","guard","ranger"]
const ENEMY_STATS := {
    "normal":[44.0,82.0,12.0],"speedy":[30.0,132.0,10.0],"toxic":[56.0,75.0,12.0],"armored":[125.0,55.0,18.0],"spitter":[68.0,66.0,9.0],
    "skirmisher":[45.0,148.0,10.0],"bombardier":[95.0,65.0,14.0],"healer":[62.0,72.0,8.0],"guard":[125.0,58.0,17.0],"ranger":[62.0,65.0,10.0],
    "king":[480.0,84.0,22.0],"toxicboss":[560.0,74.0,20.0],"frostboss":[520.0,78.0,20.0],"council":[370.0,88.0,16.0],
    "burrower":[650.0,83.0,26.0],"stormboss":[690.0,86.0,22.0],"weaver":[750.0,78.0,22.0],"nutpocalypse":[1250.0,62.0,30.0]
}

var admin_mode: bool = false
var admin_authenticated: bool = false
var admin_return_page: String = "title"
var admin_password_field: LineEdit
var admin_command_field: LineEdit
var admin_messages: Array[String] = []
var quit_dialog: ConfirmationDialog
var pending_exit_action: String = "quit"
var rng := RandomNumberGenerator.new()
var world
var ui_layer: CanvasLayer
var ui_root: Control
var mobile_touch
var mobile_web: bool = false
var menu_backdrop: TextureRect
var hud_status_box: PanelContainer
var page: String = "title"
var mode: String = "solo"  # solo, host, guest
var local_id: int = 1
var camera_pos: Vector2 = Vector2(27,27)
var players: Dictionary = {}
var enemies: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var obstacle_cells: Dictionary = {}
var hazards: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var traces: Array[Dictionary] = []
var particles: Array[Dictionary] = []
# Enemy attacks are actual moving, dodgeable stink blobs, never instant hitscan lines.
# Position and velocity are authoritative on the host and replicated to guests.
const MAX_ENEMY_BLOBS: int = 80
var enemy_blobs: Array[Dictionary] = []
var enemy_blob_interp: float = 0.0
var player_inputs: Dictionary = {}
var next_enemy_id: int = 1
var wave: int = 0
var to_spawn: int = 0
var spawn_timer: float = 0.0
var elapsed: float = 0.0
var stage_kills: int = 0
var run_acorns: int = 0
var xp_drops: Array[Dictionary] = []
var run_id: int = 0
var observed_guest_run_id: int = -1
var last_guest_kills: int = 0
var run_level: int = 1
var run_xp: float = 0.0
var xp_to_next: float = 70.0
var pending_level_choices: int = 0
var xp_vacuum: bool = false
var wave_clear_grace: float = 0.3
var hud_xp_meter: StinkyHudMeter
var hud_xp_label: Label
var hud_xp_box: PanelContainer
var day_phase: float = 0.25
var weather: String = "clear"
var weather_timer: float = 0.0
var snapshot_timer: float = 0.0
var novelty_timer: float = 0.0
var boss_name: String = ""
var upgrade_choices: Array[Dictionary] = []
var upgrades_taken: Array[Dictionary] = []
var progress: Dictionary = {}
# All optional GPU post-process effects default OFF to preserve native frame rate.
# Lighting and visual quality can be customized independently in Settings > Graphics.
const GRAPHICS_EFFECTS := [
    {"id":"fx_god_rays","name":"God Rays / Sun Shafts","desc":"GPU sunlight scattering sampled toward the visible sun.","group":"LIGHT & ATMOSPHERE","cost":"MEDIUM"},
    {"id":"fx_bloom","name":"Bloom / Glow","desc":"GPU highlight bleed around luminous pixels.","group":"LIGHT & ATMOSPHERE","cost":"MEDIUM"},
    {"id":"fx_fog","name":"Atmospheric Fog","desc":"Layered depth-cue fog; actual 3D volumetric fog requires a 3D scene.","group":"LIGHT & ATMOSPHERE","cost":"LOW"},
    {"id":"fx_ssao","name":"Ambient Occlusion","desc":"GPU screen-edge darkening, not 3D depth-buffer SSAO.","group":"LIGHT & ATMOSPHERE","cost":"MEDIUM"},
    {"id":"fx_contact_shadows","name":"Contact Shadows","desc":"Native shadows underneath characters, squirrels, and scenery.","group":"LIGHT & ATMOSPHERE","cost":"LOW"},
    {"id":"fx_color_grade","name":"Color Grading","desc":"Warm daylight, cold nights, and tonal color correction.","group":"COLOR & FINISH","cost":"LOW"},
    {"id":"fx_vignette","name":"Vignette","desc":"Gently darkens screen edges.","group":"COLOR & FINISH","cost":"LOW"},
    {"id":"fx_tonemap","name":"Tone Mapping","desc":"Filmic contrast mapping of the rendered 2D image.","group":"COLOR & FINISH","cost":"LOW"},
    {"id":"fx_chromatic","name":"Chromatic Aberration","desc":"Subtle RGB separation around edges.","group":"LENS & MOTION","cost":"LOW"},
    {"id":"fx_outlines","name":"Stylized Outlines","desc":"GPU contrast-edge ink around sprites and terrain.","group":"STYLE & SURFACES","cost":"MEDIUM"},
    {"id":"fx_reflections","name":"Wet-Surface Reflections","desc":"Native wet-ground glints; full SSR requires 3D depth/normal buffers.","group":"STYLE & SURFACES","cost":"LOW"},
    {"id":"fx_lens_flare","name":"Lens Flare","desc":"GPU ghosts and streaks around bright daylight.","group":"LENS & MOTION","cost":"LOW"},
    {"id":"fx_grain","name":"Film Grain / Noise","desc":"Low-amplitude animated film texture.","group":"COLOR & FINISH","cost":"LOW"},
    {"id":"fx_long_exposure","name":"Long Exposure Trails","desc":"Enhanced projectile streaks that fade naturally.","group":"LENS & MOTION","cost":"LOW"}
]
const FX_STRENGTH_DEFAULT := 0.32
var settings: Dictionary = {"fps":true,"weather":true,"music":true,"novelty":false,"graphics":"Original Pixels", "fx_aa":"Off", "fx_aniso":false}
var graphics_tab: String = "general"
var settings_return_page: String = "title"
var fx_layer: CanvasLayer
var fx_rect: ColorRect
var fx_material: ShaderMaterial
var fx_time: float = 0.0
var last_camera_pos: Vector2 = Vector2(27,27)
var hud_left_box: PanelContainer
var hud_right_box: PanelContainer
var hud_upgrade_box: PanelContainer
var hud_hp_bar: ProgressBar
var hud_hp_meter: StinkyHudMeter
var hud_ammo_meter: StinkyHudMeter
var hud_dash_meter: StinkyHudMeter
var hud_cached: Dictionary = {}
var save_dirty: bool = false
var save_seconds: float = 0.0
var hud_fps_seconds: float = 0.0
var upgrades_rerolled: bool = false
var settings_scroll: ScrollContainer
var encyclopedia_tab := "enemies"
var toast_message := ""
var toast_timer := 0.0
var ui_links: Array[Control] = []
var buttons: Array[Button] = []
var hud_left: Label
var hud_right: Label
var hud_enemy_count: Label
var hud_kill_count: Label
var hud_best_wave: Label
var hud_acorns_collected: Label
var hud_acorns_saved: Label
var hud_upgrades: VBoxContainer
var main_panel: PanelContainer
var main_layout: VBoxContainer
var connection_text: LineEdit
var message_label: Label
var import_dialog: FileDialog
var badge: Label
var music: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var sfx: Dictionary = {}

func _ready() -> void:
    rng.randomize()
    mobile_web = _is_mobile_web()
    Engine.max_fps = 60 if OS.has_feature("web") else 120
    RenderingServer.set_default_clear_color(Color("172f38"))
    set_process_input(true)
    # Keep OS close/Alt-F4 from bypassing the quit confirmation.
    get_tree().auto_accept_quit = false
    _load_progress()
    if not settings.has("touch_controls"):
        settings["touch_controls"] = mobile_web
    # Safari's WebGL2/WASM pipeline benefits from an inexpensive pixel preset.
    # Do not automatically erase desktop graphics preferences from the save.
    if mobile_web:
        settings["fx_bloom"] = false
        settings["fx_chromatic"] = false
        settings["fx_vignette"] = false
        settings["fps"] = false
        settings["graphics"] = "Performance"
    world = preload("res://scripts/World.gd").new()
    world.game = self
    add_child(world)
    _make_gpu_fx()
    _make_ui()
    _make_quit_dialog()
    _make_audio()
    multiplayer.peer_connected.connect(_peer_connected)
    multiplayer.peer_disconnected.connect(_peer_disconnected)
    multiplayer.connected_to_server.connect(_joined_server)
    multiplayer.connection_failed.connect(_failed_connection)
    multiplayer.server_disconnected.connect(_server_disconnected)
    _create_obstacles()
    _apply_graphics_settings()
    _show_page("title")

func _is_mobile_web() -> bool:
    if not OS.has_feature("web"):
        return false
    if DisplayServer.is_touchscreen_available():
        return true
    return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0", true))

func _touch_active() -> bool:
    return mobile_touch != null and mobile_touch.visible

func _mobile_menu_requested() -> void:
    if page != "playing":
        return
    if mode == "guest":
        _return_menu_immediately()
    else:
        _show_page("paused")

func _make_audio() -> void:
    music = AudioStreamPlayer.new()
    add_child(music)
    music.stream = load("res://audio/forest_loop.wav")
    music.volume_db = -22
    music.finished.connect(func(): music.play())
    boss_music = AudioStreamPlayer.new()
    add_child(boss_music)
    boss_music.stream = load("res://audio/boss_theme.ogg")
    boss_music.volume_db = -15
    boss_music.finished.connect(func(): boss_music.play())
    for key in ["shotgun","reload","chitter","upgrade","hurt"]:
        var a := AudioStreamPlayer.new()
        a.stream = load("res://audio/%s.wav" % key)
        a.volume_db = -13
        add_child(a)
        sfx[key] = a

func _sound(key: String) -> void:
    if settings.get("music",true) and sfx.has(key):
        sfx[key].stop()
        sfx[key].play()

# Save at a bounded cadence, not once per enemy killed (a source of frame stalls).
func _save_progress() -> void:
    save_dirty = true

func _flush_progress() -> void:
    if not save_dirty:
        return
    var f := FileAccess.open("user://stinky_squirrel_native_save.json",FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify({"progress":progress,"settings":settings,"admin_mode":admin_mode}))
        save_dirty = false
        save_seconds = 0.0

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Avoid double prompts if the user clicks the window X more than once.
        if quit_dialog != null and not quit_dialog.visible:
            _request_exit("quit")
    elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mobile_web and mode == "solo" and page == "playing":
        _show_page("paused")
    elif what == NOTIFICATION_PREDELETE:
        _flush_progress()

func _load_progress() -> void:
    for effect in GRAPHICS_EFFECTS:
        var key: String = str(effect.id)
        settings[key] = key == "fx_contact_shadows"
        settings[key + "_strength"] = FX_STRENGTH_DEFAULT
    progress = {"kills":0,"best_wave":0,"boss_kills":0,"acorns":0,"weapon_kills":{},"discovered":{},"weapon":"shotgun","character":"scout","gun_skins":{}}
    for w in WEAPON_ORDER:
        progress.weapon_kills[w] = 0
        progress.gun_skins[w] = SKIN_OPTIONS[w][0]
    if FileAccess.file_exists("user://stinky_squirrel_native_save.json"):
        var f := FileAccess.open("user://stinky_squirrel_native_save.json",FileAccess.READ)
        if f != null:
            var obj: Variant = JSON.parse_string(f.get_as_text())
            if obj is Dictionary:
                admin_mode = bool(obj.get("admin_mode",false))
                var previous: Dictionary = obj.get("progress",{})
                for key in previous:
                    progress[key] = previous[key]
                var prev_settings: Dictionary = obj.get("settings",{})
                for key in prev_settings:
                    settings[key] = prev_settings[key]

func _create_obstacles() -> void:
    obstacles.clear()
    obstacle_cells.clear()
    for x in range(192):
        for y in range(192):
            var dx := Vector2(float(x),float(y)).distance_to(Vector2(27,27))
            if dx < 9.0:continue
            var h: int = ((x*73856093) ^ (y*19349663) ^ 92821) & 0x7fffffff
            var kind := ""
            if h % 67 == 7:kind = "tree"
            elif h % 89 == 11:kind = "rock"
            elif h % 101 == 9:kind = "stump"
            if kind != "":
                var prop := {"pos":Vector2(x+.5,y+.5),"kind":kind,"radius":.95 if kind=="tree" else (.75 if kind=="rock" else .55)}
                obstacles.append(prop)
                var bucket := Vector2i(int(x/8),int(y/8))
                if not obstacle_cells.has(bucket):obstacle_cells[bucket]=[]
                obstacle_cells[bucket].append(prop)

func nearby_obstacles(pos: Vector2, range_tiles:int=3) -> Array:
    var found: Array = []
    var radius: int = maxi(1, ceili(float(range_tiles)/8.0))
    var bx: int = int(floor(pos.x/8.0))
    var by: int = int(floor(pos.y/8.0))
    for dx in range(-radius,radius+1):
        for dy in range(-radius,radius+1):
            var key:=Vector2i(posmod(bx+dx,24),posmod(by+dy,24))
            if obstacle_cells.has(key):found.append_array(obstacle_cells[key])
    return found

func _wrap_vec(p: Vector2) -> Vector2:
    return Vector2(fposmod(p.x, MAP), fposmod(p.y, MAP))

func _sd(d: float) -> float:
    return fposmod(d + MAP*.5,MAP)-MAP*.5

func _screen_delta(a: Vector2,b: Vector2) -> Vector2:
    return Vector2((_sd(a.x-b.x)-_sd(a.y-b.y))*32.0,(_sd(a.x-b.x)+_sd(a.y-b.y))*16.0)

func _screen_distance(a: Vector2,b: Vector2) -> float:
    return _screen_delta(a,b).length()

func _uniso(v: Vector2) -> Vector2:
    return Vector2(v.x/64.0+v.y/32.0,v.y/32.0-v.x/64.0)

# Collision remains deterministic on the toroidal map; testing only nine small
# spatial buckets per step avoids allocating a navigation mesh for every squirrel.
func _can_occupy(pos: Vector2, collision_radius: float=.48) -> bool:
    for object in nearby_obstacles(pos, 3):
        if _screen_distance(pos, object.pos) < (collision_radius + float(object.radius)) * 24.0:
            return false
    return true

func _move_to(p: Vector2, move: Vector2, radius: float=.48) -> Vector2:
    if move.length_squared() < 0.00000001:
        return p
    var trial: Vector2 = _wrap_vec(p + move)
    if _can_occupy(trial, radius):
        return trial
    # Sliding resolves diagonal collision smoothly instead of stopping dead.
    # These two vectors are independent in *isometric screen space*.
    var movement_pixels: Vector2 = _screen_delta(trial, p)
    var horiz: Vector2 = _wrap_vec(p + _uniso(Vector2(movement_pixels.x, 0.0)))
    var vert: Vector2 = _wrap_vec(p + _uniso(Vector2(0.0, movement_pixels.y)))
    var free_h: bool = _can_occupy(horiz, radius)
    var free_v: bool = _can_occupy(vert, radius)
    if free_h and free_v:
        return horiz if absf(movement_pixels.x) >= absf(movement_pixels.y) else vert
    if free_h:
        return horiz
    if free_v:
        return vert
    return p

# Lightweight obstacle skirt: direct movement first, then a persistent side
# chosen around the obstruction. The short side-memory stops left/right jitter.
# Work beyond the direct movement attempt occurs only near a blocked obstacle.
func _move_enemy_around(enemy: Dictionary, goal_direction: Vector2, step: float, dt: float) -> void:
    if step <= 0.0 or goal_direction.length_squared() < 0.001:
        return
    var position: Vector2 = enemy.pos
    var memory: float = maxf(0.0, float(enemy.get("avoid_time", 0.0)) - dt)
    var side: float = float(enemy.get("avoid_side", 1.0))
    if memory > 0.0:
        var along_wall: Vector2 = goal_direction.rotated(side * 1.16)
        var wall_trial: Vector2 = _move_to(position, _uniso(along_wall * step), 0.3)
        if _screen_distance(wall_trial, position) >= step * 0.60:
            enemy.pos = wall_trial
            enemy.avoid_time = memory
            return
        memory = 0.0
    var forward: Vector2 = _move_to(position, _uniso(goal_direction * step), 0.3)
    if _screen_distance(forward, position) >= step * 0.80:
        enemy.pos = forward
        enemy.avoid_time = 0.0
        return
    # Probe a small set of angular routes; keep the best one for ~0.6 seconds
    # so squirrels commit to circling a tree rather than wobbling against it.
    var preferred: float = side
    var best_score: float = -999.0
    var best_position: Vector2 = position
    var best_side: float = side
    for sign_value in [preferred, -preferred]:
        for turn in [0.72, 1.15, 1.6, 2.2]:
            var candidate_dir: Vector2 = goal_direction.rotated(sign_value * turn)
            var candidate: Vector2 = _move_to(position, _uniso(candidate_dir * step), 0.3)
            var traveled: float = _screen_distance(candidate, position)
            if traveled < step * 0.45:
                continue
            var displacement: Vector2 = _screen_delta(candidate, position).normalized()
            var score: float = traveled / step + displacement.dot(goal_direction) * 0.18 - turn * 0.10
            if sign_value == preferred:
                score += 0.035
            if score > best_score:
                best_score = score
                best_position = candidate
                best_side = sign_value
    if best_score > -100.0:
        enemy.pos = best_position
        enemy.avoid_side = best_side
        enemy.avoid_time = 0.55
    elif _screen_distance(forward, position) >= step * 0.25:
        enemy.pos = forward
        enemy.avoid_time = 0.0
    else:
        # Reverse preference after a failed probe, useful in narrow gaps.
        enemy.avoid_side = -preferred
        enemy.avoid_time = 0.0

func _make_player(id: int) -> Dictionary:
    var gun_id: String = progress.get("weapon","shotgun") if id == local_id else "shotgun"
    if not _unlocked_weapon(gun_id):gun_id="shotgun"
    var w: Dictionary = WEAPONS[gun_id]
    var char_id: String = progress.get("character","scout") if id == local_id else "scout"
    var health := 135.0 if char_id == "ironbark" else 100.0
    # ENet peer identifiers may be very large random integers; they are not spawn slots.
    var spawn_slot: int = maxi(1,players.size()+1)
    var m := {"pos":Vector2(27.0+spawn_slot*.38,27.0+spawn_slot*.26),"hp":health,"max_hp":health,"weapon":gun_id,"skin":str(progress.gun_skins.get(gun_id,SKIN_OPTIONS[gun_id][0])),"character":char_id,
      "ammo":w.ammo,"mag":w.ammo,"damage":w.damage*(1.12 if char_id=="sharpsight" else 1.0),"cooldown":w.cooldown,"reload_time":w.reload,"range":w.range,"pellets":w.pellets,"spread":w.spread,
      "speed":185.0*(1.14 if char_id=="trailblazer" else 1.0),"timer":0.0,"reload":0.0,"dash_cd":0.0,"flash":0.0,"invincible":0.0,"aim":Vector2.RIGHT,"moving":false,"walk":0.0,
      "kills":0,"fire":1 if char_id=="cindercloak" else 0,"ice":1 if char_id=="frostbound" else 0,"chain":0,"pierce":0,"double":0,"shatter":0,"magnet":0,"lucky":0,"shots_fired":0,"dash_recharge":2.6,"resist":0.0,"lifesteal":0.0,"nova":0,"singularity":0,"zero":0,"satellites":0,"overkill":0,"ultimate_timer":0.0,"name":"PLAYER %d" % id}
    return m

func _unlocked_weapon(w: String) -> bool:
    if not WEAPONS.has(w):return false
    if admin_mode:return true
    if w == "railgun":return progress.kills>=2400 and progress.best_wave>=30 and progress.boss_kills>=14
    return progress.kills >= WEAPONS[w].unlock

func _unlocked_character(id: String) -> bool:
    if not CHARACTER_SKINS.has(id):return false
    if admin_mode:return true
    var c: Dictionary = CHARACTER_SKINS[id]
    match c.kind:
        "starter":return true
        "kills":return progress.kills>=c.value
        "wave":return progress.best_wave>=c.value
        "bosses":return progress.boss_kills>=c.value
        "special":return progress.best_wave>=20 and progress.boss_kills>=8
    return false

func _unlocked_gun_skin(weapon_id: String, skin_index: int) -> bool:
    if not GUN_SKIN_REQUIREMENTS.has(weapon_id):return false
    if skin_index < 0 or skin_index >= SKIN_OPTIONS[weapon_id].size():return false
    if admin_mode:return true
    # Preserve cosmetics already equipped in an existing native save.
    var equipped_skins: Dictionary = progress.get("gun_skins",{})
    if str(equipped_skins.get(weapon_id,"")) == str(SKIN_OPTIONS[weapon_id][skin_index]):return true
    if not _unlocked_weapon(weapon_id):return false
    var rule: Array = GUN_SKIN_REQUIREMENTS[weapon_id][skin_index]
    var target: int = int(rule[1])
    match str(rule[0]):
        "starter", "railgun":return true
        "total_kills":return int(progress.get("kills",0)) >= target
        "best_wave":return int(progress.get("best_wave",0)) >= target
        "boss_kills":return int(progress.get("boss_kills",0)) >= target
        "weapon_kills":return int(progress.get("weapon_kills",{}).get(weapon_id,0)) >= target
    return false

func _gun_skin_requirement_text(weapon_id: String, skin_index: int) -> String:
    var rule: Array = GUN_SKIN_REQUIREMENTS[weapon_id][skin_index]
    match str(rule[0]):
        "starter":return "Starter cosmetic"
        "railgun":return "Unlocked with the Railgun"
        "total_kills":return "%d total kills" % int(rule[1])
        "best_wave":return "Reach wave %d" % int(rule[1])
        "boss_kills":return "Defeat %d bosses" % int(rule[1])
        "weapon_kills":return "%d kills using this weapon" % int(rule[1])
    return "Cosmetic mission"

func _start_run() -> void:
    run_id+=1
    enemies.clear();enemy_blobs.clear();hazards.clear();xp_drops.clear();particles.clear();traces.clear();upgrades_taken.clear()
    upgrades_rerolled = false
    run_level=1;run_xp=0.0;xp_to_next=_xp_requirement(run_level)
    pending_level_choices=0;xp_vacuum=false;wave_clear_grace=0.3
    wave=0;stage_kills=0;run_acorns=0;next_enemy_id=1;elapsed=0;day_phase=.25;weather="clear";weather_timer=0;novelty_timer=0
    players.clear()
    players[1]=_make_player(1)
    if mode == "host":
        for id in multiplayer.get_peers():
            players[id]=_make_player(id)
    if mode == "guest":
        players[local_id]=_make_player(local_id)
    _next_wave()
    _show_page("playing")
    if settings.get("music",true):music.play()

func _next_wave() -> void:
    xp_vacuum=false
    wave_clear_grace=0.3
    wave+=1
    boss_name=""
    if wave % 5 == 0:
        to_spawn = 4 if _boss_for_wave(wave) == "council" else 1
    else:
        to_spawn = 6 + 4 * wave + (players.size()-1) * (2 + int(.4*wave))
    spawn_timer=.85
    enemies.clear();enemy_blobs.clear();hazards.clear();drops.clear()
    for id in players:
        var p: Dictionary = players[id]
        p.ammo=p.mag;p.reload=0.0
        players[id]=p
    if wave % 5 == 0:
        boss_name=BOSS_NAMES[BOSS_KINDS.find(_boss_for_wave(wave))]
        if settings.get("music",true):music.stop();boss_music.play()
    else:
        if boss_music.playing:boss_music.stop()
        if settings.get("music",true) and not music.playing:music.play()
    toast_message=("BOSS WAVE %d - %s" % [wave,boss_name]) if boss_name!="" else ("WAVE %d - STINKY SWARM!" % wave)
    toast_timer=3.0

func _boss_for_wave(w: int) -> String:
    return BOSS_KINDS[(int(w/5)-1)%BOSS_KINDS.size()]

func _spawn_enemy(forced: String="") -> void:
    var kind := forced
    if kind=="":
        if wave % 5 == 0:
            kind=_boss_for_wave(wave)
        else:
            var r:=rng.randi_range(0,99)
            if wave>=9 and r<9:kind="healer"
            elif wave>=8 and r<18:kind="guard"
            elif wave>=7 and r<27:kind="bombardier"
            elif wave>=6 and r<37:kind="ranger"
            elif wave>=5 and r<49:kind="skirmisher"
            elif wave>=4 and r<63:kind="armored"
            elif wave>=3 and r<78:kind="spitter"
            elif wave>=2 and r<90:kind="toxic"
            else:kind="speedy" if r<96 else "normal"
    var anchor: Vector2 = players[1].pos if players.has(1) else Vector2(27,27)
    for id in players:
        if players[id].hp>0:
            anchor=players[id].pos
            break
    var angle := rng.randf_range(-PI,PI)
    var pixels := Vector2(cos(angle),sin(angle))*rng.randf_range(520,760)
    var origin := _wrap_vec(anchor+_uniso(pixels))
    var stats: Array = ENEMY_STATS.get(kind,ENEMY_STATS.normal)
    var enemy_level: int = 1 + int((wave-1)/2)
    var max_hp: float = float(stats[0])*(1.0+float(wave-1)*.1)
    if kind=="council":max_hp*=.8
    enemies.append({"id":next_enemy_id,"level":enemy_level,"kind":kind,"pos":origin,"hp":max_hp,"max_hp":max_hp,"speed":stats[1],"damage":stats[2],"attack":rng.randf_range(.3,.9),"cool":rng.randf_range(.3,1.5),"special":rng.randf_range(.8,2),"hit":0.0,"bob":rng.randf_range(0,TAU),"burn":0.0,"chill":0.0,"fire_stacks":0.0})
    next_enemy_id+=1
    if not progress.discovered.get(kind,false):
        progress.discovered[kind]=true
        _save_progress()

func _pick_rarity() -> int:
    var r := rng.randf_range(0,100)
    for i in range(RARITY_WEIGHTS.size()):
        r-=RARITY_WEIGHTS[i]
        if r <= 0:return i
    return 0

func _upgrade_options() -> Array[Dictionary]:
    var all: Array[String] = []
    for id in GENERAL_UPGRADES:all.append(id)
    var selected: String = players[1].weapon if players.has(1) else "shotgun"
    for id in UNIQUE_UPGRADES[selected]:all.append(id)
    if wave>=10:
        for id in LEGENDARY_UPGRADES:all.append(id)
    all.shuffle()
    var options: Array[Dictionary]=[]
    for i in range(mini(3,all.size())):
        var key: String = all[i]
        var rarity: int = _pick_rarity()
        if LEGENDARY_UPGRADES.has(key):rarity=4
        var desc := str(GENERAL_UPGRADES.get(key,UNIQUE_UPGRADES[selected].get(key,LEGENDARY_UPGRADES.get(key,""))))
        options.append({"id":key,"description":desc,"rarity":rarity})
    return options

func _apply_upgrade(option:Dictionary)->void:
    if mode == "guest":return
    var id: String = option.id
    var rarity: int = option.rarity
    var q: float = RARITY_SCALES[rarity]
    var n: int = maxi(1,int(round(q)))
    upgrades_taken.append(option.duplicate(true))
    for who in players:
        var p: Dictionary = players[who]
        match id:
            "FOREST_BOOTS":p.speed*=1.0+.12*q
            "BARK_ARMOR":p.max_hp+=24*q;p.hp=minf(p.max_hp,p.hp+24*q)
            "ACORN_FEAST":p.hp=minf(p.max_hp,p.hp+35*q)
            "QUICKDRAW","CAPACITOR","OVERCLOCK":
                p.cooldown=maxf(.04,p.cooldown*(1-.08*q))
                if id=="QUICKDRAW":p.reload_time=maxf(.35,p.reload_time*(1-.08*q))
            "FIRE_ROUNDS","DRAGONS_BREATH","INCENDIARY_FEED":p.fire+=n
            "ICE_ROUNDS","ICE_BUCK","ICE_STREAM","FROST_TIP":p.ice+=n
            "CHAIN_LIGHTNING","ION_STORM","RICOCHET_ROUNDS":p.chain+=n
            "BLOODSCENT":p.lifesteal+=.018*q
            "STINK_REPELLENT":p.resist=minf(.9,p.resist+.22*q)
            "HOLLOWPOINT","DEADEYE","OVERCHARGE":p.damage*=1+.16*q
            "SP RAY_N_PRAY","SPRAY_N_PRAY":p.pellets+=n;p.spread+=.04*q
            "PIERCE","PHASE_DRILL","GLACIAL_SPIKE","THERMAL_LANCE":
                p.pierce+=n
                if id=="THERMAL_LANCE":p.fire+=n
                if id=="GLACIAL_SPIKE":p.ice+=n
            "DOUBLE_TAP","FAN_FIRE","BURST_CORE":p.double+=n
            "ENTROPY_NOVA":p.nova+=n
            "SINGULARITY_SHELLS":p.singularity+=n
            "ABSOLUTE_ZERO":p.zero+=n
            "ACORN_SATELLITES":p.satellites+=n
            "OVERKILL_ENGINE":p.overkill+=n
            "SCATTERSHOT":p.pellets+=n
            "ECHO_DASH":p.dash_recharge=maxf(.78,p.dash_recharge-.40*q)
            "ACORN_MAGNET":p.magnet+=n
            "LUCKY_CHAMBER":p.lucky+=n
            "SHATTER_BLAST","CRYO_BURST":
                p.shatter+=n
                if id=="CRYO_BURST":p.ice+=n
        players[who]=p
    if id=="ACORN_FEAST":progress.acorns+=roundi(3*q);_save_progress()
    _flush_progress()
    if mode=="host":_broadcast_upgrade(option)
    upgrades_rerolled=false
    if pending_level_choices>0:
        _open_level_upgrade()
    else:
        _show_page("playing")

func _broadcast_upgrade(option: Dictionary) -> void:
    if mode=="host":rpc("upgrade_announcement",option)

@rpc("authority","call_remote","reliable")
func upgrade_announcement(option: Dictionary) -> void:
    upgrades_taken.append(option)
    toast_message=str(option.id).replace("_"," ")
    toast_timer=2.0

func _xp_requirement(level: int) -> float:
    return 55.0 + 15.0*float(level) + 12.0*pow(float(maxi(0,level-1)),1.35)

func _open_level_upgrade() -> void:
    if pending_level_choices<=0 or page=="defeated":return
    pending_level_choices-=1
    upgrade_choices=_upgrade_options()
    upgrades_rerolled=false
    _show_page("upgrades")
    if mode=="host":rpc("set_phase","upgrades")

func _gain_xp(value: float) -> void:
    run_xp+=value
    while run_xp >= xp_to_next:
        run_xp-=xp_to_next
        run_level+=1
        xp_to_next=_xp_requirement(run_level)
        pending_level_choices+=1
    if pending_level_choices>0 and page=="playing":_open_level_upgrade()

func _create_xp_drop(enemy: Dictionary) -> void:
    var enemy_level: int = int(enemy.get("level",1))
    var amount: float = float(XP_VALUE.get(str(enemy.kind),10))*(1.0+0.16*float(enemy_level-1))
    xp_drops.append({"pos":enemy.pos,"value":amount,"age":0.0,"fly":false})

func _create_drop(p: Vector2) -> void:
    drops.append({"pos":p,"age":0.0})

func _kill_enemy(e: Dictionary, owner: int=1) -> void:
    if not enemies.has(e):return
    enemies.erase(e)
    stage_kills+=1
    if players.has(owner):
        var shooter:Dictionary=players[owner]
        shooter.kills+=1
        players[owner]=shooter
    if owner==1:
        progress.kills+=1
        var weapon: String = players[1].weapon
        progress.weapon_kills[weapon]=int(progress.weapon_kills.get(weapon,0))+1
        _save_progress()
    if BOSS_KINDS.has(e.kind):
        progress.boss_kills+=1
        _save_progress()
    _create_xp_drop(e)
    # Shatter Blast rewards freezing a target before defeating it.
    if float(e.get("chill",0.0))>0 and players.has(owner) and int(players[owner].get("shatter",0))>0:
        var shatter_strength: int = int(players[owner].shatter)
        for nearby in enemies:
            if _screen_distance(nearby.pos,e.pos)<75.0:
                nearby.hp-=11.0*float(shatter_strength)
                nearby.chill=maxf(float(nearby.chill),0.7)
    if rng.randf()<.38 or BOSS_KINDS.has(e.kind):_create_drop(e.pos)
    var loc: Vector2 = world.screen_point(e.pos,camera_pos)
    _burst(loc,Color("ffc781"),14)

func _burst(at: Vector2, tint: Color, n: int=8) -> void:
    # Bounded cosmetic effects: avoid large allocation spikes in crowded waves.
    var particle_limit: int = 130 if mobile_web else 320
    var available: int = maxi(0,particle_limit-particles.size())
    var requested: int = mini(n,6) if mobile_web else n
    for i in range(mini(requested,available)):
        var angle := rng.randf_range(0,TAU)
        var vel := Vector2.from_angle(angle)*rng.randf_range(40,130)
        particles.append({"pos":at,"velocity":vel,"age":0.0,"life":rng.randf_range(.2,.5),"tint":tint,"size":rng.randf_range(2,5)})

func _shot(origin_id: int) -> void:
    if not players.has(origin_id):
        return
    var p: Dictionary = players[origin_id]
    if p.hp <= 0 or p.timer > 0 or p.reload > 0:
        return
    if p.ammo <= 0:
        _reload(origin_id)
        return
    p.ammo -= 1
    p.timer = p.cooldown
    p.flash = 0.12
    var aim: Vector2 = p.aim.normalized()
    # Every pellet starts at this ORIGINAL muzzle point, not at the hit end
    # of the previous pellet. That was the cause of bullets multiplying
    # behind a squirrel when a shotgun blast landed.
    var muzzle: Vector2 = world.screen_point(p.pos, camera_pos) + Vector2(0, -27)
    if origin_id == local_id:
        _sound("shotgun")
    p.shots_fired+=1
    var critical_shot: bool = p.lucky>0 and p.shots_fired%5==0
    var pellet_count: int = maxi(1, int(p.pellets)+int(p.double))
    var spread_amount: float = float(p.spread)
    var pierce_count: int = maxi(0, int(p.pierce))
    for i in range(pellet_count):
        var angle: float = aim.angle()
        if pellet_count > 1:
            angle += (float(i) / float(pellet_count - 1) - 0.5) * spread_amount
        angle += rng.randf_range(-spread_amount * 0.10, spread_amount * 0.10)
        var direction: Vector2 = Vector2.from_angle(angle)
        var ray_origin: Vector2 = muzzle
        var remaining: float = float(p.range)
        var pierced: int = 0
        var hit_ids: Dictionary = {}
        while remaining > 0.0:
            var best: Dictionary = {}
            var best_distance: float = remaining
            for e in enemies:
                if float(e.hp) <= 0.0 or hit_ids.has(e.id):
                    continue
                var point: Vector2 = world.screen_point(e.pos, camera_pos) + Vector2(0, -22)
                var difference: Vector2 = point - ray_origin
                var along: float = difference.dot(direction)
                if along <= 0.0 or along >= best_distance:
                    continue
                var distance_from_ray: float = absf(difference.cross(direction))
                var radius: float = 44.0 if BOSS_KINDS.has(e.kind) else (25.0 if e.kind in ["armored", "guard"] else 19.0)
                if distance_from_ray < radius:
                    best = e
                    best_distance = along
            var endpoint: Vector2 = ray_origin + direction * best_distance
            traces.append({"start":ray_origin,"end":endpoint,"tint":Color("ffe293"),"width":3.0,"life":0.13})
            if best.is_empty():
                break
            var bonus: float = 1.0 + minf(0.9, float(p.overkill) * float(p.kills) * 0.0009)
            best.hp -= float(p.damage) * bonus * (1.8 if critical_shot else 1.0)
            if p.singularity > 0:
                for nearby in enemies:
                    if nearby.id != best.id and _screen_distance(nearby.pos,best.pos) < 65:
                        nearby.hp -= float(p.damage) * 0.24 * float(p.singularity)
            best.hit = 0.12
            best.burn = maxf(float(best.burn),float(p.fire) * 0.9)
            best.fire_stacks += p.fire
            best.chill = maxf(float(best.chill),float(p.ice) * 0.9)
            hit_ids[best.id] = true
            _burst(endpoint,Color("7fe7ff") if p.ice > 0 else (Color("ff9155") if p.fire > 0 else Color("f5ca79")),2)
            if p.chain > 0:
                for other in enemies:
                    if other.id != best.id and _screen_distance(other.pos,best.pos) < 90:
                        other.hp -= float(p.damage) * 0.25
                        break
            if p.lifesteal > 0:
                p.hp = minf(float(p.max_hp),float(p.hp) + float(p.damage) * float(p.lifesteal) * 0.03)
            if pierced >= pierce_count:
                break  # No phantom segment after the final permitted hit.
            pierced += 1
            remaining -= best_distance + 17.0
            ray_origin = endpoint + direction * 17.0
    for e in enemies.duplicate():
        if e.hp <= 0:
            _kill_enemy(e,origin_id)
    players[origin_id] = p

func _reload(id: int) -> void:
    if not players.has(id):return
    var p: Dictionary=players[id]
    if p.reload>0 or p.ammo>=p.mag:return
    p.reload=p.reload_time
    players[id]=p
    if id==local_id:_sound("reload")

func _dash(id: int) -> void:
    if not players.has(id):return
    var p:Dictionary=players[id]
    if p.dash_cd>0 or p.hp<=0:return
    var aim: Vector2 = p.aim.normalized()
    var movement := _uniso(aim*225.0)
    p.pos=_move_to(p.pos,movement)
    p.dash_cd=float(p.get("dash_recharge",2.6))
    p.invincible=.30
    players[id]=p
    _burst(world.screen_point(p.pos,camera_pos),Color("b6ebfa"),15)

func _damage_player(id:int,dmg:float) -> void:
    if not players.has(id):return
    var p:Dictionary=players[id]
    if p.invincible>0 or p.hp<=0:return
    p.hp=maxf(0,p.hp-maxf(1,dmg*(1.0-p.resist*.3)))
    p.invincible=.6
    players[id]=p
    if id==local_id:_sound("hurt")
    if _everyone_down():_end_run()

func _everyone_down()->bool:
    if players.size()==0:return false
    for id in players:
        if players[id].hp>0:return false
    return true

func _end_run()->void:
    progress.best_wave=maxi(progress.best_wave,wave)
    _save_progress()
    _flush_progress()
    if mode=="host":rpc("set_phase","defeated")
    _show_page("defeated")

@rpc("authority","call_remote","reliable")
func set_phase(new_phase:String)->void:
    if mode=="guest":_show_page(new_phase)

func _update_player(id: int,move: Vector2,aim: Vector2,firing:bool,do_reload:bool,do_dash:bool,dt:float)->void:
    if not players.has(id):return
    var p:Dictionary=players[id]
    p.timer=maxf(0,p.timer-dt)
    p.reload=maxf(0,p.reload-dt)
    p.dash_cd=maxf(0,p.dash_cd-dt)
    p.flash=maxf(0,p.flash-dt)
    p.invincible=maxf(0,p.invincible-dt)
    if p.reload<=0 and p.get("was_reloading",false):
        p.ammo=p.mag;p.was_reloading=false
    if p.reload>0:p.was_reloading=true
    p.aim=aim.normalized() if aim.length_squared()>.01 else Vector2.RIGHT
    p.moving=move.length_squared()>.01
    if p.moving and p.hp>0:
        p.walk+=dt*3.5
        p.pos=_move_to(p.pos,_uniso(move.normalized()*p.speed*dt))
    players[id]=p
    if do_dash:_dash(id)
    if do_reload:_reload(id)
    if firing:_shot(id)

func _update_ultimates(dt:float)->void:
    for id in players:
        var p:Dictionary=players[id]
        if p.hp<=0:continue
        if int(p.nova)+int(p.zero)+int(p.satellites)==0:continue
        p.ultimate_timer+=dt
        var trigger:bool=p.ultimate_timer>2.2
        if trigger:
            p.ultimate_timer=0
            var center:Vector2=world.screen_point(p.pos,camera_pos)
            if p.nova>0:_burst(center,Color("fba56d"),18)
            if p.zero>0:_burst(center,Color("8ae9ff"),15)
            for e in enemies:
                var dist: float = _screen_distance(e.pos,p.pos)
                if p.nova>0 and dist<135:
                    e.hp-=8*p.nova
                    e.burn=maxf(e.burn,1.0)
                    e.fire_stacks+=1
                if p.zero>0 and dist<160:
                    e.hp-=6*p.zero
                    e.chill=maxf(e.chill,1.8)
                if p.satellites>0 and dist<110:
                    e.hp-=7*p.satellites
        players[id]=p

func _update_enemies(dt:float)->void:
    for e in enemies.duplicate():
        if e.hp<=0:_kill_enemy(e);continue
        e.bob+=dt*8
        e.hit=maxf(0,e.hit-dt)
        e.attack-=dt
        e.cool-=dt
        e.special-=dt
        if e.burn>0:
            e.burn-=dt
            e.hp-=dt*5.0*maxf(1,e.fire_stacks)
        if e.chill>0:e.chill-=dt
        var target:int=_nearest_alive_player(e.pos)
        if target<0:continue
        var target_pos:Vector2=players[target].pos
        var diff: Vector2 = _screen_delta(target_pos,e.pos)
        var dist:=maxf(1,diff.length())
        var direction:=diff/dist
        var slow: float = 0.6 if float(e.chill)>0.0 else 1.0
        var move: Vector2 = _uniso(direction * float(e.speed) * slow * dt)
        if e.kind=="spitter" and dist<230:
            if e.attack<=0:
                _shoot_enemy(e,direction,"poison")
                e.attack=1.25
            move=Vector2.ZERO if dist<170 else move*.4
        elif e.kind=="ranger" and dist<300:
            if e.attack<=0:
                _shoot_enemy(e,direction,"normal")
                e.attack=1.3
            move=Vector2.ZERO
        elif e.kind=="healer" and e.cool<=0:
            for other in enemies:
                if other.id!=e.id and _screen_distance(other.pos,e.pos)<130:
                    other.hp=minf(other.max_hp,other.hp+other.max_hp*.1)
            e.cool=4.0
        if BOSS_KINDS.has(e.kind):
            _boss_attack(e,target,direction,dist,dt)
        if dist > 24.0 and move.length_squared() > 0.0:
            # The desired step remains expressed in isometric screen space.
            # Give ranged enemies the same route-around-obstacle behavior.
            var screen_step: Vector2 = _screen_delta(_wrap_vec(e.pos + move), e.pos)
            if screen_step.length_squared() > 0.0001:
                _move_enemy_around(e,screen_step.normalized(),screen_step.length(),dt)
        if dist<(52.0 if BOSS_KINDS.has(e.kind) else 27.0) and e.attack<=0:
            _damage_player(target,e.damage)
            e.attack=1.0
    for e in enemies.duplicate():
        if e.hp<=0:_kill_enemy(e)

func _boss_attack(e:Dictionary,target:int,dir:Vector2,dist:float,dt:float)->void:
    if e.cool>0:return
    match e.kind:
        "king":
            e.pos=_move_to(e.pos,_uniso(dir*130),.4)
            for n in range(2):_spawn_enemy("speedy")
            e.cool=3.2
        "toxicboss":
            _create_hazard(e.pos,"poison",73,3.5)
            for n in range(5):_shoot_enemy(e,dir.rotated((n-2)*.24),"poison")
            e.cool=3.0
        "frostboss":
            for n in range(7):_shoot_enemy(e,Vector2.from_angle(TAU*float(n)/7),"ice")
            _create_hazard(players[target].pos,"ice",58,2.7)
            e.cool=3.3
        "council":
            if rng.randf()<.4:_spawn_enemy("guard")
            _shoot_enemy(e,dir,"normal")
            e.cool=2.3
        "burrower":
            e.pos=_move_to(e.pos,_uniso(dir*210),.6)
            _create_hazard(e.pos,"blast",80,1.3)
            e.cool=3.4
        "stormboss":
            for n in range(4):_create_hazard(_wrap_vec(players[target].pos+_uniso(Vector2.from_angle(TAU*float(n)/4)*100)),"lightning",39,1.8)
            e.cool=3.2
        "weaver":
            for n in range(4):_create_hazard(_wrap_vec(players[target].pos+_uniso(Vector2.from_angle(TAU*float(n)/4)*80)),"ice",50,3.0)
            _spawn_enemy("skirmisher")
            e.cool=3.6
        "nutpocalypse":
            for n in range(8):_shoot_enemy(e,Vector2.from_angle(TAU*float(n)/8),"blast")
            for n in range(2):_spawn_enemy("bombardier")
            e.cool=3.5

func _shoot_enemy(e:Dictionary,dir:Vector2,kind:String)->void:
    # Real traveling projectiles in world coordinates, with screen-pixel velocities.
    # Slow enough to see and dodge; variants differ in color, size, and pace.
    if enemy_blobs.size() >= MAX_ENEMY_BLOBS:
        enemy_blobs.remove_at(0)
    var heading: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
    var speed: float = 152.0
    var radius: float = 9.0
    var duration: float = 2.8
    var impact: float = 9.0
    match kind:
        "ice":
            speed = 144.0
            radius = 9.5
            duration = 3.0
            impact = 10.0
        "normal":
            speed = 172.0
            radius = 8.0
            duration = 2.7
            impact = 9.0
        "blast":
            speed = 164.0
            radius = 12.0
            duration = 2.8
            impact = 12.0
    # Begin outside the source sprite: no point-blank invisible hit.
    var start: Vector2 = _wrap_vec(e.pos + _uniso(heading * 23.0))
    enemy_blobs.append({
        "pos": start, "velocity": heading * speed, "kind": kind,
        "radius": radius, "damage": impact, "age": 0.0, "life": duration,
        "terrain_clock": 0.07
    })

func _update_enemy_blobs(dt:float)->void:
    # Host-side movement/collision; every local and remote player gets the same
    # dodge window. Swept collision prevents projectiles skipping players at high FPS.
    for blob in enemy_blobs.duplicate():
        var start: Vector2 = blob.pos
        var movement: Vector2 = blob.velocity * dt
        var destination: Vector2 = _wrap_vec(start + _uniso(movement))
        blob.age += dt
        if blob.age >= blob.life:
            enemy_blobs.erase(blob)
            continue
        # Check blocking terrain at a bounded rate to avoid unnecessary per-frame
        # spatial-hash allocations when many squirrels shoot together.
        blob.terrain_clock -= dt
        if blob.terrain_clock <= 0.0:
            blob.terrain_clock = 0.07
            if not _can_occupy(destination, 0.18):
                _burst(world.screen_point(destination,camera_pos), Color("a6e879") if blob.kind != "ice" else Color("97e9ff"), 3)
                enemy_blobs.erase(blob)
                continue
        var struck: bool = false
        var span_sq: float = movement.length_squared()
        for id in players:
            var player: Dictionary = players[id]
            if player.hp <= 0.0:
                continue
            var relative: Vector2 = _screen_delta(player.pos,start)
            var alpha: float = clampf(relative.dot(movement)/span_sq,0.0,1.0) if span_sq > 0.0001 else 0.0
            var nearest: Vector2 = movement * alpha
            var combined_radius: float = 17.0 + float(blob.radius)
            if relative.distance_squared_to(nearest) <= combined_radius * combined_radius:
                _damage_player(id,float(blob.damage))
                _burst(world.screen_point(player.pos,camera_pos) + Vector2(0,-23), Color("b2f36c") if blob.kind != "ice" else Color("87dfff"), 5)
                struck = true
                break
        if struck:
            enemy_blobs.erase(blob)
        else:
            blob.pos = destination

func _create_hazard(pos:Vector2,kind:String,radius:float,lifetime:float)->void:
    hazards.append({"pos":pos,"kind":kind,"radius":radius,"age":0.0,"life":lifetime,"tick":.5})

func _nearest_alive_player(pos:Vector2)->int:
    var best:float=INF
    var closest:int=-1
    for id in players:
        var p:Dictionary=players[id]
        if p.hp<=0:continue
        var d:=_screen_distance(pos,p.pos)
        if d<best:best=d;closest=id
    return closest

func _update_drops_and_hazards(dt:float)->void:
    # XP is distinct from acorns. Uncollected prisms vacuum toward the squad at wave clear.
    for shard in xp_drops.duplicate():
        shard.age+=dt
        var nearest: int = _nearest_alive_player(shard.pos)
        if nearest<0:continue
        var target: Vector2 = players[nearest].pos
        var delta: Vector2 = _screen_delta(target,shard.pos)
        var distance_px: float = delta.length()
        var flying: bool = xp_vacuum or distance_px<94.0
        if flying and distance_px>1.0:
            var speed_px: float = 1750.0 if xp_vacuum else 420.0
            var travel: Vector2 = delta.limit_length(speed_px*dt)
            shard.pos=_wrap_vec(shard.pos+_uniso(travel))
        if distance_px<26.0 or (flying and distance_px<=1750.0*dt):
            xp_drops.erase(shard)
            _gain_xp(float(shard.value))
    for a in drops.duplicate():
        a.age+=dt
        # Acorn magnet is distinct from the automatic wave-end XP vacuum.
        var magnet_target: int = -1
        var magnet_distance: float = 150.0
        for id in players:
            var collector: Dictionary = players[id]
            if collector.hp>0 and int(collector.get("magnet",0))>0:
                var dist: float = _screen_distance(collector.pos,a.pos)
                if dist<magnet_distance:
                    magnet_distance=dist
                    magnet_target=id
        if magnet_target>=0:
            var pull: Vector2 = _screen_delta(players[magnet_target].pos,a.pos)
            a.pos=_wrap_vec(a.pos+_uniso(pull.limit_length(300.0*dt)))
        for id in players:
            var p:Dictionary=players[id]
            if p.hp>0 and _screen_distance(p.pos,a.pos)<27:
                p.hp=minf(p.max_hp,p.hp+4.0)
                players[id]=p
                drops.erase(a)
                run_acorns+=1
                progress.acorns+=1
                _save_progress()
                break
    for h in hazards.duplicate():
        h.age+=dt
        h.tick-=dt
        if h.age>=h.life:
            hazards.erase(h)
            continue
        if h.tick<=0:
            for id in players:
                if players[id].hp>0 and _screen_distance(players[id].pos,h.pos)<h.radius:
                    _damage_player(id,9.0)
            h.tick=.7
    for p in particles.duplicate():
        p.pos+=p.velocity*dt
        p.age+=dt
        if p.age>=p.life:particles.erase(p)
    if traces.size()>180:
        traces = traces.slice(traces.size()-180)
    for t in traces.duplicate():
        t.life-=dt
        if t.life<=0:traces.erase(t)

func _get_local_move()->Vector2:
    if _touch_active() and mobile_touch.move_vector().length_squared() > 0.001:
        return mobile_touch.move_vector()
    var keys: Vector2 = Vector2(Input.get_axis("ui_left","ui_right"),Input.get_axis("ui_up","ui_down")) + Vector2((1.0 if Input.is_key_pressed(KEY_D) else 0.0)-(1.0 if Input.is_key_pressed(KEY_A) else 0.0),(1.0 if Input.is_key_pressed(KEY_S) else 0.0)-(1.0 if Input.is_key_pressed(KEY_W) else 0.0))
    return keys.limit_length(1.0)

func _get_local_aim()->Vector2:
    if _touch_active():
        return mobile_touch.aim_vector().normalized()
    var d: Vector2 = get_viewport().get_mouse_position() - Vector2(640,334)
    return d.normalized() if d.length_squared()>1.0 else Vector2.RIGHT

func _local_fire() -> bool:
    return mobile_touch.is_firing() if _touch_active() else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _local_reload() -> bool:
    var touch_reload: bool = mobile_touch.consume_reload() if _touch_active() else false
    return touch_reload or Input.is_key_pressed(KEY_R)

func _local_dash() -> bool:
    return mobile_touch.consume_dash() if _touch_active() else false

func _process(dt:float)->void:
    if save_dirty:
        save_seconds += dt
        if save_seconds >= 2.8:
            _flush_progress()
    elapsed+=dt
    if fx_rect != null and fx_rect.visible:
        fx_time += dt
        fx_material.set_shader_parameter("u_time", fx_time)
        fx_material.set_shader_parameter("u_day", day_phase)
        fx_material.set_shader_parameter("u_weather", 1.0 if weather in ["rain","mist","snow"] and bool(settings.get("weather",true)) else 0.0)
        var motion_vec: Vector2 = _screen_delta(camera_pos, last_camera_pos)
        fx_material.set_shader_parameter("u_motion", motion_vec / 64.0)
    last_camera_pos = camera_pos
    toast_timer=maxf(0,toast_timer-dt)
    if mode=="host" or mode=="solo":
        if page=="playing":
            var local_move:=_get_local_move()
            _update_player(1,local_move,_get_local_aim(),_local_fire(),_local_reload(),_local_dash(),dt)
            if mode=="host":
                for id in player_inputs:
                    if players.has(id):
                        var inp:Dictionary=player_inputs[id]
                        _update_player(id,inp.get("move",Vector2.ZERO),inp.get("aim",Vector2.RIGHT),inp.get("fire",false),inp.get("reload",false),inp.get("dash",false),dt)
                        inp.dash=false
                        player_inputs[id]=inp
            if to_spawn>0:
                spawn_timer-=dt
                if spawn_timer<=0:
                    _spawn_enemy()
                    to_spawn-=1
                    spawn_timer=maxf(.16,.83-wave*.028)
            _update_ultimates(dt)
            _update_enemies(dt)
            _update_enemy_blobs(dt)
            _update_drops_and_hazards(dt)
            if to_spawn<=0 and enemies.is_empty() and page=="playing":
                if not xp_vacuum:
                    xp_vacuum=true
                    progress.best_wave=maxi(int(progress.best_wave),wave)
                    _save_progress()
                    toast_message="✦ WAVE %d CLEAR  ·  XP GATHER!" % wave
                    toast_timer=1.6
                if xp_drops.is_empty() and pending_level_choices==0:
                    wave_clear_grace-=dt
                    if wave_clear_grace<=0.0:_next_wave()
            novelty_timer+=dt
            if settings.get("novelty",false) and novelty_timer>100:
                novelty_timer=0
                toast_message=["PARODY AD: ACORN DELUXE — ONLY 99,999 NUTS!","PARODY AD: OFFICIAL STINKY SOCKS — ZERO REFUNDS!","PARODY AD: MINI FOAM RAILGUN — NOT A REAL WEAPON!","PARODY AD: PLUSH SQUIRREL KING — HE SCREAMS!"].pick_random()
                toast_timer=6.0
            day_phase=fposmod(day_phase+dt/260.0,1.0)
            weather_timer+=dt
            if weather_timer>=48:
                weather_timer=0
                weather=["clear","rain","mist","snow","wind"][rng.randi_range(0,4)]
        if mode=="host":
            snapshot_timer+=dt
            if snapshot_timer>.09:
                snapshot_timer=0
                var snap:Dictionary={"players":players,"enemies":enemies,"drops":drops,"xp_drops":xp_drops,"run_id":run_id,"run_level":run_level,"run_xp":run_xp,"xp_to_next":xp_to_next,"hazards":hazards,"enemy_blobs":enemy_blobs,"traces":traces.slice(maxi(0,traces.size()-45)),"particles":particles.slice(maxi(0,particles.size()-50)),"wave":wave,"to_spawn":to_spawn,"elapsed":elapsed,"stage_kills":stage_kills,"day":day_phase,"weather":weather,"boss_name":boss_name,"phase":page}
                rpc("receive_snapshot",snap)
    elif mode=="guest" and page=="playing":
        enemy_blob_interp = minf(0.11, enemy_blob_interp + dt)
        rpc_id(HOST_ID,"submit_input",_get_local_move(),_get_local_aim(),_local_fire(),_local_reload(),_local_dash())
    if players.has(local_id):camera_pos=players[local_id].pos
    hud_fps_seconds += dt
    if ui_root!=null and hud_fps_seconds >= 0.065:
        hud_fps_seconds = 0.0
        _update_hud()
    if world != null and (not mobile_web or page == "playing"):
        world.queue_redraw()

# Capture number shortcuts ahead of GUI focus so 1/2/3 always select the cards.
func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if page != "upgrades" or mode == "guest" or not key.pressed or key.echo:
        return
    var index: int = -1
    if key.keycode == KEY_1 or key.keycode == KEY_KP_1: index = 0
    elif key.keycode == KEY_2 or key.keycode == KEY_KP_2: index = 1
    elif key.keycode == KEY_3 or key.keycode == KEY_KP_3: index = 2
    if index >= 0 and index < upgrade_choices.size():
        get_viewport().set_input_as_handled()
        _apply_upgrade(upgrade_choices[index])

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE:
            if quit_dialog != null and quit_dialog.visible:
                quit_dialog.hide()
            elif page == "playing":
                _show_page("paused")
            elif page == "paused" or page == "title":
                _request_exit("quit")
            elif page == "upgrades" or page == "defeated":
                _request_exit("menu")
            elif page == "settings":
                _show_page(settings_return_page)
            elif page == "admin":
                _show_page(admin_return_page)
            else:
                _show_page("title")
            get_viewport().set_input_as_handled()
        elif event.keycode==KEY_SPACE and page=="playing":
            if mode=="guest":rpc_id(HOST_ID,"submit_input",_get_local_move(),_get_local_aim(),false,false,true)
            else:_dash(1)

func _peer_connected(id:int)->void:
    if mode=="host":
        players[id]=_make_player(id)
        toast_message="PLAYER %d JOINED" % id
        toast_timer=2.8

func _peer_disconnected(id:int)->void:
    players.erase(id)
    player_inputs.erase(id)

func _joined_server()->void:
    local_id=multiplayer.get_unique_id()
    observed_guest_run_id=-1;last_guest_kills=0
    mode="guest"
    _show_page("playing")
    rpc_id(HOST_ID,"select_loadout",str(progress.get("weapon","shotgun")),str(progress.get("character","scout")))

func _failed_connection()->void:
    _show_page("title")
    toast_message="COULD NOT CONNECT TO HOST"
    toast_timer=5.0

func _server_disconnected()->void:
    mode="solo"
    _show_page("title")
    toast_message="HOST DISCONNECTED"
    toast_timer=5.0

@rpc("any_peer","call_remote","reliable")
func select_loadout(w:String,ch:String)->void:
    if mode!="host":return
    var id:=multiplayer.get_remote_sender_id()
    if not players.has(id):return
    var p:Dictionary=players[id]
    # Guest loadouts are self-reported; a private LAN game does not validate
    # each guest's local progression. Do not treat this as an anti-cheat check.
    var weapon_id:=w if WEAPONS.has(w) else "shotgun"
    var config:Dictionary=WEAPONS[weapon_id]
    p.weapon=weapon_id
    p.skin=SKIN_OPTIONS[weapon_id][0]
    p.character=ch if CHARACTER_SKINS.has(ch) else "scout"
    p.mag=config.ammo;p.ammo=config.ammo;p.damage=config.damage;p.pellets=config.pellets
    p.cooldown=config.cooldown;p.reload_time=config.reload;p.range=config.range;p.spread=config.spread
    players[id]=p

@rpc("any_peer","call_remote","unreliable")
func submit_input(move:Vector2,aim:Vector2,firing:bool,reload:bool,dash:bool)->void:
    if mode!="host":return
    var id:=multiplayer.get_remote_sender_id()
    if not players.has(id):return
    player_inputs[id]={"move":move.limit_length(1),"aim":aim.normalized(),"fire":firing,"reload":reload,"dash":dash or bool(player_inputs.get(id,{}).get("dash",false))}

@rpc("authority","call_remote","unreliable")
func receive_snapshot(snapshot:Dictionary)->void:
    if mode!="guest":return
    players=snapshot.get("players",{})
    # Earn each guest's real weapon/total-kill progression from host-authoritative
    # snapshots. Run IDs prevent double-counting across successive waves/runs.
    var incoming_run_id: int = int(snapshot.get("run_id",0))
    if incoming_run_id!=observed_guest_run_id:
        observed_guest_run_id=incoming_run_id
        last_guest_kills=0
    if players.has(local_id):
        var own: Dictionary = players[local_id]
        var actual_kills: int = int(own.get("kills",0))
        if actual_kills>last_guest_kills:
            var earned: int = actual_kills-last_guest_kills
            var weapon_key: String = str(own.get("weapon","shotgun"))
            progress.kills=int(progress.get("kills",0))+earned
            progress.weapon_kills[weapon_key]=int(progress.weapon_kills.get(weapon_key,0))+earned
            _save_progress()
            last_guest_kills=actual_kills
    enemies.assign(snapshot.get("enemies",[]))
    drops.assign(snapshot.get("drops",[]))
    xp_drops.assign(snapshot.get("xp_drops",[]))
    run_level=int(snapshot.get("run_level",1))
    run_xp=float(snapshot.get("run_xp",0.0))
    xp_to_next=float(snapshot.get("xp_to_next",70.0))
    hazards.assign(snapshot.get("hazards",[]))
    enemy_blobs.assign(snapshot.get("enemy_blobs",[]))
    enemy_blob_interp = 0.0
    traces.assign(snapshot.get("traces",[]))
    particles.assign(snapshot.get("particles",[]))
    wave=snapshot.get("wave",0)
    to_spawn=snapshot.get("to_spawn",0)
    stage_kills=snapshot.get("stage_kills",0)
    elapsed=snapshot.get("elapsed",0.0)
    day_phase=snapshot.get("day",.25)
    weather=snapshot.get("weather","clear")
    boss_name=snapshot.get("boss_name","")
    var status: String=snapshot.get("phase","playing")
    if status!=page and status in ["playing","upgrades","defeated"]:
        _show_page(status)

func _start_solo()->void:
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
    mode="solo";local_id=1
    _start_run()

func _start_host()->void:
    if OS.has_feature("web"):
        toast_message="WEB BROWSERS CANNOT HOST UDP LAN GAMES"
        toast_timer=6.0
        return
    # Resolve this transport only on native platforms. Web exports must not
    # instantiate ENet because UDP sockets are unavailable in browsers.
    var peer = ClassDB.instantiate("ENetMultiplayerPeer")
    if peer == null:
        toast_message="ENET TRANSPORT UNAVAILABLE"
        toast_timer=5.0
        return
    var err: int = int(peer.call("create_server", PORT, MAX_GUESTS))
    if err!=OK:
        toast_message="CANNOT HOST UDP %d (error %d)" % [PORT,err]
        toast_timer=5
        return
    multiplayer.multiplayer_peer=peer
    local_id=1;mode="host"
    _start_run()

func _start_join()->void:
    if OS.has_feature("web"):
        toast_message="WEB CO-OP NEEDS A WEBSOCKET RELAY SERVER"
        toast_timer=6.0
        return
    var addr: String=connection_text.text.strip_edges() if connection_text!=null else "127.0.0.1"
    if addr=="":addr="127.0.0.1"
    # Resolve this transport only on native platforms. Web exports must not
    # instantiate ENet because UDP sockets are unavailable in browsers.
    var peer = ClassDB.instantiate("ENetMultiplayerPeer")
    if peer == null:
        toast_message="ENET TRANSPORT UNAVAILABLE"
        toast_timer=5.0
        return
    var err: int = int(peer.call("create_client", addr, PORT))
    if err!=OK:
        toast_message="COULD NOT JOIN %s (error %d)" % [addr,err]
        toast_timer=5
        return
    multiplayer.multiplayer_peer=peer
    mode="guest"
    _show_page("connecting")

# Windows close, the Quit button, and leaving an active run all require confirmation.
func _make_quit_dialog() -> void:
    quit_dialog = ConfirmationDialog.new()
    quit_dialog.title = "LEAVE THE FOREST?"
    quit_dialog.dialog_text = "Are you sure you want to quit Stinky Squirrel?"
    quit_dialog.ok_button_text = "YES, QUIT"
    quit_dialog.min_size = Vector2i(510,215)
    quit_dialog.unresizable = true
    quit_dialog.add_theme_stylebox_override("panel",_panel_style("#122c31", "#f2c77d", 18))
    quit_dialog.add_theme_color_override("title_color",Color("ffe7b8"))
    add_child(quit_dialog)
    quit_dialog.confirmed.connect(_confirm_exit)

func _request_exit(target: String = "quit") -> void:
    if quit_dialog == null or quit_dialog.visible:return
    pending_exit_action = target
    if target == "menu":
        quit_dialog.title = "END THIS RUN?"
        quit_dialog.dialog_text = "Return to the main menu? Your permanent progress will be saved."
        quit_dialog.ok_button_text = "YES, MAIN MENU"
    else:
        quit_dialog.title = "QUIT STINKY SQUIRREL?"
        quit_dialog.dialog_text = "Are you sure you want to close the game? Your permanent progress will be saved."
        quit_dialog.ok_button_text = "YES, QUIT GAME"
    quit_dialog.popup_centered(Vector2i(550,230))

func _confirm_exit() -> void:
    if pending_exit_action == "menu":
        _return_menu_immediately()
    else:
        _flush_progress()
        if OS.has_feature("web"):
            _return_menu_immediately() # A web iframe cannot safely close itself.
        else:
            get_tree().quit()

func _return_menu() -> void:
    _request_exit("menu")

func _return_menu_immediately() -> void:
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
    mode="solo"
    local_id=1
    _flush_progress()
    _show_page("title")

# -------- Native menus and HUD (palette and content mapped from original HTML) --------
func _panel_style(bg: String="#10292c", border: String="#c5a66f", radius:int=18)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=Color(bg)
    s.border_color=Color(border)
    s.set_border_width_all(2)
    s.set_corner_radius_all(radius)
    s.border_blend = true
    s.anti_aliasing = true
    s.anti_aliasing_size = 1.0
    var glow: Color = Color(border)
    glow.a = 0.24
    s.shadow_color = glow
    s.shadow_size = 9
    s.shadow_offset = Vector2(0.0, 2.0)
    s.content_margin_left=14
    s.content_margin_right=14
    s.content_margin_top=12
    s.content_margin_bottom=12
    return s

# -------- GPU post effects: a single native shader pass, OFF when no effects active --------
func _make_gpu_fx() -> void:
    fx_layer = CanvasLayer.new()
    fx_layer.layer = 3
    add_child(fx_layer)
    fx_rect = ColorRect.new()
    fx_rect.name = "GPU Post Processing (optional)"
    fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_rect.color = Color.WHITE
    fx_material = ShaderMaterial.new()
    fx_material.shader = load("res://shaders/native_post.gdshader")
    fx_rect.material = fx_material
    fx_layer.add_child(fx_rect)
    fx_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _apply_graphics_settings()

func _fx_amount(key: String) -> float:
    if not bool(settings.get(key, false)):
        return 0.0
    return float(settings.get(key + "_strength", FX_STRENGTH_DEFAULT))

func _apply_graphics_settings() -> void:
    if fx_rect == null or fx_material == null:
        return
    # Old saved settings and Cinematic must not reintroduce sprite smearing.
    settings["fx_dof"] = false
    settings["fx_motion_blur"] = false
    settings["fx_aa"] = "Off"
    var shader_needed: bool = false
    for effect in GRAPHICS_EFFECTS:
        var key: String = str(effect.id)
        if key in ["fx_contact_shadows", "fx_reflections", "fx_long_exposure"]:
            continue
        var amount: float = _fx_amount(key)
        fx_material.set_shader_parameter(key, amount)
        if amount > 0.001:
            shader_needed = true
    var aa_weight: float = 0.0
    # Antialias blending is intentionally disabled for crisp nearest-neighbor pixels.
    fx_material.set_shader_parameter("fx_aa", aa_weight)
    shader_needed = shader_needed or aa_weight > 0.0
    # WebGL2 pixel-art performance safeguard: full-screen shaders are optional
    # on desktop but never run on iPhone Safari (including Cinematic preset).
    fx_rect.visible = shader_needed and not mobile_web
    if world != null:
        world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        world.queue_redraw()

func _set_fx_bool(key: String, value: bool) -> void:
    settings[key] = value
    _apply_graphics_settings()
    _save_progress()

func _set_fx_strength(key: String, value: float) -> void:
    settings[key + "_strength"] = value
    _apply_graphics_settings()
    _save_progress()

func _choose_antialias(index: int) -> void:
    var modes: PackedStringArray = PackedStringArray(["Off", "FXAA-like", "SMAA-like", "TAA-like"])
    if index >= 0 and index < modes.size():
        settings["fx_aa"] = "Off"
        _apply_graphics_settings()
        _save_progress()

func _apply_graphics_preset(preset: String) -> void:
    # Keep high-cost effects disabled in the default settings.
    for effect in GRAPHICS_EFFECTS:
        var key: String = str(effect.id)
        settings[key] = false
        settings[key + "_strength"] = FX_STRENGTH_DEFAULT
    settings["fx_aniso"] = false
    settings["fx_aa"] = "Off"
    if preset == "Balanced":
        settings["fx_contact_shadows"] = true
        settings["fx_color_grade"] = true
        settings["fx_vignette"] = true
        settings["fx_color_grade_strength"] = 0.20
        settings["fx_vignette_strength"] = 0.14
    elif preset == "Cinematic":
        for effect in GRAPHICS_EFFECTS:
            var key: String = str(effect.id)
            settings[key] = true
        settings["fx_aa"] = "Off"
        settings["fx_aniso"] = false
        settings["fx_bloom_strength"] = 0.25
        settings["fx_chromatic_strength"] = 0.09
    elif preset == "Performance":
        settings["fx_contact_shadows"] = true
    else:
        settings["fx_contact_shadows"] = true
    settings["graphics"] = preset
    _apply_graphics_settings()
    _save_progress()
    _show_page("settings")

func _open_settings(from_page: String) -> void:
    settings_return_page = from_page
    graphics_tab = "general"
    _show_page("settings")

func _change_settings_tab(which: String) -> void:
    graphics_tab = which
    _show_page("settings")

func _make_pixel_hud_stat(container: HBoxContainer, icon_file: String, tooltip: String, tint: Color) -> Label:
    var stat: HBoxContainer = HBoxContainer.new()
    stat.add_theme_constant_override("separation",4)
    stat.tooltip_text=tooltip
    container.add_child(stat)
    var pixel_icon: TextureRect = TextureRect.new()
    pixel_icon.texture=load("res://art/hud/%s.png" % icon_file)
    pixel_icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    pixel_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    pixel_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    pixel_icon.custom_minimum_size=Vector2(29,29) if mobile_web else Vector2(21,21)
    pixel_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    stat.add_child(pixel_icon)
    var amount: Label = Label.new()
    amount.text="0"
    amount.add_theme_font_size_override("font_size",21 if mobile_web else 16)
    amount.add_theme_color_override("font_color",tint)
    amount.mouse_filter=Control.MOUSE_FILTER_IGNORE
    stat.add_child(amount)
    return amount

func _make_ui()->void:
    ui_layer=CanvasLayer.new()
    ui_layer.layer = 9
    add_child(ui_layer)
    ui_root=Control.new()
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(ui_root)
    # Single static GPU-sampled texture: warm/cool atmosphere costs virtually
    # nothing compared with a full-screen shader, and is disabled in gameplay.
    menu_backdrop = TextureRect.new()
    menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_backdrop.texture = load("res://ui/nightwatch_ui_atmosphere.png")
    menu_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    menu_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
    menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(menu_backdrop)
    var menu_center:=CenterContainer.new()
    menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_center.mouse_filter=Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(menu_center)
    main_panel=PanelContainer.new()
    main_panel.custom_minimum_size=Vector2(1020,0)
    main_panel.add_theme_stylebox_override("panel",_panel_style("#0c2428", "#d8b879", 22))
    menu_center.add_child(main_panel)
    var scroll:=ScrollContainer.new()
    scroll.custom_minimum_size=Vector2(978,538)
    scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    main_panel.add_child(scroll)
    main_layout=VBoxContainer.new()
    main_layout.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    main_layout.add_theme_constant_override("separation",10)
    scroll.add_child(main_layout)
    var leftbox:=PanelContainer.new()
    hud_left_box = leftbox
    leftbox.visible = false
    leftbox.position=Vector2(12,12)
    leftbox.custom_minimum_size=Vector2(294,119)
    leftbox.add_theme_stylebox_override("panel",_panel_style("#102d30", "#8edcbd", 14))
    ui_root.add_child(leftbox)
    hud_left=Label.new()
    hud_left.add_theme_font_size_override("font_size",20 if mobile_web else 16)
    hud_left.add_theme_color_override("font_color",Color("f6d38f"))
    hud_left.custom_minimum_size=Vector2(270,75)
    var left_column := VBoxContainer.new()
    left_column.add_theme_constant_override("separation", 4)
    leftbox.add_child(left_column)
    hud_left.custom_minimum_size = Vector2(280, 38)
    left_column.add_child(hud_left)
    var counter_row: HBoxContainer = HBoxContainer.new()
    counter_row.add_theme_constant_override("separation",18)
    left_column.add_child(counter_row)
    hud_enemy_count=_make_pixel_hud_stat(counter_row,"enemies","Squirrels remaining",Color("ffcd9e"))
    hud_kill_count=_make_pixel_hud_stat(counter_row,"kills","Squirrels defeated this run",Color("f2e7ce"))
    hud_hp_meter = StinkyHudMeter.new()
    hud_hp_meter.mode = "health"
    hud_hp_meter.custom_minimum_size = Vector2(274, 23)
    left_column.add_child(hud_hp_meter)
    var rightbox:=PanelContainer.new()
    hud_right_box = rightbox
    rightbox.visible = false
    rightbox.position=Vector2(988,12)
    rightbox.custom_minimum_size=Vector2(268,128)
    rightbox.add_theme_stylebox_override("panel",_panel_style("#102d30", "#ebd08e", 14))
    ui_root.add_child(rightbox)
    var ammo_column: VBoxContainer = VBoxContainer.new()
    ammo_column.add_theme_constant_override("separation", 2)
    rightbox.add_child(ammo_column)
    hud_right=Label.new()
    hud_right.custom_minimum_size=Vector2(246,42)
    hud_right.add_theme_font_size_override("font_size",19 if mobile_web else 15)
    hud_right.add_theme_color_override("font_color",Color("f6d38f"))
    ammo_column.add_child(hud_right)
    hud_ammo_meter=StinkyHudMeter.new()
    hud_ammo_meter.mode="ammo"
    hud_ammo_meter.custom_minimum_size=Vector2(244,58)
    ammo_column.add_child(hud_ammo_meter)
    hud_status_box=PanelContainer.new()
    hud_status_box.position=Vector2(12,665)
    hud_status_box.custom_minimum_size=Vector2(385,42)
    hud_status_box.add_theme_stylebox_override("panel", _panel_style("#10292c", "#537d70", 12))
    ui_root.add_child(hud_status_box)
    var status_row: HBoxContainer = HBoxContainer.new()
    status_row.add_theme_constant_override("separation",18)
    hud_status_box.add_child(status_row)
    # Keep acorns separate: one counter for this run and one banked total.
    var run_acorns_stat: HBoxContainer = HBoxContainer.new()
    run_acorns_stat.tooltip_text="Acorns collected this run"
    status_row.add_child(run_acorns_stat)
    run_acorns_stat.add_child(_make_label("🌰",16,"#cfebdd"))
    hud_acorns_collected=_make_label("0",16,"#cfebdd")
    run_acorns_stat.add_child(hud_acorns_collected)
    var saved_acorns_stat: HBoxContainer = HBoxContainer.new()
    saved_acorns_stat.tooltip_text="Banked acorns"
    status_row.add_child(saved_acorns_stat)
    saved_acorns_stat.add_child(_make_label("◇",17,"#a9e9da"))
    hud_acorns_saved=_make_label("0",16,"#cfebdd")
    saved_acorns_stat.add_child(hud_acorns_saved)
    hud_best_wave=_make_pixel_hud_stat(status_row,"record","Best wave reached",Color("f9d389"))
    # Small circular cooldown in the lower-left, away from the health panel.
    hud_dash_meter=StinkyHudMeter.new()
    hud_dash_meter.mode="dash"
    hud_dash_meter.position=Vector2(19,570)
    hud_dash_meter.custom_minimum_size=Vector2(76,84)
    ui_root.add_child(hud_dash_meter)
    hud_xp_box=PanelContainer.new()
    hud_xp_box.position=Vector2(442,654)
    hud_xp_box.custom_minimum_size=Vector2(396,51)
    hud_xp_box.add_theme_stylebox_override("panel",_panel_style("#102a2d","#6de5cd",10))
    ui_root.add_child(hud_xp_box)
    var xp_stack:=VBoxContainer.new()
    xp_stack.add_theme_constant_override("separation",2)
    hud_xp_box.add_child(xp_stack)
    # mobile-label
    hud_xp_label=_make_label("✦  1    0 / 70",17 if mobile_web else 12,"#9ff8de",true)
    xp_stack.add_child(hud_xp_label)
    hud_xp_meter=StinkyHudMeter.new()
    hud_xp_meter.mode="xp"
    hud_xp_meter.custom_minimum_size=Vector2(360,13)
    xp_stack.add_child(hud_xp_meter)
    var upgrades_box:=PanelContainer.new()
    hud_upgrade_box = upgrades_box
    upgrades_box.visible = false
    upgrades_box.position=Vector2(1211,146)
    upgrades_box.custom_minimum_size=Vector2(53,360)
    upgrades_box.add_theme_stylebox_override("panel",_panel_style("#102c2f", "#93cbbe", 14))
    ui_root.add_child(upgrades_box)
    var upgrade_scroll:=ScrollContainer.new()
    upgrade_scroll.custom_minimum_size=Vector2(47,339)
    upgrade_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    upgrades_box.add_child(upgrade_scroll)
    hud_upgrades=VBoxContainer.new()
    hud_upgrades.add_theme_constant_override("separation",4)
    upgrade_scroll.add_child(hud_upgrades)
    message_label=Label.new()
    message_label.position=Vector2(380,18)
    message_label.custom_minimum_size=Vector2(520,40)
    message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size",19)
    message_label.add_theme_color_override("font_color",Color("f2d991"))
    ui_root.add_child(message_label)
    badge=Label.new()
    badge.position=Vector2(1070,684)
    badge.add_theme_font_size_override("font_size",13)
    badge.add_theme_color_override("font_color",Color("9af4c5"))
    badge.add_theme_color_override("font_shadow_color",Color("246d54"))
    badge.add_theme_constant_override("shadow_outline_size",4)
    ui_root.add_child(badge)
    import_dialog = FileDialog.new()
    import_dialog.title = "Import Stinky Squirrel browser progression"
    import_dialog.access = FileDialog.ACCESS_FILESYSTEM
    import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    import_dialog.filters = PackedStringArray(["*.json ; Browser save JSON"])
    import_dialog.file_selected.connect(_import_browser_save)
    ui_root.add_child(import_dialog)
    # HUD and gameplay remain native Godot. This single overlay interprets
    # simultaneous touches and is hidden for menus and upgrade cards.
    mobile_touch = preload("res://scripts/TouchOverlay.gd").new()
    ui_root.add_child(mobile_touch)
    mobile_touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mobile_touch.visible = false
    mobile_touch.menu_requested.connect(_mobile_menu_requested)
    _update_hud()

func _import_browser_save(path:String)->void:
    var f:=FileAccess.open(path,FileAccess.READ)
    if f==null:
        toast_message="COULD NOT OPEN SAVE FILE"
        toast_timer=4
        return
    var obj:Variant=JSON.parse_string(f.get_as_text())
    if not (obj is Dictionary):
        toast_message="INVALID BROWSER SAVE JSON"
        toast_timer=4
        return
    progress.kills=int(obj.get("totalKills",progress.kills))
    progress.best_wave=int(obj.get("bestWave",progress.best_wave))
    progress.boss_kills=int(obj.get("bossKills",progress.boss_kills))
    progress.acorns=int(obj.get("totalAcorns",progress.acorns))
    var source_kills:Dictionary=obj.get("weaponKills",{})
    for w in WEAPON_ORDER:
        progress.weapon_kills[w]=int(source_kills.get(w,0))
    progress.discovered=obj.get("discovered",{})
    var selected_weapon:String=str(obj.get("selectedWeapon","shotgun"))
    progress.weapon=selected_weapon if WEAPONS.has(selected_weapon) else "shotgun"
    var selected_char:String=str(obj.get("characterSkin","scout"))
    progress.character=selected_char if CHARACTER_SKINS.has(selected_char) else "scout"
    var source_skins:Dictionary=obj.get("selectedSkins",{})
    for w in WEAPON_ORDER:
        progress.gun_skins[w]=str(source_skins.get(w,SKIN_OPTIONS[w][0]))
    _save_progress()
    toast_message="BROWSER PROGRESSION IMPORTED"
    toast_timer=5
    _show_page("title")

func _make_label(text: String,size:int=17,color:String="#fff0cd",center:bool=false)->Label:
    var l:=Label.new()
    l.text=text
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",Color(color))
    var text_glow: Color = Color(color)
    text_glow.a = 0.26 if size >= 19 else 0.12
    l.add_theme_color_override("font_shadow_color",text_glow)
    l.add_theme_constant_override("shadow_outline_size",5 if size >= 19 else 2)
    l.add_theme_color_override("font_outline_color", Color("06181c"))
    l.add_theme_constant_override("outline_size",1 if size >= 19 else 0)
    l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
    l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    return l

func _heading(text:String)->void:
    var frame: PanelContainer = PanelContainer.new()
    frame.add_theme_stylebox_override("panel", _panel_style("#153837", "#eccb85", 15))
    main_layout.add_child(frame)
    var row: VBoxContainer = VBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    frame.add_child(row)
    row.add_child(_make_label("✦  " + text + "  ✦", 30, "#ffe1a0", true))
    row.add_child(_make_label("NIGHTWATCH  /  RANGER COMMAND", 11, "#96ddca", true))

func _spacer(h:int=8)->void:
    var x:=Control.new()
    x.custom_minimum_size.y=h
    main_layout.add_child(x)

func _section(text:String)->void:
    _spacer(6)
    main_layout.add_child(_make_label("◆   " + text,18,"#b4f4d4",false))
    var rule: HSeparator = HSeparator.new()
    rule.add_theme_constant_override("separation",3)
    main_layout.add_child(rule)

func _menu_button(text:String,callback:Callable,color:String="normal")->Button:
    var b:=Button.new()
    b.text=text
    b.custom_minimum_size=Vector2(0,79 if mobile_web else 38)
    b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    var bg:="#274c43"
    var border:="#caaa70"
    if color=="blue":bg="#203f51";border="#80afca"
    elif color=="purple":bg="#38294c";border="#a587cb"
    elif color=="muted":bg="#213337";border="#5d8580"
    b.add_theme_stylebox_override("normal",_panel_style(bg,border,12))
    b.add_theme_stylebox_override("hover",_panel_style("#46715c",border,12))
    b.add_theme_stylebox_override("pressed",_panel_style("#142c2b",border,12))
    b.add_theme_stylebox_override("focus",_panel_style("#00000000", "#fee2a7", 12))
    b.add_theme_color_override("font_hover_color", Color("fff9dc"))
    b.add_theme_font_size_override("font_size",17)
    b.add_theme_color_override("font_color",Color("fff0d6"))
    b.pressed.connect(callback)
    main_layout.add_child(b)
    buttons.append(b)
    return b

func _clear_menu()->void:
    buttons.clear()
    for c in main_layout.get_children():
        main_layout.remove_child(c)
        c.queue_free()

func _show_page(new_page:String)->void:
    page=new_page
    _clear_menu()
    var gaming:=page in ["playing","paused","upgrades","defeated"]
    main_panel.visible=page!="playing"
    menu_backdrop.visible=page!="playing"
    hud_left_box.visible=gaming
    hud_right_box.visible=gaming
    hud_dash_meter.visible=gaming
    hud_xp_box.visible=gaming
    hud_upgrade_box.visible=gaming and not upgrades_taken.is_empty()
    hud_status_box.visible=gaming
    badge.visible=gaming
    message_label.visible=gaming
    if mobile_touch != null:
        var show_touch: bool = page == "playing" and bool(settings.get("touch_controls", mobile_web))
        if mobile_touch.visible != show_touch:
            mobile_touch.reset_inputs()
        mobile_touch.visible = show_touch
    if hud_dash_meter != null:
        hud_dash_meter.visible = gaming and not bool(settings.get("touch_controls",mobile_web))
    match page:
        "title":_title_menu()
        "armory":_armory_menu()
        "wardrobe":_wardrobe_menu()
        "encyclopedia":_encyclopedia_menu()
        "upgrade_encyclopedia":_upgrades_reference_menu()
        "settings":_settings_menu()
        "admin":_admin_console_menu()
        "help":_help_menu()
        "upgrades":_upgrades_menu()
        "paused":_paused_menu()
        "defeated":_defeated_menu()
        "connecting":_heading("CONNECTING TO HOST...")
    _update_hud()

# -------- HTML-inspired main menu cards --------
func _menu_card(title: String, description: String, color: String) -> VBoxContainer:
    var card: PanelContainer = PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var trim: String = "#93e4b6" if title == "PLAY" else ("#d6b4ff" if title == "PROGRESSION" else "#9fdcff")
    card.add_theme_stylebox_override("panel", _panel_style(color, trim, 17))
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    card.add_child(column)
    var accent: String = "▶" if title == "PLAY" else ("✦" if title == "PROGRESSION" else "⚙")
    column.add_child(_make_label(accent + "  " + title, 19, trim, true))
    column.add_child(_make_label(description, 12, "#d1e8df", true))
    var separator: HSeparator = HSeparator.new()
    column.add_child(separator)
    if main_layout.has_meta("cards_layout"):
        var row: HBoxContainer = main_layout.get_meta("cards_layout") as HBoxContainer
        row.add_child(card)
    else:
        main_layout.add_child(card)
    return column

func _card_button(parent: VBoxContainer, text_value: String, callback: Callable, bg: String) -> Button:
    var b: Button = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(0, 76 if mobile_web else 41)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_stylebox_override("normal", _panel_style(bg, "#739c91", 11))
    b.add_theme_stylebox_override("hover", _panel_style("#40796a", "#d2bf83", 11))
    b.add_theme_stylebox_override("pressed", _panel_style("#122b2b", "#81a4a0", 11))
    b.add_theme_stylebox_override("focus", _panel_style("#00000000", "#ffdf94", 11))
    b.add_theme_color_override("font_hover_color", Color("ffffff"))
    b.add_theme_color_override("font_color", Color("#f3ead0"))
    b.add_theme_font_size_override("font_size", 15)
    b.pressed.connect(callback)
    parent.add_child(b)
    buttons.append(b)
    return b

func _title_menu()->void:
    # Brighter, glowing HTML-inspired lobby, with genuine original sprite art.
    # All of these widgets are created only on menu entry, not each frame.
    var hero_panel: PanelContainer = PanelContainer.new()
    hero_panel.add_theme_stylebox_override("panel", _panel_style("#153937", "#f8d18a", 21))
    main_layout.add_child(hero_panel)
    var banner_row: HBoxContainer = HBoxContainer.new()
    banner_row.add_theme_constant_override("separation", 13)
    hero_panel.add_child(banner_row)
    var ranger: TextureRect = _menu_portrait("outfit_trailblazer", Vector2(82,106))
    banner_row.add_child(ranger)
    var banner: VBoxContainer = VBoxContainer.new()
    banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    banner.add_theme_constant_override("separation", 5)
    banner_row.add_child(banner)
    var title_glow: Label = _make_label("✦ STINKY SQUIRREL ✦", 33, "#ffdf8d", true)
    banner.add_child(title_glow)
    # A single slow menu-only tween, automatically freed with its label.
    var title_pulse: Tween = title_glow.create_tween()
    title_pulse.set_loops()
    title_pulse.tween_property(title_glow,"modulate:a",0.81,1.9)
    title_pulse.tween_property(title_glow,"modulate:a",1.0,1.9)
    banner.add_child(_make_label("N I G H T W A T C H", 18, "#a5f7dd", true))
    banner.add_child(_make_label("INFINITE FOREST  ·  TOUCH-FRIENDLY PIXEL SURVIVAL" if OS.has_feature("web") else "INFINITE FOREST  ·  PIXEL-ART SURVIVAL  ·  SIX-PLAYER LAN", 12, "#cbe9da", true))
    var squirrel: TextureRect = _menu_portrait("boss",Vector2(77,104))
    banner_row.add_child(squirrel)
    var stats: HBoxContainer = HBoxContainer.new()
    stats.add_theme_constant_override("separation", 12)
    main_layout.add_child(stats)
    for stat in [
        {"name":"TOTAL KILLS","value":progress.kills,"accent":"#90e7ba"},
        {"name":"BEST WAVE","value":progress.best_wave,"accent":"#f7c478"},
        {"name":"BOSSES SLAIN","value":progress.boss_kills,"accent":"#dbb2ff"},
        {"name":"BANKED ACORNS","value":progress.acorns,"accent":"#7bdbf0"}
    ]:
        var cell: PanelContainer = PanelContainer.new()
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        cell.add_theme_stylebox_override("panel", _panel_style("#112b2e", str(stat.accent), 13))
        stats.add_child(cell)
        var stack: VBoxContainer = VBoxContainer.new()
        stack.add_theme_constant_override("separation",3)
        cell.add_child(stack)
        stack.add_child(_make_label(str(stat.value),23,str(stat.accent),true))
        stack.add_child(_make_label(str(stat.name),11,"#d4e8df",true))
    var cards: HBoxContainer = HBoxContainer.new()
    cards.add_theme_constant_override("separation", 13)
    main_layout.add_child(cards)
    main_layout.set_meta("cards_layout", cards)
    var play_card: VBoxContainer = _menu_card("PLAY", "Start a run, or defend the forest together.", "#193c31")
    _card_button(play_card, "▶  PLAY SOLO", Callable(self,"_start_solo"), "#296650")
    if not OS.has_feature("web"):
        _card_button(play_card, "✦  HOST LAN CO-OP", Callable(self,"_start_host"), "#255944")
        _card_button(play_card, "◇  JOIN LAN", Callable(self,"_start_join"), "#254755")
    else:
        play_card.add_child(_make_label("iOS WEB: SOLO PLAY  ·  NETWORK ROOMS REQUIRE A SEPARATE SERVER", 12, "#b6ead7", true))
    connection_text = LineEdit.new()
    connection_text.visible = not OS.has_feature("web")
    connection_text.text = "127.0.0.1"
    connection_text.placeholder_text = "Host LAN IP address"
    connection_text.custom_minimum_size.y = 32
    connection_text.add_theme_stylebox_override("normal",_panel_style("#0b2526","#679e8d",9))
    play_card.add_child(connection_text)
    var progress_card: VBoxContainer = _menu_card("PROGRESSION", "Tune your gear, looks, and build.", "#312640")
    _card_button(progress_card, "◆  ARMORY", func():_show_page("armory"), "#493962")
    _card_button(progress_card, "✦  RANGER WARDROBE", func():_show_page("wardrobe"), "#433456")
    _card_button(progress_card, "◈  SQUIRREL ENCYCLOPEDIA", func():_show_page("encyclopedia"), "#423653")
    _card_button(progress_card, "✧  UPGRADE ENCYCLOPEDIA", func():_show_page("upgrade_encyclopedia"), "#423653")
    var learn_card: VBoxContainer = _menu_card("LEARN & SETTINGS", "Graphics, controls, and progression.", "#1c3749")
    _card_button(learn_card, "⚙  SETTINGS", func():_open_settings("title"), "#24546a")
    _card_button(learn_card, "?  HOW TO PLAY", func():_show_page("help"), "#24495c")
    if not OS.has_feature("web"):
        _card_button(learn_card, "⬆  IMPORT HTML PROGRESS", func():import_dialog.popup_centered(Vector2i(900,520)), "#244d60")
    _card_button(learn_card, "⌘  ADMIN CONSOLE", func():_open_admin("title"), "#374359")
    if not OS.has_feature("web"):
        _card_button(learn_card, "✕  QUIT GAME", func():_request_exit("quit"), "#503540")
    learn_card.add_child(_make_label("iPhone/iPad: landscape orientation and two-thumb controls" if mobile_web else "Browser save JSON  ·  See SAVE_IMPORT_GUIDE.txt", 12, "#b3d4d0", true))
    main_layout.remove_meta("cards_layout")
    var footer: PanelContainer = PanelContainer.new()
    footer.add_theme_stylebox_override("panel",_panel_style("#0d2527", "#568980", 10))
    main_layout.add_child(footer)
    footer.add_child(_make_label("EQUIPPED: %s  /  %s     •     WEB / SAFARI TOUCH EDITION" % [str(WEAPONS[progress.weapon].name),str(CHARACTER_SKINS[progress.character].name)] if OS.has_feature("web") else "EQUIPPED: %s  /  %s     •     LOCAL LAN: UDP 27844" % [str(WEAPONS[progress.weapon].name),str(CHARACTER_SKINS[progress.character].name)], 12, "#c1e5d9", true))

func _menu_portrait(key: String, image_size: Vector2) -> TextureRect:
    var preview: TextureRect = TextureRect.new()
    preview.custom_minimum_size = image_size
    preview.texture = load("res://art/%s.png" % key)
    preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return preview

func _choose_weapon(id:String)->void:
    if not _unlocked_weapon(id):return
    progress.weapon=id
    _save_progress()
    _show_page("armory")

func _choose_gun_skin(name:String)->void:
    var weapon_id: String = str(progress.weapon)
    var index: int = SKIN_OPTIONS[weapon_id].find(name)
    if not _unlocked_gun_skin(weapon_id,index):return
    progress.gun_skins[progress.weapon]=name
    _save_progress()
    _show_page("armory")

func _choose_character(id:String)->void:
    if not _unlocked_character(id):return
    progress.character=id
    _save_progress()
    _show_page("wardrobe")

func _armory_menu()->void:
    _heading("ARMORY")
    _section("PERMANENT WEAPON UNLOCKS")
    for w in WEAPON_ORDER:
        var unlocked:=_unlocked_weapon(w)
        var title:=str(WEAPONS[w].name)
        var condition: String = "Unlocked" if unlocked else ("%d total kills" % int(WEAPONS[w].unlock))
        if w=="railgun" and not unlocked:condition="2400 kills + wave 30 + 14 bosses"
        var b:=_menu_button("%s   —   %s%s" % [title,condition,"  [EQUIPPED]" if progress.weapon==w else ""],Callable(self,"_choose_weapon").bind(w))
        b.disabled=not unlocked
    _section("WEAPON SKINS — %s" % WEAPONS[progress.weapon].name)
    main_layout.add_child(_make_label("ORIGINAL HTML-STYLE SILHOUETTES  ·  HOVER AND EQUIP",13,"#a6e9dc"))
    var gallery: GridContainer = GridContainer.new()
    gallery.columns = 2
    gallery.add_theme_constant_override("h_separation", 12)
    gallery.add_theme_constant_override("v_separation", 12)
    main_layout.add_child(gallery)
    var index: int = 0
    for skin in SKIN_OPTIONS[progress.weapon]:
        var chosen: bool = str(progress.gun_skins[progress.weapon]) == skin
        var available: bool = _unlocked_gun_skin(str(progress.weapon),index)
        var premium: bool = index > 0
        var accent: String = "#ffe09a" if chosen else ("#d4a7ff" if index >= 2 else ("#7fece0" if premium else "#78dccc"))
        var preview_card: PanelContainer = PanelContainer.new()
        preview_card.custom_minimum_size = Vector2(443,106)
        preview_card.add_theme_stylebox_override("panel", _panel_style("#1f283e" if premium else "#102629", accent,16))
        gallery.add_child(preview_card)
        var preview_row: HBoxContainer = HBoxContainer.new()
        preview_row.add_theme_constant_override("separation",14)
        preview_card.add_child(preview_row)
        var preview_texture: TextureRect = TextureRect.new()
        preview_texture.texture = load("res://ui/guns/%s_%d.png" % [str(progress.weapon),index])
        preview_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        preview_texture.custom_minimum_size=Vector2(204,82)
        preview_row.add_child(preview_texture)
        # Small alpha-gradient bloom texture. Prebaked once at import, no shader pass.
        if premium:
            var glow: TextureRect = TextureRect.new()
            glow.texture = load("res://ui/guns/glows/%s_%d.png" % [str(progress.weapon),index])
            glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
            preview_texture.add_child(glow)
        var stack: VBoxContainer = VBoxContainer.new()
        stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        preview_row.add_child(stack)
        stack.add_child(_make_label(skin,16,"#ffe9b8"))
        stack.add_child(_make_label("EQUIPPED" if chosen else ("PREMIUM GRADIENT GLOW" if available and premium else ("COSMETIC SKIN" if available else "LOCKED COSMETIC")),12,accent))
        stack.add_child(_make_label("Unlocked" if available else _gun_skin_requirement_text(str(progress.weapon),index),11,"#aac7c5"))
        var choose_btn: Button = Button.new()
        choose_btn.text = "EQUIPPED" if chosen else ("EQUIP SKIN" if available else "LOCKED")
        choose_btn.disabled = chosen or not available
        choose_btn.add_theme_stylebox_override("normal",_panel_style("#244b48","#9de4d4",9))
        choose_btn.add_theme_stylebox_override("hover",_panel_style("#376a67","#ffdfa2",9))
        choose_btn.pressed.connect(Callable(self,"_choose_gun_skin").bind(skin))
        stack.add_child(choose_btn)
        index += 1
    _menu_button("BACK TO MAIN MENU",func():_show_page("title"),"muted")

func _wardrobe_menu()->void:
    _heading("RANGER WARDROBE")
    _section("ORIGINAL RANGER ART  ·  PERMANENT UNLOCK MISSIONS")
    var gallery: GridContainer = GridContainer.new()
    gallery.columns = 2
    gallery.add_theme_constant_override("h_separation", 10)
    gallery.add_theme_constant_override("v_separation", 10)
    main_layout.add_child(gallery)
    for skin_id in CHARACTER_SKINS:
        var info: Dictionary = CHARACTER_SKINS[skin_id]
        var available: bool = _unlocked_character(str(skin_id))
        var selected: bool = progress.character == skin_id
        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(450,106)
        card.add_theme_stylebox_override("panel",_panel_style("#2b2342" if selected else "#182d31", "#d6bd8b" if selected else "#55776f",14))
        gallery.add_child(card)
        var line: HBoxContainer = HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        card.add_child(line)
        var icon_name: String = "hero" if skin_id == "scout" else "outfit_"+str(skin_id)
        var avatar: TextureRect = TextureRect.new()
        avatar.custom_minimum_size = Vector2(69,80)
        avatar.texture = load("res://art/%s.png" % icon_name)
        avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        line.add_child(avatar)
        var details: VBoxContainer = VBoxContainer.new()
        details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(details)
        details.add_child(_make_label(str(info.name),17,"#ffe2af"))
        details.add_child(_make_label(str(info.perk),13,"#c5e6d7"))
        details.add_child(_make_label(str(info.requirement),12,"#a7c5c0"))
        var equip: Button = Button.new()
        equip.text = "EQUIPPED" if selected else ("EQUIP" if available else "LOCKED")
        equip.disabled = not available
        equip.custom_minimum_size = Vector2(96,32)
        equip.pressed.connect(Callable(self,"_choose_character").bind(str(skin_id)))
        details.add_child(equip)
    _menu_button("BACK",func():_show_page("title"),"muted")

func _encyclopedia_menu()->void:
    _heading("SQUIRREL ENCYCLOPEDIA")
    _menu_button("REGULAR ENEMIES",func():encyclopedia_tab="enemies";_show_page("encyclopedia"),"blue")
    _menu_button("BOSSES",func():encyclopedia_tab="bosses";_show_page("encyclopedia"),"purple")
    var ids:Array=ENEMY_ORDER if encyclopedia_tab=="enemies" else BOSS_KINDS
    _section("DISCOVERED %s" % encyclopedia_tab.to_upper())
    for kind in ids:
        var seen:bool=admin_mode or bool(progress.discovered.get(kind,false))
        var name: String = String(kind).replace("_"," ").capitalize() if encyclopedia_tab=="enemies" else String(BOSS_NAMES[BOSS_KINDS.find(kind)])
        var entry:=HBoxContainer.new()
        entry.add_theme_constant_override("separation",14)
        main_layout.add_child(entry)
        var portrait:=TextureRect.new()
        portrait.custom_minimum_size=Vector2(72,72)
        portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.texture=load("res://art/encyclopedia/%s.png" % (str(kind) if seen else "unknown"))
        portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        entry.add_child(portrait)
        var copy:=VBoxContainer.new()
        copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        entry.add_child(copy)
        copy.add_child(_make_label(name if seen else "??? · Undiscovered",17,"#f2dea5" if seen else "#809a97",true))
        copy.add_child(_make_label(("⬆  LEVEL SCALES WITH WAVES  ·  " + str(ENEMY_DESCRIPTIONS[kind])) if seen else "Encounter to reveal this entry",14,"#b7dad0"))
    _menu_button("BACK",func():_show_page("title"),"muted")

func _ency_upgrade_row(key: String, description: String) -> void:
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    main_layout.add_child(line)
    var portrait:=TextureRect.new()
    portrait.custom_minimum_size=Vector2(48,48)
    portrait.texture=load("res://art/encyclopedia/upgrades/%s.png" % key)
    portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    line.add_child(portrait)
    var v:=VBoxContainer.new()
    line.add_child(v)
    v.add_child(_make_label(key.replace("_"," "),16,"#ffe0aa",true))
    v.add_child(_make_label(description,13,"#c8e4d6"))

func _upgrades_reference_menu()->void:
    _heading("RUN UPGRADE ENCYCLOPEDIA")
    _section("GENERAL")
    for k in GENERAL_UPGRADES:_ency_upgrade_row(k,GENERAL_UPGRADES[k])
    for w in WEAPON_ORDER:
        _section(WEAPONS[w].name.to_upper()+" SPECIALTIES")
        for k in UNIQUE_UPGRADES[w]:_ency_upgrade_row(k,UNIQUE_UPGRADES[w][k])
    _section("SPECIAL LEGENDARIES")
    for k in LEGENDARY_UPGRADES:_ency_upgrade_row(k,LEGENDARY_UPGRADES[k])
    _menu_button("BACK",func():_show_page("title"),"muted")

func _fx_row(key: String, label_text: String, description: String, cost: String) -> void:
    var row: PanelContainer = PanelContainer.new()
    row.add_theme_stylebox_override("panel", _panel_style("#162d30", "#3e6965", 11))
    main_layout.add_child(row)
    var line: HBoxContainer = HBoxContainer.new()
    line.add_theme_constant_override("separation", 9)
    row.add_child(line)
    var info: VBoxContainer = VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.custom_minimum_size.x = 440
    line.add_child(info)
    info.add_child(_make_label(label_text + "   [" + cost + "]", 16, "#f4dab0"))
    info.add_child(_make_label(description, 12, "#b5d0c9"))
    var toggle: CheckButton = CheckButton.new()
    toggle.text = "ON" if bool(settings.get(key, false)) else "OFF"
    toggle.button_pressed = bool(settings.get(key, false))
    toggle.custom_minimum_size.x = 72
    toggle.toggled.connect(func(enabled: bool) -> void:
        _set_fx_bool(key, enabled)
        toggle.text = "ON" if enabled else "OFF"
    )
    line.add_child(toggle)
    var slider: HSlider = HSlider.new()
    slider.custom_minimum_size = Vector2(150, 28)
    slider.min_value = 0.05
    slider.max_value = 1.0
    slider.step = 0.05
    slider.value = float(settings.get(key + "_strength", FX_STRENGTH_DEFAULT))
    slider.value_changed.connect(func(new_value: float) -> void: _set_fx_strength(key, new_value))
    line.add_child(slider)

func _set_general_option(enabled: bool, key: String) -> void:
    settings[key] = enabled
    if key == "music" and not enabled:
        music.stop()
        boss_music.stop()
    _save_progress()

func _settings_menu()->void:
    _heading("SETTINGS")
    var tab_row: HBoxContainer = HBoxContainer.new()
    tab_row.add_theme_constant_override("separation", 12)
    main_layout.add_child(tab_row)
    for tab_id in ["general", "graphics"]:
        var tab: Button = Button.new()
        tab.text = tab_id.to_upper()
        tab.custom_minimum_size = Vector2(0, 76 if mobile_web else 42)
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.add_theme_stylebox_override("normal", _panel_style("#38594c" if graphics_tab == tab_id else "#1b3439", "#d4b67e" if graphics_tab == tab_id else "#497476", 12))
        tab.add_theme_stylebox_override("hover", _panel_style("#527968", "#d4b67e", 12))
        tab.pressed.connect(Callable(self,"_change_settings_tab").bind(tab_id))
        tab_row.add_child(tab)
    if graphics_tab == "general":
        _section("GENERAL / ACCESSIBILITY")
        for item in [
            ["touch_controls", "TOUCH TWIN-STICK CONTROLS", "Two joysticks, reload, dash and menu on the screen."],
            ["fps", "FPS COUNTER", "Display your current native frame rate."],
            ["weather", "DAY & WEATHER EFFECTS", "Rain, snow, fog and the host-synchronized cycle."],
            ["music", "SOUND / MUSIC", "Audio and original boss music."],
            ["novelty", "FAKE STINKY MERCH ADS", "Entirely fictional novelty pop-ups, off by default."]
        ]:
            var setting_key: String = str(item[0])
            var toggle: CheckButton = CheckButton.new()
            toggle.text = str(item[1]) + "    —    " + str(item[2])
            toggle.button_pressed = bool(settings.get(setting_key, false))
            toggle.custom_minimum_size.y = 72 if mobile_web else 46
            toggle.toggled.connect(Callable(self,"_set_general_option").bind(setting_key))
            main_layout.add_child(toggle)
        _section("PERFORMANCE")
        main_layout.add_child(_make_label("Browser frame cap: 60 FPS, Compatibility / WebGL2, single-threaded. Mobile Safari disables the full-screen shader pass. Desktop native cap: 120 FPS.", 14, "#c8e0c9"))
    else:
        main_layout.add_child(_make_label("NATIVE GPU SHADERS  ·  Customize effects individually. Most are off by default to protect FPS.", 14, "#a7dfca", true))
        var presets: HBoxContainer = HBoxContainer.new()
        presets.add_theme_constant_override("separation", 8)
        main_layout.add_child(presets)
        for preset_name in ["Original Pixels", "Performance", "Balanced", "Cinematic"]:
            var preset_button: Button = Button.new()
            preset_button.text = preset_name
            preset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            preset_button.custom_minimum_size.y = 37
            preset_button.add_theme_stylebox_override("normal", _panel_style("#2b4946", "#668d82", 11))
            preset_button.pressed.connect(Callable(self,"_apply_graphics_preset").bind(preset_name))
            presets.add_child(preset_button)
        _section("IMAGE CLARITY")
        main_layout.add_child(_make_label("CRISP PIXELS  ·  No blur, anti-alias smoothing or anisotropic filtering at any quality setting. Original nearest-neighbor sprites stay sharp.",14,"#b6f5d6",true))
        var category: String = ""
        for effect in GRAPHICS_EFFECTS:
            var group: String = str(effect.group)
            if category != group:
                category = group
                _section(category)
            _fx_row(str(effect.id), str(effect.name), str(effect.desc), str(effect.cost))
        _spacer(8)
        main_layout.add_child(_make_label("NOTE: True depth-buffer SSR, SSAO, 3D volumetric fog, and temporal TAA require a future 2.5D geometry stage. Current Godot features are native shader/sprite techniques—not physically accurate 3D depth effects.", 13, "#fac98c"))
    _menu_button("BACK",func():_show_page(settings_return_page),"muted")

# -------- Local developer console (password gate; not a network privilege) --------
func _open_admin(from_page: String) -> void:
    admin_return_page = from_page
    _show_page("admin")

func _admin_console_menu() -> void:
    _heading("NIGHTWATCH  /  DEVELOPER CONSOLE")
    _section("LOCAL ADMIN TOOLS")
    main_layout.add_child(_make_label("A local testing tool. Commands affect only this computer's progression. The password is a convenience gate, not a security boundary.",14,"#b8ded4",true))
    _spacer(8)
    if not admin_authenticated:
        main_layout.add_child(_make_label("ENTER ADMIN PASSWORD",17,"#ffe3ab",true))
        admin_password_field = LineEdit.new()
        admin_password_field.secret = true
        admin_password_field.placeholder_text = "Password"
        admin_password_field.custom_minimum_size.y = 44
        admin_password_field.add_theme_stylebox_override("normal",_panel_style("#102b30","#d5b784",12))
        main_layout.add_child(admin_password_field)
        admin_password_field.text_submitted.connect(func(_value: String) -> void: _admin_login())
        _menu_button("UNLOCK CONSOLE",Callable(self,"_admin_login"),"blue")
        admin_password_field.call_deferred("grab_focus")
    else:
        main_layout.add_child(_make_label("ACCESS GRANTED   •   ADMIN OVERRIDE: %s" % ("ACTIVE" if admin_mode else "OFF"),16,"#ffd68f" if admin_mode else "#9fe7cb",true))
        _spacer(4)
        admin_command_field = LineEdit.new()
        admin_command_field.placeholder_text = "Type a command, for example /unlockall"
        admin_command_field.custom_minimum_size.y = 44
        admin_command_field.add_theme_stylebox_override("normal",_panel_style("#102b30","#88cbb7",11))
        main_layout.add_child(admin_command_field)
        admin_command_field.text_submitted.connect(_admin_execute_command)
        _menu_button("EXECUTE COMMAND",func():_admin_execute_command(admin_command_field.text),"blue")
        main_layout.add_child(_make_label("/unlockall    /unlockoriginal    /status    /help",13,"#b3dbcf",true))
        var log_panel: PanelContainer = PanelContainer.new()
        log_panel.add_theme_stylebox_override("panel",_panel_style("#0a1d25", "#486c77",10))
        main_layout.add_child(log_panel)
        var log_text: Label = _make_label("\n".join(PackedStringArray(admin_messages.slice(maxi(0,admin_messages.size()-8)))) if not admin_messages.is_empty() else "Ready. Use /help for available commands.",13,"#b8efdb",true)
        log_panel.add_child(log_text)
        admin_command_field.call_deferred("grab_focus")
    _spacer(10)
    _menu_button("BACK",func():_show_page(admin_return_page),"muted")

func _admin_login() -> void:
    if admin_password_field == null:return
    if admin_password_field.text != ADMIN_PASSWORD:
        admin_password_field.clear()
        admin_messages.append("Incorrect password.")
        toast_message = "ADMIN ACCESS DENIED"
        toast_timer = 3.0
        return
    admin_authenticated = true
    admin_messages.append("Admin console unlocked for this session.")
    _show_page("admin")

func _admin_execute_command(raw: String) -> void:
    if not admin_authenticated:return
    var command: String = raw.strip_edges().to_lower()
    if command == "":return
    var response: String = ""
    match command:
        "/help":
            response = "Commands: " + ", ".join(PackedStringArray(ADMIN_COMMANDS))
        "/status":
            response = "Override: %s  |  Real kills: %d  |  Best wave: %d  |  Real boss wins: %d" % ["ON" if admin_mode else "OFF",int(progress.kills),int(progress.best_wave),int(progress.boss_kills)]
        "/unlockall":
            response = _admin_unlock_all()
        "/unlockoriginal":
            response = _admin_unlock_original()
        _:
            response = "Unknown command: %s  (type /help)" % command
    admin_messages.append("> " + command + "  |  " + response)
    _show_page("admin")

func _admin_unlock_all() -> String:
    if admin_mode:return "All items are already temporarily unlocked. Your backup has not been overwritten."
    # Snapshot BEFORE enabling the override; never overwrite an active snapshot.
    _flush_progress()
    var file: FileAccess = FileAccess.open(ADMIN_BACKUP_FILE,FileAccess.WRITE)
    if file == null:return "Could not create original-progress backup; no unlocks changed."
    file.store_string(JSON.stringify({"version":1,"progress":progress.duplicate(true)}))
    file.flush()
    admin_mode = true
    _save_progress()
    _flush_progress()
    return "Everything unlocked for testing: weapons, gun skins, outfits, and squirrel entries. Real progress backed up."

func _admin_unlock_original() -> String:
    if not admin_mode:return "Already using original progression; nothing to restore."
    if not FileAccess.file_exists(ADMIN_BACKUP_FILE):return "Backup is missing. Restore aborted to protect your progress."
    var file: FileAccess = FileAccess.open(ADMIN_BACKUP_FILE,FileAccess.READ)
    if file == null:return "Could not open the progress backup; no changes made."
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):return "Backup is invalid. Restore aborted."
    var original: Variant = parsed.get("progress",null)
    if not (original is Dictionary):return "Backup has no progress data. Restore aborted."
    progress = (original as Dictionary).duplicate(true)
    admin_mode = false
    _save_progress()
    _flush_progress()
    return "Original progression restored exactly from the pre-unlockall backup."

func _help_menu()->void:
    _heading("SURVIVAL GUIDE")
    main_layout.add_child(_make_label("iPhone/iPad: LEFT STICK = MOVE   •   RIGHT STICK = AIM + FIRE\nDASH / RELOAD = on-screen buttons   •   II = pause/menu\nRotate to LANDSCAPE for the best play area." if OS.has_feature("web") else "WASD or arrows: move   •   Mouse: aim   •   Left click: shoot\nR: reload   •   Space: dash toward mouse   •   Esc: pause",17))
    _spacer(12)
    main_layout.add_child(_make_label("Defeat squirrels for floating ✦ XP. Approach to collect it and level up for three-card rarity upgrades. Leftover XP automatically flies toward your team after each wave. Acorns still heal and fill the permanent bank.",16))
    _spacer(12)
    main_layout.add_child(_make_label("Browser note: iOS Safari supports this single-player Web export, but ENet/UDP LAN networking does not run in browsers. An external WSS/WebRTC server is needed for web co-op." if OS.has_feature("web") else "Native LAN hosting uses UDP 27844: the guest needs the host's local IP. This differs from the original HTML WebRTC code exchange and may be blocked on managed networks.",15,"#f6cb85"))
    _menu_button("BACK",func():_show_page("title"),"muted")

func _upgrades_menu()->void:
    _heading("✦ LEVEL %d  ·  POWER UP!" % run_level)
    main_layout.add_child(_make_label("XP LEVEL-UP  ·  CHOOSE 1, 2 OR 3",17,"#aef4df",true))
    _spacer(12)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",12)
    main_layout.add_child(row)
    for i in range(upgrade_choices.size()):
        var opt: Dictionary = upgrade_choices[i]
        var r: int = clampi(int(opt.get("rarity",0)),0,4)
        var rarity_color: Color = Color(RARITY_COLORS[r])
        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size=Vector2(291,214)
        card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel",_panel_style("#36263d" if r>=3 else "#163639",RARITY_COLORS[r],17))
        row.add_child(card)
        var body: VBoxContainer = VBoxContainer.new()
        body.add_theme_constant_override("separation",9)
        card.add_child(body)
        var top: HBoxContainer = HBoxContainer.new()
        body.add_child(top)
        var number_tag: Label = _make_label("[%d]" % (i+1),20,"#fff7dc")
        top.add_child(number_tag)
        top.add_spacer(false)
        top.add_child(_make_label(RARITY_NAMES[r].to_upper(),13,RARITY_COLORS[r]))
        body.add_child(_make_label(str(opt.id).replace("_"," "),19,"#fff2d3",true))
        var glow_strip: ColorRect = ColorRect.new()
        glow_strip.custom_minimum_size=Vector2(0,4)
        glow_strip.color=rarity_color
        body.add_child(glow_strip)
        var description: Label = _make_label(str(opt.description),14,"#d3efe7",true)
        description.custom_minimum_size=Vector2(0,62)
        body.add_child(description)
        var choose: Button = Button.new()
        choose.text="HOST CHOOSING…" if mode=="guest" else "CHOOSE [ %d ]" % (i+1)
        choose.disabled=(mode=="guest")
        choose.custom_minimum_size=Vector2(0,77 if mobile_web else 40)
        choose.add_theme_color_override("font_color",Color("fff4de"))
        choose.add_theme_stylebox_override("normal",_panel_style("#234c45",RARITY_COLORS[r],11))
        choose.add_theme_stylebox_override("hover",_panel_style("#3f7569",RARITY_COLORS[r],11))
        choose.add_theme_stylebox_override("pressed",_panel_style("#142f2c",RARITY_COLORS[r],11))
        choose.pressed.connect(Callable(self,"_apply_upgrade").bind(opt))
        body.add_child(choose)
    _spacer(10)
    var reroll: Button = _menu_button("REROLL CHOICES  ·  8 BANKED ACORNS  (BANK: %d)" % int(progress.acorns),func():
        if not upgrades_rerolled and progress.acorns >= 8:
            upgrades_rerolled=true
            progress.acorns-=8
            _save_progress()
            upgrade_choices=_upgrade_options()
            _show_page("upgrades")
    ,"blue")
    reroll.disabled = mode=="guest" or upgrades_rerolled or int(progress.acorns)<8
    main_layout.add_child(_make_label("ONE REROLL PER LEVEL  ·  RARITY BOOSTS UPGRADE STRENGTH",12,"#a1c9c0",true))

func _paused_menu()->void:
    _heading("PAUSED")
    _menu_button("RESUME",func():_show_page("playing"))
    _menu_button("SETTINGS",func():_open_settings("paused"),"blue")
    _menu_button("ADMIN CONSOLE",func():_open_admin("paused"),"purple")
    _menu_button("MAIN MENU",Callable(self,"_return_menu"),"muted")
    if not OS.has_feature("web"):
        _menu_button("QUIT GAME",func():_request_exit("quit"),"muted")

func _defeated_menu()->void:
    _heading("YOU WERE OVERRUN")
    main_layout.add_child(_make_label("Reached wave %d • %d squirrels vanquished • %d acorns collected" % [wave,stage_kills,run_acorns],18,"#d9f0bd",true))
    _menu_button("TRY AGAIN",Callable(self,"_start_run"))
    _menu_button("MAIN MENU",Callable(self,"_return_menu"),"muted")
    if not OS.has_feature("web"):
        _menu_button("QUIT GAME",func():_request_exit("quit"),"muted")

func _update_hud()->void:
    if hud_left == null:
        return
    var local_player: Dictionary = players.get(local_id,{})
    if not local_player.is_empty():
        var hp_value: float = float(local_player.hp)
        var max_hp_value: float = maxf(1,float(local_player.max_hp))
        var left_text: String = "◈ %02d   ·   %s\n♥ %d/%d" % [wave,"◉" if mode!="solo" else "◆",int(ceil(hp_value)),int(ceil(max_hp_value))]
        hud_enemy_count.text=str(enemies.size()+to_spawn)
        hud_kill_count.text=str(stage_kills)
        if hud_left.text != left_text: hud_left.text = left_text
        hud_hp_meter.update_meter(hp_value,max_hp_value)
        var gun_text: String = "%s  ·  %s" % [str(WEAPONS[local_player.weapon].name).to_upper(),str(local_player.skin)]
        if hud_right.text != gun_text: hud_right.text = gun_text
        hud_ammo_meter.update_meter(float(local_player.ammo),float(local_player.mag),float(local_player.reload))
        hud_dash_meter.update_meter(float(local_player.dash_cd),2.6)
    hud_acorns_collected.text=str(run_acorns)
    hud_acorns_saved.text=str(int(progress.acorns))
    hud_best_wave.text=str(int(progress.best_wave))
    if hud_xp_meter!=null:
        hud_xp_meter.update_meter(run_xp,xp_to_next)
        hud_xp_label.text="✦ %d     %d / %d" % [run_level,int(run_xp),int(xp_to_next)]
    var fps_text: String = "%d FPS" % int(Engine.get_frames_per_second()) if settings.get("fps",true) else ""
    if badge.text != fps_text: badge.text = fps_text
    var toast_text: String = toast_message if toast_timer > 0 else (boss_name if wave%5 == 0 and boss_name != "" else "")
    if message_label.text != toast_text: message_label.text = toast_text
    if hud_upgrade_box != null:
        hud_upgrade_box.visible = page in ["playing", "paused", "upgrades", "defeated"] and not upgrades_taken.is_empty()
    if hud_upgrades.get_child_count() != upgrades_taken.size():
        for child in hud_upgrades.get_children():
            hud_upgrades.remove_child(child)
            child.queue_free()
        var icon_map: Dictionary = {"FIRE_ROUNDS":"🔥","ICE_ROUNDS":"❄","CHAIN_LIGHTNING":"⚡","FOREST_BOOTS":"➤","BARK_ARMOR":"◆","ACORN_FEAST":"🌰","ECHO_DASH":"💨","BLOODSCENT":"♥","ACORN_MAGNET":"✦","ENTROPY_NOVA":"☼","ABSOLUTE_ZERO":"❄","ION_STORM":"⚡"}
        for option in upgrades_taken:
            var rarity: int = clampi(int(option.get("rarity",0)),0,RARITY_COLORS.size()-1)
            var upgrade_id: String = str(option.get("id",""))
            var icon: String = str(icon_map.get(upgrade_id,"✦"))
            var b: Button = Button.new()
            b.text = icon
            b.custom_minimum_size = Vector2(42,38)
            b.add_theme_font_size_override("font_size",18)
            b.add_theme_color_override("font_color",Color(RARITY_COLORS[rarity]))
            b.add_theme_stylebox_override("normal",_panel_style("#102a2c",RARITY_COLORS[rarity],11))
            b.add_theme_stylebox_override("hover",_panel_style("#1a4444",RARITY_COLORS[rarity],11))
            b.tooltip_text = "[%s] %s\n%s" % [RARITY_NAMES[rarity],upgrade_id.replace("_"," "),str(option.get("description",""))]
            b.focus_mode = Control.FOCUS_ALL
            hud_upgrades.add_child(b)
