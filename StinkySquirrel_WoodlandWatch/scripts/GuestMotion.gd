extends RefCounted

const MAP_SIZE := 192.0
const BUFFER_DELAY := .105
const MAX_LOOK_AHEAD := .06

var frames: Array[Dictionary] = []
var time := 0.0
var blend := 0.0
var before: Dictionary = {}
var after: Dictionary = {}

func reset() -> void:
    frames.clear()
    before.clear()
    after.clear()
    time = 0.0
    blend = 0.0

func observe(stamp: float, players: Dictionary, enemies: Array[Dictionary], bullets: Array[Dictionary]) -> void:
    if not frames.is_empty() and stamp <= float(frames.back().stamp):
        return
    var actors := {}
    for id in players:
        actors[id] = players[id].pos
    var squirrels := {}
    for enemy in enemies:
        squirrels[enemy.id] = enemy.pos
    var shots := {}
    for shot in bullets:
        shots[shot.id] = shot.pos
    if frames.is_empty() or stamp - time > .65:
        frames.clear()
        time = stamp - BUFFER_DELAY
    frames.append({"stamp": stamp, "players": actors, "enemies": squirrels, "shots": shots})
    if frames.size() > 10:
        frames.pop_front()

func step(dt: float) -> void:
    if frames.is_empty():
        return
    var newest: float = frames.back().stamp
    var drift := newest - BUFFER_DELAY - time
    time = minf(newest + MAX_LOOK_AHEAD, time + dt * clampf(1.0 + drift * 2.5, .85, 1.15))
    while frames.size() > 2 and float(frames[1].stamp) <= time:
        frames.pop_front()
    before = frames[0]
    after = frames[1] if frames.size() > 1 else before
    var span := float(after.stamp) - float(before.stamp)
    blend = clampf((time - float(before.stamp)) / span, 0.0, 1.0) if span > 0.0 else 1.0

func sample(group: String, id: int, fallback: Vector2) -> Vector2:
    if before.is_empty() or after.is_empty():
        return fallback
    var left: Dictionary = before[group]
    var right: Dictionary = after[group]
    if not left.has(id) or not right.has(id):
        return fallback
    var a: Vector2 = left[id]
    var b: Vector2 = right[id]
    var delta := wrapped_difference(b, a)
    if delta.length_squared() > 52.0:
        return b
    return wrap_position(a + delta * blend)

func extra_time() -> float:
    return clampf(time - float(after.stamp), 0.0, MAX_LOOK_AHEAD) if not after.is_empty() else 0.0

static func wrapped_difference(a: Vector2, b: Vector2) -> Vector2:
    var half := MAP_SIZE * .5
    return Vector2(fposmod(a.x - b.x + half, MAP_SIZE) - half, fposmod(a.y - b.y + half, MAP_SIZE) - half)

static func wrap_position(pos: Vector2) -> Vector2:
    return Vector2(fposmod(pos.x, MAP_SIZE), fposmod(pos.y, MAP_SIZE))
