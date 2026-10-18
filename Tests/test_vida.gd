extends Node

# teste headless: godot --headless --path . res://Tests/test_vida.tscn

var falhas: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame

	print("== Global: regras de vida ==")
	_testar_global()

	print("== UI: cores e upgrades ==")
	await _testar_ui()

	print("== Jogo: entrada em fase nova ==")
	await _testar_jogo()

	print("== Morte: reset da run ==")
	await _testar_morte()

	if falhas.is_empty():
		print("RESULTADO: TODOS OS TESTES PASSARAM")
		get_tree().quit(0)
	else:
		for f in falhas:
			printerr("FALHOU: " + f)
		print("RESULTADO: %d TESTE(S) FALHARAM" % falhas.size())
		get_tree().quit(1)

func _verificar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok: " + descricao)
	else:
		falhas.append(descricao)
		printerr("  FALHOU: " + descricao)

func _resetar_run(teto: int, vida: int) -> void:
	Global.MaxH = teto
	Global.Health = vida

func _testar_global() -> void:
	_resetar_run(10, 10)
	_verificar(Global.Health == 10, "Health inicia em 10 (recebeu %d)" % Global.Health)
	_verificar(Global.MaxH == 10, "MaxH inicia em 10 (recebeu %d)" % Global.MaxH)

	Global.Health = 10
	Global.Health = Global.Health + 3
	_verificar(Global.Health == 10, "cura com teto 10 satura em 10 (recebeu %d)" % Global.Health)

	Global.MaxH = 15
	_verificar(Global.Health == 10, "+5 de limite nao da vida (recebeu %d)" % Global.Health)

	Global.Health = Global.Health + 3
	_verificar(Global.Health == 13, "cura com teto 15 vai a 13 (recebeu %d)" % Global.Health)

	Global.Health = Global.Health + 3
	_verificar(Global.Health == 15, "cura satura no teto 15 (recebeu %d)" % Global.Health)

	_verificar(Global.Health == 15, "vida extra persiste: 15/15 (recebeu %d)" % Global.Health)
	Global.Health -= 1
	_verificar(Global.Health == 14, "dano de 15 vai a 14 (recebeu %d)" % Global.Health)

	var emitidos: Array = []
	var receptor := func(valor): emitidos.append(valor)
	Global.New_Health.connect(receptor)
	Global.Health = 99
	Global.New_Health.disconnect(receptor)
	_verificar(emitidos.size() == 1 and int(emitidos[0]) == 15,
		"sinal New_Health emite valor limitado a 15 (recebeu %s)" % str(emitidos))
	Global.Health = 10

func _testar_ui() -> void:
	_resetar_run(10, 10)
	var ui = load("res://Objetos/UI/ui.tscn").instantiate()
	add_child(ui)
	await get_tree().process_frame

	var container: HBoxContainer = ui.get_node("HBoxContainer")
	var coracoes: Array = container.get_children()
	_verificar(coracoes.size() == 10, "HUD inicia com 10 coracoes (recebeu %d)" % coracoes.size())
	_verificar(coracoes[9].modulate.is_equal_approx(ui.COR_PADRAO),
		"vida base cheia fica branca (recebeu %s)" % str(coracoes[9].modulate))

	var btn_limite := Button.new()
	ui.upgrades_atuais[btn_limite] = {"id": "mais_vida", "texto": "+5 VIDA MÁXIMA"}
	ui.aplicar_upgrade(btn_limite)
	_verificar(Global.MaxH == 15, "upgrade de limite sobe o teto para 15 (recebeu %d)" % Global.MaxH)
	_verificar(Global.Health == 10, "upgrade de limite nao da vida (recebeu %d)" % Global.Health)
	coracoes = container.get_children()
	_verificar(coracoes.size() == 15, "HUD passa a mostrar 15 slots (recebeu %d)" % coracoes.size())
	_verificar(coracoes[10].modulate.is_equal_approx(ui.COR_CIANO_DESATIVADO),
		"slot do limite extra vazio fica ciano acinzentado (recebeu %s)" % str(coracoes[10].modulate))

	var btn_cura := Button.new()
	ui.upgrades_atuais[btn_cura] = {"id": "curar", "texto": "+3 DE VIDA"}
	ui.aplicar_upgrade(btn_cura)
	_verificar(Global.Health == 13, "cura +3 com teto 15 vai a 13 (recebeu %d)" % Global.Health)
	_verificar(coracoes[12].modulate.is_equal_approx(ui.COR_CIANO),
		"vida extra cheia fica ciano normal (recebeu %s)" % str(coracoes[12].modulate))
	_verificar(coracoes[13].modulate.is_equal_approx(ui.COR_CIANO_DESATIVADO),
		"slot extra nao preenchido continua acinzentado (recebeu %s)" % str(coracoes[13].modulate))

	Global.Health -= 1
	_verificar(Global.Health == 12, "dano reduz para 12 (recebeu %d)" % Global.Health)
	_verificar(coracoes[11].modulate.is_equal_approx(ui.COR_CIANO),
		"extra ainda cheio permanece ciano (recebeu %s)" % str(coracoes[11].modulate))
	_verificar(coracoes[12].modulate.is_equal_approx(ui.COR_CIANO_DESATIVADO),
		"extra perdido volta a acinzentado (recebeu %s)" % str(coracoes[12].modulate))

	ui.aplicar_upgrade(btn_cura)
	_verificar(Global.Health == 15, "cura satura no teto 15 (recebeu %d)" % Global.Health)
	ui.aplicar_upgrade(btn_cura)
	_verificar(Global.Health == 15, "cura com vida cheia nao passa do limite (recebeu %d)" % Global.Health)
	_verificar(coracoes[14].modulate.is_equal_approx(ui.COR_CIANO),
		"ultimo slot extra cheio fica ciano (recebeu %s)" % str(coracoes[14].modulate))

	ui.queue_free()
	await get_tree().process_frame

func _testar_jogo() -> void:
	_resetar_run(15, 13)
	var jogo = load("res://Cenas/Jogo.tscn").instantiate()
	add_child(jogo)
	_verificar(Global.Health == 13, "passar de fase com 13 mantem 13 (recebeu %d)" % Global.Health)
	_verificar(Global.MaxH == 15, "teto de 15 persiste na fase nova (recebeu %d)" % Global.MaxH)

	Global.Health -= 1
	var jogo2 = load("res://Cenas/Jogo.tscn").instantiate()
	add_child(jogo2)
	_verificar(Global.Health == 12, "fase nova apos dano comeca com 12 (recebeu %d)" % Global.Health)

	var hud_ui: Control = jogo2.get_node("CanvasLayer/UI")
	var coracoes: Array = hud_ui.get_node("HBoxContainer").get_children()
	_verificar(coracoes.size() == 15, "HUD da fase mostra 15 slots (recebeu %d)" % coracoes.size())
	_verificar(coracoes[0].modulate.is_equal_approx(hud_ui.COR_PADRAO),
		"base cheia fica branca no HUD da fase (recebeu %s)" % str(coracoes[0].modulate))
	_verificar(coracoes[9].modulate.is_equal_approx(hud_ui.COR_PADRAO),
		"vida base 10/10 segue cheia no HUD da fase (recebeu %s)" % str(coracoes[9].modulate))
	_verificar(coracoes[10].modulate.is_equal_approx(hud_ui.COR_CIANO),
		"vida extra cheia continua ciano no HUD da fase (recebeu %s)" % str(coracoes[10].modulate))
	_verificar(coracoes[12].modulate.is_equal_approx(hud_ui.COR_CIANO_DESATIVADO),
		"limite extra vazio fica ciano acinzentado no HUD da fase (recebeu %s)" % str(coracoes[12].modulate))

	jogo.queue_free()
	jogo2.queue_free()
	await get_tree().process_frame

func _testar_morte() -> void:
	_resetar_run(15, 13)
	var ui = load("res://Objetos/UI/ui.tscn").instantiate()
	add_child(ui)
	await get_tree().process_frame

	ui.update_life(0)
	_verificar(Global.MaxH == 10, "morte reseta o teto para 10 (recebeu %d)" % Global.MaxH)
	_verificar(Global.Health == 10, "morte reseta a vida para 10 (recebeu %d)" % Global.Health)
	_verificar(SceneTransition.transitioning, "morte inicia a transicao de game over")
