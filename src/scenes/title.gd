extends Node2D

@export var play_button: BaseButton
@export var settings_button: BaseButton
@export var leaderboard_button: BaseButton
@export var quit_button: BaseButton
@export var menu_panel: TextureRect

const UI_HOVER = preload("res://audio/pop.mp3")
const LEADERBOARD = preload("res://components/interface/leaderboard/leaderboard.tscn")

var _time: float = 0.0
var _panel_base_y: float = 0.0
@export var bob_amplitude: float = 10.0
@export var bob_speed: float = 2.0

func _ready() -> void:
	_connect_ui()
	if menu_panel:
		_panel_base_y = menu_panel.position.y
	Eventbus.menu_closed.connect(_toggle_visual)

## Toggles the title UI when called
func _toggle_visual() -> void:
	$CanvasLayer/Outline.visible = !$CanvasLayer/Outline.visible

func _connect_ui() -> void:
	play_button.pressed.connect(func(): Sceneloader.to_game())
	settings_button.pressed.connect(func(): SettingsManager.display_settings_overlay(self) ; _toggle_visual())
	leaderboard_button.pressed.connect(func(): _toggle_visual() ; var l = LEADERBOARD.instantiate() ; $CanvasLayer.add_child(l))
	quit_button.pressed.connect(func(): SettingsManager.close_game())

	var buttons = [play_button, settings_button, leaderboard_button, quit_button]
	for b in buttons:
		b.mouse_entered.connect(func(): AudioManager.play_sound(UI_HOVER))

func _process(delta: float) -> void:
	if menu_panel:
		_time += delta
		menu_panel.position.y = _panel_base_y + sin(_time * bob_speed) * bob_amplitude
