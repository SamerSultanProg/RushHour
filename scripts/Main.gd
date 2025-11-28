extends Control

# ========================================================
# CONSTANTES DU BOARD
# ========================================================
const GRID_SIZE := 6
const CELL := 96
const PADDING := 24

# ========================================================
# VARIABLES
# ========================================================
var board_rect : ColorRect
var cars : Dictionary = {}
var car_defs : Dictionary = {}
var occ : Array = []

var move_count := 0
var timer := 0.0
var timer_running := true
var won := false

var victory_layer : Control
var pause_layer : Control

# HUD
var level_label : Label
var moves_label : Label
var timer_label : Label

# ========================================================
# READY
# ========================================================
func _ready() -> void:
	_build_board()
	_build_ui()
	_build_pause_layer()
	_build_victory_layer()

	_load_level()
	_rebuild_occupancy()

	set_process(true)

# ========================================================
# PROCESS — TIMER
# ========================================================
func _process(delta: float) -> void:
	if timer_running and not won:
		timer += delta
		_update_timer_label()

# ========================================================
# BUILD BOARD
# ========================================================
func _build_board() -> void:
	board_rect = ColorRect.new()
	board_rect.color = Color(0, 0, 0, 0)
	board_rect.position = Vector2(PADDING, 140)
	board_rect.size = Vector2(CELL * GRID_SIZE, CELL * GRID_SIZE)
	add_child(board_rect)

	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(
		Image.load_from_file("res://assets/board/board_bg.png")
	)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = board_rect.size
	board_rect.add_child(bg)

# ========================================================
# BUILD UI (HUD)
# ========================================================
func _build_ui() -> void:
	var hud := VBoxContainer.new()
	hud.anchor_left = 0
	hud.anchor_top = 0
	hud.position = Vector2(PADDING, 20)
	add_child(hud)

	level_label = Label.new()
	moves_label = Label.new()
	timer_label = Label.new()

	level_label.text = "Niveau %d" % (Levels.get_current_index() + 1)
	moves_label.text = "Mouvements : 0"
	timer_label.text = "Temps : 00:00"

	hud.add_child(level_label)
	hud.add_child(moves_label)
	hud.add_child(timer_label)

# ========================================================
# BUILD PAUSE LAYER
# ========================================================
func _build_pause_layer() -> void:
	pause_layer = Control.new()
	pause_layer.visible = false
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.anchor_right = 1
	pause_layer.anchor_bottom = 1
	add_child(pause_layer)

	var center := CenterContainer.new()
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	pause_layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var lbl := Label.new()
	lbl.text = "Pause"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)

	var btn_resume := Button.new()
	btn_resume.text = "Reprendre"
	btn_resume.pressed.connect(_toggle_pause)
	box.add_child(btn_resume)

	var btn_restart := Button.new()
	btn_restart.text = "Recommencer"
	btn_restart.pressed.connect(func (): get_tree().reload_current_scene())
	box.add_child(btn_restart)

	var btn_menu := Button.new()
	btn_menu.text = "Menu principal"
	btn_menu.pressed.connect(func (): get_tree().change_scene_to_file("res://scenes/Start.tscn"))
	box.add_child(btn_menu)

# ========================================================
# BUILD VICTORY LAYER
# ========================================================
func _build_victory_layer() -> void:
	victory_layer = Control.new()
	victory_layer.visible = false
	victory_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_layer.anchor_right = 1
	victory_layer.anchor_bottom = 1
	add_child(victory_layer)

	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	victory_layer.add_child(center)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "Victoire !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var lbl_moves := Label.new()
	lbl_moves.name = "MovesText"
	box.add_child(lbl_moves)

	var lbl_time := Label.new()
	lbl_time.name = "TimeText"
	box.add_child(lbl_time)

	var lbl_medal := Label.new()
	lbl_medal.name = "MedalText"
	box.add_child(lbl_medal)

	var btn_next := Button.new()
	btn_next.text = "Prochain niveau"
	btn_next.pressed.connect(_on_next_level)
	box.add_child(btn_next)

	var btn_restart := Button.new()
	btn_restart.text = "Recommencer"
	btn_restart.pressed.connect(func (): get_tree().reload_current_scene())
	box.add_child(btn_restart)

	var btn_menu := Button.new()
	btn_menu.text = "Menu principal"
	btn_menu.pressed.connect(func (): get_tree().change_scene_to_file("res://scenes/Start.tscn"))
	box.add_child(btn_menu)

# ========================================================
# LOAD LEVEL
# ========================================================
func _load_level() -> void:
	var level : Dictionary = Levels.get_level()
	cars.clear()
	car_defs.clear()

	for cd in level["cars"]:
		var id : String = cd["id"]
		car_defs[id] = cd.duplicate(true)

		var dir : String = cd["dir"]
		var len : int = int(cd["len"])

		var tex_path := "res://assets/cars/%s_%s.png" % [id, dir]
		var tex : ImageTexture
		if FileAccess.file_exists(tex_path):
			tex = ImageTexture.create_from_image(Image.load_from_file(tex_path))
		else:
			tex = ImageTexture.create_from_image(
				Image.load_from_file("res://assets/cars/FALLBACK.png")
			)

		var car := TextureRect.new()
		car.name = id
		car.texture = tex
		car.stretch_mode = TextureRect.STRETCH_SCALE
		car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		# taille en cellules (PAS de ternaire)
		var w_cells : int
		var h_cells : int
		if dir == "H":
			w_cells = len
			h_cells = 1
		else:
			w_cells = 1
			h_cells = len

		car.custom_minimum_size = Vector2(w_cells * CELL, h_cells * CELL)
		car.size = car.custom_minimum_size

		car.anchor_left = 0
		car.anchor_top = 0

		var px := int(cd["x"]) * CELL
		var py := int(cd["y"]) * CELL
		car.position = Vector2(px, py)

		board_rect.add_child(car)
		cars[id] = car

		_connect_drag(car)

# ========================================================
# DRAG LOGIC
# ========================================================
func _connect_drag(car: TextureRect) -> void:
	car.gui_input.connect(func (event: InputEvent) -> void:
		if won:
			return

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				car.set_meta("dragging", true)
				car.set_meta("drag_offset", car.get_local_mouse_position())
			else:
				car.set_meta("dragging", false)
				_snap_car(car)

		elif event is InputEventMouseMotion:
			if car.get_meta("dragging", false):
				var off : Vector2 = car.get_meta("drag_offset")
				var desired : Vector2 = car.get_parent().get_local_mouse_position() - off

				var id : String = car.name
				var d : Dictionary = car_defs[id]
				var dir : String = d["dir"]

				var bounds : Dictionary = _get_bounds(id)

				if dir == "H":
					var min_px: int = int(bounds["min"]) * CELL
					var max_px: int = int(bounds["max"]) * CELL
					var clamped_x: int = clamp(desired.x, min_px, max_px)
					car.position.x = clamped_x
				else:
					var min_py: int = int(bounds["min"]) * CELL
					var max_py: int = int(bounds["max"]) * CELL
					var clamped_y: int = clamp(desired.y, min_py, max_py)
					car.position.y = clamped_y

	)

# --------------------------------------------------------
# BORNES (COLLISIONS) – retourne min / max en CASES
# --------------------------------------------------------
func _get_bounds(id: String) -> Dictionary:
	# reconstruit la grille en ignorant cette voiture
	_rebuild_occupancy(id)

	var def : Dictionary = car_defs[id]
	var x : int = def["x"]
	var y : int = def["y"]
	var l : int = def["len"]
	var dir : String = def["dir"]

	var min_cell := 0
	var max_cell := 0

	if dir == "H":
		min_cell = x
		for xx in range(x - 1, -1, -1):
			if occ[y][xx] != null:
				break
			min_cell = xx

		max_cell = x + l - 1
		for xx in range(x + l, GRID_SIZE):
			if occ[y][xx] != null:
				break
			max_cell = xx
	else:
		min_cell = y
		for yy in range(y - 1, -1, -1):
			if occ[yy][x] != null:
				break
			min_cell = yy

		max_cell = y + l - 1
		for yy in range(y + l, GRID_SIZE):
			if occ[yy][x] != null:
				break
			max_cell = yy

	return {
		"min": min_cell,
		"max": max_cell,
	}

# ========================================================
# SNAP
# ========================================================
func _snap_car(car: TextureRect) -> void:
	var id : String = car.name
	var def : Dictionary = car_defs[id]
	var dir : String = def["dir"]
	var length : int = def["len"]

	var grid_x := int(round(car.position.x / CELL))
	var grid_y := int(round(car.position.y / CELL))

	if dir == "H":
		grid_x = clampi(grid_x, 0, GRID_SIZE - length)
	else:
		grid_y = clampi(grid_y, 0, GRID_SIZE - length)

	_rebuild_occupancy(id)

	var blocked := false
	if dir == "H":
		for dx in range(length):
			if occ[grid_y][grid_x + dx] != null:
				blocked = true
				break
	else:
		for dy in range(length):
			if occ[grid_y + dy][grid_x] != null:
				blocked = true
				break

	if blocked:
		_rebound_animation(car)
		car.position = Vector2(def["x"] * CELL, def["y"] * CELL)
		return

	if def["x"] != grid_x or def["y"] != grid_y:
		move_count += 1
		_update_moves_label()

	def["x"] = grid_x
	def["y"] = grid_y
	car.position = Vector2(grid_x * CELL, grid_y * CELL)

	_rebuild_occupancy()
	_check_victory()

# Petit effet de shake quand collision
func _rebound_animation(car: TextureRect) -> void:
	var tween := get_tree().create_tween()
	var orig := car.position
	tween.tween_property(car, "position", orig + Vector2(6, 0), 0.05)
	tween.tween_property(car, "position", orig, 0.05)

# ========================================================
# OCCUPANCY GRID
# ========================================================
func _rebuild_occupancy(except_id: String = "") -> void:
	occ.clear()
	for _y in range(GRID_SIZE):
		var row : Array = []
		for _x in range(GRID_SIZE):
			row.append(null)
		occ.append(row)

	for id in car_defs.keys():
		if id == except_id:
			continue
		var d : Dictionary = car_defs[id]
		var x : int = d["x"]
		var y : int = d["y"]
		var l : int = d["len"]
		var dir : String = d["dir"]

		if dir == "H":
			for dx in range(l):
				occ[y][x + dx] = id
		else:
			for dy in range(l):
				occ[y + dy][x] = id

# ========================================================
# VICTOIRE
# ========================================================
func _check_victory() -> void:
	var R : Dictionary = car_defs["R"]
	if int(R["x"]) + int(R["len"]) == GRID_SIZE:
		_trigger_victory()

func _trigger_victory() -> void:
	won = true
	timer_running = false

	var car : TextureRect = cars["R"]

	var tween := get_tree().create_tween()
	tween.tween_property(car, "position", car.position + Vector2(300, 0), 1.2)
	await tween.finished

	_show_victory_screen()

func _show_victory_screen() -> void:
	victory_layer.visible = true

	victory_layer.get_node("CenterContainer/VBoxContainer/MovesText").text = "Mouvements : %d" % move_count

	victory_layer.get_node("CenterContainer/VBoxContainer/TimeText").text = "Temps : %s" % _format_time(timer)

	victory_layer.get_node("CenterContainer/VBoxContainer/MedalText").text = "Médaille : %s" % _get_medal(move_count)

func _get_medal(moves: int) -> String:
	if moves <= 5:
		return "Or"
	elif moves <= 10:
		return "Argent"
	return "Bronze"

func _on_next_level() -> void:
	Levels.go_to_next_level()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ========================================================
# INPUT
# ========================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not won:
		_toggle_pause()
	elif event is InputEventKey and event.pressed and event.keycode == Key.KEY_R:
		get_tree().reload_current_scene()

func _toggle_pause() -> void:
	if won:
		return
	pause_layer.visible = not pause_layer.visible
	timer_running = not pause_layer.visible

# ========================================================
# HUD HELPERS
# ========================================================
func _update_moves_label() -> void:
	moves_label.text = "Mouvements : %d" % move_count

func _update_timer_label() -> void:
	timer_label.text = "Temps : %s" % _format_time(timer)

func _format_time(t: float) -> String:
	var m := int(t / 60)
	var s := int(t) % 60
	return "%02d:%02d" % [m, s]
