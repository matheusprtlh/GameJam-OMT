
extends Label

@export var velocidade: float = 0.5

@export var cor_branca: Color = Color("#FFFFFF")
@export var cor_ciano: Color = Color("#00FFFF")
@export var cor_rosa: Color = Color("#FF69D2")

var tempo: float = 0.0

func _process(delta: float) -> void:
	tempo += delta * velocidade

	var cores = [
		cor_branca,
		cor_ciano,
		cor_rosa
	]

	var posicao = fposmod(tempo, 3.0)
	var indice = int(posicao)
	var proximo = (indice + 1) % 3

	var fade = posicao - float(indice)

	fade = fade * fade * (3.0 - 2.0 * fade)

	var cor_atual = cores[indice].lerp(
		cores[proximo],
		fade
	)

	add_theme_color_override("font_color", cor_atual)
