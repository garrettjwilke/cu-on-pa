extends Node3D
var cam_offset = Vector3(0, 4, 6)
var cam_speed = 4.0

var LEVEL_MATRIX = hmls.LEVEL_1
func _ready():
	hmls.update_level(LEVEL_MATRIX)

func _process(delta):
	$Camera3D.position = lerp($Camera3D.position, $Cube.position + cam_offset, cam_speed * delta)
