extends Node3D
@onready var CAMERA_NODE = $Camera3D

var cam_offset = Vector3(2, 8, 5)
var cam_rotation = Vector3(-60,0,0)
var static_cam_offset = Vector3(0,0,0)
var cam_speed = 4

func rotate_view(input):
	hmls.ROTATION_COUNT += input
	if hmls.ROTATION_COUNT > 4:
		if hmls.ENABLE_JANK == "true":
			hmls.ROTATION_COUNT = 1
		else:
			input = 0
			hmls.ROTATION_COUNT = 4
	if hmls.ROTATION_COUNT < 1:
		if hmls.ENABLE_JANK == "true":
			hmls.ROTATION_COUNT = 4
		else:
			input = 0
			hmls.ROTATION_COUNT = 1
	var ROTATION_DEGREES = 0
	if input == 1:
		ROTATION_DEGREES = 90
	elif input == -1:
		ROTATION_DEGREES = -90
	cam_rotation.y += ROTATION_DEGREES
	cam_rotation.z = -2
	match hmls.ROTATION_COUNT:
		1:
			cam_offset = Vector3(2.6, 8, 5)
		2:
			cam_offset = Vector3(5, 8, -2.6)
		3:
			cam_offset = Vector3(-2.6, 8, -5)
		4:
			cam_offset = Vector3(-5, 8, 2.6)
		_:
			hmls.ROTATION_COUNT = 1
			cam_offset = Vector3(2, 8, 5)
			cam_rotation.y = 0

func _ready():
	hmls.PAUSE = false
	rotate_view(0)
	hmls.update_tiles("3d")
	# after updating the level tiles, set the cube position
	var CUBE = get_node("Cube")
	CUBE.position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(CUBE.position.x, CUBE.position.z))

func _process(delta):
	if hmls.PAUSE:
		return
	if hmls.DYNAMIC_CAM == "true":
		if Input.is_action_just_pressed("CAM_ROTATE_LEFT"):
			rotate_view(-1)
		if Input.is_action_just_pressed("CAM_ROTATE_RIGHT"):
			rotate_view(1)
		$Camera3D.position = lerp($Camera3D.position, $Cube.position + cam_offset, cam_speed * delta)
		$Camera3D.rotation_degrees = lerp($Camera3D.rotation_degrees, cam_rotation, cam_speed * delta)
	else:
		var CAM = Vector3()
		# this will center the cam to the width of the level matrix
		CAM.x = (hmls.LEVEL_RESOLUTION.x / 2)
		CAM.y = ((hmls.LEVEL_RESOLUTION.y + hmls.LEVEL_RESOLUTION.x) / 2) + 2
		#CAM.y = CAM.x * 1.9
		CAM.z = (hmls.LEVEL_RESOLUTION.y) * 1.3
		if CAM.z < 10:
			CAM.z += 4
		var CAM_ROTATE = Vector3(0,0,0)
		var ROTATION = ((CAM.y - 2) * 0.02)
		CAM_ROTATE.x = -0.76 - ROTATION
		static_cam_offset = Vector3(CAM.x, CAM.y, CAM.z)
		#static_cam_offset = Vector3(CAM.x, CAM.y, CAM.z)
		$Camera3D.position = lerp($Camera3D.position, static_cam_offset, cam_speed * delta)
		$Camera3D.rotation = lerp($Camera3D.rotation, CAM_ROTATE, cam_speed * delta)
		#$Camera3D.rotation = Vector3(-0.6,0,0)
	if Input.is_action_just_pressed("ui_accept"):
		if hmls.DYNAMIC_CAM == "true":
			hmls.DYNAMIC_CAM = "false"
		else:
			hmls.DYNAMIC_CAM = "true"
	
