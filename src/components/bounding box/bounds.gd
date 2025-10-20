@tool
extends Node2D

## Sets the size of the bounding box
@export var rect_size: Vector2 = Vector2(600, 400)
## Redraws the drawn rectangle if true
@export var update_realtime: bool = true
@export var z_order: int = 100
@export var display_in_engine: bool = true

func _draw():
	var top_left = -rect_size * 0.5
	draw_rect(Rect2(top_left, rect_size), Color(0, 1, 0, 0.2), false, 9)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and update_realtime:
		queue_redraw()
		z_index = z_order
