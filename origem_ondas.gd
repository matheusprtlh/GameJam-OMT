extends Node2D

@onready var jogador: CharacterBody2D = $"../Player"

@export var tempo_primeira_onda: float = 3.0
@export var distancia_maxima: float = 5000.0
@export var raio_maximo: float = 6000.0

@export var intervalo_longe: float = 3.0
@export var intervalo_perto: float = 0.8

@export var velocidade_longe: float = 420.0
@export var velocidade_perto: float = 1400.0

@export var multiplicador_velocidade_morte: float = 1.0
@export var multiplicador_frequencia_morte: float = 3.0
@export var duracao_ondas_morte: float = 5.0

var ondas_aceleradas: bool = false
var ondas_finalizadas: bool = false
var tempo_desde_morte: float = 0.0

@export var velocidade_onda_final: float = 550.0
@export var espessura_onda_final: float = 35.0
@export var brilho_onda_final: float = 2.5
@export var particulas_onda_final: int = 48

var onda_final_ativa: bool = false
var onda_final_emitida: bool = false

@export var intensidade_longe: float = 0.55
@export var intensidade_perto: float = 1.0

@export var espessura_longe: float = 3.0
@export var espessura_perto: float = 7.0

@export var cor_onda: Color = Color(0.0, 0.95, 1.0, 1.0)
@export var cor_nucleo: Color = Color(0.85, 1.0, 1.0, 1.0)

@export var brilho_longe: float = 0.7
@export var brilho_perto: float = 1.5

@export var particulas_longe: int = 12
@export var particulas_perto: int = 18
@export var tamanho_particula: float = 2.0
@export var velocidade_particulas: float = 0.25
@export var rastro_particulas: bool = true

var ondas: Array[Dictionary] = []
var tempo: float = 0.0
var tempo_global: float = 0.0
var proximidade: float = 0.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	if not is_instance_valid(jogador):
		return

	var distancia_inicial: float = global_position.distance_to(
		jogador.global_position
	)

	raio_maximo = maxf(
		raio_maximo,
		distancia_inicial + 1000.0
	)

	var raio_inicial: float = maxf(
		0.0,
		distancia_inicial - velocidade_longe * tempo_primeira_onda
	)

	criar_onda(raio_inicial)

func acelerar_ondas() -> void:
	if ondas_aceleradas or ondas_finalizadas:
		return

	ondas_aceleradas = true
	tempo_desde_morte = 0.0
	tempo = 0.0

	print("ONDAS DO CORAÇÃO ACELERADAS!")

func parar_ondas() -> void:
	ondas_finalizadas = true
	ondas_aceleradas = false

	ondas.clear()
	queue_redraw()

	print("ONDAS NORMAIS FINALIZADAS!")

func emitir_onda_final() -> void:
	if onda_final_emitida:
		return

	onda_final_emitida = true

	parar_ondas()

	onda_final_ativa = true

	var particulas: Array[Dictionary] = []

	var quantidade: int = maxi(0, particulas_onda_final)

	for i in range(quantidade):
		particulas.append({
			"angulo": TAU * float(i) / float(maxi(quantidade, 1)),
			"fase": rng.randf_range(0.0, TAU),
			"tamanho": rng.randf_range(1.0, 2.0),
			"velocidade": rng.randf_range(0.5, 1.5)
		})

	ondas.append({
		"raio": 1.0,
		"alpha": 1.0,
		"particulas": particulas,
		"final": true
	})

	queue_redraw()

	print("ÚLTIMA ONDA EMITIDA!")

func _process(delta: float) -> void:
	if onda_final_ativa:
		tempo_global += delta

		for i in range(ondas.size() - 1, -1, -1):
			var onda: Dictionary = ondas[i]

			onda["raio"] += velocidade_onda_final * delta

			var progresso: float = clampf(
				onda["raio"] / maxf(raio_maximo, 1.0),
				0.0,
				1.0
			)

			onda["alpha"] = pow(1.0 - progresso, 1.5)

			if onda["raio"] >= raio_maximo:
				ondas.remove_at(i)
			else:
				ondas[i] = onda

		if ondas.is_empty():
			onda_final_ativa = false

		queue_redraw()
		return

	if ondas_finalizadas:
		return

	if ondas_aceleradas:
		tempo_desde_morte += delta

		if tempo_desde_morte >= duracao_ondas_morte:
			parar_ondas()
			return

	if not is_instance_valid(jogador):
		return

	tempo_global += delta

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)

	proximidade = clampf(
		1.0 - distancia / maxf(distancia_maxima, 1.0),
		0.0,
		1.0
	)

	var aceleracao: float = pow(proximidade, 1.5)

	var intervalo: float = lerpf(
		intervalo_longe,
		intervalo_perto,
		aceleracao
	)

	var velocidade: float = lerpf(
		velocidade_longe,
		velocidade_perto,
		aceleracao
	)

	if ondas_aceleradas:
		velocidade *= maxf(
			multiplicador_velocidade_morte,
			1.0
		)

		intervalo /= maxf(
			multiplicador_frequencia_morte,
			1.0
		)

	tempo += delta

	if tempo >= intervalo:
		tempo = 0.0
		criar_onda()

	for i in range(ondas.size() - 1, -1, -1):
		var onda: Dictionary = ondas[i]

		onda["raio"] += delta * velocidade

		var forca: float = lerpf(
			intensidade_longe,
			intensidade_perto,
			proximidade
		)

		var desaparecimento: float = lerpf(
			1.0,
			0.6,
			clampf(
				onda["raio"] / maxf(raio_maximo, 1.0),
				0.0,
				1.0
			)
		)

		onda["alpha"] = forca * desaparecimento

		if onda["raio"] >= raio_maximo:
			ondas.remove_at(i)
		else:
			ondas[i] = onda

	queue_redraw()

func criar_onda(raio_inicial: float = 0.0) -> void:
	if ondas_finalizadas:
		return

	var particulas: Array[Dictionary] = []

	var quantidade: int = maxi(0, particulas_perto)

	for i in range(quantidade):
		particulas.append({
			"angulo": TAU * float(i) / float(maxi(quantidade, 1)),
			"fase": rng.randf_range(0.0, TAU),
			"tamanho": rng.randf_range(0.6, 1.4),
			"velocidade": rng.randf_range(0.6, 1.4)
		})

	ondas.append({
		"raio": raio_inicial,
		"alpha": intensidade_longe,
		"particulas": particulas,
		"final": false
	})

func _draw() -> void:
	var espessura_normal: float = lerpf(
		espessura_longe,
		espessura_perto,
		proximidade
	)

	var brilho_normal: float = lerpf(
		brilho_longe,
		brilho_perto,
		proximidade
	)

	var quantidade_normal: int = roundi(
		lerpf(
			float(particulas_longe),
			float(particulas_perto),
			proximidade
		)
	)

	for onda in ondas:
		var raio: float = onda["raio"]
		var alpha: float = clampf(
			onda["alpha"],
			0.0,
			1.0
		)

		if raio < 2.0:
			continue

		var eh_final: bool = onda.get("final", false)

		var espessura: float = espessura_normal
		var fator_brilho: float = brilho_normal
		var quantidade_visivel: int = quantidade_normal

		if eh_final:
			espessura = espessura_onda_final
			fator_brilho = brilho_onda_final
			quantidade_visivel = particulas_onda_final

		var segmentos: int = 96

		var halo: Color = cor_onda
		halo.a = clampf(
			alpha * 0.08 * fator_brilho,
			0.0,
			1.0
		)

		draw_arc(
			Vector2.ZERO,
			raio,
			0.0,
			TAU,
			segmentos,
			halo,
			espessura * 3.0,
			true
		)

		var brilho: Color = cor_onda
		brilho.a = clampf(
			alpha * 0.25 * fator_brilho,
			0.0,
			1.0
		)

		draw_arc(
			Vector2.ZERO,
			raio,
			0.0,
			TAU,
			segmentos,
			brilho,
			espessura * 1.7,
			true
		)

		var linha: Color = cor_onda
		linha.a = clampf(
			alpha * 0.75 * fator_brilho,
			0.0,
			1.0
		)

		draw_arc(
			Vector2.ZERO,
			raio,
			0.0,
			TAU,
			segmentos,
			linha,
			espessura,
			true
		)

		var nucleo: Color = cor_nucleo
		nucleo.a = clampf(
			alpha * fator_brilho,
			0.0,
			1.0
		)

		draw_arc(
			Vector2.ZERO,
			raio,
			0.0,
			TAU,
			segmentos,
			nucleo,
			maxf(1.0, espessura * 0.3),
			true
		)

		var particulas: Array = onda["particulas"]

		var total: int = mini(
			quantidade_visivel,
			particulas.size()
		)

		for i in range(total):
			var particula: Dictionary = particulas[i]

			var angulo: float = (
				particula["angulo"]
				+ tempo_global * velocidade_particulas * particula["velocidade"]
			)

			var cintilacao: float = (
				sin(
					tempo_global * 5.0
					+ particula["fase"]
				) + 1.0
			) * 0.5

			var deslocamento: float = sin(
				tempo_global * 3.0
				+ particula["fase"]
			) * 3.0

			var raio_particula: float = raio + deslocamento

			var direcao := Vector2(
				cos(angulo),
				sin(angulo)
			)

			var posicao: Vector2 = direcao * raio_particula

			var tamanho: float = (
				tamanho_particula
				* particula["tamanho"]
				* lerpf(0.7, 1.4, proximidade)
			)

			if eh_final:
				tamanho *= 1.6

			var alpha_particula: float = clampf(
				alpha
				* (0.4 + cintilacao * 0.6)
				* fator_brilho,
				0.0,
				1.0
			)

			var cor_halo: Color = cor_onda
			cor_halo.a = alpha_particula * 0.18

			draw_circle(
				posicao,
				tamanho * 2.5,
				cor_halo
			)

			if rastro_particulas:
				var tangente := Vector2(
					-sin(angulo),
					cos(angulo)
				)

				var cor_rastro: Color = cor_onda
				cor_rastro.a = alpha_particula * 0.3

				draw_line(
					posicao,
					posicao - tangente * tamanho * 4.0,
					cor_rastro,
					maxf(1.0, tamanho * 0.6),
					true
				)

			var cor_particula: Color = cor_nucleo
			cor_particula.a = alpha_particula

			draw_circle(
				posicao,
				tamanho,
				cor_particula
			)
