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

var config_scene_instance: Control

# Medal indicator
var medal_panel: PanelContainer
var medal_icon: TextureRect
var gold_label: Label
var silver_label: Label
var bronze_label: Label
var current_medal: String = "gold"

# Hint system
var hint_button: Button
var hint_car_highlight: ColorRect


# ========================================================
# READY
# ========================================================
func _ready() -> void:
	# Add background first so it's behind everything
	_build_background()
	
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
# BUILD BACKGROUND
# ========================================================
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.anchor_left = 0
	bg.anchor_top = 0
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var tex = load("res://assets/backgrounds/background.png")
	if tex:
		bg.texture = tex
	else:
		# Fallback: use a solid color if texture fails to load
		print("WARNING: Could not load background.png, using fallback color")
		var fallback := ColorRect.new()
		fallback.name = "BackgroundFallback"
		fallback.anchor_right = 1
		fallback.anchor_bottom = 1
		fallback.color = Color(0.15, 0.15, 0.2, 1.0)
		add_child(fallback)
		move_child(fallback, 0)
		return
	
	add_child(bg)
	move_child(bg, 0)

# ========================================================
# BUILD BOARD
# ========================================================
func _build_board() -> void:
	board_rect = ColorRect.new()
	board_rect.color = Color(0, 0, 0, 0)
	board_rect.size = Vector2(CELL * GRID_SIZE, CELL * GRID_SIZE)
	
	# Center the board in the window, with slight offset to the right for UI space
	var viewport_size = get_viewport_rect().size
	var board_x = (viewport_size.x - board_rect.size.x) / 2 + 60
	var board_y = (viewport_size.y - board_rect.size.y) / 2
	board_rect.position = Vector2(board_x, board_y)
	add_child(board_rect)

	# Solid asphalt-like background color for the board
	var bg := ColorRect.new()
	bg.color = Color(0.18, 0.19, 0.21, 1.0)  # Darker asphalt
	bg.size = board_rect.size
	board_rect.add_child(bg)
	
	# Add road texture/details
	_draw_road_details()
	
	# Add grid lines (dashed road markings style)
	_draw_grid_lines()

func _draw_road_details() -> void:
	# Add some texture variation to make it look more like asphalt
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for consistent look
	
	# Add subtle speckles/noise for asphalt texture
	for i in range(80):
		var speckle := ColorRect.new()
		var brightness := rng.randf_range(0.15, 0.25)
		speckle.color = Color(brightness, brightness, brightness, 0.3)
		var speckle_size := rng.randf_range(2, 6)
		speckle.size = Vector2(speckle_size, speckle_size)
		speckle.position = Vector2(
			rng.randf_range(0, CELL * GRID_SIZE - speckle_size),
			rng.randf_range(0, CELL * GRID_SIZE - speckle_size)
		)
		board_rect.add_child(speckle)

func _draw_grid_lines() -> void:
	var yellow := Color(0.9, 0.75, 0.1, 0.9)  # Road marking yellow
	var white := Color(0.85, 0.85, 0.85, 0.7)  # White lane markings
	
	# Draw yellow border around the parking lot (except exit)
	var border_width := 4
	
	# Top border
	var top_border := ColorRect.new()
	top_border.color = yellow
	top_border.size = Vector2(CELL * GRID_SIZE, border_width)
	top_border.position = Vector2(0, 0)
	board_rect.add_child(top_border)
	
	# Bottom border
	var bottom_border := ColorRect.new()
	bottom_border.color = yellow
	bottom_border.size = Vector2(CELL * GRID_SIZE, border_width)
	bottom_border.position = Vector2(0, CELL * GRID_SIZE - border_width)
	board_rect.add_child(bottom_border)
	
	# Left border
	var left_border := ColorRect.new()
	left_border.color = yellow
	left_border.size = Vector2(border_width, CELL * GRID_SIZE)
	left_border.position = Vector2(0, 0)
	board_rect.add_child(left_border)
	
	# Right border (with gap for exit at row 2)
	for row in range(GRID_SIZE):
		if row == 2:
			continue  # Skip for exit
		var right_segment := ColorRect.new()
		right_segment.color = yellow
		right_segment.size = Vector2(border_width, CELL)
		right_segment.position = Vector2(CELL * GRID_SIZE - border_width, row * CELL)
		board_rect.add_child(right_segment)
	
	# Draw dashed white lines for internal grid (parking space style)
	var dash_length := 12
	var gap_length := 8
	
	# Vertical dashed lines
	for i in range(1, GRID_SIZE):
		var y := 0
		while y < CELL * GRID_SIZE:
			var dash := ColorRect.new()
			dash.color = white
			dash.size = Vector2(2, dash_length)
			dash.position = Vector2(i * CELL - 1, y)
			board_rect.add_child(dash)
			y += dash_length + gap_length
	
	# Horizontal dashed lines
	for i in range(1, GRID_SIZE):
		var x := 0
		while x < CELL * GRID_SIZE:
			var dash := ColorRect.new()
			dash.color = white
			dash.size = Vector2(dash_length, 2)
			dash.position = Vector2(x, i * CELL - 1)
			board_rect.add_child(dash)
			x += dash_length + gap_length
	
	# Draw exit
	_draw_exit_indicator()

func _draw_exit_indicator() -> void:
	var exit_row := 2
	var exit_width := 50
	var yellow := Color(0.9, 0.75, 0.1, 1.0)
	var green := Color(0.2, 0.7, 0.2, 1.0)
	
	# Exit road extension
	var exit_road := ColorRect.new()
	exit_road.color = Color(0.18, 0.19, 0.21, 1.0)
	exit_road.size = Vector2(exit_width, CELL)
	exit_road.position = Vector2(CELL * GRID_SIZE, exit_row * CELL)
	board_rect.add_child(exit_road)
	
	# Yellow borders for exit lane (top and bottom)
	var exit_top := ColorRect.new()
	exit_top.color = yellow
	exit_top.size = Vector2(exit_width, 4)
	exit_top.position = Vector2(CELL * GRID_SIZE, exit_row * CELL)
	board_rect.add_child(exit_top)
	
	var exit_bottom := ColorRect.new()
	exit_bottom.color = yellow
	exit_bottom.size = Vector2(exit_width, 4)
	exit_bottom.position = Vector2(CELL * GRID_SIZE, (exit_row + 1) * CELL - 4)
	board_rect.add_child(exit_bottom)
	
	# Green "EXIT" sign background
	var sign_bg := ColorRect.new()
	sign_bg.color = green
	sign_bg.size = Vector2(44, 28)
	sign_bg.position = Vector2(CELL * GRID_SIZE + 3, exit_row * CELL + CELL / 2 - 14)
	board_rect.add_child(sign_bg)
	
	# Sign border
	var sign_border := ColorRect.new()
	sign_border.color = Color(1, 1, 1, 0.9)
	sign_border.size = Vector2(48, 32)
	sign_border.position = Vector2(CELL * GRID_SIZE + 1, exit_row * CELL + CELL / 2 - 16)
	board_rect.add_child(sign_border)
	board_rect.move_child(sign_border, sign_bg.get_index())
	
	# Arrow on sign
	var arrow := Label.new()
	arrow.text = "EXIT →"
	arrow.add_theme_font_size_override("font_size", 12)
	arrow.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	arrow.position = Vector2(CELL * GRID_SIZE + 5, exit_row * CELL + CELL / 2 - 10)
	board_rect.add_child(arrow)

# ========================================================
# BUILD UI (HUD)
# ========================================================
func _build_ui() -> void:
	# Create a panel background for the HUD
	var hud_panel := PanelContainer.new()
	hud_panel.position = Vector2(PADDING, 20)
	
	# Style the panel with a sleek semi-transparent background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	hud_panel.add_theme_stylebox_override("panel", style)
	add_child(hud_panel)

	var hud := VBoxContainer.new()
	hud_panel.add_child(hud)

	level_label = Label.new()
	moves_label = Label.new()
	timer_label = Label.new()

	if Levels.is_playing_random():
		level_label.text = "Niveau Aléatoire"
	else:
		level_label.text = "Niveau %d" % (Levels.get_current_index() + 1)
	moves_label.text = "Mouvements : 0"
	timer_label.text = "Temps : 00:00"

	hud.add_child(level_label)
	hud.add_child(moves_label)
	hud.add_child(timer_label)

	# Mute Icon (en bas à gauche)
	mute_icon = TextureRect.new()
	mute_icon.texture = load("res://assets/ui/mute_icon.png")
	mute_icon.anchor_left = 0.0
	mute_icon.anchor_top = 1.0
	mute_icon.anchor_right = 0.0
	mute_icon.anchor_bottom = 1.0
	mute_icon.position = Vector2(20, -80)
	mute_icon.visible = AudioManager.is_muted()
	add_child(mute_icon)

	# Connect to AudioManager's mute signal
	AudioManager.mute_changed.connect(_on_mute_changed)
	
	# Build medal indicator panel (bottom right)
	_build_medal_indicator()

func _build_medal_indicator() -> void:
	var level_idx = Levels.get_current_index()
	var optimal = Levels.OPTIMAL_MOVES[level_idx]
	
	medal_panel = PanelContainer.new()
	medal_panel.name = "MedalPanel"
	# Position in top-left, below the HUD
	medal_panel.anchor_left = 0.0
	medal_panel.anchor_right = 0.0
	medal_panel.anchor_top = 0.0
	medal_panel.anchor_bottom = 0.0
	medal_panel.position = Vector2(20, 130)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.7)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	medal_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(medal_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	medal_panel.add_child(vbox)
	
	# Current medal icon + label header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	medal_icon = TextureRect.new()
	medal_icon.texture = load("res://assets/ui/medal_gold.png")
	medal_icon.custom_minimum_size = Vector2(32, 32)
	medal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(medal_icon)
	
	var title := Label.new()
	title.text = "Objectifs"
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)
	
	# Gold threshold (0 to optimal)
	gold_label = Label.new()
	gold_label.text = "🥇 Or : ≤%d coups" % optimal
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(gold_label)
	
	# Silver threshold (optimal+1 to optimal+5)
	silver_label = Label.new()
	silver_label.text = "🥈 Argent : %d-%d coups" % [optimal + 1, optimal + 5]
	silver_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(silver_label)
	
	# Bronze threshold (optimal+6 and above)
	bronze_label = Label.new()
	bronze_label.text = "🥉 Bronze : %d+ coups" % (optimal + 6)
	bronze_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	vbox.add_child(bronze_label)
	
	# Hint button
	var hint_sep := HSeparator.new()
	hint_sep.add_theme_constant_override("separation", 8)
	vbox.add_child(hint_sep)
	
	hint_button = Button.new()
	hint_button.text = "💡 Indice"
	hint_button.custom_minimum_size = Vector2(120, 36)
	UIHelper.style_button(hint_button)
	hint_button.pressed.connect(_on_hint_pressed)
	vbox.add_child(hint_button)

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
	
	# Fond semi-transparent sur tout l'écran
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	pause_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	pause_layer.add_child(center)
	
	# Panel avec fond et bordure
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.8, 0.8, 0.8, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var lbl := Label.new()
	lbl.text = "Pause"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	box.add_child(lbl)

	var btn_resume := Button.new()
	btn_resume.text = "▶ Reprendre"
	UIHelper.style_primary_button(btn_resume)
	btn_resume.pressed.connect(func():
		AudioManager.play_button_click()
		_toggle_pause()
	)
	box.add_child(btn_resume)

	var btn_restart := Button.new()
	btn_restart.text = "↺ Recommencer"
	UIHelper.style_button(btn_restart)
	btn_restart.pressed.connect(func ():
		AudioManager.play_button_click()
		get_tree().reload_current_scene()
	)
	box.add_child(btn_restart)

	var btn_config := Button.new()
	btn_config.text = "⚙ Configuration"
	UIHelper.style_button(btn_config)
	btn_config.pressed.connect(func ():
		AudioManager.play_button_click()
		_open_config_modal()
	)
	box.add_child(btn_config)

	var btn_menu := Button.new()
	btn_menu.text = "⌂ Menu principal"
	UIHelper.style_secondary_button(btn_menu)
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
	
	# Fond semi-transparent avec effet de célébration
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.05, 0.1, 0.7)
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	victory_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	victory_layer.add_child(center)
	
	# Panel principal avec style de victoire
	var panel := PanelContainer.new()
	panel.name = "VictoryPanel"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.12, 0.18, 0.98)
	panel_style.border_color = Color(1.0, 0.85, 0.3, 0.9)  # Bordure dorée
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(15)
	panel_style.set_content_margin_all(30)
	panel_style.shadow_color = Color(1.0, 0.8, 0.2, 0.3)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)

	# Titre "Victoire !" avec style
	var title := Label.new()
	title.name = "VictoryTitle"
	title.text = "Victoire !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	box.add_child(title)
	
	# Séparateur décoratif
	var separator := HSeparator.new()
	separator.custom_minimum_size.x = 250
	box.add_child(separator)
	
	# Container pour les stats avec icônes
	var stats_container := VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 12)
	box.add_child(stats_container)
	
	# Médaille (en premier, plus visible)
	var medal_row := VBoxContainer.new()
	medal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	medal_row.add_theme_constant_override("separation", 8)
	stats_container.add_child(medal_row)
	
	# Image de la médaille
	var medal_texture := TextureRect.new()
	medal_texture.name = "MedalIcon"
	medal_texture.custom_minimum_size = Vector2(80, 80)
	medal_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal_row.add_child(medal_texture)
	
	var lbl_medal := Label.new()
	lbl_medal.name = "MedalText"
	lbl_medal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_medal.add_theme_font_size_override("font_size", 20)
	lbl_medal.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	medal_row.add_child(lbl_medal)
	
	# Mouvements
	var moves_row := HBoxContainer.new()
	moves_row.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_row.add_theme_constant_override("separation", 8)
	stats_container.add_child(moves_row)
	
	var moves_icon := Label.new()
	moves_icon.text = "Mouvements:"
	moves_icon.add_theme_font_size_override("font_size", 16)
	moves_icon.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	moves_row.add_child(moves_icon)
	
	var lbl_moves := Label.new()
	lbl_moves.name = "MovesText"
	lbl_moves.add_theme_font_size_override("font_size", 18)
	lbl_moves.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	moves_row.add_child(lbl_moves)
	
	# Temps
	var time_row := HBoxContainer.new()
	time_row.alignment = BoxContainer.ALIGNMENT_CENTER
	time_row.add_theme_constant_override("separation", 8)
	stats_container.add_child(time_row)
	
	var time_icon := Label.new()
	time_icon.text = "Temps:"
	time_icon.add_theme_font_size_override("font_size", 16)
	time_icon.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	time_row.add_child(time_icon)
	
	var lbl_time := Label.new()
	lbl_time.name = "TimeText"
	lbl_time.add_theme_font_size_override("font_size", 18)
	lbl_time.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	time_row.add_child(lbl_time)
	
	# Espacement avant les boutons
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	box.add_child(spacer)

	# Container pour les boutons
	var btn_container := VBoxContainer.new()
	btn_container.name = "ButtonContainer"
	btn_container.add_theme_constant_override("separation", 8)
	box.add_child(btn_container)
	
	# Note: Buttons are populated in _show_victory_panel based on random/normal level

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
# Cars can only move to CONTIGUOUS positions from their current spot
# --------------------------------------------------------
func _get_bounds(id: String) -> Dictionary:
	# Rebuild occupancy grid WITHOUT the car we're moving
	_rebuild_occupancy(id)

	var def : Dictionary = car_defs[id]
	var l : int = int(def["len"])
	var dir : String = def["dir"]
	
	# Get the CURRENT visual position of the car (more accurate during drag)
	var car_node : TextureRect = cars[id]
	var current_x : int = int(round(car_node.position.x / CELL))
	var current_y : int = int(round(car_node.position.y / CELL))

	if dir == "H":
		# Horizontal car: fixed Y, moves along X
		var y : int = int(def["y"])
		
		# Clamp current_x to valid range
		current_x = clamp(current_x, 0, GRID_SIZE - l)
		
		# Find minimum X by scanning left from current position
		var min_x := current_x
		for check_x in range(current_x - 1, -1, -1):
			# Check if position check_x is free for the full car length
			var blocked := false
			for dx in range(l):
				var cell_x = check_x + dx
				if cell_x >= GRID_SIZE or occ[y][cell_x] != null:
					blocked = true
					break
			if blocked:
				break
			min_x = check_x
		
		# Find maximum X by scanning right from current position
		var max_x := current_x
		for check_x in range(current_x + 1, GRID_SIZE - l + 1):
			# Check if position check_x is free for the full car length
			var blocked := false
			for dx in range(l):
				var cell_x = check_x + dx
				if cell_x >= GRID_SIZE or occ[y][cell_x] != null:
					blocked = true
					break
			if blocked:
				break
			max_x = check_x
		
		return {"min": min_x, "max": max_x}
	else:
		# Vertical car: fixed X, moves along Y
		var x : int = int(def["x"])
		
		# Clamp current_y to valid range
		current_y = clamp(current_y, 0, GRID_SIZE - l)
		
		# Find minimum Y by scanning up from current position
		var min_y := current_y
		for check_y in range(current_y - 1, -1, -1):
			# Check if position check_y is free for the full car length
			var blocked := false
			for dy in range(l):
				var cell_y = check_y + dy
				if cell_y >= GRID_SIZE or occ[cell_y][x] != null:
					blocked = true
					break
			if blocked:
				break
			min_y = check_y
		
		# Find maximum Y by scanning down from current position
		var max_y := current_y
		for check_y in range(current_y + 1, GRID_SIZE - l + 1):
			# Check if position check_y is free for the full car length
			var blocked := false
			for dy in range(l):
				var cell_y = check_y + dy
				if cell_y >= GRID_SIZE or occ[cell_y][x] != null:
					blocked = true
					break
			if blocked:
				break
			max_y = check_y
		
		return {"min": min_y, "max": max_y}

# ========================================================
# SNAP
# ========================================================
func _snap_car(car: TextureRect) -> void:
	var id : String = car.name
	var def : Dictionary = car_defs[id]
	var dir : String = def["dir"]
	var car_length : int = int(def["len"])

	# Get snapped grid position from visual position
	var grid_x := int(round(car.position.x / CELL))
	var grid_y := int(round(car.position.y / CELL))

	# Fix axis based on direction (cars only move in one direction)
	if dir == "H":
		grid_x = clamp(grid_x, 0, GRID_SIZE - car_length)
		grid_y = int(def["y"])  # Horizontal cars stay on their row
	else:
		grid_x = int(def["x"])  # Vertical cars stay on their column
		grid_y = clamp(grid_y, 0, GRID_SIZE - car_length)

	# Save old position to check if moved
	var old_x : int = int(def["x"])
	var old_y : int = int(def["y"])

	# Update stored position BEFORE getting bounds (so bounds use correct position)
	def["x"] = grid_x
	def["y"] = grid_y
	
	# Snap visual position to grid
	car.position = Vector2(grid_x * CELL, grid_y * CELL)

	# Update move count if position actually changed
	if old_x != grid_x or old_y != grid_y:
		move_count += 1
		_update_moves_label()
		AudioManager.play_car_move()

	# Rebuild occupancy and check victory
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
	# Clear and rebuild the grid
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
		var car_length : int = int(d["len"])
		var dir : String = d["dir"]
		
		# Use the SNAPPED visual position of the car for collision
		var car_node : TextureRect = cars[id]
		var grid_x : int = int(round(car_node.position.x / CELL))
		var grid_y : int = int(round(car_node.position.y / CELL))
		
		# Clamp to valid grid bounds
		if dir == "H":
			grid_x = clamp(grid_x, 0, GRID_SIZE - car_length)
			grid_y = clamp(grid_y, 0, GRID_SIZE - 1)
		else:
			grid_x = clamp(grid_x, 0, GRID_SIZE - 1)
			grid_y = clamp(grid_y, 0, GRID_SIZE - car_length)

		# Fill the occupancy grid
		if dir == "H":
			for dx in range(car_length):
				var cell_x = grid_x + dx
				if cell_x < GRID_SIZE:
					occ[grid_y][cell_x] = id
		else:
			for dy in range(car_length):
				var cell_y = grid_y + dy
				if cell_y < GRID_SIZE:
					occ[cell_y][grid_x] = id

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
	
	# Save completion with medal earned (only for non-random levels)
	if not Levels.is_playing_random():
		Levels.mark_level_completed(Levels.get_current_index(), move_count)

	var car : TextureRect = cars["R"]

	var tween := get_tree().create_tween()
	tween.tween_property(car, "position", car.position + Vector2(300, 0), 1.2)
	await tween.finished

	_show_victory_screen()

func _show_victory_screen() -> void:
	victory_layer.visible = true
	
	# Récupérer les infos de médaille
	var medal_info := _get_medal_info(move_count)
	
	# Trouver les éléments par nom
	var victory_medal_icon = _find_node_recursive(victory_layer, "MedalIcon")
	var medal_text = _find_node_recursive(victory_layer, "MedalText")
	var moves_text = _find_node_recursive(victory_layer, "MovesText")
	var time_text = _find_node_recursive(victory_layer, "TimeText")
	var btn_container = _find_node_recursive(victory_layer, "ButtonContainer")
	var panel = _find_node_recursive(victory_layer, "VictoryPanel")
	
	# Image et texte de médaille
	if victory_medal_icon and victory_medal_icon is TextureRect:
		victory_medal_icon.texture = medal_info.texture
	if medal_text:
		medal_text.text = "Medaille %s" % medal_info.name
		medal_text.add_theme_color_override("font_color", medal_info.color)
	
	# Mouvements et temps
	if moves_text:
		moves_text.text = "%d" % move_count
	if time_text:
		time_text.text = "%s" % _format_time(timer)
	
	# Créer les boutons dynamiquement
	if btn_container:
		# Clear existing buttons
		for child in btn_container.get_children():
			child.queue_free()
		
		if Levels.is_playing_random():
			# Random level: offer new random or menu
			var btn_new_random := Button.new()
			btn_new_random.text = "🎲 Nouveau niveau aléatoire"
			UIHelper.style_primary_button(btn_new_random)
			btn_new_random.pressed.connect(func():
				AudioManager.play_button_click()
				_load_new_random_level()
			)
			btn_container.add_child(btn_new_random)
		else:
			# Normal level: show next if not last
			if Levels.get_current_index() < Levels.get_level_count() - 1:
				var btn_next := Button.new()
				btn_next.text = "Prochain niveau"
				UIHelper.style_primary_button(btn_next)
				btn_next.pressed.connect(func():
					AudioManager.play_button_click()
					_on_next_level()
				)
				btn_container.add_child(btn_next)
		
		# Restart button (always shown)
		var btn_restart := Button.new()
		btn_restart.text = "Recommencer"
		UIHelper.style_button(btn_restart)
		btn_restart.pressed.connect(func():
			AudioManager.play_button_click()
			get_tree().reload_current_scene()
		)
		btn_container.add_child(btn_restart)
		
		# Menu button (always shown)
		var btn_menu := Button.new()
		btn_menu.text = "Menu principal"
		UIHelper.style_secondary_button(btn_menu)
		btn_menu.pressed.connect(func():
			AudioManager.play_button_click()
			get_tree().change_scene_to_file("res://scenes/Start.tscn")
		)
		btn_container.add_child(btn_menu)
	
	# Animation d'entrée
	if panel:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.8, 0.8)
		panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _load_new_random_level() -> void:
	# Generate a new random level
	var generated := Solver.generate_level(5, 10)
	var level_data := {"cars": generated["cars"]}
	var optimal_moves : int = generated["optimal_moves"]
	Levels.set_random_level(level_data, optimal_moves)
	get_tree().reload_current_scene()

func _find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = _find_node_recursive(child, node_name)
		if result:
			return result
	return null

func _get_medal_info(moves: int) -> Dictionary:
	var optimal := Levels.get_optimal_moves_for_current()
	if moves <= optimal:
		return {
			"name": "Or",
			"texture": load("res://assets/ui/medal_gold.png"),
			"color": Color(1.0, 0.85, 0.2)
		}
	elif moves <= optimal + 5:
		return {
			"name": "Argent",
			"texture": load("res://assets/ui/medal_silver.png"),
			"color": Color(0.75, 0.75, 0.85)
		}
	else:
		return {
			"name": "Bronze",
			"texture": load("res://assets/ui/medal_bronze.png"),
			"color": Color(0.85, 0.55, 0.25)
		}

func _on_next_level() -> void:
	# Check if this was the last level
	if Levels.get_current_index() >= Levels.get_level_count() - 1:
		# All levels completed! Show game complete screen
		get_tree().change_scene_to_file("res://scenes/GameComplete.tscn")
	else:
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
	elif event is InputEventKey and event.pressed and event.keycode == Key.KEY_J:
		# Debug shortcut: Show game complete screen (for presentation)
		get_tree().change_scene_to_file("res://scenes/GameComplete.tscn")

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
	_update_medal_indicator()

func _update_medal_indicator() -> void:
	if not medal_panel:
		return
	
	var level_idx = Levels.get_current_index()
	var new_medal = Levels.get_medal_for_moves(level_idx, move_count)
	
	# Update icon if medal changed
	if new_medal != current_medal:
		current_medal = new_medal
		match current_medal:
			"gold":
				medal_icon.texture = load("res://assets/ui/medal_gold.png")
			"silver":
				medal_icon.texture = load("res://assets/ui/medal_silver.png")
			"bronze":
				medal_icon.texture = load("res://assets/ui/medal_bronze.png")
	
	# Reset all to default colors (dimmed)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 0.5))
	silver_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 0.5))
	bronze_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2, 0.5))
	
	# Highlight current medal tier
	match current_medal:
		"gold":
			gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		"silver":
			silver_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		"bronze":
			bronze_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2, 1.0))

func _refresh_medal_panel_for_level() -> void:
	if not medal_panel:
		return
	
	var optimal = Levels.get_optimal_moves_for_current()
	
	# Update threshold labels for new level
	gold_label.text = "🥇 Or : ≤%d coups" % optimal
	silver_label.text = "🥈 Argent : %d-%d coups" % [optimal + 1, optimal + 5]
	bronze_label.text = "🥉 Bronze : %d+ coups" % (optimal + 6)
	
	# Reset to gold medal display
	current_medal = ""
	_update_medal_indicator()

func _update_timer_label() -> void:
	timer_label.text = "Temps : %s" % _format_time(timer)

func _format_time(t: float) -> String:
	var m := int(t / 60)
	var s := int(t) % 60
	return "%02d:%02d" % [m, s]

# ========================================================
# HINT SYSTEM (BFS ALGORITHM)
# ========================================================
func _get_current_positions() -> Dictionary:
	var positions : Dictionary = {}
	for id in car_defs.keys():
		var d : Dictionary = car_defs[id]
		positions[id] = Vector2(int(d["x"]), int(d["y"]))
	return positions

func _on_hint_pressed() -> void:
	if won:
		return
	
	# Clear previous hint highlight
	_clear_hint_highlight()
	
	# Get current level data and positions
	var level_data : Dictionary = Levels.get_level()
	var current_pos : Dictionary = _get_current_positions()
	
	# Ask the solver for a hint
	var hint : Dictionary = Solver.get_hint(level_data, current_pos)
	
	if hint.is_empty():
		# No solution found or already solved
		return
	
	# Hint format: {"car_id": "X", "dx": -1, "dy": 0}
	var car_id : String = hint["car_id"]
	var dx : int = hint["dx"]
	var dy : int = hint["dy"]
	
	# Convert dx/dy to direction and steps
	var direction : String
	var steps : int
	if dx < 0:
		direction = "left"
		steps = -dx
	elif dx > 0:
		direction = "right"
		steps = dx
	elif dy < 0:
		direction = "up"
		steps = -dy
	else:
		direction = "down"
		steps = dy
	
	# Highlight the car to move
	_highlight_hint_car(car_id, direction, steps)

func _highlight_hint_car(car_id: String, direction: String, steps: int) -> void:
	if not cars.has(car_id):
		return
	
	var car : TextureRect = cars[car_id]
	
	# Create a highlight overlay
	if hint_car_highlight:
		hint_car_highlight.queue_free()
	
	hint_car_highlight = ColorRect.new()
	hint_car_highlight.color = Color(0.0, 1.0, 0.0, 0.4)  # Semi-transparent green
	hint_car_highlight.size = car.size
	hint_car_highlight.position = car.position
	board_rect.add_child(hint_car_highlight)
	
	# Create pulsing animation
	var tween := create_tween()
	tween.set_loops(5)  # Pulse 5 times
	tween.tween_property(hint_car_highlight, "modulate:a", 0.2, 0.3)
	tween.tween_property(hint_car_highlight, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_clear_hint_highlight)
	
	# Create arrow indicator showing direction
	var arrow_label := Label.new()
	arrow_label.name = "HintArrow"
	
	var arrow_text : String
	match direction:
		"left":
			arrow_text = "← %d" % steps
		"right":
			arrow_text = "→ %d" % steps
		"up":
			arrow_text = "↑ %d" % steps
		"down":
			arrow_text = "↓ %d" % steps
	
	arrow_label.text = arrow_text
	arrow_label.add_theme_font_size_override("font_size", 24)
	arrow_label.add_theme_color_override("font_color", Color.WHITE)
	arrow_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	arrow_label.add_theme_constant_override("shadow_offset_x", 2)
	arrow_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Position arrow next to the car
	var arrow_pos := car.position + car.size / 2 - Vector2(20, 15)
	arrow_label.position = arrow_pos
	board_rect.add_child(arrow_label)
	
	# Store reference in hint_car_highlight metadata for cleanup
	hint_car_highlight.set_meta("arrow", arrow_label)

func _clear_hint_highlight() -> void:
	if hint_car_highlight:
		# Also remove the arrow if it exists
		if hint_car_highlight.has_meta("arrow"):
			var arrow = hint_car_highlight.get_meta("arrow")
			if is_instance_valid(arrow):
				arrow.queue_free()
		hint_car_highlight.queue_free()
		hint_car_highlight = null
