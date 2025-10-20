extends Node2D

@export var net: Sprite2D

#this just handles the nets animation
@export var sway_speed: float = 1.0
@export var sway_x_multiplier: float = 5.0
@export var sway__y_multiplier: float = 3.0
@export var pixel_amount: float = 1.0

##how many entities can be added to one layer
@export var batch_threshold: int = 50

@export var debug_spawn_extra_bugs: bool = false
@export var debug_bugs_provided: int = 4

##x equals to the minimum and y equals to the maximum random initial velocity to prevent stacking
@export var initial_push_min_max:Vector2 = Vector2(-50.0, 50.0)
@export var initial_push_y: float = 500.0

var sway: float = 0.0
var pause_sway: bool = false
var base_position: Vector2

#for batch layering and control for collision layer
var _current_layer: int = 1
#batch count is how many entities can be created on this layer before swapping to avoid overflow
var _batch_count: int = 0

var bug_tex: Texture2D

@onready var net_anim: AnimationPlayer = $"005/NetAnim"
@onready var find_bug: Sprite2D = $"005/FindBug"
@onready var bug_fall: Sprite2D = $BugFall

const PHYSICS_BUG = preload("res://components/physics_entity/physics_bug.tscn")

func _ready() -> void:
	if net:
		base_position = net.position
	_current_layer = 1
	_batch_count = 0


func _process(delta: float) -> void:
	if not net or pause_sway:
		return
	sway += delta * sway_speed
	var raw_position = base_position + Vector2(sin(sway) * sway_x_multiplier, sin(sway) * 0.8 * sway__y_multiplier)
	net.position = Vector2(floor(raw_position.x / pixel_amount + 0.5) * pixel_amount, floor(raw_position.y / pixel_amount + 0.5) * pixel_amount)


func show_net() -> void:
	net_anim.play("show")
	await net_anim.animation_finished
	pause_sway = false


func hide_net(play_drop: bool) -> void:
	pause_sway = true
	net_anim.play("hide")
	await net_anim.animation_finished
	if !play_drop:
		return
	await get_tree().create_timer(1.0).timeout
	net_anim.play("bug_fall")
	Eventbus.sound_request.emit("res://audio/bug falling.mp3")
	await net_anim.animation_finished
	if debug_spawn_extra_bugs:
		for i in debug_bugs_provided - 1:
			_spawn_physics_bug()
	_spawn_physics_bug()
	Eventbus.add_bug.emit()


func set_target(texture: Texture2D) -> void:
	bug_tex = texture
	find_bug.texture = texture
	bug_fall.texture = texture


func _spawn_physics_bug() -> RigidBody2D:
	var phys_bug = PHYSICS_BUG.instantiate()
	var sprite = phys_bug.get_node("BugTexture")
	sprite.texture = bug_fall.texture
	add_child(phys_bug)

	phys_bug.add_to_group("bugs_layer_" + str(_current_layer))

	phys_bug.global_position = bug_fall.global_position

	var initial_x_vel = randf_range(initial_push_min_max.x, initial_push_min_max.y)
	phys_bug.linear_velocity.x = initial_x_vel
	phys_bug.linear_velocity.y = initial_push_y
	phys_bug.collision_layer = _current_layer
	phys_bug.collision_mask = _current_layer

	_batch_count += 1

	if _batch_count >= batch_threshold:
		#print("Max entities allowed on this layer, changing to a new layer")
		_next_layer()
	else:
		print("Under max threshold, we can continue providing top quality bugs :)")

	return phys_bug

##swaps to the next layer and freezes all entities on the previous
func _next_layer() -> void:
	var prev = _current_layer
	_freeze_layer(prev)
	if _current_layer + 1 == 32:
		#print("last layer reached, clearing 1st layer and restarting cycle")
		_clear_layer(1)
		_current_layer = 1
	else:
		_current_layer += 1
		_clear_layer(_current_layer)
		#print("current layer is now %i" %_current_layer)

	_batch_count = 0

func get_group_name(value: int) -> String:
	var group = "bugs_layer_" + str(value)
	print("group gotten: ", group)
	return group

func _freeze_layer(layer: int) -> void:
	print("layer " + str(layer) + " has been frozen")
	var g = get_group_name(layer)
	for rid: RigidBody2D in get_tree().get_nodes_in_group(g):
		if not is_instance_valid(rid):
			continue
		rid.freeze = true
		rid.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

func _clear_layer(layer: int) -> void:
	print("layer " + str(layer) + " has been cleared")
	var g = get_group_name(layer)
	for bug in get_tree().get_nodes_in_group(g):
		if not is_instance_valid(bug):
			continue
		bug.queue_free()
