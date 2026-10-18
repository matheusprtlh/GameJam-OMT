extends Control

func _exit_tree() -> void:
	$AudioStreamPlayer.stop()
	$AudioStreamPlayer.stream = null

func _on_quit_pressed() -> void:
	$AudioStreamPlayer.stop()
	# Permite que o servidor de audio libere o playback antes de encerrar.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()




func _on_play_pressed() -> void:
	if SceneTransition.transitioning:
		return
	if Global.Health <= 0:
		Global.prepare_retry()
	SceneTransition.change_scene("res://Cenas/cutscene_historia.tscn")
	
	
