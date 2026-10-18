extends Node

signal New_Health(valor)
signal New_Level(valor)

var Health: int = 10:
	set(valor):
		Health = clampi(valor, 0, MaxH)
		New_Health.emit(Health)
var levelup = 0:
	set(valor):
		levelup = valor
		New_Level.emit(valor)
var current_seed = 0
# Para PowerUPS
var MaxH = 10
var Speed: float = 300.0
var Damage = 1


# Uma nova tentativa mantém o mapa e as melhorias já conquistadas.
func prepare_retry() -> void:
	levelup = 0
	Health = MaxH
