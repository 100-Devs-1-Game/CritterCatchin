extends Node2D

@export var _panel_base_y: float = 0.0
@export var _override_position_y: float = 0.0
@export var bob_amplitude: float = 10.0
@export var bob_speed: float = 2.0

@export var target: Node
@export var override_starting_position: bool = false

var _time : float = 0.0
var _default_position: Vector2

func _ready() -> void:
	if !override_starting_position:
		return
	if target:
		_panel_base_y = target.position.y
		_default_position = target.position

func _process(delta: float) -> void:
	if SettingsManager.animated_ui:
		if target:
			if override_starting_position:
				_panel_base_y = _override_position_y
			_time += delta
			target.position.y = _panel_base_y + sin(_time * bob_speed) * bob_amplitude
	else:
		target.position = _default_position
