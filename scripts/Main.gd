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
var mute_icon : TextureRect
var mute_icon_tween : Tween
var fps_label: Label
var ram_label: Label

var config_scene_instance: Control


# ========================================================
# READY
# ========================================================
func _ready() -> void:
	# Add background first so it's behind everything
	var background = load("res://scenes/Background.tscn").instantiate()
	add_child(background)
	move_child(background, 0)
	
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

	# Update stats labels
	var fps := Engine.get_frames_per_second()
	var ram := OS.get_static_memory_usage() / 1024 / 1024
	if fps_label:
		fps_label.text = "FPS: %d" % fps
	if ram_label:
		ram_label.text = "RAM: %d MB" % ram

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
	bg.texture = load("res://assets/board/board_bg.png")
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

	# Mute Icon
	mute_icon = TextureRect.new()
	mute_icon.texture = load("res://assets/ui/mute_icon.png")
	mute_icon.anchor_left = 1.0
	mute_icon.anchor_top = 0.0
	mute_icon.anchor_right = 1.0
	mute_icon.anchor_bottom = 0.0
	mute_icon.position = Vector2(-128, 20)
	mute_icon.visible = AudioManager.is_muted()
	add_child(mute_icon)

	# Stats Display (FPS and RAM)
	var stats_container := VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.anchor_left = 1.0
	stats_container.anchor_right = 1.0
	stats_container.position = Vector2(-200, 60)
	stats_container.size.x = 180 # Give it some width
	add_child(stats_container)

	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_container.add_child(fps_label)

	ram_label = Label.new()
	ram_label.name = "RAMLabel"
	ram_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_container.add_child(ram_label)

	# Connect to AudioManager's mute signal
	AudioManager.mute_changed.connect(_on_mute_changed)

func _on_mute_changed(is_muted: bool) -> void:
	if mute_icon:
		mute_icon.visible = is_muted

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
	btn_resume.pressed.connect(func():
		AudioManager.play_button_click()
		_toggle_pause()
	)
	box.add_child(btn_resume)

	var btn_restart := Button.new()
	btn_restart.text = "Recommencer"
	btn_restart.pressed.connect(func ():
		AudioManager.play_button_click()
		get_tree().reload_current_scene()
	)
	box.add_child(btn_restart)

	var btn_config := Button.new()
	btn_config.text = "Configuration"
	btn_config.pressed.connect(func ():
		AudioManager.play_button_click()
		_open_config_modal()
	)
	box.add_child(btn_config)

	var btn_menu := Button.new()
	btn_menu.text = "Menu principal"
	btn_menu.pressed.connect(func ():
		AudioManager.play_button_click()
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
	)
	box.add_child(btn_menu)

func _open_config_modal():
	if config_scene_instance:
		return # Already open

	var config_scene = load("res://scenes/Configuration.tscn").instantiate()
	config_scene_instance = config_scene
	config_scene.is_modal = true
	config_scene.back_pressed.connect(func():
		if config_scene_instance:
			config_scene_instance.queue_free()
			config_scene_instance = null
		# Re-enable pause menu input handling
		get_viewport().set_input_as_handled()
	)
	add_child(config_scene)

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
	btn_next.pressed.connect(func():
		AudioManager.play_button_click()
		_on_next_level()
	)
	box.add_child(btn_next)

	var btn_restart := Button.new()
	btn_restart.text = "Recommencer"
	btn_restart.pressed.connect(func ():
		AudioManager.play_button_click()
		get_tree().reload_current_scene()
	)
	box.add_child(btn_restart)

	var btn_menu := Button.new()
	btn_menu.text = "Menu principal"
	btn_menu.pressed.connect(func ():
		AudioManager.play_button_click()
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
	)
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
		var car_length : int = int(cd["len"])

		var tex_path := "res://assets/cars/%s_%s_%d.png" % [id, dir, car_length]
		var tex : Texture2D
		if ResourceLoader.exists(tex_path):
			tex = load(tex_path)
		else:
			var fallback_path := "res://assets/cars/FALLBACK_%d.png" % car_length
			if ResourceLoader.exists(fallback_path):
				tex = load(fallback_path)
			else:
				# Final fallback if specific length is missing
				tex = load("res://assets/cars/FALLBACK.png")

		var car := TextureRect.new()
		car.name = id
		car.texture = tex
		car.stretch_mode = TextureRect.STRETCH_SCALE
		car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		# taille en cellules (PAS de ternaire)
		var w_cells : int
		var h_cells : int
		if dir == "H":
			w_cells = car_length
			h_cells = 1
		else:
			w_cells = 1
			h_cells = car_length

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

	# Debug: print initial car_defs mapping after loading the level
	print("Loaded car_defs:")
	for k in car_defs.keys():
		var v = car_defs[k]
		print(k, ":", v["x"], v["y"], v["len"], v["dir"])

	# ...existing code...


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

		max_cell = x
		for xx in range(x + 1, GRID_SIZE - l + 1):
			if occ[y][xx + l - 1] != null:
				break
			max_cell = xx
	else:
		min_cell = y
		for yy in range(y - 1, -1, -1):
			if occ[yy][x] != null:
				break
			min_cell = yy

		max_cell = y
		for yy in range(y + 1, GRID_SIZE - l + 1):
			if occ[yy + l - 1][x] != null:
				break
			max_cell = yy

	# Debug: Print bounds for the car
	print("Bounds for car %s: min=%d, max=%d" % [id, min_cell, max_cell])

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
	var car_length : int = def["len"]

	var grid_x := int(round(car.position.x / CELL))
	var grid_y := int(round(car.position.y / CELL))

	if dir == "H":
		grid_x = int(clamp(grid_x, 0, GRID_SIZE - car_length))
	else:
		grid_y = int(clamp(grid_y, 0, GRID_SIZE - car_length))

	_rebuild_occupancy(id)

	var blocked := false
	if dir == "H":
		for dx in range(car_length):
			if occ[grid_y][grid_x + dx] != null:
				blocked = true
				break
	else:
		for dy in range(car_length):
			if occ[grid_y + dy][grid_x] != null:
				blocked = true
				break

	if blocked:
		# Debug: print why the move is blocked
		print("Blocked move for car %s at attempted grid (%d, %d) — def pos=(%s,%s)" % [id, grid_x, grid_y, str(def["x"]), str(def["y"])])
		print("Current occupancy grid:")
		for r in occ:
			print(r)
		_rebound_animation(car)
		car.position = Vector2(def["x"] * CELL, def["y"] * CELL)
		return

	if def["x"] != grid_x or def["y"] != grid_y:
		move_count += 1
		_update_moves_label()
		AudioManager.play_car_move()

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

	# Debug: print car_defs snapshot used to build occupancy (excluding the except_id car)
	print("Building occupancy from car_defs (except %s):" % except_id)
	for k in car_defs.keys():
		if k == except_id:
			continue
		var dlog = car_defs[k]
		print(k, ":", dlog["x"], dlog["y"], dlog["len"], dlog["dir"])

	for id in car_defs.keys():
		if id == except_id:
			continue
		var d : Dictionary = car_defs[id]
		var x : int = d["x"]
		var y : int = d["y"]
		var car_length : int = d["len"]
		var dir : String = d["dir"]

		if dir == "H":
			for dx in range(car_length):
				occ[y][x + dx] = id
		else:
			for dy in range(car_length):
				occ[y + dy][x] = id

	# Debug: Print the occupancy grid
	print("Occupancy Grid:")
	for row in occ:
		print(row)

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
	AudioManager.play_win()

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
	if config_scene_instance and config_scene_instance.visible:
		# If config modal is open, let it handle the input first
		return

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
