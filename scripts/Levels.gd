extends Node

# =====================================================
# GESTION DES NIVEAUX
# =====================================================

var current_level_index : int = 0

# 10 niveaux — aucun overlap, tout tient dans une grille 6x6
# Tous les niveaux sont solvables, difficulté croissante
# (en nombre minimal de coups nécessaires pour libérer la voiture rouge).
var LEVELS := [
	{ "cars": [   # NIVEAU 1 - Intro (5 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":2,"y":0,"len":2,"dir":"V"},
		{"id":"B","x":3,"y":2,"len":3,"dir":"V"},
		{"id":"C","x":4,"y":0,"len":2,"dir":"V"}
	]},
	{ "cars": [   # NIVEAU 2 (5 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":1,"y":1,"len":3,"dir":"H"},
		{"id":"B","x":2,"y":3,"len":3,"dir":"V"},
		{"id":"C","x":0,"y":3,"len":3,"dir":"V"},
		{"id":"D","x":5,"y":3,"len":3,"dir":"V"},
		{"id":"E","x":5,"y":1,"len":2,"dir":"V"}
	]},
	{ "cars": [   # NIVEAU 3 (6 moves)
		{"id":"R","x":1,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":0,"y":2,"len":2,"dir":"V"},
		{"id":"B","x":2,"y":4,"len":2,"dir":"V"},
		{"id":"C","x":4,"y":2,"len":2,"dir":"V"},
		{"id":"D","x":5,"y":1,"len":3,"dir":"V"}
	]},
	{ "cars": [   # NIVEAU 4 (9 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":3,"y":1,"len":3,"dir":"V"},
		{"id":"B","x":0,"y":4,"len":3,"dir":"H"},
		{"id":"C","x":2,"y":5,"len":3,"dir":"H"},
		{"id":"D","x":5,"y":1,"len":2,"dir":"V"},
		{"id":"E","x":1,"y":0,"len":2,"dir":"H"}
	]},
	{ "cars": [   # NIVEAU 5 (8 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":4,"y":4,"len":2,"dir":"H"},
		{"id":"B","x":3,"y":0,"len":2,"dir":"H"},
		{"id":"C","x":5,"y":1,"len":3,"dir":"V"},
		{"id":"D","x":1,"y":4,"len":3,"dir":"H"},
		{"id":"E","x":4,"y":2,"len":2,"dir":"V"}
	]},
	{ "cars": [   # NIVEAU 6 (10 moves)
		{"id":"R","x":1,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":3,"y":3,"len":3,"dir":"V"},
		{"id":"B","x":0,"y":5,"len":3,"dir":"H"},
		{"id":"C","x":4,"y":0,"len":3,"dir":"V"},
		{"id":"D","x":4,"y":4,"len":2,"dir":"H"},
		{"id":"E","x":0,"y":1,"len":2,"dir":"V"},
		{"id":"G","x":1,"y":0,"len":2,"dir":"V"}
	]},
	{ "cars": [   # NIVEAU 7 (12 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":5,"y":0,"len":2,"dir":"V"},
		{"id":"B","x":0,"y":0,"len":2,"dir":"H"},
		{"id":"C","x":3,"y":2,"len":3,"dir":"V"},
		{"id":"D","x":2,"y":1,"len":2,"dir":"V"},
		{"id":"E","x":2,"y":0,"len":2,"dir":"H"},
		{"id":"F","x":0,"y":3,"len":2,"dir":"V"},
		{"id":"G","x":1,"y":5,"len":2,"dir":"H"}
	]},
	{ "cars": [   # NIVEAU 8 (14 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":0,"y":1,"len":2,"dir":"H"},
		{"id":"B","x":3,"y":0,"len":3,"dir":"V"},
		{"id":"C","x":4,"y":3,"len":2,"dir":"V"},
		{"id":"D","x":0,"y":3,"len":3,"dir":"H"},
		{"id":"E","x":0,"y":0,"len":2,"dir":"H"},
		{"id":"F","x":0,"y":4,"len":2,"dir":"V"},
		{"id":"G","x":4,"y":0,"len":2,"dir":"H"}
	]},
	{ "cars": [   # NIVEAU 9 (15 moves)
		{"id":"R","x":2,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":4,"y":4,"len":2,"dir":"H"},
		{"id":"B","x":2,"y":3,"len":3,"dir":"V"},
		{"id":"C","x":0,"y":5,"len":2,"dir":"H"},
		{"id":"D","x":4,"y":1,"len":3,"dir":"V"},
		{"id":"E","x":5,"y":1,"len":2,"dir":"V"},
		{"id":"F","x":3,"y":0,"len":2,"dir":"H"}
	]},
	{ "cars": [   # NIVEAU 10 (18 moves)
		{"id":"R","x":0,"y":2,"len":2,"dir":"H"},
		{"id":"A","x":0,"y":5,"len":2,"dir":"H"},
		{"id":"B","x":2,"y":1,"len":2,"dir":"V"},
		{"id":"C","x":1,"y":4,"len":3,"dir":"H"},
		{"id":"D","x":4,"y":3,"len":2,"dir":"H"},
		{"id":"E","x":5,"y":0,"len":2,"dir":"V"},
		{"id":"F","x":0,"y":3,"len":2,"dir":"V"},
		{"id":"G","x":1,"y":0,"len":2,"dir":"H"}
	]}
]

func get_level():
	return LEVELS[current_level_index]

func set_level(idx : int) -> void:
	current_level_index = clamp(idx, 0, LEVELS.size() - 1)

func go_to_next_level() -> void:
	if current_level_index < LEVELS.size() - 1:
		current_level_index += 1

func get_current_index() -> int:
	return current_level_index

func get_level_count() -> int:
	return LEVELS.size()
