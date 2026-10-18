extends Control

# Referências aos nós da cena
@onready var texto_label: RichTextLabel = $CaixaTexto/TextoHistoria
@onready var indicador_proximo: Label = $IndicadorProximo
@onready var sprite_personagem: AnimatedSprite2D = $Personagem
@onready var caixa_texto: PanelContainer = $CaixaTexto

# História completa, rica em contexto e dividida em blocos consistentes
@export_multiline var falas: Array[String] = [
	"Há muito tempo, o Coração da Floresta mantinha o equilíbrio perfeito da natureza. Rios bioluminescentes e cogumelos gigantes iluminavam a noite, e tudo o que morria voltava a florescer em paz.",
	"Mas um dia o Coração pulsou além do limite e a harmonia se rompeu. Recusando-se a deixar qualquer vida terminar, a energia ancestral corrompeu a vegetação e transformou as criaturas em monstros agressivos.",
	"Você é um pequeno guardião nascido da última semente pura, armado com uma lâmina de luz. Preso no mesmo ciclo imortal, você renasce a cada derrota para cumprir o seu dever.",
	"Para devolver a paz e o descanso à floresta, você precisará enfrentar as criaturas corrompidas e destruir a própria fonte de onde nasceu: o Coração da Floresta."
]

# Caminho para a cena da primeira fase
@export var proxima_fase: String = "res://Cenas/Jogo.tscn"

# Velocidade da digitação do texto (quanto menor o número, mais rápido)
@export var velocidade_digitacao: float = 0.03

# Nome da tua animação no AnimatedSprite2D
@export var animacao_fala: String = "talk"

var indice_fala_atual: int = 0
var exibindo_texto: bool = false
var tween_texto: Tween
var finalizando: bool = false

func _ready() -> void:
	indicador_proximo.visible = false
	sprite_personagem.visible = true
	
	# Exemplo de como ajustar o tamanho da caixa de texto via código (opcional):
	# Você pode alterar a largura (size.x) e a altura (size.y) aqui se preferir
	# caixa_texto.size = Vector2(800, 150) 
	
	# Inicia já pausado no primeiro frame (boca fechada/parado)
	if sprite_personagem.sprite_frames != null and sprite_personagem.sprite_frames.has_animation(animacao_fala):
		sprite_personagem.play(animacao_fala)
		sprite_personagem.pause()
		sprite_personagem.frame = 0
		
	mostrar_fala_atual()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo() and not finalizando:
		if exibindo_texto:
			completar_texto_imediatamente()
		else:
			avancar_fala()

func mostrar_fala_atual() -> void:
	if indice_fala_atual < falas.size():
		texto_label.text = falas[indice_fala_atual]
		texto_label.visible_characters = 0
		exibindo_texto = true
		indicador_proximo.visible = false
		
		if sprite_personagem.sprite_frames != null and sprite_personagem.sprite_frames.has_animation(animacao_fala):
			sprite_personagem.play(animacao_fala)
		
		var total_caracteres = texto_label.text.length()
		var tempo_total = total_caracteres * velocidade_digitacao
		
		tween_texto = create_tween()
		tween_texto.tween_property(texto_label, "visible_characters", total_caracteres, tempo_total)
		tween_texto.finished.connect(_on_texto_concluido)
	else:
		finalizando = true
		SceneTransition.change_scene(proxima_fase)

func _on_texto_concluido() -> void:
	exibindo_texto = false
	indicador_proximo.visible = true
	
	if sprite_personagem.sprite_frames != null and sprite_personagem.sprite_frames.has_animation(animacao_fala):
		sprite_personagem.pause()
		sprite_personagem.frame = 0

func completar_texto_imediatamente() -> void:
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
	texto_label.visible_characters = texto_label.text.length()
	_on_texto_concluido()

func avancar_fala() -> void:
	indice_fala_atual += 1
	mostrar_fala_atual()
