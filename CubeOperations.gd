extends Node3D


enum Layer {
	UP = 1,
	BOTTOM = -1,
}

var moved_layer: Layer = Layer.UP

enum ActionType {
	DUMMY,
	TILT,
	ROTATE_LAYER,
}

class Action:
	func get_action_type() -> ActionType:
		return ActionType.DUMMY
	func get_duration() -> float:
		return 0
	func _to_string() -> String:
		return ""

class RotateLayerAction extends Action:
	var layer: Layer
	var times: int
	func get_action_type() -> ActionType:
		return ActionType.ROTATE_LAYER
	func _init(layer: Layer, times: int):
		self.layer = layer
		self.times = times
	func _to_string() -> String:
		match layer:
			1: return "T" + str(-times)
			-1: return "B" + str(-times)
			_: return ""
	func get_duration() -> float:
		return 0.2 * abs(times)

class TiltAction extends Action:
	func get_action_type() -> ActionType:
		return ActionType.TILT
	func _to_string() -> String:
		return "/"
	func get_duration() -> float:
		return 1.0

var action_queue: Array[Action] = []


func rot_n(n: int):
	action_queue.push_back(RotateLayerAction.new(moved_layer, (int(negate_rotation) * 2 - 1) * n))
	negate_rotation = false
	moved_layer *= -1


var processed_action: Action = null
var action_progress: float = 0

const DEFAULT_ELEMENT_POSITIONS: Dictionary = {
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

const LARGE_ELEMENTS: Array[String] = [
	"bottom_1",
	"bottom_3",
	"bottom_5",
	"bottom_7",
	"up_2",
	"up_4",
	"up_6",
	"up_8",
]

var element_positions: Dictionary = {}
var middle_flipped = false
var negate_rotation = false


func refresh_displayed_info():
	%ActionQueueDisplay.text = \
		str(processed_action if processed_action else "") \
		+ "".join(action_queue)
	%ActiveLayerDisplay.text = "top" if moved_layer == 1 else "bottom"
	%RotationDirectionDisplay.text = "reverse" if negate_rotation else "normal"


func show_cube():
	var middle_tilt_q = Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), int(middle_flipped) * PI)
	if processed_action != null:
		if processed_action.get_action_type() == ActionType.TILT:
			middle_tilt_q *= Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), -action_progress * PI)
	get_node("middle_2").rotation = middle_tilt_q.get_euler()
	for k in element_positions:
		var el = element_positions[k]
		var def_el = DEFAULT_ELEMENT_POSITIONS[k]
		var el_tilt = abs(el[0] - def_el[0]) / 2
		var tilt_q = Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), el_tilt * PI)
		var el_rot = el[1] - def_el[1]
		var rot_q = Quaternion(Vector3.UP, el_rot * PI / 6 * def_el[0])
		if processed_action != null:
			if processed_action.get_action_type() == ActionType.ROTATE_LAYER:
				if processed_action.layer == el[0]:
					rot_q *= Quaternion(Vector3.UP, action_progress * processed_action.times * PI / 6 * def_el[0])
			elif processed_action.get_action_type() == ActionType.TILT:
				if el[1] < 6:
					tilt_q *= Quaternion(Vector3(tan(PI/12), 0, -1).normalized(), -action_progress * PI)
		get_node(k).rotation = (tilt_q * rot_q).get_euler()


func can_tilt() -> bool:
	for k in LARGE_ELEMENTS:
		if element_positions[k][1] in [5, 11]:
			return false
	return true


func _init():
	for k in DEFAULT_ELEMENT_POSITIONS:
		element_positions[k] = DEFAULT_ELEMENT_POSITIONS[k]
	show_cube()


func _input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var c = event.get_keycode()
		if c >= 48 and c <= 57:
			rot_n(c - 48)
			refresh_displayed_info()
		elif c == 45:
			negate_rotation = !negate_rotation
			refresh_displayed_info()
		elif c == 47:
			negate_rotation = false
			moved_layer = Layer.UP
			action_queue.push_back(TiltAction.new())
			refresh_displayed_info()


func _process(delta: float):
	if processed_action != null:
		action_progress += delta / processed_action.get_duration()
		if action_progress >= 1:
			if processed_action.get_action_type() == ActionType.ROTATE_LAYER:
				for k in element_positions:
					var el = element_positions[k]
					if el[0] == processed_action.layer:
						element_positions[k] = [el[0], (el[1] + processed_action.times + 12) % 12]
			elif processed_action.get_action_type() == ActionType.TILT:
				middle_flipped = !middle_flipped
				for k in element_positions:
					var el = element_positions[k]
					if el[1] < 6:
						element_positions[k] = [el[0] * -1, el[1]]
			processed_action = null
	if processed_action == null and action_queue:
		processed_action = action_queue.pop_front()
		if processed_action.get_action_type() == ActionType.TILT and not can_tilt():
			processed_action = null
		action_progress = 0
	refresh_displayed_info()
	show_cube()


func _on_button_tilt_pressed():
	action_queue.push_back(TiltAction.new())


func _on_button_10_pressed():
	action_queue.push_back(RotateLayerAction.new(Layer.UP, -1))


func _on_button_n_10_pressed():
	action_queue.push_back(RotateLayerAction.new(Layer.UP, 1))


func _on_button_01_pressed():
	action_queue.push_back(RotateLayerAction.new(Layer.BOTTOM, -1))


func _on_button_n_01_pressed():
	action_queue.push_back(RotateLayerAction.new(Layer.BOTTOM, 1))
