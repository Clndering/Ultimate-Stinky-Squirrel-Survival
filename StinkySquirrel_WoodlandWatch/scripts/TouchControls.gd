extends Control

signal dash_pressed
signal chest_pressed
signal menu_pressed
signal interrupted

const STICK_RADIUS := 80.0
const STICK_REACH := 112.0
const BUTTON_RADIUS := 42.0
const DEAD_ZONE := 0.18
const GOLD := Color("#f0d390")
const MINT := Color("#9ad9c1")
const BASE := Color(0.05, 0.15, 0.18, 0.80)

var mobile_layout := false
var using_touch := false
var active := false
var gameplay_active := false
var browser_canvas: JavaScriptObject
var browser_window: JavaScriptObject
var browser_document: JavaScriptObject
var browser_rotate_hint: JavaScriptObject
var browser_layout_callback: JavaScriptObject
var browser_visibility_callback: JavaScriptObject
var browser_uses_pointers := false
var browser_portrait := false
var browser_touch_callback: JavaScriptObject
var browser_blur_callback: JavaScriptObject
var browser_events: Array[String] = []
var browser_touch_options: JavaScriptObject
var move_vector := Vector2.ZERO
var aim_vector := Vector2.ZERO
var last_aim := Vector2.RIGHT
var move_finger := -1
var aim_finger := -1
var move_center := Vector2.ZERO
var aim_center := Vector2.ZERO
var action_centers: Dictionary = {}
var action_fingers: Dictionary = {}
var reload_until := 0
var dash_display := -1
var original_mouse_emulation := true

static func wants_mobile_layout() -> bool:
    if not OS.has_feature("web"):
        return OS.has_feature("android") or OS.has_feature("ios")
    if OS.has_feature("web_android") or OS.has_feature("web_ios"):
        return true
    var browser_location := JavaScriptBridge.get_interface("location")
    if browser_location != null:
        if str(browser_location.search).contains("touch=1"):
            return true
    var browser_navigator := JavaScriptBridge.get_interface("navigator")
    return browser_navigator != null and int(browser_navigator.maxTouchPoints) > 0

func _ready() -> void:
    mouse_filter = MOUSE_FILTER_IGNORE
    original_mouse_emulation = Input.emulate_mouse_from_touch
    mobile_layout = wants_mobile_layout()
    using_touch = mobile_layout
    resized.connect(_update_layout)
    _update_layout()
    _bind_browser_touch()
    set_active(false)

func set_active(value: bool) -> void:
    gameplay_active = value
    if not value:
        clear_input()
    active = value and mobile_layout
    visible = active
    set_process_input(active)
    if mobile_layout:
        # Tap-to-click is for menus. Only the aim stick fires during gameplay.
        Input.emulate_mouse_from_touch = not active

func _exit_tree() -> void:
    if browser_window != null:
        for event in browser_events:
            browser_window.removeEventListener(event, browser_touch_callback, browser_touch_options)
        browser_window.removeEventListener("blur", browser_blur_callback)
        browser_window.removeEventListener("pagehide", browser_blur_callback)
        browser_window.removeEventListener("resize", browser_layout_callback)
    if browser_document != null:
        browser_document.removeEventListener("visibilitychange", browser_visibility_callback)
    if browser_rotate_hint != null:
        browser_rotate_hint.remove()
    if mobile_layout:
        Input.emulate_mouse_from_touch = original_mouse_emulation

func _notification(what: int) -> void:
    if not OS.has_feature("web") and (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT):
        clear_input()

func clear_input() -> void:
    move_finger = -1
    aim_finger = -1
    move_vector = Vector2.ZERO
    aim_vector = Vector2.ZERO
    reload_until = 0
    action_fingers.clear()
    queue_redraw()

func _update_layout() -> void:
    # Insets in game coordinates keep touch targets inside the 16:9 canvas.
    move_center = Vector2(175, size.y - 169)
    aim_center = Vector2(size.x - 175, size.y - 169)
    action_centers = {
        "DASH": Vector2(size.x - 322, size.y - 133),
        "RELOAD": Vector2(size.x - 183, size.y - 305),
        "OPEN": Vector2(size.x - 294, size.y - 276),
        "MENU": Vector2(size.x - 159, 203)
    }
    queue_redraw()

func set_dash_cooldown(seconds: float) -> void:
    var tenths := ceili(maxf(0.0, seconds) * 10.0)
    if tenths != dash_display:
        dash_display = tenths
        queue_redraw()

func wants_fire() -> bool:
    return active and using_touch and aim_finger >= 0 and aim_vector.length_squared() > 0.0

func wants_reload() -> bool:
    return active and Time.get_ticks_msec() < reload_until

func _bind_browser_touch() -> void:
    if not OS.has_feature("web"):
        return
    browser_document = JavaScriptBridge.get_interface("document")
    browser_window = JavaScriptBridge.get_interface("window")
    if browser_document == null or browser_window == null:
        return
    browser_canvas = browser_document.getElementById("canvas")
    if browser_canvas == null:
        return
    browser_canvas.style.touchAction = "none"
    # Safari may cancel pointer capture for browser gestures while Touch Events
    # continue to track each finger. This also covers iPads using desktop mode.
    var nav := JavaScriptBridge.get_interface("navigator")
    var apple_touch := OS.has_feature("web_ios") or (nav != null and
        (str(nav.userAgent).contains("iPhone") or str(nav.userAgent).contains("iPad")
        or (str(nav.platform) == "MacIntel" and int(nav.maxTouchPoints) > 1)))
    browser_uses_pointers = not apple_touch and bool(JavaScriptBridge.eval("typeof PointerEvent === 'function'"))
    if browser_uses_pointers:
        browser_events.assign(["pointerdown", "pointermove", "pointerup", "pointercancel", "lostpointercapture"])
        browser_touch_callback = JavaScriptBridge.create_callback(_on_browser_pointer)
    else:
        browser_events.assign(["touchstart", "touchmove", "touchend", "touchcancel"])
        browser_touch_callback = JavaScriptBridge.create_callback(_on_browser_touch)
    browser_blur_callback = JavaScriptBridge.create_callback(_on_browser_blur)
    browser_window.addEventListener("blur", browser_blur_callback)
    browser_window.addEventListener("pagehide", browser_blur_callback)
    browser_visibility_callback = JavaScriptBridge.create_callback(_on_browser_visibility)
    browser_document.addEventListener("visibilitychange", browser_visibility_callback)
    browser_layout_callback = JavaScriptBridge.create_callback(_on_browser_resize)
    browser_window.addEventListener("resize", browser_layout_callback)
    _update_browser_layout()
    browser_touch_options = JavaScriptBridge.create_object("Object")
    browser_touch_options.passive = false
    browser_touch_options.capture = true
    for event in browser_events:
        browser_window.addEventListener(event, browser_touch_callback, browser_touch_options)

static func browser_to_game(client: Vector2, canvas_rect: Rect2, game_size: Vector2) -> Vector2:
    if canvas_rect.size.x <= 0.0 or canvas_rect.size.y <= 0.0 or game_size.x <= 0.0 or game_size.y <= 0.0:
        return Vector2.INF
    var scale_value := minf(canvas_rect.size.x / game_size.x, canvas_rect.size.y / game_size.y)
    var padding := (canvas_rect.size - game_size * scale_value) * .5
    return (client - canvas_rect.position - padding) / scale_value

func _on_browser_blur(_args: Array) -> void:
    _interrupt_input()

func _interrupt_input() -> void:
    var had_touch := move_finger >= 0 or aim_finger >= 0 or not action_fingers.is_empty() or reload_until > Time.get_ticks_msec()
    clear_input()
    if active and had_touch:
        interrupted.emit()

func _on_browser_visibility(_args: Array) -> void:
    if bool(browser_document.hidden):
        _interrupt_input()

func _on_browser_resize(_args: Array) -> void:
    _update_browser_layout()

func _update_browser_layout() -> void:
    var portrait := int(browser_window.innerHeight) > int(browser_window.innerWidth)
    if portrait != browser_portrait:
        browser_portrait = portrait
        _interrupt_input()
    if not mobile_layout:
        return
    if browser_rotate_hint == null:
        browser_rotate_hint = browser_document.createElement("p")
        browser_rotate_hint.id = "woodland-rotate-hint"
        browser_rotate_hint.textContent = "Rotate your device for larger controls."
        browser_rotate_hint.setAttribute("role", "status")
        browser_rotate_hint.style.cssText = ("position:fixed;z-index:2;left:0;right:0;"
            + "top:max(12px,env(safe-area-inset-top));margin:0 auto;padding:10px 14px;width:max-content;"
            + "max-width:calc(100% - 32px);text-align:center;box-sizing:border-box;"
            + "font:600 15px system-ui,sans-serif;color:#f3e9d0;background:#10292c;"
            + "border:1px solid #547970;border-radius:12px;pointer-events:none;")
        browser_document.body.appendChild(browser_rotate_hint)
    browser_rotate_hint.hidden = not portrait

func _browser_point(client: Vector2) -> Vector2:
    var rect: JavaScriptObject = browser_canvas.getBoundingClientRect()
    var bounds := Rect2(float(rect.left), float(rect.top), float(rect.width), float(rect.height))
    return browser_to_game(client, bounds, size)

func _begin_browser_touch(event: JavaScriptObject) -> void:
    if not mobile_layout:
        mobile_layout = true
        set_active(true)
        _update_browser_layout()
    using_touch = true
    event.preventDefault()
    event.stopImmediatePropagation()

func _on_browser_pointer(args: Array) -> void:
    if not gameplay_active or args.is_empty():
        return
    var event: JavaScriptObject = args[0]
    var pointer_type := str(event.pointerType)
    if pointer_type == "mouse" and move_finger < 0 and aim_finger < 0 and action_fingers.is_empty():
        using_touch = false
    if pointer_type != "touch":
        return
    var id := int(event.pointerId)
    var kind := str(event.type)
    if kind == "pointerup" or kind == "pointercancel" or kind == "lostpointercapture":
        _release_touch(id)
        return
    var point := _browser_point(Vector2(float(event.clientX), float(event.clientY)))
    if not point.is_finite():
        return
    if kind == "pointerdown" and Rect2(Vector2.ZERO, size).has_point(point):
        _begin_browser_touch(event)
        # Capture independently for each thumb, including when it leaves the canvas.
        browser_canvas.setPointerCapture(id)
        _try_touch(id, point)
    elif kind == "pointermove" and (id == move_finger or id == aim_finger):
        _drag_touch(id, point)

func _on_browser_touch(args: Array) -> void:
    if not gameplay_active or args.is_empty():
        return
    var event: JavaScriptObject = args[0]
    _begin_browser_touch(event)
    var kind := str(event.type)
    var changed: JavaScriptObject = event.changedTouches
    for i in range(int(changed.length)):
        var touch: JavaScriptObject = changed.item(i)
        var id := int(touch.identifier)
        if kind == "touchend" or kind == "touchcancel":
            _release_touch(id)
            continue
        var point := _browser_point(Vector2(float(touch.clientX), float(touch.clientY)))
        if not point.is_finite():
            continue
        if kind == "touchstart":
            _try_touch(id, point)
        elif kind == "touchmove":
            _drag_touch(id, point)

func _input(event: InputEvent) -> void:
    if not active:
        return
    if event is InputEventMouse:
        if browser_uses_pointers or event.device == InputEvent.DEVICE_ID_EMULATION:
            return
        if move_finger < 0 and aim_finger < 0 and action_fingers.is_empty():
            using_touch = false
        return
    if browser_canvas != null:
        return  # Web gameplay touch is handled by the canvas listener.
    if event is InputEventScreenTouch:
        var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
        using_touch = true
        if event.pressed and not event.canceled:
            _try_touch(event.index, point)
        else:
            _release_touch(event.index)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
        _drag_touch(event.index, point)
        get_viewport().set_input_as_handled()

func _try_touch(id: int, point: Vector2) -> void:
    for action in action_centers:
        if point.distance_to(action_centers[action]) > BUTTON_RADIUS + 4.0:
            continue
        action_fingers[id] = action
        queue_redraw()
        match action:
            "DASH":
                dash_pressed.emit()
            "RELOAD":
                # Give the next network input tick time to see a quick tap.
                reload_until = Time.get_ticks_msec() + 180
            "OPEN":
                chest_pressed.emit()
            "MENU":
                _open_menu_deferred.call_deferred()
        return
    if move_finger < 0 and point.distance_to(move_center) < STICK_REACH:
        move_finger = id
        _drag_touch(id, point)
    elif aim_finger < 0 and point.distance_to(aim_center) < STICK_REACH:
        aim_finger = id
        _drag_touch(id, point)

func _open_menu_deferred() -> void:
    if active:
        menu_pressed.emit()

func _release_touch(id: int) -> void:
    if id == move_finger:
        move_finger = -1
        move_vector = Vector2.ZERO
    if id == aim_finger:
        aim_finger = -1
        aim_vector = Vector2.ZERO
    action_fingers.erase(id)
    queue_redraw()

func _drag_touch(id: int, point: Vector2) -> void:
    if id == move_finger:
        move_vector = _stick_vector(point - move_center)
    elif id == aim_finger:
        aim_vector = _stick_vector(point - aim_center)
        if aim_vector.length_squared() > 0.0:
            last_aim = aim_vector.normalized()
    else:
        return
    queue_redraw()

func _stick_vector(delta: Vector2) -> Vector2:
    var strength := minf(1.0, delta.length() / STICK_RADIUS)
    if strength <= DEAD_ZONE:
        return Vector2.ZERO
    return delta.normalized() * ((strength - DEAD_ZONE) / (1.0 - DEAD_ZONE))

func _draw() -> void:
    if not active:
        return
    _draw_stick(move_center, move_vector, MINT, "MOVE")
    _draw_stick(aim_center, aim_vector, GOLD, "AIM + FIRE")
    for action in action_centers:
        var center: Vector2 = action_centers[action]
        var full: bool = action != "DASH" or dash_display < 1
        var rim: Color = GOLD if full else Color("#94e5a8")
        var down: bool = action_fingers.values().has(action)
        draw_circle(center, BUTTON_RADIUS, BASE if not down else Color(0.21, 0.35, 0.33, 0.95), true, -1.0, true)
        draw_arc(center, BUTTON_RADIUS, 0.0, TAU, 36, rim, 2.4, true)
        var title: String = str(action)
        if action == "DASH" and not full:
            title = "%.1fs" % (float(dash_display) / 10.0)
        _draw_caption(center, title, 19, rim)

func _draw_stick(center: Vector2, direction: Vector2, tint: Color, title: String) -> void:
    draw_circle(center, STICK_RADIUS, BASE, true, -1.0, true)
    draw_arc(center, STICK_RADIUS, 0.0, TAU, 44, tint, 2.6, true)
    draw_line(center - Vector2(58, 0), center + Vector2(58, 0), Color(tint, 0.23), 2.0)
    draw_line(center - Vector2(0, 58), center + Vector2(0, 58), Color(tint, 0.23), 2.0)
    var grip := center + direction * (STICK_RADIUS - 24.0)
    draw_circle(grip, 24.0, Color(tint, 0.52), true, -1.0, true)
    _draw_caption(center + Vector2(0, STICK_RADIUS + 14), title, 19, tint)

func _draw_caption(center: Vector2, title: String, size_px: int, tint: Color) -> void:
    var font := ThemeDB.fallback_font
    var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    draw_string(font, center + Vector2(-width * 0.5, size_px * 0.34), title,
        HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, tint)
