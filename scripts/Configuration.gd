extends Control

signal back_pressed

var is_modal := false # Determines if it's an overlay or a full scene

func _ready() -> void:
	# Add background (only if not modal)
	if not is_modal:
		_build_background()
	
	# Masquer les éléments de base de la scène et créer une belle interface
	_hide_default_ui()
	_build_styled_ui()

func _hide_default_ui() -> void:
	# Cacher les éléments par défaut
	if has_node("VBoxContainer"):
		$VBoxContainer.visible = false
	if has_node("BackButton"):
		$BackButton.visible = false
	if has_node("Background"):
		$Background.visible = false

func _build_styled_ui() -> void:
	# Overlay semi-transparent
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	add_child(overlay)
	
	# Centre container
	var center := CenterContainer.new()
	center.anchor_right = 1
	center.anchor_bottom = 1
	add_child(center)
	
	# Panel principal avec style
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	panel_style.border_color = Color(0.5, 0.7, 1.0, 0.8)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(15)
	panel_style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	# Container principal vertical
	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 20)
	panel.add_child(main_box)
	
	# Titre
	var title := Label.new()
	title.text = "⚙ Configuration"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	main_box.add_child(title)
	
	# Séparateur
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	main_box.add_child(sep)
	
	# === Section Musique ===
	var music_section := _create_volume_section("🎵 Musique", AudioManager.get_music_volume_db() + 15, func(value):
		AudioManager.set_music_volume_db(linear_to_db(value) - 15)
	)
	main_box.add_child(music_section)
	
	# === Section Effets Sonores ===
	var sfx_section := _create_volume_section("🔊 Effets Sonores", AudioManager.get_sfx_volume_db(), func(value):
		AudioManager.set_sfx_volume_db(linear_to_db(value))
	)
	main_box.add_child(sfx_section)
	
	# Espaceur
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	main_box.add_child(spacer)
	
	# Bouton Retour
	var back_btn := Button.new()
	back_btn.text = "✓ Retour"
	back_btn.custom_minimum_size = Vector2(200, 50)
	_style_config_button(back_btn)
	back_btn.pressed.connect(func():
		AudioManager.play_button_click()
		if is_modal:
			back_pressed.emit()
		else:
			get_tree().change_scene_to_file("res://scenes/Start.tscn")
	)
	main_box.add_child(back_btn)

func _create_volume_section(label_text: String, initial_db: float, callback: Callable) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	# Container horizontal pour label et pourcentage
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	section.add_child(header)
	
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	
	var percent_label := Label.new()
	percent_label.add_theme_font_size_override("font_size", 18)
	percent_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	percent_label.custom_minimum_size.x = 50
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(percent_label)
	
	# Slider stylisé
	var slider := HSlider.new()
	slider.min_value = 0.0001
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = db_to_linear(initial_db)
	slider.custom_minimum_size = Vector2(280, 30)
	
	# Style du fond du slider (la piste)
	var slider_style := StyleBoxFlat.new()
	slider_style.bg_color = Color(0.25, 0.25, 0.35, 1.0)
	slider_style.set_corner_radius_all(6)
	slider_style.content_margin_top = 12
	slider_style.content_margin_bottom = 12
	slider.add_theme_stylebox_override("slider", slider_style)
	
	# Zone remplie (avant le curseur)
	var grabber_area := StyleBoxFlat.new()
	grabber_area.bg_color = Color(0.3, 0.6, 1.0, 1.0)
	grabber_area.set_corner_radius_all(6)
	grabber_area.content_margin_top = 12
	grabber_area.content_margin_bottom = 12
	slider.add_theme_stylebox_override("grabber_area", grabber_area)
	
	var grabber_area_hl := StyleBoxFlat.new()
	grabber_area_hl.bg_color = Color(0.4, 0.7, 1.0, 1.0)
	grabber_area_hl.set_corner_radius_all(6)
	grabber_area_hl.content_margin_top = 12
	grabber_area_hl.content_margin_bottom = 12
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_area_hl)
	
	# Curseur (le bouton qu'on déplace)
	slider.add_theme_icon_override("grabber", _create_grabber_texture(Color(0.9, 0.9, 1.0)))
	slider.add_theme_icon_override("grabber_highlight", _create_grabber_texture(Color(1.0, 1.0, 1.0)))
	
	section.add_child(slider)
	
	# Mise à jour du pourcentage
	var update_percent = func(value):
		percent_label.text = str(int(value * 100)) + "%"
		callback.call(value)
	
	slider.value_changed.connect(update_percent)
	update_percent.call(slider.value)  # Initialiser l'affichage
	
	return section

func _create_grabber_texture(color: Color) -> ImageTexture:
	# Créer une image circulaire pour le curseur du slider
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0 - 2
	
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				img.set_pixel(x, y, color)
			elif dist <= radius + 1:
				# Anti-aliasing simple
				var alpha := 1.0 - (dist - radius)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(img)

func _style_config_button(btn: Button) -> void:
	# Utilise le style standard de UIHelper
	UIHelper.style_button(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_button_click()
		if is_modal:
			back_pressed.emit()
		else:
			get_tree().change_scene_to_file("res://scenes/Start.tscn")

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
