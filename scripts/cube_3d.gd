extends CharacterBody3D

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D

var cube_size = 1.0
var speed = 6.0
var rolling = false
var CURRENT_ORIENTATION = Vector3(0,0,0)
var CURRENT_ORIENTATION_COLOR = "blue"

func _ready():
	position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(position.x,position.z))

func _physics_process(_delta):
	if Input.is_action_pressed("forward"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y - 1)):
			"stop":
				return
		roll(Vector3.FORWARD)
	if Input.is_action_pressed("back"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y + 1)):
			"stop":
				return
		roll(Vector3.BACK)
	if Input.is_action_pressed("right"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x + 1, hmls.CUBE_POSITION.y)):
			"stop":
				return
		roll(Vector3.RIGHT)
	if Input.is_action_pressed("left"):
		match str(hmls.floor_check(hmls.CUBE_POSITION.x - 1, hmls.CUBE_POSITION.y)):
			"stop":
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

# round number up/down
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

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
	# the orientation comes out with small floating point differences. round down/up
	CURRENT_ORIENTATION = Vector3(
		round_to_dec(mesh.rotation_degrees.x, 0),
		round_to_dec(mesh.rotation_degrees.y, 0),
		round_to_dec(mesh.rotation_degrees.z, 0)
		)
	# this messy match statement is how to keep track of what color is facing up on the cube
	match CURRENT_ORIENTATION:
		Vector3(0,0,0),Vector3(0,90,0),Vector3(0,-90,0),Vector3(0,180,-90),Vector3(0,-180,0),Vector3(0,180,0):
			CURRENT_ORIENTATION_COLOR = "blue"
		Vector3(0,0,-90),Vector3(0,-180,-90),Vector3(0,90,-90),Vector3(0,-90,-90):
			CURRENT_ORIENTATION_COLOR = "red"
		Vector3(0,0,180),Vector3(0,0,-180),Vector3(0,180,-180),Vector3(0,-180,180),Vector3(0,90,180),Vector3(0,-90,-180),Vector3(0,90,-180),Vector3(0,-90,180),Vector3(0, 180, 180),Vector3(0,-180,-180):
			CURRENT_ORIENTATION_COLOR = "orange"
		Vector3(0,0,90),Vector3(0,90,90),Vector3(0,-90,90),Vector3(0,180,90),Vector3(0,-180,90):
			CURRENT_ORIENTATION_COLOR = "yellow"
		Vector3(-90,0,0),Vector3(-90,-90,0),Vector3(0,90,90),Vector3(-90,90,0),Vector3(-90,-180,0),Vector3(-90,180,0):
			CURRENT_ORIENTATION_COLOR = "green"
		Vector3(90,0,0),Vector3(90,-90,0),Vector3(90,90,0),Vector3(90,180,0),Vector3(90,-180,0):
			CURRENT_ORIENTATION_COLOR = "purple"
		_:
			CURRENT_ORIENTATION_COLOR = "null"
	# if there is no color associated with the CURRENT_ORIENTATION, show the warning
	if CURRENT_ORIENTATION_COLOR == "null":
		print("!!!! WARNING !!!!")
		print(str("from cube_3d.gd - find missing CURRENT_ORIENTATION: ", CURRENT_ORIENTATION))
		print("!!!! WARNING !!!!")
	hmls.debug_message("", str("CURRENT COLOR: ", CURRENT_ORIENTATION_COLOR))
	rolling = false
	hmls.update_cube_position(Vector2(int(position.x), int(position.z)))
	
