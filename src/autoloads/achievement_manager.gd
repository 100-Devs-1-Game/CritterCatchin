extends Node

signal achievement_unlocked(id: StringName, data: AchievementData)
signal achievement_progress(data: AchievementData, current: int, required: int)
signal achievements_loaded

const ACHIEVEMENTS_DIR = "res://resources/achievements/"
const SAVE_PATH = "user://achievements.cfg"
const SAVE_SECTION = "achievements"
const SAVE_SECTION_PROGRESS = "achievements_progress"

var _achievements_by_id: Dictionary = {}
var _unlocked_ids: Dictionary = {}
var _progress_by_id: Dictionary = {}

var _bus_connected: bool = false

func _ready() -> void:
	_connect_listen_to(Eventbus)
	_load_definitions()
	_load_progress()
	_apply_loaded_progress()

	emit_signal("achievements_loaded")

	if not is_connected("achievement_unlocked", Callable(self, "_on_achievement_unlocked")):
		connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))


func all() -> Array:
	var list = _achievements_by_id.values()
	list.sort_custom(func(a, b): return a.title.naturalnocasecmp_to(b.title) < 0)
	return list


func get_by_id(id: String) -> AchievementData:
	return _achievements_by_id.get(id)


func is_unlocked(id: String) -> bool:
	return _unlocked_ids.get(id, false)


func unlock(id: String) -> void:
	var data: AchievementData = _achievements_by_id.get(id)
	if data == null:
		push_warning("Tried to unlock unknown achievement id='%s'" % id)
		return
	if is_unlocked(id):
		return
	_unlocked_ids[id] = true
	data.unlocked = true
	_save_progress()
	emit_signal("achievement_unlocked", data.id, data)
	Eventbus.announce_unlock.emit()


func try_unlock_on_predicate(id: String, predicate: Callable) -> void:
	if is_unlocked(id):
		return
	if predicate.call():
		unlock(id)


func try_unlock_threshold(id: String, current_value: int, required: int) -> void:
	#print("Achievement ID: %s, Current progress: %s,  Required amount: %s " % [id, str(current_value), str(required)])
	if is_unlocked(id):
		return
	if current_value >= required:
		unlock(id)


func _load_definitions() -> void:
	_achievements_by_id.clear()

	var dir = DirAccess.open(ACHIEVEMENTS_DIR)
	if dir == null:
		push_warning("Achievements directory not found at " + ACHIEVEMENTS_DIR)
		return

	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if dir.current_is_dir():
			continue

		var should_consider = false
		if file.ends_with(".tres"):
			should_consider = true
		elif file.ends_with(".res"):
			should_consider = true
		elif file.ends_with(".tres.remap"):
			should_consider = true
		elif file.ends_with(".res.remap"):
			should_consider = true

		if not should_consider:
			continue

		var load_name = file
		if file.ends_with(".remap"):
			load_name = file.substr(0, file.length() - 6)

		var path = ACHIEVEMENTS_DIR + load_name
		var res = ResourceLoader.load(path)

		if res == null:
			push_warning("Failed to load achievement resource: " + path)
			continue
		if not (res is AchievementData):
			push_warning("Resource at " + path + " is not AchievementData.")
			continue

		var id = res.id
		if id == "":
			push_warning("Achievement missing id at " + path)
			continue
		if _achievements_by_id.has(id):
			push_warning("Duplicate achievement id '" + id + "' at " + path)
			continue

		_achievements_by_id[id] = res

	dir.list_dir_end()


func _apply_loaded_progress() -> void:
	for id in _achievements_by_id.keys():
		var data: AchievementData = _achievements_by_id[id]
		data.unlocked = _unlocked_ids.get(id, false)
		data.current_amount = int(_progress_by_id.get(id, 0))

func _load_progress() -> void:
	_unlocked_ids.clear()
	_progress_by_id.clear()

	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("Failed to load achievements from %s (code %d)." % [SAVE_PATH, err])
		return

	if cfg.has_section(SAVE_SECTION):
		for id in cfg.get_section_keys(SAVE_SECTION):
			_unlocked_ids[id] = bool(cfg.get_value(SAVE_SECTION, id, false))

	if cfg.has_section(SAVE_SECTION_PROGRESS):
		for id in cfg.get_section_keys(SAVE_SECTION_PROGRESS):
			_progress_by_id[id] = int(cfg.get_value(SAVE_SECTION_PROGRESS, id, 0))


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)

	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("Couldn't load existing %s (code %d); writing fresh." % [SAVE_PATH, err])
		cfg = ConfigFile.new()

	for id in _achievements_by_id.keys():
		cfg.set_value(SAVE_SECTION, id, _unlocked_ids.get(id, false))

	for id in _achievements_by_id.keys():
		var data: AchievementData = _achievements_by_id[id]
		if data.progressive:
			var cur: int = int(_progress_by_id.get(id, data.current_amount))
			cfg.set_value(SAVE_SECTION_PROGRESS, id, cur)

	err = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save achievements at %s (code %d)" % [SAVE_PATH, err])

func reset_all() -> void:
	print("Achievements have been reset.")
	_unlocked_ids.clear()
	_progress_by_id.clear()
	for id in _achievements_by_id.keys():
		var data: AchievementData = _achievements_by_id[id]
		if data.progressive:
			data.current_amount = 0
		data.unlocked = false
	_save_progress()
	emit_signal("achievements_loaded")


func add_progress(id: String, amount: int) -> void:
	if not _achievements_by_id.has(id):
		return
	var data: AchievementData = _achievements_by_id[id]
	if not data.progressive:
		return

	var cur = int(_progress_by_id.get(id, data.current_amount))
	cur += amount
	if cur < 0:
		cur = 0
	if data.required_amount > 0:
		cur = min(cur, data.required_amount)

	_progress_by_id[id] = cur
	data.current_amount = cur

	emit_signal("achievement_progress", data, cur, data.required_amount)
	try_unlock_threshold(id, cur, data.required_amount)
	_save_progress()


func set_progress(id: String, value: int) -> void:
	add_progress(id, value - int(_progress_by_id.get(id, 0)))


func set_progress_max(id: String, value: int) -> void:
	var prev = int(_progress_by_id.get(id, 0))
	if value > prev:
		set_progress(id, value)


func get_progress(id: String) -> int:
	return int(_progress_by_id.get(id, 0))


func _connect_listen_to(bus: Eventbus) -> void:
	if _bus_connected or bus == null:
		return

	bus.bug_caught.connect(_on_bug_caught)
	bus.stage_begun.connect(_on_stage_started)
	bus.special_bug_caught.connect(_on_special_bug_caught)

	_bus_connected = true


func _on_bug_caught() -> void:
	try_unlock_on_predicate("first_bug", func() -> bool: return true)
	var bug_achievements = ["ten_bugs", "thirty_bugs", "fifty_bugs", "hundred_bugs", "two_hundred_bugs", "five_hundred_bugs"]
	for id in bug_achievements:
		add_progress(id, 1)


func _on_stage_started(current_stage: int) -> void:
	#print("Achievement manager recieved stage %s" % str(current_stage))
	var stage_achievements = ["ten_stages", "twenty_stages", "fifty_stages", "hundred_stages", "five_hundred_stages"] 
	for id in stage_achievements:
		set_progress_max(id, current_stage)


func _on_special_bug_caught() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		reset_all()
