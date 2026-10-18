extends Node

# execute com interface gráfica para capturar a cena.

const DESTINO := "res://Tests/captura_heart.png"

func _ready() -> void:
	var sala = load("res://sala_heart.tscn").instantiate()
	add_child(sala)
	await get_tree().create_timer(0.6).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(DESTINO)
	print("CAPTURA_SALVA: ", ProjectSettings.globalize_path(DESTINO))
	get_tree().quit()
