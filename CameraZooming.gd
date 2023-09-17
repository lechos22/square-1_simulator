extends Node3D

const ZOOM_MULTIPLIER = 1.5

var zoom = 0

func apply_zoom():
	self.position = Vector3(2 + pow(1.5, -zoom), 0, 0)

func _input(event):
	if event is InputEventMouseButton:
		match event.get_button_index():
			MOUSE_BUTTON_WHEEL_UP:
				zoom = mini(zoom + 1, 5)
				apply_zoom()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = maxi(zoom - 1, -15)
				apply_zoom()
