extends Node2D

var LEVEL_MATRIX = hmls.LEVEL_1
var x = 0
var y = 0
var TILE_SIZE = 32

func tile_spawn_2d():
	var CURRENT_TILE
	match LEVEL_MATRIX[y][x]:
		0:
			return
		1:
			CURRENT_TILE = hmls.TILE_BLANK.instantiate()
		2:
			CURRENT_TILE = hmls.TILE_BLUE.instantiate()
		3:
			CURRENT_TILE = hmls.TILE_RED.instantiate()
		4:
			CURRENT_TILE = hmls.TILE_GREEN.instantiate()
		5:
			CURRENT_TILE = hmls.TILE_YELLOW.instantiate()
		6:
			CURRENT_TILE = hmls.TILE_PURPLE.instantiate()
		7:
			CURRENT_TILE = hmls.TILE_ORANGE.instantiate()
		_:
			return
	# add the tile if valid
	CURRENT_TILE.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(CURRENT_TILE)

func _ready():
	for row in LEVEL_MATRIX:
		for cell in row:
			tile_spawn_2d()
			x += 1
		x = 0
		y += 1
