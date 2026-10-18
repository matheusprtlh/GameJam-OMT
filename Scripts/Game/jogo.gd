extends Node2D

@export var chunk_scenes: Array[PackedScene] = []
@export var grid_width: int = 5
@export var chunk_size_in_pixels: Vector2 = Vector2(256, 256)
@onready var player: CharacterBody2D = $Player
@onready var chunks_container: Node2D = $ChunksContainer
@export var enemy_scenes: Array[PackedScene] = []
# Margem abaixo da área do mapa antes de considerar uma queda fatal.
@export var fall_margin: float = 200.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	get_tree().paused = false
	Global.levelup = 0
	if Global.comecou == false:
		Global.comecou = true

	# a seed salva permite repetir a mesma fase.
	if Global.current_seed == 0:
		rng.randomize()
		Global.current_seed = rng.seed
	else:
		rng.seed = Global.current_seed
	
	print("Seed atual: ", Global.current_seed)
	generate_map()

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	if is_instance_valid(player):
		if player.global_position.y > chunk_size_in_pixels.y + fall_margin and not SceneTransition.transitioning:
			Global.Health = 0
			return

		$Parallax/GPUParticles2D2.global_position.x = player.global_position.x
		$Parallax/GPUParticles2D.global_position.x = player.global_position.x

		if player.global_position.x >= (640 * grid_width) and Global.levelup == 0 and not SceneTransition.transitioning:
			$CanvasLayer/UI.power()
			Global.levelup = 1

func generate_map() -> void:
	if chunk_scenes.is_empty():
		push_error("Nenhum chunk foi configurado no Array 'chunk_scenes'!")
		return

	for child in chunks_container.get_children():
		child.queue_free()

	for x in range(grid_width):
		var random_index := rng.randi_range(0, chunk_scenes.size() - 1)
		var chunk_scene := chunk_scenes[random_index]

		var chunk_instance := chunk_scene.instantiate() as Node2D

		chunk_instance.position = Vector2.RIGHT * (
			x * chunk_size_in_pixels.x
		)

		chunks_container.add_child(chunk_instance)

		_setup_chunk_markers(chunk_instance, x == 0)
	player.get_node("Camera2D").limit_right = 640 * grid_width

func _setup_chunk_markers(
	chunk: Node2D,
	is_first_chunk: bool
) -> void:

	for marker_node in chunk.find_children("*", "Marker2D", true, false):
		var child := marker_node as Marker2D

		if is_first_chunk and child.name == "PlayerSpawn":
			if is_instance_valid(player):
				player.global_position = child.global_position

			child.queue_free()

		elif child.name.begins_with("Enemy") and not enemy_scenes.is_empty():
			_spawn_enemy_at_marker(child)

func _spawn_enemy_at_marker(marker: Node2D) -> void:
	var random_index := rng.randi_range(0, enemy_scenes.size() - 1)
	var random_enemy_scene := enemy_scenes[random_index]

	var enemy_instance := random_enemy_scene.instantiate() as Node2D

	add_child(enemy_instance)
	enemy_instance.global_position = marker.global_position

	marker.queue_free()

func restart_scene() -> void:
	if not SceneTransition.transitioning:
		Global.prepare_retry()
		SceneTransition.change_scene(scene_file_path)

func generate_new_seed_and_restart() -> void:
	if SceneTransition.transitioning:
		return

	Global.vitorias += 1
	print("Vitórias: ", Global.vitorias)

	Global.levelup = 0
	Global.current_seed = 0

	if Global.vitorias % 5 == 0:
		get_tree().change_scene_to_file("res://caminho_heart.tscn")
	else:
		SceneTransition.change_scene(scene_file_path)
	
