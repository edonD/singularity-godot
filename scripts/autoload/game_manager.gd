extends Node

## Global game state manager singleton.

signal game_paused
signal game_resumed
signal hitstop_started
signal hitstop_ended
signal day_changed(day: int)
signal player_died

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.PLAYING
var day: int = 1
var time_of_day: float = 0.0 # 0-1, 0=dawn, 0.5=dusk, 1=dawn
var day_length: float = 180.0 # seconds per full day
var is_night: bool = false

var player: Node2D = null
var player_stats: Dictionary = {
	"hp": 100,
	"max_hp": 100,
	"stamina": 100.0,
	"max_stamina": 100.0,
	"hunger": 100.0,
	"max_hunger": 100.0,
	"thirst": 100.0,
	"max_thirst": 100.0,
	"xp": 0,
	"level": 1,
	"xp_to_next": 100,
	"attack": 10,
	"defense": 5,
	"speed": 120.0,
	"sprint_speed": 200.0,
	"crit_chance": 0.1,
	"background": "soldier", # soldier, scientist, survivalist
}

# Emotional state system — ranges 0-100
var emotional_state: Dictionary = {
	"fear": 20,
	"determination": 50,
	"despair": 10,
	"hope": 40,
}

# Morality tracking — not good/evil, but pragmatic/compassionate/ruthless
var morality: Dictionary = {
	"pragmatic": 0,
	"compassionate": 0,
	"ruthless": 0,
}

# Dilemma history
var dilemma_history: Array[Dictionary] = [] # [{id, choice, day}]

# NEXUS awareness — how much NEXUS knows about you
var nexus_awareness: float = 0.0
var nexus_adaptation: Dictionary = {
	"stealth_counter": 0, # thermal sensors deployed
	"combat_counter": 0, # sentinels sent
	"hoard_counter": 0, # harvesters sent to base
}

# Hitstop
var _hitstop_timer: float = 0.0
var _is_hitstop: bool = false

# Kill tracking
var kills: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return

	# Hitstop processing
	if _is_hitstop:
		_hitstop_timer -= delta
		if _hitstop_timer <= 0.0:
			_is_hitstop = false
			Engine.time_scale = 1.0
			hitstop_ended.emit()
		return

	# Day/night cycle
	time_of_day += delta / day_length
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
		day_changed.emit(day)
		# Auto-save on new day
		if has_node("/root/SaveManager"):
			SaveManager.save_game()

	var was_night := is_night
	is_night = time_of_day > 0.35 and time_of_day < 0.85
	if is_night != was_night and is_night:
		pass # Night started - enemies get aggressive


func request_hitstop(duration: float = 0.05) -> void:
	if _is_hitstop:
		return
	_is_hitstop = true
	_hitstop_timer = duration
	Engine.time_scale = 0.05
	hitstop_started.emit()


func add_xp(amount: int) -> void:
	player_stats.xp += amount
	while player_stats.xp >= player_stats.xp_to_next:
		player_stats.xp -= player_stats.xp_to_next
		player_stats.level += 1
		player_stats.xp_to_next = int(player_stats.xp_to_next * 1.5)
		player_stats.max_hp += 10
		player_stats.hp = player_stats.max_hp
		player_stats.attack += 2
		player_stats.defense += 1
		# Grant skill point every level
		var st := get_tree().get_first_node_in_group("skill_tree")
		if st and st.has_method("add_skill_points"):
			st.add_skill_points(1)


func adjust_emotion(emotion: String, amount: int) -> void:
	if emotional_state.has(emotion):
		emotional_state[emotion] = clampi(emotional_state[emotion] + amount, 0, 100)


func get_dominant_emotion() -> String:
	var best_key := "determination"
	var best_val := 0
	for key: String in emotional_state:
		if emotional_state[key] > best_val:
			best_val = emotional_state[key]
			best_key = key
	return best_key


func record_dilemma(dilemma_id: String, choice: String) -> void:
	dilemma_history.append({"id": dilemma_id, "choice": choice, "day": day})


func add_morality(category: String, amount: int) -> void:
	if morality.has(category):
		morality[category] += amount


func apply_background(bg: String) -> void:
	player_stats.background = bg
	match bg:
		"soldier":
			player_stats.attack += 5
			player_stats.defense += 3
			player_stats.max_hp += 20
			player_stats.hp = player_stats.max_hp
		"scientist":
			player_stats.crit_chance += 0.1
			player_stats.max_stamina += 20.0
			player_stats.stamina = player_stats.max_stamina
		"survivalist":
			player_stats.max_hunger += 30.0
			player_stats.hunger = player_stats.max_hunger
			player_stats.max_thirst += 30.0
			player_stats.thirst = player_stats.max_thirst
			player_stats.speed += 15.0


func pause_game() -> void:
	if state == GameState.PLAYING:
		state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()


func resume_game() -> void:
	if state == GameState.PAUSED:
		state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()


func toggle_pause() -> void:
	if state == GameState.PLAYING:
		pause_game()
	elif state == GameState.PAUSED:
		resume_game()
