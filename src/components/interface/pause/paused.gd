extends Control

@export var pause: Panel
@export var hide_panel: Control

func _ready() -> void:
	_pause()
	Eventbus.menu_closed.connect(func(): hide_panel.visible = true)

func _pause() -> void:
	SettingsManager.pause_game(true)
	SettingsManager.pause_streams(true)

func _unpause() -> void:
	SettingsManager.pause_game(false)
	SettingsManager.pause_streams(false)
	Eventbus.pauser_removed.emit()
	queue_free()

func _resume() -> void:
	_unpause()

func _settings() -> void:
	SettingsManager.display_settings_overlay(self)
	hide_panel.visible = false

func _exit() -> void:
	_unpause()
	Sceneloader.to_title()
