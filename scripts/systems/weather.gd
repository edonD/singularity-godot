extends CanvasLayer

## Weather system — rain, snow, fog overlays based on biome and time.

enum WeatherType { CLEAR, RAIN, SNOW, FOG, STORM }

var current_weather: WeatherType = WeatherType.CLEAR
var _particles: Array[Dictionary] = []
var _overlay: ColorRect
var _weather_timer: float = 0.0
var _weather_duration: float = 60.0
var _draw_node: Node2D

const MAX_PARTICLES := 100


func _ready() -> void:
	layer = 5

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# We need a Node2D for drawing particles
	_draw_node = Node2D.new()
	_draw_node.z_index = 50
	# Weather draws in world space, but we add to our layer
	add_child(_draw_node)
	_draw_node.set_script(preload("res://scripts/systems/weather_draw.gd"))


func _process(delta: float) -> void:
	_weather_timer += delta

	# Change weather periodically
	if _weather_timer >= _weather_duration:
		_weather_timer = 0.0
		_weather_duration = randf_range(30.0, 90.0)
		_change_weather()

	_update_particles(delta)
	_update_overlay()


func _change_weather() -> void:
	var roll := randf()
	if GameManager.is_night:
		if roll < 0.3:
			current_weather = WeatherType.FOG
		elif roll < 0.5:
			current_weather = WeatherType.STORM
		else:
			current_weather = WeatherType.CLEAR
	else:
		if roll < 0.2:
			current_weather = WeatherType.RAIN
		elif roll < 0.3:
			current_weather = WeatherType.FOG
		else:
			current_weather = WeatherType.CLEAR


func _update_particles(delta: float) -> void:
	var target_count := 0
	match current_weather:
		WeatherType.RAIN:
			target_count = 80
		WeatherType.SNOW:
			target_count = 50
		WeatherType.STORM:
			target_count = MAX_PARTICLES

	# Add particles
	while _particles.size() < target_count:
		_particles.append(_create_particle())

	# Remove excess
	while _particles.size() > target_count:
		_particles.pop_back()

	# Update
	for p in _particles:
		p.pos += p.vel * delta
		# Reset if off screen
		if p.pos.y > 280 or p.pos.x > 500 or p.pos.x < -20:
			var np := _create_particle()
			p.pos = np.pos
			p.vel = np.vel

	if _draw_node and _draw_node.has_method("set_particles"):
		_draw_node.set_particles(_particles, current_weather)


func _create_particle() -> Dictionary:
	match current_weather:
		WeatherType.RAIN, WeatherType.STORM:
			return {
				"pos": Vector2(randf() * 480, randf() * -50),
				"vel": Vector2(randf_range(-20, 20), randf_range(200, 350)),
			}
		WeatherType.SNOW:
			return {
				"pos": Vector2(randf() * 480, randf() * -30),
				"vel": Vector2(randf_range(-15, 15), randf_range(20, 50)),
			}
	return {"pos": Vector2.ZERO, "vel": Vector2.ZERO}


func _update_overlay() -> void:
	match current_weather:
		WeatherType.FOG:
			_overlay.color = Color(0.3, 0.35, 0.4, 0.25)
		WeatherType.STORM:
			_overlay.color = Color(0.1, 0.1, 0.15, 0.15)
		_:
			_overlay.color = Color(0, 0, 0, 0)
