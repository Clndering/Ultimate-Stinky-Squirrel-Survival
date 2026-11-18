extends Node2D

const RangerProgress := preload("res://scripts/RangerProgress.gd")
## Native CanvasItem renderer using the EXACT source PNG files from the latest HTML.
## Isometric projection, scale, terrain hash, and sprite draw rectangles follow the HTML.

const MAP := 192.0
const C := Vector2(640.0, 368.0)
const ART := ["acorn", "xp", "boss", "bruiser", "bush", "grass_0", "grass_1", "grass_2", "grass_3", "hero", "hero_left", "mud", "speedy", "squirrel", "stone", "toxic", "tree", "tree_autumn", "outfit_trailblazer", "outfit_trailblazer_left", "outfit_sharpsight", "outfit_sharpsight_left", "outfit_ironbark", "outfit_ironbark_left", "outfit_cindercloak", "outfit_cindercloak_left", "outfit_frostbound", "outfit_frostbound_left"]

const FieldPatterns = preload("res://scripts/FieldPatterns.gd")
const SHOT_COLOR := {"spark": Color("#ffcf72"), "arc": Color("#d7a9ff"), "needle_shot": Color("#ff9489"), "ice": Color("#82e8ff"), "poison": Color("#a7ed77")}

var game
var art: Dictionary = {}
var terrain_atlas: ImageTexture
var ground_mesh: ArrayMesh
var ground_anchor := Vector2i.ZERO
var ground_cache: Dictionary = {}
var ground_marks := PackedVector2Array()
const GROUND_KEYS := ["grass_0", "grass_1", "grass_2", "grass_3", "mud", "stone"]
var tile_offsets: Array[Vector2i] = []
var tile_centers := PackedVector2Array()
var tile_uvs: Array[Vector4] = []
var ground_geometry: Array = []
var terrain_regions: Dictionary = {}
var gun_art: Dictionary = {}
var upgrade_icons: Dictionary = {}
var gun_glow_art: Dictionary = {}

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for key in ART:
        art[key] = load("res://art/%s.png" % key)
    _build_terrain_atlas()
    for weapon_id in game.WEAPON_ORDER:
        var styles: Array = game.SKIN_OPTIONS[weapon_id]
        for i in range(styles.size()):
            gun_art["%s_%d" % [weapon_id,i]] = load("res://ui/guns/%s_%d.png" % [weapon_id,i])
            if i > 0:
                gun_glow_art["%s_%d" % [weapon_id,i]] = load("res://ui/guns/glows/%s_%d.png" % [weapon_id,i])

func _build_terrain_atlas() -> void:
    var atlas := Image.create_empty(768, 128, false, Image.FORMAT_RGBA8)
    for i in range(GROUND_KEYS.size()):
        var tile: Image = art[GROUND_KEYS[i]].get_image()
        if tile == null or tile.get_width() > 126 or tile.get_height() > 126:
            return
        tile.convert(Image.FORMAT_RGBA8)
        var offset := Vector2i(i * 128 + 1, 1)
        var bounds := Rect2i(Vector2i.ZERO, tile.get_size())
        atlas.blit_rect(tile, bounds, offset)
        terrain_regions[GROUND_KEYS[i]] = Rect2(Vector2(offset), Vector2(tile.get_size()))
    terrain_atlas = ImageTexture.create_from_image(atlas)
    var atlas_size := terrain_atlas.get_size()
    for key in GROUND_KEYS:
        var region: Rect2 = terrain_regions[key]
        var top := region.position / atlas_size
        var bottom := region.end / atlas_size
        tile_uvs.append(Vector4(top.x, top.y, bottom.x, bottom.y))
    _prepare_ground_geometry()

func delta_toroid(d: float) -> float:
    return fposmod(d + MAP * 0.5, MAP) - MAP * 0.5

func iso(v: Vector2) -> Vector2:
    return Vector2((v.x - v.y) * 32.0, (v.x + v.y) * 16.0)

func screen_point(v: Vector2, focus: Vector2) -> Vector2:
    return C + iso(Vector2(delta_toroid(v.x - focus.x), delta_toroid(v.y - focus.y)))

func texture_rect(key: String, rect: Rect2, alpha: float = 1.0) -> void:
    if art.has(key):
        draw_texture_rect(art[key], rect, false, Color(1, 1, 1, alpha))

func sprite_region(key: String, src: Rect2, dst: Rect2, alpha: float = 1.0, tint: Color = Color.WHITE) -> void:
    if art.has(key):
        draw_texture_rect_region(art[key], dst, src, Color(tint, alpha))

func shadow(p: Vector2, radius: Vector2, opacity: float = 0.32) -> void:
    draw_set_transform(p, 0.0, Vector2(1.0, max(0.1, radius.y / radius.x)))
    draw_circle(Vector2.ZERO, radius.x, Color(0.02, 0.08, 0.07, opacity))
    draw_set_transform(Vector2.ZERO)

# Godot CanvasItem has circles but no guaranteed built-in ellipse draw call.
# This helper draws a flat ellipse without allocating polygon arrays every frame.
func _draw_pixel_ellipse(center: Vector2, rx: float, ry: float, tint: Color) -> void:
    if rx <= 0.0 or ry <= 0.0:
        return
    draw_set_transform(center,0.0,Vector2(1.0,ry/rx))
    draw_circle(Vector2.ZERO,rx,tint)
    draw_set_transform(Vector2.ZERO)

func hash_tile(x: int, y: int) -> int:
    return ((x * 73856093) ^ (y * 19349663) ^ 92821) & 0x7fffffff

func ground_kind(x: int, y: int) -> String:
    return GROUND_KEYS[_ground_tile(x, y, hash_tile(x, y))]

func _ground_tile(x: int, y: int, hash_value: int) -> int:
    var dx := x - 27
    var dy := y - 27
    if dx * dx + dy * dy >= 64:
        if hash_value % 17 == 3:
            return 4
        if hash_value % 23 == 9:
            return 5
    return hash_value % 4

func _draw_ground(focus: Vector2) -> void:
    var anchor := Vector2i(floori(focus.x / 4.0) * 4, floori(focus.y / 4.0) * 4)
    if terrain_atlas == null:
        _draw_ground_fallback(focus)
        return
    if ground_mesh == null or ground_anchor != anchor:
        if ground_cache.has(anchor):
            var cached: Array = ground_cache[anchor]
            ground_anchor = anchor
            ground_mesh = cached[0]
            ground_marks = cached[1]
        else:
            _rebuild_ground(anchor)
            if ground_cache.size() >= 8:
                ground_cache.erase(ground_cache.keys()[0])
            ground_cache[anchor] = [ground_mesh, ground_marks]
    var shift := -iso(focus - Vector2(anchor))
    if ground_mesh.get_surface_count() > 0:
        draw_mesh(ground_mesh, terrain_atlas, Transform2D(0.0, shift))
    for mark in ground_marks:
        draw_rect(Rect2(mark + shift + Vector2(8, -6), Vector2(3, 3)), Color("#5f7e57"))

func _prepare_ground_geometry() -> void:
    var vertices := PackedVector2Array()
    var indices := PackedInt32Array()
    var bound := Rect2(-196, -174, 1672, 1068)
    for diagonal in range(-36, 37):
        var first := floori(float(diagonal - 29) * .5)
        var last := ceili(float(diagonal + 29) * .5)
        for x in range(first, last + 1):
            var y := diagonal - x
            var center := C + iso(Vector2(x, y))
            if not bound.has_point(center):
                continue
            tile_offsets.append(Vector2i(x, y))
            tile_centers.append(center)
            var top := center + Vector2(-32, -16)
            var index := vertices.size()
            vertices.append(top)
            vertices.append(top + Vector2(64, 0))
            vertices.append(top + Vector2(64, 40))
            vertices.append(top + Vector2(0, 40))
            indices.append_array(PackedInt32Array([index, index + 1, index + 2, index, index + 2, index + 3]))
    ground_geometry.resize(Mesh.ARRAY_MAX)
    ground_geometry[Mesh.ARRAY_VERTEX] = vertices
    ground_geometry[Mesh.ARRAY_INDEX] = indices

func _rebuild_ground(anchor: Vector2i) -> void:
    ground_anchor = anchor
    ground_marks.clear()
    var uvs := PackedVector2Array()
    uvs.resize(tile_offsets.size() * 4)
    for tile in range(tile_offsets.size()):
        var offset := tile_offsets[tile]
        var x := posmod(anchor.x + offset.x, int(MAP))
        var y := posmod(anchor.y + offset.y, int(MAP))
        var tile_hash := hash_tile(x, y)
        var region := tile_uvs[_ground_tile(x, y, tile_hash)]
        var top := Vector2(region.x, region.y)
        var bottom := Vector2(region.z, region.w)
        var index := tile * 4
        uvs[index] = top
        uvs[index + 1] = Vector2(bottom.x, top.y)
        uvs[index + 2] = bottom
        uvs[index + 3] = Vector2(top.x, bottom.y)
        if tile_hash % 37 == 0:
            ground_marks.append(tile_centers[tile])
    ground_geometry[Mesh.ARRAY_TEX_UV] = uvs
    ground_mesh = ArrayMesh.new()
    ground_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ground_geometry, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)

func _draw_ground_fallback(focus: Vector2) -> void:
    # Draw only the projected diamonds actually visible. Cached textures are GPU-native.
    # Bound the visible isometric diamonds analytically (about 1500 candidates,
    # not a 67x67 square scan) without changing their exact pixel coordinates.
    var tile_sum := focus.x + focus.y
    var tile_difference := focus.x - focus.y
    for diagonal in range(int(floor(tile_sum - 29)), int(ceil(tile_sum + 29))):
        var first_x := int(floor((float(diagonal) + tile_difference - 26.0) * .5))
        var last_x := int(ceil((float(diagonal) + tile_difference + 26.0) * .5))
        for xi in range(first_x,last_x+1):
            var yi := diagonal-xi
            var p := C + iso(Vector2(float(xi) - focus.x, float(yi) - focus.y))
            if p.x < -70 or p.x > 1350 or p.y < -70 or p.y > 780:
                continue
            var wx := posmod(xi, int(MAP))
            var wy := posmod(yi, int(MAP))
            var tile := ground_kind(wx, wy)
            var rect := Rect2(p.x - 32, p.y - 16, 64, 40)
            if terrain_atlas != null:
                draw_texture_rect_region(terrain_atlas, rect, terrain_regions[tile])
            else:
                texture_rect(tile, rect)
            if hash_tile(wx, wy) % 37 == 0:
                draw_rect(Rect2(p.x + 8, p.y - 6, 3, 3), Color("5f7e57"))

func _draw() -> void:
    if game == null:
        return
    draw_rect(Rect2(0, 0, 1280, 720), Color("172f38"))
    var focus: Vector2 = game.camera_pos
    _draw_ground(focus)

    _draw_operation_site(focus)
    _draw_encounter_zones(focus)
    var drawables: Array[Dictionary] = []
    if game.page == "playing":
        var local: Dictionary = game.players.get(game.local_id, {})
        var interact := -1
        if not local.is_empty() and local.hp > 0.0:
            interact = game._nearest_chest(local.pos)
        for index in range(game.field_chests.size()):
            var chest: Dictionary = game.field_chests[index]
            var point := screen_point(chest.pos, focus)
            if Rect2(-60, -65, 1400, 845).has_point(point):
                drawables.append({"y": point.y, "kind": "field_chest", "p": point, "source": chest, "active": index == interact})
        for loot in game.field_upgrade_drops:
            var point := screen_point(loot.pos, focus)
            if Rect2(-35, -50, 1350, 820).has_point(point):
                drawables.append({"y": point.y, "kind": "chest_perk", "p": point, "source": loot})
    for o in game.nearby_obstacles(focus,34):
        var p := screen_point(o.pos, focus)
        if p.x < -110 or p.x > 1390 or p.y < -140 or p.y > 840:
            continue
        drawables.append({"y":p.y, "kind":o.kind, "p":p, "source":o})
    for a in game.drops:
        var p := screen_point(a.pos, focus)
        if Rect2(-28, -30, 1336, 780).has_point(p):
            drawables.append({"y":p.y-1, "kind":"acorn", "p":p, "source":a})
    for shard in game.xp_drops:
        var p := screen_point(shard.pos,focus)
        if p.x > -40 and p.x < 1320 and p.y > -40 and p.y < 760:
            drawables.append({"y":p.y-1,"kind":"xp","p":p,"source":shard})
    # Traveling stinky-air globs use the original isometric camera and layer
    # alongside the world entities rather than fake full-screen laser lines.
    for blob in game.enemy_blobs:
        var position: Vector2 = game.render_bullet_position(blob)
        var p := screen_point(position, focus) + Vector2(0, -5.0 if blob.get("pattern_shot", false) else -20.0)
        if p.x < -40 or p.x > 1320 or p.y < -40 or p.y > 760:
            continue
        drawables.append({"y":p.y, "kind":"stink_blob", "p":p, "source":blob})
    for hz in game.hazards:
        var p := screen_point(hz.pos, focus)
        if Rect2(0, 0, 1280, 720).grow(float(hz.radius) + 12.0).has_point(p):
            drawables.append({"y":p.y-2, "kind":"hazard", "p":p, "source":hz})
    var locator_needed := true
    var locator_positions := PackedVector2Array()
    var locator_distances := PackedFloat32Array()
    for e in game.enemies:
        var p := screen_point(game.render_enemy_position(e), focus)
        if locator_needed and e.hp > 0:
            var distance := p.distance_squared_to(C)
            if distance <= 625.0 * 625.0:
                locator_needed = false
            else:
                var index := 0
                while index < locator_distances.size() and locator_distances[index] <= distance:
                    index += 1
                if index < 3:
                    locator_distances.insert(index, distance)
                    locator_positions.insert(index, p)
                    if locator_positions.size() > 3:
                        locator_distances.resize(3)
                        locator_positions.resize(3)
        if p.x < -160 or p.x > 1440 or p.y < -150 or p.y > 850:
            continue
        drawables.append({"y":p.y + 0.05, "kind":"enemy", "p":p, "source":e})
    for id in game.players.keys():
        var player: Dictionary = game.players[id]
        var position: Vector2 = game.render_player_position(id, player.pos)
        var p := screen_point(position, focus)
        drawables.append({"y":p.y + 0.2, "kind":"player", "p":p, "source":player, "id":id})
    drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
    for item in drawables:
        var k: String = item.kind
        var p: Vector2 = item.p
        var src: Dictionary = item.source
        if k == "tree":
            shadow(p, Vector2(24, 11))
            var tree_id := "tree_autumn" if hash_tile(int(src.pos.x), int(src.pos.y)) % 4 == 0 else "tree"
            var h := hash_tile(int(src.pos.x),int(src.pos.y))
            var sway := sin(game.elapsed * 1.8 + float(h % 9)) * (5.2 if game.weather == "wind" else 2.7)
            texture_rect(tree_id, Rect2(p.x - 45 + sway, p.y - 126, 90, 133))
        elif k == "rock":
            shadow(p, Vector2(19, 8), 0.4)
            draw_colored_polygon(PackedVector2Array([p+Vector2(-21, -3), p+Vector2(-16, -19), p+Vector2(-3, -28), p+Vector2(15, -21), p+Vector2(21, -7), p+Vector2(8, 1), p+Vector2(-14, 0)]), Color("5b6870"))
            draw_line(p+Vector2(-16, -19), p+Vector2(2, -21), Color("849198"), 3)
        elif k == "stump":
            shadow(p, Vector2(14, 7))
            draw_rect(Rect2(p.x-11, p.y-22, 22, 20), Color("5b3e29"))
            _draw_pixel_ellipse(p + Vector2(0,-19), 11.0, 6.0, Color("987b4d"))
        elif k == "field_chest":
            _draw_chest(p, src.rarity, item.active)
        elif k == "chest_perk":
            _draw_chest_perk(p, src)
        elif k == "acorn":
            texture_rect("acorn", Rect2(p.x - 12, p.y - 23 + sin(game.elapsed * 4 + float(src.get("age",0.0)) * 2) * 2, 24,25))
        elif k == "xp":
            var bob: float = sin(game.elapsed*7.0 + float(src.age)*4.0)*2.0
            texture_rect("xp",Rect2(p.x-9.0,p.y-23.0+bob,18,18))
        elif k == "stink_blob":
            draw_stink_blob(src,p)
        elif k == "hazard":
            var lifetime: float = max(0.01, src.life)
            var alpha: float = clampf(1.0 - src.age/lifetime,0.0,1.0)
            var color := Color(0.56,0.86,1,0.22 * alpha) if src.kind == "ice" else Color(0.4,0.9,0.3,0.22*alpha)
            _draw_pixel_ellipse(p + Vector2(0,-10), float(src.radius), float(src.radius) * 0.48, color)
        elif k == "enemy":
            draw_enemy(src,p)
        elif k == "player":
            draw_player(src, p, item.id == game.local_id)
            if game.mission_phase == "guard" and game._field_objective() == "flag" and game.flag_carrier == item.id and not game.flag_delivered:
                _draw_flag(p + Vector2(23, -49))

    for trace in game.traces:
        var offset := screen_point(trace.get("focus", focus), focus) - C
        draw_line(trace.start + offset, trace.end + offset, trace.tint, max(1.0,trace.width))
    for particle in game.particles:
        var fade: float = clampf(1.0 - particle.age / max(particle.life,.01),0,1)
        var color: Color = particle.tint
        color.a = fade
        var offset := screen_point(particle.get("focus", focus), focus) - C
        var point: Vector2 = particle.pos + offset
        if Rect2(-12, -12, 1304, 744).has_point(point):
            draw_rect(Rect2(point, Vector2(particle.size,particle.size)), color)
    _draw_operation_waypoint(focus)
    if locator_needed:
        var colors := [Color("ffcf6d"),Color("78e0ec"),Color("e8a6fa")]
        for i in range(locator_positions.size()):
            var d := locator_positions[i] - C
            var u:Vector2=d.normalized()
            var v:Vector2=Vector2(-u.y,u.x)
            var margin := (i-1)*40.0
            var here := C+u*minf(140,d.length())+v*margin
            draw_colored_polygon(PackedVector2Array([here+u*21,here-u*13-v*10,here-u*7,here-u*13+v*10]),colors[i])
    # Atmosphere: lightweight native canvas tint, not an added browser upload.
    var day: float = game.day_phase
    var dusk := pow(1.0 - absf(cos(day * TAU)), 3.0)
    draw_rect(Rect2(0, 0, 1280, 720), Color(.95, .43, .16, dusk * .11))
    var night: float = (1.0 - sin(day * TAU - PI * 0.5)) * 0.5
    draw_rect(Rect2(0,0,1280,720), Color(0.04,0.1,0.26,night * 0.21))
    var ticks: int = int(game.elapsed * 100.0)
    if game.weather == "clear":
        for i in range(13):
            var dust := Vector2((i * 171 + ticks / 5) % 1280, (i * 313 + ticks / 12) % 720)
            draw_rect(Rect2(dust, Vector2(2, 2)), Color(.93, .96, .54, .18 + .13 * sin(float(ticks + i * 17) * .036)))
    if game.weather == "rain":
        for i in range(56):
            var rx: float = float((i * 131 + ticks * 3) % 1280)
            var ry: float = float((i * 277 + ticks * 7) % 720)
            draw_line(Vector2(rx,ry), Vector2(rx-6,ry+15), Color(0.67,0.83,0.94,0.30),1.0)
    elif game.weather == "snow":
        for i in range(32):
            var sx: float = float((i * 157 + ticks / 6) % 1280)
            var sy: float = float((i * 229 + ticks / 3) % 720)
            draw_circle(Vector2(sx,sy),1.2,Color(0.86,0.95,1.0,0.54))
    elif game.weather == "wind":
        for i in range(20):
            var wx: float = float((i * 167 + ticks * 2) % 1280)
            var wy: float = float((i * 237 + ticks / 2) % 720)
            draw_line(Vector2(wx,wy),Vector2(wx+25,wy-7),Color(0.77,0.93,0.82,0.13),1.0)
    elif game.weather == "mist":
        draw_rect(Rect2(0,0,1280,720),Color(0.55,0.71,0.67,0.055))


func _draw_chest(point: Vector2, rarity: int, active: bool) -> void:
    var tint := Color(game.RARITY_COLORS[rarity])
    shadow(point, Vector2(23, 9), .48)
    var base := point.round()
    if active:
        draw_arc(base, 33.0, 0.0, TAU, 28, Color(tint, .72), 2.0)
    draw_rect(Rect2(base + Vector2(-21, -19), Vector2(42, 19)), Color("#302735"))
    draw_rect(Rect2(base + Vector2(-19, -17), Vector2(38, 15)), Color("#8d5b3f"))
    draw_rect(Rect2(base + Vector2(-21, -25), Vector2(42, 9)), Color("#382d35"))
    draw_rect(Rect2(base + Vector2(-18, -24), Vector2(36, 5)), Color("#b87c51"))
    for offset in [-14.0, 11.0]:
        draw_rect(Rect2(base + Vector2(offset, -24), Vector2(3, 22)), tint.darkened(.42))
    draw_rect(Rect2(base + Vector2(-5, -18), Vector2(10, 8)), Color("#241f2b"))
    draw_rect(Rect2(base + Vector2(-3, -18), Vector2(6, 5)), tint)
    if active:
        var action := "TAP OPEN  " if game.using_touch_layout() else "E  OPEN "
        var text := action + str(game.RARITY_NAMES[rarity]).to_upper()
        draw_rect(Rect2(base + Vector2(-82, -52), Vector2(164, 22)), Color("#152528"))
        draw_string(ThemeDB.fallback_font, base + Vector2(-82, -36), text, HORIZONTAL_ALIGNMENT_CENTER, 164, 13, tint)

func _draw_chest_perk(point: Vector2, drop: Dictionary) -> void:
    var tint := Color(game.RARITY_COLORS[drop.rarity])
    var id: String = drop.id
    if not upgrade_icons.has(id):
        upgrade_icons[id] = load("res://art/encyclopedia/upgrades/%s.png" % id)
    var p := (point + Vector2(0, -17.0 + 3.0 * sin(float(game.elapsed) * 5.0))).round()
    shadow(point, Vector2(14, 6), .4)
    draw_rect(Rect2(p - Vector2(16, 16), Vector2(32, 32)), Color("#15262f"))
    draw_rect(Rect2(p - Vector2(16, 16), Vector2(32, 32)), tint, false, 2.0)
    var icon: Texture2D = upgrade_icons[id]
    if icon != null:
        draw_texture_rect(icon, Rect2(p - Vector2(12, 12), Vector2(24, 24)), false)

func _draw_encounter_zones(focus: Vector2) -> void:
    if game.page != "playing":
        return
    for core in game.field_salvage:
        var p := screen_point(core, focus)
        if Rect2(-20, -20, 1320, 760).has_point(p):
            draw_circle(p, 15.0, Color(0.3, 1.0, 0.85, .18))
            texture_rect("xp", Rect2(p + Vector2(-11, -24), Vector2(22, 26)))
    for zone in game.warning_zones:
        _draw_attack_zone(zone, focus, false)
    for zone in game.warning_impacts:
        _draw_attack_zone(zone, focus, true)

func _draw_attack_zone(zone: Dictionary, focus: Vector2, impact: bool) -> void:
    var p := screen_point(zone.pos, focus)
    var size: float = zone.size
    var ratio := 1.0 - clampf(float(zone.time) / float(zone.duration), 0.0, 1.0)
    var edge := Color("#fff5b4") if impact else Color("#ffa254").lerp(Color("#ff6652"), ratio)
    var fill := Color(edge, .45 if impact else .11 + ratio * .26)
    if zone.shape == "line":
        var endpoint: Vector2 = p + zone.dir * float(zone.length)
        var side: Vector2 = zone.dir.orthogonal() * size
        draw_colored_polygon(PackedVector2Array([p - side, endpoint - side, endpoint + side, p + side]), fill)
        draw_line(p - side, endpoint - side, edge, 2.0)
        draw_line(p + side, endpoint + side, edge, 2.0)
        draw_line(endpoint - side, endpoint + side, edge, 2.0)
    elif zone.shape == "ring":
        draw_arc(p, size, 0.0, TAU, 48, fill, 44.0)
        draw_arc(p, size - 22.0, 0.0, TAU, 44, edge, 2.0)
        draw_arc(p, size + 22.0, 0.0, TAU, 48, edge, 2.0)
    else:
        draw_circle(p, size, fill)
        draw_arc(p, size, 0.0, TAU, 36, edge, 3.0)
        if not impact:
            draw_arc(p, size * maxf(.08, 1.0 - ratio), 0.0, TAU, 28, Color(edge, .75), 1.0)

func _draw_operation_site(focus: Vector2) -> void:
    if game.wave <= 0 or game.mission_phase == "complete":
        return
    var site: Vector2 = game._field_site()
    var point := screen_point(site, focus)
    if not Rect2(-130, -130, 1540, 980).has_point(point):
        return
    var color := Color("#ffd482") if game.mission_phase in ["travel", "guard"] else Color("#8cecc4")
    var objective: String = game._field_objective() if game.mission_phase == "guard" else ""
    if objective in ["survive", "salvage", "hunt", "quota"]:
        return
    if objective == "flag":
        if game.flag_carrier < 0 and not game.flag_delivered:
            _draw_flag(point)
            return
        color = Color("#8cecc4")
    elif objective == "capture" and game.capture_blocked:
        color = Color("#ff9a6f")
    var radius: float = 50.0 if objective == "flag" else game.SITE_RADIUS
    _draw_pixel_ellipse(point, radius, radius, Color(color, .07))
    draw_arc(point, radius, 0.0, TAU, 52, Color(color, .53), 2.0, true)
    _draw_pixel_ellipse(point, 33.0, 16.0, Color("#23382d"))
    if objective == "escort":
        for wheel in [-19.0, 19.0]:
            draw_circle(point + Vector2(wheel, 2.0), 8.0, Color("#28353a"))
            draw_circle(point + Vector2(wheel, 2.0), 3.0, color)
    draw_rect(Rect2(point + Vector2(-15, -32), Vector2(30, 38)), Color("#242d29"))
    draw_rect(Rect2(point + Vector2(-12, -29), Vector2(24, 31)), Color("#665340"))
    draw_rect(Rect2(point + Vector2(-20, -34), Vector2(40, 8)), Color("#a38257"))
    draw_rect(Rect2(point + Vector2(-7, -24), Vector2(14, 15)), color)
    draw_circle(point + Vector2(0, -16), 24, Color(color, .14))
    if game.mission_phase == "guard" and game.guard_remaining > 0.0:
        var total := (4.0 + float(game.encounter_wave)) if objective == "capture" else (float(game._mission().guard_seconds) * .65 + float(game.encounter_wave - 1) * 2.0)
        var repaired := 1.0 - clampf(game.guard_remaining / total, 0.0, 1.0)
        draw_rect(Rect2(point + Vector2(-32, -46), Vector2(64, 7)), Color("#18272a"))
        draw_rect(Rect2(point + Vector2(-30, -44), Vector2(60.0 * repaired, 3)), color)

func _draw_flag(point: Vector2) -> void:
    var flutter := sin(float(game.elapsed) * 9.0) * 4.0
    draw_line(point, point + Vector2(0, -41), Color("#fbedb9"), 3.0)
    draw_colored_polygon(PackedVector2Array([point + Vector2(1, -40),
        point + Vector2(29, -36 + flutter), point + Vector2(22, -26 + flutter),
        point + Vector2(1, -23)]), Color("#7ce5c9"))
    draw_rect(Rect2(point + Vector2(3, -36), Vector2(5, 8)), Color("#e7ffe1"))

func _draw_operation_waypoint(focus: Vector2) -> void:
    if game.wave <= 0 or game.mission_phase not in ["travel", "guard", "secure"]:
        return
    var site: Vector2 = game._field_site()
    if game.mission_phase == "guard":
        var objective: String = game._field_objective()
        if objective in ["survive", "quota"]:
            return
        if objective == "hunt":
            for enemy in game.enemies:
                if enemy.get("marked", false):
                    site = enemy.pos
                    break
        elif objective == "salvage" and not game.field_salvage.is_empty():
            site = game.field_salvage[0]
    var projected := screen_point(site, focus) + Vector2(0, -61)
    var point := projected.clamp(Vector2(86, 112), Vector2(1194, 565))
    var toward: Vector2 = (projected - point).normalized() if projected != point else Vector2.DOWN
    var side := toward.orthogonal()
    draw_circle(point, 16, Color("#1a2d29"))
    draw_colored_polygon(PackedVector2Array([
        point + toward * 11.0, point - toward * 7.0 + side * 7.0,
        point - toward * 4.0, point - toward * 7.0 - side * 7.0
    ]), Color("#ffdc8b"))

func draw_enemy(e: Dictionary, p: Vector2) -> void:
    var kind: String = e.kind
    var boss: bool = game.BOSS_KINDS.has(kind)
    var mult := 1.75 if boss else (1.23 if kind in ["armored","guard"] else 1.0)
    if kind in ["nutpocalypse", "weaver"]:
        mult = 2.25
    var key := "squirrel"
    if kind in ["speedy","skirmisher"]: key = "speedy"
    elif kind in ["toxic","toxicboss","spitter","healer"]: key = "toxic"
    elif kind in ["armored","guard","burrower"]: key = "bruiser"
    elif boss: key = "boss"
    elif kind in ["charger", "stalker", "wisp"]: key = "speedy"
    elif kind in ["bulwark", "splitter"]: key = "bruiser"
    elif kind == "grenadier": key = "toxic"
    var variant: Array = FieldPatterns.ROSTER.get(kind, [])
    if not variant.is_empty():
        if variant[2] >= 120:
            key = "bruiser"
            mult = 1.14
        elif variant[6] in ["strafe", "orbit"]:
            key = "speedy"
        elif variant[5] in ["fan", "pod", "snare"]:
            key = "toxic"
    var w := 59.0 * mult
    var h := 72.0 * mult
    var bob := sin(float(e.get("bob",0))) * 2.3
    shadow(p, Vector2(18*mult,9*mult))
    texture_rect(key, Rect2(p.x-w/2, p.y-h+bob,w,h), 0.65 if float(e.get("hit",0))>0 else 1.0)
    if not variant.is_empty():
        _draw_field_enemy_mark(p + Vector2(0, -h + bob), variant)
    if e.get("marked", false) or e.get("core", false):
        var badge_color := Color("#ffdf80") if e.get("marked", false) else Color("#79ffdf")
        var tip := p + Vector2(0, -h - 28.0)
        draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-8, -9), tip + Vector2(0, -17), tip + Vector2(8, -9)]), badge_color)
    if float(e.get("windup", 0.0)) > 0.0:
        draw_arc(p + Vector2(0, -h * .58), w * .55, 0.0, TAU, 24, Color("#ffc481"), 2.5)
    if boss:
        var acc := Color("f7dd82")
        if kind == "toxicboss": acc = Color("a3fb69")
        elif kind == "frostboss": acc = Color("9fe8ff")
        elif kind == "stormboss": acc = Color("c7afff")
        elif kind == "nutpocalypse": acc = Color("ff9c65")
        draw_arc(p+Vector2(0,-h+10),13*mult,0,TAU,12,acc,3.0)
        if kind in ["king","council"]:
            draw_colored_polygon(PackedVector2Array([p+Vector2(-20,-h+14),p+Vector2(-14,-h-7),p+Vector2(-3,-h+9),p+Vector2(10,-h-14),p+Vector2(20,-h+11)]),acc)
        elif kind == "weaver":
            for a in range(6):
                draw_line(p+Vector2(-38+a*15,-h*.42),p+Vector2(-60+a*24,-h*.18),Color("d9c6f3"),3)
    if float(e.get("burn",0))>0:
        draw_circle(p+Vector2(10,-34),6,Color(1,0.43,0.13,0.9))
    if float(e.get("chill",0))>0:
        draw_arc(p+Vector2(0,-h*.45),w*.48,0,TAU,24,Color("9ee8ff"),2)
    if e.hp < e.max_hp:
        draw_rect(Rect2(p.x-24, p.y-h-11,48,6),Color("513039"))
        draw_rect(Rect2(p.x-24,p.y-h-11,48*clampf(e.hp/maxf(1,e.max_hp),0,1),6),Color("f6d081"))

func _draw_field_enemy_mark(p: Vector2, profile: Array) -> void:
    var tint := Color(profile[7])
    var border := Color("#202934")
    var style: String = profile[6]
    if style == "anchor":
        draw_rect(Rect2(p + Vector2(-17, 4), Vector2(27, 11)), border)
        draw_rect(Rect2(p + Vector2(-14, 6), Vector2(20, 4)), tint)
        draw_rect(Rect2(p + Vector2(-3, 1), Vector2(5, 12)), tint)
    elif style == "orbit":
        draw_line(p + Vector2(-19, 15), p + Vector2(17, 26), border, 6.0)
        draw_line(p + Vector2(-18, 15), p + Vector2(15, 25), tint, 3.0)
        draw_rect(Rect2(p + Vector2(11, 22), Vector2(7, 6)), tint)
    elif style == "strafe":
        draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 14), p + Vector2(13, 14), p + Vector2(-6, 24)]), border)
        draw_line(p + Vector2(-14, 16), p + Vector2(10, 16), tint, 3.0)
    else:
        for spike in [-12.0, -2.0, 8.0]:
            draw_rect(Rect2(p + Vector2(spike, 10.0), Vector2(6, 10)), border)
            draw_rect(Rect2(p + Vector2(spike + 1.0, 11.0), Vector2(4, 6)), tint)

func draw_stink_blob(blob:Dictionary, p:Vector2)->void:
    if blob.get("pattern_shot", false):
        var hue: Color = SHOT_COLOR.get(blob.kind, SHOT_COLOR.spark)
        var radius: float = blob.radius
        var heading: Vector2 = Vector2(blob.velocity).normalized()
        draw_line(p - heading * (radius + 9.0), p, Color(hue, .40), 3.0)
        draw_circle(p, radius + 2.0, Color("#35283a"))
        draw_circle(p, radius, hue)
        draw_circle(p + heading * 1.5, radius * .44, Color("#fff6d8"))
        return
    # A soft cluster of several short-lived vapor puffs, not a laser or beam.
    # Color and cadence communicate the attack while keeping dodgeable hitboxes clear.
    var ice: bool = str(blob.get("kind","poison")) == "ice"
    var blast: bool = str(blob.get("kind","poison")) == "blast"
    var radius: float = float(blob.get("radius",9.0))
    var age: float = float(blob.get("age",0.0))
    var heading: Vector2 = blob.get("velocity",Vector2.RIGHT)
    heading = heading.normalized()
    var tangent := Vector2(-heading.y,heading.x)
    var ripple: float = sin(age * 13.0) * 1.4
    var glow: Color = Color(0.56,0.86,1.0,0.14) if ice else (Color(1.0,0.70,0.38,0.17) if blast else Color(0.55,0.95,0.36,0.16))
    var rim: Color = Color("a9f3ff") if ice else (Color("ffd68b") if blast else Color("b1f86c"))
    var body: Color = Color("67bde2") if ice else (Color("d7a44e") if blast else Color("69bf4c"))
    draw_circle(p, radius + 7.0, glow)
    draw_circle(p - heading * 9.5 + tangent * ripple, radius * 0.45, Color(rim.r,rim.g,rim.b,0.22))
    draw_circle(p - heading * 14.0 - tangent * 3.0, radius * 0.27, Color(rim.r,rim.g,rim.b,0.13))
    draw_circle(p + tangent * 1.6, radius, Color(0.07,0.23,0.17,0.90))
    draw_circle(p + tangent * 1.6, radius - 1.8, body)
    draw_circle(p + tangent * (radius * 0.47) - heading * 2.2, radius * 0.60, rim)
    draw_circle(p - tangent * 3.0 - heading * 2.2, radius * 0.30, Color(0.91,1.0,0.80,0.77) if not ice else Color(0.93,1.0,1.0,0.86))

func draw_player(player: Dictionary, p: Vector2, is_local: bool) -> void:
    var alpha := 0.48 if player.hp <= 0 else 1.0
    var charskin: String = player.get("character","scout")
    var aim: Vector2 = player.get("aim",Vector2.RIGHT)
    if is_local and game.mode == "guest" and player.hp > 0.0:
        aim = game._get_local_aim()
    var sprite := "hero"
    var tint: Color = RangerProgress.OUTFITS.get(charskin, {}).get("tint", Color.WHITE)
    if charskin != "scout" and art.has("outfit_" + charskin):
        sprite = "outfit_" + charskin
    if aim.x < -0.1:
        sprite += "_left"
    shadow(p, Vector2(21,9))
    if float(player.get("dash_left", 0.0)) > 0.0 and player.hp > 0.0:
        var along: Vector2 = player.get("dash_heading", aim)
        for ghost in range(1, 4):
            var echo := p - along * float(ghost) * 19.0
            sprite_region(sprite, Rect2(0,0,36,48), Rect2(echo.x - 29, echo.y - 75, 58, 76), .32 - .065 * float(ghost), tint)
    # Identical source sprite regions, including independent left and right boot offsets.
    var moving: bool = player.get("moving",false)
    var walk: float = player.get("walk",0.0)
    var step := sin(walk*10)*5.0 if moving else 0.0
    sprite_region(sprite,Rect2(0,0,36,35),Rect2(p.x-29,p.y-79+(sin(walk*20)*1.5 if moving else 0),58,57),alpha,tint)
    sprite_region(sprite,Rect2(0,35,18,13),Rect2(p.x-29,p.y-23+step*.5,29,22),alpha,tint)
    sprite_region(sprite,Rect2(18,35,18,13),Rect2(p.x,p.y-23-step*.5,29,22),alpha,tint)
    if player.hp <= 0.0:
        var revive: float = float(player.get("revive_time", 0.0)) / 2.5
        draw_rect(Rect2(p + Vector2(-25, -99), Vector2(50, 7)), Color("#19242a"))
        draw_rect(Rect2(p + Vector2(-23, -97), Vector2(46.0 * revive, 3)), Color("#9ce5a8"))
        draw_string(ThemeDB.fallback_font, p + Vector2(-24, -105), "REVIVE", HORIZONTAL_ALIGNMENT_LEFT, 60, 13, Color("#ffda8e"))
        return
    draw_gun(p+Vector2(4,-37),aim,player)
    if float(player.get("flash",0)) > 0:
        draw_circle(p+Vector2(aim.x*45,-37+aim.y*17),11,Color("ffe187"))
    var label_font := ThemeDB.fallback_font
    var caption := "%s  ·  LV %d" % ["YOU" if is_local else str(player.get("name", "PLAYER")), int(player.get("level", 1))]
    draw_string(label_font, p + Vector2(-85,-95), caption, HORIZONTAL_ALIGNMENT_CENTER, 170, 12, Color("cbeeff"))
    if not is_local:
        draw_rect(Rect2(p.x-23,p.y-90,46,5),Color("50303d"))
        draw_rect(Rect2(p.x-23,p.y-90,46*clampf(player.hp/maxf(1,player.max_hp),0,1),5),Color("8ddf88"))

func draw_gun(p: Vector2,aim: Vector2,player: Dictionary) -> void:
    var weapon_id: String = str(player.get("weapon","shotgun"))
    var skin_name: String = str(player.get("skin",""))
    var options: Array = game.SKIN_OPTIONS.get(weapon_id, [])
    var skin_index: int = maxi(0,options.find(skin_name))
    var key: String = "%s_%d" % [weapon_id,skin_index]
    if not gun_art.has(key):
        return
    var angle: float = atan2(aim.y,aim.x)
    draw_set_transform(p,angle)
    var rect: Rect2 = Rect2(-27,-24,106,58)
    if skin_index > 0 and gun_glow_art.has(key):
        # A pre-baked lightweight two-tone aura instead of full-screen bloom.
        draw_texture_rect(gun_glow_art[key],rect,false)
    draw_texture_rect(gun_art[key],rect,false)
    draw_set_transform(Vector2.ZERO)
