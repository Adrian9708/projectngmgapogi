extends Control

@onready var timer_label = $"Delivery time/Timer Label"

var time_elapsed: float = 0.0

func _ready():
	print("Script started!")
	print("Timer label found: ", timer_label)
	
	if timer_label == null:
		print("ERROR: Can't find Timer Label!")
	else:
		print("Timer label text: ", timer_label.text)
		timer_label.text = "SCRIPT WORKING"
	
	update_timer_display()

func _process(delta):
	time_elapsed += delta
	update_timer_display()

func update_timer_display():
	if timer_label != null:
		var minutes = int(time_elapsed) / 60
		var seconds = int(time_elapsed) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]
