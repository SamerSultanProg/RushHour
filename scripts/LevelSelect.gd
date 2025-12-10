extends Control

func _ready() -> void:
	# S'assurer que ce Control remplit tout l'écran
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background en premier
	_build_background()
	
	# CenterContainer qui remplit tout l'écran
	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	# Panel avec fond semi-transparent pour encadrer les boutons
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel_style.border_color = Color(0.4, 0.5, 0.7, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)

	# VBox principal
	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 20)
	panel.add_child(main_vbox)
	
	# Titre
	var title := Label.new()
	title.text = "Sélection de niveau"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	main_vbox.add_child(title)

	# GridContainer pour les boutons de niveau
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	main_vbox.add_child(grid)
	
	var count: int = Levels.get_level_count()
	for i in range(count):
		var level_container := VBoxContainer.new()
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.add_theme_constant_override("separation", 4)
		grid.add_child(level_container)
		
		var b := Button.new()
		b.text = "Niveau %d" % (i + 1)
		b.pressed.connect(func (): _load_level(i))
		UIHelper.style_button(b)
		level_container.add_child(b)
		
		# Add medal indicator if level is completed
		var medal_container := CenterContainer.new()
		medal_container.custom_minimum_size = Vector2(0, 24)
		level_container.add_child(medal_container)
		
		if Levels.is_level_completed(i):
			var medal_icon := TextureRect.new()
			medal_icon.custom_minimum_size = Vector2(24, 24)
			medal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			medal_icon.texture = _get_medal_texture(Levels.get_level_medal(i))
			medal_container.add_child(medal_icon)

	# Espaceur
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)

	# Container pour les boutons spéciaux
	var special_container := HBoxContainer.new()
	special_container.alignment = BoxContainer.ALIGNMENT_CENTER
	special_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(special_container)
	
	# Bouton niveau aléatoire
	var random_button := Button.new()
	random_button.text = "🎲 Niveau Aléatoire"
	random_button.pressed.connect(_load_random_level)
	UIHelper.style_button(random_button)
	special_container.add_child(random_button)
	
	# Bouton retour
	var back_button := Button.new()
	back_button.text = "← Retour"
	back_button.pressed.connect(_go_back)
	UIHelper.style_button(back_button)
	special_container.add_child(back_button)

func _load_level(idx: int) -> void:
	AudioManager.play_button_click()
	Levels.set_level(idx)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _load_random_level() -> void:
	AudioManager.play_button_click()
	
	# Generate a random level using procedural generation
	var generated := Solver.generate_level(5, 10)  # min 5 moves, max 10 cars
	
	var level_data := {"cars": generated["cars"]}
	var optimal_moves : int = generated["optimal_moves"]
	
	Levels.set_random_level(level_data, optimal_moves)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _go_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Start.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _get_medal_texture(medal: String) -> Texture2D:
	match medal:
		"gold":
			return load("res://assets/ui/medal_gold.png")
		"silver":
			return load("res://assets/ui/medal_silver.png")
		"bronze":
			return load("res://assets/ui/medal_bronze.png")
		_:
			return null

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load("res://assets/backgrounds/background.png")
	if tex:
		bg.texture = tex
	add_child(bg)
	move_child(bg, 0)
