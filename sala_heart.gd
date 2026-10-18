
extends Node2D

@onready var player: CharacterBody2D = $Player

@export var zoom_da_cena: float = 0.8
@export var velocidade_zoom: float = 2.0

var camera_fixa: Camera2D
var posicao_fixa: Vector2

@export var intensidade_tremor_explosao: float = 22.0
@export var duracao_tremor_explosao: float = 0.85

var tempo_tremor_explosao: float = 0.0
var duracao_tremor_atual: float = 0.85

var rng_camera := RandomNumberGenerator.new()

func _ready() -> void:
	get_tree().paused = false

	rng_camera.randomize()

	var coracao: Node = get_node_or_null("Heart")

	if coracao != null:
		if coracao.has_signal("coracao_morreu"):
			coracao.coracao_morreu.connect(explodir_coracao)

	posicao_fixa = player.global_position

	for node in player.find_children("*", "Camera2D", true, false):
		var camera_antiga := node as Camera2D
		camera_antiga.enabled = false

	camera_fixa = Camera2D.new()
	camera_fixa.name = "CameraFixa"

	add_child(camera_fixa)

	camera_fixa.global_position = posicao_fixa
	camera_fixa.position_smoothing_enabled = false
	camera_fixa.zoom = Vector2.ONE
	camera_fixa.make_current()

	var fade := create_tween()
	fade.tween_property($FadeBranco/ColorRect, "color:a", 0.0, 1.0)
	fade.tween_callback($FadeBranco.queue_free)

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if is_instance_valid(camera_fixa):

		var deslocamento_camera := Vector2.ZERO

		if tempo_tremor_explosao > 0.0:
			tempo_tremor_explosao = maxf(
				0.0,
				tempo_tremor_explosao - delta
			)

			var forca: float = (
				tempo_tremor_explosao
				/ maxf(duracao_tremor_atual, 0.01)
			) * intensidade_tremor_explosao

			deslocamento_camera = Vector2(
				rng_camera.randf_range(-forca, forca),
				rng_camera.randf_range(-forca, forca)
			)

		camera_fixa.global_position = (
			posicao_fixa + deslocamento_camera
		)

		var zoom_alvo := Vector2.ONE * zoom_da_cena

		camera_fixa.zoom = camera_fixa.zoom.lerp(
			zoom_alvo,
			1.0 - exp(-velocidade_zoom * delta)
		)

	if is_instance_valid(player):
		$Parallax/GPUParticles2D2.global_position.x = player.global_position.x
		$Parallax/GPUParticles2D.global_position.x = player.global_position.x

func explodir_coracao() -> void:
	print("EXPLOSÃO FINAL DO CORAÇÃO!")

	var explosao: Node2D = get_node_or_null("ExplosaoCoracao")
	var coracao: Node2D = get_node_or_null("Heart")
	var origem: Node = get_node_or_null("OrigemOndas")

	if origem != null:
		if origem.has_method("parar_ondas"):
			origem.parar_ondas()

	if explosao != null and coracao != null:
		explosao.global_position = coracao.global_position

		if explosao.has_method("explodir"):
			explosao.explodir()

	tempo_tremor_explosao = duracao_tremor_explosao
	duracao_tremor_atual = maxf(
		duracao_tremor_explosao,
		0.01
	)
