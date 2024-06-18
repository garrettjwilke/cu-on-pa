extends Node

var DEBUG = true

var RESOLUTION = get_default("RESOLUTION")

func debug_message(TYPE, MESSAGE):
	if DEBUG == true:
		print(TYPE)
		print(MESSAGE)

# set the tile size for the 2d tiles
var TILE_SIZE_2D = get_default("TILE_SIZE_2D")

# this will get set with the level data later
var LEVEL_MATRIX = []
# every time a tile is spawned, this NODE_COUNTER goes up
var NODE_COUNTER = 0

var CUBE_POSITION = Vector2()
func update_cube_position(position):
	CUBE_POSITION = position
	debug_message("",str("cube position: ", CUBE_POSITION.x, " ", CUBE_POSITION.y))

# to transfer the 3d level to 2d, we keep track of the CURRENT_LEVEL
var CURRENT_LEVEL = []
func reset_current_level():
	debug_message("hmls.reset_current_level()", "")
	CURRENT_LEVEL = []

func get_default(setting):
	var file = FileAccess.open("res://data/defaults.json", FileAccess.READ)
	var DEFAULTS = JSON.parse_string(file.get_as_text())
	match setting:
		"WINDOW_TITLE":
			return DEFAULTS.WINDOW_TITLE
		"RNG_SEED":
			return DEFAULTS.RNG_SEED
		"TILE_SIZE_2D":
			return DEFAULTS.TILE_SIZE_2D
		"RESOLUTION":
			return Vector2(DEFAULTS.RESOLUTION[0], DEFAULTS.RESOLUTION[1])
		"LEVEL_MATRIX":
			return DEFAULTS.LEVEL_MATRIX
		"COLOR_BLANK":
			return DEFAULTS.COLOR_BLANK
		"COLOR_BLUE":
			return DEFAULTS.COLOR_BLUE
		"COLOR_GREEN":
			return DEFAULTS.COLOR_GREEN
		"COLOR_ORANGE":
			return DEFAULTS.COLOR_ORANGE
		"COLOR_PURPLE":
			return DEFAULTS.COLOR_PURPLE
		"COLOR_RED":
			return DEFAULTS.COLOR_RED
		"COLOR_YELLOW":
			return DEFAULTS.COLOR_YELLOW

# the 'new_rng_number' is created every time the 'rng()' function is run
var new_rng_number = 0
var RNG_SEED = get_default("RNG_SEED")
func update_rng_seed(new_seed):
	RNG_SEED = new_seed

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
	var new_seed = str(RNG_SEED + str(new_rng_number)).hash()
	number.randomize()
	number.set_seed(new_seed)
	number = number.randi_range(MIN, MAX)
	return number

# starting level
var LEVEL = 0
func update_level():
	LEVEL += 1
	debug_message("hmls.update_level()", str("level = ", LEVEL))

# this will return COLOR and NAME
func get_color(cell):
	var COLOR
	var NAME
	var NEW_CELL = cell
	var ATTRIBUTE
	# the json file has numbers that represent the colors/attributes listed here
	# placing the sequence [1,2,3,4] will output the following colors:
	# # blank(gray), blue, red, green
	match str(cell).left(1):
		"0":
			COLOR = "null"
			NAME = "null"
		"1":
			COLOR = get_default("COLOR_BLANK")
			NAME = "blank"
		"2":
			COLOR = get_default("COLOR_RED")
			NAME = "red"
		"3":
			COLOR = get_default("COLOR_GREEN")
			NAME = "green"
		"4":
			COLOR = get_default("COLOR_BLUE")
			NAME = "blue"
		"5":
			COLOR = get_default("COLOR_YELLOW")
			NAME = "yellow"
		"6":
			COLOR = get_default("COLOR_PURPLE")
			NAME = "purple"
		"7":
			COLOR = get_default("COLOR_ORANGE")
			NAME = "orange"
		"8":
			var NEW_DATA = get_color(rng(1,7))
			NEW_CELL = NEW_DATA[2]
			COLOR = NEW_DATA[0]
			NAME = NEW_DATA[1]
		"hmls.hello":
			debug_message("get_color() - hmls.hello","hello")
			COLOR = "null"
			NAME = "null"
		_:
			COLOR = "null"
			NAME = "null"
	# set attributes to tiles from 2nd number in cell
	match str(cell).right(1):
		"0":
			ATTRIBUTE = "regular"
		"1":
			ATTRIBUTE = "bomb"
	return [COLOR, NAME, NEW_CELL, ATTRIBUTE]

# this will spawn after the update_tiles() is ran
func tile_spawn(x, y, MODE, cell):
	# get_color() returns an array with html color codes and attributes
	var CELL_DATA = get_color(cell)
	var COLOR = CELL_DATA[0]
	# if the cell is set to RNG, then set the LEVEL_MATRIX to the new RNG number
	# it gets the left number (which is the color)
	if int(str(cell).left(1)) == 8:
		# it sets the new number from the rng, but sets the old number on the right (which is the attribute)
		LEVEL_MATRIX[y][x] = int(str(CELL_DATA[2],str(cell).right(1)))
	# set the NAME based on the get_color function
	var NAME = CELL_DATA[1]
	var ATTRIBUTE = CELL_DATA[3]
	# set the CURRENT_LEVEL so the 2d view can update later
	CURRENT_LEVEL = LEVEL_MATRIX
	if COLOR == "null":
		return
	# add the tile if valid
	NODE_COUNTER += 1
	var CURRENT_TILE
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
	CURRENT_TILE.name = str(x,"x",y,"_",NAME, "_", NODE_COUNTER)
	add_child(CURRENT_TILE)
	update_mesh_spawn_names(CURRENT_TILE.name)

# this is the first function to run to spawn tiles
func update_tiles(MODE):
	# check if the level exists and load it as LEVEL_MATRIX
	var LEVEL_STRING = str("res://levels/LEVEL_", LEVEL, ".json")
	if not FileAccess.file_exists(LEVEL_STRING):
		LEVEL_MATRIX = get_default("LEVEL_MATRIX")
		TILE_SIZE_2D = get_default("TILE_SIZE_2D")
		LEVEL = 0
	else:
		var file = FileAccess.open(LEVEL_STRING, FileAccess.READ)
		var level_data = JSON.parse_string(file.get_as_text())
		# check if the level json has TILE_SIZE_2D
		if level_data.has("TILE_SIZE_2D"):
			TILE_SIZE_2D = level_data.TILE_SIZE_2D
		else:
			TILE_SIZE_2D = get_default("TILE_SIZE_2D")
		# check if level json even has level data
		if level_data.has("LEVEL_MATRIX"):
			LEVEL_MATRIX = level_data.LEVEL_MATRIX
		else:
			LEVEL_MATRIX = get_default("LEVEL_MATRIX")
	# if reset, then delete all nodes and update_tiles for 3d and 2d
	if MODE == "reset":
		for i in mesh_spawn_names:
			remove_child(get_node(str(i)))
		update_mesh_spawn_names("!!delete")
		# set CURRENT_LEVEL to empty and fill it with 2d, then 3d
		CURRENT_LEVEL = []
		update_tiles("3d")
		update_tiles("2d")
	else:
		# if the CURRENT_LEVEL is not empty, set last LEVEL_MATRIX
		# this is so that when we draw the 2d tiles, none of the RNG is re-generated
		if CURRENT_LEVEL != []:
			LEVEL_MATRIX = CURRENT_LEVEL
			debug_message("current level", CURRENT_LEVEL)
		# spawn individual tiles
		var x = 0
		var y = 0
		for row in LEVEL_MATRIX:
			for cell in row:
				tile_spawn(x, y, MODE, cell)
				# increment x so the next cell will be read correctly
				x += 1
			# set x back to 0 and increment y to read the next row
			x = 0
			y += 1
		# reset the node counter so when 2d draws, the nodes start at 1
		NODE_COUNTER = 0

func _ready():
	DisplayServer.window_set_title(get_default("WINDOW_TITLE"))
	DisplayServer.window_set_size(RESOLUTION)
	update_level()

