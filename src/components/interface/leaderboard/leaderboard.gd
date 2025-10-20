extends Node2D

@export var label_container: VBoxContainer
@export var label_template: Label

@export var exit_button: BaseButton
@export var first_place_label: Label

@export var scale_amplitude: float = 0.1
@export var rotation_amplitude: float = 5
@export var speed: float = 1.0

var _time : float = 0.0

var leaderboard_name := "stages-complete"

func _ready() -> void:
	exit_button.pressed.connect(func(): queue_free())
	fetch_top_scores()

func fetch_top_scores() -> void:
	print("Fetching top scores...")

	for child in label_container.get_children():
		if child != label_template:
			child.queue_free()

	first_place_label.text = ""

	var options = Talo.leaderboards.GetEntriesOptions.new()
	options.set("page", 0)
	options.set("per_page", 50)

	var response = await Talo.leaderboards.get_entries(leaderboard_name, options)

	if response.entries.size() == 0:
		return

	var first = response.entries[0]
	first_place_label.text = "1. %s - %d" % [first.get_prop("name", "Unknown Player"), first.score]
	first_place_label.visible = true

	for i in range(1, response.entries.size()):
		var entry = response.entries[i]
		var label = label_template.duplicate() as Label
		label.text = "%d. %s - %d" % [i + 1, entry.get_prop("name", "Unknown Player"), entry.score]
		label.visible = true
		label_container.add_child(label)

	if label_container.get_child_count() == 0:
		label_template.text = "Looks like nobody's here."
	else:
		label_template.queue_free()
		

func _process(delta):
	if not first_place_label:
		return
	
	_time += delta * speed
	
	var scale_factor = 1.0 + sin(_time) * scale_amplitude
	first_place_label.scale = Vector2(scale_factor, scale_factor)
	first_place_label.rotation_degrees = sin(_time * 0.8) * rotation_amplitude
	
	if SettingsManager.flashing_enabled:
		var hue = fmod(_time * 0.2, 1.0)
		var color = Color.from_hsv(hue, 1.0, 1.0)
		first_place_label.modulate = color


func _on_tree_exiting() -> void:
	Eventbus.menu_closed.emit()
