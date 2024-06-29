extends CharacterBody3D

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D
#var STARTING_PIVOT
var cube_size = 1.0
var speed = 6.0
var rolling = false
var CURRENT_ORIENTATION = Vector3(0,0,0)
var CURRENT_ORIENTATION_COLOR
var FUTURE_ORIENTATION = Vector3(0,0,0)
var FUTURE_ORIENTATION_COLOR

# the input passed through to match_orientation is a Vector3 with xyz containting a Vector3
func match_orientation(input):
	var RETURN_COLOR = "null"
	if input.x.y == 1:
		RETURN_COLOR = "yellow"
	elif input.x.y == -1:
		RETURN_COLOR = "red"
	if input.y.y == 1:
		RETURN_COLOR = "blue"
	elif input.y.y == -1:
		RETURN_COLOR = "orange"
	if input.z.y == 1:
		RETURN_COLOR = "green"
	elif input.z.y == -1:
		RETURN_COLOR = "purple"
	if RETURN_COLOR == "null":
		hmls.debug_message("cube_3d.gd - match_orientation()", str(input), 3)
	return RETURN_COLOR

# before actually rolling, we want check for the color of the tile we are rolling into
# so this junk below will create a fake cube and roll it to find if we can even land there
func fake_roll(dir):
	if rolling:
		#CAN_ROLL = "false"
		return "false"
	rolling = true
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
	FAKE_MESH.rotation_degrees = hmls.round_vect3(mesh.rotation_degrees)
	# do the stuffs to make the fake pivot move
	#FAKE_PIVOT.translate(dir * cube_size / 2)
	FAKE_MESH.global_translate(-dir * cube_size / 2)
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(FAKE_PIVOT, "transform",FAKE_PIVOT.transform.rotated_local(axis, PI/2), 0)
	await tween.finished
	var b = FAKE_MESH.global_transform.basis
	FAKE_PIVOT.transform = Transform3D.IDENTITY
	FAKE_MESH.position = Vector3(0, cube_size / 2, 0)
	FAKE_MESH.global_transform.basis = b
	# this will get the orientation of the FAKE_MESH after it has moved around and stuffs
	FUTURE_ORIENTATION_COLOR = match_orientation(FAKE_MESH.global_transform.basis)
	# we then delete the FAKE_PIVOT and FAKE_MESH
	FAKE_PIVOT.queue_free()
	# we need to get the properties of the tile we are moving into
	# this will create an x y position of the tile we are trying to move to
	var CELL = Vector2(hmls.CUBE_POSITION.x + dir.x, hmls.CUBE_POSITION.y + dir.z)
	# we then take that CELL_DATA and get color and attributes of the tile we are trying to move to
	var CHECK_TILE = hmls.get_cell_data(hmls.CURRENT_LEVEL[CELL.y][CELL.x])
	# if the tile color is gray, we cheat and say that the tile color is the color of our cube
	if CHECK_TILE[1] == "gray":
		FUTURE_ORIENTATION_COLOR = CHECK_TILE[1]
		#CHECK_COLOR[1] = FUTURE_ORIENTATION_COLOR
	rolling = false
	# if the color of the tile we are trying to move into is the same as what our cube will be
	if FUTURE_ORIENTATION_COLOR == CHECK_TILE[1]:
		#hmls.attribute_stuffs(CELL)
		return "true"
		#CAN_ROLL = "true"
	else:
		hmls.debug_message("cube_3d.gd - fake_roll() - CHECK_COLOR",CHECK_TILE,2)
		#CAN_ROLL = "false"
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
				hmls.debug_message("cube_3d.gd - roll()","right side collision detected", 2)
			1:
				hmls.debug_message("cube_3d.gd - roll()","left side collision detected", 2)
		match int(collision.normal.z):
			-1:
				hmls.debug_message("cube_3d.gd - roll()","bottom side collision detected", 2)
			1:
				hmls.debug_message("cube_3d.gd - roll()","top side collision detected", 2)
		return
	rolling = true
	# Step 1: Offset the pivot.
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)
	# Step 2: Animate the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pivot, "transform",pivot.transform.rotated_local(axis, PI/2), 1 / speed)
	await tween.finished
	# Step 3: Finalize the movement and reset the offset.
	position += dir * cube_size
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2, 0)
	mesh.global_transform.basis = b
	CURRENT_ORIENTATION_COLOR = match_orientation(mesh.global_transform.basis)
	hmls.debug_message("cube_3d.gd - roll() - CURRENT_ORIENTATION_COLOR", CURRENT_ORIENTATION_COLOR,1)
	rolling = false
	hmls.update_cube_position(Vector2(int(position.x), int(position.z)))

func reset_pos():
	position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(position.x,position.z))
	mesh.rotation_degrees = Vector3(0,0,0)

func _ready():
	hmls.KEY_COUNT = 0
	position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(position.x,position.z))

var ORIGINAL_SPEED = speed
# sloppy input management
func _physics_process(_delta):
	speed = ORIGINAL_SPEED
	if Input.is_action_pressed("hmls_shift"):
		speed = speed * 2
	var DIR = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		DIR = Vector3.FORWARD
	if Input.is_action_pressed("back"):
		DIR = Vector3.BACK
	if Input.is_action_pressed("right"):
		DIR = Vector3.RIGHT
	if Input.is_action_pressed("left"):
		DIR = Vector3.LEFT
	if DIR != Vector3.ZERO:
		match str(hmls.floor_check(hmls.CUBE_POSITION.x + DIR.x, hmls.CUBE_POSITION.y + DIR.z)):
			"stop":
				return
		var CAN_ROLL = await fake_roll(DIR)
		#await fake_roll(DIR)
		if CAN_ROLL == "false":
			return
		hmls.attribute_stuffs(Vector2(hmls.CUBE_POSITION.x + DIR.x, hmls.CUBE_POSITION.y + DIR.z))
		roll(DIR)
	if Input.is_action_just_pressed("reset"):
		# uncomment the line below to force the RNG to be the same each reset
		#hmls.update_rng_seed(hmls.get_default("RNG_SEED"))
		hmls.debug_message("cube_3d.gd", "reset button pressed", 1)
		hmls.update_tiles("reset")
		hmls.update_tiles("3d")
		reset_pos()
	if Input.is_action_just_pressed("level_next"):
		hmls.update_level(1)
		hmls.update_tiles("reset")
		hmls.update_tiles("3d")
		# set the position and then pass position to hmls.update_cube_position
		# if we don't do this, the cube can end up on a bad tile
		reset_pos()
	if Input.is_action_just_pressed("level_previous"):
		hmls.update_level(-1)
		hmls.update_tiles("reset")
		hmls.update_tiles("3d")
		reset_pos()
