extends Control

var money = 0
var pizzas_delivered = 0

# Preload music tracks as resources
var tracks = {
	"track1": preload("res://Graveyard Waltz (Main Menu).mp3"),
	"track2": preload("res://Graveyard Waltz (Main Menu).mp3")
}

var current_track: String = ""
var audio_player: AudioStreamPlayer
var is_muted: bool = false

func _ready():
	# Hide by default - only show when in gameplay scene
	visible = false
	
	set_process_input(true)
	# Get the AudioStreamPlayer child node
	audio_player = get_node("MusicPlayer")
	
	# Add error checking
	if audio_player == null:
		print("Error: MusicPlayer node not found!")
		return
	
	# Load saved settings
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		print("Settings loaded successfully")
		var volume = config.get_value("audio", "master_volume", 0.5)
		is_muted = config.get_value("audio", "is_muted", false)
		set_volume(volume)
		# Don't call set_mute here as it will save again, just set the value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	else:
		print("No settings file found, using defaults")
	
	# Start playing background music
	play_track("track1")

func play_track(track_name: String):
	print("Attempting to play track: ", track_name)
	
	if audio_player == null:
		print("Error: audio_player is null!")
		return
		
	if tracks.has(track_name) and track_name != current_track:
		current_track = track_name
		var track_resource = tracks[track_name]
		
		print("Loading track resource: ", track_resource)
		audio_player.stream = track_resource
		
		if not is_muted:
			print("Starting playback...")
			audio_player.play()
		else:
			print("Audio is muted, not playing")
	else:
		if not tracks.has(track_name):
			print("Track not found: ", track_name)
		else:
			print("Track already playing: ", track_name)

func stop_track():
	if audio_player != null:
		audio_player.stop()
	current_track = ""

func set_volume(volume: float):
	# Clamp volume to valid range
	volume = clamp(volume, 0.0, 1.0)
	
	# Convert linear volume (0.0 to 1.0) to decibels
	var db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	print("Volume set to: ", volume, " (", db, " dB)")
	
	# Save volume setting
	var config = ConfigFile.new()
	# Load existing config first to preserve other settings
	config.load("user://settings.cfg")
	config.set_value("audio", "master_volume", volume)
	config.save("user://settings.cfg")

func set_mute(mute: bool):
	# FIX: Set the value directly, don't toggle it
	is_muted = mute
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mute)
	
	print("Mute set to: ", mute)
	
	# Add null check before calling methods on audio_player
	if audio_player != null:
		if is_muted:
			audio_player.stop()
			print("Audio stopped due to mute")
		elif current_track != "":
			audio_player.play()
			print("Audio resumed from mute")
	
	# Save mute setting
	var config = ConfigFile.new()
	# Load existing config first to preserve other settings
	config.load("user://settings.cfg")
	config.set_value("audio", "is_muted", mute)
	config.save("user://settings.cfg")
