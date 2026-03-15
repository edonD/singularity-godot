extends Node

## Day/night cycle — controls CanvasModulate color and ambient feel.

var _canvas_mod: CanvasModulate
var _time_label_updating: bool = true

# Color palette for different times of day
const DAWN_COLOR := Color(0.9, 0.75, 0.65)
const DAY_COLOR := Color(1.0, 1.0, 1.0)
const DUSK_COLOR := Color(0.8, 0.55, 0.4)
const NIGHT_COLOR := Color(0.2, 0.2, 0.35)
const DEEP_NIGHT_COLOR := Color(0.12, 0.12, 0.25)


func _ready() -> void:
	await get_tree().process_frame
	# Find or create CanvasModulate
	_canvas_mod = get_tree().get_first_node_in_group("canvas_modulate") as CanvasModulate
	if not _canvas_mod:
		var parent := get_parent()
		while parent:
			for child in parent.get_children():
				if child is CanvasModulate:
					_canvas_mod = child
					break
			if _canvas_mod:
				break
			parent = parent.get_parent()


func _process(_delta: float) -> void:
	if not _canvas_mod:
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var t := GameManager.time_of_day
	var color: Color

	# Time phases:
	# 0.0-0.1: dawn
	# 0.1-0.35: day
	# 0.35-0.45: dusk
	# 0.45-0.75: night
	# 0.75-0.85: deep night
	# 0.85-1.0: pre-dawn

	if t < 0.1:
		# Dawn
		var p := t / 0.1
		color = DAWN_COLOR.lerp(DAY_COLOR, p)
	elif t < 0.35:
		color = DAY_COLOR
	elif t < 0.45:
		# Dusk
		var p := (t - 0.35) / 0.1
		color = DAY_COLOR.lerp(DUSK_COLOR, p)
	elif t < 0.55:
		var p := (t - 0.45) / 0.1
		color = DUSK_COLOR.lerp(NIGHT_COLOR, p)
	elif t < 0.75:
		color = NIGHT_COLOR
	elif t < 0.85:
		var p := (t - 0.75) / 0.1
		color = NIGHT_COLOR.lerp(DEEP_NIGHT_COLOR, p)
	else:
		# Pre-dawn
		var p := (t - 0.85) / 0.15
		color = DEEP_NIGHT_COLOR.lerp(DAWN_COLOR, p)

	_canvas_mod.color = color
