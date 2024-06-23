extends Node

var DEBUG = false
# setting DEBUG_SEVERITY can help isolate debug messages
#   setting to 0 will show all debug messages
var DEBUG_SEVERITY = 0
var START_POSITION = Vector2(0,0)

var MODE_EXCLUSIVE = "false"

var DYNAMIC_CAM = "true"

# when calling debug message, you need to set a severity
# if the DEBUG_SEVERITY is set to 0, it will display all debug messages
func debug_message(INFO, MESSAGE, SEVERITY):
	if DEBUG == true:
		# severity 0 shows all messages regardless of passed through severity
		var ORIGINAL_SEVERITY = DEBUG_SEVERITY
		if DEBUG_SEVERITY == 0:
			DEBUG_SEVERITY = SEVERITY
		if DEBUG_SEVERITY == SEVERITY:
			print("DEBUG_SEVERITY: ", SEVERITY, " | ", INFO)
			print(MESSAGE)
		DEBUG_SEVERITY = ORIGINAL_SEVERITY

# set the tile size for the 2d tiles
var TILE_SIZE_2D = get_default("TILE_SIZE_2D")

# this will get set with the level data later
var LEVEL_MATRIX = []
# other parts of the game need to know the dimensions of the level. this is added up as we spawn tiles
var LEVEL_RESOLUTION = Vector2(0,0)
# every time a tile is spawned, this NODE_COUNTER goes up
var NODE_COUNTER = 0

# round number up/down
func round_to_dec(num):
	return round(num * pow(10.0, 0)) / pow(10.0, 0)

# get the position of the cube
var CUBE_POSITION = Vector2()
func update_cube_position(position):
	CUBE_POSITION = position
	debug_message("hmls.gd - update_cube_position()", CUBE_POSITION, 1)

func floor_check(pos_x, pos_y):
	var NODE_NAME = str(pos_x,"x",pos_y)
	var NEXT_COLOR
	for node in get_node("/root/hmls/VIEW_3D").get_children():
		if not get_node_or_null(str("/root/hmls/VIEW_3D/",NODE_NAME)):
			debug_message("hmls.gd - floor_check() - couldn't find node",str("/root/hmls/VIEW_3D/",NODE_NAME),2)
			return "stop"
	# if cube passes check, get the color of the next tile it is rolling into
	NEXT_COLOR = LEVEL_MATRIX[pos_y][pos_x]
	# if the next color is a 00 (ZZ) then stop
	#if str(NEXT_COLOR) == "ZZ":
	#	return "stop"
	return NEXT_COLOR

# to transfer the 3d level to 2d, we keep track of the CURRENT_LEVEL
var CURRENT_LEVEL = []
func reset_current_level():
	debug_message("hmls.reset_current_level()", "", 1)
	CURRENT_LEVEL = []

# pass a string through the get_default() function and get the default from data/defaults.json
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
		"GAME_DIFFICULTY":
			return DEFAULTS.GAME_DIFFICULTY
		"LEVEL_MATRIX":
			return DEFAULTS.LEVEL_MATRIX
		"COLOR_GRAY":
			return DEFAULTS.COLOR_GRAY
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

# you can control the outcome of the RNG with a seed
var RNG_SEED = get_default("RNG_SEED")
var RNG_COUNTER = 0
func update_rng_seed(new_seed):
	RNG_SEED = new_seed
	RNG_COUNTER = 0

func rng(MIN, MAX):
	RNG_COUNTER += 1
	var number = RandomNumberGenerator.new()
	# combine the RNG number with the seed and you get a new_seed unique from the rest
	# if we skip this, we run into a chance where the RNG produces the same result and the game breaks
	var new_seed = str(RNG_SEED, str(RNG_COUNTER)).hash()
	number.randomize()
	number.set_seed(new_seed)
	number = number.randi_range(MIN, MAX)
	return number

# keep track of all the nodes that are spawned
var mesh_spawn_names = []
func update_mesh_spawn_names(mesh_name):
	if mesh_name == "!!delete":
		mesh_spawn_names = []
	else:
		mesh_spawn_names.append(mesh_name)

# starting level
var LEVEL = 0
func update_level():
	LEVEL += 1
	CURRENT_LEVEL = []
	START_POSITION = Vector2(0,0)
	debug_message("hmls.update_level()", str("level = ", LEVEL), 1)

# this will return COLOR and NAME
func get_cell_data(cell):
	# wonky things happen if you input a number that isn't double digits
	# so i check if the cell data is exactly 2 digits and work from there
	var CHARACTER_COUNT = 0
	# add 1 to the character count for every character in the current cell
	for character in str(cell):
		CHARACTER_COUNT += 1
	
	# if the character count is less than or greater than 2, skip it by setting a 00
	if not CHARACTER_COUNT == 2:
		cell = 00
	var COLOR
	var NAME
	var NEW_CELL = cell
	var ATTRIBUTE
	# the json file has numbers that represent the colors/attributes listed here
	# placing the sequence [1,2,3,4] will output the following colors:
	# # gray, blue, red, green
	match str(cell).left(1):
		"0":
			COLOR = "null"
			NAME = "null"
		"1":
			COLOR = get_default("COLOR_GRAY")
			NAME = "gray"
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
			# when RNG is set, we need a way to keep track of what the new tile color is
			# so we get a random tile, and set the properties back in the level matrix
			var NEW_DATA = get_cell_data(rng(1,7))
			COLOR = NEW_DATA[0]
			NAME = NEW_DATA[1]
			NEW_CELL = NEW_DATA[2]
		_:
			COLOR = "null"
			NAME = "null"
	# set attributes to tiles from 2nd number in cell
	match str(cell).right(1):
		"0":
			ATTRIBUTE = "default"
		"1":
			ATTRIBUTE = "bomb"
		"2":
			ATTRIBUTE = "lightning"
		"3":
			ATTRIBUTE = "box"
		"7":
			ATTRIBUTE = "unspawnable"
		"8":
			ATTRIBUTE = "camera_switch"
		"9":
			ATTRIBUTE = "start_position"
		_:
			ATTRIBUTE = "null"
	return [COLOR, NAME, NEW_CELL, ATTRIBUTE]

# this will spawn after the update_tiles() is ran
func tile_spawn(x, y, MODE, cell):
	# the get_cell_data() returns an array with html color codes and attributes
	var CELL_DATA = get_cell_data(cell)
	var COLOR = CELL_DATA[0]
	var ATTRIBUTE = CELL_DATA[3]
	if ATTRIBUTE == "start_position":
		print("wtf")
		START_POSITION = Vector2(x,y)
	if COLOR == "null":
		return
	# add the tile if valid
	NODE_COUNTER += 1
	var CURRENT_TILE
	if MODE == "3d":
		if MODE_EXCLUSIVE == "2d":
			return
		# create a VIEW_3D node to attach all 3d nodes to
		if not get_node_or_null("/root/hmls/VIEW_3D"):
			var NODE_3D = Node3D.new()
			NODE_3D.name = str("VIEW_3D")
			get_node("/root/hmls").add_child(NODE_3D)
			hmls.update_mesh_spawn_names(NODE_3D.name)
		CURRENT_TILE = MeshInstance3D.new()
		CURRENT_TILE.mesh = BoxMesh.new()
		var material = StandardMaterial3D.new()
		material.albedo_color = COLOR
		CURRENT_TILE.mesh.surface_set_material(0, material)
		
		var TILE_GAP_SIZE = 0.85
		var TILE_HEIGHT = 0.1
		CURRENT_TILE.scale = Vector3(TILE_GAP_SIZE, TILE_HEIGHT, TILE_GAP_SIZE)
		CURRENT_TILE.position = Vector3(x, -(TILE_HEIGHT / 2 + 0.03), y)
		var COLLISION = CollisionShape3D.new()
		COLLISION.shape = BoxShape3D.new()
		COLLISION.name = str(x,"x",y,"_collision")
		CURRENT_TILE.add_child(COLLISION)
		get_node("/root/hmls/VIEW_3D").add_child(CURRENT_TILE)
	if MODE == "2d":
		if MODE_EXCLUSIVE == "3d":
			return
		if not get_node_or_null("/root/hmls/VIEW_2D"):
			var NODE_2D = Node2D.new()
			NODE_2D.name = str("VIEW_2D")
			get_node("/root/hmls").add_child(NODE_2D)
			hmls.update_mesh_spawn_names(NODE_2D.name)
		CURRENT_TILE = ColorRect.new()
		CURRENT_TILE.name = str(x,"x",y)
		CURRENT_TILE.size = Vector2(TILE_SIZE_2D - 1, TILE_SIZE_2D - 1)
		CURRENT_TILE.position = Vector2(x * TILE_SIZE_2D + 3, y * TILE_SIZE_2D + 3)
		CURRENT_TILE.color = COLOR
		get_node("/root/hmls/VIEW_2D").add_child(CURRENT_TILE)
		
	# WARNING: changing the CURRENT_TILE.name var will break floor_check() function
	CURRENT_TILE.name = str(x,"x",y)
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
		remove_child(get_node_or_null("/root/hmls/VIEW_2D"))
		remove_child(get_node_or_null("/root/hmls/VIEW_3D"))
		update_mesh_spawn_names("!!delete")
		# set CURRENT_LEVEL to empty and fill it with 3d, then 2d
		CURRENT_LEVEL = []
		update_tiles("3d")
		update_tiles("2d")
	else:
		# if the CURRENT_LEVEL is not empty, set last LEVEL_MATRIX
		# this is so that when we draw the 2d tiles, none of the RNG is re-generated
		if CURRENT_LEVEL != []:
			LEVEL_MATRIX = CURRENT_LEVEL
			#LEVEL_HEIGHT = 0
			#LEVEL_WIDTH = 0
			LEVEL_RESOLUTION = Vector2(0,0)
		# spawn individual tiles
		var x = 0
		var y = 0
		for row in LEVEL_MATRIX:
			for cell in row:
				# check if level has RNG values set
				var NEW_CELL = int(cell)
				if str(NEW_CELL) == "9":
					START_POSITION = Vector2(x,y)
					NEW_CELL = int(00)
					LEVEL_MATRIX[y][x] = NEW_CELL
				if int(str(cell).left(1)) == 8:
					# if level has RNG values set, change the cell to the new RNG value
					NEW_CELL = int(str(rng(1, 7),str(cell).right(1)))
					# set the NEW_CELL value to the LEVEL_MATRIX
					LEVEL_MATRIX[y][x] = int(str(NEW_CELL))
				# set CURRENT_LEVEL so that when 2d level is spawned, the RNG stays the same
				CURRENT_LEVEL = LEVEL_MATRIX
				tile_spawn(x, y, MODE, NEW_CELL)
				# increment x so the next cell will be read correctly
				x += 1
				if x > LEVEL_RESOLUTION.x:
					LEVEL_RESOLUTION.x += 1
				#if x > LEVEL_WIDTH:
				#	LEVEL_WIDTH += 1
			# set x back to 0 and increment y to read the next row
			x = 0
			y += 1
			if y > LEVEL_RESOLUTION.y:
				LEVEL_RESOLUTION.y += 1
		# reset the node counter so when 2d draws, the nodes start at 1
		NODE_COUNTER = 0

func _ready():
	DisplayServer.window_set_title(get_default("WINDOW_TITLE"))
	DisplayServer.window_set_size(get_default("RESOLUTION"))
	update_level()

