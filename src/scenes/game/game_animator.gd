extends Node2D

@export var net: Sprite2D
@export var sway_speed: float = 1.0
@export var sway_x_amplitude: float = 5.0
@export var sway_y_amplitude: float = 3.0
@export var pixel_size: float = 1.0

@export var bug_tex: Texture2D

@onready var netanim: AnimationPlayer = $"005/NetAnim"
@onready var find_bug: Sprite2D = $"005/FindBug"
@onready var bug_fall: Sprite2D = $BugFall

var sway: float = 0.0
var pause_sway: bool = false
var base_position: Vector2

const PHYSICS_BUG = preload("res://components/physics_entity/physics_bug.tscn")

@export var batch_threshold: int = 60
@export var rotating_layers: int = 8
@export var environment_mask: int = 0
@export var spawn_horizontal_push_min: float = -50.0
@export var spawn_horizontal_push_max: float = 50.0
@export var spawn_vertical_velocity: float = 500.0
@export var z_layer_base: int = 0

var _current_layer_idx: int = 0
var _batch_count: int = 0

func _ready() -> void:
	if net:
		base_position = net.position
	_current_layer_idx = 0
	_batch_count = 0

func _process(delta: float) -> void:
	if not net or pause_sway:
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

func show_net() -> void:
	netanim.play("show")
	await netanim.animation_finished
	pause_sway = false

func hide_net(play_drop: bool) -> void:
	pause_sway = true
	netanim.play("hide")
	await netanim.animation_finished
	if not play_drop:
		return
	await get_tree().create_timer(1.0).timeout
	netanim.play("bug_fall")
	Eventbus.sound_request.emit("res://audio/bug falling.mp3")
	await netanim.animation_finished
	_spawn_physics_bug()
	Eventbus.add_bug.emit()

func set_target(texture: Texture2D) -> void:
	bug_tex = texture
	find_bug.texture = texture
	bug_fall.texture = texture

func _get_collision_layer_bit(layer_idx: int) -> int:
	return 1 << layer_idx

func _get_frozen_layer_bit() -> int:
	return 1 << rotating_layers

func _get_active_mask() -> int:
	var mask = environment_mask
	mask = mask | _get_collision_layer_bit(_current_layer_idx)
	return mask

## Creates a physics bug on the current batch layer
func _spawn_physics_bug() -> RigidBody2D:
	var phys_bug = PHYSICS_BUG.instantiate() as RigidBody2D
	var sprite = phys_bug.get_node("BugTexture")
	sprite.texture = bug_fall.texture
	add_child(phys_bug)
	phys_bug.global_position = bug_fall.global_position
	phys_bug.freeze = false
	phys_bug.collision_layer = _get_collision_layer_bit(_current_layer_idx)
	phys_bug.collision_mask = _get_active_mask()
	phys_bug.add_to_group("bugs_layer_%d" % _current_layer_idx)
	var push_x = randf_range(spawn_horizontal_push_min, spawn_horizontal_push_max)
	phys_bug.linear_velocity.x = push_x
	phys_bug.linear_velocity.y = spawn_vertical_velocity
	phys_bug.z_index = z_layer_base + _current_layer_idx
	#Batch keesp count of how many bugs are on the current layer and in the container
	#If they pass the threshold it will begin spawning them on the next layer
	_batch_count += 1
	if _batch_count >= batch_threshold:
		_switch_spawn_layer()
	return phys_bug

#Switches to a new layer to spawn more bugs on
func _switch_spawn_layer() -> void:
	var prev = _current_layer_idx
	_freeze_layer(prev)
	if _current_layer_idx + 1 < rotating_layers:
		_current_layer_idx += 1
	else:
		_current_layer_idx = 0
	_batch_count = 0

#Freezes all rigidbodies on a given layer
func _freeze_layer(layer_idx: int) -> void:
	var group_name = "bugs_layer_%d" % layer_idx
	for bug in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(bug):
			continue
		bug.collision_layer = _get_frozen_layer_bit()
		if bug is RigidBody2D:
			bug.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			bug.sleeping = true
		bug.z_index = z_layer_base + rotating_layers + 1
		bug.remove_from_group(group_name)
		bug.add_to_group("bugs_frozen")
