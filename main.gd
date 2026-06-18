extends Node

func _unhandled_input(event):
	if event.is_action_pressed("reset_player"):
		# This restarts the current scene.
		get_tree().reload_current_scene()
