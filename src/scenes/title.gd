extends Node2D

@export var play_button: BaseButton
@export var settings_button: BaseButton
@export var leaderboard_button: BaseButton
@export var quit_button: BaseButton
@export var change_user: BaseButton
@export var credits_button: BaseButton
@export var achievement_button: BaseButton
@export var menu_panel: TextureRect
@export var username_entry: LineEdit
@export var info_text: Label

const LEADERBOARD = preload("res://components/interface/leaderboard/leaderboard.tscn")
const CREDITS = preload("res://components/interface/credits/credits.tscn")
const ACHIEVEMENTS = preload("res://components/interface/achievements/achievements.tscn")
const NOTIFIER = preload("res://components/interface/notifier/notifier.tscn")


func _ready() -> void:
	_connect_ui()
	_check_name()
	Eventbus.menu_closed.connect(_toggle_visual)
	if OS.has_feature("web"):
		quit_button.visible = false

## Toggles the title UI when called
func _toggle_visual() -> void:
	$CanvasLayer/Outline.visible = !$CanvasLayer/Outline.visible
	$CanvasLayer/InfoCard.visible = $CanvasLayer/Outline.visible
	$CanvasLayer/Discord.visible = $CanvasLayer/Outline.visible

func _connect_ui() -> void:
	play_button.pressed.connect(func(): Sceneloader.to_game())
	settings_button.pressed.connect(func(): SettingsManager.display_settings_overlay(self) ; _toggle_visual())
	leaderboard_button.pressed.connect(request_open_leaderboard)
	quit_button.pressed.connect(func(): SettingsManager.close_game())
	change_user.pressed.connect(func(): SettingsManager.clear_username() ; _check_name())
	credits_button.pressed.connect(func(): var l = CREDITS.instantiate() ; add_child(l) ; _toggle_visual())
	achievement_button.pressed.connect(func(): var a = ACHIEVEMENTS.instantiate() ; add_child(a) ; _toggle_visual())

func open_leaderboard() -> void:
	_toggle_visual()
	var l = LEADERBOARD.instantiate()
	$CanvasLayer.call_deferred("add_child", l)

func request_open_leaderboard() -> void:
	if !SettingsManager.notified:
		var n = NOTIFIER.instantiate()
		$CanvasLayer.add_child(n)
		var response = await Eventbus.warning_closed
		if response == false:
			return
		else:
			open_leaderboard()
	else:
		open_leaderboard()

func _check_name() -> void:
	if SettingsManager.has_username():
		info_text.text = "Good luck and catch all those bugs, " + SettingsManager.get_username() + "!"
		$CanvasLayer/InfoCard/ChangeUser.visible = true
		$CanvasLayer/InfoCard/UsernameEntry.visible = false
	else:
		info_text.text = "Want to submit your scores to the leaderboard? Enter a name below!"
		$CanvasLayer/InfoCard/ChangeUser.visible = false
		$CanvasLayer/InfoCard/UsernameEntry.visible = true

func _submit_username(username: String) -> void:
	if username.length() < 1:
		push_warning("Username must be at least 2 characters long.")
		return
	if username != "":
		SettingsManager.set_username(username)
		_check_name()
	else:
		push_warning("Username cannot be blank.")

	$CanvasLayer/InfoCard/UsernameEntry.text = ""
