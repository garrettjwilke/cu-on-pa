extends Node3D

var cam_offset = Vector3(0, 4, 8)
var static_cam_offset = Vector3(10,4,18)
var cam_speed = 3.0
var DYNAMIC_CAM = true

func _ready():
	get_node("Camera3D/Label").add_theme_font_size_override("font_size", 8)
	hmls.update_tiles("3d")

func _process(delta):
	if DYNAMIC_CAM == true:
		$Camera3D.position = lerp($Camera3D.position, $Cube.position + cam_offset, cam_speed * delta)
		$Camera3D.rotation = Vector3(-0.3,0,0)
	else:
		$Camera3D.position = static_cam_offset
		$Camera3D.rotation = Vector3(-0.3,0.4,0)
	if Input.is_action_just_pressed("ui_accept"):
		if DYNAMIC_CAM == true:
			DYNAMIC_CAM = false
		else:
			DYNAMIC_CAM = true
	
