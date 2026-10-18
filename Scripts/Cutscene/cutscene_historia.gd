
extends Control

@onready var texto_label: RichTextLabel = $CaixaTexto/TextoHistoria
@onready var indicador_proximo: Label = $IndicadorProximo
@onready var sprite_personagem: AnimatedSprite2D = $Personagem
@onready var caixa_texto: PanelContainer = $CaixaTexto

@export_multiline var falas: Array[String] = [
	"HÁ MUITO TEMPO, O CORAÇÃO DA FLORESTA MANTINHA O EQUILÍBRIO PERFEITO DA NATUREZA. RIOS BIOLUMINESCENTES E COGUMELOS GIGANTES ILUMINAVAM A NOITE, E TUDO O QUE MORRIA VOLTAVA A FLORESCER EM PAZ.",
	"MAS UM DIA O CORAÇÃO PULSOU ALÉM DO LIMITE E A HARMONIA SE ROMPEU. RECUSANDO-SE A DEIXAR QUALQUER VIDA TERMINAR, A ENERGIA ANCESTRAL CORROMPEU A VEGETAÇÃO E TRANSFORMOU AS CRIATURAS EM MONSTROS AGRESSIVOS.",
	"VOCÊ É UM PEQUENO GUARDIÃO NASCIDO DA ÚLTIMA SEMENTE PURA, ARMADO COM UMA LÂMINA DE LUZ. PRESO NO MESMO CICLO IMORTAL, VOCÊ RENASCE A CADA DERROTA PARA CUMPRIR O SEU DEVER.",
	"PARA DEVOLVER A PAZ E O DESCANSO À FLORESTA, VOCÊ PRECISARÁ ENFRENTAR AS CRIATURAS CORROMPIDAS E DESTRUIR A PRÓPRIA FONTE DE ONDE NASCEU: O CORAÇÃO DA FLORESTA."
]

@export var proxima_fase: String = "res://Cenas/Jogo.tscn"
@export var velocidade_digitacao: float = 0.03
@export var delay_inicial: float = 2.0

var indice_fala_atual: int = 0
var exibindo_texto: bool = false
var dialogo_iniciado: bool = false
var finalizando: bool = false
var tween_texto: Tween

func _ready() -> void:
	indicador_proximo.visible = false
	texto_label.visible = false
	sprite_personagem.visible = true

	dialogo_iniciado = false
	exibindo_texto = false
	finalizando = false

	await get_tree().create_timer(delay_inicial).timeout

	if not is_inside_tree():
		return

	dialogo_iniciado = true
	texto_label.visible = true
	mostrar_fala_atual()

func _input(event: InputEvent) -> void:
	if not dialogo_iniciado or finalizando:
		return

	if event.is_action_pressed("ui_accept") and not event.is_echo():
		if exibindo_texto:
			completar_texto_imediatamente()
		else:
			avancar_fala()

func mostrar_fala_atual() -> void:
	if finalizando:
		return

	if indice_fala_atual >= falas.size():
		finalizar_dialogo()
		return

	if tween_texto and tween_texto.is_running():
		tween_texto.kill()

	texto_label.text = falas[indice_fala_atual]
	texto_label.visible_characters = 0

	exibindo_texto = true
	indicador_proximo.visible = false

	var total_caracteres: int = texto_label.get_total_character_count()
	var tempo_total: float = total_caracteres * velocidade_digitacao

	if total_caracteres == 0 or tempo_total <= 0.0:
		texto_label.visible_characters = -1
		_on_texto_concluido()
		return

	tween_texto = create_tween()
	tween_texto.tween_property(
		texto_label,
		"visible_characters",
		total_caracteres,
		tempo_total
	)
	tween_texto.finished.connect(_on_texto_concluido)

func _on_texto_concluido() -> void:
	if finalizando or not exibindo_texto:
		return

	exibindo_texto = false
	indicador_proximo.visible = true

func completar_texto_imediatamente() -> void:
	if not exibindo_texto:
		return

	if tween_texto and tween_texto.is_running():
		tween_texto.kill()

	texto_label.visible_characters = -1
	_on_texto_concluido()

func avancar_fala() -> void:
	if exibindo_texto or finalizando:
		return

	indice_fala_atual += 1
	mostrar_fala_atual()

func finalizar_dialogo() -> void:
	if finalizando:
		return

	finalizando = true
	dialogo_iniciado = false
	exibindo_texto = false

	indicador_proximo.visible = false

	SceneTransition.change_scene(proxima_fase)
	
