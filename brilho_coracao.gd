
extends Node2D

@onready var jogador: CharacterBody2D = $"../Player"
@onready var claridade: ColorRect = $CanvasLayer/ClaridadeCoracao

@export var distancia_branco: float = 750.0

@export var raio_luz_longe: float = 130.0
@export var raio_luz_perto: float = 500.0

@export var intensidade_longe: float = 0.35
@export var intensidade_perto: float = 1.0

@export var claridade_maxima: float = 1.0
@export var suavidade_clareamento: float = 3.0

@export var cor_azul: Color = Color(0.0, 0.85, 1.0)
@export var cor_branco: Color = Color(1.0, 1.0, 1.0)

@export var velocidade_pulso: float = 2.5

var proximidade: float = 0.0
var tempo: float = 0.0
var claridade_atual: float = 0.0
var distancia_inicial: float = 0.0

func _ready() -> void:
	if not is_instance_valid(claridade):
		push_error("ClaridadeCoracao não encontrado!")
		set_process(false)
		return

	claridade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claridade.color = Color(1.0, 1.0, 1.0, 0.0)

	if is_instance_valid(jogador):
		distancia_inicial = global_position.distance_to(
			jogador.global_position
		)

func _process(delta: float) -> void:
	if not is_instance_valid(jogador):
		return

	tempo += delta

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)

	var inicio: float = maxf(
		distancia_inicial,
		distancia_branco + 1.0
	)

	proximidade = clampf(
		(inicio - distancia) /
		(inicio - distancia_branco),
		0.0,
		1.0
	)

	var intensidade_tela: float = pow(
		proximidade,
		1.5
	)

	claridade_atual = lerpf(
		claridade_atual,
		intensidade_tela,
		1.0 - exp(-suavidade_clareamento * delta)
	)

	var cor_tela: Color = cor_azul.lerp(
		cor_branco,
		pow(proximidade, 0.8)
	)

	cor_tela.a = clampf(
		claridade_atual * claridade_maxima,
		0.0,
		1.0
	)

	claridade.color = cor_tela

	queue_redraw()

func _draw() -> void:
	var pulso: float = (
		sin(tempo * velocidade_pulso) + 1.0
	) * 0.5

	var raio: float = lerpf(
		raio_luz_longe,
		raio_luz_perto,
		proximidade
	)

	raio *= lerpf(0.95, 1.08, pulso)

	var intensidade: float = lerpf(
		intensidade_longe,
		intensidade_perto,
		proximidade
	)

	for i in range(12, 0, -1):
		var fator: float = float(i) / 12.0

		var cor: Color = cor_azul.lerp(
			cor_branco,
			proximidade * 0.7
		)

		cor.a = intensidade * 0.035

		draw_circle(
			Vector2.ZERO,
			raio * fator * 2.5,
			cor
		)

	for i in range(8, 0, -1):
		var fator: float = float(i) / 8.0

		var cor: Color = cor_azul
		cor.a = intensidade * 0.055

		draw_circle(
			Vector2.ZERO,
			raio * fator,
			cor
		)

	var nucleo: Color = cor_branco
	nucleo.a = intensidade * 0.85

	draw_circle(
		Vector2.ZERO,
		raio * 0.12,
		nucleo
	)

	draw_circle(
		Vector2.ZERO,
		raio * 0.045,
		Color(1.0, 1.0, 1.0, intensidade)
	)
