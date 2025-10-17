extends Node2D

@export var net: Sprite2D
@export var sway_speed: float = 1.0
@export var sway_x_amplitude: float = 5.0
@export var sway_y_amplitude: float = 3.0
@export var pixel_size: float = 1.0

var sway: float = 0.0
var base_position: Vector2

func _ready() -> void:
	if net:
		base_position = net.position

func _process(delta: float) -> void:
	if not net:
		return

	sway += delta * sway_speed
	var raw_pos = base_position + Vector2(
		sin(sway) * sway_x_amplitude,
		sin(sway * 0.8) * sway_y_amplitude
	)

	net.position = Vector2(
		floor(raw_pos.x / pixel_size + 0.5) * pixel_size,
		floor(raw_pos.y / pixel_size + 0.5) * pixel_size
	)
