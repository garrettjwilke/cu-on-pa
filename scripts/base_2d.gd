extends Node2D

var LEVEL_MATRIX = hmls.LEVEL_1

func _ready():
	hmls.update_tiles(LEVEL_MATRIX, 0, 0, "2d")
