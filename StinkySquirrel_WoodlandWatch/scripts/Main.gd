extends Node2D
## Stinky Squirrel: Woodland Watch — cooperative campaign.
## The original source is supplied unchanged in reference/ for exhaustive parity work.
## This native implementation is independent of HTML, JavaScript, WebView and .NET.

const Campaign = preload("res://scripts/Campaign.gd")
const WEB_PROFILE_KEY := "woodland-watch.profile.v1"
const WEB_PROFILE_BACKUP_KEY := "woodland-watch.profile.before-import"
const SAVE_FILE := "user://woodland_watch_save.json"
const HOST_SAVE_FILE := "user://woodland_watch_host.json"
const SITE_RADIUS := 108.0

const BossPatterns = preload("res://scripts/BossPatterns.gd")
const NetState = preload("res://scripts/NetState.gd")
const ProfileTransfer = preload("res://scripts/ProfileTransfer.gd")
const GuestMotion = preload("res://scripts/GuestMotion.gd")
const SNAPSHOT_INTERVAL := 1.0 / 15.0
const SNAPSHOT_MAX_BYTES := 262144
const RangerProgress := preload("res://scripts/RangerProgress.gd")
const PUBLIC_GAME_HOST := "play.stinkysquirrel.online"
const CHEST_REACH := 67.0
const DASH_DURATION := .24
const DASH_DISTANCE := 225.0
const MAP := 192.0
const PORT := 27844
const HOST_ID := 1
const MAX_GUESTS := 5
const CENTER := Vector2(640, 368)
const BOSS_KINDS := ["king","toxicboss","frostboss","council","burrower","stormboss","weaver","nutpocalypse"]
const BOSS_NAMES := ["THE CROWNED MENACE","TOXIC MATRIARCH","FROST BARON","THE ACORN COUNCIL","CLOCKWORK BURROWER","STORM HERALD","THE SILKEN EMPRESS","THE NUTPOCALYPSE"]
const BOSS_WAVES := [5,10,15,20,25,30,35,40]
const FieldPatterns = preload("res://scripts/FieldPatterns.gd")
const WEAPONS := {
    "shotgun":{"name":"Shotgun","ammo":6,"cooldown":.67,"reload":1.25,"damage":15.0,"pellets":6,"spread":.66,"range":385.0,"unlock":0},
    "pistol":{"name":"Pistol","ammo":12,"cooldown":.40,"reload":.95,"damage":17.0,"pellets":1,"spread":.06,"range":473.0,"unlock":110},
    "smg":{"name":"SMG","ammo":28,"cooldown":.163,"reload":1.30,"damage":10.5,"pellets":1,"spread":.18,"range":330.0,"unlock":250},
    "ar":{"name":"AR","ammo":20,"cooldown":.109,"reload":1.35,"damage":13.0,"pellets":1,"spread":.09,"range":462.0,"unlock":425},
    "sniper":{"name":"Sniper","ammo":4,"cooldown":.95,"reload":1.5,"damage":58.0,"pellets":1,"spread":.025,"range":682.0,"unlock":650},
    "railgun":{"name":"RAILGUN","ammo":3,"cooldown":1.32,"reload":2.25,"damage":295.0,"pellets":1,"spread":0.0,"range":1155.0,"unlock":2400}
,
    "lever":{"name":"Lever Carbine","ammo":10,"cooldown":0.28,"reload":1.18,"damage":19,"pellets":1,"spread":0.045,"range":490,"unlock":0},
    "birch_auto":{"name":"Birch Auto","ammo":30,"cooldown":0.133,"reload":1.29,"damage":11.8,"pellets":1,"spread":0.12,"range":365,"unlock":0},
    "needle":{"name":"Needle PDW","ammo":34,"cooldown":0.089,"reload":1.38,"damage":14.1,"pellets":1,"spread":0.105,"range":414,"unlock":0},
    "tempest":{"name":"Tempest Repeater","ammo":38,"cooldown":0.075,"reload":1.49,"damage":15,"pellets":1,"spread":0.16,"range":439,"unlock":0},
    "mistral":{"name":"Mistral Gatling","ammo":54,"cooldown":0.061,"reload":1.64,"damage":15.8,"pellets":1,"spread":0.205,"range":397,"unlock":0}
}
const ORIGINAL_WEAPONS := ["shotgun","pistol","smg","ar","sniper","railgun"]
const WEAPON_LICENSE_ORDER := ["shotgun","pistol","lever","smg","birch_auto","ar","needle","sniper","tempest","railgun","mistral"]
const WEAPON_ORDER := ["shotgun","pistol","lever","smg","ar","needle","sniper","railgun","mistral"]
const RETIRED_WEAPONS := {"birch_auto":"smg", "tempest":"ar"}
const CHARACTER_SKINS := {
    "scout":{"name":"Forest Scout","perk":"No passive bonus","requirement":"Starter ranger","kind":"starter","value":0},
    "trailblazer":{"name":"Trailblazer","perk":"+14% movement speed","requirement":"180 total kills","kind":"kills","value":180},
    "sharpsight":{"name":"Sharpsight","perk":"+12% weapon damage","requirement":"Clear chapter 2","kind":"wave","value":10},
    "ironbark":{"name":"Ironbark","perk":"+35 maximum HP","requirement":"Defeat 5 bosses","kind":"bosses","value":5},
    "cindercloak":{"name":"Cindercloak","perk":"Igniting shots","requirement":"600 total kills","kind":"kills","value":600},
    "frostbound":{"name":"Frostbound","perk":"Freezing shots","requirement":"Clear chapter 7","kind":"special","value":8}
}
const SKIN_OPTIONS := {
    "shotgun":["Woodland","Blaze Core","Aurora Moss"],
    "pistol":["Courier","Cherry Volt","Blue Ember"],
    "smg":["Scrapwire","Slime Pop","Neon Static"],
    "ar":["Canopy","Sunset","Royal Fern"],
    "sniper":["Long Night","Icepine","Golden Hush"],
    "railgun":["Void Prism","Starfall","Solar Reactor","Celestial Static"]
,
    "lever":["Birchstock","Copper Lever"],
    "birch_auto":["Birch Bark","Verdant Alloy"],
    "needle":["Slate Needle","Brightsteel"],
    "tempest":["Stormcloud","Violet Squall"],
    "mistral":["Iron Wind","Sunforge"]
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
,
    "lever":[["starter",0],["weapon_kills",70]],
    "birch_auto":[["starter",0],["weapon_kills",70]],
    "needle":[["starter",0],["weapon_kills",70]],
    "tempest":[["starter",0],["weapon_kills",70]],
    "mistral":[["starter",0],["weapon_kills",70]]
}
const ADMIN_BACKUP_FILE := "user://woodland_watch_admin_backup.json"
const ADMIN_PASSWORD := "1234"
const ADMIN_COMMANDS := ["/help", "/status", "/unlockall", "/unlockoriginal", "/reset"]
const RARITY_NAMES := ["Common","Uncommon","Rare","Epic","Legendary"]
const RARITY_WEIGHTS := [47,28,15,8,2]
const RARITY_SCALES := [1.0,1.28,1.7,2.2,3.0]
const RARITY_COLORS := ["#e7dfca","#a6ec96","#78c6ff","#d6a2ff","#ffd469"]
const GENERAL_UPGRADES := {
    "FOREST_BOOTS":"Move 12% faster", "BARK_ARMOR":"+24 max HP and heal", "ACORN_FEAST":"Acorns restore more health", "ECHO_DASH":"Dash recharges faster",
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
const WEAPON_UPGRADE_FAMILY := {"lever":"pistol","birch_auto":"smg","needle":"smg","tempest":"ar","mistral":"ar"}
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
    "charger":"A tusked charger that locks on and rushes in a straight line.",
    "grenadier":"Marks explosive landing zones before throwing an acorn charge.",
    "splitter":"Breaks into two small sprinters when defeated.",
    "wisp":"Circles the squad and fires a fan of cold projectiles.",
    "bulwark":"A slow captain that reduces damage to nearby allies.",
    "stalker":"A fast ambusher that marks a lunge before committing.",
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
const ENEMY_ORDER := ["normal","speedy","toxic","armored","spitter","skirmisher","bombardier","healer","guard","ranger","charger","grenadier","splitter","wisp","bulwark","stalker"]
const ENEMY_STATS := {
    "normal":[44.0,82.0,12.0],"speedy":[30.0,132.0,10.0],"toxic":[56.0,75.0,12.0],"armored":[125.0,55.0,18.0],"spitter":[68.0,66.0,9.0],
    "skirmisher":[45.0,148.0,10.0],"bombardier":[95.0,65.0,14.0],"healer":[62.0,72.0,8.0],"guard":[125.0,58.0,17.0],"ranger":[62.0,65.0,10.0],
    "charger":[62.0,94.0,15.0],"grenadier":[70.0,64.0,13.0],"splitter":[73.0,77.0,13.0],
    "wisp":[53.0,108.0,10.0],"bulwark":[152.0,51.0,17.0],"stalker":[75.0,118.0,15.0],
    "king":[620.0,84.0,22.0],"toxicboss":[560.0,74.0,20.0],"frostboss":[520.0,78.0,20.0],"council":[370.0,88.0,16.0],
    "burrower":[650.0,83.0,26.0],"stormboss":[690.0,86.0,22.0],"weaver":[750.0,78.0,22.0],"nutpocalypse":[1250.0,62.0,30.0]
}

var admin_mode: bool = false
var admin_authenticated: bool = false
var admin_return_page: String = "title"
var admin_password_field: LineEdit
var admin_command_field: LineEdit
var admin_messages: Array[String] = []
var reset_confirmation_deadline := 0
var quit_dialog: ConfirmationDialog
var pending_exit_action: String = "quit"
var rng := RandomNumberGenerator.new()
var world
const MobileTouch = preload("res://scripts/TouchControls.gd")
var ui_layer: CanvasLayer
var touch_controls: MobileTouch
var ui_root: Control
var menu_backdrop: TextureRect
var hud_status_box: PanelContainer
var page: String = "title"
var mode: String = "solo"  # solo, host, guest
var local_id: int = 1
var dedicated_server := false
var server_is_dedicated := false
var guest_input_seconds := 0.0
var guest_loadouts: Dictionary = {}
var join_timeout: Timer
const ONLINE_PORT := 27845
const FERN_CREEK := "fern-creek"
const LANTERN_HOLLOW := "lantern-hollow"
var camera_pos: Vector2 = Vector2(27,27)
var guest_motion := GuestMotion.new()
var last_snapshot_stamp := -1.0
var last_packet_at := 0
var guest_local_position := Vector2.ZERO
var guest_local_ready := false
var next_blob_id := 1
var guest_visual_run_id := -1
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
const MAX_ENEMY_BLOBS: int = 128
var enemy_blobs: Array[Dictionary] = []
var player_inputs: Dictionary = {}
var next_enemy_id: int = 1
var wave: int = 0  # Chapter number on the wire and in existing enemy formulas.
var selected_chapter: int = 1
var mission_phase := "travel"
var mission_checkpoint := false
var field_chests: Array[Dictionary] = []
var field_upgrade_drops: Array[Dictionary] = []
var checkpoint_chests: Array[Dictionary] = []
var checkpoint_upgrade_drops: Array[Dictionary] = []
var checkpoint_ground_acorns: Array[Dictionary] = []
var checkpoint_chest_perks: Dictionary = {}
var upgrade_catalog: Dictionary = {}
var displayed_upgrade_keys: Array[String] = []
var flag_carrier := -1
var flag_pos := Vector2.ZERO
var flag_delivered := false
var quota_goal := 0
var wave_kills := 0
var capture_blocked := false
var encounter_wave := 0
var wave_break := -1.0
var objective_pos := Vector2.ZERO
var objective_goal := Vector2.ZERO
var objective_arrived := false
var marked_remaining := 0
var marked_to_spawn := 0
var salvage_needed := 0
var salvage_collected := 0
var salvage_to_spawn := 0
var field_salvage: Array[Vector2] = []
var replay_rotation := 0
var veteran_operation := false
var warning_zones: Array[Dictionary] = []
var warning_impacts: Array[Dictionary] = []
var weather_timer := 0.0
var weather_index := 0
var guard_remaining := 0.0
var encounter_queue: Array[String] = []
var checkpoint_xp := 0.0
var checkpoint_kills := 0
var checkpoint_acorns := 0
var squad_mission_acorns := 0
var observed_clear := -1
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
var xp_vacuum: bool = false
var hud_xp_meter: StinkyHudMeter
var hud_xp_label: Label
var hud_xp_box: PanelContainer
var day_phase: float = 0.25
var weather: String = "clear"
var snapshot_timer: float = 0.0
var pending_fx: Array[Array] = []
var novelty_timer: float = 0.0
var boss_name: String = ""
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
var main_scroll: ScrollContainer
var settings_scroll: ScrollContainer
var enemy_level_scale := 1.0
var prestige_confirm: ConfirmationDialog
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
var mission_label: Label
var import_dialog: FileDialog
var profile_import_dialog: FileDialog
var profile_export_dialog: FileDialog
var profile_confirm: ConfirmationDialog
var profile_status_label: Label
var profile_transfer_status := ""
var pending_profile: Dictionary = {}
var web_file_input: JavaScriptObject
var web_picker_change: JavaScriptObject
var web_picker_cancel: JavaScriptObject
var web_file_reader: JavaScriptObject
var web_reader_load: JavaScriptObject
var web_reader_error: JavaScriptObject
var web_profile_store: JavaScriptObject
var badge: Label
var music: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var sfx: Dictionary = {}

func _ready() -> void:
    rng.randomize()
    upgrade_catalog = _upgrade_catalog()
    Engine.max_fps = 120
    RenderingServer.set_default_clear_color(Color("172f38"))
    set_process_input(true)
    # Keep OS close/Alt-F4 from bypassing the quit confirmation.
    get_tree().auto_accept_quit = false
    _load_progress()
    _retain_legacy_licenses()
    _normalize_loadout_profile()
    _migrate_unlock_rules()
    world = preload("res://scripts/World.gd").new()
    world.game = self
    add_child(world)
    _make_gpu_fx()
    _make_ui()
    if not OS.get_cmdline_user_args().has("--serve"):
        _make_touch_controls()
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
    if OS.get_cmdline_user_args().has("--serve"):
        _start_dedicated_server()

func _make_audio() -> void:
    music = AudioStreamPlayer.new()
    add_child(music)
    music.stream = load("res://audio/forest_loop.wav")
    music.volume_db = -22
    music.finished.connect(func(): music.play())
    boss_music = AudioStreamPlayer.new()
    add_child(boss_music)
    boss_music.stream = load("res://audio/woodland_boss_assault.wav")
    boss_music.volume_db = -9
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

func _save_file() -> String:
    if not OS.get_cmdline_user_args().has("--serve"):
        return SAVE_FILE
    if _host_room() == LANTERN_HOLLOW:
        return HOST_SAVE_FILE.get_basename() + "_lantern_hollow.json"
    return HOST_SAVE_FILE

func _get_web_profile_store() -> JavaScriptObject:
    if not OS.has_feature("web"):
        return null
    if web_profile_store == null:
        JavaScriptBridge.eval("""
            window.woodlandProfileStore = {
                read: function(key) {
                    try { return localStorage.getItem(key); } catch (_) { return null; }
                },
                write: function(key, value) {
                    try { localStorage.setItem(key, value); return true; } catch (_) { return false; }
                }
            };
        """, true)
        web_profile_store = JavaScriptBridge.get_interface("woodlandProfileStore")
    return web_profile_store

func _flush_progress() -> void:
    if not save_dirty:
        return
    var raw := JSON.stringify({"progress": progress, "settings": settings, "admin_mode": admin_mode})
    var written := false
    var file := FileAccess.open(_save_file(), FileAccess.WRITE)
    if file != null:
        file.store_string(raw)
        file.flush()
        written = file.get_error() == OK
        file.close()
    var browser := _get_web_profile_store()
    if browser != null:
        written = bool(browser.write(WEB_PROFILE_KEY, raw)) or written
    if written:
        save_dirty = false
        save_seconds = 0.0

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Avoid double prompts if the user clicks the window X more than once.
        if quit_dialog != null and not quit_dialog.visible:
            _request_exit("quit")
    elif what == NOTIFICATION_PREDELETE:
        _flush_progress()

func _load_progress() -> void:
    for effect in GRAPHICS_EFFECTS:
        var key: String = str(effect.id)
        settings[key] = key == "fx_contact_shadows"
        settings[key + "_strength"] = FX_STRENGTH_DEFAULT
    progress = _new_profile()
    _read_saved_profile()

func _new_profile() -> Dictionary:
    var fresh := {"kills":0,"best_wave":0,"campaign_clears":0,"field_xp":0,"prestige":0,"boss_kills":0,"acorns":0,"weapon_kills":{},"discovered":{},"weapon":"shotgun","character":"scout","gun_skins":{}}
    for w in WEAPON_ORDER:
        fresh.weapon_kills[w] = 0
        fresh.gun_skins[w] = SKIN_OPTIONS[w][0]
    return fresh

func _read_saved_profile() -> void:
    var saved: Variant = null
    var browser := _get_web_profile_store()
    if browser != null:
        var mirror: Variant = browser.read(WEB_PROFILE_KEY)
        if mirror is String:
            saved = JSON.parse_string(mirror)
    if not (saved is Dictionary and saved.get("progress") is Dictionary) and FileAccess.file_exists(_save_file()):
        var file := FileAccess.open(_save_file(), FileAccess.READ)
        if file != null:
            saved = JSON.parse_string(file.get_as_text())
    if not (saved is Dictionary and saved.get("progress") is Dictionary):
        return
    admin_mode = bool(saved.get("admin_mode", false))
    progress.merge(saved.progress, true)
    if saved.get("settings") is Dictionary:
        settings.merge(saved.settings, true)

func _create_obstacles() -> void:
    obstacles.clear()
    obstacle_cells.clear()
    for x in range(192):
        for y in range(192):
            var h: int = ((x*73856093) ^ (y*19349663) ^ 92821) & 0x7fffffff
            var kind := ""
            if h % 67 == 7:kind = "tree"
            elif h % 89 == 11:kind = "rock"
            elif h % 101 == 9:kind = "stump"
            var point := Vector2(x + .5, y + .5)
            if kind != "" and Vector2(x, y).distance_squared_to(Vector2(27, 27)) >= 81.0 and not _near_operation_site(point):
                var prop := {"pos":Vector2(x+.5,y+.5),"kind":kind,"radius":.95 if kind=="tree" else (.75 if kind=="rock" else .55)}
                obstacles.append(prop)
                var bucket := Vector2i(int(x/8),int(y/8))
                if not obstacle_cells.has(bucket):obstacle_cells[bucket]=[]
                obstacle_cells[bucket].append(prop)

func _near_operation_site(point: Vector2) -> bool:
    for chapter in Campaign.MISSIONS:
        if point.distance_squared_to(chapter.site) < 10.0 or point.distance_squared_to(chapter.start) < 4.0:
            return true
        for offset in Campaign.FIELD_OFFSETS:
            if point.distance_squared_to(chapter.site + offset) < 3.5:
                return true
    return false

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
    var health := 100.0
    # ENet peer identifiers may be very large random integers; they are not spawn slots.
    var spawn_slot: int = maxi(1,players.size()+1)
    var m := {"pos":Vector2(27.0+spawn_slot*.38,27.0+spawn_slot*.26),"hp":health,"max_hp":health,"weapon":gun_id,"skin":str(progress.gun_skins.get(gun_id,SKIN_OPTIONS[gun_id][0])),"character":char_id,
      "ammo":w.ammo,"mag":w.ammo,"damage":w.damage*(1.12 if char_id=="sharpsight" else 1.0),"cooldown":w.cooldown,"reload_time":w.reload,"range":w.range,"pellets":w.pellets,"spread":w.spread,
      "speed":185.0*(1.14 if char_id=="trailblazer" else 1.0),"timer":0.0,"reload":0.0,"dash_cd":0.0,"flash":0.0,"invincible":0.0,"aim":Vector2.RIGHT,"moving":false,"walk":0.0,
      "kills":0,"fire":1 if char_id=="cindercloak" else 0,"ice":1 if char_id=="frostbound" else 0,"chain":0,"pierce":0,"double":0,"shatter":0,"magnet":0,"lucky":0,"shots_fired":0,"dash_recharge":2.6,"resist":0.0,"lifesteal":0.0,"nova":0,"singularity":0,"zero":0,"satellites":0,"overkill":0,"ultimate_timer":0.0,"name":"PLAYER %d" % id}
    m.level = _career_level() if id == local_id else 1
    _apply_prestige_outfit(m)
    return m

func _career_level() -> int:
    return RangerProgress.level(int(progress.get("field_xp", 0)))

func _prestige_rank() -> int:
    return clampi(int(progress.get("prestige", 0)), 0, RangerProgress.MAX_PRESTIGE)

func _outfit_catalog() -> Dictionary:
    return CHARACTER_SKINS.merged(RangerProgress.OUTFITS)

func _apply_prestige_outfit(ranger: Dictionary) -> void:
    if not RangerProgress.OUTFITS.has(ranger.character):
        if ranger.character == "ironbark":
            ranger.max_hp = 135.0
            ranger.hp = ranger.max_hp
        return
    var outfit: Dictionary = RangerProgress.OUTFITS[ranger.character]
    ranger.damage *= outfit.damage
    ranger.max_hp = outfit.health
    ranger.hp = ranger.max_hp
    ranger.speed *= outfit.speed
    if ranger.character == "voidwarden":
        ranger.fire = 1
        ranger.ice = 1

func _unlocked_weapon(w: String, previous_rules: bool = false) -> bool:
    if not WEAPON_ORDER.has(w):
        return false
    if admin_mode or progress.get("earned_weapons", {}).get(w, false):
        return true
    var index := WEAPON_LICENSE_ORDER.find(w)
    var xp: int = PREVIOUS_WEAPON_XP[index] if previous_rules else WEAPON_TRAINING_XP[index]
    var chapter := _weapon_clear_requirement(w, previous_rules)
    if int(progress.get("campaign_clears", 0)) < chapter or int(progress.get("field_xp", 0)) < xp:
        return false
    return previous_rules or int(progress.get("late_veteran_clears", 0)) >= _weapon_veteran_requirement(w)

const PREVIOUS_WEAPON_XP := [0, 0, 550, 1250, 1650, 2250, 2850, 3700, 4950, 6100, 7100]
const WEAPON_TRAINING_XP := [0, 380, 1150, 2200, 3350, 4750, 6100, 7950, 9100, 11200, 13500]
const OUTFIT_CHAPTERS := {"scout":0, "trailblazer":2, "sharpsight":4, "ironbark":5, "cindercloak":6, "frostbound":8}

func _weapon_clear_requirement(w: String, previous_rules: bool = false) -> int:
    var stages := [0, 2, 2, 3, 4, 5, 5, 7, 7, 8, 8] if previous_rules else [0, 2, 3, 4, 4, 5, 6, 7, 7, 8, 8]
    return stages[WEAPON_LICENSE_ORDER.find(w)]

func _weapon_veteran_requirement(w: String) -> int:
    return int({"railgun":1,"mistral":2}.get(w, 0))

func _migrate_unlock_rules() -> void:
    if int(progress.get("unlock_rules_version", 1)) >= 2:
        return
    var override := admin_mode
    admin_mode = false
    var weapons: Dictionary = progress.get("earned_weapons", {})
    var skins: Dictionary = progress.get("earned_skins", {})
    var outfits: Dictionary = progress.get("earned_outfits", {})
    for weapon in WEAPON_ORDER:
        if _unlocked_weapon(weapon, true):
            weapons[weapon] = true
        for index in range(1, SKIN_OPTIONS[weapon].size()):
            if _unlocked_gun_skin(weapon, index, true):
                skins["%s:%d" % [weapon, index]] = true
    for outfit in CHARACTER_SKINS:
        if _unlocked_character(outfit, true):
            outfits[outfit] = true
    progress.earned_weapons = weapons
    progress.earned_skins = skins
    progress.earned_outfits = outfits
    progress.unlock_rules_version = 2
    admin_mode = override
    _save_progress()

func _retain_legacy_licenses() -> void:
    if progress.has("earned_weapons"):
        return
    var earned: Dictionary = {}
    var legacy_chapters := [0, 1, 2, 3, 4, 6]
    for index in range(ORIGINAL_WEAPONS.size()):
        var weapon: String = ORIGINAL_WEAPONS[index]
        if int(progress.get("campaign_clears", 0)) >= legacy_chapters[index] or int(progress.get("kills", 0)) >= WEAPONS[weapon].unlock:
            earned[weapon] = true
    progress.earned_weapons = earned
    var old_skins: Dictionary = {}
    if not admin_mode:
        for weapon in WEAPON_ORDER:
            for index in range(1, SKIN_OPTIONS[weapon].size()):
                if _unlocked_gun_skin(weapon, index):
                    old_skins["%s:%d" % [weapon, index]] = true
    progress.earned_skins = old_skins
    _save_progress()

func _normalize_loadout_profile() -> void:
    var kills: Dictionary = progress.get("weapon_kills", {})
    var skins: Dictionary = progress.get("gun_skins", {})
    for weapon in WEAPON_ORDER:
        if not kills.has(weapon):
            kills[weapon] = 0
        if not SKIN_OPTIONS[weapon].has(skins.get(weapon, "")):
            skins[weapon] = SKIN_OPTIONS[weapon][0]
    progress.weapon_kills = kills
    progress.gun_skins = skins
    var equipped := str(progress.get("weapon", ""))
    var replacement := str(RETIRED_WEAPONS.get(equipped, "shotgun"))
    if not WEAPON_ORDER.has(equipped):
        progress.weapon = replacement if _unlocked_weapon(replacement) else "shotgun"
    var outfit := str(progress.get("character", ""))
    if not CHARACTER_SKINS.has(outfit) and not _unlocked_character(outfit):
        progress.character = "scout"

func _unlocked_character(id: String, previous_rules: bool = false) -> bool:
    if RangerProgress.OUTFITS.has(id):
        return admin_mode or _prestige_rank() >= int(RangerProgress.OUTFITS[id].value)
    if not CHARACTER_SKINS.has(id):return false
    if admin_mode or progress.get("earned_outfits", {}).get(id, false):return true
    if not previous_rules and int(progress.get("campaign_clears", 0)) < int(OUTFIT_CHAPTERS[id]):return false
    var c: Dictionary = CHARACTER_SKINS[id]
    match c.kind:
        "starter":return true
        "kills":return progress.kills>=c.value
        "wave":return int(progress.get("campaign_clears", 0)) >= 2 or progress.best_wave>=c.value
        "bosses":return progress.boss_kills>=c.value
        "special":return int(progress.get("campaign_clears", 0)) >= 7 or (progress.best_wave>=20 and progress.boss_kills>=8)
    return false

func _unlocked_gun_skin(weapon_id: String, skin_index: int, previous_rules: bool = false) -> bool:
    if not GUN_SKIN_REQUIREMENTS.has(weapon_id):return false
    if skin_index < 0 or skin_index >= SKIN_OPTIONS[weapon_id].size():return false
    if admin_mode:return true
    # Preserve cosmetics already equipped in an existing native save.
    var equipped_skins: Dictionary = progress.get("gun_skins",{})
    if str(equipped_skins.get(weapon_id,"")) == str(SKIN_OPTIONS[weapon_id][skin_index]):return true
    if not _unlocked_weapon(weapon_id, previous_rules):return false
    var credit := "%s:%d" % [weapon_id, skin_index]
    if progress.get("earned_skins", {}).get(credit, false):
        return true
    if progress.has("earned_skins") and skin_index > 0 and int(progress.get("campaign_clears", 0)) < _premium_chapter(skin_index, previous_rules):
        return false
    var rule: Array = GUN_SKIN_REQUIREMENTS[weapon_id][skin_index]
    var target := _skin_challenge_value(rule, previous_rules)
    match str(rule[0]):
        "starter", "railgun":return true
        "total_kills":return int(progress.get("kills",0)) >= target
        "best_wave":return int(progress.get("campaign_clears",0)) >= _skin_clear_requirement(target) or int(progress.get("best_wave",0)) >= target
        "boss_kills":return int(progress.get("boss_kills",0)) >= target
        "weapon_kills":return int(progress.get("weapon_kills",{}).get(weapon_id,0)) >= target
    return false

func _premium_chapter(skin_index: int, previous_rules: bool = false) -> int:
    return ([0, 3, 5, 8] if previous_rules else [0, 4, 6, 8])[skin_index]

func _skin_challenge_value(rule: Array, previous_rules: bool = false) -> int:
    var amount := int(rule[1])
    if not previous_rules and str(rule[0]) in ["total_kills", "boss_kills", "weapon_kills"]:
        amount = ceili(float(amount) * 1.35)
    return amount

func _gun_skin_requirement_text(weapon_id: String, skin_index: int) -> String:
    if skin_index > 0 and int(progress.get("campaign_clears", 0)) < _premium_chapter(skin_index):
        return "Clear chapter %d, then complete the cosmetic challenge" % _premium_chapter(skin_index)
    var rule: Array = GUN_SKIN_REQUIREMENTS[weapon_id][skin_index]
    var target := _skin_challenge_value(rule)
    match str(rule[0]):
        "starter":return "Starter cosmetic"
        "railgun":return "Unlocked with the Railgun"
        "total_kills":return "%d total kills" % target
        "best_wave":return "Complete chapter %d" % _skin_clear_requirement(int(rule[1]))
        "boss_kills":return "Defeat %d bosses" % target
        "weapon_kills":return "%d kills using this weapon" % target
    return "Cosmetic mission"

func _skin_clear_requirement(former_wave: int) -> int:
    return clampi(ceili(float(former_wave) / 6.0), 1, Campaign.MISSIONS.size())

func _mission() -> Dictionary:
    return Campaign.MISSIONS[clampi(wave - 1, 0, Campaign.MISSIONS.size() - 1)]

func _make_campaign_player(id: int, apply_training: bool = true) -> Dictionary:
    var ranger := _make_player(id)
    var deployment: Vector2 = _mission().site if mission_checkpoint else _mission().start
    ranger.pos = deployment + Vector2(
        float(players.size() % 3) * .45, float(players.size() / 3) * .35)
    ranger.invincible = 2.0
    ranger.revive_time = 0.0
    ranger.feast = 0.0
    if apply_training:
        _train_player(ranger)
    return ranger

func _training_options(weapon: String) -> Array[Dictionary]:
    var clearance: int = maxi(wave - 1, int(progress.get("campaign_clears", 0))) if mode == "solo" else wave - 1
    var options: Array[Dictionary] = Campaign.training_for_clears(clearance, WEAPON_UPGRADE_FAMILY.get(weapon, weapon))
    for option in options:
        var key: String = option.id
        option.description = str(GENERAL_UPGRADES.get(key, UNIQUE_UPGRADES[WEAPON_UPGRADE_FAMILY.get(weapon, weapon)].get(key, LEGENDARY_UPGRADES.get(key, ""))))
    return options

func _train_player(ranger: Dictionary) -> void:
    for option in _training_options(str(ranger.weapon)):
        _apply_training(ranger, option)

func _start_run(chapter: int = 0, from_checkpoint: bool = false) -> void:
    if mode == "guest":
        return
    run_id += 1
    wave = clampi(chapter if chapter > 0 else selected_chapter, 1, Campaign.MISSIONS.size())
    if not from_checkpoint:
        checkpoint_xp = 0.0
        checkpoint_kills = 0
        checkpoint_acorns = 0
        checkpoint_chest_perks.clear()
        checkpoint_chests.clear()
        checkpoint_upgrade_drops.clear()
        checkpoint_ground_acorns.clear()
    field_chests.clear()
    field_upgrade_drops.clear()
    enemies.clear()
    enemy_blobs.clear()
    hazards.clear()
    drops.clear()
    xp_drops.clear()
    particles.clear()
    traces.clear()
    pending_fx.clear()
    upgrades_taken.clear()
    encounter_queue.clear()
    player_inputs.clear()
    to_spawn = 0
    spawn_timer = 0.0
    run_xp = checkpoint_xp
    stage_kills = checkpoint_kills
    run_acorns = checkpoint_acorns
    squad_mission_acorns = checkpoint_acorns
    run_level = _career_level()
    xp_to_next = 250.0
    xp_vacuum = false
    next_enemy_id = 1
    next_blob_id = 1
    elapsed = 0.0
    day_phase = .52
    weather = _mission().weather
    novelty_timer = 0.0
    mission_phase = "travel"
    flag_carrier = -1
    flag_delivered = false
    encounter_wave = Campaign.APPROACH_WAVES[wave - 1] if from_checkpoint else 0
    wave_break = -1.0
    field_salvage.clear()
    warning_zones.clear()
    warning_impacts.clear()
    weather_timer = 0.0
    weather_index = ["clear", "wind", "rain", "mist", "snow"].find(weather)
    replay_rotation = int(progress.get("chapter_completions", {}).get(str(wave), 0)) % 24
    veteran_operation = bool(settings.get("veteran", false)) if not dedicated_server else int(progress.get("campaign_clears", 0)) >= Campaign.MISSIONS.size()
    mission_checkpoint = from_checkpoint
    guard_remaining = float(_mission().guard_seconds)
    boss_name = ""
    players.clear()
    if not dedicated_server:
        players[1] = _make_campaign_player(1)
    if mode == "host":
        for id in multiplayer.get_peers():
            players[id] = _make_online_guest(id)

    enemy_level_scale = 1.0
    _update_enemy_level_scale()
    if from_checkpoint:
        field_chests.assign(checkpoint_chests.duplicate(true))
        field_upgrade_drops.assign(checkpoint_upgrade_drops.duplicate(true))
        drops.assign(checkpoint_ground_acorns.duplicate(true))
        for id in players:
            for perk in checkpoint_chest_perks.get(id, []):
                _grant_chest_upgrade(players[id], perk)
    else:
        _scatter_chests()
    if players.has(1):
        upgrades_taken.assign(_training_options(str(players[1].weapon)).slice(-8))
        camera_pos = players[1].pos
    toast_message = "%02d  %s" % [wave, _mission().title]
    toast_timer = 3.0
    _show_page("playing")
    if boss_music.playing:
        boss_music.stop()
    if not dedicated_server and settings.get("music", true) and not music.playing:
        music.play()
    if from_checkpoint:
        _begin_boss()

func _upgrade_catalog() -> Dictionary:
    var catalog := GENERAL_UPGRADES.duplicate()
    for group in UNIQUE_UPGRADES.values():
        catalog.merge(group, true)
    catalog.merge(LEGENDARY_UPGRADES, true)
    return catalog

func _scatter_chests() -> void:
    field_chests.clear()
    var layout := RandomNumberGenerator.new()
    layout.seed = rng.randi()
    var chapter := _mission()
    var anchors: Array[Vector2] = [chapter.start, chapter.site]
    for offset in Campaign.FIELD_OFFSETS:
        anchors.append(_wrap_vec(chapter.site + offset))
    for index in range(layout.randi_range(4, 6)):
        var found := false
        var pos := Vector2.ZERO
        for attempt in range(28):
            var anchor: Vector2 = anchors[index % anchors.size()]
            var radius := layout.randf_range(230.0, 460.0) if index < 2 else layout.randf_range(485.0, 1000.0)
            pos = _wrap_vec(anchor + _uniso(Vector2.from_angle(layout.randf_range(0, TAU)) * radius))
            if not _can_occupy(pos, .8):
                continue
            var separated := true
            for existing in field_chests:
                if _screen_distance(existing.pos, pos) < 270.0:
                    separated = false
                    break
            if separated:
                found = true
                break
        if found:
            var rarity := clampi(layout.rand_weighted(PackedFloat32Array(RARITY_WEIGHTS)), 0, 4)
            field_chests.append({"pos": pos, "rarity": rarity})

func _nearest_chest(pos: Vector2) -> int:
    var best := CHEST_REACH
    var result := -1
    for index in range(field_chests.size()):
        var distance := _screen_distance(pos, field_chests[index].pos)
        if distance <= best:
            best = distance
            result = index
    return result

@rpc("any_peer", "call_remote", "reliable")
func request_open_chest(operation_id: int) -> void:
    if mode == "host" and operation_id == run_id:
        _open_nearby_chest(multiplayer.get_remote_sender_id())

func _open_nearby_chest(id: int) -> void:
    if page != "playing" or mode == "guest" or not players.has(id):
        return
    var ranger: Dictionary = players[id]
    if ranger.hp <= 0.0:
        return
    var now := Time.get_ticks_msec()
    if now < int(ranger.get("next_chest_input", 0)):
        return
    ranger.next_chest_input = now + 240
    var index := _nearest_chest(ranger.pos)
    if index < 0:
        return
    var chest: Dictionary = field_chests[index]
    field_chests.remove_at(index)
    _drop_chest_loot(chest, rng.randf())
    _notify_loot(id, "CHEST OPENED")

func _drop_chest_loot(chest: Dictionary, roll: float) -> void:
    var rarity: int = chest.rarity
    var origin: Vector2 = chest.pos
    if roll < .53:
        var id: String = str(upgrade_catalog.keys().pick_random())
        field_upgrade_drops.append({
            "pos": origin, "rarity": rarity, "id": id, "age": 0.0
        })
    elif roll < .78:
        for index in range(3 + rarity * 2):
            _create_drop(_chest_spill(origin, index))
    else:
        for index in range(3 + rarity):
            xp_drops.append({"pos": _chest_spill(origin, index),
                "value": float(17 + rarity * 13), "age": 0.0, "fly": false})
    _burst(world.screen_point(origin, camera_pos), Color(RARITY_COLORS[rarity]), 13)

func _chest_spill(origin: Vector2, index: int) -> Vector2:
    var angle := float(index) * 2.399963
    var offset := Vector2.from_angle(angle) * (28.0 + float(index % 3) * 13.0)
    return _move_to(origin, _uniso(offset), .15)

func _update_upgrade_drops(dt: float) -> void:
    for index in range(field_upgrade_drops.size() - 1, -1, -1):
        var drop: Dictionary = field_upgrade_drops[index]
        drop.age += dt
        if drop.age < .38:
            continue
        var id := _nearest_alive_player(drop.pos)
        if id < 0 or _screen_distance(players[id].pos, drop.pos) > 32.0:
            continue
        _grant_chest_upgrade(players[id], drop)
        field_upgrade_drops.remove_at(index)
        _notify_loot(id, "%s  %s" % [str(RARITY_NAMES[drop.rarity]).to_upper(), str(drop.id).replace("_", " ")])

func _grant_chest_upgrade(ranger: Dictionary, drop: Dictionary) -> void:
    var option := {"id": drop.id, "rarity": drop.rarity}
    _apply_training(ranger, option)
    if not ranger.has("chest_upgrades"):
        ranger.chest_upgrades = []
    ranger.chest_upgrades.append(option)

func _notify_loot(id: int, label: String) -> void:
    if id == local_id:
        loot_message(label)
    elif mode == "host":
        rpc_id(id, "loot_message", label)

@rpc("authority", "call_remote", "reliable")
func loot_message(label: String) -> void:
    toast_message = label
    toast_timer = 2.6
    _sound("upgrade")

func _field_site() -> Vector2:
    if mission_phase == "guard":
        return objective_pos
    return _mission().site

func _field_objective() -> String:
    var plan: Array = FieldPatterns.WAVE_OBJECTIVES[clampi(wave - 1, 0, 7)]
    return plan[clampi(encounter_wave - 1, 0, plan.size() - 1)]

func _objective_endpoint(index: int) -> Vector2:
    if _field_objective() in ["escort", "relay", "sabotage", "rotation", "flag", "capture"]:
        return _wrap_vec(_mission().site + Campaign.FIELD_OFFSETS[index])
    return _mission().site

func _begin_guard() -> void:
    var chapter := _mission()
    mission_phase = "guard"
    encounter_wave += 1
    var objective := _field_objective()
    var index := encounter_wave - 1
    objective_goal = _objective_endpoint(index)
    objective_pos = _objective_endpoint(maxi(0, index - 1)) if objective == "escort" else objective_goal
    flag_carrier = -1
    flag_delivered = false
    flag_pos = objective_pos
    if objective == "flag":
        objective_goal = _wrap_vec(chapter.site + Campaign.FIELD_OFFSETS[(index + 2) % Campaign.FIELD_OFFSETS.size()])
    capture_blocked = false
    wave_kills = 0
    guard_remaining = (float(chapter.guard_seconds) * .65 + index * 2.0) if objective in ["hold", "rotation", "survive", "sabotage", "capture"] else 0.0
    if objective == "survive":
        guard_remaining += 16.0
    elif objective == "capture":
        guard_remaining = 5.0 + float(index)
    objective_arrived = false
    salvage_collected = 0
    salvage_needed = 2 + index if objective == "salvage" else 0
    field_salvage.clear()
    encounter_queue.clear()
    var roster: Array = chapter.roster
    var count := 7 + index * 3 + int(wave / 2.0) + maxi(0, players.size() - 1) * 2
    if veteran_operation:
        count += 4
    var debut: Array = FieldPatterns.DEBUTS[wave - 1]
    var returning := FieldPatterns.previous_debuts(wave)
    quota_goal = maxi(5, int(count * .77)) if objective == "quota" else 0
    for slot in range(count):
        var kind: String = roster[(slot + index + replay_rotation) % roster.size()]
        if slot < 2 or slot % 6 == 4:
            kind = debut[slot % 2]
        elif slot % 6 == 3 and not returning.is_empty():
            kind = returning[(slot + replay_rotation + index * 3) % returning.size()]
        elif slot % 3 == 2:
            kind = Campaign.ADDITIONAL_ENEMIES[(slot + wave + index + replay_rotation) % Campaign.ADDITIONAL_ENEMIES.size()]
        elif slot % 4 == 1 and players.size() > 1:
            kind = chapter.reinforcements[slot % chapter.reinforcements.size()]
        encounter_queue.append(kind)
    marked_remaining = 2 + int(index / 2.0) if objective == "hunt" else 0
    for slot in range(marked_remaining):
        encounter_queue[mini(2 + slot * 3, encounter_queue.size() - 1)] = "stalker"
    marked_to_spawn = marked_remaining
    salvage_to_spawn = salvage_needed
    to_spawn = encounter_queue.size()
    spawn_timer = 1.0
    wave_break = -1.0
    xp_vacuum = false
    toast_message = "WAVE %d OF %d" % [encounter_wave, Campaign.APPROACH_WAVES[wave - 1]]
    toast_timer = 2.0
    if encounter_wave == 1:
        toast_message = "NEW: %s / %s" % [FieldPatterns.ROSTER[debut[0]][0], FieldPatterns.ROSTER[debut[1]][0]]
        toast_timer = 4.0

func _ranger_at(site: Vector2, radius: float = SITE_RADIUS) -> bool:
    for ranger in players.values():
        if ranger.hp > 0.0 and _screen_distance(ranger.pos, site) <= radius:
            return true
    return false

func _update_field_objective(dt: float) -> bool:
    var type := _field_objective()
    var near_site := _ranger_at(objective_pos)
    match type:
        "hold", "sabotage", "rotation", "survive":
            if near_site or type == "survive":
                guard_remaining = maxf(0.0, guard_remaining - dt)
            return guard_remaining <= 0.0
        "capture":
            capture_blocked = false
            for enemy in enemies:
                if enemy.hp > 0.0 and _screen_distance(enemy.pos, objective_pos) < 77.0:
                    capture_blocked = true
                    break
            if near_site and not capture_blocked:
                guard_remaining = maxf(0.0, guard_remaining - dt)
            return guard_remaining <= 0.0
        "flag":
            return _advance_flag()
        "quota":
            return wave_kills >= quota_goal
        "relay":
            objective_arrived = objective_arrived or near_site
            return objective_arrived
        "escort":
            var route: Vector2 = _screen_delta(objective_goal, objective_pos)
            if near_site:
                objective_pos = _wrap_vec(objective_pos + _uniso(route.limit_length(42.0 * dt)))
            return route.length() < 10.0 and near_site
        "hunt":
            return marked_remaining <= 0
        "salvage":
            for index in range(field_salvage.size() - 1, -1, -1):
                if _ranger_at(field_salvage[index], 42.0):
                    salvage_collected += 1
                    field_salvage.remove_at(index)
            return salvage_collected >= salvage_needed
    return false

func _advance_flag() -> bool:
    if flag_delivered:
        return true
    var carrier: Dictionary = players.get(flag_carrier, {})
    if not carrier.is_empty() and carrier.hp > 0.0:
        flag_pos = carrier.pos
        objective_pos = objective_goal
        flag_delivered = _screen_distance(flag_pos, objective_goal) <= 50.0
        return flag_delivered
    flag_carrier = -1
    objective_pos = flag_pos
    for id in players:
        if players[id].hp > 0.0 and _screen_distance(players[id].pos, flag_pos) <= 40.0:
            flag_carrier = id
            objective_pos = objective_goal
            break
    return false

func _finish_field_wave(dt: float) -> void:
    if wave_break < 0.0:
        wave_break = 3.5
        xp_vacuum = true
        warning_zones.clear()
        enemy_blobs.clear()
        hazards.clear()
        for ranger in players.values():
            if ranger.hp > 0.0:
                ranger.hp = minf(ranger.max_hp, ranger.hp + 14.0)
                ranger.ammo = ranger.mag
                ranger.reload = 0.0
        toast_message = "WAVE CLEARED"
        toast_timer = 2.5
    wave_break -= dt
    if wave_break <= 0.0 and xp_drops.is_empty():
        if encounter_wave < Campaign.APPROACH_WAVES[wave - 1]:
            _begin_guard()
        else:
            _begin_boss()
            xp_vacuum = false


func _begin_boss() -> void:
    var chapter := _mission()
    mission_phase = "boss"
    field_salvage.clear()
    warning_zones.clear()
    warning_impacts.clear()
    if not mission_checkpoint:
        checkpoint_chests.assign(field_chests.duplicate(true))
        checkpoint_upgrade_drops.assign(field_upgrade_drops.duplicate(true))
        checkpoint_ground_acorns.assign(drops.duplicate(true))
        for id in players:
            var perks: Array = players[id].get("chest_upgrades", [])
            checkpoint_chest_perks[id] = perks.duplicate(true)
    mission_checkpoint = true
    checkpoint_xp = run_xp
    checkpoint_kills = stage_kills
    checkpoint_acorns = squad_mission_acorns
    for ranger in players.values():
        ranger.hp = ranger.max_hp
        ranger.ammo = ranger.mag
        ranger.reload = 0.0
        ranger.invincible = 1.6
    boss_name = BOSS_NAMES[BOSS_KINDS.find(chapter.boss)]
    for _boss in range(int(chapter.boss_count)):
        encounter_queue.append(chapter.boss)
    to_spawn = encounter_queue.size()
    spawn_timer = .75
    toast_message = boss_name
    toast_timer = 3.5

func _update_mission(dt: float) -> void:
    match mission_phase:
        "travel":
            if _ranger_at(_mission().site):
                _begin_guard()
        "guard":
            if wave_break >= 0.0:
                _finish_field_wave(dt)
                return
            var objective := _field_objective()
            var done := _update_field_objective(dt)
            if done and objective in ["hunt", "quota", "flag", "capture", "survive"]:
                encounter_queue.clear()
                to_spawn = 0
                enemies.clear()  # Surviving enemies retreat when the squad meets its objective.
            if done and to_spawn == 0 and enemies.is_empty():
                _finish_field_wave(dt)
        "boss":
            if to_spawn == 0 and enemies.is_empty():
                mission_phase = "secure"
                warning_zones.clear()
                enemy_blobs.clear()
                hazards.clear()
                xp_vacuum = true
        "secure":
            if _ranger_at(_mission().site) and xp_drops.is_empty():
                _complete_mission()

func _update_revives(dt: float) -> void:
    for ranger in players.values():
        if ranger.hp > 0.0:
            continue
        var helping := false
        for teammate in players.values():
            if teammate.hp > 0.0 and _screen_distance(ranger.pos, teammate.pos) < 64.0:
                helping = true
                break
        var time: float = float(ranger.get("revive_time", 0.0))
        ranger.revive_time = minf(2.5, time + dt) if helping else maxf(0.0, time - dt)
        if ranger.revive_time >= 2.5:
            ranger.hp = ranger.max_hp * .45
            ranger.invincible = 2.0
            ranger.revive_time = 0.0

func _complete_mission() -> void:
    mission_phase = "complete"
    if boss_music.playing:
        boss_music.stop()
    var reward: int = int(_mission().reward_acorns) + (18 if veteran_operation else 0)
    var field_xp := _mission_reward_xp()
    if mode == "host":
        for id in multiplayer.get_peers():
            if players.has(id):
                if guest_loadouts.has(id):
                    var loadout: Dictionary = guest_loadouts[id]
                    loadout.field_xp = mini(int(loadout.field_xp) + field_xp, RangerProgress.MAX_LEVEL * RangerProgress.XP_PER_LEVEL)
                rpc_id(id, "record_clearance", run_id, wave, field_xp,
                    reward + squad_mission_acorns, int(_mission().boss_count), veteran_operation)
    _bank_clearance(wave, field_xp, reward + squad_mission_acorns, veteran_operation)
    _show_page("mission_complete")

func _mission_reward_xp() -> int:
    return roundi((run_xp + wave * 60.0) * (1.25 if veteran_operation else 1.0))

func _bank_clearance(chapter: int, field_xp: int, reward: int, veteran: bool = false) -> void:
    if veteran and chapter >= 5:
        progress.late_veteran_clears = int(progress.get("late_veteran_clears", 0)) + 1
    progress.campaign_clears = maxi(int(progress.get("campaign_clears", 0)), chapter)
    var completions: Dictionary = progress.get("chapter_completions", {})
    var key := str(chapter)
    completions[key] = int(completions.get(key, 0)) + 1
    progress.chapter_completions = completions
    progress.field_xp = int(progress.get("field_xp", 0)) + field_xp
    progress.acorns = int(progress.get("acorns", 0)) + reward
    _save_progress()
    _flush_progress()

@rpc("authority", "call_remote", "reliable")
func record_clearance(completed_run: int, chapter: int, field_xp: int, reward: int, bosses: int, veteran: bool) -> void:
    if mode != "guest" or completed_run <= observed_clear:
        return
    observed_clear = completed_run
    progress.boss_kills = int(progress.get("boss_kills", 0)) + bosses
    _bank_clearance(chapter, field_xp, reward, veteran)

func _advance_operation() -> void:
    if mode == "guest":
        rpc_id(HOST_ID, "request_operation")
        return
    if page == "defeated":
        _start_run(wave, mission_checkpoint)
    elif page == "mission_complete":
        _start_run(wave + 1 if wave < Campaign.MISSIONS.size() else 1)

@rpc("any_peer", "call_remote", "reliable")
func request_operation() -> void:
    if dedicated_server and mode == "host" and players.has(multiplayer.get_remote_sender_id()):
        _advance_operation()

func _update_enemy_level_scale() -> void:
    var highest := 1
    for ranger in players.values():
        highest = maxi(highest, int(ranger.get("level", 1)))
    var new_scale := RangerProgress.enemy_scale(highest)
    if is_equal_approx(new_scale, enemy_level_scale):
        return
    var ratio := new_scale / enemy_level_scale
    enemy_level_scale = new_scale
    for enemy in enemies:
        enemy.max_hp *= ratio
        enemy.hp *= ratio
        enemy.damage *= ratio

func _spawn_enemy(kind: String, marked: bool = false, core: bool = false, at: Vector2 = Vector2.INF) -> void:
    var anchor := _field_site()
    var angle := rng.randf_range(-PI, PI)
    var radius := 395.0 if BOSS_KINDS.has(kind) else rng.randf_range(285.0, 485.0)
    var origin := _wrap_vec(anchor + _uniso(Vector2(cos(angle), sin(angle)) * radius))
    for _probe in range(6):
        if _can_occupy(origin, .65):
            break
        angle += TAU / 7.0
        origin = _wrap_vec(anchor + _uniso(Vector2(cos(angle), sin(angle)) * radius))
    if at.is_finite():
        origin = at
    var stats: Array
    if FieldPatterns.ROSTER.has(kind):
        stats = FieldPatterns.ROSTER[kind].slice(2, 5)
    else:
        stats = ENEMY_STATS[kind]
    var enemy_level: int = 1 + int((wave - 1) / 2.0)
    var max_hp: float = float(stats[0]) * (1.0 + float(wave - 1) * .08) * enemy_level_scale
    if not BOSS_KINDS.has(kind):
        max_hp *= 1.0 + .13 * maxi(0, encounter_wave - 1)
    if veteran_operation:
        max_hp *= 1.25
    if BOSS_KINDS.has(kind):
        max_hp *= 1.0 + .25 * maxi(0, players.size() - 1)
    if kind == "council":
        max_hp *= .74
    enemies.append({"id":next_enemy_id,"level":enemy_level,"kind":kind,"pos":origin,"hp":max_hp,"max_hp":max_hp,"speed":float(stats[1]) * (1.12 if veteran_operation else 1.0),"damage":float(stats[2]) * (1.15 if veteran_operation else 1.0) * enemy_level_scale,"marked":marked,"core":core,"attack":rng.randf_range(.3,.9),"cool":rng.randf_range(.3,1.5),"special":rng.randf_range(.8,2),"hit":0.0,"bob":rng.randf_range(0,TAU),"burn":0.0,"chill":0.0,"fire_stacks":0.0})
    next_enemy_id += 1
    if not progress.discovered.get(kind, false):
        progress.discovered[kind] = true
        _save_progress()

func _apply_training(p: Dictionary, option: Dictionary) -> void:
    var id: String = option.id
    var q: float = RARITY_SCALES[int(option.rarity)]
    var n: int = maxi(1, roundi(q))
    match id:
        "FOREST_BOOTS":p.speed*=1.0+.12*q
        "BARK_ARMOR":p.max_hp+=24*q;p.hp=minf(p.max_hp,p.hp+24*q)
        "ACORN_FEAST":p.feast += 7.0 * q
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

func _gain_xp(value: float) -> void:
    run_xp += value

func _create_xp_drop(enemy: Dictionary) -> void:
    var enemy_level: int = int(enemy.get("level",1))
    var amount: float = float(XP_VALUE.get(str(enemy.kind), 14 if FieldPatterns.ROSTER.has(enemy.kind) else 10))*(1.0+0.16*float(enemy_level-1))
    xp_drops.append({"pos":enemy.pos,"value":amount,"age":0.0,"fly":false})

func _create_drop(p: Vector2) -> void:
    drops.append({"pos":p,"age":0.0})

func _kill_enemy(e: Dictionary, owner: int=1) -> void:
    if not enemies.has(e):return
    enemies.erase(e)
    if e.get("marked", false):
        marked_remaining -= 1
    if e.get("core", false):
        field_salvage.append(e.pos)
    if e.kind == "splitter" and enemies.size() < 34:
        for offset in [-1.0, 1.0]:
            _spawn_enemy("speedy", false, false, _move_to(e.pos, _uniso(Vector2(23.0 * offset, 10.0)), .4))
    stage_kills += 1
    if mission_phase == "guard":
        wave_kills += 1
    if players.has(owner):
        var shooter:Dictionary=players[owner]
        shooter.kills+=1
        players[owner]=shooter
    if e.kind == "toxic":
        _create_hazard(e.pos, "poison", 37.0, 1.65)
    if owner==1 and players.has(1):
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
    if mode == "host" and n >= 5 and pending_fx.size() < 14 and not multiplayer.get_peers().is_empty():
        var point := _wrap_vec(camera_pos + _uniso(at - CENTER))
        pending_fx.append([point, tint, mini(n, 9)])
    if dedicated_server:
        return
    # Bounded cosmetic effects: avoid large allocation spikes in crowded waves.
    var budget := 480 if settings.get("graphics") == "Cinematic" else 320
    var available := maxi(0, budget - particles.size())
    for i in range(mini(n,available)):
        var angle := rng.randf_range(0,TAU)
        var vel := Vector2.from_angle(angle)*rng.randf_range(40,130)
        particles.append({"pos":at,"focus":camera_pos,"velocity":vel,"age":0.0,"life":rng.randf_range(.2,.5),"tint":tint,"size":rng.randf_range(2,5)})

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
            traces.append({"start":ray_origin,"end":endpoint,"focus":camera_pos,"tint":Color("ffe293"),"width":3.0,"life":0.13})
            if best.is_empty():
                break
            var bonus: float = 1.0 + minf(0.9, float(p.overkill) * float(p.kills) * 0.0009)
            var protection := 1.0
            for guard in enemies:
                if guard.kind == "bulwark" and guard.id != best.id and guard.hp > 0.0 and _screen_distance(guard.pos, best.pos) < 108.0:
                    protection = .72
                    break
            best.hp -= float(p.damage) * bonus * (1.8 if critical_shot else 1.0) * protection
            best.last_attacker = origin_id
            if p.singularity > 0:
                for nearby in enemies:
                    if nearby.id != best.id and _screen_distance(nearby.pos,best.pos) < 65:
                        nearby.hp -= float(p.damage) * 0.24 * float(p.singularity)
                        nearby.last_attacker = origin_id
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
                        other.last_attacker = origin_id
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
    if not players.has(id):
        return
    var ranger: Dictionary = players[id]
    if ranger.dash_cd > 0.0 or ranger.hp <= 0.0:
        return
    ranger.dash_heading = ranger.aim.normalized()
    ranger.dash_left = DASH_DURATION
    ranger.dash_dust = 0.0
    ranger.dash_cd = float(ranger.get("dash_recharge", 2.6))
    ranger.invincible = maxf(float(ranger.invincible), DASH_DURATION + .10)

func _step_dash(ranger: Dictionary, dt: float) -> void:
    var remaining: float = ranger.get("dash_left", 0.0)
    var step := minf(dt, remaining)
    var a := remaining / DASH_DURATION
    var b := (remaining - step) / DASH_DURATION
    var distance := DASH_DISTANCE * (a * a - b * b)
    var heading: Vector2 = ranger.dash_heading
    ranger.pos = _move_to(ranger.pos, _uniso(heading * distance))
    ranger.dash_left = remaining - step
    ranger.moving = true
    ranger.walk += step * 15.0
    ranger.dash_dust -= step
    if ranger.dash_dust <= 0.0:
        ranger.dash_dust = .045
        _burst(world.screen_point(ranger.pos, camera_pos) + Vector2(0, -4), Color("#a8edda"), 5)

func _damage_player(id:int,dmg:float) -> void:
    if not players.has(id):return
    var p:Dictionary=players[id]
    if p.invincible>0 or p.hp<=0:return
    p.hp=maxf(0,p.hp-maxf(1,dmg*(1.0-p.resist*.3)))
    p.invincible=.6
    players[id]=p
    if id==local_id:_sound("hurt")
    if p.hp <= 0.0:
        p.revive_time = 0.0
    if _everyone_down():_end_run()

func _everyone_down()->bool:
    if players.size()==0:return false
    for id in players:
        if players[id].hp>0:return false
    return true

func _end_run()->void:
    _flush_progress()
    if boss_music.playing:
        boss_music.stop()
    _show_page("defeated")

@rpc("authority","call_remote","reliable")
func set_phase(new_phase:String)->void:
    if mode == "guest" and new_phase in ["playing", "defeated", "mission_complete"]:
        _show_page(new_phase)

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
    if do_dash:
        _dash(id)
    if p.hp > 0.0 and float(p.get("dash_left", 0.0)) > 0.0:
        _step_dash(p, dt)
    elif p.moving and p.hp>0:
        p.walk+=dt*3.5
        p.pos=_move_to(p.pos,_uniso(move.limit_length(1.0)*p.speed*dt))
    players[id]=p
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
        if e.hp <= 0.0:
            _kill_enemy(e, int(e.get("last_attacker", 1)))
            continue
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
        var boss: bool = BOSS_KINDS.has(e.kind)
        if _step_enemy_rush(e, dt):
            continue
        e.windup = maxf(0.0, float(e.get("windup", 0.0)) - dt)
        if boss:
            if e.windup > 0.0:
                continue
            var cast_range := 238.0 if e.kind in ["king", "burrower", "council"] else 355.0
            if e.cool <= 0.0 and dist < cast_range:
                _boss_attack(e, target_pos, direction)
                continue
            move *= 0.52
        elif e.kind in ["charger", "stalker", "grenadier", "bombardier"]:
            if e.windup > 0.0:
                continue
            if e.cool <= 0.0 and dist < 210.0:
                e.windup = .72
                e.cool = 3.2
                if e.kind in ["charger", "stalker"]:
                    _warn_attack(e, "line", e.pos, 19.0, .72, direction, 175.0, "charge")
                else:
                    _warn_attack(e, "circle", target_pos, 51.0, .85)
                continue
        elif FieldPatterns.ROSTER.has(e.kind):
            move = _field_enemy_steer(e, direction, dist, target_pos, float(e.speed) * slow, dt)
        elif e.kind == "wisp" and dist < 265.0:
            move = _uniso(direction.orthogonal() * float(e.speed) * dt)
            if e.cool <= 0.0:
                for ray in [-.24, 0.0, .24]:
                    _shoot_enemy(e, direction.rotated(ray), "ice")
                e.cool = 2.6
        if dist > 24.0 and move.length_squared() > 0.0:
            # The desired step remains expressed in isometric screen space.
            # Give ranged enemies the same route-around-obstacle behavior.
            var screen_step: Vector2 = _screen_delta(_wrap_vec(e.pos + move), e.pos)
            if screen_step.length_squared() > 0.0001:
                _move_enemy_around(e,screen_step.normalized(),screen_step.length(),dt)
        if not boss and dist < 27.0 and e.attack <= 0.0:
            _damage_player(target,e.damage)
            e.attack=1.0
    for e in enemies.duplicate():
        if e.hp <= 0.0:
            _kill_enemy(e, int(e.get("last_attacker", 1)))

func _fire_arc(enemy: Dictionary, heading: Vector2, count: int, step: float,
        kind: String = "spark", speed: float = 134.0) -> void:
    for shot in range(count):
        var offset := (float(shot) - float(count - 1) * .5) * step
        _shoot_enemy(enemy, heading.rotated(offset), kind, speed)

func _fire_ring(enemy: Dictionary, phase: float, count: int, speed: float,
        kind: String = "spark") -> void:
    for shot in range(count):
        _shoot_enemy(enemy, Vector2.from_angle(phase + TAU * float(shot) / float(count)), kind, speed)

func _fire_curtain(enemy: Dictionary, heading: Vector2, spacing: float, lanes: Array, speed: float) -> void:
    var origin: Vector2 = enemy.pos
    for lane in lanes:
        var source := {"pos": _wrap_vec(origin + _uniso(heading.orthogonal() * float(lane) * spacing))}
        _shoot_enemy(source, heading, "needle_shot", speed)

func _field_enemy_attack(enemy: Dictionary, target: Vector2, heading: Vector2,
        pattern: String) -> void:
    var step: int = int(enemy.get("volley", 0))
    enemy.volley = step + 1
    match pattern:
        "triplet":
            _fire_arc(enemy, heading, 3, .27, "spark", 122.0)
        "trail":
            _fire_arc(enemy, heading.rotated(.13 if step % 2 == 0 else -.13), 2, .30, "spark", 139.0)
        "fan":
            _fire_arc(enemy, heading, 5, .19, "poison", 133.0)
        "pinwheel":
            _fire_ring(enemy, float(step) * .39, 8, 114.0, "arc")
        "lane":
            enemy.windup = .76
            _warn_attack(enemy, "line", enemy.pos, 15.0, .76, heading, 360.0, "frost_lance")
        "cross":
            _fire_arc(enemy, heading.rotated(-.40), 3, .13, "ice", 147.0)
            _fire_arc(enemy, heading.rotated(.40), 3, .13, "ice", 147.0)
        "sweep":
            _fire_arc(enemy, heading.rotated(float((step % 5) - 2) * .16), 4, .14, "needle_shot", 165.0)
        "gates":
            _fire_curtain(enemy, heading, 20.0, [-2, -1, 1, 2], 159.0)
        "rush":
            enemy.windup = .80
            _fire_ring(enemy, heading.angle() + .39, 6, 107.0, "spark")
            _warn_attack(enemy, "line", enemy.pos, 21.0, .80, heading, 175.0, "charge")
        "pod":
            _warn_attack(enemy, "circle", target, 43.0, .92, heading, 0.0, "spore_ring")
        "channel":
            _fire_curtain(enemy, heading, 23.0, [-3, -2, 2, 3], 175.0)
        "thunder":
            if step % 2 == 0:
                _fire_arc(enemy, heading, 7, .22, "arc", 147.0)
            else:
                _fire_ring(enemy, heading.angle() + .28, 11, 123.0, "arc")
        "snare":
            _warn_attack(enemy, "circle", target, 53.0, .92, heading, 0.0, "snare_ring")
        "curtain":
            var gap := 1 if step % 2 == 0 else -1
            var lanes: Array = []
            for lane in range(-4, 5):
                if abs(lane - gap) > 1:
                    lanes.append(lane)
            _fire_curtain(enemy, heading, 22.0, lanes, 145.0)
        "double_ring":
            _fire_ring(enemy, heading.angle(), 11, 128.0)
            _warn_attack(enemy, "ring", enemy.pos, 61.0, .77, heading.rotated(.28), 0.0, "sentinel_ring")
        "spiral":
            enemy.spiral_steps = 9
            enemy.spiral_timer = 0.0
            enemy.spiral_angle = heading.angle()

func _tick_spiral(enemy: Dictionary, dt: float) -> void:
    var remaining: int = int(enemy.get("spiral_steps", 0))
    if remaining <= 0:
        return
    enemy.spiral_timer -= dt
    if enemy.spiral_timer <= 0.0:
        enemy.spiral_steps = remaining - 1
        enemy.spiral_timer = .12
        enemy.spiral_angle += .38
        for offset in [0.0, PI]:
            _shoot_enemy(enemy, Vector2.from_angle(enemy.spiral_angle + offset), "arc", 149.0)

func _field_enemy_steer(enemy: Dictionary, heading: Vector2, distance: float,
        target: Vector2, speed: float, dt: float) -> Vector2:
    var profile: Array = FieldPatterns.ROSTER[enemy.kind]
    var behavior: String = profile[6]
    _tick_spiral(enemy, dt)
    if enemy.windup > 0.0:
        return Vector2.ZERO
    if enemy.cool <= 0.0 and distance < 320.0:
        enemy.cool = maxf(1.85, 3.48 - float(wave) * .125 - float(encounter_wave) * .11)
        enemy.cool += float(int(enemy.id) % 5) * .16
        _field_enemy_attack(enemy, target, heading, profile[5])
    var side := heading.orthogonal() * (1.0 if int(enemy.id) % 2 == 0 else -1.0)
    var move := heading
    match behavior:
        "kite":
            if distance < 122.0:
                move = -heading * .75
            elif distance < 230.0:
                move = side * .4
        "orbit":
            move = (side + heading * (.6 if distance > 192.0 else -.25)).normalized()
        "strafe":
            move = (heading + side * sin(float(enemy.bob) * .38) * 1.35).normalized()
        "anchor":
            if distance < 214.0:
                move = Vector2.ZERO
    return _uniso(move * speed * dt)

func _step_enemy_rush(e: Dictionary, dt: float) -> bool:
    var remaining: float = e.get("rush_left", 0.0)
    if remaining <= 0.0:
        return false
    var speed := 670.0 if BOSS_KINDS.has(e.kind) else 430.0
    e.pos = _move_to(e.pos, _uniso(e.rush_dir * speed * minf(dt, remaining)), .42)
    e.rush_left = maxf(0.0, remaining - dt)
    for id in players:
        if not e.rush_hit.has(id) and _screen_distance(players[id].pos, e.pos) < (30.0 if BOSS_KINDS.has(e.kind) else 20.0):
            e.rush_hit.append(id)
            _damage_player(id, e.damage)
    return true

func _warn_attack(e: Dictionary, shape: String, center: Vector2, size: float,
        delay: float, direction: Vector2 = Vector2.RIGHT, length_px: float = 0.0,
        payload: String = "impact") -> void:
    if warning_zones.size() >= 68:
        return
    var damage: float = float(e.damage)
    warning_zones.append({
        "owner": e.id, "shape": shape, "pos": center, "dir": direction,
        "size": size, "length": length_px, "time": delay, "duration": delay,
        "damage": damage, "payload": payload
    })

func _boss_attack(e: Dictionary, target_pos: Vector2, dir: Vector2) -> void:
    var enraged: bool = e.hp <= e.max_hp * .47
    var step: int = int(e.get("pattern_step", 0))
    var kind: String = e.kind
    var pattern: String = BossPatterns.action(kind, enraged, step)
    var windup: float = .90 if enraged else 1.18
    if kind == "council":
        windup += float(e.id % 4) * .20
    e.pattern_step = step + 1
    e.cool = windup + (1.5 if enraged else 2.1)
    e.windup = windup
    e.pattern = pattern.capitalize().to_upper()
    if step % 2 == 0:
        _warn_attack(e, "circle", e.pos, 38.0, windup + .25, dir, 0.0, "boss_sweep")
    match pattern:
        "charge", "charge_combo":
            _warn_attack(e, "line", e.pos, 30.0, windup, dir, 268.0, "charge")
            if pattern == "charge_combo":
                var landing := _wrap_vec(e.pos + _uniso(dir * 248.0))
                _warn_attack(e, "circle", landing, 87.0, windup + .66)
        "cleave":
            _warn_attack(e, "circle", _wrap_vec(e.pos + _uniso(dir * 68.0)), 96.0, windup)
            _warn_attack(e, "circle", e.pos, 61.0, windup + .42)
        "lance":
            _warn_attack(e, "line", e.pos, 25.0, windup, dir, 430.0)
        "crossfire", "ice_cross":
            for arm in range(4):
                var heading := dir.rotated(float(arm) * PI / 2.0)
                _warn_attack(e, "line", e.pos, 23.0, windup + .16 * arm, heading, 370.0)
        "rings", "split_rings":
            _warn_attack(e, "ring", e.pos, 105.0, windup)
            _warn_attack(e, "ring", e.pos, 174.0, windup + .49)
            if pattern == "split_rings":
                _warn_attack(e, "circle", target_pos, 58.0, windup + .92)
        "poison_bloom", "toxic_grid", "minefield", "storm", "web", "reactor":
            var count := 5 if pattern in ["reactor", "toxic_grid", "storm"] else 3
            var payload := "poison" if pattern.begins_with("poison") or pattern == "toxic_grid" else ("ice" if pattern == "web" else "impact")
            _warn_attack(e, "circle", target_pos, 65.0, windup, dir, 0.0, payload)
            for spot in range(count):
                var offset := dir.rotated(float(spot) * TAU / float(count)) * (100.0 if count == 3 else 135.0)
                _warn_attack(e, "circle", _wrap_vec(target_pos + _uniso(offset)), 50.0, windup + .31 + float(spot) * .14, dir, 0.0, payload)
        "tunnel":
            for segment in range(4):
                var offset := dir * (78.0 + float(segment) * 74.0)
                _warn_attack(e, "circle", _wrap_vec(e.pos + _uniso(offset)), 61.0, windup + float(segment) * .26)
        "fan", "shards":
            for ray in range(5):
                var heading := dir.rotated(float(ray - 2) * .28)
                _warn_attack(e, "line", e.pos, 14.0, windup + float(ray) * .12, heading, 310.0, "shard")

func _warning_hits(zone: Dictionary, position: Vector2) -> bool:
    var delta := _screen_delta(position, zone.pos)
    if zone.shape == "ring":
        return absf(delta.length() - float(zone.size)) <= 22.0
    if zone.shape == "line":
        var along: float = delta.dot(zone.dir)
        return along >= 0.0 and along <= float(zone.length) and absf(delta.cross(zone.dir)) <= float(zone.size)
    return delta.length() <= float(zone.size)

func _update_warnings(dt: float) -> void:
    if warning_zones.is_empty():
        return
    var active: Dictionary = {}
    for enemy in enemies:
        if enemy.hp > 0.0:
            active[enemy.id] = enemy
    for zone in warning_zones.duplicate():
        if not active.has(zone.owner):
            warning_zones.erase(zone)
            continue
        var enemy: Dictionary = active[zone.owner]
        zone.time -= dt
        if zone.time > 0.0:
            continue
        warning_zones.erase(zone)
        var impact: Vector2 = zone.pos
        match str(zone.payload):
            "boss_sweep", "spore_ring", "snare_ring", "sentinel_ring":
                var source := {"pos": impact}
                var phase := Vector2(zone.dir).angle()
                if zone.payload == "boss_sweep":
                    var shots := 14 if enemy.hp < enemy.max_hp * .47 else 10
                    _fire_ring(source, phase + .17, shots, 127.0, "arc")
                elif zone.payload == "spore_ring":
                    _fire_ring(source, phase, 8, 106.0, "poison")
                elif zone.payload == "snare_ring":
                    _create_hazard(impact, "ice", zone.size, 1.4)
                    _fire_ring(source, phase + .28, 8, 130.0, "ice")
                else:
                    _fire_ring(source, phase, 11, 168.0, "arc")
                continue
            "frost_lance":
                _fire_curtain({"pos": impact}, zone.dir, 10.0, [-1, 0, 1], 203.0)
                continue
            "charge":
                enemy.rush_dir = zone.dir
                enemy.rush_left = .40
                enemy.rush_hit = []
                continue
            "shard":
                _shoot_enemy(enemy, zone.dir, "ice" if enemy.kind == "frostboss" else "blast")
                continue
            "poison", "ice":
                _create_hazard(impact, zone.payload, zone.size, 1.75)
        for id in players:
            if _warning_hits(zone, players[id].pos):
                _damage_player(id, float(zone.damage))
        _burst(world.screen_point(impact, camera_pos), Color("#ffc16f"), 23)
        zone.life = .25
        if warning_impacts.size() < 28:
            warning_impacts.append(zone)


func _shoot_enemy(e: Dictionary, dir: Vector2, kind: String, speed_override: float = 0.0) -> void:
    # Real traveling projectiles in world coordinates, with screen-pixel velocities.
    # Slow enough to see and dodge; variants differ in color, size, and pace.
    if enemy_blobs.size() >= MAX_ENEMY_BLOBS:
        return
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
        "spark", "arc", "needle_shot":
            radius = 6.0 if kind == "needle_shot" else 7.0
            duration = 3.6
            impact = 8.0 if kind == "spark" else 10.0
    if speed_override > 0.0:
        speed = speed_override
    # Begin outside the source sprite: no point-blank invisible hit.
    var start: Vector2 = _wrap_vec(e.pos + _uniso(heading * 23.0))
    enemy_blobs.append({
        "id": next_blob_id, "pos": start, "velocity": heading * speed, "kind": kind,
        "radius": radius, "damage": impact, "age": 0.0, "life": duration,
        "terrain_clock": 0.07, "pattern_shot": speed_override > 0.0
    })
    next_blob_id += 1

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
            if not blob.pattern_shot and not _can_occupy(destination, 0.18):
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
            var combined_radius: float = (11.0 if blob.pattern_shot else 17.0) + float(blob.radius)
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
                p.hp = minf(p.max_hp, p.hp + 4.0 + float(p.get("feast", 0.0)))
                players[id]=p
                drops.erase(a)
                squad_mission_acorns += 1
                if id == local_id:
                    run_acorns += 1
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
func _update_particles(dt: float) -> void:
    var kept := 0
    for particle in particles:
        particle.age += dt
        if particle.age < particle.life:
            particle.pos += particle.velocity * dt
            particles[kept] = particle
            kept += 1
    particles.resize(kept)
    if traces.size()>180:
        traces = traces.slice(traces.size()-180)
    for t in traces.duplicate():
        t.life-=dt
        if t.life<=0:traces.erase(t)

func _get_local_move()->Vector2:
    if _using_touch_input() and touch_controls.move_finger >= 0:
        return touch_controls.move_vector
    return Vector2(Input.get_axis("ui_left","ui_right"),Input.get_axis("ui_up","ui_down")) + Vector2((1.0 if Input.is_key_pressed(KEY_D) else 0.0)-(1.0 if Input.is_key_pressed(KEY_A) else 0.0),(1.0 if Input.is_key_pressed(KEY_S) else 0.0)-(1.0 if Input.is_key_pressed(KEY_W) else 0.0))

func _get_local_aim()->Vector2:
    if _using_touch_input():
        return touch_controls.last_aim
    var d:=get_viewport().get_mouse_position()-Vector2(640,334)
    return d.normalized() if d.length_squared()>1 else Vector2.RIGHT

func _make_touch_controls() -> void:
    touch_controls = MobileTouch.new()
    ui_root.add_child(touch_controls)
    touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_controls.dash_pressed.connect(_trigger_local_dash)
    touch_controls.chest_pressed.connect(_trigger_local_chest)
    touch_controls.menu_pressed.connect(_touch_pause)

func using_touch_layout() -> bool:
    return touch_controls != null and touch_controls.mobile_layout

func _using_touch_input() -> bool:
    return using_touch_layout() and touch_controls.active and touch_controls.using_touch

func _get_local_firing() -> bool:
    if _using_touch_input():
        return touch_controls.wants_fire()
    return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _get_local_reload() -> bool:
    return Input.is_key_pressed(KEY_R) or (_using_touch_input() and touch_controls.wants_reload())

func _trigger_local_dash() -> void:
    if page != "playing":
        return
    var move := _get_local_move()
    var aim := _get_local_aim()
    if _using_touch_input() and touch_controls.aim_finger < 0 and move.length_squared() > 0.01:
        aim = move.normalized()
    if mode == "guest":
        rpc_id(HOST_ID, "submit_input", move, aim, _get_local_firing(), _get_local_reload(), true)
    elif players.has(1):
        players[1].aim = aim
        _dash(1)

func _trigger_local_chest() -> void:
    if page != "playing":
        return
    if mode == "guest":
        rpc_id(HOST_ID, "request_open_chest", observed_guest_run_id)
    else:
        _open_nearby_chest(local_id)

func _touch_pause() -> void:
    if page == "playing":
        _show_page("paused")

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
        var grove_shift := Vector2(sin(camera_pos.x * TAU / MAP), cos(camera_pos.y * TAU / MAP))
        fx_material.set_shader_parameter("u_canopy", grove_shift)
        fx_material.set_shader_parameter("u_weather", 1.0 if weather in ["rain","mist","snow"] and bool(settings.get("weather",true)) else 0.0)
        var motion_vec: Vector2 = _screen_delta(camera_pos, last_camera_pos)
        fx_material.set_shader_parameter("u_motion", motion_vec / 64.0)
    last_camera_pos = camera_pos
    for impact in warning_impacts.duplicate():
        impact.life -= dt
        if impact.life <= 0.0:
            warning_impacts.erase(impact)
    toast_timer=maxf(0,toast_timer-dt)
    if mode == "host" and not multiplayer.get_peers().is_empty():
        snapshot_timer += dt
        if snapshot_timer >= SNAPSHOT_INTERVAL:
            snapshot_timer = fmod(snapshot_timer, SNAPSHOT_INTERVAL)
            var packet := var_to_bytes(_build_snapshot())
            if packet.size() <= SNAPSHOT_MAX_BYTES:
                var compressed := packet.compress(FileAccess.COMPRESSION_FASTLZ)
                if not compressed.is_empty() and compressed.size() < packet.size():
                    rpc("receive_snapshot", compressed, packet.size())
                else:
                    rpc("receive_snapshot", packet, 0)
            pending_fx.clear()
    elif mode == "guest" and page == "playing":
        _send_guest_input(dt)
        _update_particles(dt)
    if dedicated_server:
        return
    if mode == "guest":
        _smooth_guest_positions(dt)
    if players.has(local_id):
        camera_pos = guest_local_position if mode == "guest" and guest_local_ready else players[local_id].pos
    hud_fps_seconds += dt
    if ui_root!=null and hud_fps_seconds >= 0.065:
        hud_fps_seconds = 0.0
        _update_hud()
    if world != null and page == "playing":
        world.queue_redraw()

func _physics_process(dt: float) -> void:
    if mode == "guest" or page != "playing" or (dedicated_server and players.is_empty()):
        return
    _update_enemy_level_scale()
    if not dedicated_server:
        _update_player(1, _get_local_move(), _get_local_aim(), _get_local_firing(), _get_local_reload(), false, dt)
    if mode=="host":
        for id in player_inputs:
            if players.has(id):
                var inp: Dictionary = player_inputs[id]
                if Time.get_ticks_msec() - int(inp.get("received_at", 0)) > 750:
                    inp = {}
                _update_player(id,inp.get("move",Vector2.ZERO),inp.get("aim",Vector2.RIGHT),inp.get("fire",false),inp.get("reload",false),inp.get("dash",false),dt)
                inp.dash=false
                player_inputs[id]=inp
    if to_spawn>0:
        spawn_timer-=dt
        if spawn_timer<=0:
            var next_kind: String = encounter_queue.pop_front()
            var marked := marked_to_spawn > 0 and next_kind == "stalker"
            var core := salvage_to_spawn > 0
            if marked:
                marked_to_spawn -= 1
            if core:
                salvage_to_spawn -= 1
            _spawn_enemy(next_kind, marked, core)
            if BOSS_KINDS.has(next_kind) and settings.get("music", true) and not dedicated_server and not boss_music.playing:
                music.stop()
                boss_music.play()
            to_spawn = encounter_queue.size()
            spawn_timer = maxf(.52, 1.20 - encounter_wave * .13) if mission_phase == "guard" else .63
    _update_ultimates(dt)
    _update_enemies(dt)
    _update_warnings(dt)
    _update_enemy_blobs(dt)
    _update_drops_and_hazards(dt)
    _update_particles(dt)
    _update_upgrade_drops(dt)
    if page == "playing":
        _update_revives(dt)
        _update_mission(dt)

    novelty_timer+=dt
    if settings.get("novelty",false) and novelty_timer>100:
        novelty_timer=0
        toast_message=["PARODY AD: ACORN DELUXE — ONLY 99,999 NUTS!","PARODY AD: OFFICIAL STINKY SOCKS — ZERO REFUNDS!","PARODY AD: MINI FOAM RAILGUN — NOT A REAL WEAPON!","PARODY AD: PLUSH SQUIRREL KING — HE SCREAMS!"].pick_random()
        toast_timer=6.0
    day_phase = fposmod(day_phase + dt / 185.0, 1.0)
    weather_timer += dt
    if weather_timer >= 30.0:
        weather_timer -= 30.0
        weather_index = (weather_index + 1) % 5
        weather = ["clear", "wind", "rain", "mist", "snow"][weather_index]

func _build_snapshot() -> Dictionary:
    return {"stamp":Time.get_ticks_msec() * .001,"players":NetState.pack_players(players),"enemies":NetState.pack_enemies(enemies),"drops":drops,"xp_drops":xp_drops,"run_id":run_id,"run_level":run_level,"run_xp":run_xp,"xp_to_next":xp_to_next,"hazards":hazards,"pattern_shots":NetState.pack_bullets(enemy_blobs),"traces":traces.slice(-24),"fx":pending_fx,"wave":wave,"to_spawn":to_spawn,"elapsed":elapsed,"stage_kills":stage_kills,"day":day_phase,"weather":weather,"boss_name":boss_name,"phase":page,"mission_phase":mission_phase,"field":[encounter_wave, wave_break, objective_pos, objective_goal, salvage_collected, salvage_needed, marked_remaining, veteran_operation, flag_carrier, flag_pos, flag_delivered, quota_goal, wave_kills, capture_blocked],"cores":field_salvage,"chests":field_chests,"upgrade_drops":field_upgrade_drops,"warnings":warning_zones,"impacts":warning_impacts,"guard_remaining":guard_remaining,"mission_checkpoint":mission_checkpoint,"dedicated_server":dedicated_server,"run_acorns":squad_mission_acorns,"upgrades_taken":upgrades_taken}

func _smooth_guest_positions(dt: float) -> void:
    guest_motion.step(dt)
    if guest_visual_run_id != observed_guest_run_id:
        guest_visual_run_id = observed_guest_run_id
        guest_local_ready = false
    var own: Dictionary = players.get(local_id, {})
    if own.is_empty():
        guest_local_ready = false
        return
    var target: Vector2 = own.pos
    if not guest_local_ready or GuestMotion.wrapped_difference(target, guest_local_position).length_squared() > 36.0:
        guest_local_position = target
        guest_local_ready = true
    var moving := _get_local_move().limit_length(1.0) if page == "playing" and own.hp > 0.0 else Vector2.ZERO
    if float(own.dash_left) <= 0.0:
        var age := clampf(float(Time.get_ticks_msec() - last_packet_at) * .001, 0.0, .09)
        if age < .09:
            guest_local_position = _move_to(guest_local_position, _uniso(moving * float(own.speed) * dt))
        var lead := minf(.14, age + .046)
        target = _move_to(target, _uniso(moving * float(own.speed) * lead))
    var error := GuestMotion.wrapped_difference(target, guest_local_position)
    guest_local_position = _wrap_vec(guest_local_position + error * (1.0 - exp(-dt * 14.0)))

func render_player_position(id: int, fallback: Vector2) -> Vector2:
    if mode != "guest":
        return fallback
    if id == local_id and guest_local_ready:
        return guest_local_position
    return guest_motion.sample("players", id, fallback)

func render_enemy_position(enemy: Dictionary) -> Vector2:
    if mode == "guest":
        return guest_motion.sample("enemies", enemy.id, enemy.pos)
    return enemy.pos

func render_bullet_position(bullet: Dictionary) -> Vector2:
    if mode == "guest":
        var pos := guest_motion.sample("shots", bullet.id, bullet.pos)
        return _wrap_vec(pos + _uniso(bullet.velocity * guest_motion.extra_time()))
    return bullet.pos

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE:
            if quit_dialog != null and quit_dialog.visible:
                quit_dialog.hide()
            elif page == "playing":
                _show_page("paused")
            elif page == "paused" or page == "title":
                _request_exit("quit")
            elif page in ["defeated", "mission_complete"]:
                _request_exit("menu")
            elif page == "settings":
                _show_page(settings_return_page)
            elif page == "admin":
                _show_page(admin_return_page)
            else:
                _show_page("title")
            get_viewport().set_input_as_handled()
        elif (event.physical_keycode == KEY_E or event.keycode == KEY_E) and page == "playing":
            _trigger_local_chest()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_SPACE and page == "playing":
            _trigger_local_dash()
            get_viewport().set_input_as_handled()

func _peer_connected(id:int)->void:
    if mode != "host":
        return
    if multiplayer.get_peers().size() > (MAX_GUESTS + 1 if dedicated_server else MAX_GUESTS):
        multiplayer.multiplayer_peer.disconnect_peer(id)
        return
    if dedicated_server and page == "title":
        var cleared := int(progress.get("campaign_clears", 0))
        var first_chapter := 1 if cleared >= Campaign.MISSIONS.size() else cleared + 1
        _start_run(first_chapter)
    elif not players.has(id):
        players[id] = _make_online_guest(id)
    toast_message = "A RANGER JOINED THE SQUAD"
    toast_timer = 2.8

func _peer_disconnected(id:int)->void:
    players.erase(id)
    player_inputs.erase(id)
    guest_loadouts.erase(id)

func _joined_server()->void:
    _stop_join_timeout()
    last_snapshot_stamp = -1.0
    guest_motion.reset()
    guest_local_ready = false
    local_id=multiplayer.get_unique_id()
    observed_guest_run_id=-1;last_guest_kills=0
    observed_clear = -1
    wave = 0
    players.clear()
    server_is_dedicated = false
    guest_input_seconds = 0.0
    mode="guest"
    _show_page("playing")
    var weapon_id := str(progress.get("weapon", "shotgun"))
    if not _unlocked_weapon(weapon_id):
        weapon_id = "shotgun"
    var outfit := str(progress.get("character", "scout"))
    if not _unlocked_character(outfit):
        outfit = "scout"
    var skin := str(progress.gun_skins.get(weapon_id, SKIN_OPTIONS[weapon_id][0]))
    rpc_id(HOST_ID, "select_loadout", weapon_id, outfit, skin, _career_level(), int(progress.get("field_xp", 0)) % RangerProgress.XP_PER_LEVEL, _prestige_rank())

func _failed_connection()->void:
    _stop_join_timeout()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    mode = "solo"
    local_id = 1
    _show_network_error("Could not connect to the host. Check that the game server is running and try again.")

func _server_disconnected()->void:
    _stop_join_timeout()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    mode="solo"
    local_id = 1
    music.stop()
    boss_music.stop()
    _show_network_error("The host disconnected. Your completed operations are saved.")

func _show_network_error(message: String) -> void:
    toast_message = message
    toast_timer = 5.0
    _show_page("title")
    var banner := _make_label(message, 14, "#ffce8f", true)
    banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    main_layout.add_child(banner)
    main_layout.move_child(banner, 0)

@rpc("any_peer","call_remote","reliable")
func select_loadout(weapon_id: String, outfit: String, skin: String, level: int, xp_remainder: int, prestige: int) -> void:
    if mode != "host":
        return
    var id := multiplayer.get_remote_sender_id()
    if not players.has(id) or guest_loadouts.has(id):
        return
    if not WEAPON_ORDER.has(weapon_id):
        weapon_id = str(RETIRED_WEAPONS.get(weapon_id, "shotgun"))
    if RangerProgress.OUTFITS.has(outfit):
        if prestige < int(RangerProgress.OUTFITS[outfit].value) or prestige > RangerProgress.MAX_PRESTIGE:
            outfit = "scout"
    elif not CHARACTER_SKINS.has(outfit):
        outfit = "scout"
    if not SKIN_OPTIONS[weapon_id].has(skin):
        skin = SKIN_OPTIONS[weapon_id][0]
    # Local unlocks travel with each guest. The host only accepts catalog items
    # and uses their own fixed stats. A guest cannot send a stat or edit mid-mission.
    guest_loadouts[id] = {"weapon": weapon_id, "character": outfit, "skin": skin,
        "field_xp": (clampi(level, 1, RangerProgress.MAX_LEVEL) - 1) * RangerProgress.XP_PER_LEVEL
            + clampi(xp_remainder, 0, RangerProgress.XP_PER_LEVEL - 1)}
    var old: Dictionary = players[id]
    var ranger := _make_online_guest(id)
    ranger.pos = old.pos
    for perk in old.get("chest_upgrades", []):
        _grant_chest_upgrade(ranger, perk)
    ranger.hp = float(ranger.max_hp) * clampf(float(old.hp) / float(old.max_hp), 0.0, 1.0)
    ranger.kills = old.kills
    players[id] = ranger

func _make_online_guest(id: int) -> Dictionary:
    if not guest_loadouts.has(id):
        return _make_campaign_player(id)
    var loadout: Dictionary = guest_loadouts[id]
    var ranger := _make_campaign_player(id, false)
    var weapon: Dictionary = WEAPONS[loadout.weapon]
    var outfit: String = loadout.character
    ranger.weapon = loadout.weapon
    ranger.skin = loadout.skin
    ranger.character = outfit
    ranger.level = RangerProgress.level(int(loadout.field_xp))
    ranger.max_hp = 100.0
    ranger.hp = ranger.max_hp
    ranger.speed = 185.0 * (1.14 if outfit == "trailblazer" else 1.0)
    ranger.fire = 1 if outfit == "cindercloak" else 0
    ranger.ice = 1 if outfit == "frostbound" else 0
    ranger.mag = weapon.ammo
    ranger.ammo = weapon.ammo
    ranger.damage = float(weapon.damage) * (1.12 if outfit == "sharpsight" else 1.0)
    ranger.pellets = weapon.pellets
    ranger.cooldown = weapon.cooldown
    ranger.reload_time = weapon.reload
    ranger.range = weapon.range
    ranger.spread = weapon.spread
    _apply_prestige_outfit(ranger)
    _train_player(ranger)
    return ranger

@rpc("any_peer","call_remote","unreliable")
func submit_input(move:Vector2,aim:Vector2,firing:bool,reload:bool,dash:bool)->void:
    if mode!="host":return
    var id:=multiplayer.get_remote_sender_id()
    if page != "playing" or not players.has(id) or not move.is_finite() or not aim.is_finite():
        return
    var previous: Dictionary = player_inputs.get(id, {})
    var now := Time.get_ticks_msec()
    if not dash and now - int(previous.get("received_at", -1000)) < 15:
        return
    var minimum := Vector2(-1.0, -1.0)
    var maximum := Vector2(1.0, 1.0)
    player_inputs[id] = {
        "move": move.clamp(minimum, maximum).limit_length(1.0),
        "aim": aim.clamp(minimum, maximum).normalized(),
        "fire": firing,
        "reload": reload,
        "dash": dash or bool(previous.get("dash", false)),
        "received_at": now,
    }

func _send_guest_input(dt: float) -> void:
    guest_input_seconds += dt
    if guest_input_seconds < 1.0 / 30.0:
        return
    guest_input_seconds = fmod(guest_input_seconds, 1.0 / 30.0)
    rpc_id(HOST_ID, "submit_input", _get_local_move(), _get_local_aim(),
        _get_local_firing(), _get_local_reload(), false)

@rpc("authority","call_remote","unreliable")
func receive_snapshot(payload: PackedByteArray, original_size: int) -> void:
    if mode != "guest" or payload.is_empty() or payload.size() > SNAPSHOT_MAX_BYTES:
        return
    if original_size < 0 or original_size > SNAPSHOT_MAX_BYTES:
        return
    var bytes := payload.decompress(original_size, FileAccess.COMPRESSION_FASTLZ) if original_size > 0 else payload
    if bytes.is_empty():
        return
    var decoded: Variant = bytes_to_var(bytes)
    if decoded is Dictionary:
        _use_snapshot(decoded)

func _use_snapshot(snapshot: Dictionary) -> void:
    var stamp: float = snapshot.get("stamp", -1.0)
    if stamp <= last_snapshot_stamp:
        return
    last_snapshot_stamp = stamp
    last_packet_at = Time.get_ticks_msec()
    var previous_player: Dictionary = players.get(local_id, {})
    var previous_wave := wave
    var incoming_run_id := int(snapshot.get("run_id", 0))
    var same_run := incoming_run_id == observed_guest_run_id
    players = NetState.unpack_players(snapshot.get("players", {}))
    # Earn each guest's real weapon/total-kill progression from host-authoritative
    # snapshots. Run IDs prevent double-counting across successive waves/runs.
    if not same_run:
        guest_motion.reset()
        observed_guest_run_id=incoming_run_id
        last_guest_kills=0
    if players.has(local_id):
        var own: Dictionary = players[local_id]
        if same_run and not previous_player.is_empty():
            if int(own.get("shots_fired", 0)) > int(previous_player.get("shots_fired", 0)):
                _sound("shotgun")
            if float(own.get("reload", 0.0)) > 0.0 and float(previous_player.get("reload", 0.0)) <= 0.0:
                _sound("reload")
        var actual_kills: int = int(own.get("kills",0))
        if actual_kills>last_guest_kills:
            var earned: int = actual_kills-last_guest_kills
            var weapon_key: String = str(own.get("weapon","shotgun"))
            progress.kills=int(progress.get("kills",0))+earned
            progress.weapon_kills[weapon_key]=int(progress.weapon_kills.get(weapon_key,0))+earned
            _save_progress()
            last_guest_kills=actual_kills
    enemies = NetState.unpack_enemies(snapshot.get("enemies", []))
    for enemy in enemies:
        if not progress.discovered.get(enemy.kind, false):
            progress.discovered[enemy.kind] = true
            _save_progress()
    drops.assign(snapshot.get("drops",[]))
    xp_drops.assign(snapshot.get("xp_drops",[]))
    run_level=int(snapshot.get("run_level",1))
    run_xp=float(snapshot.get("run_xp",0.0))
    xp_to_next=float(snapshot.get("xp_to_next",70.0))
    hazards.assign(snapshot.get("hazards",[]))
    enemy_blobs = NetState.unpack_bullets(snapshot.get("pattern_shots", PackedFloat32Array()))
    guest_motion.observe(stamp, players, enemies, enemy_blobs)
    traces.assign(snapshot.get("traces",[]))
    if not same_run:
        particles.clear()
    for event in snapshot.get("fx", []):
        if event is Array and event.size() == 3:
            _burst(world.screen_point(event[0], camera_pos), event[1], int(event[2]))
    wave=snapshot.get("wave",0)
    to_spawn=snapshot.get("to_spawn",0)
    stage_kills=snapshot.get("stage_kills",0)
    elapsed = maxf(elapsed, float(snapshot.get("elapsed", 0.0))) if same_run else float(snapshot.get("elapsed", 0.0))
    day_phase=snapshot.get("day",.25)
    weather=snapshot.get("weather","clear")
    boss_name=snapshot.get("boss_name","")
    mission_phase = str(snapshot.get("mission_phase", ""))
    var field: Array = snapshot.get("field", [])
    if field.size() == 14:
        encounter_wave = field[0]
        wave_break = field[1]
        objective_pos = field[2]
        objective_goal = field[3]
        salvage_collected = field[4]
        salvage_needed = field[5]
        marked_remaining = field[6]
        veteran_operation = field[7]
        flag_carrier = field[8]
        flag_pos = field[9]
        flag_delivered = field[10]
        quota_goal = field[11]
        wave_kills = field[12]
        capture_blocked = field[13]
    field_salvage.assign(snapshot.get("cores", []))
    field_chests.assign(snapshot.get("chests", []))
    field_upgrade_drops.assign(snapshot.get("upgrade_drops", []))
    warning_zones.assign(snapshot.get("warnings", []))
    warning_impacts.assign(snapshot.get("impacts", []))
    guard_remaining = float(snapshot.get("guard_remaining", 0.0))
    mission_checkpoint = bool(snapshot.get("mission_checkpoint", false))
    run_acorns = int(snapshot.get("run_acorns", 0))
    server_is_dedicated = bool(snapshot.get("dedicated_server", false))
    if server_is_dedicated:
        if players.has(local_id):
            var equipped: String = players[local_id].weapon
            if not same_run or previous_wave != wave or previous_player.get("weapon", "") != equipped:
                upgrades_taken.assign(_training_options(equipped).slice(-8))
    else:
        upgrades_taken.assign(snapshot.get("upgrades_taken", []))
    var status: String=snapshot.get("phase","playing")
    _update_guest_music(status)
    if page == "paused" and status == "playing":
        return
    if status!=page and status in ["playing", "defeated", "mission_complete", "operations_lobby"]:
        _show_page(status)

func _update_guest_music(status: String) -> void:
    if status != "playing" or not settings.get("music", true):
        if music.playing:
            music.stop()
        if boss_music.playing:
            boss_music.stop()
    elif mission_phase == "boss" and enemies.any(func(enemy: Dictionary): return BOSS_KINDS.has(enemy.kind)):
        if music.playing:
            music.stop()
        if not boss_music.playing:
            boss_music.play()
    else:
        if boss_music.playing:
            boss_music.stop()
        if not music.playing:
            music.play()

func _start_solo()->void:
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
    guest_loadouts.clear()
    mode="solo";local_id=1
    _start_run()

func _start_host()->void:
    if OS.has_feature("web"):
        _start_join()
        return
    var peer:=ENetMultiplayerPeer.new()
    var err:=peer.create_server(PORT,MAX_GUESTS)
    if err!=OK:
        toast_message="CANNOT HOST UDP %d (error %d)" % [PORT,err]
        toast_timer=5
        return
    multiplayer.multiplayer_peer=peer
    guest_loadouts.clear()
    local_id=1;mode="host"
    _start_run()

func _new_online_peer() -> WebSocketMultiplayerPeer:
    var peer := WebSocketMultiplayerPeer.new()
    peer.inbound_buffer_size = 262144
    peer.outbound_buffer_size = 262144
    peer.max_queued_packets = 512
    return peer

func _start_dedicated_server() -> void:
    if OS.has_feature("web"):
        return
    var peer := _new_online_peer()
    var room := _host_room()
    var port := ONLINE_PORT + 1 if room == LANTERN_HOLLOW else ONLINE_PORT
    var err := peer.create_server(port, "127.0.0.1")
    if err != OK:
        push_error("CANNOT START ONLINE SERVER (PORT %d, ERROR %d)" % [port, err])
        get_tree().quit(1)
        return
    dedicated_server = true
    Engine.max_fps = 60
    local_id = 0
    mode = "host"
    guest_loadouts.clear()
    var scene_network := multiplayer as SceneMultiplayer
    if scene_network != null:
        scene_network.server_relay = false
    multiplayer.multiplayer_peer = peer
    print("%s is listening on ws://127.0.0.1:%d. Waiting for the squad." % [room, port])

func _host_room() -> String:
    if OS.get_cmdline_user_args().has("--room=" + LANTERN_HOLLOW):
        return LANTERN_HOLLOW
    return FERN_CREEK

func _web_endpoint(room: String = FERN_CREEK) -> String:
    if not OS.has_feature("web"):
        return "wss://" + PUBLIC_GAME_HOST + _room_path(room)
    var location = JavaScriptBridge.get_interface("location")
    if location == null:
        return ""
    var protocol := "wss" if str(location.protocol) == "https:" else "ws"
    return "%s://%s%s" % [protocol, str(location.host), _room_path(room)]

func _room_path(room: String) -> String:
    return "/play/" + LANTERN_HOLLOW if room == LANTERN_HOLLOW else "/play"

func _start_join_room(room: String) -> void:
    _join_at(_web_endpoint(room))

func _start_join()->void:
    var addr: String=connection_text.text.strip_edges() if connection_text!=null else "127.0.0.1"
    _join_at(addr)

func _join_at(addr: String) -> void:
    addr = addr.strip_edges()
    var host_part := addr.get_slice("/", 0).to_lower()
    if host_part in [PUBLIC_GAME_HOST, "stinkysquirrel.online"]:
        addr = "https://" + addr
    if addr.begins_with("https://") or addr.begins_with("http://"):
        var scheme := "https://" if addr.begins_with("https://") else "http://"
        var authority_and_path := addr.trim_prefix(scheme).trim_suffix("/")
        addr = ("wss://" if scheme == "https://" else "ws://") + authority_and_path
        if not authority_and_path.contains("/"):
            addr += "/play"
    var peer: MultiplayerPeer
    var err: Error
    if addr.begins_with("ws://") or addr.begins_with("wss://"):
        var online_peer := _new_online_peer()
        online_peer.handshake_timeout = 9.0
        err = online_peer.create_client(addr)
        peer = online_peer
    elif OS.has_feature("web"):
        _show_network_error("Open the host’s game page or enter its secure server address.")
        return
    else:
        if addr.is_empty():
            addr = "127.0.0.1"
        var lan_peer := ENetMultiplayerPeer.new()
        err = lan_peer.create_client(addr, PORT)
        peer = lan_peer
    if err!=OK:
        _show_network_error("Could not join %s (error %d)." % [addr, err])
        return
    multiplayer.multiplayer_peer=peer
    mode="guest"
    _show_page("connecting")
    if join_timeout == null:
        join_timeout = Timer.new()
        join_timeout.one_shot = true
        join_timeout.timeout.connect(_failed_connection)
        add_child(join_timeout)
    join_timeout.start(12.0)

func _stop_join_timeout() -> void:
    if join_timeout != null:
        join_timeout.stop()

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
        quit_dialog.title = "LEAVE THIS OPERATION?"
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
        get_tree().quit()

func _return_menu() -> void:
    _request_exit("menu")

func _return_menu_immediately() -> void:
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
    mode="solo"
    local_id=1
    players.clear()
    wave = 0
    if music.playing:
        music.stop()
    if boss_music.playing:
        boss_music.stop()
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
    fx_rect.visible = shader_needed and page == "playing"
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
        for key in ["fx_contact_shadows", "fx_color_grade", "fx_vignette", "fx_fog", "fx_god_rays", "fx_bloom", "fx_reflections", "fx_long_exposure"]:
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
    pixel_icon.custom_minimum_size=Vector2(21,21)
    pixel_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    stat.add_child(pixel_icon)
    var amount: Label = Label.new()
    amount.text="0"
    amount.add_theme_font_size_override("font_size",16)
    amount.add_theme_color_override("font_color",tint)
    amount.mouse_filter=Control.MOUSE_FILTER_IGNORE
    stat.add_child(amount)
    return amount

func _hud_acorn_icon() -> TextureRect:
    var icon := TextureRect.new()
    icon.texture = preload("res://art/acorn.png")
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.custom_minimum_size = Vector2(19, 19)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    return icon

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
    main_scroll = scroll
    scroll.custom_minimum_size = Vector2(978, 580)
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
    hud_left.add_theme_font_size_override("font_size",16)
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
    hud_right.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    hud_right.add_theme_font_size_override("font_size",15)
    hud_right.add_theme_color_override("font_color",Color("f6d38f"))
    ammo_column.add_child(hud_right)
    hud_ammo_meter=StinkyHudMeter.new()
    hud_ammo_meter.mode="ammo"
    hud_ammo_meter.custom_minimum_size=Vector2(244,58)
    ammo_column.add_child(hud_ammo_meter)
    hud_status_box=PanelContainer.new()
    hud_status_box.position=Vector2(12,654)
    hud_status_box.custom_minimum_size=Vector2(385,42)
    hud_status_box.add_theme_stylebox_override("panel", _panel_style("#10292c", "#537d70", 12))
    ui_root.add_child(hud_status_box)
    var status_row: HBoxContainer = HBoxContainer.new()
    status_row.add_theme_constant_override("separation",18)
    hud_status_box.add_child(status_row)
    # Keep acorns separate: one counter for this run and one banked total.
    var run_acorns_stat: HBoxContainer = HBoxContainer.new()
    run_acorns_stat.tooltip_text="Acorns collected on this operation"
    status_row.add_child(run_acorns_stat)
    run_acorns_stat.add_child(_hud_acorn_icon())
    hud_acorns_collected=_make_label("0",16,"#cfebdd")
    hud_acorns_collected.autowrap_mode = TextServer.AUTOWRAP_OFF
    run_acorns_stat.add_child(hud_acorns_collected)
    var saved_acorns_stat: HBoxContainer = HBoxContainer.new()
    saved_acorns_stat.tooltip_text="Banked acorns"
    status_row.add_child(saved_acorns_stat)
    var bank_label := _make_label("BANK", 11, "#a9e9da")
    bank_label.custom_minimum_size.x = 34.0
    bank_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    saved_acorns_stat.add_child(bank_label)
    hud_acorns_saved=_make_label("0",16,"#cfebdd")
    hud_acorns_saved.autowrap_mode = TextServer.AUTOWRAP_OFF
    saved_acorns_stat.add_child(hud_acorns_saved)
    hud_best_wave=_make_pixel_hud_stat(status_row,"record","Campaign chapters cleared",Color("f9d389"))
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
    hud_xp_label=_make_label("1    0 / 70",12,"#9ff8de",true)
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
    mission_label = _make_label("", 15, "#e9ffdd", true)
    mission_label.position = Vector2(347, 57)
    mission_label.custom_minimum_size = Vector2(586, 26)
    mission_label.add_theme_color_override("font_outline_color", Color("#172f38"))
    mission_label.add_theme_constant_override("outline_size", 5)
    ui_root.add_child(mission_label)
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
    _create_transfer_dialogs()
    _update_hud()

func _create_transfer_dialogs() -> void:
    if not OS.has_feature("web"):
        profile_export_dialog = _new_json_dialog("Export Woodland Watch progress", FileDialog.FILE_MODE_SAVE_FILE)
        profile_export_dialog.file_selected.connect(_write_profile_export)
        profile_import_dialog = _new_json_dialog("Import Woodland Watch progress", FileDialog.FILE_MODE_OPEN_FILE)
        profile_import_dialog.file_selected.connect(_read_profile_file)
    profile_confirm = ConfirmationDialog.new()
    profile_confirm.title = "Replace local progress?"
    profile_confirm.ok_button_text = "IMPORT PROGRESS"
    profile_confirm.confirmed.connect(_apply_profile_import)
    profile_confirm.canceled.connect(func(): pending_profile.clear())
    add_child(profile_confirm)
    prestige_confirm = ConfirmationDialog.new()
    prestige_confirm.title = "Prestige and reset progress?"
    prestige_confirm.ok_button_text = "PRESTIGE AND RESET"
    prestige_confirm.confirmed.connect(_apply_prestige)
    add_child(prestige_confirm)

func _request_prestige() -> void:
    if not _can_prestige():
        return
    prestige_confirm.dialog_text = (
        "Prestige %d unlocks a powerful ranger skin. Your level, operations, weapons, " +
        "other unlocks, counters, and currencies reset. Earlier prestige skins carry forward."
    ) % (_prestige_rank() + 1)
    prestige_confirm.popup_centered(Vector2i(520, 0))

func _can_prestige() -> bool:
    return _profile_can_transfer() and _career_level() == RangerProgress.MAX_LEVEL and _prestige_rank() < RangerProgress.MAX_PRESTIGE

func _apply_prestige() -> void:
    if not _can_prestige():
        return
    var next_rank := _prestige_rank() + 1
    var result := _reset_local_profile(next_rank)
    _show_page("profile_tools")
    _profile_status(result)

func _new_json_dialog(title_value: String, mode_value: int) -> FileDialog:
    var dialog := FileDialog.new()
    dialog.title = title_value
    dialog.file_mode = mode_value as FileDialog.FileMode
    dialog.access = FileDialog.ACCESS_FILESYSTEM
    dialog.filters = PackedStringArray(["*.json ; Woodland Watch progress JSON"])
    dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
    ui_root.add_child(dialog)
    return dialog

func _profile_can_transfer() -> bool:
    return page == "profile_tools" and mode == "solo" and not admin_mode and not dedicated_server

func _profile_status(text: String) -> void:
    profile_transfer_status = text
    if page == "profile_tools" and is_instance_valid(profile_status_label):
        profile_status_label.text = text

func _profile_export_name() -> String:
    return "woodland-watch-progress-%s.json" % Time.get_date_string_from_system()

func _request_profile_export() -> void:
    if not _profile_can_transfer():
        return
    if OS.has_feature("web"):
        JavaScriptBridge.download_buffer(ProfileTransfer.encode(progress).to_utf8_buffer(), _profile_export_name(), "application/json")
        _profile_status("Download requested. Look for the JSON file in your browser downloads.")
    else:
        profile_export_dialog.current_file = _profile_export_name()
        profile_export_dialog.popup_centered(Vector2i(820, 500))

func _write_profile_export(path: String) -> void:
    if not _profile_can_transfer():
        return
    if path.get_extension().to_lower() != "json":
        _profile_status("Save the file with a .json extension.")
        return
    if _write_profile_json(path, progress):
        _profile_status("Exported " + path.get_file())
    else:
        _profile_status("Could not write the export. Try a different folder.")

func _write_profile_json(path: String, data: Dictionary) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(ProfileTransfer.encode(data))
    file.flush()
    return file.get_error() == OK

func _request_profile_import() -> void:
    if not _profile_can_transfer():
        return
    if not OS.has_feature("web"):
        profile_import_dialog.popup_centered(Vector2i(820, 500))
        return
    if web_file_reader != null:
        _profile_status("Reading the selected save…")
        return
    _clear_web_picker()
    var document := JavaScriptBridge.get_interface("document")
    web_file_input = document.createElement("input")
    web_file_input.type = "file"
    web_file_input.accept = ".json,application/json"
    web_file_input.style.display = "none"
    web_picker_change = JavaScriptBridge.create_callback(_web_profile_selected)
    web_picker_cancel = JavaScriptBridge.create_callback(_web_profile_canceled)
    web_file_input.addEventListener("change", web_picker_change)
    web_file_input.addEventListener("cancel", web_picker_cancel)
    document.body.appendChild(web_file_input)
    web_file_input.click()

func _clear_web_picker() -> void:
    if web_file_input != null:
        web_file_input.remove()
        web_file_input = null
    web_picker_change = null
    web_picker_cancel = null

func _web_profile_canceled(_arguments: Array) -> void:
    _clear_web_picker()

func _web_profile_selected(_arguments: Array) -> void:
    if web_file_input == null:
        return
    var file = web_file_input.files.item(0)
    _clear_web_picker()
    if file == null or not _profile_can_transfer():
        return
    if float(file.size) > ProfileTransfer.MAX_BYTES:
        _profile_status("That file is too large for a Woodland Watch save.")
        return
    web_file_reader = JavaScriptBridge.create_object("FileReader")
    web_reader_load = JavaScriptBridge.create_callback(_web_profile_loaded)
    web_reader_error = JavaScriptBridge.create_callback(_web_profile_read_failed)
    web_file_reader.addEventListener("load", web_reader_load)
    web_file_reader.addEventListener("error", web_reader_error)
    web_file_reader.readAsText(file, "utf-8")

func _web_profile_loaded(_arguments: Array) -> void:
    if web_file_reader == null:
        return
    var raw := str(web_file_reader.result)
    web_file_reader = null
    web_reader_load = null
    web_reader_error = null
    _stage_profile_import(raw)

func _web_profile_read_failed(_arguments: Array) -> void:
    web_file_reader = null
    web_reader_load = null
    web_reader_error = null
    _profile_status("The browser could not read that file.")

func _read_profile_file(path: String) -> void:
    if not _profile_can_transfer():
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _profile_status("Could not open that file.")
        return
    if file.get_length() > ProfileTransfer.MAX_BYTES:
        _profile_status("That file is too large for a Woodland Watch save.")
        return
    _stage_profile_import(file.get_as_text())

func _stage_profile_import(raw: String) -> void:
    if not _profile_can_transfer():
        return
    pending_profile.clear()
    var known_enemies: Array = ENEMY_ORDER + BOSS_KINDS + FieldPatterns.ROSTER.keys()
    var decoded := ProfileTransfer.decode(raw, SKIN_OPTIONS, _outfit_catalog(), known_enemies, Campaign.MISSIONS.size())
    if decoded.has("error"):
        _profile_status(decoded.error)
        return
    pending_profile = decoded.progress
    profile_confirm.dialog_text = "This file has chapter %d clearance and %d field XP. Importing replaces local progress and makes a backup of your current save." % [
        pending_profile.campaign_clears, pending_profile.field_xp]
    profile_confirm.popup_centered(Vector2i(570, 210))

func _apply_profile_import() -> void:
    if not _profile_can_transfer() or pending_profile.is_empty():
        pending_profile.clear()
        return
    var backup_path := "user://woodland-watch-before-import-%d-%d.json" % [
        int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
    if not _write_profile_json(backup_path, progress):
        pending_profile.clear()
        _profile_status("Could not back up your current save. Progress was kept.")
        return
    var browser := _get_web_profile_store()
    if browser != null:
        browser.write(WEB_PROFILE_BACKUP_KEY, ProfileTransfer.encode(progress))
    var original := progress
    progress = pending_profile
    pending_profile = {}
    _normalize_loadout_profile()
    _migrate_unlock_rules()
    _save_progress()
    _flush_progress()
    if save_dirty:
        progress = original
        _profile_status("Could not save the import. Your previous progress is in " + backup_path.get_file())
        return
    selected_chapter = 1
    if OS.has_feature("web"):
        JavaScriptBridge.force_fs_sync()
    _profile_status("Progress imported. Previous save backed up as " + backup_path.get_file())

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
    _retain_legacy_licenses()
    for weapon in ORIGINAL_WEAPONS:
        if int(progress.kills) >= WEAPONS[weapon].unlock:
            progress.earned_weapons[weapon] = true
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
    row.add_child(_make_label(text, 30, "#ffe1a0", true))
    row.add_child(_make_label("NIGHTWATCH  /  RANGER COMMAND", 11, "#96ddca", true))

func _spacer(h:int=8)->void:
    var x:=Control.new()
    x.custom_minimum_size.y=h
    main_layout.add_child(x)

func _section(text:String)->void:
    _spacer(6)
    main_layout.add_child(_make_label(text,18,"#b4f4d4",false))
    var rule: HSeparator = HSeparator.new()
    rule.add_theme_constant_override("separation",3)
    main_layout.add_child(rule)

func _menu_button(text:String,callback:Callable,color:String="normal")->Button:
    var b:=Button.new()
    b.text=text
    b.custom_minimum_size=Vector2(0,38)
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
    if new_page != "admin":
        reset_confirmation_deadline = 0
    if page != new_page:
        main_scroll.set_deferred("scroll_vertical", 0)
    page=new_page
    _apply_graphics_settings()
    if world != null:
        world.queue_redraw()
    _clear_menu()
    var gaming := page == "playing"
    main_panel.visible=page!="playing"
    menu_backdrop.visible=page!="playing"
    hud_left_box.visible=gaming
    hud_right_box.visible=gaming
    hud_dash_meter.visible = gaming and not using_touch_layout()
    if touch_controls != null:
        touch_controls.set_active(gaming)
    hud_xp_box.visible=gaming
    hud_upgrade_box.visible=gaming and not upgrades_taken.is_empty()
    hud_status_box.visible=gaming
    badge.visible=gaming
    message_label.visible=gaming
    mission_label.visible=gaming
    match page:
        "title":_title_menu()
        "armory":_armory_menu()
        "wardrobe":_wardrobe_menu()
        "encyclopedia":_encyclopedia_menu()
        "upgrade_encyclopedia":_upgrades_reference_menu()
        "settings":_settings_menu()
        "admin":_admin_console_menu()
        "help":_help_menu()
        "profile_tools":_profile_tools_menu()
        "operations":_operations_menu()
        "join_address":_join_by_address_menu()
        "mission_complete":_mission_complete_menu()
        "paused":_paused_menu()
        "defeated":_defeated_menu()
        "connecting":_heading("CONNECTING TO HOST...")
    _update_hud()

# -------- HTML-inspired main menu cards --------
func _menu_card(title: String, description: String, color: String) -> VBoxContainer:
    var card: PanelContainer = PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var trim: String = "#93e4b6" if title == "DEPLOY" else ("#d6b4ff" if title == "PROGRESSION" else "#9fdcff")
    card.add_theme_stylebox_override("panel", _panel_style(color, trim, 17))
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    card.add_child(column)
    column.add_child(_make_label(title, 18, trim, true))
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
    b.custom_minimum_size = Vector2(0, 41)
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
    var title_glow: Label = _make_label("STINKY SQUIRREL", 33, "#ffdf8d", true)
    banner.add_child(title_glow)
    # A single slow menu-only tween, automatically freed with its label.
    var title_pulse: Tween = title_glow.create_tween()
    title_pulse.set_loops()
    title_pulse.tween_property(title_glow,"modulate:a",0.81,1.9)
    title_pulse.tween_property(title_glow,"modulate:a",1.0,1.9)
    banner.add_child(_make_label("WOODLAND WATCH", 19, "#a5f7dd", true))
    banner.add_child(_make_label("COOPERATIVE CAMPAIGN  ·  EIGHT OPERATIONS  ·  UP TO SIX RANGERS", 12, "#cbe9da", true))
    var squirrel: TextureRect = _menu_portrait("boss",Vector2(77,104))
    banner_row.add_child(squirrel)
    var stats: HBoxContainer = HBoxContainer.new()
    stats.add_theme_constant_override("separation", 12)
    main_layout.add_child(stats)
    for stat in [
        {"name":"TOTAL KILLS","value":progress.kills,"accent":"#90e7ba"},
        {"name":"CHAPTERS CLEARED","value":int(progress.get("campaign_clears", 0)),"accent":"#f7c478"},
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
    var play_card: VBoxContainer = _menu_card("DEPLOY", "Reopen the watch posts and take back the forest.", "#193c31")
    _card_button(play_card, "CHOOSE OPERATION", func(): _show_page("operations"), "#296650")
    _card_button(play_card, "JOIN FERN CREEK", func(): _start_join_room(FERN_CREEK), "#254755")
    _card_button(play_card, "JOIN LANTERN HOLLOW", func(): _start_join_room(LANTERN_HOLLOW), "#254755")
    if not OS.has_feature("web"):
        _card_button(play_card, "JOIN BY ADDRESS", func(): _show_page("join_address"), "#254755")

    var progress_card: VBoxContainer = _menu_card("PROGRESSION", "Tune your gear, looks, and build.", "#312640")
    _card_button(progress_card, "ARMORY", func():_show_page("armory"), "#493962")
    _card_button(progress_card, "RANGER WARDROBE", func():_show_page("wardrobe"), "#433456")
    _card_button(progress_card, "SQUIRREL ENCYCLOPEDIA", func():_show_page("encyclopedia"), "#423653")
    _card_button(progress_card, "UPGRADE ENCYCLOPEDIA", func():_show_page("upgrade_encyclopedia"), "#423653")
    var learn_card: VBoxContainer = _menu_card("LEARN & SETTINGS", "Graphics, controls, and progression.", "#1c3749")
    _card_button(learn_card, "SETTINGS", func():_open_settings("title"), "#24546a")
    _card_button(learn_card, "HOW TO PLAY", func():_show_page("help"), "#24495c")
    _card_button(learn_card, "ADMIN CONSOLE", func(): _open_admin("title"), "#374359")
    _card_button(learn_card, "PROGRESS TOOLS", func(): _show_page("profile_tools"), "#374359")
    if not OS.has_feature("web"):
        _card_button(learn_card, "QUIT GAME", func():_request_exit("quit"), "#503540")
    main_layout.remove_meta("cards_layout")
    var footer: PanelContainer = PanelContainer.new()
    footer.add_theme_stylebox_override("panel",_panel_style("#0d2527", "#568980", 10))
    main_layout.add_child(footer)
    footer.add_child(_make_label("EQUIPPED: %s  /  %s" % [str(WEAPONS[progress.weapon].name),str(_outfit_catalog()[progress.character].name)], 12, "#c1e5d9", true))

func _join_by_address_menu() -> void:
    _heading("JOIN BY ADDRESS")
    main_layout.add_child(_make_label("Enter the local host’s IP or a full server URL.", 17, "#d8efd4", true))
    connection_text = LineEdit.new()
    connection_text.placeholder_text = "Example: 192.168.1.10"
    connection_text.custom_minimum_size.y = 40
    connection_text.text_submitted.connect(func(_text: String): _start_join())
    main_layout.add_child(connection_text)
    _menu_button("JOIN", _start_join, "blue")
    _menu_button("BACK", func(): _show_page("title"), "muted")

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
        var title := "%s  /  %.1f shots per second" % [WEAPONS[w].name, 1.0 / float(WEAPONS[w].cooldown)]
        var condition: String = "Unlocked" if unlocked else ("Clear chapter %d  •  Earn %d field XP" % [_weapon_clear_requirement(w), WEAPON_TRAINING_XP[WEAPON_LICENSE_ORDER.find(w)]])
        if not unlocked and _weapon_veteran_requirement(w) > 0:
            condition += "  •  %d Veteran clear(s), ch. 5+" % _weapon_veteran_requirement(w)
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
    _section("RANGER SKINS  ·  LEVEL %d  ·  PRESTIGE %d" % [_career_level(), _prestige_rank()])
    var gallery: GridContainer = GridContainer.new()
    gallery.columns = 2
    gallery.add_theme_constant_override("h_separation", 10)
    gallery.add_theme_constant_override("v_separation", 10)
    main_layout.add_child(gallery)
    var outfits := _outfit_catalog()
    for skin_id in outfits:
        var info: Dictionary = outfits[skin_id]
        var available: bool = _unlocked_character(str(skin_id))
        var selected: bool = progress.character == skin_id
        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(450,106)
        card.add_theme_stylebox_override("panel",_panel_style("#2b2342" if selected else "#182d31", "#d6bd8b" if selected else "#55776f",14))
        gallery.add_child(card)
        var line: HBoxContainer = HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        card.add_child(line)
        var icon_name: String = "hero" if skin_id == "scout" or info.kind == "prestige" else "outfit_"+str(skin_id)
        var avatar: TextureRect = TextureRect.new()
        avatar.custom_minimum_size = Vector2(69,80)
        avatar.texture = load("res://art/%s.png" % icon_name)
        avatar.modulate = info.get("tint", Color.WHITE)
        avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        line.add_child(avatar)
        var details: VBoxContainer = VBoxContainer.new()
        details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(details)
        details.add_child(_make_label(str(info.name),17,"#ffe2af"))
        details.add_child(_make_label(str(info.perk),13,"#c5e6d7"))
        var requirement := str(info.requirement)
        if not available and int(progress.get("campaign_clears", 0)) < int(OUTFIT_CHAPTERS.get(skin_id, 0)):
            requirement = "Clear chapter %d" % int(OUTFIT_CHAPTERS[skin_id])
            if str(info.kind) in ["kills", "bosses"]:
                requirement += " and " + str(info.requirement).to_lower()
        details.add_child(_make_label(requirement,12,"#a7c5c0"))
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
    var ids: Array = BOSS_KINDS
    if encyclopedia_tab == "enemies":
        ids = ENEMY_ORDER.duplicate()
        ids.append_array(FieldPatterns.ROSTER.keys())
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
        copy.add_child(_make_label(("" + str(FieldPatterns.ROSTER[kind][1] if FieldPatterns.ROSTER.has(kind) else ENEMY_DESCRIPTIONS[kind])) if seen else "Encounter to reveal this entry",14,"#b7dad0"))
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
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.add_child(v)
    v.add_child(_make_label(key.replace("_"," "),16,"#ffe0aa",true))
    v.add_child(_make_label(description,13,"#c8e4d6"))

func _upgrades_reference_menu()->void:
    _heading("RUN UPGRADE ENCYCLOPEDIA")
    _section("GENERAL")
    for k in GENERAL_UPGRADES:_ency_upgrade_row(k,GENERAL_UPGRADES[k])
    for w in WEAPON_ORDER:
        _section(WEAPONS[w].name.to_upper()+" SPECIALTIES")
        var family: String = WEAPON_UPGRADE_FAMILY.get(w, w)
        for k in UNIQUE_UPGRADES[family]:_ency_upgrade_row(k,UNIQUE_UPGRADES[family][k])
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
        tab.custom_minimum_size = Vector2(0, 42)
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.add_theme_stylebox_override("normal", _panel_style("#38594c" if graphics_tab == tab_id else "#1b3439", "#d4b67e" if graphics_tab == tab_id else "#497476", 12))
        tab.add_theme_stylebox_override("hover", _panel_style("#527968", "#d4b67e", 12))
        tab.pressed.connect(Callable(self,"_change_settings_tab").bind(tab_id))
        tab_row.add_child(tab)
    if graphics_tab == "general":
        _section("GENERAL / ACCESSIBILITY")
        for item in [
            ["fps", "FPS COUNTER", "Display your current native frame rate."],
            ["weather", "DAY & WEATHER EFFECTS", "Rain, snow, fog and the host-synchronized cycle."],
            ["music", "SOUND / MUSIC", "Audio and original boss music."],
            ["novelty", "FAKE STINKY MERCH ADS", "Entirely fictional novelty pop-ups, off by default."]
        ]:
            var setting_key: String = str(item[0])
            var toggle: CheckButton = CheckButton.new()
            toggle.text = str(item[1]) + "    —    " + str(item[2])
            toggle.button_pressed = bool(settings.get(setting_key, false))
            toggle.custom_minimum_size.y = 46
            toggle.toggled.connect(Callable(self,"_set_general_option").bind(setting_key))
            main_layout.add_child(toggle)
        _section("PERFORMANCE")
        main_layout.add_child(_make_label("Default native frame cap: 120 FPS. Optional GPU effects are inactive unless you enable them. Leave expensive effects disabled to protect your 100 FPS baseline.", 14, "#c8e0c9"))
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
    _heading("WOODLAND WATCH  /  ADMIN CONSOLE")
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
        _focus_admin_field.call_deferred(admin_password_field)
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
        main_layout.add_child(_make_label("/unlockall    /unlockoriginal    /reset    /status    /help",13,"#b3dbcf",true))
        var log_panel: PanelContainer = PanelContainer.new()
        log_panel.add_theme_stylebox_override("panel",_panel_style("#0a1d25", "#486c77",10))
        main_layout.add_child(log_panel)
        var log_text: Label = _make_label("\n".join(PackedStringArray(admin_messages.slice(maxi(0,admin_messages.size()-8)))) if not admin_messages.is_empty() else "Ready. Use /help for available commands.",13,"#b8efdb",true)
        log_panel.add_child(log_text)
        _focus_admin_field.call_deferred(admin_command_field)
    _spacer(10)
    _menu_button("BACK",func():_show_page(admin_return_page),"muted")

func _focus_admin_field(control: Control) -> void:
    if is_instance_valid(control) and control.is_inside_tree():
        control.grab_focus()

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
    if command not in ["/reset", "/reset confirm"]:
        reset_confirmation_deadline = 0
    match command:
        "/help":
            response = "Commands: " + ", ".join(PackedStringArray(ADMIN_COMMANDS))
        "/status":
            response = "Override: %s  |  Real kills: %d  |  Best wave: %d  |  Real boss wins: %d" % ["ON" if admin_mode else "OFF",int(progress.kills),int(progress.best_wave),int(progress.boss_kills)]
        "/unlockall":
            response = _admin_unlock_all()
        "/unlockoriginal":
            response = _admin_unlock_original()
        "/reset":
            if dedicated_server or mode != "solo" or admin_return_page == "paused":
                response = "Return to the title and open Progress Tools to reset your local profile."
            else:
                reset_confirmation_deadline = Time.get_ticks_msec() + 30000
                response = "This clears local unlocks, XP, and chapter progress. Type /reset confirm within 30 seconds. A backup will be kept."
        "/reset confirm":
            response = _admin_reset_progress()
        _:
            response = "Unknown command: %s  (type /help)" % command
    admin_messages.append("> " + command + "  |  " + response)
    _show_page("admin")

func _admin_reset_progress() -> String:
    if dedicated_server or mode != "solo" or admin_return_page == "paused":
        return "Return to the title to reset your local profile."
    var ready := reset_confirmation_deadline > 0 and Time.get_ticks_msec() <= reset_confirmation_deadline
    reset_confirmation_deadline = 0
    if not ready:
        return "Type /reset before confirming."
    return _reset_local_profile(0)

func _reset_local_profile(prestige: int) -> String:
    var backup_path := "user://woodland_watch_before_reset_%d_%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
    var backup := FileAccess.open(backup_path, FileAccess.WRITE)
    if backup == null:
        return "Could not back up your profile. Progress was kept."
    backup.store_string(JSON.stringify({"progress": progress, "settings": settings, "admin_mode": admin_mode}))
    backup.flush()
    if backup.get_error() != OK:
        return "Could not finish writing the backup. Progress was kept."
    backup.close()
    var previous := progress
    var previous_override := admin_mode
    progress = _new_profile()
    progress.prestige = prestige
    progress.earned_weapons = {}
    progress.earned_skins = {}
    progress.earned_outfits = {}
    progress.unlock_rules_version = 2
    admin_mode = false
    _save_progress()
    _flush_progress()
    if save_dirty:
        progress = previous
        admin_mode = previous_override
        return "Could not save the reset. Backup: " + backup_path.get_file()
    selected_chapter = 1
    if prestige > 0:
        return "Prestige %d reached. Find your new skin in the Ranger Wardrobe." % prestige
    return "Local progress reset. Backup: " + backup_path.get_file()

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
    return "Everything unlocked for testing: operations, weapons, gun skins, outfits, and squirrel entries. Real progress backed up."

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
    _retain_legacy_licenses()
    _normalize_loadout_profile()
    _migrate_unlock_rules()
    _save_progress()
    _flush_progress()
    return "Original progression restored exactly from the pre-unlockall backup."

func _profile_tools_menu() -> void:
    _heading("PROGRESS TOOLS")
    main_layout.add_child(_make_label("Back up or move your local progress between Windows and browser play.", 16, "#b8ded4", true))
    _section("LEVEL %d / %d  ·  PRESTIGE %d / %d" % [_career_level(), RangerProgress.MAX_LEVEL, _prestige_rank(), RangerProgress.MAX_PRESTIGE])
    var prestige_button := _menu_button("PRESTIGE" if _prestige_rank() < RangerProgress.MAX_PRESTIGE else "MAX PRESTIGE", _request_prestige, "purple")
    prestige_button.disabled = not _can_prestige()
    var save_button := _menu_button("EXPORT SAVE JSON", _request_profile_export, "blue")
    var load_button := _menu_button("IMPORT SAVE JSON", _request_profile_import, "blue")
    save_button.disabled = not _profile_can_transfer()
    load_button.disabled = not _profile_can_transfer()
    var notice := profile_transfer_status
    if admin_mode:
        notice = "Run /unlockoriginal in the Admin Console before transferring progress."
    profile_status_label = _make_label(notice, 14, "#ffe0a5", true)
    main_layout.add_child(profile_status_label)
    if not OS.has_feature("web"):
        _menu_button("IMPORT ORIGINAL HTML PROGRESS", func(): import_dialog.popup_centered(Vector2i(900, 520)), "blue")
    _menu_button("ADMIN CONSOLE", func(): _open_admin("profile_tools"), "purple")
    _menu_button("BACK", func(): _show_page("title"), "muted")

func _operations_menu() -> void:
    _heading("WATCH OPERATIONS")
    var veteran := CheckButton.new()
    veteran.text = "Veteran  •  Stronger waves and extra rewards"
    veteran.button_pressed = bool(settings.get("veteran", false))
    veteran.toggled.connect(func(value: bool):
        settings.veteran = value
        _save_progress())
    main_layout.add_child(veteran)
    var cleared: int = int(progress.get("campaign_clears", 0))
    var last_available := Campaign.MISSIONS.size() if admin_mode else mini(cleared + 1, Campaign.MISSIONS.size())
    for index in range(Campaign.MISSIONS.size()):
        var chapter: Dictionary = Campaign.MISSIONS[index]
        var number := index + 1
        var suffix := "  [CLEARED]" if number <= cleared else ("  [LOCKED]" if number > last_available else "")
        var entry := _menu_button("%02d   %s%s" % [number, chapter.title, suffix], _select_operation.bind(number), "blue")
        entry.disabled = number > last_available
    _menu_button("BACK", func(): _show_page("title"), "muted")

func _select_operation(chapter: int) -> void:
    selected_chapter = chapter
    _clear_menu()
    var briefing: Dictionary = Campaign.MISSIONS[chapter - 1]
    _heading("%02d   %s" % [chapter, briefing.title])
    main_layout.add_child(_make_label(str(briefing.briefing), 18, "#d8efd4", true))
    var names: Array[String] = []
    for enemy in FieldPatterns.DEBUTS[chapter - 1]:
        names.append(FieldPatterns.ROSTER[enemy][0])
    main_layout.add_child(_make_label("New threats: " + " and ".join(names), 15, "#f5d598", true))
    var waves: Array[String] = []
    for objective in FieldPatterns.WAVE_OBJECTIVES[chapter - 1]:
        waves.append(FieldPatterns.OBJECTIVE_NAMES[objective])
    main_layout.add_child(_make_label("Waves: " + "  /  ".join(waves), 14, "#b7dad0", true))
    _spacer(14)
    _menu_button("DEPLOY SOLO", Callable(self, "_start_solo"))
    if not OS.has_feature("web"):
        _menu_button("HOST LAN CO-OP", Callable(self, "_start_host"), "blue")
    _menu_button("BACK TO OPERATIONS", func(): _show_page("operations"), "muted")

func _help_menu() -> void:
    _heading("RANGER FIELD GUIDE")
    if using_touch_layout():
        main_layout.add_child(_make_label("Use the left stick to move. Hold the right stick off center to aim and fire. Tap DASH, RELOAD or OPEN when you need them. MENU opens pause.", 18))
    main_layout.add_child(_make_label("WASD or arrows: move   •   Mouse: aim   •   Left click: shoot\nR: reload   •   Space: dash   •   E: open chest   •   Esc: menu", 17))
    _spacer(12)
    main_layout.add_child(_make_label("Follow each operation’s briefing. Gold marks the objective. Orange outlines mark incoming attacks; step or dash out before they flare. After the boss, return to the green marker.", 16))
    main_layout.add_child(_make_label("Stand beside a downed ranger for 2.5 seconds to revive them. Defeat after the repair sends the squad back to the boss checkpoint.", 16))
    main_layout.add_child(_make_label("Completing chapters unlocks weapons and fixed training. Pick up XP and acorns in the field to bank them after the operation.", 16))
    var chest_instruction := "Tap OPEN beside a chest" if using_touch_layout() else "Press E beside a chest"
    main_layout.add_child(_make_label(chest_instruction + ", then walk over the loot. Chest upgrades last for the operation. Acorns and XP are banked when you clear it.", 16))
    _menu_button("BACK", func(): _show_page("title"), "muted")

func _mission_complete_menu() -> void:
    var final_chapter := wave == Campaign.MISSIONS.size()
    _heading("THE FOREST IS SECURE" if final_chapter else "OPERATION COMPLETE")
    main_layout.add_child(_make_label(str(_mission().title), 24, "#f9dfa1", true))
    main_layout.add_child(_make_label("%d squirrels defeated   •   %d field XP   •   %d mission bonus acorns" % [
        stage_kills, _mission_reward_xp(), int(_mission().reward_acorns) + (18 if veteran_operation else 0)
    ], 16, "#c7ead2", true))
    if mode != "guest" or server_is_dedicated:
        _menu_button("REPLAY CAMPAIGN" if final_chapter else "CONTINUE TO NEXT OPERATION", Callable(self, "_advance_operation"))
    else:
        main_layout.add_child(_make_label("Waiting for the host to choose the next operation.", 16, "#c7ead2", true))
    _menu_button("MAIN MENU", Callable(self, "_return_menu"), "muted")



func _paused_menu()->void:
    _heading("PAUSED")
    _menu_button("RESUME",func():_show_page("playing"))
    _menu_button("SETTINGS",func():_open_settings("paused"),"blue")
    _menu_button("ADMIN CONSOLE",func():_open_admin("paused"),"purple")
    _menu_button("MAIN MENU",Callable(self,"_return_menu"),"muted")
    _menu_button("QUIT GAME",func():_request_exit("quit"),"muted")

func _defeated_menu() -> void:
    _heading("SQUAD DOWN")
    main_layout.add_child(_make_label("%02d  %s   •   %d squirrels defeated" % [
        wave, _mission().title, stage_kills
    ], 18, "#d9f0bd", true))
    if mode != "guest" or server_is_dedicated:
        _menu_button("RETRY FROM BOSS CHECKPOINT" if mission_checkpoint else "RETRY OPERATION", Callable(self, "_advance_operation"))
    else:
        main_layout.add_child(_make_label("Waiting for the host to retry.", 16, "#c7ead2", true))
    _menu_button("MAIN MENU", Callable(self, "_return_menu"), "muted")

func _objective_status() -> String:
    if wave <= 0:
        return ""
    match mission_phase:
        "travel":
            return "REACH  %s" % str(_mission().objective).to_upper()
        "guard":
            var title := "WAVE %d/%d  |  " % [encounter_wave, Campaign.APPROACH_WAVES[wave - 1]]
            if wave_break >= 0.0:
                return title + "REGROUP AND RELOAD"
            match _field_objective():
                "capture": return title + ("CLEAR THE CAPTURE RING" if capture_blocked else "CAPTURE THE OBJECTIVE  %ds" % ceili(guard_remaining))
                "flag": return title + ("BRING THE FLAG TO THE BEACON" if flag_carrier >= 0 else "PICK UP THE MARKED FLAG")
                "quota": return title + ("DEFEAT SQUIRRELS  %d/%d" % [mini(wave_kills, quota_goal), quota_goal])
                "salvage": return title + ("RECOVER FILTER CORES  %d/%d" % [salvage_collected, salvage_needed])
                "escort": return title + "STAY BESIDE THE PUMP CART"
                "relay": return title + "ACTIVATE THE MARKED RELAY"
                "hunt": return title + ("%d WARDENS REMAIN" % marked_remaining)
                "survive": return title + ("SURVIVE  %ds" % ceili(guard_remaining)) if guard_remaining > 0.0 else title + "CLEAR THE AMBUSH"
                "sabotage": return title + ("GROUND THE CAPACITOR  %ds" % ceili(guard_remaining))
                _: return title + ("HOLD THE MARKED SITE  %ds" % ceili(guard_remaining)) if guard_remaining > 0.0 else title + "CLEAR THE ATTACKERS"
        "boss":
            var callout := ""
            for enemy in enemies:
                if BOSS_KINDS.has(enemy.kind) and float(enemy.get("windup", 0.0)) > 0.0:
                    callout = "   |   INCOMING: " + str(enemy.get("pattern", ""))
                    break
            return boss_name + callout
        "secure":
            return "REGROUP AT  %s" % str(_mission().objective).to_upper()
    return "OPERATION COMPLETE"

func _update_hud()->void:
    if hud_left == null:
        return
    var local_player: Dictionary = players.get(local_id,{})
    if not local_player.is_empty():
        var hp_value: float = float(local_player.hp)
        var max_hp_value: float = maxf(1,float(local_player.max_hp))
        var left_text: String = "CHAPTER %02d  /  %s\nHP  %d/%d" % [wave, "CO-OP" if mode != "solo" else "SOLO", int(ceil(hp_value)), int(ceil(max_hp_value))]
        hud_enemy_count.text=str(enemies.size()+to_spawn)
        hud_kill_count.text=str(stage_kills)
        if hud_left.text != left_text: hud_left.text = left_text
        hud_hp_meter.update_meter(hp_value,max_hp_value)
        var gun_text: String = "%s  ·  %s" % [str(WEAPONS[local_player.weapon].name).to_upper(),str(local_player.skin)]
        if hud_right.text != gun_text: hud_right.text = gun_text
        hud_ammo_meter.update_meter(float(local_player.ammo),float(local_player.mag),float(local_player.reload))
        if using_touch_layout() and page == "playing":
            touch_controls.set_dash_cooldown(float(local_player.dash_cd))
        else:
            hud_dash_meter.update_meter(float(local_player.dash_cd), 2.6)
    hud_acorns_collected.text=str(run_acorns)
    hud_acorns_saved.text=str(int(progress.acorns))
    hud_best_wave.text=str(int(progress.get("campaign_clears", 0)))
    if hud_xp_meter!=null:
        var career_xp: int = int(progress.get("field_xp", 0))
        var capped := _career_level() == RangerProgress.MAX_LEVEL
        var xp_display := RangerProgress.XP_PER_LEVEL if capped else career_xp % RangerProgress.XP_PER_LEVEL
        hud_xp_meter.update_meter(float(xp_display), float(RangerProgress.XP_PER_LEVEL))
        hud_xp_label.text = "RANGER %d   ·   +%d FIELD XP ON CLEAR" % [_career_level(), roundi(run_xp)]
    var fps_text: String = "%d FPS" % int(Engine.get_frames_per_second()) if settings.get("fps",true) else ""
    if badge.text != fps_text: badge.text = fps_text
    var objective_text := _objective_status()
    if not local_player.is_empty() and local_player.hp <= 0.0 and page == "playing":
        objective_text = "DOWNED   ·   TEAMMATE NEEDED   %d%%" % roundi(40.0 * float(local_player.get("revive_time", 0.0)))
    if mission_label.text != objective_text:
        mission_label.text = objective_text
    var toast_text: String = toast_message if toast_timer > 0 else ""
    if message_label.text != toast_text: message_label.text = toast_text
    var active: Array[Dictionary] = upgrades_taken.duplicate()
    active.append_array(local_player.get("chest_upgrades", []))
    active = active.slice(-8)
    if hud_upgrade_box != null:
        hud_upgrade_box.visible = page == "playing" and not active.is_empty()
    var keys: Array[String] = []
    for item in active:
        keys.append("%s:%d" % [item.id, item.rarity])
    if keys != displayed_upgrade_keys:
        displayed_upgrade_keys = keys
        for child in hud_upgrades.get_children():
            hud_upgrades.remove_child(child)
            child.queue_free()
        for option in active:
            var rarity: int = clampi(int(option.get("rarity",0)),0,RARITY_COLORS.size()-1)
            var upgrade_id: String = str(option.get("id",""))
            var b: Button = Button.new()
            b.icon = load("res://art/encyclopedia/upgrades/%s.png" % upgrade_id)
            b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
            b.expand_icon = true
            b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            b.custom_minimum_size = Vector2(42,38)
            b.add_theme_font_size_override("font_size",18)
            b.add_theme_color_override("font_color",Color(RARITY_COLORS[rarity]))
            b.add_theme_stylebox_override("normal",_panel_style("#102a2c",RARITY_COLORS[rarity],11))
            b.add_theme_stylebox_override("hover",_panel_style("#1a4444",RARITY_COLORS[rarity],11))
            b.tooltip_text = "[%s] %s\n%s" % [RARITY_NAMES[rarity],upgrade_id.replace("_"," "),str(upgrade_catalog.get(upgrade_id, ""))]
            b.focus_mode = Control.FOCUS_ALL
            hud_upgrades.add_child(b)
