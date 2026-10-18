
extends CanvasLayer

@onready var overlay: ColorRect = $PulseOverlay
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var transitioning := false

func _ready() -> void:
	overlay.visible = false

func change_scene(scene_path: String) -> void:
	if transitioning:
		return
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("Cena inexistente: " + scene_path)
		return

	transitioning = true
	overlay.visible = true

	await get_tree().create_timer(0.5).timeout
	audio.play()

	var material := overlay.material as ShaderMaterial

	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("pulse", 0.0)

	var first := create_tween()
	first.tween_method(
		set_pulse, 0.0, 1.0, 0.25
	)
	await first.finished

	material.set_shader_parameter("pulse", 0.0)

	var second := create_tween()
	second.set_parallel(true)
	second.tween_method(
		set_pulse, 0.0, 1.0, 0.35
	)
	second.tween_method(
		set_progress, 0.0, 1.0, 0.35
	)
	await second.finished

	var error := get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		push_error("Erro ao trocar cena: " + scene_path)
		overlay.visible = false
		transitioning = false
		return

	await get_tree().scene_changed

	material.set_shader_parameter("pulse", 0.0)

	var reveal := create_tween()
	reveal.set_parallel(true)
	reveal.tween_method(
		set_progress, 1.0, 0.0, 0.5
	)
	reveal.tween_method(
		set_pulse, 0.0, 1.0, 0.5
	)
	await reveal.finished

	overlay.visible = false
	transitioning = false

func set_pulse(value: float) -> void:
	overlay.material.set_shader_parameter(
		"pulse", value
	)

func set_progress(value: float) -> void:
	overlay.material.set_shader_parameter(
		"progress", value
	)
