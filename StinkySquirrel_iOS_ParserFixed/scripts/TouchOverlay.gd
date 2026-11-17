extends Control
## Two-thumb control surface for Godot Web on iOS/iPadOS.
## It deliberately uses raw multi-touch indices, so either thumb can move
## independently while the other shoots. This node never appears on menus.

signal menu_requested

const RING := Color(0.12, 0.37, 0.38, 0.68)
const EDGE := Color(0.56, 0.91, 0.73, 0.90)
const INK := Color(0.92, 0.96, 0.79, 0.96)
const CENTER := Color(0.14, 0.47, 0.41, 0.88)
const STICK_RADIUS := 78.0
const BUTTON_RADIUS := 46.0

var left_touch: int = -1
var right_touch: int = -1
var left_value := Vector2.ZERO
var right_value := Vector2.ZERO
var previous_aim := Vector2.RIGHT
var dash_queued := false
var reload_queued := false
var menu_queued := false
var active_touches: Dictionary = {}
var left_origin := Vector2.ZERO
var right_origin := Vector2.ZERO
var dash_origin := Vector2.ZERO
var reload_origin := Vector2.ZERO
var menu_origin := Vector2.ZERO
var last_size := Vector2.ZERO

func _ready() -> void:
    name = "iOS Twin-Stick Controls"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)
    resized.connect(_layout_controls)
    _layout_controls()

func _layout_controls() -> void:
    var s: Vector2 = size
    if s.x < 1.0 or s.y < 1.0:
        return
    last_size = s
    # Keep the controls inside the canvas, below the compact upper HUD.
    var base_y: float = s.y - minf(172.0, s.y * 0.25)
    var side: float = minf(160.0, s.x * 0.145)
    left_origin = Vector2(side, base_y)
    right_origin = Vector2(s.x - side, base_y)
    dash_origin = Vector2(s.x - side * 0.76, base_y - 192.0)
    reload_origin = Vector2(s.x - side * 1.95, base_y - 155.0)
    menu_origin = Vector2(s.x - side * 0.69, 191.0)
    queue_redraw()

func reset_inputs() -> void:
    left_touch = -1
    right_touch = -1
    left_value = Vector2.ZERO
    right_value = Vector2.ZERO
    active_touches.clear()
    dash_queued = false
    reload_queued = false
    menu_queued = false
    queue_redraw()

func move_vector() -> Vector2:
    return left_value

func aim_vector() -> Vector2:
    return right_value if right_value.length_squared() > 0.0225 else previous_aim

func is_firing() -> bool:
    return right_touch >= 0

func consume_dash() -> bool:
    var pressed: bool = dash_queued
    dash_queued = false
    return pressed

func consume_reload() -> bool:
    var pressed: bool = reload_queued
    reload_queued = false
    return pressed

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _finger_down(touch.index, touch.position)
        else:
            _finger_up(touch.index)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        _finger_drag(drag.index, drag.position)
        get_viewport().set_input_as_handled()

func _finger_down(finger: int, point: Vector2) -> void:
    active_touches[finger] = point
    if point.distance_to(menu_origin) < BUTTON_RADIUS * 1.32:
        if not menu_queued:
            menu_queued = true
            menu_requested.emit()
        return
    if point.distance_to(dash_origin) < BUTTON_RADIUS * 1.30:
        dash_queued = true
        queue_redraw()
        return
    if point.distance_to(reload_origin) < BUTTON_RADIUS * 1.30:
        reload_queued = true
        queue_redraw()
        return
    if point.x < size.x * 0.49 and point.y > size.y * 0.39 and left_touch < 0:
        left_touch = finger
        _finger_drag(finger, point)
    elif point.x >= size.x * 0.49 and point.y > size.y * 0.39 and right_touch < 0:
        right_touch = finger
        _finger_drag(finger, point)

func _finger_drag(finger: int, point: Vector2) -> void:
    if not active_touches.has(finger):
        return
    active_touches[finger] = point
    if finger == left_touch:
        left_value = ((point - left_origin) / STICK_RADIUS).limit_length(1.0)
        if left_value.length() < 0.13:
            left_value = Vector2.ZERO
    elif finger == right_touch:
        right_value = ((point - right_origin) / STICK_RADIUS).limit_length(1.0)
        if right_value.length_squared() > 0.0225:
            previous_aim = right_value.normalized()
    queue_redraw()

func _finger_up(finger: int) -> void:
    active_touches.erase(finger)
    if finger == left_touch:
        left_touch = -1
        left_value = Vector2.ZERO
    elif finger == right_touch:
        right_touch = -1
        right_value = Vector2.ZERO
    if active_touches.is_empty():
        menu_queued = false
    queue_redraw()

func _draw_ring(origin: Vector2, radius: float, pressed: bool = false) -> void:
    var fill_color: Color = CENTER if pressed else RING
    draw_circle(origin, radius, fill_color)
    draw_arc(origin, radius - 5.0, 0.0, TAU, 48, EDGE, 4.0, false)
    draw_arc(origin, radius - 14.0, 0.0, TAU, 48, Color(0.54, 0.82, 0.77, 0.24), 2.0, false)

func _print_centered(text_value: String, origin: Vector2, font_size: int = 21) -> void:
    var font: Font = get_theme_default_font()
    if font != null:
        var width: float = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        draw_string(font, origin + Vector2(-width * 0.5, font_size * 0.34), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)

func _draw() -> void:
    if size != last_size:
        _layout_controls()
    # Character silhouette styling matches the compact Nightwatch UI.
    _draw_ring(left_origin, STICK_RADIUS, left_touch >= 0)
    _draw_ring(right_origin, STICK_RADIUS, right_touch >= 0)
    var left_knob: Vector2 = left_origin + left_value * STICK_RADIUS * 0.67
    var right_knob: Vector2 = right_origin + right_value * STICK_RADIUS * 0.67
    draw_circle(left_knob, 30.0, Color(0.71, 0.93, 0.76, 0.80))
    draw_circle(left_knob, 20.0, Color(0.15, 0.38, 0.34, 0.96))
    draw_circle(right_knob, 30.0, Color(0.98, 0.80, 0.44, 0.84))
    draw_circle(right_knob, 20.0, Color(0.38, 0.26, 0.20, 0.95))
    _print_centered("MOVE", left_origin + Vector2(0, -STICK_RADIUS - 20), 18)
    _print_centered("AIM + FIRE", right_origin + Vector2(0, -STICK_RADIUS - 20), 18)
    _draw_ring(dash_origin, BUTTON_RADIUS, dash_queued)
    _draw_ring(reload_origin, BUTTON_RADIUS, reload_queued)
    _draw_ring(menu_origin, BUTTON_RADIUS * 0.76)
    _print_centered("DASH", dash_origin, 18)
    _print_centered("RELOAD", reload_origin, 14)
    _print_centered("II", menu_origin, 23)
