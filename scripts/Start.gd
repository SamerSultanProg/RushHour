extends Control

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_pressed)
	$LevelSelectButton.pressed.connect(_on_level_select_pressed)

func _on_play_pressed() -> void:
	Levels.set_level(0)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
