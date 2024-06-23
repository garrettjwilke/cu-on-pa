extends Node3D

var cam_offset = Vector3(0, 8, 8)
var static_cam_offset = Vector3(0,0,0)
var cam_speed = 3

func _ready():
	get_node("Camera3D/Label").add_theme_font_size_override("font_size", 8)
	# not sure why but the print line below fixes the standalone 3d version
	#print("")
	hmls.update_tiles("3d")
	# after updating the level tiles, set the cube position
	var CUBE = get_node("Cube")
	CUBE.position = Vector3(hmls.START_POSITION.x,0,hmls.START_POSITION.y)
	hmls.update_cube_position(Vector2(CUBE.position.x, CUBE.position.z))

func _process(delta):
	if hmls.DYNAMIC_CAM == "true":
		if get_node_or_null("/root/hmls/VIEW_2D"):
			get_node("/root/hmls/VIEW_2D").show()
		$Camera3D.position = lerp($Camera3D.position, $Cube.position + cam_offset, cam_speed * delta)
		$Camera3D.rotation = lerp($Camera3D.rotation, Vector3(-0.6,0,0), cam_speed * delta)
	else:
		if get_node_or_null("/root/hmls/VIEW_2D"):
			get_node("/root/hmls/VIEW_2D").hide()
		#var CAM = Vector3(hmls.LEVEL_RESOLUTION.x, 10, hmls.LEVEL_RESOLUTION.y)
		var CAM = Vector3()
		# this will center the cam to the width of the level matrix
		CAM.x = (hmls.LEVEL_RESOLUTION.x / 2) - 0.5
		CAM.y = hmls.LEVEL_RESOLUTION.y * 1.3
		CAM.z = CAM.x * 1.5
		var CAM_ROTATE = Vector3(0,0,0)
		CAM_ROTATE.x = -0.95
		static_cam_offset = Vector3(CAM.x, CAM.z, CAM.y)
		$Camera3D.position = lerp($Camera3D.position, static_cam_offset, cam_speed * delta)
		$Camera3D.rotation = lerp($Camera3D.rotation, CAM_ROTATE, cam_speed * delta)
		#$Camera3D.rotation = Vector3(-0.6,0,0)
	if Input.is_action_just_pressed("ui_accept"):
		if hmls.DYNAMIC_CAM == "true":
			hmls.DYNAMIC_CAM = "false"
		else:
			hmls.DYNAMIC_CAM = "true"
	
