extends Button

@onready var texto: RichTextLabel = get_parent()

var texto_original: String

func _ready() -> void:
	texto_original = texto.text

	mouse_entered.connect(_mouse_entrou)
	mouse_exited.connect(_mouse_saiu)

func _mouse_entrou() -> void:
	texto.text = "[shake rate=30.0 level=5.0 connected=1]%s[/shake]" % texto_original

func _mouse_saiu() -> void:
	texto.text = texto_original
