extends Control

# Assumes the mute button node is named "MuteButton" and is a child of this scene.
# Please verify the node path is correct.
@onready var mute_button = $MuteButton

func _ready():
	# You can connect the signal here in code, or in the editor's Node dock.
	if mute_button and not mute_button.is_connected("pressed", Callable(self, "_on_mute_button_pressed")):
		mute_button.pressed.connect(self._on_mute_button_pressed)
	
	# Set the initial state of the icon when the game loads.
	update_mute_icon_visibility()

# This function is called when the mute button is clicked.
func _on_mute_button_pressed():
	var master_bus = AudioServer.get_bus_index("Master")
	# Toggle the mute state of the master audio bus.
	AudioServer.set_bus_mute(master_bus, not AudioServer.is_bus_mute(master_bus))
	# Update the icon's visibility to match.
	update_mute_icon_visibility()

# This function correctly shows or hides the mute icon.
func update_mute_icon_visibility():
	var master_bus = AudioServer.get_bus_index("Master")
	if mute_button:
		# The mute icon's visibility is set to be true only if the audio is muted.
		mute_button.visible = AudioServer.is_bus_mute(master_bus)

# ... any other existing code in your DebugStats.gd file should remain ...
