extends Control

# ========================================================
# GAME COMPLETE SCREEN
# Shown when player finishes all 10 levels
# ========================================================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background
	_build_background()
	
	# Main content
	_build_content()
	
	# Play celebration sound
	AudioManager.play_win()

func _build_background() -> void:
	# Dark overlay with gradient feel
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.08, 0.12, 1.0)
	add_child(bg)
	
	# Background image (subtle)
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.modulate = Color(0.3, 0.3, 0.4, 0.5)  # Dimmed
	var tex = load("res://assets/backgrounds/background.png")
	if tex:
		bg_tex.texture = tex
	add_child(bg_tex)

func _build_content() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main panel
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	panel_style.border_color = Color(1.0, 0.85, 0.3, 0.9)  # Gold border
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(30)
	panel_style.shadow_color = Color(1.0, 0.8, 0.2, 0.2)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Trophy/celebration emoji or icon
	var trophy := Label.new()
	trophy.text = "🏆"
	trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy.add_theme_font_size_override("font_size", 52)
	vbox.add_child(trophy)
	
	# Main title
	var title := Label.new()
	title.text = "Félicitations !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Vous avez terminé Rush Hour !"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(subtitle)
	
	# Decorative separator
	var sep := HSeparator.new()
	sep.custom_minimum_size.x = 300
	vbox.add_child(sep)
	
	# Stats container
	var stats_panel := PanelContainer.new()
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.08, 0.1, 0.15, 0.8)
	stats_style.set_corner_radius_all(8)
	stats_style.set_content_margin_all(15)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	vbox.add_child(stats_panel)
	
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)
	
	# Levels completed
	var levels_row := _create_stat_row("Niveaux complétés", "10 / 10")
	stats_vbox.add_child(levels_row)
	
	# Medal summary
	var gold_count := _count_medals("gold")
	var silver_count := _count_medals("silver")
	var bronze_count := _count_medals("bronze")
	
	var medals_label := Label.new()
	medals_label.text = "Médailles obtenues"
	medals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medals_label.add_theme_font_size_override("font_size", 16)
	medals_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	stats_vbox.add_child(medals_label)
	
	var medals_row := HBoxContainer.new()
	medals_row.alignment = BoxContainer.ALIGNMENT_CENTER
	medals_row.add_theme_constant_override("separation", 25)
	stats_vbox.add_child(medals_row)
	
	# Gold medals
	var gold_box := _create_medal_stat("gold", gold_count)
	medals_row.add_child(gold_box)
	
	# Silver medals
	var silver_box := _create_medal_stat("silver", silver_count)
	medals_row.add_child(silver_box)
	
	# Bronze medals
	var bronze_box := _create_medal_stat("bronze", bronze_count)
	medals_row.add_child(bronze_box)
	
	# Achievement message based on medals
	var achievement := Label.new()
	if gold_count == 10:
		achievement.text = "★ Maître absolu ! Toutes les médailles d'or ! ★"
		achievement.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	elif gold_count >= 7:
		achievement.text = "Excellent ! Vous êtes un expert !"
		achievement.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	elif gold_count >= 4:
		achievement.text = "Très bien joué !"
		achievement.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	else:
		achievement.text = "Bien joué ! Rejouez pour améliorer vos scores !"
		achievement.add_theme_color_override("font_color", Color(0.85, 0.6, 0.3))
	achievement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement.add_theme_font_size_override("font_size", 16)
	vbox.add_child(achievement)
	
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_container)
	
	var btn_replay := Button.new()
	btn_replay.text = "↺ Rejouer"
	UIHelper.style_button(btn_replay)
	btn_replay.pressed.connect(_on_replay)
	btn_container.add_child(btn_replay)
	
	var btn_menu := Button.new()
	btn_menu.text = "⌂ Menu principal"
	UIHelper.style_primary_button(btn_menu)
	btn_menu.pressed.connect(_on_menu)
	btn_container.add_child(btn_menu)
	
	var btn_quit := Button.new()
	btn_quit.text = "✕ Quitter"
	UIHelper.style_secondary_button(btn_quit)
	btn_quit.pressed.connect(_on_quit)
	btn_container.add_child(btn_quit)
	
	# Animate entrance
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.7, 0.7)
	panel.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _create_stat_row(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 15)
	
	var label := Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	row.add_child(label)
	
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	row.add_child(value)
	
	return row

func _create_medal_stat(medal_type: String, count: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	match medal_type:
		"gold":
			icon.texture = load("res://assets/ui/medal_gold.png")
		"silver":
			icon.texture = load("res://assets/ui/medal_silver.png")
		"bronze":
			icon.texture = load("res://assets/ui/medal_bronze.png")
	
	# Center the icon
	var icon_center := CenterContainer.new()
	icon_center.add_child(icon)
	box.add_child(icon_center)
	
	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	box.add_child(count_label)
	
	return box

func _count_medals(medal_type: String) -> int:
	var count := 0
	for i in range(Levels.get_level_count()):
		if Levels.get_level_medal(i) == medal_type:
			count += 1
	return count

func _on_replay() -> void:
	AudioManager.play_button_click()
	Levels.reset_progress()
	Levels.set_level(0)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Start.tscn")

func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu()
