extends Node3D


enum Layer {
	UP = 1,
	MIDDLE = 0,
	BOTTOM = -1,
}

var moved_layer: Layer = Layer.UP

class Action:
	func get_duration() -> float:
		return 0

class RotateLayerAction extends Action:
	var layer: Layer
	var times: int
	func _init(layer: Layer, times: int):
		self.layer = layer
		self.times = times
	func _to_string() -> String:
		return "RotateLayerAction(" + str(layer) + ", " + str(times) + ")"
	func get_duration() -> float:
		return 0.2 * abs(times)

class RotateHalfAction extends Action:
	func _to_string() -> String:
		return "RotateHalfAction"
	func get_duration() -> float:
		return 1.0

var action_queue: Array[Action] = []

func rot_n(n: int):
	action_queue.push_back(RotateLayerAction.new(moved_layer, (int(negate_rotation) * 2 - 1) * n))
	negate_rotation = false
	moved_layer *= -1

var processed_action: Action = null
var action_progress: float = 0

var default_element_positions: Dictionary = {
	"up_1": [1, 0],
	"up_2": [1, 1],
	"up_3": [1, 3],
	"up_4": [1, 4],
	"up_5": [1, 6],
	"up_6": [1, 7],
	"up_7": [1, 9],
	"up_8": [1, 10],
	"bottom_1": [-1, 0],
	"bottom_2": [-1, 2],
	"bottom_3": [-1, 3],
	"bottom_4": [-1, 5],
	"bottom_5": [-1, 6],
	"bottom_6": [-1, 8],
	"bottom_7": [-1, 9],
	"bottom_8": [-1, 11],
}

var element_positions: Dictionary = {}
var middle_flipped = false
var negate_rotation = false

func show_cube():
	var middle_tilt_q = Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), int(middle_flipped) * PI)
	if processed_action != null:
		if processed_action is RotateHalfAction:
			middle_tilt_q *= Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), -action_progress * PI)
	get_node("middle_2").rotation = middle_tilt_q.get_euler()
	for k in element_positions:
		var el = element_positions[k]
		var def_el = default_element_positions[k]
		var el_tilt = abs(el[0] - def_el[0]) / 2
		var tilt_q = Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), el_tilt * PI)
		var el_rot = el[1] - def_el[1]
		var rot_q = Quaternion(Vector3.UP, el_rot * PI / 6 * def_el[0])
		if processed_action != null:
			if processed_action is RotateLayerAction:
				if processed_action.layer == el[0]:
					rot_q *= Quaternion(Vector3.UP, action_progress * processed_action.times * PI / 6 * def_el[0])
			elif processed_action is RotateHalfAction:
				if el[1] < 6:
					tilt_q *= Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), -action_progress * PI)
		get_node(k).rotation = (tilt_q * rot_q).get_euler()
		#get_node(k).rotation = Vector3(0, el_rot * PI / 6, sign(el[0] - def_el[0]) * PI)

func _init():
	for k in default_element_positions:
		element_positions[k] = default_element_positions[k]
	show_cube()

func _input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var c = event.get_keycode()
		if c >= 48 and c <= 57:
			rot_n(c - 48)
		elif c == 45:
			negate_rotation = !negate_rotation
		elif c == 47:
			negate_rotation = false
			moved_layer = Layer.UP
			action_queue.push_back(RotateHalfAction.new())

func _process(delta: float):
	if processed_action != null:
		action_progress += delta / processed_action.get_duration()
		if action_progress >= 1:
			if processed_action is RotateLayerAction:
				for k in element_positions:
					var el = element_positions[k]
					if el[0] == processed_action.layer:
						element_positions[k] = [el[0], (el[1] + processed_action.times + 12) % 12]
			elif processed_action is RotateHalfAction:
				middle_flipped = !middle_flipped
				for k in element_positions:
					var el = element_positions[k]
					if el[1] < 6:
						element_positions[k] = [el[0] * -1, el[1]]
			processed_action = null
	elif action_queue:
		processed_action = action_queue.pop_front()
		action_progress = 0
	show_cube()
