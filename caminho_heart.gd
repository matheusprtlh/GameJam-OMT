
extends Node2D

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	get_tree().paused = false

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	if is_instance_valid(player):
		$Parallax/GPUParticles2D2.global_position.x = player.global_position.x
		$Parallax/GPUParticles2D.global_position.x = player.global_position.x
