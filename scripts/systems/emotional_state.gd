extends Node

## Emotional State System — tracks fear, determination, despair, hope.
## Emotions affect gameplay: dialogue options, ability effectiveness, visual effects.
## Events trigger emotion changes organically.

signal emotion_changed(emotion: String, value: int)
signal dominant_emotion_changed(emotion: String)

var _last_dominant: String = "determination"
var _decay_timer: float = 0.0
const DECAY_INTERVAL := 30.0 # Emotions drift toward neutral every 30s

# Thresholds for gameplay effects
const HIGH_THRESHOLD := 70
const LOW_THRESHOLD := 30
const CRITICAL_THRESHOLD := 85


func _ready() -> void:
	add_to_group("emotional_state")


func _process(delta: float) -> void:
	_decay_timer += delta
	if _decay_timer >= DECAY_INTERVAL:
		_decay_timer = 0.0
		_decay_emotions()

	# Check for dominant emotion change
	var current := GameManager.get_dominant_emotion()
	if current != _last_dominant:
		_last_dominant = current
		dominant_emotion_changed.emit(current)

	# Apply emotional gameplay effects
	_apply_effects()


func _decay_emotions() -> void:
	var emo := GameManager.emotional_state
	# All emotions drift toward 30 (baseline)
	for key: String in emo:
		if emo[key] > 35:
			GameManager.adjust_emotion(key, -2)
		elif emo[key] < 25:
			GameManager.adjust_emotion(key, 1)


func _apply_effects() -> void:
	var emo := GameManager.emotional_state
	var s := GameManager.player_stats

	# Fear effects — high fear reduces attack but increases speed (fight or flight)
	if emo.fear >= HIGH_THRESHOLD:
		# Visual: slight screen tremor handled by camera
		pass

	# Determination effects — high determination boosts damage and stamina regen
	# (applied in player controller checks)

	# Despair effects — high despair slows everything
	# Hope effects — high hope boosts healing and XP gain


func get_emotion_modifier(stat: String) -> float:
	## Returns a multiplier based on emotional state for a given stat.
	var emo := GameManager.emotional_state
	var mod := 1.0

	match stat:
		"attack":
			# Determination boosts, fear/despair reduce
			if emo.determination >= HIGH_THRESHOLD:
				mod += 0.15
			if emo.fear >= HIGH_THRESHOLD:
				mod -= 0.1
			if emo.despair >= HIGH_THRESHOLD:
				mod -= 0.15
		"speed":
			# Fear increases speed (adrenaline), despair reduces
			if emo.fear >= HIGH_THRESHOLD:
				mod += 0.1
			if emo.despair >= HIGH_THRESHOLD:
				mod -= 0.1
			if emo.hope >= HIGH_THRESHOLD:
				mod += 0.05
		"healing":
			# Hope boosts healing, despair reduces
			if emo.hope >= HIGH_THRESHOLD:
				mod += 0.3
			if emo.despair >= HIGH_THRESHOLD:
				mod -= 0.2
		"xp":
			# Determination and hope boost XP
			if emo.determination >= HIGH_THRESHOLD:
				mod += 0.15
			if emo.hope >= HIGH_THRESHOLD:
				mod += 0.1
		"stamina_regen":
			# Determination boosts, despair tanks
			if emo.determination >= HIGH_THRESHOLD:
				mod += 0.2
			if emo.despair >= HIGH_THRESHOLD:
				mod -= 0.25
		"crit_chance":
			# Fear and determination can trigger crits
			if emo.fear >= CRITICAL_THRESHOLD:
				mod += 0.15 # Desperate critical strikes
			if emo.determination >= CRITICAL_THRESHOLD:
				mod += 0.1

	return mod


func on_enemy_killed() -> void:
	GameManager.adjust_emotion("determination", 3)
	GameManager.adjust_emotion("fear", -2)
	GameManager.adjust_emotion("hope", 1)


func on_player_damaged(percent_lost: float) -> void:
	# Losing health increases fear
	var fear_gain := int(percent_lost * 30)
	GameManager.adjust_emotion("fear", fear_gain)
	GameManager.adjust_emotion("determination", -1)


func on_near_death() -> void:
	# Below 15% HP
	GameManager.adjust_emotion("fear", 15)
	GameManager.adjust_emotion("despair", 10)


func on_healing() -> void:
	GameManager.adjust_emotion("fear", -5)
	GameManager.adjust_emotion("hope", 3)


func on_npc_helped() -> void:
	GameManager.adjust_emotion("hope", 8)
	GameManager.adjust_emotion("determination", 5)
	GameManager.adjust_emotion("despair", -5)


func on_npc_abandoned() -> void:
	GameManager.adjust_emotion("despair", 5)
	GameManager.adjust_emotion("hope", -3)


func on_night_survived() -> void:
	GameManager.adjust_emotion("determination", 5)
	GameManager.adjust_emotion("hope", 3)
	GameManager.adjust_emotion("fear", -5)


func on_shelter_lost() -> void:
	GameManager.adjust_emotion("despair", 15)
	GameManager.adjust_emotion("hope", -10)
	GameManager.adjust_emotion("fear", 10)


func on_discovery() -> void:
	# Found a terminal, lore, secret area
	GameManager.adjust_emotion("hope", 5)
	GameManager.adjust_emotion("determination", 3)


func on_starvation() -> void:
	GameManager.adjust_emotion("despair", 5)
	GameManager.adjust_emotion("hope", -3)
	GameManager.adjust_emotion("determination", -2)


func get_available_dialogue_options() -> Array[String]:
	## Returns extra dialogue options based on emotional state.
	var options: Array[String] = []
	var emo := GameManager.emotional_state

	if emo.fear >= HIGH_THRESHOLD:
		options.append("fearful") # Panicked dialogue options
	if emo.determination >= HIGH_THRESHOLD:
		options.append("determined") # Bold/aggressive dialogue
	if emo.despair >= HIGH_THRESHOLD:
		options.append("despairing") # Nihilistic/giving up options
	if emo.hope >= HIGH_THRESHOLD:
		options.append("hopeful") # Optimistic/inspiring dialogue

	return options
