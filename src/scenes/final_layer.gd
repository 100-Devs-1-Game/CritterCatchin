extends CanvasLayer

@export var stage_lbl: Label
@export var exit_button: BaseButton
@export var scale_amplitude: float = 0.1
@export var rotation_amplitude: float = 5
@export var speed: float = 1.0

var _time : float = 0.0

func set_final_info(amount: int) -> void:
	var count: int = 0
	for x in range(amount):
		stage_lbl.text = "Stage Reached: " + str(count)
		count += 1
		await get_tree().create_timer(0.05).timeout

func _process(delta):
	if not stage_lbl:
		return
	
	_time += delta * speed
	
	var scale_factor = 1.0 + sin(_time) * scale_amplitude
	stage_lbl.scale = Vector2(scale_factor, scale_factor)
	
	stage_lbl.rotation_degrees = sin(_time * 0.8) * rotation_amplitude
