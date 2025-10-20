extends Node2D

@export var speed: float = 0.0
@export var bounce_angle_variance: float = 0.25
@export var sprite: Sprite2D
var velocity: Vector2 = Vector2.ZERO
var bounds_rect: Rect2
var capturing_bug: bool = false
var target_pos: Vector2

var target: bool = false
var can_click: bool = false

const CATCH_HANDLER = preload("res://components/catch handler/catch_handler.tscn")

func _ready():

	if !sprite:
		sprite = get_node_or_null("Sprite2D")

	var angle = randf_range(0, TAU)
	velocity = Vector2(cos(angle), sin(angle))

	var move_area_node = get_tree().get_first_node_in_group("bounds")
	if move_area_node:
		bounds_rect = Rect2(move_area_node.global_position - move_area_node.rect_size * 0.5, move_area_node.rect_size)

	Eventbus.bug_caught.connect(func(): speed = 0.0)


func _process(delta):
	if not capturing_bug:
		position += velocity.normalized() * speed * delta
		_check_bounce()

func _check_bounce():
	if position.x < bounds_rect.position.x:
		position.x = bounds_rect.position.x
		velocity.x = -velocity.x
		velocity = velocity.rotated(randf_range(-bounce_angle_variance, bounce_angle_variance))
	elif position.x > bounds_rect.position.x + bounds_rect.size.x:
		position.x = bounds_rect.position.x + bounds_rect.size.x
		velocity.x = -velocity.x
		velocity = velocity.rotated(randf_range(-bounce_angle_variance, bounce_angle_variance))

	if position.y < bounds_rect.position.y:
		position.y = bounds_rect.position.y
		velocity.y = -velocity.y
		velocity = velocity.rotated(randf_range(-bounce_angle_variance, bounce_angle_variance))
	elif position.y > bounds_rect.position.y + bounds_rect.size.y:
		position.y = bounds_rect.position.y + bounds_rect.size.y
		velocity.y = -velocity.y
		velocity = velocity.rotated(randf_range(-bounce_angle_variance, bounce_angle_variance))

func add_catch_handler() -> void:
	var c = CATCH_HANDLER.instantiate()
	target = true
	add_child(c)
