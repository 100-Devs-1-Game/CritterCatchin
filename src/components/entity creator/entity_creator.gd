extends Node2D
class_name EntityCreator

const LILGUY = preload("res://components/traveling entity/lilguy.tscn")

@export var override_difficulty_count: bool = false
@export var num_lilguys: int = 30
@export var spawn_area_node: Node2D

var lilguys: Array = []
var special_lilguy: Node2D = null

var stage_entity_amount: int = 30
@export var stage_speed_ramp: float = 7.0
@export var stage_entity_ramp: int = 3
@export var for_title: bool = false

@export var world: Node2D

var bug_textures: Array = []
var other_textures: Array = []
var normal_textures: Array = []
var special_texture: Texture2D

func _ready() -> void:
	_load_textures_from_folder("res://assets/bugs/", bug_textures)
	_load_textures_from_folder("res://assets/other/", other_textures)

	if for_title:
		start_level(60)
		return

	Eventbus.level_started.connect(start_level)
	Eventbus.level_ended.connect(_clear_lilguys)

## Loads all png files from a given folder into the target array
func _load_textures_from_folder(path: String, target_array: Array) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_warning("Could not open folder: " + path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path = path + file_name
			if ResourceLoader.exists(full_path, "Texture2D"):
				var tex = load(full_path)
				if tex:
					target_array.append(tex)
				else:
					push_warning("Failed to load texture: " + full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

## Reserves a texture for the special bug, creates the other bugs and the special bug.
func start_level(level: int) -> void:
	if bug_textures.size() == 0:
		push_warning("No bug textures loaded!")
		return

	special_texture = bug_textures[randi() % bug_textures.size()]

	normal_textures = []
	for tex in bug_textures + other_textures:
		if tex != special_texture:
			normal_textures.append(tex)

	var count: int
	if override_difficulty_count:
		count = num_lilguys
	else:
		count = stage_entity_amount + stage_entity_ramp * (level - 1)

	for i in range(count):
		_spawn_lilguy(level)
	if !for_title:
		_spawn_special_lilguy(level)

func _spawn_lilguy(difficulty: int) -> void:
	if not is_instance_valid(spawn_area_node):
		push_warning("No spawn_area_node assigned!")
		return

	var rect_size = spawn_area_node.rect_size
	var rect_pos = spawn_area_node.global_position - rect_size * 0.5

	var lilguy = LILGUY.instantiate()
	lilguy.position = Vector2(
		randf_range(rect_pos.x, rect_pos.x + rect_size.x),
		randf_range(rect_pos.y, rect_pos.y + rect_size.y)
	)
	add_child(lilguy)
	lilguys.append(lilguy)

	if normal_textures.size() > 0 and lilguy.has_node("Sprite2D"):
		var sprite = lilguy.get_node("Sprite2D") as Sprite2D
		sprite.texture = normal_textures[randi() % normal_textures.size()]

	if difficulty > 10:
		var ramp_amount = difficulty - 10
		lilguy.speed += ramp_amount * stage_speed_ramp

func _spawn_special_lilguy(difficulty: int) -> void:
	if !is_instance_valid(spawn_area_node):
		push_warning("No spawn_area_node assigned!")
		return

	var rect_size = spawn_area_node.rect_size
	var rect_pos = spawn_area_node.global_position - rect_size * 0.5

	special_lilguy = LILGUY.instantiate()
	special_lilguy.position = Vector2(
		randf_range(rect_pos.x, rect_pos.x + rect_size.x),
		randf_range(rect_pos.y, rect_pos.y + rect_size.y)
	)
	add_child(special_lilguy)
	special_lilguy.z_index = -1

	if special_texture and special_lilguy.has_node("Sprite2D"):
		var sprite = special_lilguy.get_node("Sprite2D") as Sprite2D
		sprite.texture = special_texture
		if is_instance_valid(world):
			world.set_target(special_texture)

	if special_lilguy.has_method("add_catch_handler"):
		special_lilguy.add_catch_handler()

	if difficulty > 10:
		var ramp_amount = difficulty - 10
		special_lilguy.speed += ramp_amount * stage_speed_ramp

## Removes all bugs, then removes the special one after a short time
func _clear_lilguys() -> void:
	for lilguy in lilguys:
		if is_instance_valid(lilguy):
			lilguy.queue_free()
	lilguys.clear()

	await get_tree().create_timer(1.5).timeout
	Eventbus.special_removed.emit()

	if is_instance_valid(special_lilguy):
		special_lilguy.queue_free()
	special_lilguy = null
