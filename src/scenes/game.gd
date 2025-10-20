extends Node2D

@export var click_cooldown : float = 0.5
@export var time_penalty : float = 2.0
@export var total_time : float = 20.0
@export var timer_label: Label
@export var stage_label: Label
@export var world: Node2D
@export var cont_anim: AnimationPlayer
@export var end_call_delay : float = 1.0

var _can_click : bool = true
var _timer : float = 0.0
var _bug_caught_recent : bool = false
var times_up :bool = false
var game_running : bool = false
var current_stage : int = 1

var _skip_pressed: bool = false

var _lowtime_playing: bool = false

const PAUSED = preload("res://components/interface/pause/paused.tscn")
const TIME_RUNNING_OUT = preload("res://audio/time running out.mp3")
const ACHIEVEMENT_DISPLAY = preload("res://resources/displayer/achievement_display.tscn")

func _ready():
	Eventbus.bug_caught.connect(_on_bug_caught)
	Eventbus.sound_request.connect(play_audio)
	Eventbus.announce_unlock.connect(func(): var a = ACHIEVEMENT_DISPLAY.instantiate() ; add_child(a))
	animated_leaves()

	if SettingsManager.st_notified:
		_start_level()

func _process(delta):
	if not game_running:
		return

	_timer = max(_timer - delta, 0.0)

	if _timer <= 5.0 and not _lowtime_playing:
		$GameAudio.stream = TIME_RUNNING_OUT
		$GameAudio.play()
		_lowtime_playing = true
	elif _timer > 5.0 and _lowtime_playing:
		$GameAudio.stop()
		_lowtime_playing = false

	if _timer <= 0: 
		_on_time_up()
	_update_timer_label()

	if Input.is_action_just_pressed("click") and _can_click:
		_can_click = false
		await get_tree().create_timer(0.015).timeout

		if _bug_caught_recent:
			_bug_caught_recent = false
		else:
			_timer = max(_timer - time_penalty, 0.0)
			_flash_wrong_click()

		await get_tree().create_timer(click_cooldown).timeout
		_can_click = true


func _start_level():
	if $CanvasLayer.visible == false:
		$CanvasLayer.visible = true
	if $Explain.visible == true:
		$Explain.visible = false
	world.show_net()
	current_stage += 1
	game_running = true
	_timer = total_time
	_update_timer_label()
	Eventbus.level_started.emit(current_stage)
	Eventbus.stage_begun.emit() #was too lazy to merge level_started and the one for ach manager, sorry 😅


func _end_level():
	game_running = false
	_timer = total_time
	_update_timer_label()


func _on_bug_caught():
	play_audio("res://audio/pop.mp3")
	_bug_caught_recent = true
	_end_level()
	await get_tree().create_timer(end_call_delay).timeout
	Eventbus.level_ended.emit()
	await Eventbus.special_removed
	world.hide_net(true)
	_stash_bug()


## Begins the sequence to stashing the bug in the container
func _stash_bug():
	if cont_anim:
		cont_anim.play("lid")
		play_audio("res://audio/container noise open.wav")
		await Eventbus.add_bug
		cont_anim.play_backwards("lid")
		play_audio("res://audio/container noise close.wav")
		await cont_anim.animation_finished

	stage_label.text = "STAGE: %d" % current_stage
	_start_level()


func _on_time_up():
	if times_up:
		return
	Eventbus.level_ended.emit()
	times_up = true
	world.hide_net(false)
	$GameAudio.stop()
	$CanvasLayer/Overlay/Control.visible = false
	await get_tree().create_timer(2.0).timeout
	$FinalLayer.visible = true ; $FinalLayer.set_final_info(current_stage)
	#add_child(game_over_scene.instantiate())


func animated_leaves():
	await get_tree().create_timer(randf_range(0, 20)).timeout
	$BGSprite.play("leaves")
	animated_leaves()


func _flash_wrong_click():
	var orig = timer_label.modulate
	timer_label.modulate = Color(1, 0, 0)
	create_tween().tween_property(timer_label, "modulate", orig, 0.3)
	Eventbus.wrong_click.emit()


func _update_timer_label():
	if timer_label and is_instance_valid(timer_label):
		timer_label.text = str(roundi(_timer))


func play_audio(audio: String):
	if SettingsManager.is_paused():
		await Eventbus.pauser_removed
	$GameAudio.stream = load(audio)
	$GameAudio.play()


func _input(event):
	if event.is_action_pressed("pause") and !times_up:
		$CanvasLayer.add_child(PAUSED.instantiate())


func return_to_title() -> void:
	_skip_pressed = false
	$FinalLayer/Button.disabled = true
	$FinalLayer/Skip.visible = true

	var username = SettingsManager.get_username()
	if not _skip_pressed and username != null and username.strip_edges() != "":
		print_debug("User available, sending score to leaderboard")
		await Talo.players.identify("guest", username)
		if _skip_pressed:
			Sceneloader.to_title()
			return
		await Talo.leaderboards.add_entry("stages-complete", current_stage, {"name": username})
		if _skip_pressed:
			Sceneloader.to_title()
			return
		print("Score submitted to the leaderboard, Current stage - ", str(current_stage))

	if _skip_pressed:
		Sceneloader.to_title()
		return

	await get_tree().create_timer(1.0).timeout
	if _skip_pressed:
		Sceneloader.to_title()
		return

	Sceneloader.to_title()


func _on_skip_pressed() -> void:
	_skip_pressed = true
	print("Leaderboard submission cancelled.")
	Sceneloader.to_title()
