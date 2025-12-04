extends Control

func _ready() -> void:
	# Connect the back button's pressed signal
	$BackButton.text = "Retour"
	UIHelper.style_button($BackButton)
	$BackButton.pressed.connect(func():
		AudioManager.play_button_click()
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_button_click()
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
