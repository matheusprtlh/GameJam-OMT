extends CharacterBody2D

@onready var camera: Camera2D = $Camera2D
var alvo: CharacterBody2D = null

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _process(delta: float) -> void:
	camera.global_position.x = global_position.x
	camera.global_position.y = 180

func _physics_process(delta: float) -> void:
	# Adiciona gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		criar_poeira()

	# Movimentação
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()

# Quando o inimigo entra no alcance
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		alvo = body

# Quando o inimigo SAI do alcance
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == alvo:
		alvo = null
		for candidato in $Area2D.get_overlapping_bodies():
			if candidato != body and candidato.is_in_group("Enemy"):
				alvo = candidato
				break

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Ataque"):
		if is_instance_valid(alvo) and alvo.has_method("levar_dano"):
			var direcao_ataque = alvo.global_position - global_position
			
			var segurando_cima = Input.is_action_pressed("ui_up")
			var dir_horizontal = Input.get_axis("ui_left", "ui_right")
			
			# Lança na diagonal se segurar CIMA + DIREÇÃO
			var tipo_lancamento = "normal"
			if segurando_cima and dir_horizontal != 0:
				tipo_lancamento = "diagonal"
				direcao_ataque = Vector2(dir_horizontal, -1.0) # Direção na diagonal superior
			elif segurando_cima:
				tipo_lancamento = "vertical"
				direcao_ataque.y = -1.0
			
			alvo.levar_dano(1, direcao_ataque, tipo_lancamento)

func criar_poeira() -> void:
	var poeira: CPUParticles2D = $CPUParticles2D.duplicate()
	get_parent().add_child(poeira)
	poeira.global_position = $CPUParticles2D.global_position
	poeira.restart()
	poeira.finished.connect(poeira.queue_free)
