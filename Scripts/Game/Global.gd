extends Node

signal New_Health(valor)
signal New_Level(valor)

var Health = 10:
	set(valor):
		Health = clamp(valor, 0, MaxH)
		New_Health.emit(valor)
var levelup = 0:
	set(valor):
		levelup = valor
		New_Level.emit(valor)
var current_seed = 0
# Para PowerUPS
var MaxH = 10
var Speed = 300
var Damage = 1
