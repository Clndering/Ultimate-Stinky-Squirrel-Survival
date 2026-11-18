extends RefCounted
## Wire data contains presentation fields only. Combat stats stay with the host.

const PLAYER_FIELDS := ["pos", "hp", "max_hp", "weapon", "skin", "character", "aim",
    "walk", "moving", "flash", "dash_left", "dash_heading", "revive_time", "ammo", "mag",
    "reload", "dash_cd", "kills", "shots_fired", "chest_upgrades", "name", "speed", "level"]
const PLAYER_DEFAULTS := [Vector2.ZERO, 0.0, 100.0, "shotgun", "", "scout", Vector2.RIGHT,
    0.0, false, 0.0, 0.0, Vector2.RIGHT, 0.0, 0, 1, 0.0, 0.0, 0, 0, [], "", 185.0, 1]
const ENEMY_FIELDS := ["id", "kind", "pos", "hp", "max_hp", "bob", "hit", "burn",
    "chill", "windup", "pattern", "marked", "core"]
const ENEMY_DEFAULTS := [0, "normal", Vector2.ZERO, 0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, "", false, false]
const BULLET_KINDS := ["poison", "ice", "normal", "blast", "spark", "arc", "needle_shot"]
const BULLET_STRIDE := 9

static func _pack(source: Dictionary, fields: Array, defaults: Array) -> Array:
    var row: Array = []
    row.resize(fields.size())
    for i in range(fields.size()):
        row[i] = source.get(fields[i], defaults[i])
    return row

static func _unpack(row: Array, fields: Array) -> Dictionary:
    var values := {}
    for i in range(fields.size()):
        values[fields[i]] = row[i]
    return values

static func pack_players(source: Dictionary) -> Dictionary:
    var rows := {}
    for id in source:
        rows[id] = _pack(source[id], PLAYER_FIELDS, PLAYER_DEFAULTS)
    return rows

static func unpack_players(rows: Dictionary) -> Dictionary:
    var source := {}
    for id in rows:
        var row: Array = rows[id]
        if row.size() == PLAYER_FIELDS.size() - 1:
            row = row.duplicate()
            row.append(1)
        if row.size() == PLAYER_FIELDS.size():
            source[id] = _unpack(row, PLAYER_FIELDS)
    return source

static func pack_enemies(source: Array[Dictionary]) -> Array:
    var rows: Array = []
    for enemy in source:
        rows.append(_pack(enemy, ENEMY_FIELDS, ENEMY_DEFAULTS))
    return rows

static func unpack_enemies(rows: Array) -> Array[Dictionary]:
    var source: Array[Dictionary] = []
    for row in rows:
        if row is Array and row.size() == ENEMY_FIELDS.size():
            source.append(_unpack(row, ENEMY_FIELDS))
    return source

static func pack_bullets(shots: Array[Dictionary]) -> PackedFloat32Array:
    var values := PackedFloat32Array()
    values.resize(shots.size() * BULLET_STRIDE)
    for i in range(shots.size()):
        var shot: Dictionary = shots[i]
        var pos: Vector2 = shot.pos
        var velocity: Vector2 = shot.velocity
        var offset := i * BULLET_STRIDE
        values[offset] = float(shot.id)
        values[offset + 1] = pos.x
        values[offset + 2] = pos.y
        values[offset + 3] = velocity.x
        values[offset + 4] = velocity.y
        values[offset + 5] = float(BULLET_KINDS.find(shot.kind))
        values[offset + 6] = shot.radius
        values[offset + 7] = shot.age
        values[offset + 8] = 1.0 if shot.pattern_shot else 0.0
    return values

static func unpack_bullets(values: PackedFloat32Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for offset in range(0, values.size() - BULLET_STRIDE + 1, BULLET_STRIDE):
        var kind := clampi(int(values[offset + 5]), 0, BULLET_KINDS.size() - 1)
        result.append({"id": int(values[offset]), "pos": Vector2(values[offset+1], values[offset+2]),
            "velocity": Vector2(values[offset+3], values[offset+4]), "kind": BULLET_KINDS[kind],
            "radius": values[offset+6], "age": values[offset+7], "pattern_shot": values[offset+8] > .5})
    return result
