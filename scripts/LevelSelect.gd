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
		var b := Button.new()
		b.text = "Niveau %d" % (i + 1)
		b.pressed.connect(func (): _load_level(i))
		UIHelper.style_button(b)
		grid.add_child(b)

	# Espaceur
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)

	# Bouton retour centré
	var back_container := CenterContainer.new()
	main_vbox.add_child(back_container)
	
	var back_button := Button.new()
	back_button.text = "← Retour"
	back_button.pressed.connect(_go_back)
	UIHelper.style_button(back_button)
	back_container.add_child(back_button)

func _load_level(idx: int) -> void:
	AudioManager.play_button_click()
	Levels.set_level(idx)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _go_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Start.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

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
