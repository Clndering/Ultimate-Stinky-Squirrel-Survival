class_name StinkyHudMeter
extends Control
## Small cached native HUD drawing: no extra shader passes or textures allocated per frame.
## mode is one of: health, ammo, dash.

var mode: String = "health"
var amount: float = 0.0
var capacity: float = 100.0
var reload: float = 0.0
var last_display_bucket: int = -1

func update_meter(new_amount: float, new_capacity: float, new_reload: float = 0.0) -> void:
    var bucket: int = int(round(new_amount * 10.0)) if mode == "dash" else int(round(new_amount))
    var new_max: float = maxf(0.01,new_capacity)
    if bucket == last_display_bucket and is_equal_approx(capacity,new_max) and absf(reload-new_reload)<0.1:
        return
    amount = clampf(new_amount,0.0,new_max)
    capacity = new_max
    reload = new_reload
    last_display_bucket = bucket
    queue_redraw()

func _draw() -> void:
    if mode == "dash":
        _draw_dash()
    elif mode == "xp":
        _draw_xp()
    elif mode == "ammo":
        _draw_ammo()
    else:
        _draw_health()

func _draw_health() -> void:
    var width: float = 266.0
    var height: float = 17.0
    var fraction: float = clampf(amount / capacity,0.0,1.0)
    draw_rect(Rect2(0,1,width,height), Color("071b20"))
    draw_rect(Rect2(1,2,width-2,height-2),Color("243b39"))
    var lit_width: float = (width - 6.0) * fraction
    if lit_width > 0.0:
        # 35 inexpensive vertical strips create a gold-to-coral gradient.
        var segments: int = maxi(1,int(ceil(lit_width/7.0)))
        var step: float = lit_width / float(segments)
        for i in range(segments):
            var x: float = 3.0 + float(i) * step
            var t: float = float(i)/maxf(1.0,float(segments-1))
            var fill: Color = Color("fff0a4").lerp(Color("fd736b"),t)
            draw_rect(Rect2(x,4,step+0.4,10),fill)
            draw_rect(Rect2(x,1,step+0.4,2),Color(fill.r,fill.g,fill.b,0.25))
        draw_rect(Rect2(3,5,lit_width,2),Color(1.0,0.97,0.80,0.50))
    draw_rect(Rect2(0,1,width,height),Color("e2b78a"),false,1.2)

func _draw_ammo() -> void:
    var total: int = maxi(1,int(round(capacity)))
    var left: int = maxi(0,mini(total,int(round(amount))))
    var columns: int = mini(total,14)
    var gap: float = 4.0
    var tick_width: float = maxf(6.0,minf(15.0,(240.0-float(columns-1)*gap)/float(columns)))
    var rows: int = ceili(float(total)/float(columns))
    var y_start: float = 20.0 if rows == 1 else 14.0
    var font: Font = ThemeDB.fallback_font
    var top_line: String = "↻  %.1f" % reload if reload > 0.0 else ("▮  %d / %d" % [left,total])
    draw_string(font,Vector2(0,11),top_line,HORIZONTAL_ALIGNMENT_LEFT,240,12,Color("ffe4a6"))
    for i in range(total):
        var col: int = i % columns
        var row: int = int(i / columns)
        var x: float = float(col)*(tick_width+gap)
        var y: float = y_start+float(row)*19.0
        var rect: Rect2 = Rect2(x,y,tick_width,13)
        if i < left:
            # Sparse, bounded glow per tick (not a full-screen bloom pass).
            draw_rect(Rect2(x-1,y-1,tick_width+2,15),Color(0.91,0.65,0.25,0.16))
            draw_rect(rect,Color("edb958"))
            draw_rect(Rect2(x+2,y+2,maxf(1.0,tick_width-4),4),Color("fff2b1"))
            draw_rect(rect,Color("f8d78c"),false,1.0)
        else:
            draw_rect(rect,Color("20383b"))
            draw_rect(rect,Color("57706b"),false,1.0)

func _draw_dash() -> void:
    var center: Vector2 = Vector2(38,36)
    var radius: float = 27.0
    var remaining: float = clampf(amount/capacity,0.0,1.0)
    var ready: bool = amount <= 0.045
    draw_circle(center,33,Color("0a2026"))
    draw_circle(center,30,Color("235052"))
    draw_circle(center,26,Color("0d262c"))
    draw_arc(center,radius,-PI/2.0,PI*1.5,64,Color("486c69"),5.0,true)
    var ring_color: Color = Color("a4ffe7") if ready else Color("ffcd82")
    if ready:
        draw_arc(center,radius,-PI/2.0,PI*1.5,64,ring_color,5.0,true)
    else:
        draw_arc(center,radius,-PI/2.0,-PI/2.0+TAU*(1.0-remaining),64,ring_color,5.0,true)
    var center_label: String = "0.0" if ready else ("%.1f" % amount)
    draw_string(ThemeDB.fallback_font,Vector2(22,43),center_label,HORIZONTAL_ALIGNMENT_CENTER,32,17,Color("f5f8e9"))
    draw_string(ThemeDB.fallback_font,Vector2(5,81),"SPACE",HORIZONTAL_ALIGNMENT_CENTER,67,11,Color("a5d8cf"))

func _draw_xp() -> void:
    # Stepped luminescent crystals with nearest-neighbor edges (never blurred).
    var width: float = maxf(250.0,size.x-1.0)
    var height: float = 11.0
    var percent: float = clampf(amount / maxf(1.0,capacity),0.0,1.0)
    draw_rect(Rect2(0,0,width,height),Color("061a20"))
    var ticks: int = 34
    var unit: float = (width - 4.0)/float(ticks)
    for i in range(ticks):
        var filled: bool = float(i+1)/float(ticks)<=percent
        var tint: Color = Color("89fbe2") if filled else Color("224f50")
        if filled and i%5==0:tint=Color("d2fff0")
        draw_rect(Rect2(2+i*unit,2,maxf(1.0,unit-1.7),7),tint)
    draw_rect(Rect2(0,0,width,height),Color("69cdb7"),false,1.0)
