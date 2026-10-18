extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if visible:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func pause_game() -> void:
	show()
	get_tree().paused = true
	var resume_button := get_node_or_null("RichTextLabel/Resume") as Button
	if resume_button != null:
		resume_button.grab_focus()

func resume_game() -> void:
	get_tree().paused = false
	hide()

func _on_resume_pressed() -> void:
	resume_game()

func _on_menu_pressed() -> void:
	# despause antes da transição para o menu funcionar.
	resume_game()
	SceneTransition.change_scene("res://Cenas/menu.tscn")
