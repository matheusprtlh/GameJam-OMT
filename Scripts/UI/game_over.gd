extends Control

func _on_retry_pressed() -> void:
	SceneTransition.change_scene("res://Cenas/Jogo.tscn")

func _on_menu_pressed() -> void:
	SceneTransition.change_scene("res://Cenas/menu.tscn")
