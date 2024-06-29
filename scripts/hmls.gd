extends Node

var DEBUG = false
# setting DEBUG_SEVERITY can help isolate debug messages
#   setting to 0 will show all debug messages
var DEBUG_SEVERITY = 0
var START_POSITION = Vector2(0,0)

var DYNAMIC_CAM = "true"

var BOX_MESH = preload("res://scenes/3d/block_3d.tscn")

var KEY_COUNT = 0

var KEY_BLANK = 0
var KEY_RED = 0
var KEY_GREEN = 0
var KEY_BLUE = 0
var KEY_YELLOW = 0
var KEY_PURPLE = 0
var KEY_ORANGE = 0
func reset_keys():
	KEY_COUNT = 0
	KEY_BLANK = 0
	KEY_RED = 0
	KEY_GREEN = 0
	KEY_BLUE = 0
	KEY_YELLOW = 0
	KEY_PURPLE = 0
	KEY_ORANGE = 0

# this is set after the level matrix has been loaded
var CURRENT_LEVEL = []

var ENABLE_JANK = false

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


# this will get set with the level data later
var LEVEL_MATRIX = []
# other parts of the game need to know the dimensions of the level. this is added up as we spawn tiles
var LEVEL_RESOLUTION = Vector2(0,0)
# every time a tile is spawned, this NODE_COUNTER goes up
#var NODE_COUNTER = 0

# round number up/down
func round_to_dec(num):
	return round(num * pow(10.0, 0)) / pow(10.0, 0)

# round vector3
func round_vect3(data):
	data.x = round(data.x * pow(10.0,0))
	data.y = round(data.y * pow(10.0,0))
	data.z = round(data.z * pow(10.0,0))
	return data

# get the position of the cube
var CUBE_POSITION = Vector2()
func update_cube_position(position):
	CUBE_POSITION = position

func floor_check(pos_x, pos_y):
	var NODE_NAME = str(pos_x,"x",pos_y)
	var NEXT_COLOR
	for node in get_node("/root/hmls/VIEW_3D").get_children():
		if not get_node_or_null(str("/root/hmls/VIEW_3D/",NODE_NAME)):
			debug_message("hmls.gd - floor_check() - couldn't find node",str("/root/hmls/VIEW_3D/",NODE_NAME),2)
			return "stop"
	# if cube passes check, get the color of the next tile it is rolling into
	NEXT_COLOR = LEVEL_MATRIX[pos_y][pos_x]
	#print(NEXT_COLOR)
	# if the next color is a 00 (ZZ) then stop
	#if str(NEXT_COLOR) == "ZZ":
	#	return "stop"
	return NEXT_COLOR

# pass a string through the get_default() function and get the default from data/defaults.json
func get_default(setting):
	var file = FileAccess.open("res://data/defaults.json", FileAccess.READ)
	var DEFAULTS = JSON.parse_string(file.get_as_text())
	match setting:
		"WINDOW_TITLE":
			return DEFAULTS.WINDOW_TITLE
		"RNG_SEED":
			return DEFAULTS.RNG_SEED
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
		"COLOR_BLACK":
			return DEFAULTS.COLOR_BLACK
		"GAME_MODE":
			return DEFAULTS.GAME_MODE

var GAME_MODE = get_default("GAME_MODE")

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

# starting level
var LEVEL = 0
func update_level(amount):
	LEVEL += amount
	#CURRENT_LEVEL = []
	START_POSITION = Vector2(0,0)
	KEY_COUNT = 0
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
	match int(str(cell).left(1)):
		0:
			COLOR = "null"
			NAME = "null"
		1:
			COLOR = get_default("COLOR_GRAY")
			NAME = "gray"
		2:
			COLOR = get_default("COLOR_RED")
			NAME = "red"
		3:
			COLOR = get_default("COLOR_GREEN")
			NAME = "green"
		4:
			COLOR = get_default("COLOR_BLUE")
			NAME = "blue"
		5:
			COLOR = get_default("COLOR_YELLOW")
			NAME = "yellow"
		6:
			COLOR = get_default("COLOR_PURPLE")
			NAME = "purple"
		7:
			COLOR = get_default("COLOR_ORANGE")
			NAME = "orange"
		8:
			COLOR = get_default("COLOR_BLACK")
			NAME = "black"
		9:
			print("hopefully this never prints - hmls.gd - get_cell_data()")
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
			ATTRIBUTE = "box"
		"3":
			ATTRIBUTE = "key"
		"7":
			ATTRIBUTE = "unspawnable"
		"8":
			ATTRIBUTE = "camera_switch"
		"9":
			ATTRIBUTE = "start_position"
		_:
			ATTRIBUTE = "null"
	return [COLOR, NAME, NEW_CELL, ATTRIBUTE]

func spawn_box(x, y, COLOR):
	var NEW_BOX = BOX_MESH.instantiate()
	NEW_BOX.name = str(x,"x",y,"_box")
	NEW_BOX.scale = NEW_BOX.scale * 0.5
	NEW_BOX.position = Vector3(x,0.3,y)
	var material = load("res://textures/block_3d_texture.tres")
	var new_material = material.duplicate()
	new_material.albedo_color = COLOR
	get_node("/root/hmls/VIEW_3D/").add_child(NEW_BOX)
	get_node(str("/root/hmls/VIEW_3D/",NEW_BOX.name,"/MeshInstance3D")).mesh.surface_set_material(0, new_material)
	if ENABLE_JANK:
		scale_thingy(NEW_BOX,0.3)

func spawn_key(COLOR,node_name):
	var material = load("res://textures/key_texture.tres")
	var new_material = material.duplicate()
	new_material.albedo_color = COLOR
	get_node(str("/root/hmls/VIEW_3D/",node_name)).mesh.surface_set_material(0, new_material)

func scale_thingy(node, speed):
	var old_scale = node.scale
	node.scale = Vector3(0,0,0)
	node.show()
	var tween = create_tween().set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(node,"scale",old_scale, speed)
	#await tween.finished

# this will spawn after the update_tiles() is ran
func tile_spawn(x, y, cell):
	# the get_cell_data() returns an array with html color codes and attributes
	var CELL_DATA = get_cell_data(cell)
	var COLOR = CELL_DATA[0]
	var ATTRIBUTE = CELL_DATA[3]
	if ATTRIBUTE == "start_position":
		START_POSITION = Vector2(x,y)
	if COLOR == "null":
		return
	var CURRENT_TILE
	# create a VIEW_3D node to attach all 3d nodes to
	if not get_node_or_null("/root/hmls/VIEW_3D"):
		var NODE_3D = Node3D.new()
		NODE_3D.name = str("VIEW_3D")
		get_node("/root/hmls").add_child(NODE_3D)
	if get_node_or_null(str("/root/hmls/VIEW_3D/",x,"x",y)):
		CURRENT_TILE = get_node(str("/root/hmls/VIEW_3D/",x,"x",y))
		var tween2 = create_tween()
		tween2.tween_property(CURRENT_TILE,"scale",Vector3(0,0,0), 0.3)
		await tween2.finished
	else:
		CURRENT_TILE = MeshInstance3D.new()
		CURRENT_TILE.name = str(x,"x",y)
		CURRENT_TILE.mesh = BoxMesh.new()
		get_node("/root/hmls/VIEW_3D").add_child(CURRENT_TILE)
	var material = StandardMaterial3D.new()
	material.albedo_color = COLOR
	CURRENT_TILE.mesh.surface_set_material(0, material)
	var TILE_SCALE = 0.85
	var TILE_HEIGHT = 0.1
	# WARNING: changing the CURRENT_TILE.name var will break floor_check() function
	CURRENT_TILE.name = str(x,"x",y)
	CURRENT_TILE.scale = Vector3(TILE_SCALE, TILE_HEIGHT, TILE_SCALE)
	CURRENT_TILE.position = Vector3(x, -(TILE_HEIGHT / 2 + 0.03), y)
	scale_thingy(CURRENT_TILE,0.4)
	match ATTRIBUTE:
		"box":
			spawn_box(x,y,COLOR)
		"key":
			spawn_key(COLOR,CURRENT_TILE.name)

func load_level():
	# if the CURRENT_LEVEL has data, set the LEVEL_MATRIX
	# this is so that when we redraw the tiles, the RNG is not set to a new value
	if CURRENT_LEVEL != []:
		LEVEL_MATRIX = CURRENT_LEVEL
		return
	# check if the level exists and load it as LEVEL_MATRIX
	var LEVEL_STRING = str("res://levels/LEVEL_", LEVEL, ".json")
	if not FileAccess.file_exists(LEVEL_STRING):
		LEVEL_MATRIX = get_default("LEVEL_MATRIX")
		GAME_MODE = get_default("GAME_MODE")
		LEVEL = 0
	else:
		var file = FileAccess.open(LEVEL_STRING, FileAccess.READ)
		var level_data = JSON.parse_string(file.get_as_text())
		# check if level json even has level data
		if level_data.has("LEVEL_MATRIX"):
			LEVEL_MATRIX = level_data.LEVEL_MATRIX
		else:
			LEVEL_MATRIX = get_default("LEVEL_MATRIX")
		if level_data.has("GAME_MODE"):
			GAME_MODE = level_data.GAME_MODE
		else:
			GAME_MODE = get_default("GAME_MODE")
		if level_data.has("DYNAMIC_CAM"):
			DYNAMIC_CAM = level_data.DYNAMIC_CAM

# this is the first function to run to spawn tiles
func update_tiles(MODE):
	# if reset, then delete all nodes and set CURRENT_LEVEL to nothing
	if MODE == "reset":
		remove_child(get_node("/root/hmls/VIEW_3D"))
		CURRENT_LEVEL = []
		LEVEL_RESOLUTION = Vector2(0,0)
		return
	load_level()
	# spawn all tiles in LEVEL_MATRIX
	var x = 0
	var y = 0
	for row in LEVEL_MATRIX:
		for cell in row:
			# check if level has RNG values set
			var NEW_CELL = cell
			if str(cell).left(1) == "9":
				# if level has RNG values set, change the cell to the new RNG value
				NEW_CELL = str(str(rng(1, 7),str(cell).right(1)))
				# set the NEW_CELL value to the LEVEL_MATRIX
				LEVEL_MATRIX[y][x] = NEW_CELL
			# set CURRENT_LEVEL so that when tiles are updated, we are no longer regenerating RNG
			CURRENT_LEVEL = LEVEL_MATRIX
			tile_spawn(x, y, NEW_CELL)
			# increment x so the next cell will be read correctly
			x += 1
			if x > LEVEL_RESOLUTION.x:
				LEVEL_RESOLUTION.x += 1
		# set x back to 0 and increment y to read the next row
		x = 0
		y += 1
		if y > LEVEL_RESOLUTION.y:
			LEVEL_RESOLUTION.y += 1

func attribute_stuffs(CELL):
	var CELL_DATA = CURRENT_LEVEL[CELL.y][CELL.x]
	var CHECK_TILE = hmls.get_cell_data(hmls.CURRENT_LEVEL[CELL.y][CELL.x])
	var COLOR = CHECK_TILE[1]
	var ATTRIBUTE = CHECK_TILE[3]
	match ATTRIBUTE:
		"start_position":
			if GAME_MODE == "classic":
				# check to see if tile is gray - without doing this, the level lags because it is rebuilt every step
				if COLOR != "gray":
					CURRENT_LEVEL[CELL.y][CELL.x] = "10"
					tile_spawn(CELL.x,CELL.y,"10")
			if GAME_MODE == "puzzle":
				if COLOR != "gray":
					CURRENT_LEVEL[CELL.y][CELL.x] = str(str(CELL_DATA).left(1),0)
					tile_spawn(CELL.x,CELL.y,str(str(CELL_DATA).left(1),0))
		"default":
			if GAME_MODE == "classic":
				# check to see if tile is gray - without doing this, the level lags because it is rebuilt every step
				if COLOR != "gray":
					CURRENT_LEVEL[CELL.y][CELL.x] = "10"
					tile_spawn(CELL.x,CELL.y,"10")
			if GAME_MODE == "puzzle":
				if COLOR != "gray":
					CURRENT_LEVEL[CELL.y][CELL.x] = str(str(CELL_DATA).left(1),0)
					tile_spawn(CELL.x,CELL.y,str(str(CELL_DATA).left(1),0))
		"camera_switch":
			if DYNAMIC_CAM == "true":
				DYNAMIC_CAM = "false"
			else:
				DYNAMIC_CAM = "true"
		"key":
			if KEY_COUNT < 1:
				reset_keys()
				KEY_COUNT = 0
			KEY_COUNT += 1
			if GAME_MODE == "puzzle":
				CURRENT_LEVEL[CELL.y][CELL.x] = str(str(CELL_DATA).left(1),0)
				tile_spawn(CELL.x,CELL.y,str(str(CELL_DATA).left(1),0))
			if GAME_MODE == "classic":
				CURRENT_LEVEL[CELL.y][CELL.x] = "10"
				tile_spawn(CELL.x,CELL.y,"10")
			debug_message("cube_3d.gd - fake_roll() - KEY_COUNT",KEY_COUNT,1)
		"box":
			if KEY_COUNT < 1:
				return
			var NODE_NAME = str("/root/hmls/VIEW_3D/",CELL.x,"x",CELL.y,"_box")
			KEY_COUNT -= 1
			if is_instance_valid(get_node(NODE_NAME)):
				if ENABLE_JANK == true:
					var tween2 = create_tween()
					tween2.tween_property(get_node(NODE_NAME),"scale",Vector3(0,0,0), 0.3)
					#await tween2.finished
				get_node(NODE_NAME).queue_free()
			match GAME_MODE:
				"classic":
					CURRENT_LEVEL[CELL.y][CELL.x] = "10"
					tile_spawn(CELL.x,CELL.y,"10")
				"puzzle":
					CURRENT_LEVEL[CELL.y][CELL.x] = str(str(CELL_DATA).left(1),0)
					tile_spawn(CELL.x, CELL.y, str(str(CELL_DATA).left(1),0))

func _ready():
	DisplayServer.window_set_title(get_default("WINDOW_TITLE"))
	DisplayServer.window_set_size(get_default("RESOLUTION"))
	update_level(1)

