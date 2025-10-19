extends CanvasLayer

@export var white_overlay: ColorRect
@export var flash_alpha: float = 0.5
@export var flash_out_time: float = 0.5

func _ready() -> void:
	Eventbus.bug_caught.connect(func(): flash_response(true))
	Eventbus.wrong_click.connect(func(): flash_response(false))
	if white_overlay:
		white_overlay.color.a = 0.0

## Flashes either red or white depending on if the click was correct
func flash_response(success: bool) -> void:
	if not white_overlay:
		return

	var target_color: Color
	if success:
		target_color = Color(1, 1, 1, flash_alpha)
	else:
		target_color = Color(1, 0, 0, flash_alpha)

	white_overlay.color = target_color

	var tween = create_tween()
	tween.tween_property(white_overlay, "color:a", 0.0, flash_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
