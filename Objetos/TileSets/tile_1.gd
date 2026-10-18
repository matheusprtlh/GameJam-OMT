extends TileMapLayer

@export var limite_sombras: float = 100.0

# Flag para garantir que a função limite rode apenas uma vez ao passar do limite
var limite_atingido: bool = false

func _process(_delta: float) -> void:
	atualizar_efeito_cinza()

func atualizar_efeito_cinza() -> void:
	# Calcula o progresso de 0.0 (0% sombras) a 1.0 (100% sombras)
	var progresso: float = clamp(Global.sombras / limite_sombras, 0.0, 1.0)
	
	# A saturação vai de 1.0 (cor normal) até 0.0 (cinza) conforme o número sobe
	var nivel_saturacao: float = 1.0 - progresso
	
	# Passa o valor para o Shader da Sprite
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("saturacao", nivel_saturacao)
	
	# Verificação do Limite
	if Global.sombras >= limite_sombras:
		if not limite_atingido:
			limite_atingido = true
			_ao_atingir_limite()
	else:
		# Reseta caso o valor de Global.sombras volte a cair abaixo do limite
		limite_atingido = false

# Sua função que será executada ao atingir/passar o limite
func _ao_atingir_limite() -> void:
	print("Limite de sombras atingido! Executando a função...")
	# Adicione aqui o seu código (ex: game over, transformar inimigo, etc.)
