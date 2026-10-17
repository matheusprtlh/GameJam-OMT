extends Control

@onready var timer_label: Label = $TimerLabel
@onready var button: Button = $Button
@onready var button_2: Button = $Button2
@onready var button_3: Button = $Button3

var tempo_decorrido: float = 0.0
var rodando: bool = true

const OPACIDADE_PADRAO: float = 0.4
const OPACIDADE_HOVER: float = 1.0

func _ready() -> void:
	var botoes: Array[Button] = [button, button_2, button_3]
	
	for btn in botoes:
		# Duplica o material para que o hover de um botão não afete os outros
		if btn.material:
			btn.material = btn.material.duplicate()
			btn.material.set_shader_parameter("hover_alpha", OPACIDADE_PADRAO)
		
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
		
	var tween = create_tween()
	# Anima o primeiro botão
	tween.tween_property(button_2, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	tween = create_tween()
	tween.tween_property(button, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(0.2).timeout
	tween = create_tween()
	tween.tween_property(button_3, "global_position:x", 320, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _on_button_mouse_entered(btn: Button) -> void:
	# Transição com animação suave (Tween)
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
