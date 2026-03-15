extends Node2D

## Simple particle effect for dust, impacts, etc.

var particles: Array[Dictionary] = []
var _lifetime: float = 0.5


func emit_burst(pos: Vector2, count: int = 8, color: Color = Color(0.6, 0.5, 0.4, 0.8), spread: float = 50.0) -> void:
	global_position = pos
	for i in count:
		var angle := randf() * TAU
		var speed := randf_range(20.0, spread)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.2, _lifetime),
			"max_life": _lifetime,
			"size": randf_range(1.0, 3.0),
			"color": color,
		})


func _process(delta: float) -> void:
	var alive := false
	for p in particles:
		p.life -= delta
		if p.life > 0:
			p.pos += p.vel * delta
			p.vel *= 0.95
			alive = true

	queue_redraw()

	if not alive and particles.size() > 0:
		queue_free()


func _draw() -> void:
	for p in particles:
		if p.life > 0:
			var alpha := p.life / p.max_life
			var c: Color = p.color
			c.a *= alpha
			draw_rect(Rect2(p.pos - Vector2(p.size, p.size) * 0.5, Vector2(p.size, p.size)), c)
