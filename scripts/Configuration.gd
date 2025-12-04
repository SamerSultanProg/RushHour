extends Control

signal back_pressed

var is_modal := false # Determines if it's an overlay or a full scene

func _ready() -> void:
	# Connect the back button's pressed signal
	$BackButton.text = "Retour"
	UIHelper.style_button($BackButton)
	$BackButton.pressed.connect(func():
		AudioManager.play_button_click()
		if is_modal:
			back_pressed.emit()
		else:
			get_tree().change_scene_to_file("res://scenes/Start.tscn")
	)

	# --- Connect Sliders ---
	var music_slider = $VBoxContainer/MusicSlider
	var sfx_slider = $VBoxContainer/SfxSlider
	
	# Set sliders to the current volume when the scene loads
	music_slider.value = db_to_linear(AudioManager.get_music_volume_db() + 15) # Remap to account for the -15dB cap
	sfx_slider.value = db_to_linear(AudioManager.get_sfx_volume_db())

	# Connect signals for when sliders are moved
	music_slider.value_changed.connect(func(value): AudioManager.set_music_volume_db(linear_to_db(value) - 15)) # Cap max volume at -15dB
	sfx_slider.value_changed.connect(func(value): AudioManager.set_sfx_volume_db(linear_to_db(value)))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_button_click()
		if is_modal:
			back_pressed.emit()
		else:
			get_tree().change_scene_to_file("res://scenes/Start.tscn")
