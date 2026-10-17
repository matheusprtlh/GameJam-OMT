extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Parallax/GPUParticles2D2.global_position.x = $Player.global_position.x
	$Parallax/GPUParticles2D.global_position.x = $Player.global_position.x
