extends Control
## Visual-only touch HUD. Touch ownership is handled by main.gd for multi-touch support.
var stick := Vector2.ZERO

func set_joystick(axis: Vector2) -> void:
    stick = axis
    queue_redraw()

func _draw() -> void:
    var screen := get_viewport_rect().size
    var base := Vector2(106, screen.y - 106)
    draw_circle(base, 69.0, Color(0.04, 0.12, 0.22, 0.35))
    draw_arc(base, 69.0, 0, TAU, 64, Color(0.88, 0.94, 1.0, 0.7), 3.0, true)
    draw_circle(base + Vector2(stick.x, -stick.y) * 46.0, 27.0, Color(0.65, 0.82, 1.0, 0.76))
    _button(Vector2(screen.x * 0.76, screen.y * 0.83), 50.0, "ATK", Color(0.62, 0.25, 0.18, 0.73))
    _button(Vector2(screen.x * 0.91, screen.y * 0.68), 40.0, "JUMP", Color(0.24, 0.45, 0.73, 0.7))
    _button(Vector2(screen.x * 0.91, screen.y * 0.90), 40.0, "DASH", Color(0.38, 0.30, 0.65, 0.7))

func _button(center: Vector2, radius: float, label: String, color: Color) -> void:
    draw_circle(center, radius, color)
    draw_arc(center, radius, 0, TAU, 48, Color(1, 1, 1, 0.65), 2.0, true)
    var font := ThemeDB.fallback_font
    draw_string(font, center + Vector2(-label.length() * 5.5, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
