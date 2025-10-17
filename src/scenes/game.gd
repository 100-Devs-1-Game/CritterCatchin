extends Node2D

@export var click_cooldown: float = 0.5
@export var time_penalty: float = 2.0
@export var total_time: float = 20.0
@export var timer_label: Label
@export var stage_label: Label
@export var cap_point: Marker2D

@export var game_over_scene: PackedScene
@export var cont_anim: AnimationPlayer
@export var bug_zone: Node2D

var _can_click: bool = true
var _timer: float = 0.0
var _bug_caught_recent: bool = false
var times_up: bool = false
var game_running: bool = false
var current_stage: int = 1

const PAUSED = preload("res://components/interface/pause/paused.tscn")

func _ready() -> void:
	Eventbus.bug_caught.connect(_on_bug_caught)
	_start_level()

func _process(delta: float) -> void:
	if game_running:
		_timer -= delta
		if _timer <= 0.0:
			_timer = 0.0
			_on_time_up()
		_update_timer_label()

		if Input.is_action_just_pressed("click") and _can_click:
			_can_click = false

			await get_tree().create_timer(0.015).timeout

			if _bug_caught_recent:
				_bug_caught_recent = false
			else:
				_timer = max(0.0, _timer - time_penalty)
				_flash_wrong_click()

			await get_tree().create_timer(click_cooldown).timeout
			_can_click = true

func _start_level() -> void:
	game_running = true
	_reset_time()
	_update_timer_label()
	Eventbus.level_started.emit(current_stage)

func _end_level() -> void:
	game_running = false
	_reset_time()
	_update_timer_label()

func _reset_time() -> void:
	_timer = total_time

func _on_bug_caught() -> void:
	_bug_caught_recent = true
	game_running = false
	await get_tree().create_timer(1.0).timeout
	_stash_bug()
	Eventbus.level_ended.emit()
	await get_tree().create_timer(1.0).timeout
	_end_level()


func _stash_bug() -> void:
	Eventbus.capture_bug.emit(cap_point.global_position)

	var bug_texture: Texture2D = null

	if cont_anim:
		cont_anim.play("lid")
		bug_texture = await Eventbus.add_bug
		cont_anim.play_backwards("lid")

	if bug_zone:
		var bug = Sprite2D.new()
		bug.scale = Vector2(0.043, 0.0434)
		bug.texture = bug_texture

		var top_left = bug_zone.global_position - bug_zone.rect_size * 0.5
		var random_pos = Vector2(
			randf_range(top_left.x, top_left.x + bug_zone.rect_size.x),
			randf_range(top_left.y, top_left.y + bug_zone.rect_size.y)
		)
		bug.global_position = random_pos

		add_child(bug)

	current_stage += 1
	stage_label.text = "STAGE: " + str(current_stage)

	_start_level()

func _on_time_up() -> void:
	if !times_up:
		Eventbus.level_ended.emit()
		times_up = true
		var g = game_over_scene.instantiate()
		add_child(g)

func _flash_wrong_click() -> void:
	var original_color = timer_label.modulate
	timer_label.modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(timer_label, "modulate", original_color, 0.3)

func _update_timer_label() -> void:
	if timer_label and is_instance_valid(timer_label):
		timer_label.text = str(roundi(_timer))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var p = PAUSED.instantiate()
		$CanvasLayer.add_child(p)
