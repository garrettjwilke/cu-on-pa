extends Node

var FLOOR_BLANK = preload("res://scenes/3d/floor_blank.tscn")
var FLOOR_BLUE = preload("res://scenes/3d/floor_blue.tscn")
var FLOOR_RED = preload("res://scenes/3d/floor_red.tscn")
var FLOOR_GREEN = preload("res://scenes/3d/floor_green.tscn")
var FLOOR_YELLOW = preload("res://scenes/3d/floor_yellow.tscn")
var FLOOR_PURPLE = preload("res://scenes/3d/floor_purple.tscn")
var FLOOR_ORANGE = preload("res://scenes/3d/floor_orange.tscn")
var TILE_BLANK = preload("res://scenes/2d/tile_blank.tscn")
var TILE_BLUE = preload("res://scenes/2d/tile_blue.tscn")
var TILE_RED = preload("res://scenes/2d/tile_red.tscn")
var TILE_GREEN = preload("res://scenes/2d/tile_green.tscn")
var TILE_YELLOW = preload("res://scenes/2d/tile_yellow.tscn")
var TILE_PURPLE = preload("res://scenes/2d/tile_purple.tscn")
var TILE_ORANGE = preload("res://scenes/2d/tile_orange.tscn")
var TILE_SIZE = 32
var LEVEL = 0


# The position to start spawning tiles at
var x = 0
var y = 0

var LEVEL_MATRIX = []

var LEVEL_0 = [
	[0, 1, 2, 3],
	[4, 5, 6, 7],
	[0, 7, 6, 5],
	[4, 3, 2, 1],
]

var LEVEL_1 = [
	[1, 0, 0, 0, 0, 0],
	[1, 2, 3, 4, 5, 6],
	[6, 5, 4, 3, 2, 1],
	[1, 1 ,1, 1, 0, 0],
]

func tile_spawn_3d():
	var CURRENT_TILE
	match LEVEL_MATRIX[y][x]:
		0:
			return
		1:
			CURRENT_TILE = FLOOR_BLANK.instantiate()
		2:
			CURRENT_TILE = FLOOR_BLUE.instantiate()
		3:
			CURRENT_TILE = FLOOR_RED.instantiate()
		4:
			CURRENT_TILE = FLOOR_GREEN.instantiate()
		5:
			CURRENT_TILE = FLOOR_YELLOW.instantiate()
		6:
			CURRENT_TILE = FLOOR_PURPLE.instantiate()
		7:
			CURRENT_TILE = FLOOR_ORANGE.instantiate()
		_:
			return
	# add the tile if valid
	CURRENT_TILE.position = Vector3(x, -0.5, y)
	add_child(CURRENT_TILE)


# The function to loop through the FLOOR_MATRIX and spawn tiles
func update_level(NEW_MATRIX):
	LEVEL_MATRIX = NEW_MATRIX
	for row in LEVEL_MATRIX:
		for cell in row:
			tile_spawn_3d()
			x += 1
		x = 0
		y += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
