extends Node2D

const LILGUY = preload("res://components/traveling entity/lilguy.tscn")

@export var override_difficulty_count: bool = false
@export var num_lilguys: int = 30
@export var spawn_area_node: Node2D

var lilguys: Array = []
var special_lilguy: Node2D = null

var stage_entity_amount: int = 30
@export var stage_speed_ramp: float = 7.0
@export var stage_entity_ramp: int = 3

func _ready() -> void:
	Eventbus.level_started.connect(start_level)
	Eventbus.level_ended.connect(_clear_lilguys)

func start_level(level: int) -> void:
	_clear_lilguys()

	var count: int
	if override_difficulty_count:
		count = num_lilguys
	else:
		count = stage_entity_amount + stage_entity_ramp * (level - 1)

	print("Starting this level with: ", count)

	for i in range(count):
		_spawn_lilguy(level)

	_spawn_special_lilguy(level)

func _spawn_lilguy(difficulty: int) -> void:
	if not is_instance_valid(spawn_area_node):
		push_warning("No spawn_area_node assigned!")
		return

	var rect_size = spawn_area_node.rect_size
	var rect_pos = spawn_area_node.global_position - rect_size * 0.5

	var lilguy = LILGUY.instantiate()
	var pos = Vector2(
		randf_range(rect_pos.x, rect_pos.x + rect_size.x),
		randf_range(rect_pos.y, rect_pos.y + rect_size.y)
	)
	lilguy.position = pos
	add_child(lilguy)
	lilguys.append(lilguy)

	if difficulty > 10:
		var ramp_amount = difficulty - 10
		lilguy.speed += ramp_amount * stage_speed_ramp
		print("Lil guys have: ", lilguy.speed)

func _spawn_special_lilguy(difficulty: int) -> void:
	if not is_instance_valid(spawn_area_node):
		push_warning("No spawn_area_node assigned!")
		return

	var rect_size = spawn_area_node.rect_size
	var rect_pos = spawn_area_node.global_position - rect_size * 0.5

	special_lilguy = LILGUY.instantiate()
	var pos = Vector2(
		randf_range(rect_pos.x, rect_pos.x + rect_size.x),
		randf_range(rect_pos.y, rect_pos.y + rect_size.y)
	)
	special_lilguy.position = pos
	add_child(special_lilguy)
	special_lilguy.z_index = -1
	special_lilguy.modulate = Color(0, 0, 1)

	if special_lilguy.has_method("add_catch_handler"):
		special_lilguy.add_catch_handler()

	if difficulty > 10:
		var ramp_amount = difficulty - 10
		special_lilguy.speed += ramp_amount * stage_speed_ramp
		print("Special lilguy has speed: ", special_lilguy.speed)


func _clear_lilguys() -> void:
	for lilguy in lilguys:
		if is_instance_valid(lilguy):
			lilguy.queue_free()
	lilguys.clear()
