
extends CharacterBody2D

@onready var camera: Camera2D = $Camera2D
@onready var sprite: Node2D = get_node_or_null("AnimatedSprite2D")

var alvo: CharacterBody2D = null

const ATTACK_COOLDOWN: float = 0.22
var attack_cooldown_remaining: float = 0.0

const JUMP_VELOCITY = -400.0

var jump_buffer_time: float = 0.15
var jump_buffer_timer: float = 0.0

var pode_pulo_duplo: bool = false

const DASH_SPEED = 800.0
const DASH_DURATION = 0.2
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 1.0
var ja_deu_dash_no_ar: bool = false

var ghost_spawn_timer: float = 0.0
const GHOST_SPAWN_INTERVAL: float = 0.03

var esta_invulneravel: bool = false
var em_knockback: bool = false
var tempo_knockback: float = 0.2
var timer_knockback: float = 0.0

@export var void_y: float = 1200.0
var morreu_no_void: bool = false

var passoudefase_inicial: int = 0

func _ready() -> void:
	passoudefase_inicial = Global.passoudefase

func fase_ja_concluida() -> bool:
	return Global.levelup == 1 or Global.levelup == 2

func _process(_delta: float) -> void:
	if is_instance_valid(camera) and camera.is_current():
		camera.global_position.x = global_position.x
		camera.global_position.y = 180

	# Faz o nó da luz girar na direção do cursor do mouse
	$Pivot.look_at(get_global_mouse_position())

	var posicao_mouse = get_local_mouse_position()
	var ponto_origem = $Line2D.get_point_position(0)

	if posicao_mouse != ponto_origem:
		var direcao = (posicao_mouse - ponto_origem).normalized()
		var ponto_final = ponto_origem + (direcao * 200)
		$Line2D.set_point_position(1, ponto_final)

func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = maxf(
		0.0,
		attack_cooldown_remaining - delta
	)

	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if is_dashing:
		dash_timer -= delta
		ghost_spawn_timer -= delta

		if ghost_spawn_timer <= 0:
			criar_ghost_trail()
			ghost_spawn_timer = GHOST_SPAWN_INTERVAL

		if dash_timer <= 0:
			is_dashing = false

	if em_knockback:
		timer_knockback -= delta

		if timer_knockback <= 0:
			em_knockback = false

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	if Input.is_action_just_pressed("Dash") and not is_dashing and not em_knockback:
		if is_on_floor() or not ja_deu_dash_no_ar:
			iniciar_dash()

	if is_on_floor():
		pode_pulo_duplo = true
		ja_deu_dash_no_ar = false

	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta

	if jump_buffer_time > 0 and jump_buffer_timer > 0 and not em_knockback:
		if is_on_floor():
			executar_pulo()

		elif is_dashing:
			is_dashing = false
			executar_pulo()
			pode_pulo_duplo = false

		elif pode_pulo_duplo:
			executar_pulo()
			pode_pulo_duplo = false

	if em_knockback:
		pass

	elif is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0

	else:
		var direction := Input.get_axis(
			"ui_left",
			"ui_right"
		)

		if direction:
			velocity.x = direction * Global.Speed
			$AnimatedSprite2D.play("Walk")
			$AnimatedSprite2D.flip_h = direction < 0
		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				Global.Speed
			)
			$AnimatedSprite2D.play("default")

	move_and_slide()

	verificar_void()

func verificar_void() -> void:
	if morreu_no_void:
		return

	if SceneTransition.transitioning:
		return

	if fase_ja_concluida():
		return

	if global_position.y >= void_y:
		morrer_no_void()

func morrer_no_void() -> void:
	if morreu_no_void:
		return

	if SceneTransition.transitioning:
		return

	if fase_ja_concluida():
		return

	morreu_no_void = true

	velocity = Vector2.ZERO
	is_dashing = false
	em_knockback = false

	set_physics_process(false)
	set_process_input(false)

	Global.Health = 0

func criar_ghost_trail() -> void:
	if sprite == null:
		return

	var ghost: Node2D = sprite.duplicate()
	get_parent().add_child(ghost)

	ghost.global_position = sprite.global_position
	ghost.rotation = sprite.rotation
	ghost.scale = Vector2(0.3, 0.3)

	ghost.modulate = Color(0.3, 0.7, 1.0, 0.6)

	var tween = create_tween()

	tween.tween_property(
		ghost,
		"modulate:a",
		0.0,
		0.2
	)

	tween.finished.connect(ghost.queue_free)

func levar_dano(
	quantidade: int,
	origem_dano_pos: Vector2,
	força_knockback: float = 350.0
) -> void:
	if morreu_no_void or fase_ja_concluida():
		return

	if esta_invulneravel or SceneTransition.transitioning or Global.Health <= 0:
		return

	Global.Health -= quantidade

	is_dashing = false
	em_knockback = true
	timer_knockback = tempo_knockback

	var direcao_empurrao: Vector2 = (
		global_position - origem_dano_pos
	)

	var lado_horizontal = sign(direcao_empurrao.x)

	if lado_horizontal == 0:
		lado_horizontal = -1.0

	velocity.x = lado_horizontal * força_knockback
	velocity.y = -250.0

	piscar_vermelho(0.8)

func piscar_vermelho(
	duracao_invulnerabilidade: float
) -> void:
	esta_invulneravel = true

	if sprite != null:
		var tween = create_tween()
		tween.set_loops(4)

		tween.tween_property(
			sprite,
			"modulate",
			Color(1, 0.2, 0.2, 1),
			0.1
		)

		tween.tween_property(
			sprite,
			"modulate",
			Color(1, 1, 1, 1),
			0.1
		)

	await get_tree().create_timer(
		duracao_invulnerabilidade
	).timeout

	if not is_inside_tree():
		return

	if sprite != null:
		sprite.modulate = Color(1, 1, 1, 1)

	esta_invulneravel = false

func iniciar_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	ghost_spawn_timer = 0.0

	var dir = Input.get_axis(
		"ui_left",
		"ui_right"
	)

	if dir != 0:
		dash_direction = sign(dir)
	else:
		dash_direction = (
			sign(velocity.x)
			if velocity.x != 0
			else 1.0
		)

	if not is_on_floor():
		ja_deu_dash_no_ar = true

func executar_pulo() -> void:
	velocity.y = JUMP_VELOCITY
	criar_poeira()
	jump_buffer_timer = 0.0

func _on_area_2d_body_entered(
	body: Node2D
) -> void:
	if body.is_in_group("Enemy"):
		alvo = body

func _on_area_2d_body_exited(
	body: Node2D
) -> void:
	if body == alvo:
		alvo = null

		for candidato in $Area2D.get_overlapping_bodies():
			if candidato != body and candidato.is_in_group("Enemy"):
				alvo = candidato
				break

func _input(event: InputEvent) -> void:
	if morreu_no_void or fase_ja_concluida():
		return

	if not event.is_action_pressed("Ataque") or event.is_echo() or SceneTransition.transitioning:
		return

	if attack_cooldown_remaining > 0.0:
		return

	var area_ataque: Area2D = $Area2D

	for area: Area2D in area_ataque.get_overlapping_areas():
		if not area.is_in_group("HitboxCoracao"):
			continue

		var coracao: Node = area.get_parent()

		if coracao.has_method("levar_dano"):
			coracao.levar_dano(
				Global.Damage,
				Vector2.ZERO,
				"normal"
			)

			attack_cooldown_remaining = ATTACK_COOLDOWN
			print("CORAÇÃO ATINGIDO!")
			return

	var inimigos_validos: Array[Node2D] = []

	for corpo in area_ataque.get_overlapping_bodies():
		if corpo.is_in_group("Enemy") and not corpo.is_queued_for_deletion() and corpo.has_method("levar_dano"):
			inimigos_validos.append(corpo)

	if inimigos_validos.is_empty():
		return

	attack_cooldown_remaining = ATTACK_COOLDOWN

	var segurando_cima := Input.is_action_pressed("ui_up")
	var dir_horizontal := Input.get_axis(
		"ui_left",
		"ui_right"
	)

	for inimigo in inimigos_validos:
		var direcao_ataque: Vector2 = (
			inimigo.global_position - global_position
		)

		var tipo_lancamento := "normal"

		if segurando_cima and dir_horizontal != 0:
			tipo_lancamento = "diagonal"
			direcao_ataque = Vector2(dir_horizontal, -1.0)

		elif segurando_cima:
			tipo_lancamento = "vertical"
			direcao_ataque.y = -1.0

		inimigo.levar_dano(
			Global.Damage,
			direcao_ataque,
			tipo_lancamento
		)

func criar_poeira() -> void:
	var poeira: CPUParticles2D = (
		$CPUParticles2D.duplicate()
	)

	get_parent().add_child(poeira)

	poeira.global_position = (
		$CPUParticles2D.global_position
	)

	poeira.restart()

	poeira.finished.connect(poeira.queue_free)

func _on_tpsala_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://sala_heart.tscn")
	print("funcionou")
