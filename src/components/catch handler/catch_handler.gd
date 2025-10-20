extends Area2D

var caught: bool = false

func _ready() -> void:
	Eventbus.level_ended.connect(func(): get_parent().can_click = false)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_mask == 1:
			if get_parent().can_click:
				if !caught:
					caught = true
					Eventbus.bug_caught.emit()
