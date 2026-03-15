extends Node2D

## Helper node for drawing weather particles.

var _particles: Array[Dictionary] = []
var _weather_type: int = 0 # WeatherType enum value


func set_particles(particles: Array[Dictionary], weather_type: int) -> void:
	_particles = particles
	_weather_type = weather_type
	queue_redraw()


func _draw() -> void:
	match _weather_type:
		1: # RAIN
			for p in _particles:
				draw_line(p.pos, p.pos + Vector2(0, 4), Color(0.5, 0.6, 0.8, 0.4), 1.0)
		2: # SNOW
			for p in _particles:
				draw_rect(Rect2(p.pos, Vector2(2, 2)), Color(0.9, 0.9, 1.0, 0.6))
		4: # STORM
			for p in _particles:
				draw_line(p.pos, p.pos + Vector2(-2, 6), Color(0.6, 0.7, 0.9, 0.5), 1.5)
