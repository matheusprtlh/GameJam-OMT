
extends Node2D

@export var vida_maxima: int = 3

var vida_atual: int
var morreu: bool = false

signal vida_alterada(vida_atual: int, vida_maxima: int)
signal coracao_morreu

@export var duracao_shake: float = 0.24
@export var intensidade_shake: float = 0.035
@export var oscilacoes: int = 8

@export var duracao_morte: float = 5.0
@export var intensidade_morte: float = 50
@export var velocidade_morte: float = 35.0

@onready var visual: ColorRect = $ColorRect

var posicao_original: Vector2
var escala_original: Vector2

var tween_shake: Tween

var tremendo_morte: bool = false
var tempo_morte: float = 0.0

var deslocamento_atual: Vector2 = Vector2.ZERO
var deslocamento_alvo: Vector2 = Vector2.ZERO
var tempo_novo_alvo: float = 0.0

func _ready() -> void:
	vida_maxima = maxi(1, vida_maxima)
	vida_atual = vida_maxima

	posicao_original = visual.position
	escala_original = visual.scale

	add_to_group("Coracao")

	vida_alterada.emit(vida_atual, vida_maxima)

func _process(delta: float) -> void:
	if not tremendo_morte:
		return

	tempo_morte += delta

	if tempo_morte >= duracao_morte:
		finalizar_tremida_morte()
		return

	tempo_novo_alvo -= delta

	if tempo_novo_alvo <= 0.0:
		tempo_novo_alvo = 0.055

		deslocamento_alvo = Vector2(
			randf_range(-intensidade_morte, intensidade_morte),
			randf_range(-intensidade_morte, intensidade_morte)
		)

	var suavizacao: float = 1.0 - exp(
		-velocidade_morte * delta
	)

	deslocamento_atual = deslocamento_atual.lerp(
		deslocamento_alvo,
		suavizacao
	)

	visual.position = posicao_original + deslocamento_atual

func levar_dano(
	_quantidade: int,
	_direcao: Vector2 = Vector2.ZERO,
	_tipo: String = "normal"
) -> void:
	if morreu:
		return

	vida_atual = maxi(0, vida_atual - 1)

	print("VIDA DO CORAÇÃO: ", vida_atual, "/", vida_maxima)

	vida_alterada.emit(vida_atual, vida_maxima)

	if vida_atual == 0:
		morrer()
	else:
		tremer()

func tremer() -> void:
	if not is_instance_valid(visual):
		return

	if tween_shake and tween_shake.is_running():
		tween_shake.kill()

	visual.position = posicao_original
	visual.scale = escala_original

	tween_shake = create_tween()

	var quantidade_oscilacoes: int = maxi(1, oscilacoes)
	var tempo_etapa: float = duracao_shake / float(
		quantidade_oscilacoes
	)

	for i in range(quantidade_oscilacoes):
		var forca: float = 1.0 - float(i) / float(
			quantidade_oscilacoes
		)

		var lado: float = 1.0 if i % 2 == 0 else -1.0

		var escala_alvo: Vector2 = escala_original * Vector2(
			1.0 + lado * intensidade_shake * forca,
			1.0 - lado * intensidade_shake * forca
		)

		tween_shake.tween_property(
			visual,
			"scale",
			escala_alvo,
			tempo_etapa
		).set_trans(Tween.TRANS_SINE)

	tween_shake.tween_property(
		visual,
		"scale",
		escala_original,
		0.05
	)

func morrer() -> void:
	if morreu:
		return

	morreu = true

	var origem_ondas: Node = get_parent().get_node_or_null("OrigemOndas")

	if origem_ondas != null and origem_ondas.has_method("acelerar_ondas"):
		origem_ondas.acelerar_ondas()

	if tween_shake and tween_shake.is_running():
		tween_shake.kill()

	visual.position = posicao_original
	visual.scale = escala_original

	tempo_morte = 0.0
	tempo_novo_alvo = 0.0

	deslocamento_atual = Vector2.ZERO
	deslocamento_alvo = Vector2.ZERO

	tremendo_morte = true

func finalizar_tremida_morte() -> void:
	if not tremendo_morte:
		return

	tremendo_morte = false

	visual.position = posicao_original
	visual.scale = escala_original
	$ColorRect.queue_free()

	print("O CORAÇÃO PAROU DE TREMER!")

	coracao_morreu.emit()
