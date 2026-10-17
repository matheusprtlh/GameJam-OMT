extends Node

signal New_Health(valor)

var Health = 10:
	set(valor):
		Health = valor
		New_Health.emit(valor)
