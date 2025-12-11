extends Control


func _ready() -> void:
	# Setup arcade joystick button mappings FIRST (before any UI)
	_setup_arcade_inputs()
	
	# Add background
	_build_background()
	
	# Style all buttons
	UIHelper.style_primary_button($PlayButton)  # Bouton principal en bleu accent
	UIHelper.style_button($LevelSelectButton)
	UIHelper.style_button($InstructionsButton)
	UIHelper.style_button($ConfigurationButton)
	UIHelper.style_secondary_button($QuitButton)
	
	$PlayButton.pressed.connect(_on_play_pressed)
	$LevelSelectButton.pressed.connect(_on_level_select_pressed)
	$InstructionsButton.pressed.connect(_on_instructions_pressed)
	$ConfigurationButton.pressed.connect(_on_configuration_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	
	# Configure focus navigation for keyboard/joystick
	_setup_menu_focus()

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

func _on_quit_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().quit()

func _setup_menu_focus() -> void:
	var buttons := [$PlayButton, $LevelSelectButton, $InstructionsButton, $ConfigurationButton, $QuitButton]
	
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		btn.focus_mode = Control.FOCUS_ALL
		
		# Set vertical neighbors (up/down navigation)
		var prev_idx := (i - 1 + buttons.size()) % buttons.size()
		var next_idx := (i + 1) % buttons.size()
		
		btn.focus_neighbor_top = btn.get_path_to(buttons[prev_idx])
		btn.focus_neighbor_bottom = btn.get_path_to(buttons[next_idx])
		# Left/right also wrap vertically for convenience
		btn.focus_neighbor_left = btn.get_path_to(buttons[prev_idx])
		btn.focus_neighbor_right = btn.get_path_to(buttons[next_idx])
	
	# Give initial focus to Play button
	$PlayButton.grab_focus()

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

func _setup_arcade_inputs() -> void:
	# ==============================================
	# ARCADE BUTTON MAPPINGS (Godot 4.5 on RetroPie)
	# A = joy_button_3, B = joy_button_1
	# X = joy_button_0, Y = joy_button_2
	# Select = joy_button_4, Start = joy_button_6
	# ==============================================
	
	# Menu navigation: A = accept (select), B = cancel/back
	var ev_accept := InputEventJoypadButton.new()
	ev_accept.button_index = 3 as JoyButton  # A button
	InputMap.action_add_event("ui_accept", ev_accept)
	
	var ev_cancel := InputEventJoypadButton.new()
	ev_cancel.button_index = 1 as JoyButton  # B button
	InputMap.action_add_event("ui_cancel", ev_cancel)
	
	# Joystick navigation (up/down/left/right)
	# Axis 1 negative = up, positive = down
	# Axis 0 negative = left, positive = right
	var ev_up := InputEventJoypadMotion.new()
	ev_up.axis = JOY_AXIS_LEFT_Y
	ev_up.axis_value = -1.0
	InputMap.action_add_event("ui_up", ev_up)
	
	var ev_down := InputEventJoypadMotion.new()
	ev_down.axis = JOY_AXIS_LEFT_Y
	ev_down.axis_value = 1.0
	InputMap.action_add_event("ui_down", ev_down)
	
	var ev_left := InputEventJoypadMotion.new()
	ev_left.axis = JOY_AXIS_LEFT_X
	ev_left.axis_value = -1.0
	InputMap.action_add_event("ui_left", ev_left)
	
	var ev_right := InputEventJoypadMotion.new()
	ev_right.axis = JOY_AXIS_LEFT_X
	ev_right.axis_value = 1.0
	InputMap.action_add_event("ui_right", ev_right)
