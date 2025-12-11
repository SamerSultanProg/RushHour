extends Control

# =====================================================
# TUTORIEL INTERACTIF AVEC DRAG & DROP
# =====================================================

const CELL : int = 64
const GRID_SIZE : int = 6

# Niveau tutoriel ultra simple
var tutorial_cars : Array = [
	{"id": "R", "x": 0, "y": 2, "len": 2, "dir": "H"},
	{"id": "A", "x": 2, "y": 1, "len": 2, "dir": "V"},
]

# Solution du tutoriel
var solution_steps : Array = [
	{"car": "A", "direction": "down", "cells": 2, "text": "1. Glissez la voiture bleue vers le bas"},
	{"car": "R", "direction": "right", "cells": 4, "text": "2. Glissez la voiture rouge vers la sortie !"},
]

var current_step : int = 0
var car_sprites : Dictionary = {}
var car_data_map : Dictionary = {}  # Pour stocker les données de chaque voiture
var tutorial_board : Control = null
var step_label : Label = null
var arrow_indicator : Control = null
var auto_demo_timer : Timer = null
var is_auto_demo : bool = false

# Variables pour le drag & drop
var dragging_car : Control = null
var drag_offset : Vector2 = Vector2.ZERO
var drag_start_pos : Vector2 = Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Cacher les éléments de la scène par défaut
	if has_node("BackButton"):
		$BackButton.visible = false
	if has_node("Label"):
		$Label.visible = false
	
	_build_background()
	_build_ui()

func _build_background() -> void:
	var bg = TextureRect.new()
	bg.name = "BackgroundImg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load("res://assets/backgrounds/background.png")
	if tex:
		bg.texture = tex
	add_child(bg)
	move_child(bg, 0)

func _build_ui() -> void:
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 30)
	add_child(main_hbox)
	
	var margin_left = Control.new()
	margin_left.custom_minimum_size.x = 40
	main_hbox.add_child(margin_left)
	
	var left_panel = _create_left_panel()
	main_hbox.add_child(left_panel)
	
	var right_panel = _create_right_panel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_panel)
	
	var margin_right = Control.new()
	margin_right.custom_minimum_size.x = 40
	main_hbox.add_child(margin_right)

func _create_left_panel() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var title = Label.new()
	title.text = "Demonstration"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	container.add_child(title)
	
	var board_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.4, 0.5, 0.7, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(15)
	board_panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(board_panel)
	
	var board_center = CenterContainer.new()
	board_panel.add_child(board_center)
	
	tutorial_board = Control.new()
	tutorial_board.custom_minimum_size = Vector2(GRID_SIZE * CELL, GRID_SIZE * CELL)
	board_center.add_child(tutorial_board)
	
	var board_bg = ColorRect.new()
	board_bg.color = Color(0.15, 0.15, 0.2, 1.0)
	board_bg.size = Vector2(GRID_SIZE * CELL, GRID_SIZE * CELL)
	tutorial_board.add_child(board_bg)
	
	_draw_grid()
	_draw_exit_indicator()
	_create_tutorial_cars()
	
	arrow_indicator = _create_arrow_indicator()
	tutorial_board.add_child(arrow_indicator)
	
	# Instruction label
	step_label = Label.new()
	step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_label.add_theme_font_size_override("font_size", 16)
	step_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_label.custom_minimum_size.x = GRID_SIZE * CELL
	container.add_child(step_label)
	
	# Hint label
	var hint_label = Label.new()
	hint_label.text = "(Deplacez les voitures avec la souris !)"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	container.add_child(hint_label)
	
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 10)
	container.add_child(btn_container)
	
	var btn_reset = Button.new()
	btn_reset.text = "Reset"
	UIHelper.style_button(btn_reset)
	btn_reset.pressed.connect(_reset_tutorial)
	btn_container.add_child(btn_reset)
	
	var btn_auto = Button.new()
	btn_auto.text = "Auto"
	UIHelper.style_primary_button(btn_auto)
	btn_auto.pressed.connect(_toggle_auto_demo)
	btn_container.add_child(btn_auto)
	
	auto_demo_timer = Timer.new()
	auto_demo_timer.wait_time = 1.5
	auto_demo_timer.one_shot = true
	auto_demo_timer.timeout.connect(_auto_demo_step)
	add_child(auto_demo_timer)
	
	_update_step_display()
	
	return container

func _create_right_panel() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.92)
	panel_style.border_color = Color(0.4, 0.5, 0.7, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(panel)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	
	var title = Label.new()
	title.text = "Comment jouer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	content.add_child(title)
	
	var sep = HSeparator.new()
	content.add_child(sep)
	
	_add_instruction_item(content, "Objectif", "Faites sortir la voiture rouge par le cote droit du plateau.")
	_add_instruction_item(content, "Deplacement", "Cliquez et glissez les voitures pour les deplacer.")
	_add_instruction_item(content, "Axe de mouvement", "Chaque voiture ne peut se deplacer que sur son axe (horizontal ou vertical).")
	_add_instruction_item(content, "Strategie", "Liberez le chemin en deplacant les voitures qui bloquent.")
	_add_instruction_item(content, "Progression", "Completez les 10 niveaux pour maitriser le jeu !")
	
	var btn_container = CenterContainer.new()
	container.add_child(btn_container)
	
	var back_btn = Button.new()
	back_btn.text = "Retour au menu"
	UIHelper.style_button(back_btn)
	back_btn.pressed.connect(_go_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	btn_container.add_child(back_btn)
	
	# Give focus to the back button for keyboard/joystick navigation
	back_btn.call_deferred("grab_focus")
	
	return container

func _add_instruction_item(parent: Control, title_text: String, desc_text: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	parent.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size.x = 300
	vbox.add_child(desc_lbl)

func _draw_grid() -> void:
	for i in range(GRID_SIZE + 1):
		var h_line = ColorRect.new()
		h_line.color = Color(0.3, 0.3, 0.4, 0.5)
		h_line.position = Vector2(0, i * CELL)
		h_line.size = Vector2(GRID_SIZE * CELL, 1)
		tutorial_board.add_child(h_line)
		
		var v_line = ColorRect.new()
		v_line.color = Color(0.3, 0.3, 0.4, 0.5)
		v_line.position = Vector2(i * CELL, 0)
		v_line.size = Vector2(1, GRID_SIZE * CELL)
		tutorial_board.add_child(v_line)

func _draw_exit_indicator() -> void:
	var exit = ColorRect.new()
	exit.color = Color(0.2, 0.8, 0.3, 0.8)
	exit.position = Vector2(GRID_SIZE * CELL - 4, 2 * CELL + 10)
	exit.size = Vector2(8, CELL - 20)
	tutorial_board.add_child(exit)
	
	var exit_label = Label.new()
	exit_label.text = "SORTIE"
	exit_label.rotation = -PI / 2.0
	exit_label.position = Vector2(GRID_SIZE * CELL + 18, 2 * CELL + 50)
	exit_label.add_theme_font_size_override("font_size", 12)
	exit_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	tutorial_board.add_child(exit_label)

func _create_tutorial_cars() -> void:
	for car_data in tutorial_cars:
		var car = _create_car_sprite(car_data)
		var car_id : String = str(car_data.id)
		car_sprites[car_id] = car
		car_data_map[car_id] = car_data.duplicate()
		tutorial_board.add_child(car)

func _create_car_sprite(car_data: Dictionary) -> Control:
	var car = Control.new()
	car.name = "Car_" + str(car_data.id)
	
	var car_len : int = int(car_data.len)
	var car_x : int = int(car_data.x)
	var car_y : int = int(car_data.y)
	var car_dir : String = str(car_data.dir)
	
	var width : int = CELL
	var height : int = CELL
	
	if car_dir == "H":
		width = car_len * CELL
		height = CELL
	else:
		width = CELL
		height = car_len * CELL
	
	car.position = Vector2(car_x * CELL, car_y * CELL)
	car.size = Vector2(width, height)
	
	# Fond avec dégradé simulé
	var bg = ColorRect.new()
	bg.name = "Background"
	if car_data.id == "R":
		bg.color = Color(0.85, 0.15, 0.15, 1.0)
	else:
		bg.color = Color(0.25, 0.45, 0.85, 1.0)
	bg.size = Vector2(width - 4, height - 4)
	bg.position = Vector2(2, 2)
	car.add_child(bg)
	
	# Highlight (effet 3D)
	var highlight = ColorRect.new()
	if car_data.id == "R":
		highlight.color = Color(1.0, 0.5, 0.5, 0.4)
	else:
		highlight.color = Color(0.6, 0.8, 1.0, 0.4)
	highlight.size = Vector2(width - 8, (height - 8) / 2)
	highlight.position = Vector2(4, 4)
	car.add_child(highlight)
	
	# Bordure arrondie (simulée)
	var border = ColorRect.new()
	border.name = "Border"
	if car_data.id == "R":
		border.color = Color(0.6, 0.1, 0.1, 1.0)
	else:
		border.color = Color(0.15, 0.3, 0.6, 1.0)
	border.size = Vector2(width - 6, height - 6)
	border.position = Vector2(3, 3)
	border.z_index = -1
	car.add_child(border)
	
	# Label
	var lbl = Label.new()
	lbl.text = str(car_data.id)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	var half_w : float = float(width) / 2.0
	var half_h : float = float(height) / 2.0
	lbl.position = Vector2(half_w - 8.0, half_h - 14.0)
	car.add_child(lbl)
	
	# Stocker l'ID dans les métadonnées
	car.set_meta("car_id", str(car_data.id))
	
	return car

# =====================================================
# FLÈCHE INDICATRICE AMÉLIORÉE
# =====================================================

func _create_arrow_indicator() -> Control:
	var arrow = Control.new()
	arrow.name = "ArrowIndicator"
	arrow.visible = false
	arrow.z_index = 100
	
	# Container pour la flèche
	var arrow_container = Control.new()
	arrow_container.name = "ArrowContainer"
	arrow.add_child(arrow_container)
	
	# Cercle de fond avec glow
	var glow = ColorRect.new()
	glow.name = "Glow"
	glow.color = Color(1.0, 0.85, 0.2, 0.3)
	glow.size = Vector2(50, 50)
	glow.position = Vector2(-25, -25)
	arrow_container.add_child(glow)
	
	# Cercle principal
	var circle = ColorRect.new()
	circle.name = "Circle"
	circle.color = Color(1.0, 0.8, 0.1, 0.95)
	circle.size = Vector2(36, 36)
	circle.position = Vector2(-18, -18)
	arrow_container.add_child(circle)
	
	# Cercle intérieur
	var inner = ColorRect.new()
	inner.name = "Inner"
	inner.color = Color(1.0, 0.9, 0.4, 1.0)
	inner.size = Vector2(28, 28)
	inner.position = Vector2(-14, -14)
	arrow_container.add_child(inner)
	
	# Label flèche
	var arrow_label = Label.new()
	arrow_label.name = "ArrowLabel"
	arrow_label.text = ">"
	arrow_label.add_theme_font_size_override("font_size", 28)
	arrow_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.0))
	arrow_label.position = Vector2(-10, -20)
	arrow_container.add_child(arrow_label)
	
	return arrow

func _update_arrow_direction(direction: String) -> void:
	if arrow_indicator == null:
		return
	
	var arrow_container = arrow_indicator.get_node("ArrowContainer")
	var arrow_label = arrow_container.get_node("ArrowLabel")
	
	# Symboles de flèche plus jolis
	if direction == "right":
		arrow_label.text = ">"
		arrow_label.position = Vector2(-8, -20)
	elif direction == "left":
		arrow_label.text = "<"
		arrow_label.position = Vector2(-10, -20)
	elif direction == "down":
		arrow_label.text = "v"
		arrow_label.position = Vector2(-8, -18)
	elif direction == "up":
		arrow_label.text = "^"
		arrow_label.position = Vector2(-8, -22)

func _update_step_display() -> void:
	if current_step >= solution_steps.size():
		step_label.text = "Bravo ! La voiture rouge est sortie !"
		arrow_indicator.visible = false
		return
	
	var step : Dictionary = solution_steps[current_step]
	step_label.text = str(step.text)
	
	var car_id : String = str(step.car)
	var car = car_sprites.get(car_id)
	if car != null:
		arrow_indicator.visible = true
		var car_center : Vector2 = car.position + car.size / 2.0
		
		var direction : String = str(step.direction)
		_update_arrow_direction(direction)
		
		var offset_dist : float = 35.0
		if direction == "right":
			arrow_indicator.position = car_center + Vector2(car.size.x / 2.0 + offset_dist, 0.0)
		elif direction == "left":
			arrow_indicator.position = car_center + Vector2(-car.size.x / 2.0 - offset_dist, 0.0)
		elif direction == "down":
			arrow_indicator.position = car_center + Vector2(0.0, car.size.y / 2.0 + offset_dist)
		elif direction == "up":
			arrow_indicator.position = car_center + Vector2(0.0, -car.size.y / 2.0 - offset_dist)
		
		_animate_arrow()

func _animate_arrow() -> void:
	if arrow_indicator == null or not arrow_indicator.visible:
		return
	
	var arrow_container = arrow_indicator.get_node("ArrowContainer")
	
	# Animation de pulsation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(arrow_container, "scale", Vector2(1.15, 1.15), 0.4).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(arrow_container, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)

# =====================================================
# DRAG & DROP DES VOITURES
# =====================================================

func _input(event: InputEvent) -> void:
	if is_auto_demo:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_start_drag(event.global_position)
			else:
				_end_drag()
	
	elif event is InputEventMouseMotion and dragging_car != null:
		_process_drag(event.global_position)

func _try_start_drag(global_pos: Vector2) -> void:
	if tutorial_board == null:
		return
	
	var local_pos = tutorial_board.get_global_transform().affine_inverse() * global_pos
	
	# Vérifier si on clique sur une voiture
	for car_id in car_sprites:
		var car : Control = car_sprites[car_id]
		var car_rect = Rect2(car.position, car.size)
		if car_rect.has_point(local_pos):
			dragging_car = car
			drag_offset = local_pos - car.position
			drag_start_pos = car.position
			# Highlight la voiture
			car.modulate = Color(1.2, 1.2, 1.2, 1.0)
			AudioManager.play_button_click()
			break

func _process_drag(global_pos: Vector2) -> void:
	if dragging_car == null or tutorial_board == null:
		return
	
	var local_pos = tutorial_board.get_global_transform().affine_inverse() * global_pos
	var new_pos = local_pos - drag_offset
	
	var car_id : String = str(dragging_car.get_meta("car_id"))
	var car_data : Dictionary = car_data_map.get(car_id, {})
	if car_data.is_empty():
		return
	
	var car_dir : String = str(car_data.dir)
	var car_len : int = int(car_data.len)
	
	# Contraindre le mouvement sur l'axe
	if car_dir == "H":
		new_pos.y = drag_start_pos.y
		# Limites horizontales
		new_pos.x = clampf(new_pos.x, 0.0, float((GRID_SIZE - car_len) * CELL))
		# Vérifier collision avec autres voitures
		new_pos.x = _check_collision_h(car_id, new_pos.x, int(car_data.y), car_len)
	else:
		new_pos.x = drag_start_pos.x
		# Limites verticales
		new_pos.y = clampf(new_pos.y, 0.0, float((GRID_SIZE - car_len) * CELL))
		# Vérifier collision avec autres voitures
		new_pos.y = _check_collision_v(car_id, new_pos.y, int(car_data.x), car_len)
	
	dragging_car.position = new_pos

func _check_collision_h(moving_id: String, new_x: float, row: int, car_len: int) -> float:
	var cell_x : int = int(round(new_x / float(CELL)))
	
	for other_id in car_data_map:
		if other_id == moving_id:
			continue
		var other : Dictionary = car_data_map[other_id]
		var other_car : Control = car_sprites.get(other_id)
		if other_car == null:
			continue
		
		var other_x : int = int(round(other_car.position.x / float(CELL)))
		var other_y : int = int(round(other_car.position.y / float(CELL)))
		var other_len : int = int(other.len)
		var other_dir : String = str(other.dir)
		
		if other_dir == "H":
			if other_y == row:
				# Collision horizontale
				if cell_x < other_x + other_len and cell_x + car_len > other_x:
					if drag_start_pos.x < other_car.position.x:
						return float((other_x - car_len) * CELL)
					else:
						return float((other_x + other_len) * CELL)
		else:
			# Voiture verticale
			if other_x >= cell_x and other_x < cell_x + car_len:
				if row >= other_y and row < other_y + other_len:
					if drag_start_pos.x < other_car.position.x:
						return float((other_x - car_len) * CELL)
					else:
						return float((other_x + 1) * CELL)
	
	return new_x

func _check_collision_v(moving_id: String, new_y: float, col: int, car_len: int) -> float:
	var cell_y : int = int(round(new_y / float(CELL)))
	
	for other_id in car_data_map:
		if other_id == moving_id:
			continue
		var other : Dictionary = car_data_map[other_id]
		var other_car : Control = car_sprites.get(other_id)
		if other_car == null:
			continue
		
		var other_x : int = int(round(other_car.position.x / float(CELL)))
		var other_y : int = int(round(other_car.position.y / float(CELL)))
		var other_len : int = int(other.len)
		var other_dir : String = str(other.dir)
		
		if other_dir == "V":
			if other_x == col:
				# Collision verticale
				if cell_y < other_y + other_len and cell_y + car_len > other_y:
					if drag_start_pos.y < other_car.position.y:
						return float((other_y - car_len) * CELL)
					else:
						return float((other_y + other_len) * CELL)
		else:
			# Voiture horizontale
			if other_y >= cell_y and other_y < cell_y + car_len:
				if col >= other_x and col < other_x + other_len:
					if drag_start_pos.y < other_car.position.y:
						return float((other_y - car_len) * CELL)
					else:
						return float((other_y + 1) * CELL)
	
	return new_y

func _end_drag() -> void:
	if dragging_car == null:
		return
	
	# Snap to grid
	var snapped_x : int = int(round(dragging_car.position.x / float(CELL)))
	var snapped_y : int = int(round(dragging_car.position.y / float(CELL)))
	
	var car_id : String = str(dragging_car.get_meta("car_id"))
	var car_data : Dictionary = car_data_map.get(car_id, {})
	
	# Animation de snap
	var target_pos = Vector2(snapped_x * CELL, snapped_y * CELL)
	var tween = create_tween()
	tween.tween_property(dragging_car, "position", target_pos, 0.1).set_ease(Tween.EASE_OUT)
	
	# Mettre à jour les données
	if not car_data.is_empty():
		car_data_map[car_id]["x"] = snapped_x
		car_data_map[car_id]["y"] = snapped_y
	
	# Reset highlight
	dragging_car.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Vérifier si l'étape est complétée
	_check_step_completion()
	
	# Vérifier victoire
	if car_id == "R" and snapped_x >= 4:
		_on_tutorial_win()
	
	dragging_car = null

func _check_step_completion() -> void:
	if current_step >= solution_steps.size():
		return
	
	var step : Dictionary = solution_steps[current_step]
	var car_id : String = str(step.car)
	var direction : String = str(step.direction)
	var cells : int = int(step.cells)
	
	var car_data : Dictionary = car_data_map.get(car_id, {})
	if car_data.is_empty():
		return
	
	var original : Dictionary = {}
	for orig in tutorial_cars:
		if str(orig.id) == car_id:
			original = orig
			break
	
	if original.is_empty():
		return
	
	var expected_x : int = int(original.x)
	var expected_y : int = int(original.y)
	
	# Calculer la position attendue après toutes les étapes précédentes
	for i in range(current_step):
		var prev_step : Dictionary = solution_steps[i]
		if str(prev_step.car) == car_id:
			var prev_dir : String = str(prev_step.direction)
			var prev_cells : int = int(prev_step.cells)
			if prev_dir == "right":
				expected_x += prev_cells
			elif prev_dir == "left":
				expected_x -= prev_cells
			elif prev_dir == "down":
				expected_y += prev_cells
			elif prev_dir == "up":
				expected_y -= prev_cells
	
	# Position attendue après cette étape
	if direction == "right":
		expected_x += cells
	elif direction == "left":
		expected_x -= cells
	elif direction == "down":
		expected_y += cells
	elif direction == "up":
		expected_y -= cells
	
	var current_x : int = int(car_data.x)
	var current_y : int = int(car_data.y)
	
	# Vérifier si le mouvement correspond (avec tolérance)
	if current_x == expected_x and current_y == expected_y:
		current_step += 1
		_update_step_display()

func _on_tutorial_win() -> void:
	current_step = solution_steps.size()
	step_label.text = "Bravo ! Vous avez reussi le tutoriel !"
	step_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	arrow_indicator.visible = false

# =====================================================
# DEMO AUTOMATIQUE
# =====================================================

func _execute_step() -> void:
	if current_step >= solution_steps.size():
		return
	
	var step : Dictionary = solution_steps[current_step]
	var car_id : String = str(step.car)
	var car = car_sprites.get(car_id)
	if car == null:
		return
	
	var cells_count : int = int(step.cells)
	var move_amount : float = float(cells_count * CELL)
	var target_pos : Vector2 = car.position
	var direction : String = str(step.direction)
	
	if direction == "right":
		target_pos.x += move_amount
	elif direction == "left":
		target_pos.x -= move_amount
	elif direction == "down":
		target_pos.y += move_amount
	elif direction == "up":
		target_pos.y -= move_amount
	
	# Mettre à jour car_data_map
	var snapped_x : int = int(round(target_pos.x / float(CELL)))
	var snapped_y : int = int(round(target_pos.y / float(CELL)))
	car_data_map[car_id]["x"] = snapped_x
	car_data_map[car_id]["y"] = snapped_y
	
	var tween = create_tween()
	tween.tween_property(car, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_step_complete)

func _on_step_complete() -> void:
	current_step += 1
	_update_step_display()
	if is_auto_demo and current_step < solution_steps.size():
		auto_demo_timer.start()

func _reset_tutorial() -> void:
	AudioManager.play_button_click()
	is_auto_demo = false
	if auto_demo_timer != null:
		auto_demo_timer.stop()
	current_step = 0
	
	step_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	
	for car_data in tutorial_cars:
		var car_id : String = str(car_data.id)
		var car = car_sprites.get(car_id)
		if car != null:
			var car_x : int = int(car_data.x)
			var car_y : int = int(car_data.y)
			car.position = Vector2(car_x * CELL, car_y * CELL)
			# Reset car_data_map
			car_data_map[car_id] = car_data.duplicate()
	
	_update_step_display()

func _toggle_auto_demo() -> void:
	AudioManager.play_button_click()
	
	if current_step >= solution_steps.size():
		_reset_tutorial()
		await get_tree().create_timer(0.3).timeout
	
	is_auto_demo = not is_auto_demo
	
	if is_auto_demo:
		_execute_step()
	else:
		if auto_demo_timer != null:
			auto_demo_timer.stop()

func _auto_demo_step() -> void:
	if is_auto_demo and current_step < solution_steps.size():
		_execute_step()

func _go_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Start.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
