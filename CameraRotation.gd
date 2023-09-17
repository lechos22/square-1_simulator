extends Node3D

const SENSITIVITY_X: int = 10
const SENSITIVITY_Y: int = 7

var rotation_x: float = PI / 4
var rotation_y: float = PI / 6
var invert_x: bool = false

func apply_rotation():
	rotation_x = fmod(rotation_x + 2 * PI, 2 * PI)
	rotation_y = fmod(rotation_y + 2 * PI, 2 * PI)
	self.rotation = Vector3(0, rotation_x, rotation_y)

func _init():
	apply_rotation()

func _input(event):
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_MIDDLE:
		invert_x = PI/2 < rotation_y and rotation_y < 3*PI/2
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		rotation_y += event.relative[1] * SENSITIVITY_Y / get_viewport().size.y
		rotation_x += (int(invert_x) * 2 - 1) * event.relative[0] * SENSITIVITY_X / get_viewport().size.x
		apply_rotation()
