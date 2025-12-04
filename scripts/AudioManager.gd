extends Node

signal mute_changed(is_muted: bool)

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Define bus indices for clarity
const MUSIC_BUS_IDX = 1
const SFX_BUS_IDX = 2

var background_music = preload("res://assets/audio/background_music.mp3")
var car_move_sfx = preload("res://assets/audio/car_move.mp3")
var win_sfx = preload("res://assets/audio/win.mp3")

var button_click_sfx = preload("res://assets/audio/button_click.mp3")

func _ready():
	# --- Create custom audio buses for separate volume control ---
	# Music Bus
	AudioServer.add_bus(MUSIC_BUS_IDX)
	AudioServer.set_bus_name(MUSIC_BUS_IDX, "Music")
	AudioServer.set_bus_send(MUSIC_BUS_IDX, "Master")
	AudioServer.set_bus_volume_db(MUSIC_BUS_IDX, -15) # Set a quiet default volume
	# SFX Bus
	AudioServer.add_bus(SFX_BUS_IDX)
	AudioServer.set_bus_name(SFX_BUS_IDX, "SFX")
	AudioServer.set_bus_send(SFX_BUS_IDX, "Master")


	# Create and configure the music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.stream = background_music
	music_player.bus = "Music" # Assign to Music bus
	add_child(music_player)
	
	# Connect the finished signal to loop the music
	music_player.finished.connect(music_player.play)

	# Play music on the next frame
	music_player.play.call_deferred()

	# Create the SFX player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	sfx_player.bus = "SFX" # Assign to SFX bus
	add_child(sfx_player)

	# Enable processing for the mute button check
	set_process(true)

func _process(_delta):
	if Input.is_action_just_pressed("mute"):
		var bus_index = AudioServer.get_bus_index("Master")
		var new_mute_state = not AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, new_mute_state)
		mute_changed.emit(new_mute_state)

func is_muted() -> bool:
	var bus_index = AudioServer.get_bus_index("Master")
	return AudioServer.is_bus_mute(bus_index)

# --- Volume Control Functions ---
func set_music_volume_db(volume_db: float):
	AudioServer.set_bus_volume_db(MUSIC_BUS_IDX, volume_db)

func set_sfx_volume_db(volume_db: float):
	AudioServer.set_bus_volume_db(SFX_BUS_IDX, volume_db)

func get_music_volume_db() -> float:
	return AudioServer.get_bus_volume_db(MUSIC_BUS_IDX)

func get_sfx_volume_db() -> float:
	return AudioServer.get_bus_volume_db(SFX_BUS_IDX)

func play_car_move():
	sfx_player.stream = car_move_sfx
	sfx_player.play()

func play_win():
	sfx_player.stream = win_sfx
	sfx_player.play()

func play_button_click():
	sfx_player.stream = button_click_sfx
	sfx_player.play()
