extends CharacterBody3D

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D

var cube_size = 1.0
var speed = 6.0
var rolling = false

func _physics_process(_delta):
	if Input.is_action_pressed("forward"):
		# check if the cube can roll by checking the tiles around current cube position
		if str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y - 1)) == "stop":
			return
		roll(Vector3.FORWARD)
	if Input.is_action_pressed("back"):
		# check if the cube can roll by checking the tiles around current cube position
		if str(hmls.floor_check(hmls.CUBE_POSITION.x, hmls.CUBE_POSITION.y + 1)) == "stop":
			return
		roll(Vector3.BACK)
	if Input.is_action_pressed("right"):
		# check if the cube can roll by checking the tiles around current cube position
		if str(hmls.floor_check(hmls.CUBE_POSITION.x + 1, hmls.CUBE_POSITION.y)) == "stop":
			return
		roll(Vector3.RIGHT)
	if Input.is_action_pressed("left"):
		# check if the cube can roll by checking the tiles around current cube position
		if str(hmls.floor_check(hmls.CUBE_POSITION.x - 1, hmls.CUBE_POSITION.y)) == "stop":
			return
		roll(Vector3.LEFT)
	if Input.is_action_just_pressed("reset"):
		hmls.update_tiles("reset")
	if Input.is_action_just_pressed("level_next"):
		hmls.update_level()
		hmls.update_tiles("reset")
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
	rolling = false
	hmls.update_cube_position(Vector2(int(position.x), int(position.z)))
