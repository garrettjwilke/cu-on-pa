extends Node

var COLOR_BLANK = "#9B9B9B"
var COLOR_BLUE = "#163ee2"
var COLOR_RED = "#e21616"
var COLOR_GREEN = "#38e216"
var COLOR_YELLOW = "#f5f10b"
var COLOR_PURPLE = "#db25ee"
var COLOR_ORANGE = "#fea500"
var TILE_SIZE = 16

var NODE_COUNTER = 0

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

func tile_spawn(LEVEL_MATRIX, x, y, MODE):
	var CURRENT_TILE
	var COLOR
	var NAME
	match LEVEL_MATRIX[y][x]:
		0:
			return
		1:
			COLOR = COLOR_BLANK
			NAME = "blank"
		2:
			COLOR = COLOR_BLUE
			NAME = "blue"
		3:
			COLOR = COLOR_RED
			NAME = "red"
		4:
			COLOR = COLOR_GREEN
			NAME = "green"
		5:
			COLOR = COLOR_YELLOW
			NAME = "yellow"
		6:
			COLOR = COLOR_PURPLE
			NAME = "purple"
		7:
			COLOR = COLOR_ORANGE
			NAME = "orange"
		_:
			return
	# add the tile if valid
	NODE_COUNTER += 1
	if MODE == "3d":
		CURRENT_TILE = MeshInstance3D.new()
		CURRENT_TILE.mesh = BoxMesh.new()
		var material = StandardMaterial3D.new()
		material.albedo_color = COLOR
		CURRENT_TILE.mesh.surface_set_material(0, material)
		CURRENT_TILE.position = Vector3(x, -0.5, y)
	if MODE == "2d":
		CURRENT_TILE = ColorRect.new()
		CURRENT_TILE.size = Vector2(TILE_SIZE, TILE_SIZE)
		CURRENT_TILE.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		CURRENT_TILE.color = COLOR
	CURRENT_TILE.name = str(MODE, "_", NAME, "_", NODE_COUNTER)
	self.add_child(CURRENT_TILE)

func update_tiles(LEVEL_MATRIX, x, y, MODE):
	for row in LEVEL_MATRIX:
		for cell in row:
			tile_spawn(LEVEL_MATRIX, x, y, MODE)
			x += 1
		x = 0
		y += 1
	NODE_COUNTER = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
