extends CanvasLayer

# ========================================================
# GLOBAL DEBUG STATS OVERLAY
# ========================================================
# Press F12 at ANY time to toggle FPS and RAM display
# Works across all scenes as an autoload
# ========================================================

var stats_panel: PanelContainer
var fps_label: Label
var ram_label: Label

func _ready() -> void:
	# Set to highest layer so it's always on top
	layer = 100
	
	_build_stats_panel()
	stats_panel.visible = false
	
	print("[DebugStats] Initialized - Press F12 to toggle")

func _build_stats_panel() -> void:
	# Create a Control to hold the panel (needed for proper anchoring in CanvasLayer)
	var container := Control.new()
	container.name = "StatsContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	stats_panel = PanelContainer.new()
	stats_panel.name = "GlobalStatsPanel"
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel_style.border_color = Color(0.5, 0.8, 0.5, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Position in top-right corner using offsets
	stats_panel.anchor_left = 1.0
	stats_panel.anchor_right = 1.0
	stats_panel.anchor_top = 0.0
	stats_panel.anchor_bottom = 0.0
	stats_panel.offset_left = -130
	stats_panel.offset_right = -10
	stats_panel.offset_top = 10
	stats_panel.offset_bottom = 70
	
	container.add_child(stats_panel)
	
	# VBox for labels
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(vbox)
	
	# FPS Label
	fps_label = Label.new()
	fps_label.text = "FPS: --"
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	vbox.add_child(fps_label)
	
	# RAM Label
	ram_label = Label.new()
	ram_label.text = "RAM: -- MB"
	ram_label.add_theme_font_size_override("font_size", 14)
	ram_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	vbox.add_child(ram_label)

func _process(_delta: float) -> void:
	if stats_panel and stats_panel.visible:
		var fps := Engine.get_frames_per_second()
		var ram := OS.get_static_memory_usage() / 1024 / 1024
		fps_label.text = "FPS: %d" % fps
		ram_label.text = "RAM: %d MB" % ram

func _unhandled_input(event: InputEvent) -> void:
	# Check both the input action and direct key press
	if event.is_action_pressed("toggle_debug_stats"):
		toggle_stats()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		toggle_stats()

func toggle_stats() -> void:
	if stats_panel:
		stats_panel.visible = not stats_panel.visible
		print("[DebugStats] Toggled: ", stats_panel.visible)

func show_stats() -> void:
	if stats_panel:
		stats_panel.visible = true

func hide_stats() -> void:
	if stats_panel:
		stats_panel.visible = false
