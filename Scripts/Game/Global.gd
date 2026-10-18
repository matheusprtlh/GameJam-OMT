extends Node

func _ready() -> void:
	comecar.connect(song)

signal New_Health(valor)
signal New_Level(valor)
signal comecar(valor)

# vida extra persiste entre fases; morte reinicia vida e limite.
const VIDA_BASE_MAXIMA: int = 10

# declare maxh antes de health: o setter depende dessa ordem.
var MaxH: int = VIDA_BASE_MAXIMA
var tempo_decorrido: float = 0.0
var Health: int = VIDA_BASE_MAXIMA:
	set(valor):
		Health = clampi(valor, 0, MaxH)
		New_Health.emit(Health)
var levelup = 0:
	set(valor):
		levelup = valor
		New_Level.emit(valor)
var comecou =  false:
	set(valor):
		comecou = valor
		comecar.emit(valor)
var current_seed = 0
var Speed = 300
var Damage = 1
var passoudefase: int
var sombras = 0
var vitorias: int = 0

func song(valor):
	if valor == true:
		var audio_player = AudioStreamPlayer.new()
	
		var som = load("res://Sons/Musicas/Game Music.mp3")
		audio_player.stream = som
		
		add_child(audio_player)
		
		audio_player.play()
		
