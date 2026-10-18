extends Node

# Execute após importar o projeto:
# godot --headless --path . res://tests/regression.tscn
var failures: int = 0
var checks: int = 0
var game: Node

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func switch_to(path: String) -> void:
	SceneTransition.change_scene(path)
	await get_tree().create_timer(2.0).timeout
	game = get_tree().current_scene
	check(game.scene_file_path == path and not SceneTransition.transitioning, "transição para " + path)

func disable_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.set_physics_process(false)
		enemy.get_node("Push").set_deferred("monitoring", false)

func run() -> void:
	# Mantém o runner vivo enquanto as cenas reais são substituídas.
	get_parent().remove_child(self)
	(Engine.get_main_loop() as SceneTree).root.add_child(self)
	Global.current_seed = 123456
	await switch_to("res://Cenas/Jogo.tscn")
	disable_enemies()
	var ui = game.get_node("CanvasLayer/UI")
	Global.Health = 8
	ui.upgrades_atuais[ui.button] = {"id": "mais_vida", "valor": 5}
	ui.aplicar_upgrade(ui.button)
	ui.aplicar_upgrade(ui.button)
	check(Global.MaxH == 20, "duas melhorias acumulam vida máxima: 10 → 15 → 20")
	check(Global.Health == 8, "aumentar limite não concede cura")
	check(ui.container_coracoes.get_child_count() == 20, "HUD cria vinte corações")
	check(ui.container_coracoes.get_child(10).modulate == ui.COR_CIANO_DESATIVADO, "vida extra vazia aparece no HUD")
	Global.Health = 13
	var signals: Array = []
	var listener = func(value): signals.append(value)
	Global.New_Health.connect(listener)
	ui.upgrades_atuais[ui.button] = {"id": "curar", "valor": 3}
	ui.aplicar_upgrade(ui.button)
	check(Global.Health == 16, "cura acima de dez aumenta a vida")
	check(signals == [16], "cura emite um único sinal com a vida armazenada")
	check(ui.container_coracoes.get_child(15).modulate == ui.COR_CIANO, "HUD preenche os corações extras")
	Global.Health = 19
	ui.aplicar_upgrade(ui.button)
	check(Global.Health == 20, "cura respeita o máximo atual")
	Global.Health = 100
	check(Global.Health == 20 and signals.back() == 20, "sinal respeita o clamp superior")
	Global.New_Health.disconnect(listener)
	ui.upgrades_atuais[ui.button] = {"id": "velocidade", "valor": 10}
	ui.aplicar_upgrade(ui.button)
	check(is_equal_approx(Global.Speed, 330.0), "velocidade recebe dez por cento")
	ui.aplicar_upgrade(ui.button)
	check(is_equal_approx(Global.Speed, 363.0), "dez por cento acumula sobre a velocidade atual")

	# Abre uma escolha real e morre antes de selecionar.
	game.get_node("Player").position = Vector2(640 * game.grid_width + 5, 250)
	await get_tree().create_timer(0.15).timeout
	check(Global.levelup == 1 and ui.upgrades_atuais.size() == 3, "saída oferece melhorias")
	var saved_seed = Global.current_seed
	Global.Health = -5
	check(Global.Health == 0, "vida negativa é limitada a zero")
	await get_tree().create_timer(2.0).timeout
	game = get_tree().current_scene
	check(game.scene_file_path == "res://Cenas/game_over.tscn", "morte durante escolha abre Game Over")
	check(game.get_script().resource_path == "res://Scripts/UI/game_over.gd", "Game Over usa o script corrigido sem colisão de UID")
	game._on_retry_pressed()
	game._on_retry_pressed()
	await get_tree().create_timer(2.0).timeout
	game = get_tree().current_scene
	disable_enemies()
	check(Global.Health == 20 and Global.MaxH == 20, "Retry restaura vida sem perder o limite conquistado")
	check(Global.levelup == 0 and Global.current_seed == saved_seed, "Retry limpa escolha pendente e mantém seed")
	check(is_equal_approx(Global.Speed, 363.0), "Retry preserva melhorias de velocidade")
	game.get_node("Player").position = Vector2(640 * game.grid_width + 5, 250)
	await get_tree().create_timer(0.15).timeout
	ui = game.get_node("CanvasLayer/UI")
	check(Global.levelup == 1 and ui.upgrades_atuais.size() == 3, "saída oferece novas melhorias depois do Retry")
	ui.upgrades_atuais[ui.button] = {"id": "mais_dano", "valor": 2}
	var old_damage = Global.Damage
	ui.button.pressed.emit()
	await get_tree().create_timer(2.5).timeout
	game = get_tree().current_scene
	disable_enemies()
	check(Global.levelup == 0 and Global.Damage == old_damage + 2, "selecionar melhoria continua para a próxima rodada")

	for i in range(1, 7):
		game.chunk_scenes.clear()
		game.chunk_scenes.append(load("res://Chunks/chunk1-%d.tscn" % i))
		game.generate_map()
		disable_enemies()
		await get_tree().physics_frame
		game.get_node("Player").esta_invulneravel = true
		game.get_node("Player").position = Vector2(300, 1200)
		await get_tree().create_timer(2.0).timeout
		game = get_tree().current_scene
		check(game.scene_file_path == "res://Cenas/game_over.tscn", "queda no mapa %d abre Game Over" % i)
		check(Global.Health == 0, "queda é fatal independentemente da invulnerabilidade")
		game._on_retry_pressed()
		await get_tree().create_timer(2.0).timeout
		game = get_tree().current_scene
		disable_enemies()
		check(Global.Health == Global.MaxH and Global.levelup == 0, "Retry após queda recupera partida")

	# Morte → menu → PLAY também deve restaurar a vida.
	Global.Health = 0
	await get_tree().create_timer(2.0).timeout
	game = get_tree().current_scene
	game._on_menu_pressed()
	await get_tree().create_timer(2.0).timeout
	game = get_tree().current_scene
	game._on_play_pressed()
	await get_tree().create_timer(2.0).timeout
	check(Global.Health == Global.MaxH and Global.levelup == 0, "PLAY após morte e retorno ao menu recupera o estado")
	print("REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
