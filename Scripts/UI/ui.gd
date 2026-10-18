extends Control

@onready var timer_label: Label = $TimerLabel
@onready var button: Button = $Button
@onready var button_2: Button = $Button2
@onready var button_3: Button = $Button3
@onready var container_coracoes: HBoxContainer = $HBoxContainer

@onready var som_upgrade: AudioStreamPlayer = $AudioStreamPlayer

var rodando: bool = true
var transicao_morte_iniciada: bool = false
var progressao_em_andamento: bool = false

var passoudefase_inicial: int = 0

const OPACIDADE_PADRAO: float = 0.4
const OPACIDADE_HOVER: float = 1.0

const COR_PADRAO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_PADRAO_VAZIO: Color = Color(1.0, 1.0, 1.0, 0.2)
const COR_CIANO: Color = Color(0.0, 1.0, 1.0, 1.0)
const COR_CIANO_DESATIVADO: Color = Color(0.18, 0.35, 0.42, 0.6)

# ==================== RARIDADES ====================
# peso            -> chance relativa de ser sorteado
# multiplicador   -> multiplica o valor base do upgrade
# unlock_vitorias -> só entra no sorteio com esse mínimo de Global.vitorias (0 = sempre)
const RARIDADE_NORMAL: Dictionary = {
	"nome": "NORMAL",
	"cor": Color(0.0, 0.5, 1.0, 1.0),
	"peso": 60,
	"multiplicador": 1
}

const RARIDADE_RARO: Dictionary = {
	"nome": "RARO",
	"cor": Color(0.1, 1.0, 0.3, 1.0),
	"peso": 25,
	"multiplicador": 2
}

const RARIDADE_EPICO: Dictionary = {
	"nome": "ÉPICO",
	"cor": Color(0.6, 0.1, 1.0, 1.0),
	"peso": 12,
	"multiplicador": 3
}

const RARIDADE_LENDARIO: Dictionary = {
	"nome": "LENDÁRIO",
	"cor": Color(1.0, 0.8, 0.0, 1.0),
	"peso": 3,
	"multiplicador": 4
}

# ULTRA LENDÁRIO: degradê cromático animado no shader
# a "cor" aqui é ignorada (o shader usa o arco-íris quando modo_cromatico = 1.0)
const RARIDADE_ULTRA_LENDARIO: Dictionary = {
	"nome": "ULTRA LENDÁRIO",
	"cor": Color(1.0, 1.0, 1.0, 1.0),
	"peso": 1,
	"multiplicador": 6,
	"unlock_vitorias": 5,
	"cromatico": true
}

const LISTA_RARIDADES: Array[Dictionary] = [
	RARIDADE_NORMAL,
	RARIDADE_RARO,
	RARIDADE_EPICO,
	RARIDADE_LENDARIO,
	RARIDADE_ULTRA_LENDARIO
]

# %d é trocado pelo valor final | %% vira o caractere %
const OPCOES_UPGRADE: Array[Dictionary] = [
	{"id": "curar", "texto": "+%d DE VIDA", "valor_base": 3},
	{"id": "mais_vida", "texto": "+%d VIDA MÁXIMA", "valor_base": 5},
	{"id": "mais_dano", "texto": "+%d DE DANO", "valor_base": 2},
	{"id": "velocidade", "texto": "+%d%% VELOCIDADE", "valor_base": 10}
]

var upgrades_atuais: Dictionary = {}
var tweens_pulso: Dictionary = {}

# ULTRA LENDÁRIO: contador de sorteios forçados + ajustes
var ultra_forcado_restante: int = 0

const VITORIAS_PARA_ULTRA: int = 5
const DURACAO_CICLO_CROMATICO: float = 2.0

func _ready() -> void:
	# permite chamar forcar_ultra_lendarios() de qualquer script:
	# get_tree().call_group("hud_upgrade", "forcar_ultra_lendarios")
	add_to_group("hud_upgrade")

	passoudefase_inicial = Global.passoudefase

	if Global.New_Health.is_connected(update_life):
		Global.New_Health.disconnect(update_life)

	if Global.New_Level.is_connected(update_level):
		Global.New_Level.disconnect(update_level)

	Global.New_Health.connect(update_life)
	Global.New_Level.connect(update_level)

	update_life(Global.Health)
	_configurar_botoes()

	if OS.get_name() != "Android":
		$TouchScreenButton.queue_free()
		$TouchScreenButton2.queue_free()
		$TouchScreenButton3.queue_free()
		$VirtualJoystick.queue_free()

func fase_ja_concluida() -> bool:
	return Global.passoudefase > passoudefase_inicial

func _configurar_botoes() -> void:
	await get_tree().create_timer(0.1).timeout

	if not is_inside_tree():
		return

	var botoes: Array[Button] = [
		button,
		button_2,
		button_3
	]

	for btn in botoes:
		if btn and btn.material:
			btn.material = btn.material.duplicate()
			btn.material.set_shader_parameter(
				"hover_alpha",
				OPACIDADE_PADRAO
			)

			btn.mouse_entered.connect(
				_on_button_mouse_entered.bind(btn)
			)

			btn.mouse_exited.connect(
				_on_button_mouse_exited.bind(btn)
			)

func _on_button_mouse_entered(btn: Button) -> void:
	if btn.material:
		var tween = create_tween()
		tween.tween_property(
			btn.material,
			"shader_parameter/hover_alpha",
			OPACIDADE_HOVER,
			0.15
		)

func _on_button_mouse_exited(btn: Button) -> void:
	if btn.material:
		var tween = create_tween()
		tween.tween_property(
			btn.material,
			"shader_parameter/hover_alpha",
			OPACIDADE_PADRAO,
			0.15
		)

func _process(delta: float) -> void:
	if rodando:
		Global.tempo_decorrido += delta
		atualizar_label()

	$TextureRect5.visible = !Input.is_action_pressed("ui_up")
	$TextureRect6.visible = !Input.is_action_pressed("ui_left")
	$TextureRect7.visible = !Input.is_action_pressed("ui_down")
	$TextureRect8.visible = !Input.is_action_pressed("ui_right")

	var accept_solto = !Input.is_action_pressed("ui_accept")

	$TextureRect12.visible = accept_solto
	$TextureRect13.visible = accept_solto
	$TextureRect14.visible = accept_solto

func atualizar_label() -> void:
	var minutos: int = int(Global.tempo_decorrido) / 60
	var segundos: int = int(Global.tempo_decorrido) % 60

	timer_label.text = "%02d:%02d" % [
		minutos,
		segundos
	]

func pausar() -> void:
	rodando = false

func retomar() -> void:
	rodando = true

func reiniciar() -> void:
	Global.tempo_decorrido = 0.0
	atualizar_label()

func update_life(valor: int) -> void:
	if valor <= 0:

		if fase_ja_concluida():
			return

		if transicao_morte_iniciada or SceneTransition.transitioning:
			return

		transicao_morte_iniciada = true

		SceneTransition.change_scene(
			"res://Cenas/game_over.tscn"
		)

		Global.MaxH = Global.VIDA_BASE_MAXIMA
		Global.Health = Global.VIDA_BASE_MAXIMA
		return

	var coracoes = container_coracoes.get_children()
	var max_health_atual: int = Global.MaxH

	if max_health_atual > coracoes.size() and coracoes.size() > 0:
		var modelo_coracao = coracoes[0]

		for k in range(coracoes.size(), max_health_atual):
			var novo_coracao = modelo_coracao.duplicate()
			container_coracoes.add_child(novo_coracao)

		coracoes = container_coracoes.get_children()

	for i in range(coracoes.size()):
		var coracao = coracoes[i]

		if i < valor:
			if i < Global.VIDA_BASE_MAXIMA:
				coracao.modulate = COR_PADRAO
			else:
				coracao.modulate = COR_CIANO

		elif i < max_health_atual:
			if i < Global.VIDA_BASE_MAXIMA:
				coracao.modulate = COR_PADRAO_VAZIO
			else:
				coracao.modulate = COR_CIANO_DESATIVADO

		else:
			coracao.modulate = Color(
				1.0,
				1.0,
				1.0,
				0.0
			)

# ==================== SORTEIO DE RARIDADE ====================
# A Ultra Lendária pode ser FORÇADA (independe das vitórias):
# chame forcar_ultra_lendarios() para as próximas opções serem ultra
func sortear_raridade() -> Dictionary:
	if ultra_forcado_restante > 0:
		ultra_forcado_restante -= 1
		return RARIDADE_ULTRA_LENDARIO

	var peso_total: int = 0

	for raridade in LISTA_RARIDADES:
		if _raridade_bloqueada(raridade):
			continue

		peso_total += raridade["peso"]

	var rolagem: int = randi_range(1, peso_total)
	var acumulado: int = 0

	for raridade in LISTA_RARIDADES:
		if _raridade_bloqueada(raridade):
			continue

		acumulado += raridade["peso"]

		if rolagem <= acumulado:
			return raridade

	return LISTA_RARIDADES[0]

func _raridade_bloqueada(raridade: Dictionary) -> bool:
	if raridade.get("unlock_vitorias", 0) <= 0:
		return false

	return not ultra_lendario_liberado()

func ultra_lendario_liberado() -> bool:
	if not ("vitorias" in Global):
		return false

	return Global.vitorias >= VITORIAS_PARA_ULTRA

## Força as próximas 'quantidade' opções sorteadas a serem ULTRA LENDÁRIAS.
## Ex.: forcar_ultra_lendarios()     -> a próxima tela inteira (3 botões) será ultra
##      forcar_ultra_lendarios(1)    -> só 1 botão ultra na próxima tela
func forcar_ultra_lendarios(quantidade: int = 3) -> void:
	ultra_forcado_restante = quantidade

# Aplica o visual da raridade no shader do botão
# - ÉPICO e LENDÁRIO: brilho pulsante
# - ULTRA LENDÁRIO: degradê cromático animado
func aplicar_raridade_visual(btn: Button, raridade: Dictionary) -> void:
	if not (btn.material is ShaderMaterial):
		return

	# para a animação anterior, se existir
	if tweens_pulso.has(btn):
		var tween_antigo: Tween = tweens_pulso[btn]

		if is_instance_valid(tween_antigo) and tween_antigo.is_valid():
			tween_antigo.kill()

		tweens_pulso.erase(btn)

	# garante que o botão saia do modo cromático por padrão
	btn.material.set_shader_parameter("modo_cromatico", 0.0)

	var cor: Color = raridade["cor"]

	# ULTRA LENDÁRIO: liga o degradê cromático animado
	if raridade.get("cromatico", false):
		btn.material.set_shader_parameter("modo_cromatico", 1.0)

		# 0 -> 1 = um ciclo completo do arco-íris (loop perfeito, sem "pulo")
		var tween: Tween = create_tween().set_loops()
		tween.tween_method(
			_definir_tempo_cromatico.bind(btn),
			0.0,
			1.0,
			DURACAO_CICLO_CROMATICO
		)

		tweens_pulso[btn] = tween
		return

	btn.material.set_shader_parameter("base_color", cor)

	# só ÉPICO (3x) e LENDÁRIO (4x) brilham
	if raridade["multiplicador"] < 3:
		return

	var cor_brilhante: Color = cor.lerp(Color(1.0, 1.0, 1.0), 0.45)

	var tween: Tween = create_tween().set_loops()
	tween.tween_method(_pulso_cor.bind(btn, cor, cor_brilhante), 0.0, 1.0, 0.45)
	tween.tween_method(_pulso_cor.bind(btn, cor_brilhante, cor), 0.0, 1.0, 0.45)

	tweens_pulso[btn] = tween

func _pulso_cor(t: float, btn: Button, cor_a: Color, cor_b: Color) -> void:
	if btn.material is ShaderMaterial:
		btn.material.set_shader_parameter(
			"base_color",
			cor_a.lerp(cor_b, t)
		)

func _definir_tempo_cromatico(t: float, btn: Button) -> void:
	if btn.material is ShaderMaterial:
		btn.material.set_shader_parameter("tempo_cromatico", t)

func obter_label_filho(btn: Button) -> Label:
	for child in btn.get_children():
		if child is Label and child.name != "RaridadeLabel":
			return child

	return null

# Label OPCIONAL: se você criar um Label chamado "RaridadeLabel"
# dentro de cada botão, o nome da raridade aparece nele
func obter_label_raridade(btn: Button) -> Label:
	for child in btn.get_children():
		if child is Label and child.name == "RaridadeLabel":
			return child

	return null

func gerenciar_opcoes_botoes() -> void:
	var opcoes_disponiveis = OPCOES_UPGRADE.duplicate()
	opcoes_disponiveis.shuffle()

	var botoes: Array[Button] = [
		button,
		button_2,
		button_3
	]

	for i in range(botoes.size()):
		var upgrade_base: Dictionary = opcoes_disponiveis[i]
		var raridade: Dictionary = sortear_raridade()
		var btn: Button = botoes[i]

		var valor_final: int = upgrade_base["valor_base"] * raridade["multiplicador"]

		upgrades_atuais[btn] = {
			"id": upgrade_base["id"],
			"valor": valor_final
		}

		var label_filho: Label = obter_label_filho(btn)

		if label_filho:
			label_filho.text = upgrade_base["texto"] % valor_final

		var label_raridade: Label = obter_label_raridade(btn)

		if label_raridade:
			label_raridade.text = raridade["nome"]

		aplicar_raridade_visual(btn, raridade)

func power() -> void:
	if progressao_em_andamento or SceneTransition.transitioning:
		return

	progressao_em_andamento = true

	gerenciar_opcoes_botoes()

	var tween = create_tween()
	tween.tween_property(
		button_2,
		"global_position:x",
		320,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await get_tree().create_timer(0.2).timeout

	if not is_inside_tree() or SceneTransition.transitioning:
		return

	tween = create_tween()
	tween.tween_property(
		button,
		"global_position:x",
		320,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await get_tree().create_timer(0.2).timeout

	if not is_inside_tree() or SceneTransition.transitioning:
		return

	tween = create_tween()
	tween.tween_property(
		button_3,
		"global_position:x",
		320,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func aplicar_upgrade(btn: Button) -> void:
	if not upgrades_atuais.has(btn):
		return

	if som_upgrade.stream != null:
		som_upgrade.play()

	var upgrade: Dictionary = upgrades_atuais[btn]
	var teto_maximo: int = Global.MaxH
	var valor: int = upgrade["valor"]

	match upgrade["id"]:
		"curar":
			Global.Health = mini(
				Global.Health + valor,
				teto_maximo
			)

		"mais_vida":
			Global.MaxH = teto_maximo + valor
			update_life(Global.Health)

		"mais_dano":
			if "Damage" in Global:
				Global.Damage += valor

		"velocidade":
			if "Speed" in Global:
				# mantém a proporção do código antigo: 10% exibido = 20 de Speed
				Global.Speed += valor * 2.0

func _on_button_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return

	aplicar_upgrade(button)

	var tween = create_tween()
	tween.tween_property(
		button,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	Global.levelup = 2

func _on_button_2_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return

	aplicar_upgrade(button_2)

	var tween = create_tween()
	tween.tween_property(
		button_2,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	Global.levelup = 2

func _on_button_3_pressed() -> void:
	if Global.levelup != 1 or SceneTransition.transitioning or transicao_morte_iniciada:
		return

	aplicar_upgrade(button_3)

	var tween = create_tween()
	tween.tween_property(
		button_3,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	Global.levelup = 2

func update_level(valor):
	if valor != 2 or transicao_morte_iniciada or SceneTransition.transitioning:
		return

	var tween = create_tween()
	tween.tween_property(
		button_2,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await get_tree().create_timer(0.2).timeout

	if not is_inside_tree() or SceneTransition.transitioning:
		return

	tween = create_tween()
	tween.tween_property(
		button,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await get_tree().create_timer(0.2).timeout

	if not is_inside_tree() or SceneTransition.transitioning:
		return

	tween = create_tween()
	tween.tween_property(
		button_3,
		"global_position:x",
		720,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if is_inside_tree() and not transicao_morte_iniciada and not SceneTransition.transitioning:
		$"../..".generate_new_seed_and_restart()
