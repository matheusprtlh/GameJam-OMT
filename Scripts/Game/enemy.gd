extends CharacterBody2D

# Configurações de Knockback
@export var force_knockback_normal: float = 300.0
@export var force_knockback_forte: float = 600.0
@export var force_launch_up: float = -500.0 
@export var tempo_reset_combo: float = 0.5 
@export var atrito_knockback: float = 800.0

# Aumente a força de empurrão para vencer o atrito/resitência
@export var push_force: float = 2000.0 

@onready var push_area: Area2D = $Push

var contagem_golpes: int = 0
var tempo_ultimo_golpe: float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. Aplica o atrito constante
	velocity.x = move_toward(velocity.x, 0, atrito_knockback * delta)

	move_and_slide()

func levar_dano(dano: int, direcao_ataque: Vector2, tipo_lancamento: String = "normal") -> void:
	var tempo_atual = Time.get_ticks_msec() / 1000.0
	if tempo_atual - tempo_ultimo_golpe > tempo_reset_combo:
		contagem_golpes = 0
	
	tempo_ultimo_golpe = tempo_atual
	contagem_golpes += 1
	hit(dano)
	
	if tipo_lancamento == "diagonal":
		aplicar_knockback(direcao_ataque, force_knockback_forte, "diagonal")
	elif tipo_lancamento == "vertical":
		aplicar_knockback(direcao_ataque, force_knockback_normal, "vertical")
	elif contagem_golpes >= 3:
		aplicar_knockback(direcao_ataque, force_knockback_forte, "normal")
		contagem_golpes = 0
	else:
		aplicar_knockback(direcao_ataque, force_knockback_normal, "normal")

func aplicar_knockback(direcao: Vector2, forca: float, modo: String = "normal") -> void:
	var empurrao = direcao.normalized() * forca
	
	if modo == "vertical":
		velocity.y = force_launch_up
	elif modo == "diagonal":
		velocity.x = empurrao.x
		velocity.y = force_launch_up * 0.8 # Arremessa na diagonal para cima e para o lado
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
	label.get_node("AnimationPlayer").animation_finished.connect(label.queue_free.unbind(1))
