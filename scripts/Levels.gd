extends Node

# =====================================================
# GESTION DES NIVEAUX
# =====================================================

var current_level_index : int = 0

# Track completed levels and their best medal for the session
# Key: level index, Value: medal type ("gold", "silver", "bronze")
var completed_levels : Dictionary = {}

# Random level support
var is_random_level : bool = false
var random_level_data : Dictionary = {}
var random_level_optimal : int = 0

# 10 niveaux — aucun overlap, tout tient dans une grille 6x6
# Tous les niveaux sont solvables, difficulté croissante
# (en nombre minimal de coups nécessaires pour libérer la voiture rouge).
var LEVELS := [
	{ "cars": [   # NIVEAU 1 - R at (2,2), needs to exit right
		{"id":"R", "x":2, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":4, "y":4, "len":2, "dir":"H"},
		{"id":"F", "x":3, "y":3, "len":2, "dir":"V"},
		{"id":"A", "x":4, "y":0, "len":3, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 2 - R at (0,2)
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":0, "y":0, "len":2, "dir":"V"},
		{"id":"F", "x":2, "y":4, "len":2, "dir":"V"},
		{"id":"A", "x":3, "y":5, "len":3, "dir":"H"},
		{"id":"G", "x":4, "y":3, "len":2, "dir":"H"},
		{"id":"B", "x":5, "y":0, "len":3, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 3 - R at (0,2)
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"A", "x":2, "y":0, "len":3, "dir":"V"},
		{"id":"E", "x":2, "y":4, "len":2, "dir":"H"},
		{"id":"F", "x":1, "y":3, "len":2, "dir":"V"},
		{"id":"B", "x":4, "y":3, "len":3, "dir":"V"},
		{"id":"G", "x":5, "y":1, "len":2, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 4 - R at (0,2)
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":2, "y":1, "len":2, "dir":"V"},
		{"id":"A", "x":2, "y":0, "len":3, "dir":"H"},
		{"id":"B", "x":5, "y":0, "len":3, "dir":"V"},
		{"id":"F", "x":4, "y":4, "len":2, "dir":"H"},
		{"id":"G", "x":2, "y":4, "len":2, "dir":"H"}
	]},
	{ "cars": [   # NIVEAU 5 - R at (0,2)
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"A", "x":2, "y":0, "len":3, "dir":"V"},
		{"id":"E", "x":1, "y":4, "len":2, "dir":"H"},
		{"id":"F", "x":0, "y":4, "len":2, "dir":"V"},
		{"id":"B", "x":4, "y":3, "len":3, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 6 - R at (0,2)
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"A", "x":2, "y":2, "len":3, "dir":"V"},
		{"id":"E", "x":2, "y":0, "len":2, "dir":"V"},
		{"id":"B", "x":0, "y":5, "len":3, "dir":"H"},
		{"id":"C", "x":5, "y":3, "len":3, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 7 - R at (2,2)
		{"id":"R", "x":2, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":2, "y":1, "len":2, "dir":"H"},
		{"id":"F", "x":4, "y":0, "len":2, "dir":"V"},
		{"id":"A", "x":5, "y":0, "len":3, "dir":"V"},
		{"id":"G", "x":4, "y":2, "len":2, "dir":"V"},
		{"id":"D", "x":4, "y":4, "len":2, "dir":"H"},
		{"id":"C", "x":3, "y":4, "len":2, "dir":"V"},
		{"id":"B", "x":2, "y":3, "len":3, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 8 - Simplified to use only available assets
		{"id":"R", "x":0, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":0, "y":4, "len":2, "dir":"V"},
		{"id":"A", "x":1, "y":4, "len":3, "dir":"H"},
		{"id":"F", "x":4, "y":4, "len":2, "dir":"V"},
		{"id":"G", "x":4, "y":2, "len":2, "dir":"V"},
		{"id":"B", "x":5, "y":1, "len":3, "dir":"V"},
		{"id":"C", "x":3, "y":0, "len":2, "dir":"V"},
		{"id":"D", "x":4, "y":0, "len":2, "dir":"H"}
	]},
	{ "cars": [   # NIVEAU 9 - Simplified to use only available assets
		{"id":"R", "x":2, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":1, "y":0, "len":2, "dir":"H"},
		{"id":"F", "x":1, "y":1, "len":2, "dir":"V"},
		{"id":"G", "x":3, "y":0, "len":2, "dir":"V"},
		{"id":"A", "x":5, "y":1, "len":3, "dir":"V"},
		{"id":"B", "x":4, "y":3, "len":3, "dir":"V"},
		{"id":"C", "x":4, "y":1, "len":2, "dir":"V"},
		{"id":"D", "x":2, "y":3, "len":2, "dir":"V"}
	]},
	{ "cars": [   # NIVEAU 10 - Simplified to use only available assets
		{"id":"R", "x":2, "y":2, "len":2, "dir":"H"},
		{"id":"E", "x":0, "y":0, "len":2, "dir":"H"},
		{"id":"F", "x":2, "y":0, "len":2, "dir":"V"},
		{"id":"G", "x":4, "y":0, "len":2, "dir":"H"},
		{"id":"C", "x":4, "y":2, "len":2, "dir":"V"},
		{"id":"A", "x":2, "y":4, "len":3, "dir":"H"},
		{"id":"D", "x":5, "y":4, "len":2, "dir":"V"},
		{"id":"B", "x":0, "y":4, "len":2, "dir":"H"}
	]}
]

# Optimal moves for each level (index 0 = level 1, etc.)
# Gold = exact optimal, Silver = up to 5 over, Bronze = more than 5 over
var OPTIMAL_MOVES := [5, 5, 12, 5, 11, 8, 9, 10, 11, 8]

func get_level():
	if is_random_level:
		return random_level_data
	return LEVELS[current_level_index]

func set_level(idx : int) -> void:
	is_random_level = false
	current_level_index = clamp(idx, 0, LEVELS.size() - 1)

func set_random_level(level_data: Dictionary, optimal_moves: int) -> void:
	is_random_level = true
	random_level_data = level_data
	random_level_optimal = optimal_moves

func is_playing_random() -> bool:
	return is_random_level

func go_to_next_level() -> void:
	if current_level_index < LEVELS.size() - 1:
		current_level_index += 1

func get_current_index() -> int:
	return current_level_index

func get_level_count() -> int:
	return LEVELS.size()

# =====================================================
# COMPLETION TRACKING
# =====================================================

func mark_level_completed(level_index: int, move_count: int) -> void:
	var medal := get_medal_for_moves(level_index, move_count)
	
	# Only update if this is a better medal or first completion
	if not completed_levels.has(level_index):
		completed_levels[level_index] = medal
	else:
		var current_medal = completed_levels[level_index]
		if _medal_rank(medal) > _medal_rank(current_medal):
			completed_levels[level_index] = medal

func get_medal_for_moves(level_index: int, moves: int) -> String:
	var optimal: int
	if is_random_level:
		optimal = random_level_optimal
	else:
		optimal = OPTIMAL_MOVES[level_index]
	if moves <= optimal:
		return "gold"
	elif moves <= optimal + 5:
		return "silver"
	else:
		return "bronze"

func get_optimal_moves_for_current() -> int:
	if is_random_level:
		return random_level_optimal
	return OPTIMAL_MOVES[current_level_index]

func _medal_rank(medal: String) -> int:
	# Higher rank = better medal
	match medal:
		"gold": return 3
		"silver": return 2
		"bronze": return 1
		_: return 0

func is_level_completed(level_index: int) -> bool:
	return completed_levels.has(level_index)

func get_level_medal(level_index: int) -> String:
	if completed_levels.has(level_index):
		return completed_levels[level_index]
	return ""

func reset_progress() -> void:
	completed_levels.clear()
