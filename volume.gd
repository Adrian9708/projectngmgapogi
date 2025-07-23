extends HSlider




func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)


func _on_mute_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_resolution_item_selected(index: int) -> void:
	pass # Replace with function body.
