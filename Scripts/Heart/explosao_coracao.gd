
extends Node2D

signal explosao_finalizada

@export var velocidade_onda: float = 480.0
@export var espessura_onda: float = 32.0
@export var raio_maximo: float = 3500.0
@export var quantidade_particulas: int = 65
@export var duracao_flash: float = 0.55

var ativo: bool = false
var raio: float = 0.0
var tempo: float = 0.0
var particulas: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	set_process(false)

func explodir() -> void:
	if ativo:
		return

	ativo = true
	raio = 1.0
	tempo = 0.0
	particulas.clear()

	for i in range(quantidade_particulas):
		var angulo: float = rng.randf_range(0.0, TAU)
		var velocidade: float = rng.randf_range(150.0, 650.0)

		particulas.append({
			"direcao": Vector2(cos(angulo), sin(angulo)),
			"velocidade": velocidade,
			"tamanho": rng.randf_range(2.0, 7.0),
			"fase": rng.randf_range(0.0, TAU)
		})

	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not ativo:
		return

	tempo += delta
	raio += velocidade_onda * delta

	queue_redraw()

	if raio >= raio_maximo:
		ativo = false
		set_process(false)
		queue_redraw()
		explosao_finalizada.emit()

func _draw() -> void:
	if not ativo:
		return

	var cor_ciano := Color(0.0, 0.95, 1.0)
	var cor_branca := Color(0.9, 1.0, 1.0)

	var flash: float = clampf(
		1.0 - tempo / maxf(duracao_flash, 0.01),
		0.0,
		1.0
	)

	if flash > 0.0:
		var cor_flash := Color(0.6, 1.0, 1.0, flash * 0.65)

		draw_circle(
			Vector2.ZERO,
			25.0 + tempo * 230.0,
			cor_flash
		)

	var halo := cor_ciano
	halo.a = 0.12

	draw_arc(
		Vector2.ZERO,
		raio,
		0.0,
		TAU,
		96,
		halo,
		espessura_onda * 3.5,
		true
	)

	var brilho := cor_ciano
	brilho.a = 0.38

	draw_arc(
		Vector2.ZERO,
		raio,
		0.0,
		TAU,
		96,
		brilho,
		espessura_onda * 1.8,
		true
	)

	draw_arc(
		Vector2.ZERO,
		raio,
		0.0,
		TAU,
		96,
		Color(0.1, 0.95, 1.0, 0.9),
		espessura_onda,
		true
	)

	draw_arc(
		Vector2.ZERO,
		raio,
		0.0,
		TAU,
		96,
		cor_branca,
		maxf(2.0, espessura_onda * 0.22),
		true
	)

	for particula in particulas:
		var direcao: Vector2 = particula["direcao"]
		var velocidade: float = particula["velocidade"]
		var tamanho: float = particula["tamanho"]

		var distancia: float = velocidade * tempo
		var posicao: Vector2 = direcao * distancia

		var alpha: float = clampf(
			1.0 - tempo / 2.0,
			0.0,
			1.0
		)

		if alpha <= 0.0:
			continue

		draw_circle(
			posicao,
			tamanho * 2.4,
			Color(0.0, 0.8, 1.0, alpha * 0.15)
		)

		draw_line(
			posicao,
			posicao - direcao * tamanho * 5.0,
			Color(0.1, 0.95, 1.0, alpha * 0.55),
			maxf(1.0, tamanho * 0.6),
			true
		)

		draw_circle(
			posicao,
			tamanho,
			Color(0.85, 1.0, 1.0, alpha)
		)
