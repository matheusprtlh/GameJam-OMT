
extends CharacterBody2D

@export var force_knockback_normal: float = 300.0
@export var force_knockback_forte: float = 600.0
@export var force_launch_up: float = -500.0
@export var tempo_reset_combo: float = 0.5
@export var atrito_knockback: float = 800.0
@export var vida: int = 3

@export var push_force: float = 2000.0

@export var velocidade_perseguicao: float = 80.0
@export var distancia_parada: float = 35.0
@export var duracao_stun: float = 0.3

@onready var push_area: Area2D = $Push
@onready var detection_area: Area2D = $DetectionArea

var contagem_golpes: int = 0
var tempo_ultimo_golpe: float = 0.0

var player_alvo: CharacterBody2D = null
var tempo_stun: float = 0.0
var esta_morrendo: bool = false

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	if esta_morrendo:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if tempo_stun > 0.0:
		tempo_stun -= delta
		velocity.x = move_toward(
			velocity.x, 0.0, atrito_knockback * delta
		)

	elif is_instance_valid(player_alvo):
		var distancia = abs(
			player_alvo.global_position.x - global_position.x
		)

		if distancia > distancia_parada:
			var direcao = sign(
				player_alvo.global_position.x - global_position.x
			)
			velocity.x = direcao * velocidade_perseguicao
		else:
			velocity.x = move_toward(
				velocity.x, 0.0, atrito_knockback * delta
			)
	else:
		player_alvo = null
		velocity.x = move_toward(
			velocity.x, 0.0, atrito_knockback * delta
		)
	
	if is_instance_valid(player_alvo):
		$Sprite2D.flip_h = (player_alvo.global_position.x < global_position.x)

	move_and_slide()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body is CharacterBody2D:
		player_alvo = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player_alvo:
		player_alvo = null

func levar_dano(
	dano: int,
	direcao_ataque: Vector2,
	tipo_lancamento: String = "normal"
) -> void:
	if esta_morrendo or dano <= 0:
		return

	vida = max(vida - dano, 0)
	hit(dano)
	if vida == 0:
		esta_morrendo = true
		set_collision_layer(0)
		set_collision_mask(0)
		queue_free()
		return

	var tempo_atual = Time.get_ticks_msec() / 1000.0

	if tempo_atual - tempo_ultimo_golpe > tempo_reset_combo:
		contagem_golpes = 0

	tempo_ultimo_golpe = tempo_atual
	contagem_golpes += 1

	if tipo_lancamento == "diagonal":
		aplicar_knockback(
			direcao_ataque, force_knockback_forte, "diagonal"
		)
	elif tipo_lancamento == "vertical":
		aplicar_knockback(
			direcao_ataque, force_knockback_normal, "vertical"
		)
	elif contagem_golpes >= 3:
		aplicar_knockback(
			direcao_ataque, force_knockback_forte, "normal"
		)
		contagem_golpes = 0
	else:
		aplicar_knockback(
			direcao_ataque, force_knockback_normal, "normal"
		)

func aplicar_knockback(
	direcao: Vector2,
	forca: float,
	modo: String = "normal"
) -> void:
	tempo_stun = duracao_stun

	var empurrao = direcao.normalized() * forca

	if modo == "vertical":
		velocity.y = force_launch_up
	elif modo == "diagonal":
		velocity.x = empurrao.x
		velocity.y = force_launch_up * 0.8
	else:
		velocity.y = -150.0 if empurrao.y == 0 else empurrao.y
		velocity.x = empurrao.x

func hit(num: int):
	var label = $Label.duplicate()
	label.text = str(num)
	get_parent().add_child(label)
	label.global_position = $Label.global_position
	label.show()
	label.get_node("AnimationPlayer").play("Hit")
	label.get_node("AnimationPlayer").animation_finished.connect(
		label.queue_free.unbind(1)
	)

func _on_push_body_entered(body: Node2D) -> void:
	if not esta_morrendo and not SceneTransition.transitioning and body.is_in_group("Player"):
		body.levar_dano(1, global_position, 300)
