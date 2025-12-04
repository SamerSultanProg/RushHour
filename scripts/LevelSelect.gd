extends Control

func _ready() -> void:
	# A CenterContainer fills the whole screen and perfectly centers its child.
	var center_container := CenterContainer.new()
	center_container.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	add_child(center_container)

	# This VBox holds the button grid and the back button vertically.
	var main_vbox := VBoxContainer.new()
	center_container.add_child(main_vbox)

	# --- GridContainer for the level buttons ---
	var grid := GridContainer.new()
	grid.columns = 5
	main_vbox.add_child(grid)
	
	var count: int = Levels.get_level_count()
	for i in range(count):
		var b := Button.new()
		b.text = "Niveau %d" % (i + 1)
		b.pressed.connect(func (): _load_level(i))
		UIHelper.style_button(b)
		grid.add_child(b)

	# --- A small spacer between the grid and the back button ---
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)

	# --- The back button ---
	var back_button := Button.new()
	back_button.text = "Retour"
	back_button.pressed.connect(_go_back)
	UIHelper.style_button(back_button)
	main_vbox.add_child(back_button)

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
