extends Node2D

@onready var KEYBINDS_NODE = $Control/keybinds_label

var KEYBINDS_TEXT = "------    Keybinds:    ------
Regenerate RNG: R
Load Next Level: N
Load Previous Level: B
Toggle Dynamic Cam: Enter
Rotate Cam Left (Dynamic Cam Only): Q
Rotate Cam Right(Dynamic Cam Only): E
"

func _ready():
	KEYBINDS_NODE.add_theme_font_size_override("font_size", 8)
	KEYBINDS_NODE.text = KEYBINDS_TEXT

func _process(_delta):
	if Input.is_action_just_pressed("menu_button"):
		if KEYBINDS_NODE.is_visible_in_tree():
			KEYBINDS_NODE.hide()
		else:
			KEYBINDS_NODE.show()
