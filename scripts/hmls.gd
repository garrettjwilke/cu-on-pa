extends Node

# set colors
var COLOR_BLANK = "#9B9B9B"
var COLOR_BLUE = "#163ee2"
var COLOR_RED = "#e21616"
var COLOR_GREEN = "#38e216"
var COLOR_YELLOW = "#f5f10b"
var COLOR_PURPLE = "#db25ee"
var COLOR_ORANGE = "#fea500"

# set the tile size for the 2d tiles
var TILE_SIZE_2D = 16

# this will get set with the level data later
var LEVEL_MATRIX = []
# every time a tile is spawned, this NODE_COUNTER goes up
var NODE_COUNTER = 0

# to transfer the 3d level to 2d, we keep track of the CURRENT_LEVEL
var CURRENT_LEVEL = []
func reset_current_level():
	CURRENT_LEVEL = []

# the 'new_rng_number' is created every time the 'rng()' function is run
var new_rng_number = 0
var rng_seed = "hmls test"
func update_rng_seed(new_seed):
	rng_seed = new_seed

# keep track of all the nodes that are spawned
var mesh_spawn_names = []
func update_mesh_spawn_names(mesh_name):
	if mesh_name == "!!delete":
		mesh_spawn_names = []
	else:
		mesh_spawn_names.append(mesh_name)

# RNG number generator
func rng(MIN, MAX):
	new_rng_number += 1
	var number = RandomNumberGenerator.new()
	var new_seed = str(rng_seed + str(new_rng_number)).hash()
	number.randomize()
	number.set_seed(new_seed)
	number = number.randi_range(MIN, MAX)
	return number

# if there is no level to load, it will load this
func default_level():
	var LEVEL_DEFAULT = [
		[rng(1,7),rng(1,7),rng(1,7),rng(1,7)],
		[4,5,6,7],
		[0,7,6,5],
		[4,3,2,1],
		[0,0,0,0],
		[rng(2,7),rng(2,7),rng(2,7),rng(2,7),rng(2,7)],
		[0,0,rng(2,7),0,0],
		[0,0,rng(2,7),0,0],
		[0,0,rng(2,7),0,0],
		[0,0,rng(2,7),0,0],
	]
	return LEVEL_DEFAULT

# starting level
var LEVEL = 0
func update_level():
	LEVEL += 1

# this will return COLOR and NAME
func get_color(cell):
	var COLOR
	var NAME
	var NEW_CELL = cell
	match str(cell):
		"0":
			COLOR = "null"
			NAME = "null"
		"1":
			COLOR = COLOR_BLANK
			NAME = "blank"
		"2":
			COLOR = COLOR_BLUE
			NAME = "blue"
		"3":
			COLOR = COLOR_RED
			NAME = "red"
		"4":
			COLOR = COLOR_GREEN
			NAME = "green"
		"5":
			COLOR = COLOR_YELLOW
			NAME = "yellow"
		"6":
			COLOR = COLOR_PURPLE
			NAME = "purple"
		"7":
			COLOR = COLOR_ORANGE
			NAME = "orange"
		"8":
			NEW_CELL = rng(1,7)
			COLOR = get_color(NEW_CELL)[0]
			NAME = "rng"
		_:
			COLOR = "null"
			NAME = "null"
	return [COLOR, NAME, NEW_CELL]

# this will spawn after the update_tiles() is ran
func tile_spawn(x, y, MODE, cell):
	var CURRENT_TILE
	var DATA = get_color(cell)
	var COLOR = DATA[0]
	# if the cell is set to RNG, then set the LEVEL_MATRIX to the new RNG number
	if cell == 8:
		LEVEL_MATRIX[y][x] = DATA[2]
	# set the NAME based on the get_color function
	var NAME = DATA[1]
	# set the CURRENT_LEVEL so the 2d view can update later
	CURRENT_LEVEL = LEVEL_MATRIX
	if COLOR == "null":
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
		CURRENT_TILE.size = Vector2(TILE_SIZE_2D, TILE_SIZE_2D)
		CURRENT_TILE.position = Vector2(x * TILE_SIZE_2D, y * TILE_SIZE_2D)
		CURRENT_TILE.color = COLOR
	CURRENT_TILE.name = str(MODE, "_", NAME, "_", NODE_COUNTER)
	add_child(CURRENT_TILE)
	update_mesh_spawn_names(CURRENT_TILE.name)

# this is the first function to run to spawn tiles
func update_tiles(MODE):
	var x = 0
	var y = 0
	# check if the level exists and load it as LEVEL_MATRIX
	var LEVEL_STRING = str("res://levels/LEVEL_", LEVEL, ".json")
	if not FileAccess.file_exists(LEVEL_STRING):
		LEVEL_MATRIX = default_level()
		LEVEL = 0
	else:
		var file = FileAccess.open(LEVEL_STRING, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data.has("data"):
			LEVEL_MATRIX = data.data
	# if reset, then delete all nodes and update_tiles for 3d and 2d
	if MODE == "reset":
		for i in mesh_spawn_names:
			remove_child(get_node(str(i)))
		update_mesh_spawn_names("!!delete")
		CURRENT_LEVEL = []
		update_tiles("2d")
		update_tiles("3d")
	else:
		# if the CURRENT_LEVEL is not empty, set last LEVEL_MATRIX
		if CURRENT_LEVEL != []:
			LEVEL_MATRIX = CURRENT_LEVEL
			# set CURRENT_LEVEL to empty
			CURRENT_LEVEL = []
		# spawn individual tiles
		for row in LEVEL_MATRIX:
			for cell in row:
				tile_spawn(x, y, MODE, cell)
				x += 1
			x = 0
			y += 1
		NODE_COUNTER = 0

func _ready():
	update_level()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
