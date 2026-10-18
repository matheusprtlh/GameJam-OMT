extends Control

@onready var timer_label: Label = $TimerLabel
@onready var button: Button = $Button
@onready var button_2: Button = $Button2
@onready var button_3: Button = $Button3
@onready var container_coracoes: HBoxContainer = $HBoxContainer

var tempo_decorrido: float = 0.0
var rodando: bool = true
var transicao_morte_iniciada: bool = false
var progressao_em_andamento: bool = false

const OPACIDADE_PADRAO: float = 0.4
const OPACIDADE_HOVER: float = 1.0

# Quantidade de vida padrão/base inicial
const VIDA_BASE_MAXIMA: int = 10

# Cores do sistema de vida
const COR_PADRAO: Color = Color(1.0, 1.0, 1.0, 1.0)              # Coração cheio normal (Branco)
const COR_PADRAO_VAZIO: Color = Color(1.0, 1.0, 1.0, 0.2)        # Coração base vazio (Transparente)
const COR_CIANO: Color = Color(0.0, 1.0, 1.0, 1.0)               # Vida extra cheia (Ciano brilhante)
const COR_CIANO_DESATIVADO: Color = Color(0.18, 0.35, 0.42, 0.6) # Limite extra sem vida (Ciano acinzentado)

# Pool de upgrades
const OPCOES_UPGRADE: Array[Dictionary] = [
	{"id": "curar", "texto": "+3 DE VIDA"},
	{"id": "mais_vida", "texto": "+5 VIDA MÁXIMA"},
	{"id": "mais_dano", "texto": "+2 DE DANO"},
	{"id": "velocidade", "texto": "+10% VELOCIDADE"}
]

var upgrades_atuais: Dictionary = {}

func _ready() -> void:
	# Desconecta para evitar conexões duplicadas ao recarregar fases
	if Global.New_Health.is_connected(update_life):
		Global.New_Health.disconnect(update_life)
	if Global.New_Level.is_connected(update_level):
		Global.New_Level.disconnect(update_level)

	Global.New_Health.connect(update_life)
	Global.New_Level.connect(update_level)

	# Atualiza o visual IMEDIATAMENTE no primeiro frame carregado
	# Isso impede o bug de mostrar 10 vidas antes de tomar dano
	update_life(Global.Health)

	# Configura shaders dos botões de forma assíncrona sem travar a vida
	_configurar_botoes()

func _configurar_botoes() -> void:
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return
		
	var botoes: Array[Button] = [button, button_2, button_3]
	for btn in botoes:
		if btn and btn.material:
			btn.material = btn.material.duplicate()
			btn.material.set_shader_parameter("hover_alpha", OPACIDADE_PADRAO)
			btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
			btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))

func _on_button_mouse_entered(btn: Button) -> void:
	if btn.material:
		var tween = create_tween()
		tween.tween_property(btn.material, "shader_parameter/hover_alpha", OPACIDADE_HOVER, 0.15)

func _on_button_mouse_exited(btn: Button) -> void:
	if btn.material:
		var tween = create_tween()
		tween.tween_property(btn.material, "shader_parameter/hover_alpha", OPACIDADE_PADRAO, 0.15)

func _process(delta: float) -> void:
	if rodando:
		tempo_decorrido += delta
		atualizar_label()
		
	# Teclas direcionais e controles visuais
	$TextureRect5.visible = !Input.is_action_pressed("ui_up")
	$TextureRect6.visible = !Input.is_action_pressed("ui_left")
	$TextureRect7.visible = !Input.is_action_pressed("ui_down")
	$TextureRect8.visible = !Input.is_action_pressed("ui_right")
	
	var accept_solto = !Input.is_action_pressed("ui_accept")
	$TextureRect12.visible = accept_solto
	$TextureRect13.visible = accept_solto
	$TextureRect14.visible = accept_solto

func atualizar_label() -> void:
	var minutos: int = int(tempo_decorrido) / 60
	var segundos: int = int(tempo_decorrido) % 60
	timer_label.text = "%02d:%02d" % [minutos, segundos]

func pausar() -> void:
	rodando = false

func retomar() -> void:
	rodando = true

func reiniciar() -> void:
	tempo_decorrido = 0.0
	atualizar_label()

func update_life(valor: int) -> void:
	if valor <= 0:
		if transicao_morte_iniciada or SceneTransition.transitioning:
			return
		transicao_morte_iniciada = true
		SceneTransition.change_scene("res://Cenas/game_over.tscn")
		return
	
	var coracoes = container_coracoes.get_children()
	var max_health_atual: int = Global.MaxH
	
	# Cria corações extras caso o limite seja maior do que os nós existentes
	if max_health_atual > coracoes.size() and coracoes.size() > 0:
		var modelo_coracao = coracoes[0]
		for k in range(coracoes.size(), max_health_atual):
			var novo_coracao = modelo_coracao.duplicate()
			container_coracoes.add_child(novo_coracao)
		coracoes = container_coracoes.get_children()

	# Aplicação das cores por slots de vida:
	for i in range(coracoes.size()):
		var coracao = coracoes[i]
		
		if i < valor:
			# Vida ativa/preenchida
			if i < VIDA_BASE_MAXIMA:
				coracao.modulate = COR_PADRAO           # Branco cheio
			else:
				coracao.modulate = COR_CIANO            # Ciano cheio (extra)
		elif i < max_health_atual:
			# Limite existente, mas vida perdida
			if i < VIDA_BASE_MAXIMA:
				coracao.modulate = COR_PADRAO_VAZIO     # Branco transparente (perdeu vida base)
			else:
				coracao.modulate = COR_CIANO_DESATIVADO # Ciano acinzentado (limite extra vazio)
		else:
			# Nós excedentes invisíveis
			coracao.modulate = Color(1.0, 1.0, 1.0, 0.0)

func obter_label_filho(btn: Button) -> Label:
	for child in btn.get_children():
		if child is Label:
			return child
	return null

func gerenciar_opcoes_botoes() -> void:
	var opcoes_disponiveis = OPCOES_UPGRADE.duplicate()
	opcoes_disponiveis.shuffle()
	
	var botoes: Array[Button] = [button, button_2, button_3]
	for i in range(botoes.size()):
		var upgrade_escolhido = opcoes_disponiveis[i]
		var btn = botoes[i]
		upgrades_atuais[btn] = upgrade_escolhido
		
		var label_filho = obter_label_filho(btn)
		if label_filho:
			label_filho.text = upgrade_escolhido["texto"]

func power():
	if progressao_em_andamento or SceneTransition.transitioning:
		return
	progressao_em_andamento = true
	
	gerenciar_opcoes_botoes()
	
	var tween = create_tween()
	tween.tween_property(button_2, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or SceneTransition.transitioning:
		return
	tween = create_tween()
	tween.tween_property(button, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or SceneTransition.transitioning:
		return
	tween = create_tween()
	tween.tween_property(button_3, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func aplicar_upgrade(btn: Button) -> void:
	if not upgrades_atuais.has(btn):
		return
		
	var upgrade = upgrades_atuais[btn]
	var teto_maximo: int = Global.MaxH
	
	match upgrade["id"]:
		"curar":
			# O setter emite a vida efetivamente armazenada uma única vez.
			Global.Health = min(Global.Health + 3, teto_maximo)
			
		"mais_vida":
			# Aumenta APENAS o teto máximo, sem dar vida
			Global.MaxH = teto_maximo + 5
			update_life(Global.Health)
			
		"mais_dano":
			if "Damage" in Global:
				Global.Damage += 2
				
		"velocidade":
			Global.Speed *= 1.1

func _on_button_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return
	aplicar_upgrade(button)
	var tween = create_tween()
	tween.tween_property(button, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	Global.levelup = 2

func _on_button_2_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return
	aplicar_upgrade(button_2)
	var tween = create_tween()
	tween.tween_property(button_2, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	Global.levelup = 2

func _on_button_3_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return
	aplicar_upgrade(button_3)
	var tween = create_tween()
	tween.tween_property(button_3, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	Global.levelup = 2

func update_level(valor):
	if valor != 2 or transicao_morte_iniciada or SceneTransition.transitioning:
		return
	var tween = create_tween()
	tween.tween_property(button_2, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or SceneTransition.transitioning:
		return
	tween = create_tween()
	tween.tween_property(button, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or SceneTransition.transitioning:
		return
	tween = create_tween()
	tween.tween_property(button_3, "global_position:x", 720, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	if is_inside_tree() and not transicao_morte_iniciada and not SceneTransition.transitioning:
		$"../..".generate_new_seed_and_restart()
