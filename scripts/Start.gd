extends Control


func _ready() -> void:
	# Add background
	_build_background()
	
	# Style all buttons
	UIHelper.style_primary_button($PlayButton)  # Bouton principal en bleu accent
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

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load("res://assets/backgrounds/background.png")
	if tex:
		bg.texture = tex
	add_child(bg)
	move_child(bg, 0)
