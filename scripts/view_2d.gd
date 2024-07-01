extends Node2D
@onready var MENU_NODE = $Control
@onready var KEYBINDS_NODE = $Control/CenterContainer/keybinds_label

var KEYBINDS_TEXT = "------    Keybinds:    ------
Fullscreen Toggle: F
  - for some reason it requires you to press it twice
Regenerate RNG: R
Load Next Level: N
Load Previous Level: B
Dynamic Cam Toggle: Enter
Rotate Cam Left (Dynamic Cam Only): Q
Rotate Cam Right(Dynamic Cam Only): E
"

func _ready():
	hmls.PAUSE = false
	MENU_NODE.hide()
	KEYBINDS_NODE.add_theme_font_size_override("font_size", 8)
	KEYBINDS_NODE.text = KEYBINDS_TEXT

func _process(_delta):
	if Input.is_action_just_pressed("menu_button"):
		if MENU_NODE.is_visible_in_tree():
			MENU_NODE.hide()
			hmls.PAUSE = false
		else:
			MENU_NODE.show()
			hmls.PAUSE = true
