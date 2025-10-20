extends Panel
class_name AchievementCard

@export var icon_size: Vector2 = Vector2(64, 64)

@export var icon_tex: TextureRect
@export var title_label: Label
@export var desc_label: Label
@export var progress: TextureProgressBar

var data: AchievementData = null

func _ready() -> void:
	icon_tex.size = icon_size

func setup_from_data(p_data: AchievementData) -> void:
	data = p_data

	title_label.text = _format_title_with_progress(
		data.title, data.progressive, data.current_amount, data.required_amount
	)
	desc_label.text = data.description
	if icon_tex != null:
		icon_tex.texture = data.icon

	if data.progressive and data.required_amount > 0:
		progress.visible = true
		progress.min_value = 0
		progress.max_value = float(data.required_amount)
		progress.value = float(data.current_amount)
	else:
		progress.value = progress.max_value

	set_locked_state(not data.unlocked)

func set_progress(current: int, required: int) -> void:
	if required <= 0:
		progress.visible = false
	else:
		progress.visible = true
		if current < 0:
			current = 0
		if current > required:
			current = required
		progress.min_value = 0
		progress.max_value = float(required)
		progress.value = float(current)

	if data != null:
		title_label.text = _format_title_with_progress(
			data.title, data.progressive, current, required
		)

func set_locked_state(locked: bool) -> void:
	if locked:
		modulate = Color(0.75, 0.75, 0.75, 1.0)
		icon_tex.self_modulate = Color(0, 0, 0, 1)
	else:
		modulate = Color(1, 1, 1, 1)
		icon_tex.self_modulate = Color(1, 1, 1, 1)

func _format_title_with_progress(base_title: String, is_progressive: bool, current: int, required: int) -> String:
	if is_progressive and required > 0:
		if current < 0:
			current = 0
		elif current > required:
			current = required
		return "%s (%d/%d)" % [base_title, current, required]
	return base_title
