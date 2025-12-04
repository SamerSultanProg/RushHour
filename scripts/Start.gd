extends Control


func _ready() -> void:
	# Style all buttons
	UIHelper.style_button($PlayButton)
	UIHelper.style_button($LevelSelectButton)
	UIHelper.style_button($InstructionsButton)
	UIHelper.style_button($ConfigurationButton)
	
	$PlayButton.pressed.connect(_on_play_pressed)
	$LevelSelectButton.pressed.connect(_on_level_select_pressed)
	$InstructionsButton.pressed.connect(_on_instructions_pressed)
	$ConfigurationButton.pressed.connect(_on_configuration_pressed)

func _on_play_pressed() -> void:
	AudioManager.play_button_click()
	Levels.set_level(0)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_level_select_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_instructions_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")

func _on_configuration_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Configuration.tscn")
