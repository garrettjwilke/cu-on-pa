extends CharacterBody3D

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D


var cube_size = 1.0
var speed = 6.0
var rolling = false
var CURRENT_ORIENTATION = Vector3(0,0,0)
var CURRENT_ORIENTATION_COLOR = "blue"
var FUTURE_ORIENTATION = Vector3(0,0,0)
var FUTURE_ORIENTATION_COLOR = "blue"

# round number up/down
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func round_vect3(data):
	data.x = round(data.x * pow(10.0,0))
	data.y = round(data.y * pow(10.0,0))
	data.z = round(data.z * pow(10.0,0))
	return data

func match_orientation(direction):
	direction = round_vect3(direction)
	var NEW_COLOR
	# this messy match statement is how to keep track of what color is facing up on the cube
	match direction:
		Vector3(0,0,0),Vector3(0,90,0),Vector3(0,-90,0),Vector3(0,-180,0),Vector3(0,180,0):
			NEW_COLOR = "blue"
		Vector3(0,0,-90),Vector3(0,-180,-90),Vector3(0,90,-90),Vector3(0,-90,-90),Vector3(0,180,-90):
			NEW_COLOR = "red"
		Vector3(0,0,180),Vector3(0,0,-180),Vector3(0,180,-180),Vector3(0,-180,180),Vector3(0,90,180),Vector3(0,-90,-180),Vector3(0,90,-180),Vector3(0,-90,180),Vector3(0, 180, 180),Vector3(0,-180,-180),Vector3(180,0,0),Vector3(-180,0,0):
			NEW_COLOR = "orange"
		Vector3(0,0,90),Vector3(0,90,90),Vector3(0,-90,90),Vector3(0,180,90),Vector3(0,-180,90):
			NEW_COLOR = "yellow"
		Vector3(-90,0,0),Vector3(-90,-90,0),Vector3(0,90,90),Vector3(-90,90,0),Vector3(-90,-180,0),Vector3(-90,180,0):
			NEW_COLOR = "green"
		Vector3(90,0,0),Vector3(90,-90,0),Vector3(90,90,0),Vector3(90,180,0),Vector3(90,-180,0):
			NEW_COLOR = "purple"
		_:
			print()
			print("WARNING:")
			print(str("cube_3d.gd - match_orientation: color not found. ", direction))
			NEW_COLOR = "null"
	return NEW_COLOR

var IS_ACTIVE = "false"
# before actually rolling, we want check for the color of the tile we are rolling into
# so this junk below will create a fake cube and roll it to find if we can even land there
func fake_roll(dir):
	if rolling:
		return "false"
	# create a FAKE_PIVOT mesh
	var FAKE_PIVOT = Node3D.new()
	FAKE_PIVOT.name = "FAKE_PIVOT"
	pivot.add_child(FAKE_PIVOT)
	# create an invisible mesh
	var FAKE_MESH = MeshInstance3D.new()
	FAKE_MESH.name = "INVISIBLE_CUBE"
	FAKE_PIVOT.add_child(FAKE_MESH)
	# set the properties from the original mesh and pivot
	FAKE_MESH.position = mesh.position
	FAKE_MESH.global_transform.basis = mesh.global_transform.basis
	FAKE_MESH.rotation_degrees = round_vect3(mesh.rotation_degrees)
	# do the stuffs to make the fake pivot move
	FAKE_PIVOT.translate(dir * cube_size / 2)
	FAKE_MESH.global_translate(-dir * cube_size / 2)
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(FAKE_PIVOT, "transform",
			FAKE_PIVOT.transform.rotated_local(axis, PI/2), 1 / 5000)
	await tween.finished
	var b = FAKE_MESH.global_transform.basis
	FAKE_PIVOT.transform = Transform3D.IDENTITY
	FAKE_MESH.position = Vector3(0, cube_size / 2, 0)
	FAKE_MESH.global_transform.basis = b
	# this will get the orientation of the FAKE_MESH after it has moved around and stuffs
	FUTURE_ORIENTATION = round_vect3(FAKE_MESH.rotation_degrees)
	# we use the orientation of the FAKE_MESH to determine what color would be on top if we move
	FUTURE_ORIENTATION_COLOR = match_orientation(FUTURE_ORIENTATION)
	# we then delete the FAKE_PIVOT and FAKE_MESH
	FAKE_PIVOT.queue_free()
	# we need to get the properties of the tile we are moving into
	# this will create an x y position of the tile we are trying to move to
	var CELL = Vector2(hmls.CUBE_POSITION.x + dir.x, hmls.CUBE_POSITION.y + dir.z)
	# this will give us the value in the x and y coordinates of our LEVEL_MATRIX
	var CELL_DATA = hmls.LEVEL_MATRIX[CELL.y][CELL.x]
	# we then take that CELL_DATA and get color and attributes of the tile we are trying to move to
	var CHECK_COLOR = hmls.get_cell_data(CELL_DATA)
	print()
	print("attempted cube color: ", FUTURE_ORIENTATION_COLOR, " ", FUTURE_ORIENTATION)
	print("attempted tile color: ", CHECK_COLOR[1])
	# if the color is gray, we should be able to move into it
	if CHECK_COLOR[1] == "gray":
		# we set the color to the cube orientation color
		CHECK_COLOR[1] = FUTURE_ORIENTATION_COLOR
	# if the color of the tile we are trying to move into is the same as what our cube will be
	if FUTURE_ORIENTATION_COLOR == CHECK_COLOR[1]:
		return "true"
	else:
		return "false"

func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling:
		return
	# Cast a ray to check for obstacles
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(mesh.global_position,
			mesh.global_position + dir * cube_size, collision_mask, [self])
	var collision = space.intersect_ray(ray)
	if collision:
		match int(collision.normal.x):
			-1:
				hmls.debug_message("cube_3d.gd - roll()","right side collision detected")
			1:
				hmls.debug_message("cube_3d.gd - roll()","left side collision detected")
		match int(collision.normal.z):
			-1:
				hmls.debug_message("cube_3d.gd - roll()","bottom side collision detected")
			1:
				hmls.debug_message("cube_3d.gd - roll()","top side collision detected")
		return
	rolling = true
	# Step 1: Offset the pivot.
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)
	# Step 2: Animate the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pivot, "transform",
			pivot.transform.rotated_local(axis, PI/2), 1 / speed)
	await tween.finished
	# Step 3: Finalize the movement and reset the offset.
	position += dir * cube_size
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2, 0)
	mesh.global_transform.basis = b
	CURRENT_ORIENTATION = round_vect3(mesh.rotation_degrees)
	CURRENT_ORIENTATION_COLOR = match_orientation(CURRENT_ORIENTATION)
	hmls.debug_message("", str("CURRENT COLOR: ", CURRENT_ORIENTATION_COLOR))
	rolling = false
	hmls.update_cube_position(Vector2(int(position.x), int(position.z)))

func _ready():
	position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(position.x,position.z))

# sloppy input management
func _physics_process(_delta):
	if Input.is_action_pressed("forward"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y - 1)):
			"stop":
				return
		var CAN_ROLL = await fake_roll(Vector3.FORWARD)
		if CAN_ROLL == "false":
			return
		roll(Vector3.FORWARD)
	if Input.is_action_pressed("back"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y + 1)):
			"stop":
				return
		var CAN_ROLL = await fake_roll(Vector3.BACK)
		if CAN_ROLL == "false":
			return
		roll(Vector3.BACK)
	if Input.is_action_pressed("right"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x + 1, hmls.CUBE_POSITION.y)):
			"stop":
				return
		var CAN_ROLL = await fake_roll(Vector3.RIGHT)
		if CAN_ROLL == "false":
			return
		roll(Vector3.RIGHT)
	if Input.is_action_pressed("left"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x - 1, hmls.CUBE_POSITION.y)):
			"stop":
				return
		var CAN_ROLL = await fake_roll(Vector3.LEFT)
		if CAN_ROLL == "false":
			return
		roll(Vector3.LEFT)
	if Input.is_action_just_pressed("reset"):
		hmls.update_tiles("reset")
	if Input.is_action_just_pressed("level_next"):
		hmls.update_level()
		hmls.update_tiles("reset")
		# set the position and then pass position to hmls.update_cube_position
		# if we don't do this, the cube can end up on a bad tile
		position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
		hmls.update_cube_position(Vector2(position.x,position.z))
