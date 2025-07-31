extends Node

# Preload music tracks
var tracks = {
	"track1": preload("res://zombie-packclean-record-70768.mp3"),
	"track2": preload("res://zombie-packclean-record-70768.mp3")
}

var current_track: String = ""
var audio_player: AudioStreamPlayer
var is_muted: bool = false

func _ready():
	# Get the AudioStreamPlayer child node
	audio_player = $MusicPlayer	
	
	# Load saved settings
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "master_volume", 0.5)
		is_muted = config.get_value("audio", "is_muted", false)
		set_volume(volume)
		set_mute(is_muted)

func play_track(track_name: String):
	if tracks.has(track_name) and track_name != current_track:
		current_track = track_name
		audio_player.stream = tracks[track_name]
		if not is_muted:
			audio_player.play()

func stop_track():
	audio_player.stop()
	current_track = ""

func set_volume(volume: float):
	# Convert linear volume (0.0 to 1.0) to decibels
	var db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	# Save volume setting
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", volume)
	config.save("user://settings.cfg")

func set_mute(mute: bool):
	is_muted = mute
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mute)
	if mute:
		audio_player.stop()
	elif current_track != "":
		audio_player.play()
	
	# Save mute setting
	var config = ConfigFile.new()
	config.set_value("audio", "is_muted", mute)
	config.save("user://settings.cfg")
