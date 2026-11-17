extends Node2D
## Native CanvasItem renderer using the EXACT source PNG files from the latest HTML.
## Isometric projection, scale, terrain hash, and sprite draw rectangles follow the HTML.

const MAP := 192.0
const C := Vector2(640.0, 368.0)
const ART := ["acorn", "xp", "boss", "bruiser", "bush", "grass_0", "grass_1", "grass_2", "grass_3", "hero", "hero_left", "mud", "speedy", "squirrel", "stone", "toxic", "tree", "tree_autumn", "outfit_trailblazer", "outfit_trailblazer_left", "outfit_sharpsight", "outfit_sharpsight_left", "outfit_ironbark", "outfit_ironbark_left", "outfit_cindercloak", "outfit_cindercloak_left", "outfit_frostbound", "outfit_frostbound_left"]

var game
var art: Dictionary = {}
var gun_art: Dictionary = {}
var gun_glow_art: Dictionary = {}

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for key in ART:
        art[key] = load("res://art/%s.png" % key)
    for weapon_id in game.WEAPON_ORDER:
        var styles: Array = game.SKIN_OPTIONS[weapon_id]
        for i in range(styles.size()):
            gun_art["%s_%d" % [weapon_id,i]] = load("res://ui/guns/%s_%d.png" % [weapon_id,i])
            if i > 0:
                gun_glow_art["%s_%d" % [weapon_id,i]] = load("res://ui/guns/glows/%s_%d.png" % [weapon_id,i])

func delta_toroid(d: float) -> float:
    return fposmod(d + MAP * 0.5, MAP) - MAP * 0.5

func iso(v: Vector2) -> Vector2:
    return Vector2((v.x - v.y) * 32.0, (v.x + v.y) * 16.0)

func screen_point(v: Vector2, focus: Vector2) -> Vector2:
    return C + iso(Vector2(delta_toroid(v.x - focus.x), delta_toroid(v.y - focus.y)))

func texture_rect(key: String, rect: Rect2, alpha: float = 1.0) -> void:
    if art.has(key):
        draw_texture_rect(art[key], rect, false, Color(1, 1, 1, alpha))

func sprite_region(key: String, src: Rect2, dst: Rect2, alpha: float = 1.0) -> void:
    if art.has(key):
        draw_texture_rect_region(art[key], dst, src, Color(1, 1, 1, alpha))

func shadow(p: Vector2, radius: Vector2, opacity: float = 0.32) -> void:
    if not bool(game.settings.get("fx_contact_shadows", true)):
        return
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
    var h := hash_tile(x, y)
    if Vector2(float(x), float(y)).distance_to(Vector2(27,27)) < 8.0:
        return "grass_%d" % (h % 4)
    if h % 17 == 3:
        return "mud"
    if h % 23 == 9:
        return "stone"
    return "grass_%d" % (h % 4)

func _draw() -> void:
    if game == null:
        return
    draw_rect(Rect2(0, 0, 1280, 720), Color("172f38"))
    var focus: Vector2 = game.camera_pos
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
            texture_rect(ground_kind(wx, wy), Rect2(p.x - 32, p.y - 16, 64, 40))
            # Reflective wet ground is rendered only when enabled, with strict culling.
            if bool(game.settings.get("fx_reflections",false)) and game.weather in ["rain","mist"] and hash_tile(wx,wy)%139 == 3:
                _draw_pixel_ellipse(p + Vector2(0.0,4.0), 21.0, 6.5, Color(0.34,0.64,0.70,0.19))
                draw_line(p + Vector2(-11.0,1.0),p + Vector2(10.0,1.0),Color(0.73,0.94,0.94,0.21),1.0)
            if hash_tile(wx, wy) % 37 == 0:
                draw_rect(Rect2(p.x + 8, p.y - 6, 3, 3), Color("5f7e57"))

    var drawables: Array[Dictionary] = []
    for o in game.nearby_obstacles(focus,34):
        var p := screen_point(o.pos, focus)
        if p.x < -110 or p.x > 1390 or p.y < -140 or p.y > 840:
            continue
        drawables.append({"y":p.y, "kind":o.kind, "p":p, "source":o})
    for a in game.drops:
        var p := screen_point(a.pos, focus)
        drawables.append({"y":p.y-1, "kind":"acorn", "p":p, "source":a})
    for shard in game.xp_drops:
        var p := screen_point(shard.pos,focus)
        if p.x > -40 and p.x < 1320 and p.y > -40 and p.y < 760:
            drawables.append({"y":p.y-1,"kind":"xp","p":p,"source":shard})
    # Traveling stinky-air globs use the original isometric camera and layer
    # alongside the world entities rather than fake full-screen laser lines.
    for blob in game.enemy_blobs:
        var position: Vector2 = blob.pos
        if game.mode == "guest":
            var velocity: Vector2 = blob.get("velocity",Vector2.ZERO)
            position = game._wrap_vec(position + game._uniso(velocity * float(game.enemy_blob_interp)))
        var p := screen_point(position, focus) + Vector2(0,-20)
        if p.x < -40 or p.x > 1320 or p.y < -40 or p.y > 760:
            continue
        drawables.append({"y":p.y, "kind":"stink_blob", "p":p, "source":blob})
    for hz in game.hazards:
        var p := screen_point(hz.pos, focus)
        drawables.append({"y":p.y-2, "kind":"hazard", "p":p, "source":hz})
    for e in game.enemies:
        var p := screen_point(e.pos, focus)
        if p.x < -160 or p.x > 1440 or p.y < -150 or p.y > 850:
            continue
        drawables.append({"y":p.y + 0.05, "kind":"enemy", "p":p, "source":e})
    for id in game.players.keys():
        var player: Dictionary = game.players[id]
        var p := screen_point(player.pos, focus)
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
            var sway := sin(game.elapsed*.9 + float(h%9)) * 2
            texture_rect(tree_id, Rect2(p.x - 45 + sway, p.y - 126, 90, 133))
        elif k == "rock":
            shadow(p, Vector2(19, 8), 0.4)
            draw_colored_polygon(PackedVector2Array([p+Vector2(-21, -3), p+Vector2(-16, -19), p+Vector2(-3, -28), p+Vector2(15, -21), p+Vector2(21, -7), p+Vector2(8, 1), p+Vector2(-14, 0)]), Color("5b6870"))
            draw_line(p+Vector2(-16, -19), p+Vector2(2, -21), Color("849198"), 3)
        elif k == "stump":
            shadow(p, Vector2(14, 7))
            draw_rect(Rect2(p.x-11, p.y-22, 22, 20), Color("5b3e29"))
            _draw_pixel_ellipse(p + Vector2(0,-19), 11.0, 6.0, Color("987b4d"))
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
            draw_player(src,p,item.id == game.local_id)

    for trace in game.traces:
        draw_line(trace.start, trace.end, trace.tint, max(1.0,trace.width))
        if bool(game.settings.get("fx_long_exposure",false)):
            var afterglow: Color = trace.tint
            afterglow.a *= 0.16 * float(game.settings.get("fx_long_exposure_strength",0.32))
            draw_line(trace.start, trace.end, afterglow, max(2.0,trace.width*5.0))
    for particle in game.particles:
        var fade: float = clampf(1.0 - particle.age / max(particle.life,.01),0,1)
        var color: Color = particle.tint
        color.a = fade
        draw_rect(Rect2(particle.pos, Vector2(particle.size,particle.size)), color)
    # Locator arrows: three nearest offscreen squirrels, with toroidal distance.
    var candidates: Array[Dictionary] = []
    for e in game.enemies:
        if e.hp<=0:continue
        var vp := screen_point(e.pos,focus)
        var dst := vp.distance_to(C)
        candidates.append({"screen":vp,"distance":dst})
    candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.distance<b.distance)
    if candidates.size()>0 and candidates[0].distance>625:
        var colors := [Color("ffcf6d"),Color("78e0ec"),Color("e8a6fa")]
        for i in range(mini(3,candidates.size())):
            var d:Vector2=candidates[i].screen-C
            var u:Vector2=d.normalized()
            var v:Vector2=Vector2(-u.y,u.x)
            var margin := (i-1)*40.0
            var here := C+u*minf(140,d.length())+v*margin
            draw_colored_polygon(PackedVector2Array([here+u*21,here-u*13-v*10,here-u*7,here-u*13+v*10]),colors[i])
    # Atmosphere: lightweight native canvas tint, not an added browser upload.
    var day: float = game.day_phase
    var night: float = (1.0 - sin(day * TAU - PI * 0.5)) * 0.5
    draw_rect(Rect2(0,0,1280,720), Color(0.04,0.1,0.26,night * 0.21))
    if bool(game.settings.get("weather",true)):
        var ticks: int = int(game.elapsed * 100.0)
        if game.weather == "rain":
            for i in range(75):
                var rx: float = float((i * 131 + ticks * 3) % 1280)
                var ry: float = float((i * 277 + ticks * 7) % 720)
                draw_line(Vector2(rx,ry), Vector2(rx-6,ry+15), Color(0.67,0.83,0.94,0.30),1.0)
        elif game.weather == "snow":
            for i in range(43):
                var sx: float = float((i * 157 + ticks / 6) % 1280)
                var sy: float = float((i * 229 + ticks / 3) % 720)
                draw_circle(Vector2(sx,sy),1.2,Color(0.86,0.95,1.0,0.54))
        elif game.weather == "wind":
            for i in range(24):
                var wx: float = float((i * 167 + ticks * 2) % 1280)
                var wy: float = float((i * 237 + ticks / 2) % 720)
                draw_line(Vector2(wx,wy),Vector2(wx+25,wy-7),Color(0.77,0.93,0.82,0.13),1.0)
        elif game.weather == "mist" and not bool(game.settings.get("fx_fog",false)):
            draw_rect(Rect2(0,0,1280,720),Color(0.55,0.71,0.67,0.055))

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
    var w := 59.0 * mult
    var h := 72.0 * mult
    var bob := sin(float(e.get("bob",0))) * 2.3
    shadow(p, Vector2(18*mult,9*mult))
    texture_rect(key, Rect2(p.x-w/2, p.y-h+bob,w,h), 0.65 if float(e.get("hit",0))>0 else 1.0)
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

func draw_stink_blob(blob:Dictionary, p:Vector2)->void:
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
    var sprite := "hero"
    if charskin != "scout" and art.has("outfit_" + charskin):
        sprite = "outfit_" + charskin
    if aim.x < -0.1:
        sprite += "_left"
    shadow(p, Vector2(21,9))
    # Identical source sprite regions, including independent left and right boot offsets.
    var moving: bool = player.get("moving",false)
    var walk: float = player.get("walk",0.0)
    var step := sin(walk*10)*5.0 if moving else 0.0
    sprite_region(sprite,Rect2(0,0,36,35),Rect2(p.x-29,p.y-79+(sin(walk*20)*1.5 if moving else 0),58,57),alpha)
    sprite_region(sprite,Rect2(0,35,18,13),Rect2(p.x-29,p.y-23+step*.5,29,22),alpha)
    sprite_region(sprite,Rect2(18,35,18,13),Rect2(p.x,p.y-23-step*.5,29,22),alpha)
    draw_gun(p+Vector2(4,-37),aim,player)
    if float(player.get("flash",0)) > 0:
        draw_circle(p+Vector2(aim.x*45,-37+aim.y*17),11,Color("ffe187"))
    if not is_local:
        var label_font: Font = ThemeDB.fallback_font
        draw_string(label_font,p+Vector2(-27,-95),str(player.get("name","PLAYER")),HORIZONTAL_ALIGNMENT_LEFT,110,12,Color("cbeeff"))
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
