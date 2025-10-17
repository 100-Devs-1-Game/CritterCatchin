extends Node2D

@export var play_button: BaseButton
@export var settings_button: BaseButton
@export var leaderboard_button: BaseButton
@export var quit_button: BaseButton

func _ready() -> void:
	_connect_ui()

func _connect_ui() -> void:
	play_button.pressed.connect(func(): Sceneloader.to_game())
	settings_button.pressed.connect(func(): SettingsManager.display_settings_overlay(self))
	leaderboard_button.pressed.connect(func(): pass)
	quit_button.pressed.connect(func(): SettingsManager.close_game())
